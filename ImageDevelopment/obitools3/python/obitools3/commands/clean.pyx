#cython: language_level=3

from obitools3.apps.progress cimport ProgressBar  # @UnresolvedImport
from obitools3.dms.dms cimport DMS
from obitools3.dms.view import RollbackException
from obitools3.dms.capi.obiclean cimport obi_clean
from obitools3.apps.optiongroups import addMinimalInputOption, addMinimalOutputOption
from obitools3.uri.decode import open_uri
from obitools3.apps.config import logger
from obitools3.utils cimport tobytes, str2bytes
from obitools3.dms.view.view cimport View
from obitools3.dms.view.typed_view.view_NUC_SEQS cimport View_NUC_SEQS

import sys


__title__="Tag a set of sequences for PCR and sequencing errors identification"


def addOptions(parser):

    addMinimalInputOption(parser)
    addMinimalOutputOption(parser)
 
    group = parser.add_argument_group('obi clean specific options')

    group.add_argument('--distance', '-d',
                       action="store", dest="clean:distance",
                       metavar='<DISTANCE>',
                       default=1.0,
                       type=float,
                       help="Maximum numbers of errors between two variant sequences. Default: 1.")

    group.add_argument('--sample-tag', '-s',
                       action="store", 
                       dest="clean:sample-tag-name",
                       metavar="<SAMPLE TAG NAME>",
                       type=str,
                       default="merged_sample",
                       help="Name of the tag where sample counts are kept.")
    
    group.add_argument('--ratio', '-r',
                       action="store", dest="clean:ratio",
                       metavar='<RATIO>',
                       default=0.5,
                       type=float,
                       help="Maximum ratio between the counts of two sequences so that the less abundant one can be considered"
                            " a variant of the more abundant one. Default: 0.5.")
 
    group.add_argument('--heads-only', '-H',
                       action="store_true", 
                       dest="clean:heads-only",
                       default=False,
                       help="Only sequences labeled as heads are kept in the output. Default: False")

    group.add_argument('--cluster-tags', '-C',
                       action="store_true", 
                       dest="clean:cluster-tags",
                       default=False,
                       help="Adds tags for each sequence giving its cluster's head and weight for each sample.")

    group.add_argument('--thread-count','-p',   # TODO should probably be in a specific option group
                       action="store", dest="clean:thread-count",
                       metavar='<THREAD COUNT>',
                       default=-1,
                       type=int,
                       help="Number of threads to use for the computation. Default: the maximum available.")


def run(config):
        
    DMS.obi_atexit()
    
    logger("info", "obi clean")

    # Open the input: only the DMS
    input = open_uri(config['obi']['inputURI'],
                     dms_only=True)
    if input is None:
        raise Exception("Could not read input")
    i_dms = input[0]
    i_dms_name = input[0].name
    i_view_name = input[1]

    # Open the output: only the DMS
    output = open_uri(config['obi']['outputURI'],
                      input=False,
                      dms_only=True)
    if output is None:
        raise Exception("Could not create output")
    o_dms = output[0]
    final_o_view_name = output[1]
    
    # If the input and output DMS are not the same, run obiclean creating a temporary view that will be exported to 
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
    comments = View.print_config(config, "clean", command_line, input_dms_name=[i_dms_name], input_view_name=[i_view_name])

    if obi_clean(i_dms.name_with_full_path, tobytes(i_view_name), tobytes(config['clean']['sample-tag-name']), tobytes(o_view_name), comments, \
              config['clean']['distance'], config['clean']['ratio'], config['clean']['heads-only'], config['clean']['thread-count']) < 0:
        raise Exception("Error running obiclean")
    
    # If the input and output DMS are not the same, export result view to output DMS
    if i_dms != o_dms:
        View.import_view(i_dms.full_path[:-7], o_dms.full_path[:-7], o_view_name, final_o_view_name)
    
    # Save command config in DMS comments
    o_dms.record_command_line(command_line)

    #print("\n\nOutput view:\n````````````", file=sys.stderr)
    #print(repr(o_dms[final_o_view_name]), file=sys.stderr)

    # If the input and the output DMS are different, delete the temporary result view in the input DMS
    if i_dms != o_dms:
        View.delete_view(i_dms, o_view_name)
        o_dms.close()
    
    i_dms.close()

    logger("info", "Done.")