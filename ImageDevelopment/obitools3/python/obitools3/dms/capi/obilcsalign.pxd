#cython: language_level=3

from obitools3.dms.capi.obidms       cimport OBIDMS_p
from obitools3.dms.capi.obitypes     cimport const_char_p


cdef extern from "obi_lcs.h" nogil:

    int obi_lcs_align_one_column(const_char_p dms_name, 
                                 const_char_p seq_view_name, 
                                 const_char_p seq_column_name, 
                                 const_char_p seq_elt_name,
                                 const_char_p id_column_name,
                                 const_char_p output_view_name, 
                                 const_char_p output_view_comments,
                                 bint print_seq, 
                                 bint print_count,
                                 double threshold, 
                                 bint normalize, 
                                 int reference, 
                                 bint similarity_mode,
                                 int thread_count)


    int obi_lcs_align_two_columns(const_char_p dms_name,
                                  const_char_p seq1_view_name,
                                  const_char_p seq2_view_name,
                                  const_char_p seq1_column_name,
                                  const_char_p seq2_column_name,
                                  const_char_p seq1_elt_name,
                                  const_char_p seq2_elt_name,
                                  const_char_p id1_column_name,
                                  const_char_p id2_column_name,
                                  const_char_p output_view_name, 
                                  const_char_p output_view_comments,
                                  bint print_seq, 
                                  bint print_count,
                                  double threshold, 
                                  bint normalize, 
                                  int reference, 
                                  bint similarity_mode)
