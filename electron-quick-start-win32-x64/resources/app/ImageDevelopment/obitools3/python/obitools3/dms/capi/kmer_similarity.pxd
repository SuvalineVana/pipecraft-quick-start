#cython: language_level=3

from obitools3.dms.capi.obiview cimport Obiview_p
from obitools3.dms.capi.obidmscolumn cimport OBIDMS_column_p
from obitools3.dms.capi.obitypes cimport index_t

from libc.stdint  cimport int32_t, uint8_t


cdef extern from "kmer_similarity.h" nogil:

    struct Obi_ali_t :
        double   score
        int      consensus_length
        int      overlap_length
        char*    consensus_seq
        uint8_t* consensus_qual
        int      shift
        char*    direction

    ctypedef Obi_ali_t* Obi_ali_p

    
    void obi_free_shifted_ali(Obi_ali_p ali)


    Obi_ali_p kmer_similarity(Obiview_p view1,
                              OBIDMS_column_p column1,
                              index_t idx1,
                              index_t elt_idx1,
                              Obiview_p view2,
                              OBIDMS_column_p column2,
                              index_t idx2,
                              index_t elt_idx2,
                              OBIDMS_column_p qual_col1,
                              OBIDMS_column_p qual_col2,
                              OBIDMS_column_p reversed_col,
                              uint8_t kmer_size,
                              int32_t** kmer_pos_array,
                              int32_t* kmer_pos_array_height_p,
                              int32_t** shift_array,
                              int32_t* shift_array_height_p,
                              int32_t** shift_count_array, 
                              int32_t* shift_count_array_height_p,
                              bint build_consensus)
