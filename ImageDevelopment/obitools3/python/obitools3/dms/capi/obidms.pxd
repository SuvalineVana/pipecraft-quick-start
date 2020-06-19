#cython: language_level=3

from .obitypes cimport const_char_p, \
                       obiversion_t

cdef extern from "obidms.h" nogil:

    struct OBIDMS_infos_t :
        bint                little_endian
        size_t              file_size
        size_t              used_size
        bint                working
        const_char_p        comments

    ctypedef OBIDMS_infos_t* OBIDMS_infos_p

    
    struct OBIDMS_t:
        const_char_p        dms_name
        const_char_p        directory_path
        OBIDMS_infos_p      infos

    ctypedef OBIDMS_t* OBIDMS_p 

    int obi_dms_is_clean(OBIDMS_p dms)
    int obi_clean_dms(const_char_p dms_path)
    OBIDMS_p obi_dms(const_char_p dms_name)
    OBIDMS_p obi_open_dms(const_char_p dms_path, bint cleaning)
    OBIDMS_p obi_test_open_dms(const_char_p dms_path)
    OBIDMS_p obi_create_dms(const_char_p dms_path)
    int obi_dms_exists(const char* dms_path)
    int obi_dms_write_comments(OBIDMS_p dms, const char* comments)
    int obi_dms_add_comment(OBIDMS_p dms, const char* key, const char* value)
    int obi_close_dms(OBIDMS_p dms, bint force)
    char* obi_dms_get_dms_path(OBIDMS_p dms)
    char* obi_dms_get_full_path(OBIDMS_p dms, const_char_p path_name)
    void obi_close_atexit()
    
    obiversion_t obi_import_column(const char* dms_path_1, const char* dms_path_2, const char* column_name, obiversion_t version_number)
    int obi_import_view(const char* dms_path_1, const char* dms_path_2, const char* view_name_1, const char* view_name_2)
