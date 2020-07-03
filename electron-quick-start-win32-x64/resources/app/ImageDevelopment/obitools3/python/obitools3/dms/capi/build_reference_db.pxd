#cython: language_level=3


cdef extern from "build_reference_db.h" nogil:

    int build_reference_db(const char* dms_name,
                           const char* refs_view_name,
                           const char* taxonomy_name,
                           const char* o_view_name,
                           const char* o_view_comments,
                           double threshold)

