#cython: language_level=3


cdef extern from "obi_ecotag.h" nogil:

    int obi_ecotag(const char* dms_name,
                   const char* query_view_name,
                   const char* ref_dms_name,
                   const char* ref_view_name,
                   const char* taxo_dms_name,
                   const char* taxonomy_name,
                   const char* output_view_name,
                   const char* output_view_comments,
                   double ecotag_threshold)
