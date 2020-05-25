cdef class HeaderFormat:

    cdef bytes  start
    cdef set    tags
    cdef bint   printNAKeys
    cdef bytes  NAString
    cdef size_t headerBufferLength
    