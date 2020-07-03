#cython: language_level=3

'''
Created on 27 mars 2016

@author: coissac
'''

import sys

from .command   import  getCommandsList
from .logging   cimport getLogger
from .arguments cimport buildArgumentParser

from ..version import version


cdef dict __default_config__ = {}


cpdef str setRootConfigName(str rootname):
    global __default_config__
    if '__root_config__' in __default_config__:
        if __default_config__["__root_config__"] in __default_config__:
            __default_config__[rootname]=__default_config__[__default_config__["__root_config__"]]
            del __default_config__[__default_config__["__root_config__"]]
    __default_config__['__root_config__']=rootname
    return rootname

cpdef str getRootConfigName():
    global __default_config__
    return __default_config__.get('__root_config__',None)

cdef dict buildDefaultConfiguration(str root_config_name,
                                    dict  config):
    global __default_config__
    
    __default_config__.clear()
    setRootConfigName(root_config_name)    

    __default_config__[root_config_name]=config
    
    config['version']=version
    
    commands = getCommandsList()
    
    for c in commands:
        module = commands[c]
    
        assert hasattr(module, "run")
        
        if hasattr(module, 'default_config'):
            __default_config__[c]=module.default_config
        else:
            __default_config__[c]={}
                        
    return __default_config__
        

cpdef dict getConfiguration(str root_config_name="__default__",
                            dict  config={}):
    global __default_config__

    if '__done__' in __default_config__:
        return __default_config__
    
    if root_config_name=="__default__":
        raise RuntimeError("No root_config_name specified")
    
    if not config:
        raise RuntimeError("Base configuration is empty")
    
    
    
    config =  buildDefaultConfiguration(root_config_name,
                                        config)
    
    parser = buildArgumentParser(root_config_name,
                                 config[root_config_name]['software'])
    
    options = vars(parser.parse_args())

    if options['%s:version' % root_config_name]:
        print("%s - Version %s" % (config[root_config_name]['software'],
                                   config[root_config_name]['version']))
        sys.exit(0)
    
    for k in options:
        section,key = k.split(':')
        s = config[section]
        if options[k] is not None:
            s[key]=options[k]
            
    if not 'module' in config[root_config_name]:
        print('\nError: No command specified',file=sys.stderr)
        parser.print_help()
        sys.exit(2)
                
    getLogger(config)
    
    config['__done__']=True
            
    return config

def logger(level, *messages):
    try:
        config=getConfiguration()
        root = config["__root_config__"]
        l = config[root]['logger']
        if config[root]['verbose']:
            getattr(l, level)(*messages)
    except:
        print(*messages,file=sys.stderr)

