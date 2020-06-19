#cython: language_level=3


from obitools3.uri.decode import open_uri
from obitools3.apps.config import logger
from obitools3.dms import DMS
from obitools3.apps.optiongroups import addMinimalInputOption
from obitools3.dms.capi.obiview cimport COUNT_COLUMN

from cpython.exc cimport PyErr_CheckSignals


__title__="Counts sequence records"

 
def addOptions(parser):
 
    addMinimalInputOption(parser)
 
    group = parser.add_argument_group('obi count specific options')
 
    group.add_argument('-s','--sequence',
                        action="store_true", dest="count:sequence",
                        default=False,
                        help="Prints only the number of sequence records.")
 
    group.add_argument('-a','--all',
                        action="store_true", dest="count:all",
                        default=False,
                        help="Prints only the total count of sequence records (if a sequence has no `count` attribute, its default count is 1) (default: False).")

    
def run(config):
    
    DMS.obi_atexit()
    
    logger("info", "obi count")

    # Open the input
    input = open_uri(config['obi']['inputURI'])
    if input is None:
        raise Exception("Could not read input")
    entries = input[1]

    count1 = len(entries)
    count2 = 0
    
    if COUNT_COLUMN in entries and ((config['count']['sequence'] == config['count']['all']) or (config['count']['all'])) :
        for e in entries:
            PyErr_CheckSignals()
            count2+=e[COUNT_COLUMN]

    if COUNT_COLUMN in entries and (config['count']['sequence'] == config['count']['all']):
        print(count1,count2)
    elif COUNT_COLUMN in entries and config['count']['all']:
        print(count2)
    else:
        print(count1)
