#cython: language_level=3

cdef class TabFormat:
    cdef bint header
    cdef bint first_line
    cdef bytes NAString
    cdef list tags
    cdef bytes sep