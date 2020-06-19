#cython: language_level=3

from ._nws cimport *  

cdef class FreeEndGap(NWS):
    cdef double xsmax
    cdef int    xmax
    

    cdef double doAlignment(self) except? 0
    
