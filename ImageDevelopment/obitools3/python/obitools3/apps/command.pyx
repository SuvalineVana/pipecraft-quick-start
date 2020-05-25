#cython: language_level=3

'''
Created on 27 mars 2016

@author: coissac
'''

import pkgutil

from obitools3 import commands

cdef object loadCommand(str name,loader):
    '''
    Load a command module from its name and an ImpLoader
    
    This function is for internal use
    
    @param name:   name of the module
    @type name: str 
    @param loader: the module loader
    @type loader: ImpLoader
    
    @return the loaded module
    @rtype: module 
    '''
    
    module = loader.find_module(name).load_module(name)
    return module

def getCommandsList():
    '''
    Returns the list of sub-commands available to the main `obi` command
    
    @return: a dict instance with key corresponding to each command and
             value corresponding to the module
             
    @rtype: dict
    '''
    
    cdef dict cmds = dict((x[1],loadCommand(x[1],x[0])) 
                           for x in pkgutil.iter_modules(commands.__path__) 
                           if not x[2])
    return cmds
