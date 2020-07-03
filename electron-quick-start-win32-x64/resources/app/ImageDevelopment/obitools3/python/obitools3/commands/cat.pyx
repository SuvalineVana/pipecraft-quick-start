#cython: language_level=3

from obitools3.apps.progress cimport ProgressBar  # @UnresolvedImport
from obitools3.dms import DMS
from obitools3.dms.view.view cimport View
from obitools3.uri.decode import open_uri
from obitools3.apps.optiongroups import addMinimalOutputOption
from obitools3.dms.view import RollbackException
from obitools3.apps.config import logger
from obitools3.utils cimport str2bytes
from obitools3.dms.view.typed_view.view_NUC_SEQS cimport View_NUC_SEQS
from obitools3.dms.view.view cimport View
from obitools3.dms.capi.obiview cimport NUC_SEQUENCE_COLUMN, REVERSE_SEQUENCE_COLUMN, \
                                        QUALITY_COLUMN, REVERSE_QUALITY_COLUMN
from obitools3.dms.capi.obitypes cimport OBI_SEQ, OBI_QUAL
from obitools3.dms.column.column cimport Column

import time
import sys
 
from cpython.exc cimport PyErr_CheckSignals


__title__="Concatenate views."

 
def addOptions(parser):
    
    addMinimalOutputOption(parser)

    group=parser.add_argument_group('obi cat specific options')

    group.add_argument("-c",
                       action="append", dest="cat:views_to_cat",
                       metavar="<VIEW_NAME>",
                       default=[],
                       type=str,
                       help="URI of a view to concatenate. (e.g. 'my_dms/my_view'). "
                            "Several -c options can be used on the same "
                            "command line.")

     
def run(config):
     
    DMS.obi_atexit()
    
    logger("info", "obi cat")

    # Open the views to concatenate
    iview_list = []
    idms_list = []
    total_len = 0
    remove_qual = False
    remove_rev_qual = False
    v_type = View_NUC_SEQS
    for v_uri in config["cat"]["views_to_cat"]:
        input = open_uri(v_uri)
        if input is None:
            raise Exception("Could not read input view")
        i_dms = input[0]
        i_view = input[1]
        if input[2] != View_NUC_SEQS:  # Check view type (output view is nuc_seqs view if all input view are nuc_seqs view)
            v_type = View
        if QUALITY_COLUMN not in i_view: # Check if keep quality column in output view (if all input views have it)
            remove_qual = True
        if REVERSE_QUALITY_COLUMN not in i_view: # same as above for reverse quality
            remove_rev_qual = True
        total_len += len(i_view)
        iview_list.append(i_view)
        idms_list.append(i_dms)

    # Open the output: only the DMS
    output = open_uri(config['obi']['outputURI'],
                      input=False, 
                      newviewtype=v_type)
    if output is None:
        raise Exception("Could not create output view")
    o_dms = output[0]
    o_view = output[1]
    
    # Initialize quality columns and their associated sequence columns if needed
    if not remove_qual:
        if NUC_SEQUENCE_COLUMN not in o_view:
            Column.new_column(o_view, NUC_SEQUENCE_COLUMN, OBI_SEQ)
        Column.new_column(o_view, QUALITY_COLUMN, OBI_QUAL, associated_column_name=NUC_SEQUENCE_COLUMN, associated_column_version=o_view[NUC_SEQUENCE_COLUMN].version)    
    if not remove_rev_qual:
        Column.new_column(o_view, REVERSE_SEQUENCE_COLUMN, OBI_SEQ)
        Column.new_column(o_view, REVERSE_QUALITY_COLUMN, OBI_QUAL, associated_column_name=REVERSE_SEQUENCE_COLUMN, associated_column_version=o_view[REVERSE_SEQUENCE_COLUMN].version)
        
    # Initialize multiple elements columns
    dict_cols = {}
    for v in iview_list:
        for coln in v.keys():
            if v[coln].nb_elements_per_line > 1:
                if coln not in dict_cols:
                    dict_cols[coln] = {}
                    dict_cols[coln]['eltnames'] = set(v[coln].elements_names)
                    dict_cols[coln]['nbelts'] = v[coln].nb_elements_per_line
                    dict_cols[coln]['obitype'] = v[coln].data_type_int
                else:
                    dict_cols[coln]['eltnames'] = set(v[coln].elements_names + list(dict_cols[coln]['eltnames']))
                    dict_cols[coln]['nbelts'] = len(dict_cols[coln]['eltnames'])
    for coln in dict_cols:
        Column.new_column(o_view, coln, dict_cols[coln]['obitype'], 
                          nb_elements_per_line=dict_cols[coln]['nbelts'], elements_names=list(dict_cols[coln]['eltnames']))
    
    # Initialize the progress bar
    pb = ProgressBar(total_len, config, seconde=5)
    
    i = 0
    for v in iview_list:
        for l in v:
            PyErr_CheckSignals()
            pb(i)
            o_view[i] = l
            i+=1

    # Deletes quality columns if needed
    if QUALITY_COLUMN in o_view and remove_qual :
        o_view.delete_column(QUALITY_COLUMN)
    if REVERSE_QUALITY_COLUMN in o_view and remove_rev_qual :
        o_view.delete_column(REVERSE_QUALITY_COLUMN)

    pb(i, force=True)
    print("", file=sys.stderr)
    
    # Save command config in DMS comments
    command_line = " ".join(sys.argv[1:])
    o_view.write_config(config, "cat", command_line, input_dms_name=[d.name for d in idms_list], input_view_name=[v.name for v in iview_list])
    o_dms.record_command_line(command_line)

    #print("\n\nOutput view:\n````````````", file=sys.stderr)
    #print(repr(view), file=sys.stderr)

    for d in idms_list:
        d.close()
    o_dms.close()
    
    logger("info", "Done.")
