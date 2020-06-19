#cython: language_level=3

from ._dynamic cimport *

cdef class NWS(DynamicProgramming):
    cdef double _match
    cdef double _mismatch
    
    cdef double matchScore(self,int h, int v)
    cdef double doAlignment(self) except? 0

             
