#cython: language_level=3

'''
Created on 25 mars 2016

@author: coissac
'''

from obitools3.utils cimport __etag__
import re


__ret__  = re.compile(b'''(([^ ]+)=('[^']*'|"[^"]*"|[^;]+); *)+?''')


cpdef tuple parseHeader(bytes header, bytes nastring=b"NA"):
    cdef list  m 
    cdef dict  tags 
    cdef bytes definition
    cdef bytes ident
    cdef bytes second
    
    m=header[1:-1].split(maxsplit=1)
   
    ident=m[0]
    if len(ident)>1 and ident[-2:-1] == b';':
        ident = ident[:-1]
    
    if len(m)==1:
        tags={}
        definition=b'' 
    else:
        second=m[1]
        m = __ret__.findall(second)
        
        if m:
            tags = dict([(a[1],__etag__(a[2], nastring=nastring)) for a in m])
            definition = second.split(m[-1][0],1)[1].strip()
        else:
            tags = {}
            definition = second.strip() 
        
    return ident,tags,definition
    

