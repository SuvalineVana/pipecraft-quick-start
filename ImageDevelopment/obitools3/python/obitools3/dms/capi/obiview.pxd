#cython: language_level=3

from .obitypes           cimport const_char_p, \
                                 OBIType_t, \
                                 obiversion_t, \
                                 obiint_t, \
                                 obibool_t, \
                                 obichar_t, \
                                 obifloat_t, \
                                 index_t, \
                                 time_t
from ..capi.obidms       cimport OBIDMS_p
from ..capi.obidmscolumn cimport OBIDMS_column_p, \
                                 Column_reference_t, \
                                 Column_reference_p

from libc.stdint cimport uint8_t, int32_t


cdef extern from "obiview.h" nogil:

    extern const_char_p VIEW_TYPE_NUC_SEQS
    extern const_char_p NUC_SEQUENCE_COLUMN
    extern const_char_p ID_COLUMN
    extern const_char_p DEFINITION_COLUMN
    extern const_char_p QUALITY_COLUMN
    extern const_char_p REVERSE_QUALITY_COLUMN
    extern const_char_p REVERSE_SEQUENCE_COLUMN
    extern const_char_p COUNT_COLUMN
    extern const_char_p TAXID_COLUMN
    extern const_char_p MERGED_TAXID_COLUMN
    extern const_char_p MERGED_PREFIX
    extern const_char_p TAXID_DIST_COLUMN
    extern const_char_p MERGED_COLUMN

    struct Alias_column_pair_t :
        Column_reference_t    column_refs
        const_char_p          alias
    
    ctypedef Alias_column_pair_t* Alias_column_pair_p


    struct Obiview_infos_t :
        time_t              creation_date
        const_char_p        name
        const_char_p        created_from
        const_char_p        view_type
        bint                all_lines
        Column_reference_t  line_selection
        index_t             line_count
        int                 column_count
        Alias_column_pair_p column_references
        const_char_p        comments

    ctypedef Obiview_infos_t* Obiview_infos_p


    struct Obiview_t :
        Obiview_infos_p     infos
        OBIDMS_p            dms
        bint                read_only
        OBIDMS_column_p     line_selection
        OBIDMS_column_p     columns
        int                 nb_predicates
        # TODO declarations for column dictionary and predicate function array?
        
    ctypedef Obiview_t* Obiview_p


    Obiview_p obi_new_view_nuc_seqs(OBIDMS_p dms, const_char_p view_name, Obiview_p view_to_clone, index_t* line_selection, const_char_p comments, bint quality_column, bint create_default_columns)

    Obiview_p obi_new_view(OBIDMS_p dms, const_char_p view_name, Obiview_p view_to_clone, index_t* line_selection, const_char_p comments)
    
    Obiview_p obi_new_view_cloned_from_name(OBIDMS_p dms, const_char_p view_name, const_char_p view_to_clone_name, index_t* line_selection, const_char_p comments)

    Obiview_p obi_new_view_nuc_seqs_cloned_from_name(OBIDMS_p dms, const_char_p view_name, const_char_p view_to_clone_name, index_t* line_selection, const_char_p comments)
    
    Obiview_p obi_clone_view(OBIDMS_p dms, Obiview_p view_to_clone, const char* view_name, index_t* line_selection, const char* comments)

    Obiview_p obi_clone_view_from_name(OBIDMS_p dms, const char* view_to_clone_name, const char* view_name, index_t* line_selection, const char* comments)
    
    Obiview_infos_p obi_view_map_file(OBIDMS_p dms, const char* view_name, bint finished)

    int obi_view_unmap_file(OBIDMS_p dms, Obiview_infos_p view_infos)

    Obiview_p obi_open_view(OBIDMS_p dms, const_char_p view_name)
    
    int obi_view_add_column(Obiview_p view,
                            char* column_name,
                            obiversion_t version_number,
                            const_char_p alias,
                            OBIType_t data_type,
                            index_t nb_lines,
                            index_t nb_elements_per_line,
                            char* elements_names,
                            bint  elt_names_formatted,
                            bint tuples,
                            bint to_eval,
                            const_char_p indexer_name,
                            const_char_p associated_column_name,
                            obiversion_t associated_column_version,
                            const_char_p comments,
                            bint create)

    int obi_view_delete_column(Obiview_p view, const_char_p column_name, bint delete_file)
            
    OBIDMS_column_p obi_view_get_column(Obiview_p view, const_char_p column_name)

    OBIDMS_column_p* obi_view_get_pointer_on_column_in_view(Obiview_p view, const_char_p column_name)

    int obi_view_create_column_alias(Obiview_p view, const_char_p current_name, const_char_p alias)    
    
    int obi_view_write_comments(Obiview_p view, const_char_p comments)

    int obi_view_add_comment(Obiview_p view, const_char_p key, const_char_p value)

    int obi_save_and_close_view(Obiview_p view)

    int obi_clean_unfinished_views(OBIDMS_p dms)

    int obi_rollback_view(Obiview_p view)

    int obi_delete_view(OBIDMS_p dms, const char* view_name)


    # OBI_INT
    int obi_set_int_with_elt_name_and_col_p_in_view(Obiview_p view,
                                                    OBIDMS_column_p column_p, 
                                                    index_t line_nb, 
                                                    const_char_p element_name, 
                                                    obiint_t value)

    int obi_set_int_with_elt_idx_and_col_p_in_view(Obiview_p view,
                                                   OBIDMS_column_p column_p, 
                                                   index_t line_nb, 
                                                   index_t element_idx, 
                                                   obiint_t value)
    
    obiint_t obi_get_int_with_elt_name_and_col_p_in_view(Obiview_p view,
                                                         OBIDMS_column_p column_p, 
                                                         index_t line_nb, 
                                                         const_char_p element_name)
    
    obiint_t obi_get_int_with_elt_idx_and_col_p_in_view(Obiview_p view,
                                                        OBIDMS_column_p column_p, 
                                                        index_t line_nb, 
                                                        index_t element_idx)


    # OBI_BOOL
    int obi_set_bool_with_elt_name_and_col_p_in_view(Obiview_p view,
                                                     OBIDMS_column_p column_p, 
                                                     index_t line_nb, 
                                                     const_char_p element_name, 
                                                     obibool_t value)

    int obi_set_bool_with_elt_idx_and_col_p_in_view(Obiview_p view,
                                                    OBIDMS_column_p column_p, 
                                                    index_t line_nb, 
                                                    index_t element_idx, 
                                                    obibool_t value)
    
    obibool_t obi_get_bool_with_elt_name_and_col_p_in_view(Obiview_p view,
                                                           OBIDMS_column_p column_p, 
                                                           index_t line_nb, 
                                                           const_char_p element_name)
    
    obibool_t obi_get_bool_with_elt_idx_and_col_p_in_view(Obiview_p view,
                                                          OBIDMS_column_p column_p, 
                                                          index_t line_nb, 
                                                          index_t element_idx)


    # OBI_CHAR
    int obi_set_char_with_elt_name_and_col_p_in_view(Obiview_p view,
                                                     OBIDMS_column_p column_p, 
                                                     index_t line_nb, 
                                                     const_char_p element_name, 
                                                     obichar_t value)

    int obi_set_char_with_elt_idx_and_col_p_in_view(Obiview_p view,
                                                    OBIDMS_column_p column_p, 
                                                    index_t line_nb, 
                                                    index_t element_idx, 
                                                    obichar_t value)
    
    obichar_t obi_get_char_with_elt_name_and_col_p_in_view(Obiview_p view,
                                                           OBIDMS_column_p column_p, 
                                                           index_t line_nb, 
                                                           const_char_p element_name)
    
    obichar_t obi_get_char_with_elt_idx_and_col_p_in_view(Obiview_p view,
                                                          OBIDMS_column_p column_p, 
                                                          index_t line_nb, 
                                                          index_t element_idx)


    # OBI_FLOAT
    int obi_set_float_with_elt_name_and_col_p_in_view(Obiview_p view,
                                                      OBIDMS_column_p column_p, 
                                                      index_t line_nb, 
                                                      const_char_p element_name, 
                                                      obifloat_t value)

    int obi_set_float_with_elt_idx_and_col_p_in_view(Obiview_p view,
                                                     OBIDMS_column_p column_p, 
                                                     index_t line_nb, 
                                                     index_t element_idx, 
                                                     obifloat_t value)
    
    obifloat_t obi_get_float_with_elt_name_and_col_p_in_view(Obiview_p view,
                                                             OBIDMS_column_p column_p, 
                                                             index_t line_nb, 
                                                             const_char_p element_name)
    
    obifloat_t obi_get_float_with_elt_idx_and_col_p_in_view(Obiview_p view,
                                                            OBIDMS_column_p column_p, 
                                                            index_t line_nb, 
                                                            index_t element_idx)


    # OBI_QUAL
    int obi_set_qual_char_with_elt_idx_and_col_p_in_view(Obiview_p view, 
                                                         OBIDMS_column_p column_p, 
                                                         index_t line_nb, 
                                                         index_t element_idx, 
                                                         const char* value,
                                                         int offset)

    int obi_set_qual_int_with_elt_idx_and_col_p_in_view(Obiview_p view, 
                                                        OBIDMS_column_p column_p, 
                                                        index_t line_nb, 
                                                        index_t element_idx, 
                                                        const uint8_t* value, 
                                                        int value_length)

    char* obi_get_qual_char_with_elt_idx_and_col_p_in_view(Obiview_p view, 
                                                           OBIDMS_column_p column_p, 
                                                           index_t line_nb, 
                                                           index_t element_idx,
                                                           int offset)

    const uint8_t* obi_get_qual_int_with_elt_idx_and_col_p_in_view(Obiview_p view, 
                                                                   OBIDMS_column_p column_p, 
                                                                   index_t line_nb, 
                                                                   index_t element_idx, 
                                                                   int* value_length)

    int obi_set_qual_char_with_elt_name_and_col_p_in_view(Obiview_p view, 
                                                          OBIDMS_column_p column_p, 
                                                          index_t line_nb, 
                                                          const char* element_name, 
                                                          const char* value,
                                                          int offset)

    int obi_set_qual_int_with_elt_name_and_col_p_in_view(Obiview_p view, 
                                                         OBIDMS_column_p column_p, 
                                                         index_t line_nb, 
                                                         const char* element_name, 
                                                         const uint8_t* value, 
                                                         int value_length)

    char* obi_get_qual_char_with_elt_name_and_col_p_in_view(Obiview_p view, 
                                                            OBIDMS_column_p column_p, 
                                                            index_t line_nb, 
                                                            const char* element_name,
                                                            int offset)

    const uint8_t* obi_get_qual_int_with_elt_name_and_col_p_in_view(Obiview_p view, 
                                                                    OBIDMS_column_p column_p, 
                                                                    index_t line_nb, 
                                                                    const char* element_name, 
                                                                    int* value_length)


    # OBI_STR
    int obi_set_str_with_elt_name_and_col_p_in_view(Obiview_p view,
                                                    OBIDMS_column_p column_p, 
                                                    index_t line_nb, 
                                                    const_char_p element_name, 
                                                    const_char_p value)

    int obi_set_str_with_elt_idx_and_col_p_in_view(Obiview_p view,
                                                   OBIDMS_column_p column_p, 
                                                   index_t line_nb, 
                                                   index_t element_idx, 
                                                   const_char_p value)
    
    const_char_p obi_get_str_with_elt_name_and_col_p_in_view(Obiview_p view,
                                                           OBIDMS_column_p column_p, 
                                                           index_t line_nb, 
                                                           const_char_p element_name)
    
    const_char_p obi_get_str_with_elt_idx_and_col_p_in_view(Obiview_p view,
                                                            OBIDMS_column_p column_p, 
                                                            index_t line_nb, 
                                                            index_t element_idx)


    # OBI_SEQ
    int obi_set_seq_with_elt_name_and_col_p_in_view(Obiview_p view,
                                                    OBIDMS_column_p column_p, 
                                                    index_t line_nb, 
                                                    const_char_p element_name, 
                                                    const_char_p value)

    int obi_set_seq_with_elt_idx_and_col_p_in_view(Obiview_p view,
                                                   OBIDMS_column_p column_p, 
                                                   index_t line_nb, 
                                                   index_t element_idx, 
                                                   const_char_p value)
    
    char* obi_get_seq_with_elt_name_and_col_p_in_view(Obiview_p view,
                                                      OBIDMS_column_p column_p, 
                                                      index_t line_nb, 
                                                      const_char_p element_name)
    
    char* obi_get_seq_with_elt_idx_and_col_p_in_view(Obiview_p view,
                                                     OBIDMS_column_p column_p, 
                                                     index_t line_nb, 
                                                     index_t element_idx)

    
    # OBI_IDX
    int obi_set_index_with_elt_name_and_col_p_in_view(Obiview_p view, 
                                                     OBIDMS_column_p column_p, 
                                                     index_t line_nb, 
                                                     const_char_p element_name, 
                                                     index_t value)

    int obi_set_index_with_elt_idx_and_col_p_in_view(Obiview_p view,
                                                     OBIDMS_column_p column_p, 
                                                     index_t line_nb, 
                                                     index_t element_idx, 
                                                     index_t value)
    
    index_t obi_get_index_with_elt_name_and_col_p_in_view(Obiview_p view,
                                                          OBIDMS_column_p column_p, 
                                                          index_t line_nb, 
                                                          const_char_p element_name)

    index_t obi_get_index_with_elt_idx_and_col_p_in_view(Obiview_p view,
                                                         OBIDMS_column_p column_p, 
                                                         index_t line_nb, 
                                                         index_t element_idx)

    # ARRAY
    int obi_set_array_with_col_p_in_view(Obiview_p view, 
                                         OBIDMS_column_p column, 
                                         index_t line_nb, 
                                         const void* value, 
                                         uint8_t elt_size, 
                                         int32_t value_length)
    
    const void* obi_get_array_with_col_p_in_view(Obiview_p view, 
                                                 OBIDMS_column_p column, 
                                                 index_t line_nb, 
                                                 int32_t* value_length_p)

    int obi_set_array_with_col_name_in_view(Obiview_p view, 
                                            const char* column_name, 
                                            index_t line_nb, 
                                            const void* value, 
                                            uint8_t elt_size, 
                                            int32_t value_length)

    const void* obi_get_array_with_col_name_in_view(Obiview_p view, 
                                                    const char* column_name, 
                                                    index_t line_nb, 
                                                    int32_t* value_length_p)

