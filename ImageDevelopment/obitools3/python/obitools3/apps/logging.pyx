#cython: language_level=3

'''
Created on 27 mars 2016

@author: coissac
'''

import logging
import sys

cpdef getLogger(dict config):
    '''
    Returns the logger as defined by the command line option
    or by the config file
    :param config:
    '''
    
    root = config["__root_config__"]
 
    level  = config[root]['loglevel'] 
    logfile= config[root]['log'] 
    
    rootlogger   = logging.getLogger()
    logFormatter = logging.Formatter("%%(asctime)s [%s : %%(levelname)-5.5s]  %%(message)s" % config[root]['modulename'])

    stderrHandler = logging.StreamHandler(sys.stderr)
    stderrHandler.setFormatter(logFormatter)

    rootlogger.addHandler(stderrHandler)
    
    if logfile:
        fileHandler = logging.FileHandler(logfile)
        fileHandler.setFormatter(logFormatter)
        rootlogger.addHandler(fileHandler)
    
    try:
        loglevel = getattr(logging, level) 
    except:
        loglevel = logging.INFO
        
    rootlogger.setLevel(loglevel)
    
    config[root]['logger']=rootlogger
    config[root]['verbose']=True
        
    return rootlogger

