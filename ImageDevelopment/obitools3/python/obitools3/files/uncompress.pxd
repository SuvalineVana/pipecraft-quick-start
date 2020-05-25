#cython: language_level=3

cdef class MagicKeyFile:
    cdef object stream
    cdef str    stream_mode
    cdef object binary
    cdef bytes  key 
    cdef int    keylength 
    cdef int    pos
    
    cpdef bytes read(self,int size=?)
    cpdef bytes read1(self,int size=?)
    cpdef int tell(self)

    
cdef class CompressedFile:
    cdef object accessor
    cdef bint compressed
    