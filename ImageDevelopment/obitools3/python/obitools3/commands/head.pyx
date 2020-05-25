#cython: language_level=3

from obitools3.apps.progress cimport ProgressBar  # @UnresolvedImport
from obitools3.dms import DMS
from obitools3.dms.view.view cimport View, Line_selection
from obitools3.uri.decode import open_uri
from obitools3.apps.optiongroups import addMinimalInputOption, addMinimalOutputOption
from obitools3.dms.view import RollbackException
from obitools3.apps.config import logger
from obitools3.utils cimport str2bytes

import time
import sys
 
from cpython.exc cimport PyErr_CheckSignals


__title__="Keep the N first lines of a view."

 
def addOptions(parser):
    
    addMinimalInputOption(parser)
    addMinimalOutputOption(parser)

    group=parser.add_argument_group('obi head specific options')

    group.add_argument('-n', '--sequence-count',
                       action="store", dest="head:count",
                       metavar='<N>',
                       default=10,
                       type=int,
                       help="Number of first records to keep.")

     
def run(config):
     
    DMS.obi_atexit()
    
    logger("info", "obi head")

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
    
    n = min(config['head']['count'], len(i_view))

    # Initialize the progress bar
    pb = ProgressBar(n, config, seconde=5)
        
    selection = Line_selection(i_view)
    
    for i in range(n):
        PyErr_CheckSignals()
        pb(i)
        selection.append(i)

    pb(i, force=True)
    print("", file=sys.stderr)

    # Create output view with the line selection
    try:
        o_view = selection.materialize(o_view_name)
    except Exception, e:
        raise RollbackException("obi head error, rollbacking view: "+str(e), o_view)
    
    # Save command config in DMS comments
    command_line = " ".join(sys.argv[1:])
    o_view.write_config(config, "head", command_line, input_dms_name=[i_dms.name], input_view_name=[i_view.name])
    o_dms.record_command_line(command_line)

    # If input and output DMS are not the same, export the temporary view to the output DMS
    # and delete the temporary view in the input DMS
    if i_dms != o_dms:
        o_view.close()
        View.import_view(i_dms.full_path[:-7], o_dms.full_path[:-7], o_view_name, o_view_name_final)
        o_view = o_dms[o_view_name_final]

    #print("\n\nOutput view:\n````````````", file=sys.stderr)
    #print(repr(view), file=sys.stderr)

    # If the input and the output DMS are different, delete the temporary imported view used to create the final view
    if i_dms != o_dms:
        View.delete_view(i_dms, o_view_name)
        o_dms.close()
    i_dms.close()
    
    logger("info", "Done.")
