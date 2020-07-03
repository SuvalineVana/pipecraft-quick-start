#cython: language_level=3

from ._nws cimport *  

cdef class RightDirectAssemble(NWS):
    cdef double xsmax
    cdef int    xmax

    cdef double doAlignment(self) except? 0
    
cdef class RightReverseAssemble(RightDirectAssemble):    
    pass