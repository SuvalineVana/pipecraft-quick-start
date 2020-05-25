#cython: language_level=3


cdef extern from "obierrno.h":
    int obi_errno

    extern int OBI_LINE_IDX_ERROR
    extern int OBI_ELT_IDX_ERROR
    extern int OBIVIEW_ALREADY_EXISTS_ERROR
    extern int OBIDMS_NOT_CLEAN
    extern int OBIDMS_WORKING