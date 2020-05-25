#cython: language_level=3

from obitools3.apps.progress cimport ProgressBar  # @UnresolvedImport
from obitools3.dms import DMS
from obitools3.dms.view.view cimport View, Line_selection
from obitools3.uri.decode import open_uri
from obitools3.apps.optiongroups import addMinimalInputOption, addTaxonomyOption, addMinimalOutputOption
from obitools3.dms.view import RollbackException
from functools import reduce
from obitools3.apps.config import logger
from obitools3.utils cimport tobytes, str2bytes
from obitools3.dms.capi.obiview cimport NUC_SEQUENCE_COLUMN, \
                                        ID_COLUMN, \
                                        DEFINITION_COLUMN, \
                                        QUALITY_COLUMN, \
                                        COUNT_COLUMN

import time
import math 
import sys

from cpython.exc cimport PyErr_CheckSignals

 
__title__="Annotate views with new tags and edit existing annotations"


SPECIAL_COLUMNS = [NUC_SEQUENCE_COLUMN, ID_COLUMN, DEFINITION_COLUMN, QUALITY_COLUMN]

 
def addOptions(parser):
    
    addMinimalInputOption(parser)
    addTaxonomyOption(parser)
    addMinimalOutputOption(parser)

    group=parser.add_argument_group('obi annotate specific options')
 
    group.add_argument('--seq-rank',   # TODO seq/elt/line???
                       action="store_true", 
                       dest="annotate:add_rank",
                       default=False,
                       help="Add a rank attribute to the sequence "
                            "indicating the sequence position in the data.")
 
    group.add_argument('-R', '--rename-tag',
                       action="append", 
                       dest="annotate:rename_tags",
                       metavar="<OLD_NAME:NEW_NAME>",
                       type=str,
                       default=[],
                       help="Change tag name from OLD_NAME to NEW_NAME.")

    group.add_argument('-D', '--delete-tag',
                       action="append", 
                       dest="annotate:delete_tags",
                       metavar="<TAG_NAME>",
                       type=str,
                       default=[],
                       help="Delete tag TAG_NAME.")

    group.add_argument('-S', '--set-tag',
                       action="append", 
                       dest="annotate:set_tags",
                       metavar="<TAG_NAME:PYTHON_EXPRESSION>",
                       type=str,
                       default=[],
                       help="Add a new tag named TAG_NAME with "
                            "a value computed from PYTHON_EXPRESSION.")

    group.add_argument('--set-identifier',
                       action="store", 
                       dest="annotate:set_identifier",
                       metavar="<PYTHON_EXPRESSION>",
                       type=str,
                       default=None,
                       help="Set sequence identifier with "
                            "a value computed from PYTHON_EXPRESSION.")
    
    group.add_argument('--set-sequence',
                       action="store", 
                       dest="annotate:set_sequence",
                       metavar="<PYTHON_EXPRESSION>",
                       type=str,
                       default=None,
                       help="Change the sequence itself with "
                            "a value computed from PYTHON_EXPRESSION.")

    group.add_argument('--set-definition',
                       action="store", 
                       dest="annotate:set_definition",
                       metavar="<PYTHON_EXPRESSION>",
                       type=str,
                       default=None,
                       help="Set sequence definition with "
                            "a value computed from PYTHON_EXPRESSION.")

    group.add_argument('--run',
                       action="store", 
                       dest="annotate:run",
                       metavar="<PYTHON_EXPRESSION>",
                       type=str,
                       default=None,
                       help="Run a python expression on each element.")

    group.add_argument('-C', '--clear',
                       action="store_true", 
                       dest="annotate:clear",
                       default=False,
                       help="Clear all tags except the obligatory ones.")
    
    group.add_argument('-k','--keep',
                       action='append',
                       dest="annotate:keep",
                       metavar="<TAG>",
                       default=[],
                       type=str,
                       help="Only keep this tag. (Can be specified several times.)")
    
    group.add_argument('--length',
                       action="store_true", 
                       dest="annotate:length",
                       default=False,
                       help="Add 'seq_length' tag with sequence length.")
    
    group.add_argument('--with-taxon-at-rank',
                       action='append',
                       dest="annotate:taxon_at_rank",
                       metavar="<RANK_NAME>",
                       default=[],
                       type=str,
                       help="Add taxonomy annotation at the specified rank level RANK_NAME.")


