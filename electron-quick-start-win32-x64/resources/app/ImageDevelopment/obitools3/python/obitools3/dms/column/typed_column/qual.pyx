#cython: language_level=3

from obitools3.dms.capi.obierrno cimport obi_errno

from ..column cimport register_column_class

from ...view.view cimport View

from ..column cimport Column

from obitools3.utils cimport tobytes, bytes2str, \
                             obi_errno_to_exception

from ...capi.obiview cimport obi_get_qual_char_with_elt_name_and_col_p_in_view, \
                             obi_get_qual_char_with_elt_idx_and_col_p_in_view, \
                             obi_set_qual_char_with_elt_name_and_col_p_in_view, \
                             obi_set_qual_char_with_elt_idx_and_col_p_in_view, \
                             obi_get_qual_int_with_elt_name_and_col_p_in_view, \
                             obi_get_qual_int_with_elt_idx_and_col_p_in_view, \
                             obi_set_qual_int_with_elt_name_and_col_p_in_view, \
                             obi_set_qual_int_with_elt_idx_and_col_p_in_view, \
                             Obiview_p

from ...capi.obidmscolumn cimport OBIDMS_column_p

from ...capi.obitypes     cimport OBI_QUAL, OBIQual_char_NA, OBIQual_int_NA, const_char_p

from libc.stdlib  cimport malloc, free
from libc.stdint cimport uint8_t


# TODO detect type of value and call set_item_str if str or bytes?

cdef class Column_qual(Column_idx):

    @staticmethod
    def new(View    view,
            object  column_name,
            index_t nb_elements_per_line=1,
            object  elements_names=None,
            object  associated_column_name=b"",
            int     associated_column_version=-1,
            object  comments={}):
        
        return Column.new_column(view, column_name, OBI_QUAL,
                                 nb_elements_per_line=nb_elements_per_line, 
                                 elements_names=elements_names, 
                                 tuples=False,
                                 associated_column_name=associated_column_name,
                                 associated_column_version=associated_column_name,
                                 comments=comments)


    cpdef object get_line(self, index_t line_nb):
        global obi_errno
        cdef   const uint8_t* value
        cdef   int            value_length
        cdef   object         result 
        value = obi_get_qual_int_with_elt_idx_and_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, 0, &value_length)
        obi_errno_to_exception(line_nb=line_nb, elt_id=None, error_message="Problem getting a value from a column")
        if value == OBIQual_int_NA :
            result = None
        else :
            result = []
            for i in range(value_length) :
                result.append(<int>value[i])            
        return result

    
    cpdef object get_bytes_line(self, index_t line_nb, int offset=-1):
        global obi_errno
        cdef   char*  value
        cdef   object result
        cdef   int    i
        value = obi_get_qual_char_with_elt_idx_and_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, 0, offset)
        obi_errno_to_exception(line_nb=line_nb, elt_id=None, error_message="Problem getting a value from a column")
        if value == OBIQual_char_NA :
            result = None
        else :
            result = value
            free(value)
        return result
    
    
    cpdef set_line(self, index_t line_nb, object value):
        global obi_errno
        cdef   uint8_t* value_b
        cdef   int      value_length
        if value is None :
            if obi_set_qual_int_with_elt_idx_and_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, 0, OBIQual_int_NA, 0) < 0:
                obi_errno_to_exception(line_nb=line_nb, elt_id=None, error_message="Problem setting a value in a column")
        else :
            value_length = len(value)
            value_b = <uint8_t*> malloc(value_length * sizeof(uint8_t))
            for i in range(value_length) :
                value_b[i] = <uint8_t>value[i]
            if obi_set_qual_int_with_elt_idx_and_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, 0, value_b, value_length) < 0:
                obi_errno_to_exception(line_nb=line_nb, elt_id=None, error_message="Problem setting a value in a column")
            free(value_b)
 
 
    cpdef set_bytes_line(self, index_t line_nb, object value, int offset=-1):
        global obi_errno
        cdef   bytes value_b        
        if value is None :
            if obi_set_qual_char_with_elt_idx_and_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, 0, OBIQual_char_NA, offset) < 0:
                obi_errno_to_exception(line_nb=line_nb, elt_id=None, error_message="Problem setting a value in a column")
        else :
            value_b = tobytes(value)
            if obi_set_qual_char_with_elt_idx_and_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, 0, value_b, offset) < 0:
                obi_errno_to_exception(line_nb=line_nb, elt_id=None, error_message="Problem setting a value in a column")

 
