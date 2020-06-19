#cython: language_level=3

'''
Created on 25 mars 2016

@author: coissac
'''

from urllib.request import urlopen
from obitools3.utils cimport tostr


cpdef CompressedFile uopen(object name, mode='rb'):
    cdef CompressedFile c
    
    try:
        f = urlopen(tostr(name))
    except:
        f = open(tostr(name),mode) 
        
    c = CompressedFile(f)
    
    return c
    