#cython: language_level=3

from obitools3.dms.capi.obidms       cimport OBIDMS_p


cdef extern from "obi_clean.h" nogil:

    int obi_clean(const char* dms_name,
                  const char* i_view_name,
                  const char* sample_column_name,
                  const char* o_view_name,
                  const char* o_view_comments,
                  double threshold,
                  double max_ratio,
                  bint heads_only,
                  int thread_count)
    
