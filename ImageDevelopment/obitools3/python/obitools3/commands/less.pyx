#cython: language_level=3

from obitools3.apps.progress cimport ProgressBar  # @UnresolvedImport
from obitools3.uri.decode import open_uri
from obitools3.dms import DMS
from obitools3.utils cimport tobytes
from obitools3.dms.capi.obiview cimport QUALITY_COLUMN
from obitools3.apps.optiongroups import addMinimalInputOption

import sys
import io
from subprocess import Popen, PIPE

from cpython.exc cimport PyErr_CheckSignals

__title__="Less equivalent"


def addOptions(parser):
    
    addMinimalInputOption(parser)


def run(config):
        
    DMS.obi_atexit()
        
    # Open the input
    input = open_uri(config['obi']['inputURI'])
    if input is None:
        raise Exception("Could not read input")
    iview = input[1]
    
    process = Popen(["less"], stdin=PIPE)
    
    for seq in iview :
        PyErr_CheckSignals()
        try:
            process.stdin.write(tobytes(repr(seq)))
            process.stdin.write(b"\n")
        except (StopIteration, BrokenPipeError, IOError):
            break

    sys.stderr.close()
    process.stdin.close()
    process.wait()

    iview.close()
    input[0].close()

