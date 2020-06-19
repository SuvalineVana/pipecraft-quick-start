#cython: language_level=3


cdef dict __c_cython_mapping__


cdef class OBIObject:

    cdef dict _dependent_objects
   
    cdef register(self, OBIObject object)
    cdef unregister(self, OBIObject object)


cdef class OBIWrapper(OBIObject):
    
    cdef void*  _pointer
    
    cdef inline size_t cid(self)    
    cdef inline bint active(self)
    
    @staticmethod
    cdef object new_wrapper(type constructor, void* pointer)


cdef class OBIDeactivatedInstanceError(Exception):
    pass
