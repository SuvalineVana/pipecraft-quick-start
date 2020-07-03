#cython: language_level=3

from ._freeendgap cimport *  

cdef class FreeEndGapFullMatch(FreeEndGap):
    cdef double matchScore(self,int h, int v)
    
