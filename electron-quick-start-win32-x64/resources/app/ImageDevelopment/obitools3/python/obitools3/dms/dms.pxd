#cython: language_level=3
                                
from .object cimport OBIWrapper

from .capi.obidms cimport OBIDMS_p


cdef class DMS(OBIWrapper):

    cdef inline OBIDMS_p pointer(self)
    cpdef int view_count(self)


cdef class DMS_comments(dict):
    cdef DMS _dms
