#cython: language_level=3

from obitools3.apps.optiongroups import addMinimalInputOption
from obitools3.uri.decode import open_uri
from obitools3.dms import DMS
from obitools3.dms.capi.obidms cimport obi_clean_dms
from obitools3.apps.config import logger
from obitools3.utils cimport tobytes

 
__title__="Clean a DMS from unfinished views and columns"
 

def addOptions(parser):
    addMinimalInputOption(parser)
  

def run(config):
    
    DMS.obi_atexit()
    
    logger("info", "obi clean_dms")
    
    dms_path = tobytes(config['obi']['inputURI'])
    if b'.obidms' in dms_path:
        dms_path = dms_path.split(b'.obidms')[0]
    if obi_clean_dms(dms_path) < 0 :
        raise Exception("Error cleaning DMS", config['obi']['inputURI'])

    logger("info", "Done.")
