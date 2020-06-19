#cython: language_level=3

from obitools3.apps.progress cimport ProgressBar  # @UnresolvedImport
from obitools3.dms import DMS
from obitools3.dms.view.view cimport View, Line_selection
from obitools3.uri.decode import open_uri
from obitools3.apps.optiongroups import addMinimalInputOption, addMinimalOutputOption
from obitools3.dms.view import RollbackException
from obitools3.apps.config import logger
from obitools3.utils cimport str2bytes

from obitools3.dms.capi.obitypes cimport OBI_BOOL, \
                                         OBI_CHAR, \
                                         OBI_FLOAT, \
                                         OBI_INT, \
                                         OBI_QUAL, \
                                         OBI_SEQ, \
                                         OBI_STR, \
                                         OBIBool_NA, \
                                         OBIChar_NA, \
                                         OBIFloat_NA, \
                                         OBIInt_NA

import time
import sys
from cpython.exc cimport PyErr_CheckSignals

 
NULL_VALUE = {OBI_BOOL: OBIBool_NA, 
              OBI_CHAR: OBIChar_NA, 
              OBI_FLOAT: OBIFloat_NA,
              OBI_INT: OBIInt_NA,
              OBI_QUAL: [],
              OBI_SEQ: b"",
              OBI_STR: b""}
 

__title__="Sort view lines according to the value of a given attribute."

 
def addOptions(parser):
    
    addMinimalInputOption(parser)
    addMinimalOutputOption(parser)

    group=parser.add_argument_group('obi sort specific options')

    group.add_argument('--key', '-k',
                       action="append", dest="sort:keys",
                       metavar='<TAG NAME>',
                       default=[],
                       type=str,
                       help="Attribute used to sort the sequence records.")

    group.add_argument('--reverse', '-r',
                       action="store_true", dest="sort:reverse",
                       default=False,
                       help="Sort in reverse order.")


def line_cmp(line, key, pb): 
    pb   
    if line[key] is None:
        return NULL_VALUE[line.view[key].data_type_int]
    else:
        return line[key]

     
def run(config):
     
    DMS.obi_atexit()
    
    logger("info", "obi sort")

    # Open the input
    input = open_uri(config["obi"]["inputURI"])
    if input is None:
        raise Exception("Could not read input view")
    i_dms = input[0]
    i_view = input[1]

    # Open the output: only the DMS
    output = open_uri(config['obi']['outputURI'],
                      input=False,
                      dms_only=True)
    if output is None:
        raise Exception("Could not create output view")
    o_dms = output[0]
    o_view_name_final = output[1]
    o_view_name = o_view_name_final
    
    # If the input and output DMS are not the same, create output view in input DMS first, then export it
    # to output DMS, making sure the temporary view name is unique in the input DMS 
    if i_dms != o_dms:
        i=0
        while o_view_name in i_dms:
            o_view_name = o_view_name_final+b"_"+str2bytes(str(i))
            i+=1        

    # Initialize the progress bar
    pb = ProgressBar(len(i_view), config, seconde=5)
    
    keys = config['sort']['keys']
        
    selection = Line_selection(i_view)
    
    for i in range(len(i_view)):  # TODO special function?
        PyErr_CheckSignals()
        selection.append(i)
    
    for k in keys:  # TODO order?
        PyErr_CheckSignals()
        selection.sort(key=lambda line_idx: line_cmp(i_view[line_idx], k, pb(line_idx)), reverse=config['sort']['reverse'])

    pb(len(i_view), force=True)
    print("", file=sys.stderr)

    # Create output view with the sorted line selection
    try:
        o_view = selection.materialize(o_view_name)
    except Exception, e:
        raise RollbackException("obi sort error, rollbacking view: "+str(e), o_view)

    # Save command config in View and DMS comments
    command_line = " ".join(sys.argv[1:])
    input_dms_name=[input[0].name]
    input_view_name=[input[1].name]
    o_view.write_config(config, "sort", command_line, input_dms_name=input_dms_name, input_view_name=input_view_name)
    o_dms.record_command_line(command_line)

    # If input and output DMS are not the same, export the temporary view to the output DMS
    # and delete the temporary view in the input DMS
    if i_dms != o_dms:
        o_view.close()
        View.import_view(i_dms.full_path[:-7], o_dms.full_path[:-7], o_view_name, o_view_name_final)
        o_view = o_dms[o_view_name_final]

    #print("\n\nOutput view:\n````````````", file=sys.stderr)
    #print(repr(o_view), file=sys.stderr)

    # If the input and the output DMS are different, delete the temporary imported view used to create the final view
    if i_dms != o_dms:
        View.delete_view(i_dms, o_view_name)
        o_dms.close()
    i_dms.close()

    logger("info", "Done.")
