#cython: language_level=3

from obitools3.apps.progress cimport ProgressBar  # @UnresolvedImport
from obitools3.uri.decode import open_uri
from obitools3.apps.config import logger
from obitools3.dms import DMS
from obitools3.dms.obiseq import Nuc_Seq
from obitools3.dms.capi.obiview cimport QUALITY_COLUMN

from obitools3.apps.optiongroups import addMinimalInputOption, \
                                        addExportOutputOption, \
                                        addNoProgressBarOption

import sys
import io

from cpython.exc cimport PyErr_CheckSignals

__title__="Export a view to a different file format"


def addOptions(parser):
    
    addMinimalInputOption(parser)
    addExportOutputOption(parser)
    addNoProgressBarOption(parser)


def run(config):
        
    DMS.obi_atexit()
    
    logger("info", "obi export : exports a view to a different file format")
    
    # Open the input
    input = open_uri(config['obi']['inputURI'])
    if input is None:
        raise Exception("Could not read input")
    iview = input[1]
    
    if 'outputformat' not in config['obi']:
        if iview.type == b"NUC_SEQS_VIEW":
            if QUALITY_COLUMN in iview:
                config['obi']['outputformat'] = b'fastq'
            else:
                config['obi']['outputformat'] = b'fasta'
        else:
            config['obi']['outputformat'] = b'tabular'
    
    # Open the output
    output = open_uri(config['obi']['outputURI'],
                      input=False)
    if output is None:
        raise Exception("Could not open output URI")

    output_object = output[0]
    writer = output[1]
        
     # Check that the input view has the type NUC_SEQS if needed    # TODO discuss, maybe bool property
    if (output[2] == Nuc_Seq) and (iview.type != b"NUC_SEQS_VIEW") :  # Nuc_Seq_Stored? TODO
        raise Exception("Error: the view to export in fasta or fastq format is not a NUC_SEQS view")
   
    # Initialize the progress bar
    if config['obi']['noprogressbar']:
        pb = None
    else:
        pb = ProgressBar(len(iview), config, seconde=5)
    
    i=0
    for seq in iview :
        PyErr_CheckSignals()
        if pb is not None:
            pb(i)
        try:
            writer(seq)
        except (StopIteration, BrokenPipeError, IOError):
            break
        i+=1

    if pb is not None:
        pb(i, force=True)
    print("", file=sys.stderr)

    # TODO save command in input dms?
    
    if not BrokenPipeError and not IOError:
        output_object.close()
    iview.close()
    input[0].close()

    logger("info", "Done.")

    if BrokenPipeError or IOError:
        sys.stderr.close()
