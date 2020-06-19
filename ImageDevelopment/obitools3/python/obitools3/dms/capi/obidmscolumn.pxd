#cython: language_level=3

from ..capi.obidms   cimport OBIDMS_p
from ..capi.obitypes cimport const_char_p, \
                             OBIType_t, \
                             obiversion_t, \
                             obiint_t, \
                             obibool_t, \
                             obichar_t, \
                             obifloat_t, \
                             index_t, \
                             time_t

from libc.stdint cimport uint8_t


cdef extern from "obidmscolumn.h" nogil:
    
    struct Column_reference_t :
        const_char_p  column_name
        obiversion_t  version
    
    ctypedef Column_reference_t* Column_reference_p

    struct OBIDMS_column_header_t:
        size_t              header_size
        size_t              data_size
        index_t             line_count
        index_t             lines_used
        index_t             nb_elements_per_line
        const_char_p        elements_names
        OBIType_t           returned_data_type
        OBIType_t           stored_data_type
        bint                tuples
        bint                to_eval
        time_t              creation_date
        obiversion_t        version
        obiversion_t        cloned_from
        const_char_p        name
        const_char_p        indexer_name
        Column_reference_t  associated_column
        const_char_p        comments
    
    ctypedef OBIDMS_column_header_t* OBIDMS_column_header_p

    struct OBIDMS_column_t:
        OBIDMS_p               dms
        OBIDMS_column_header_p header
        bint                   writable
        
    ctypedef OBIDMS_column_t* OBIDMS_column_p
        
    int obi_close_column(OBIDMS_column_p column)
    
    obiversion_t obi_column_get_latest_version_from_name(OBIDMS_p dms, 
                                                         const_char_p column_name)
        
    OBIDMS_column_header_p obi_column_get_header_from_name(OBIDMS_p dms, 
                                                           const_char_p column_name,
                                                           obiversion_t version_number)
    
    int obi_close_header(OBIDMS_column_header_p header)
    
    char* obi_get_elements_names(OBIDMS_column_p column)
    
    index_t obi_column_get_element_index_from_name(OBIDMS_column_p column, const char* element_name)
    
    int obi_column_write_comments(OBIDMS_column_p column, const char* comments)

    int obi_column_add_comment(OBIDMS_column_p column, const char* key, const char* value)
