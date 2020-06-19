#cython: language_level=3


cdef class LineBuffer:
    cdef object fileobj
    cdef int    size
