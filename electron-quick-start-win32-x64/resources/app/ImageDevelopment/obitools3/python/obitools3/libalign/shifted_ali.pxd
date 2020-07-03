#cython: language_level=3

from obitools3.dms.capi.kmer_similarity cimport kmer_similarity, Obi_ali_p
from libc.stdint  cimport int32_t, uint8_t
from obitools3.dms.capi.obiview cimport Obiview_p
from obitools3.dms.capi.obidmscolumn cimport OBIDMS_column_p


cdef class Ali_shifted:
    cdef Obi_ali_p _pointer
    cdef inline Obi_ali_p pointer(self)
    cpdef free(self)
    @staticmethod
    cdef Ali_shifted new_ali(Obi_ali_p ali_p)


cdef class Kmer_similarity:
    cdef uint8_t         kmer_size
    cdef int32_t*        kmer_pos_array_p
    cdef int32_t         kmer_pos_array_height_a[1]
    cdef int32_t*        shift_array_p
    cdef int32_t         shift_array_height_a[1]
    cdef int32_t*        shift_count_array_p
    cdef int32_t         shift_count_array_height_a[1]
    cdef Obiview_p       view1_p
    cdef OBIDMS_column_p column1_p
    cdef OBIDMS_column_p qual_col1_p
    cdef Obiview_p       view2_p
    cdef OBIDMS_column_p column2_p
    cdef OBIDMS_column_p qual_col2_p
    cdef OBIDMS_column_p reversed_col_p
    cdef bint            build_consensus
    cpdef free(self)