def sequenceTaggerGenerator(config, taxo=None):
    
    toSet=None
    newId=None
    newDef=None
    newSeq=None
    length=None
    add_rank=None
    run=None
    
    if 'set_tags' in config['annotate']:   # TODO default option problem, to fix
        toSet = [x.split(':',1) for x in config['annotate']['set_tags'] if len(x.split(':',1))==2]
    if 'set_identifier' in config['annotate']:
        newId = config['annotate']['set_identifier']
    if 'set_definition' in config['annotate']:
        newDef = config['annotate']['set_definition']
    if 'set_sequence' in config['annotate']:
        newSeq = config['annotate']['set_sequence']
    if 'length' in config['annotate']:
        length = config['annotate']['length']
    if 'add_rank' in config["annotate"]:
        add_rank = config["annotate"]["add_rank"]
    if 'run' in config['annotate']:
        run = config['annotate']['run']
    counter = [0]
    
    for i in range(len(toSet)):
        for j in range(len(toSet[i])):
            toSet[i][j] = tobytes(toSet[i][j])

    annoteRank=[]
    if config['annotate']['taxon_at_rank']:
        if taxo is not None:
            annoteRank = config['annotate']['taxon_at_rank']
        else:
            raise Exception("A taxonomy must be provided to annotate taxon ranks")
    
    def sequenceTagger(seq):
                
        if counter[0]>=0:
            counter[0]+=1
                            
        for rank in annoteRank:
            if 'taxid' in seq:
                taxid = seq['taxid']
                if taxid is not None:
                    rtaxid = taxo.get_taxon_at_rank(taxid, rank)
                    if rtaxid is not None:
                        scn = taxo.get_scientific_name(rtaxid)
                    else:
                        scn=None
                    seq[rank]=rtaxid
                    seq["%s_name"%rank]=scn
             
        if add_rank:
            seq['seq_rank']=counter[0]
    
        for i,v in toSet:
            #try:
            if taxo is not None:
                environ = {'taxonomy' : taxo, 'sequence':seq, 'counter':counter[0], 'math':math}
            else:
                environ = {'sequence':seq, 'counter':counter[0], 'math':math}
            val = eval(v, environ, seq)
            #except Exception,e:       # TODO discuss usefulness of this
            #    if options.onlyValid:
            #        raise e
            #    val = v
            seq[i]=val

        if length:
            seq['seq_length']=len(seq)

        if newId is not None:
#            try:
            if taxo is not None:
                environ = {'taxonomy' : taxo, 'sequence':seq, 'counter':counter[0], 'math':math}
            else:
                environ = {'sequence':seq, 'counter':counter[0], 'math':math}     
            val = eval(newId, environ, seq)
#            except Exception,e:
#                if options.onlyValid:
#                    raise e
#                val = newId
            seq.id=val

        if newDef is not None:
#            try:
            if taxo is not None:
                environ = {'taxonomy' : taxo, 'sequence':seq, 'counter':counter[0], 'math':math}
            else:
                environ = {'sequence':seq, 'counter':counter[0], 'math':math}     
            val = eval(newDef, environ, seq)
#            except Exception,e:
#                if options.onlyValid:
#                    raise e
#                val = newDef
            seq.definition=val
#             
        if newSeq is not None:
#            try:
            if taxo is not None:
                environ = {'taxonomy' : taxo, 'sequence':seq, 'counter':counter[0], 'math':math}
            else:
                environ = {'sequence':seq, 'counter':counter[0], 'math':math}     
            val = eval(newSeq, environ, seq)
#            except Exception,e:
#                if options.onlyValid:
#                    raise e
#                val = newSeq
            seq.seq=val
            if 'seq_length' in seq:
                seq['seq_length']=len(seq)
            # Delete quality since it must match the sequence.
            # TODO discuss deleting for each sequence separately
            if QUALITY_COLUMN in seq:
                seq.view.delete_column(QUALITY_COLUMN)
                    
        if run is not None:
#            try:
            if taxo is not None:
                environ = {'taxonomy' : taxo, 'sequence':seq, 'counter':counter[0], 'math':math}
            else:
                environ = {'sequence':seq, 'counter':counter[0], 'math':math}     
            eval(run, environ, seq)
#            except Exception,e:
#                if options.onlyValid:
#                    raise e

    return sequenceTagger