cdef class Column_multi_elts_qual(Column_multi_elts_idx):
 
    cpdef object get_item(self, index_t line_nb, object elt_id):
        global obi_errno
        cdef   const uint8_t*  value
        cdef   int             value_length
        cdef   object          result
        cdef   int             i
        if type(elt_id) == int :
            value = obi_get_qual_int_with_elt_idx_and_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, elt_id, &value_length)
        else :
            elt_name = tobytes(elt_id)
            value = obi_get_qual_int_with_elt_name_and_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, elt_name, &value_length)
        obi_errno_to_exception(line_nb=line_nb, elt_id=elt_id, error_message="Problem getting a value from a column")
        if value == OBIQual_int_NA :
            result = None
        else :
            result = []
            for i in range(value_length) :
                result.append(<int>value[i])            
        return result

    
    cpdef object get_bytes_item(self, index_t line_nb, object elt_id, int offset=-1):
        global obi_errno
        cdef   char*  value
        cdef   object result
        if type(elt_id) == int :
            value = obi_get_qual_char_with_elt_idx_and_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, elt_id, offset)
        else :
            elt_name = tobytes(elt_id)
            value = obi_get_qual_char_with_elt_name_and_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, elt_name, offset)
        obi_errno_to_exception(line_nb=line_nb, elt_id=elt_id, error_message="Problem getting a value from a column")
        if value == OBIQual_char_NA :
            result = None
        else :
            result = value
            free(value)
        return result

    
    cpdef object get_line(self, index_t line_nb) :
        global obi_errno
        cdef   const uint8_t*  value
        cdef   int             value_length
        cdef   list            value_in_result
        cdef   dict            result
        cdef   index_t         i
        cdef   int             j
        cdef   bint            all_NA
        cdef   list            elements_names
        cdef   Obiview_p       view_p
        cdef   OBIDMS_column_p column_p
        result = {}
        all_NA = True
        view_p = self._view.pointer()
        column_p = self.pointer()
        elements_names = self._elements_names
        for i in range(self.nb_elements_per_line) :
            value = obi_get_qual_int_with_elt_idx_and_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, i, &value_length)
            obi_errno_to_exception(line_nb=line_nb, elt_id=i, error_message="Problem getting a value from a column")
            if value != OBIQual_int_NA :
                value_in_result = []
                for j in range(value_length) :
                    value_in_result.append(<int>value[j])  
                result[elements_names[i]] = value_in_result
                if all_NA :
                    all_NA = False
        if all_NA :
            result = None
        return result


    cpdef object get_bytes_line(self, index_t line_nb, int offset=-1) :
        global obi_errno
        cdef   char*           value
        cdef   object          value_in_result
        cdef   dict            result
        cdef   index_t         i
        cdef   bint            all_NA
        cdef   list            elements_names
        cdef   Obiview_p       view_p
        cdef   OBIDMS_column_p column_p
        result = {}
        all_NA = True
        view_p = self._view.pointer()
        column_p = self.pointer()
        elements_names = self._elements_names
        for i in range(self.nb_elements_per_line) :
            value = obi_get_qual_char_with_elt_idx_and_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, i, offset)
            obi_errno_to_exception(line_nb=line_nb, elt_id=i, error_message="Problem getting a value from a column")
            if value != OBIQual_char_NA :
                value_in_result = value
                free(value)
                result[elements_names[i]] = value_in_result
                if all_NA :
                    all_NA = False
        if all_NA :
            result = None
        return result
    
    
    cpdef set_item(self, index_t line_nb, object elt_id, object value):
        global obi_errno
        cdef   uint8_t* value_b
        cdef   int      value_length
        cdef   bytes    elt_name
        
        if value is None :
            value_b = OBIQual_int_NA
            value_length = 0
        else :
            value_length = len(value)
            value_b = <uint8_t*> malloc(value_length * sizeof(uint8_t))
            for i in range(value_length) :
                value_b[i] = <uint8_t>value[i]           
   
        if type(elt_id) == int :
            if obi_set_qual_int_with_elt_idx_and_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, elt_id, value_b, value_length) < 0 :
                obi_errno_to_exception(line_nb=line_nb, elt_id=elt_id, error_message="Problem setting a value in a column")
        else :
            elt_name = tobytes(elt_id)
            if obi_set_qual_int_with_elt_name_and_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, elt_name, value_b, value_length) < 0:
                obi_errno_to_exception(line_nb=line_nb, elt_id=elt_id, error_message="Problem setting a value in a column")
        
        if value is not None :
            free(value_b)
    

    cpdef set_bytes_item(self, index_t line_nb, object elt_id, object value, int offset=-1):
        global obi_errno
        cdef   bytes value_b
        cdef   bytes elt_name
        
        if value is None :
            value_b = OBIQual_char_NA
        else :
            value_b = tobytes(value)
   
        if type(elt_id) == int :
            if obi_set_qual_char_with_elt_idx_and_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, elt_id, value_b, offset) < 0 :
                obi_errno_to_exception(line_nb=line_nb, elt_id=elt_id, error_message="Problem setting a value in a column")
        else :
            elt_name = tobytes(elt_id)
            if obi_set_qual_char_with_elt_name_and_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, elt_name, value_b, offset) < 0:
                obi_errno_to_exception(line_nb=line_nb, elt_id=elt_id, error_message="Problem setting a value in a column")


def register_class():
    register_column_class(OBI_QUAL, False, False, Column_qual, int)    # TODO bytes?
    register_column_class(OBI_QUAL, True, False, Column_multi_elts_qual, int)    # bytes?

