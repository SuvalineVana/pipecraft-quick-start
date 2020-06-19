#cython: language_level=3

from obitools3.dms.capi.apat cimport SeqPtr


cdef class One_primer_search_result:
    cdef SeqPtr _pointer
    cdef int pattern_ref
    cdef int hit_count
    cdef inline SeqPtr pointer(self)
    @staticmethod
    cdef new(SeqPtr apat_seq_p, int pattern_ref, int hit_count)
    cpdef first_encountered(self)
    

cdef class Primer_search:
    cdef SeqPtr apat_seq_p
    cdef list direct_primers
    cdef list revcomp_primers
    cpdef One_primer_search_result search_one_primer(self, bytes sequence, 
                                                     int primer_pair_index, int primer_index, 
                                                     bint reverse_comp=*, 
                                                     bint same_sequence=*, 
                                                     int pattern_ref=*,
                                                     int begin=*)
    cpdef free(self)
    