def run(config):
     
    DMS.obi_atexit()
    
    logger("info", "obi annotate")

    # Open the input
    input = open_uri(config['obi']['inputURI'])
    if input is None:
        raise Exception("Could not read input view")
    i_dms = input[0]
    i_view = input[1]
    i_view_name = input[1].name

    # Open the output: only the DMS, as the output view is going to be created by cloning the input view
    # (could eventually be done via an open_uri() argument)
    output = open_uri(config['obi']['outputURI'],
                      input=False,
                      dms_only=True)
    if output is None:
        raise Exception("Could not create output view")
    o_dms = output[0]
    o_view_name = output[1]
    
    # If the input and output DMS are not the same, import the input view in the output DMS before cloning it to modify it
    # (could be the other way around: clone and modify in the input DMS then import the new view in the output DMS)
    if i_dms != o_dms:
        imported_view_name = i_view_name
        i=0
        while imported_view_name in o_dms:  # Making sure view name is unique in output DMS
            imported_view_name = i_view_name+b"_"+str2bytes(str(i))
            i+=1
        View.import_view(i_dms.full_path[:-7], o_dms.full_path[:-7], i_view_name, imported_view_name)
        i_view = o_dms[imported_view_name]
        
    # Clone output view from input view
    o_view = i_view.clone(o_view_name)
    if o_view is None:
        raise Exception("Couldn't create output view")
    i_view.close()

    # Open taxonomy if there is one
    if 'taxoURI' in config['obi'] and config['obi']['taxoURI'] is not None:
        taxo_uri = open_uri(config['obi']['taxoURI'])
        if taxo_uri is None or taxo_uri[2] == bytes:
            raise Exception("Couldn't open taxonomy")
        taxo = taxo_uri[1]
    else :
        taxo = None

    # Initialize the progress bar
    pb = ProgressBar(len(o_view), config, seconde=5)

    try:

        # Apply editions
        # Editions at view level
        if 'delete_tags' in config['annotate']:
            toDelete = config['annotate']['delete_tags'][:]
        if 'rename_tags' in config['annotate']:
            toRename = [x.split(':',1) for x in config['annotate']['rename_tags'] if len(x.split(':',1))==2]
        if 'clear' in config['annotate']:
            clear = config['annotate']['clear']
        if 'keep' in config['annotate']:
            keep = config['annotate']['keep']
        for i in range(len(toDelete)):
            toDelete[i] = tobytes(toDelete[i])
        for i in range(len(toRename)):
            for j in range(len(toRename[i])):
                toRename[i][j] = tobytes(toRename[i][j])
        for i in range(len(keep)):
            keep[i] = tobytes(keep[i])
        keep = set(keep)
    
        if clear or keep:
            keys = [k for k in o_view.keys()]
            for k in keys:
                if k not in keep and k not in SPECIAL_COLUMNS:
                    o_view.delete_column(k)
        else:
            for k in toDelete:
                o_view.delete_column(k)
            for old_name, new_name in toRename:
                if old_name in o_view:
                    o_view.rename_column(old_name, new_name)
        
        # Editions at line level
        sequenceTagger = sequenceTaggerGenerator(config, taxo=taxo)
        for i in range(len(o_view)):
            PyErr_CheckSignals()
            pb(i)
            sequenceTagger(o_view[i])

    except Exception, e:
        raise RollbackException("obi annotate error, rollbacking view: "+str(e), o_view)

    pb(i, force=True)
    print("", file=sys.stderr)
    
    # Save command config in View and DMS comments
    command_line = " ".join(sys.argv[1:])
    input_dms_name=[input[0].name]
    input_view_name=[i_view_name]
    if 'taxoURI' in config['obi'] and config['obi']['taxoURI'] is not None:
        input_dms_name.append(config['obi']['taxoURI'].split("/")[-3])
        input_view_name.append("taxonomy/"+config['obi']['taxoURI'].split("/")[-1])
    o_view.write_config(config, "annotate", command_line, input_dms_name=input_dms_name, input_view_name=input_view_name)
    output[0].record_command_line(command_line)

    #print("\n\nOutput view:\n````````````", file=sys.stderr)
    #print(repr(o_view), file=sys.stderr)

    # If the input and the output DMS are different, delete the temporary imported view used to create the final view
    if i_dms != o_dms:
        View.delete_view(o_dms, imported_view_name)
        o_dms.close()
    i_dms.close()

    logger("info", "Done.")
