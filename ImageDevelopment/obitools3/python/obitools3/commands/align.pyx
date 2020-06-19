#cython: language_level=3

from obitools3.apps.progress cimport ProgressBar  # @UnresolvedImport
from obitools3.dms import DMS
from obitools3.dms.view.view cimport View
from obitools3.uri.decode import open_uri
from obitools3.apps.optiongroups import addMinimalInputOption, addMinimalOutputOption
from obitools3.dms.view import RollbackException
from obitools3.apps.config import logger
from obitools3.utils cimport tobytes, str2bytes

from obitools3.dms.capi.obilcsalign cimport obi_lcs_align_one_column, \
                                            obi_lcs_align_two_columns

import time
import sys


__title__="Aligns one sequence column with itself or two sequence columns"


def addOptions(parser):
   
   addMinimalInputOption(parser)
   addMinimalOutputOption(parser)

   group=parser.add_argument_group('obi align specific options')

   group.add_argument('--input-2', '-I',
                      action="store", dest="align:inputuri2",
                      metavar='<INPUT URI>',
                      default="",
                      type=str,
                      help="Eventually, the URI of the second input to align with the first one.")
      
   group.add_argument('--threshold','-t',
                      action="store", dest="align:threshold",
                      metavar='<THRESHOLD>',
                      default=0.0,
                      type=float,
                      help="Score threshold. If the score is normalized and expressed in similarity (default),"
                           " it is an identity, e.g. 0.95 for an identity of 95%%. If the score is normalized"
                           " and expressed in distance, it is (1.0 - identity), e.g. 0.05 for an identity of 95%%."
                           " If the score is not normalized and expressed in similarity, it is the length of the"
                           " Longest Common Subsequence. If the score is not normalized and expressed in distance,"
                           " it is (reference length - LCS length)."
                           " Only sequence pairs with a similarity above <THRESHOLD> are printed. Default: 0.00"
                           " (no threshold).")
   
   group.add_argument('--longest-length','-L',
                      action="store_const", dest="align:reflength",
                      default=0,
                      const=1,
                      help="The reference length is the length of the longest sequence."
                           " Default: the reference length is the length of the alignment.")
   
   group.add_argument('--shortest-length','-l',
                      action="store_const", dest="align:reflength",
                      default=0,
                      const=2,
                      help="The reference length is the length of the shortest sequence."
                           " Default: the reference length is the length of the alignment.")
   
   group.add_argument('--raw','-r',
                      action="store_false", dest="align:normalize",
                      default=True,
                      help="Raw score, not normalized. Default: score is normalized with the reference sequence length.")
   
   group.add_argument('--distance','-D',
                      action="store_false", dest="align:similarity",
                      default=True,
                      help="Score is expressed in distance. Default: score is expressed in similarity.")
   
   group.add_argument('--print-seq','-s',
                      action="store_true", dest="align:printseq",
                      default=False,
                      help="The nucleotide sequences are written in the output view. Default: they are not written.")
   
   group.add_argument('--print-count','-n',
                      action="store_true", dest="align:printcount",
                      default=False,
                      help="Sequence counts are written in the output view. Default: they are not written.")
   
   group.add_argument('--thread-count','-p',   # TODO should probably be in a specific option group
                      action="store", dest="align:threadcount",
                      metavar='<THREAD COUNT>',
                      default=1,
                      type=int,
                      help="Number of threads to use for the computation. Default: one.")


cpdef align_columns(bytes dms_n, 
                    bytes input_view_1_n, 
                    bytes output_view_n,
                    bytes input_view_2_n=b"",
                    bytes input_column_1_n=b"", 
                    bytes input_column_2_n=b"",
                    bytes input_elt_1_n=b"", 
                    bytes input_elt_2_n=b"",
                    bytes id_column_1_n=b"", 
                    bytes id_column_2_n=b"",
                    double threshold=0.0, bint normalize=True, 
                    int reference=0, bint similarity_mode=True,
                    bint print_seq=False, bint print_count=False,
                    bytes comments=b"{}",
                    int thread_count=1) : 

    if input_view_2_n == b"" and input_column_2_n == b"" :
        if obi_lcs_align_one_column(dms_n, \
                                    input_view_1_n, \
                                    input_column_1_n, \
                                    input_elt_1_n, \
                                    id_column_1_n, \
                                    output_view_n, \
                                    comments, \
                                    print_seq, \
                                    print_count, \
                                    threshold, normalize, reference, similarity_mode,
                                    thread_count) < 0 :
            raise Exception("Error aligning sequences")        
            
    else:
        if obi_lcs_align_two_columns(dms_n, \
                                     input_view_1_n, \
                                     input_view_2_n, \
                                     input_column_1_n, \
                                     input_column_2_n, \
                                     input_elt_1_n, \
                                     input_elt_2_n, \
                                     id_column_1_n, \
                                     id_column_2_n, \
                                     output_view_n, \
                                     comments, \
                                     print_seq, \
                                     print_count, \
                                     threshold, normalize, reference, similarity_mode) < 0 :
            raise Exception("Error aligning sequences")        
 
 
