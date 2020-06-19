#cython: language_level=3

from obitools3.apps.progress cimport ProgressBar  # @UnresolvedImport
from obitools3.dms.dms cimport DMS
from obitools3.dms.capi.obidms cimport OBIDMS_p
from obitools3.dms.view import RollbackException
from obitools3.dms.capi.obiecopcr cimport obi_ecopcr
from obitools3.apps.optiongroups import addMinimalInputOption, addMinimalOutputOption, addTaxonomyOption
from obitools3.uri.decode import open_uri
from obitools3.apps.config import logger
from obitools3.utils cimport tobytes
from obitools3.dms.view.typed_view.view_NUC_SEQS cimport View_NUC_SEQS
from obitools3.dms.view import View

from libc.stdlib  cimport malloc, free
from libc.stdint  cimport int32_t

import sys


__title__="in silico PCR"


# TODO: add option to output unique ids
def addOptions(parser):

    addMinimalInputOption(parser)
    addTaxonomyOption(parser)
    addMinimalOutputOption(parser)

 
    group = parser.add_argument_group('obi ecopcr specific options')

    group.add_argument('--primer1', '-F',
                       action="store", dest="ecopcr:primer1",
                       metavar='<PRIMER>',
                       type=str,
                       help="Forward primer.")

    group.add_argument('--primer2', '-R',
                       action="store", dest="ecopcr:primer2",
                       metavar='<PRIMER>',
                       type=str,
                       help="Reverse primer.")

    group.add_argument('--error', '-e',
                       action="store", dest="ecopcr:error",
                       metavar='<ERROR>',
                       default=0,
                       type=int,
                       help="Maximum number of errors (mismatches) allowed per primer. Default: 0.")

    group.add_argument('--min-length', '-l',
                       action="store", 
                       dest="ecopcr:min-length",
                       metavar="<MINIMUM LENGTH>",
                       type=int,
                       default=0,
                       help="Minimum length of the in silico amplified DNA fragment, excluding primers.")
    
    group.add_argument('--max-length', '-L',
                       action="store", 
                       dest="ecopcr:max-length",
                       metavar="<MAXIMUM LENGTH>",
                       type=int,
                       default=0,
                       help="Maximum length of the in silico amplified DNA fragment, excluding primers.")
 
    group.add_argument('--restrict-to-taxid', '-r',
                       action="append", 
                       dest="ecopcr:restrict-to-taxid",
                       metavar="<TAXID>",
                       type=int,
                       default=[],
                       help="Only the sequence records corresponding to the taxonomic group identified "
                            "by TAXID are considered for the in silico PCR. The TAXID is an integer "
                            "that can be found in the NCBI taxonomic database.")
 
    group.add_argument('--ignore-taxid', '-i',
                       action="append", 
                       dest="ecopcr:ignore-taxid",
                       metavar="<TAXID>",
                       type=int,
                       default=[],
                       help="The sequences of the taxonomic group identified by TAXID are not considered for the in silico PCR.")

    group.add_argument('--circular', '-c',
                       action="store_true", 
                       dest="ecopcr:circular",
                       default=False,
                       help="Considers that the input sequences are circular (e.g. mitochondrial or chloroplastic DNA).")

    group.add_argument('--salt-concentration', '-a',
                       action="store", 
                       dest="ecopcr:salt-concentration",
                       metavar="<FLOAT>",
                       type=float,
                       default=0.05,
                       help="Salt concentration used for estimating the Tm. Default: 0.05.")

    group.add_argument('--salt-correction-method', '-m',
                       action="store", 
                       dest="ecopcr:salt-correction-method",
                       metavar="<1|2>",
                       type=int,
                       default=1,
                       help="Defines the method used for estimating the Tm (melting temperature) between the primers and their corresponding "
                            "target sequences. SANTALUCIA: 1, or OWCZARZY: 2. Default: 1.")

    group.add_argument('--keep-primers', '-p',
                       action="store_true", 
                       dest="ecopcr:keep-primers",
                       default=False,
                       help="Whether to keep the primers attached to the output sequences (default: the primers are cut out).")

    group.add_argument('--keep-nucs', '-D',
                       action="store", 
                       dest="ecopcr:keep-nucs",
                       metavar="<N>",
                       type=int,
                       default=0,
                       help="Keeps N nucleotides on each side of the in silico amplified sequences, "
                            "not including the primers (implying that primers are automatically kept if N > 0).")

    group.add_argument('--kingdom-mode', '-k',
                       action="store_true", 
                       dest="ecopcr:kingdom-mode",
                       default=False,
                       help="Print in the output the kingdom of the in silico amplified sequences (default: print the superkingdom).")

 

def run(config):

    cdef int32_t* restrict_to_taxids_p = NULL
    cdef int32_t* ignore_taxids_p = NULL
    
    restrict_to_taxids_len = len(config['ecopcr']['restrict-to-taxid'])
    restrict_to_taxids_p = <int32_t*> malloc((restrict_to_taxids_len + 1) * sizeof(int32_t))   # +1 for the -1 flagging the end of the array
    for i in range(restrict_to_taxids_len) :
        restrict_to_taxids_p[i] = config['ecopcr']['restrict-to-taxid'][i]
    restrict_to_taxids_p[restrict_to_taxids_len] = -1

    ignore_taxids_len = len(config['ecopcr']['ignore-taxid'])
    ignore_taxids_p = <int32_t*> malloc((ignore_taxids_len + 1) * sizeof(int32_t))   # +1 for the -1 flagging the end of the array
    for i in range(ignore_taxids_len) :
        ignore_taxids_p[i] = config['ecopcr']['ignore-taxid'][i]
    ignore_taxids_p[ignore_taxids_len] = -1
    
    DMS.obi_atexit()
    
    logger("info", "obi ecopcr")

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
    o_dms_name = output[0].name
    o_view_name = output[1]

    # Read taxonomy name    
    taxonomy_name = config['obi']['taxoURI'].split("/")[-1]   # Robust in theory
    
    # Save command config in View comments
    command_line = " ".join(sys.argv[1:])
    input_dms_name=[i_dms_name]
    input_view_name= [i_view_name]
    input_dms_name.append(config['obi']['taxoURI'].split("/")[-3])
    input_view_name.append("taxonomy/"+config['obi']['taxoURI'].split("/")[-1])

    comments = View.print_config(config, "ecopcr", command_line, input_dms_name=input_dms_name, input_view_name=input_view_name)

    # TODO: primers in comments?

    if obi_ecopcr(i_dms.name_with_full_path, tobytes(i_view_name), tobytes(taxonomy_name), \
                  o_dms.name_with_full_path, tobytes(o_view_name), comments, \
                  tobytes(config['ecopcr']['primer1']), tobytes(config['ecopcr']['primer2']), \
                  config['ecopcr']['error'], \
                  config['ecopcr']['min-length'], config['ecopcr']['max-length'], \
                  restrict_to_taxids_p, ignore_taxids_p, \
                  config['ecopcr']['circular'], config['ecopcr']['salt-concentration'], config['ecopcr']['salt-correction-method'], \
                  config['ecopcr']['keep-nucs'], config['ecopcr']['keep-primers'], config['ecopcr']['kingdom-mode']) < 0:
        raise Exception("Error running ecopcr")

    # Save command config in DMS comments
    o_dms.record_command_line(command_line)

    free(restrict_to_taxids_p)
    free(ignore_taxids_p)
    
    #print("\n\nOutput view:\n````````````", file=sys.stderr)
    #print(repr(o_dms[o_view_name]), file=sys.stderr)

    o_dms.close()

    logger("info", "Done.")
