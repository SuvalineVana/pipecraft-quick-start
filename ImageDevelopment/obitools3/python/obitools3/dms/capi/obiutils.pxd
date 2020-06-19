#cython: language_level=3


from posix.types cimport time_t

from ..capi.obitypes cimport const_char_p


cdef extern from "utils.h" nogil:

    const_char_p obi_format_date(time_t date)
    char* reverse_complement_sequence(char* nucAcSeq)