def run(config):
    
    DMS.obi_atexit()
    
    logger("info", "obi align")

    # Open the input: only the DMS
    input = open_uri(config['obi']['inputURI'],
                     dms_only=True)
    if input is None:
        raise Exception("Could not read input")
    i_dms = input[0]
    i_dms_name = input[0].name
    i_uri = input[1]
    i_view_name = i_uri.split(b"/")[0]
    i_column_name = b""
    i_element_name = b""
    if len(i_uri.split(b"/")) == 2:
        i_column_name = i_uri.split(b"/")[1]
    if len(i_uri.split(b"/")) == 3:
        i_element_name = i_uri.split(b"/")[2]
    if len(i_uri.split(b"/")) > 3:
        raise Exception("Input URI contains too many elements:", config['obi']['inputURI'])

    # Open the second input if there is one
    i_dms_2 = None
    i_dms_name_2 = b""
    original_i_view_name_2 = b""
    i_view_name_2 = b""
    i_column_name_2 = b""
    i_element_name_2 = b""
    if config['align']['inputuri2']:
        input_2 = open_uri(config['align']['inputuri2'],
                           dms_only=True)
        if input_2 is None:
            raise Exception("Could not read second input")
        i_dms_2 = input_2[0]
        i_dms_name_2 = i_dms_2.name
        i_uri_2 = input_2[1]
        original_i_view_name_2 = i_uri_2.split(b"/")[0]
        if len(i_uri_2.split(b"/")) == 2:
            i_column_name_2 = i_uri_2.split(b"/")[1]
        if len(i_uri_2.split(b"/")) == 3:
            i_element_name_2 = i_uri_2.split(b"/")[2]
        if len(i_uri_2.split(b"/")) > 3:
            raise Exception("Input URI contains too many elements:", config['align']['inputuri2'])

        # If the 2 input DMS are not the same, temporarily import 2nd input view in first input DMS
        if i_dms != i_dms_2:
            temp_i_view_name_2 = original_i_view_name_2
            i=0
            while temp_i_view_name_2 in i_dms:  # Making sure view name is unique in input DMS
                temp_i_view_name_2 = original_i_view_name_2+b"_"+str2bytes(str(i))
                i+=1
            i_view_name_2 = temp_i_view_name_2
            View.import_view(i_dms_2.full_path[:-7], i_dms.full_path[:-7], original_i_view_name_2, i_view_name_2)

    # Open the output: only the DMS
    output = open_uri(config['obi']['outputURI'],
                      input=False,
                      dms_only=True)
    if output is None:
        raise Exception("Could not create output")
    o_dms = output[0]
    o_dms_name = o_dms.name 
    final_o_view_name = output[1]

    # If the input and output DMS are not the same, align creating a temporary view in the input dms that will be exported to 
    # the right DMS and deleted in the other afterwards.
    if i_dms != o_dms:
        temporary_view_name = final_o_view_name
        i=0
        while temporary_view_name in i_dms:  # Making sure view name is unique in input DMS
            temporary_view_name = final_o_view_name+b"_"+str2bytes(str(i))
            i+=1
        o_view_name = temporary_view_name
    else:
        o_view_name = final_o_view_name
        
    # Save command config in View comments
    command_line = " ".join(sys.argv[1:])
    
    i_dms_list = [i_dms_name]
    if i_dms_name_2:
        i_dms_list.append(i_dms_name_2)
    i_view_list = [i_view_name]
    if original_i_view_name_2:
        i_view_list.append(original_i_view_name_2)
    comments = View.print_config(config, "align", command_line, input_dms_name=i_dms_list, input_view_name=i_view_list)
    
    # Call cython alignment function
      # Using default ID columns of the view. TODO discuss adding option
    align_columns(i_dms.name_with_full_path,  \
                  i_view_name,  \
                  o_view_name,  \
                  input_view_2_n   = i_view_name_2,  \
                  input_column_1_n = i_column_name,  \
                  input_column_2_n = i_column_name_2, \
                  input_elt_1_n    = i_element_name,  \
                  input_elt_2_n    = i_element_name_2, \
                  id_column_1_n    = b"",  \
                  id_column_2_n    = b"", \
                  threshold        = config['align']['threshold'], \
                  normalize        = config['align']['normalize'],  \
                  reference        = config['align']['reflength'],  \
                  similarity_mode  = config['align']['similarity'],  \
                  print_seq        = config['align']['printseq'],  \
                  print_count      = config['align']['printcount'], \
                  comments         = comments, \
                  thread_count     = config['align']['threadcount'])

    # If the input and output DMS are not the same, export result view to output DMS
    if i_dms != o_dms:
        View.import_view(i_dms.full_path[:-7], o_dms.full_path[:-7], o_view_name, final_o_view_name)

    # Save command config in output DMS comments
    o_dms.record_command_line(command_line)

    #print("\n\nOutput view:\n````````````", file=sys.stderr)
    #print(repr(o_dms[final_o_view_name]), file=sys.stderr)

    # If the two input DMS are different, delete the temporary input view in the first input DMS
    if i_dms_2 and i_dms != i_dms_2:
        View.delete_view(i_dms, i_view_name_2)
        i_dms_2.close()

    # If the input and the output DMS are different, delete the temporary result view in the input DMS
    if i_dms != o_dms:
        View.delete_view(i_dms, o_view_name)
        o_dms.close()
    
    i_dms.close()
    
    logger("info", "Done.")
  