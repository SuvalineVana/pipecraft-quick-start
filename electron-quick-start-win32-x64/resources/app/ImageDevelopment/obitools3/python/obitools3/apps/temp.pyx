#cython: language_level=3

'''
Created on 28 juillet 2017

@author: coissac
'''

from os import environb,getpid
from os.path import join, isdir
from tempfile import TemporaryDirectory, _get_candidate_names
from shutil import rmtree
from atexit import register

from obitools3.dms.dms import DMS

from obitools3.apps.config import getConfiguration
from obitools3.apps.config import logger

cpdef get_temp_dir():
    """
    Returns a temporary directory object specific of this instance of obitools.
    
    This is an application function. It cannot be called out of an obi command.
    It requires a valid configuration.
    
    If the function is called several time from the same obi session, the same
    directory is returned.
    
    If the OBITMP environment variable exist, the temporary directory is created
    inside this directory.
    
    The directory is automatically destroyed at the end of the end of the process.
    
        @return: a temporary python directory object.
    """
    cdef bytes tmpdirname
    cdef dict config = getConfiguration()

    root = config["__root_config__"]
    
    try:
        return config[root]["tempdir"].name
    except KeyError:
        pass
    
    try:
        basedir=environb[b'OBITMP']
    except KeyError:
        basedir=None
    
    tmp = TemporaryDirectory(dir=basedir)
        
    config[root]["tempdir"]=tmp
    
    return tmp.name
 
cpdef get_temp_dir_name():
    """
    Returns the name of the  temporary directory object 
    specific of this instance of obitools.
    
        @return: the name of the temporary directory.
        
        @see get_temp_dir
    """
    return get_temp_dir_name().name
          
               
cpdef get_temp_dms():

    cdef bytes tmpdirname                   # @DuplicatedSignature
    cdef dict config = getConfiguration()   # @DuplicatedSignature
    cdef DMS tmpdms
    
    root = config["__root_config__"]
    
    try:
        return config[root]["tempdms"]
    except KeyError:
        pass

    tmpdirname=get_temp_dir()
        
    tempname = join(tmpdirname,
                    b"obi.%d.%s" % (getpid(),
                                    tobytes(next(_get_candidate_names())))
                   )
        
    tmpdms = DMS.new(tempname)
    
    config[root]["tempdms"]=tmpdms
    
    return tmpdms
    
    
