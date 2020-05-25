#cython: language_level=3

from ._nws cimport *  

cdef class DirectAssemble(NWS):
    cdef double ysmax
    cdef int    ymax

    cdef double doAlignment(self) except? 0
    
cdef class ReverseAssemble(DirectAssemble):    
    pass