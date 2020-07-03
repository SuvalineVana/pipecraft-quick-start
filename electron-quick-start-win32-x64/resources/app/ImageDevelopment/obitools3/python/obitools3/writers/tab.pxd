#cython: language_level=3

cdef class TabWriter:
    cdef object formatter
    cdef object output
    cdef int    only
    cdef int    skip
    cdef int    skipped
    cdef int    read