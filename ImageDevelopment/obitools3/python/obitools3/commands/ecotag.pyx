#cython: language_level=3

from obitools3.apps.progress cimport ProgressBar  # @UnresolvedImport
from obitools3.dms.dms cimport DMS
from obitools3.dms.view import RollbackException
from obitools3.dms.capi.obiecotag cimport obi_ecotag
from obitools3.apps.optiongroups import addMinimalInputOption, addTaxonomyOption, addMinimalOutputOption
from obitools3.uri.decode import open_uri
from obitools3.apps.config import logger
from obitools3.utils cimport tobytes, str2bytes
from obitools3.dms.view.view cimport View
from obitools3.dms.view.typed_view.view_NUC_SEQS cimport View_NUC_SEQS

import sys


__title__="Taxonomic assignment of sequences"


def addOptions(parser):

    addMinimalInputOption(parser)
    addTaxonomyOption(parser)
    addMinimalOutputOption(parser)
 
    group = parser.add_argument_group('obi ecotag specific options')

    group.add_argument('--ref-database','-R',
                      action="store", dest="ecotag:ref_view",
                      metavar='<REF_VIEW>',
                      type=str,
                      help="URI of the view containing the reference database as built by the build_ref_db command.")

    group.add_argument('--minimum-identity','-m',
                      action="store", dest="ecotag:threshold",
                      metavar='<THRESHOLD>',
                      default=0.0,
                      type=float,
                      help="Minimum identity to consider for assignment, as a normalized identity, e.g. 0.95 for an identity of 95%%. "
                           "Default: 0.00 (no threshold).")

def run(config):
        
    DMS.obi_atexit()
    
    logger("info", "obi ecotag")

    # Open the query view: only the DMS
    input = open_uri(config['obi']['inputURI'],
                     dms_only=True)
    if input is None:
        raise Exception("Could not read input")
    i_dms = input[0]
    i_dms_name = input[0].name
    i_view_name = input[1]

    # Open the reference view: only the DMS
    ref = open_uri(config['ecotag']['ref_view'],
                     dms_only=True)
    if ref is None:
        raise Exception("Could not read reference view URI")
    ref_dms = ref[0]
    ref_dms_name = ref[0].name
    ref_view_name = ref[1]

    # Check that the threshold demanded is greater than or equal to the threshold used to build the reference database
    if config['ecotag']['threshold'] < eval(i_dms[ref_view_name].comments["ref_db_threshold"]) :
        print("Error: The threshold demanded (%f) is lower than the threshold used to build the reference database (%f).", 
              config['ecotag']['threshold'], i_dms[ref_view_name].comments["ref_db_threshold"])

    # Open the output: only the DMS
    output = open_uri(config['obi']['outputURI'],
                      input=False,
                      dms_only=True)
    if output is None:
        raise Exception("Could not create output")
    o_dms = output[0]
    final_o_view_name = output[1]
    
    # If the input and output DMS are not the same, run ecotag creating a temporary view that will be exported to 
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

    # Read taxonomy DMS and name
    taxo = open_uri(config['obi']['taxoURI'],
                    dms_only=True)
    taxo_dms_name = taxo[0].name
    taxo_dms = taxo[0]
    taxonomy_name = config['obi']['taxoURI'].split("/")[-1]   # Robust in theory

    # Save command config in View comments
    command_line = " ".join(sys.argv[1:])
    input_dms_name=[i_dms_name]
    input_view_name= [i_view_name]
    input_dms_name.append(ref_dms_name)
    input_view_name.append(ref_view_name)
    input_dms_name.append(config['obi']['taxoURI'].split("/")[-3])
    input_view_name.append("taxonomy/"+config['obi']['taxoURI'].split("/")[-1])
    comments = View.print_config(config, "ecotag", command_line, input_dms_name=input_dms_name, input_view_name=input_view_name)

    if obi_ecotag(i_dms.name_with_full_path, tobytes(i_view_name), \
                  tobytes(ref_dms_name), tobytes(ref_view_name), \
                  tobytes(taxo_dms_name), tobytes(taxonomy_name), \
                  tobytes(o_view_name), comments, 
                  config['ecotag']['threshold']) < 0:
        raise Exception("Error running ecotag")
    
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

