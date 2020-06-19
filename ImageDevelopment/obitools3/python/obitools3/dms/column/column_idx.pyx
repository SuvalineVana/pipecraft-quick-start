#cython: language_level=3

from obitools3.dms.capi.obierrno cimport obi_errno

from ..view.view cimport View

from obitools3.utils cimport tobytes, \
                             obi_errno_to_exception

from ..capi.obiview cimport obi_get_index_with_elt_name_and_col_p_in_view, \
                             obi_get_index_with_elt_idx_and_col_p_in_view, \
                             obi_set_index_with_elt_name_and_col_p_in_view, \
                             obi_set_index_with_elt_idx_and_col_p_in_view, \
                             Obiview_p

from ..capi.obidmscolumn cimport OBIDMS_column_p

from ..capi.obitypes     cimport OBI_IDX, OBIIdx_NA, index_t

from cpython.long cimport PyLong_FromLongLong


# TODO overwrite other functions from Column and Column_multi_elts


cdef class Column_idx(Column):

    cpdef object get_line_idx(self, index_t line_nb):
        global obi_errno
        cdef   index_t value
        cdef   object  result 
        value = obi_get_index_with_elt_idx_and_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, 0)
        obi_errno_to_exception(line_nb=line_nb, elt_id=None, error_message="Problem getting a value from a column")
        if value == OBIIdx_NA :
            result = None
        else :
            result = PyLong_FromLongLong(value)
        return result

    cpdef set_line_idx(self, index_t line_nb, object value):
        global obi_errno
        if value is None :
            value = OBIIdx_NA
        if obi_set_index_with_elt_idx_and_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, 0, <index_t> value) < 0:
            obi_errno_to_exception(line_nb=line_nb, elt_id=None, error_message="Problem setting a value in a column")
 
 
cdef class Column_multi_elts_idx(Column_multi_elts):
 
    cpdef object get_item_idx(self, index_t line_nb, object elt_id) :
        global obi_errno
        cdef   int       value
        cdef   object    result
        cdef   bytes     elt_name
        if type(elt_id) == int :
            value = obi_get_index_with_elt_idx_and_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, elt_id)
        else :
            elt_name = tobytes(elt_id)
            value = obi_get_index_with_elt_name_and_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, elt_name)
        obi_errno_to_exception(line_nb=line_nb, elt_id=elt_id, error_message="Problem getting a value from a column")
        if value == OBIIdx_NA :
            result = None
        else :
            result = PyLong_FromLongLong(value)
        return result
    
    cpdef object get_line_idx(self, index_t line_nb) :
        global obi_errno
        cdef   index_t         value
        cdef   int             value_in_result
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
            value = obi_get_index_with_elt_idx_and_col_p_in_view(view_p, column_p, line_nb, i)
            obi_errno_to_exception(line_nb=line_nb, elt_id=i, error_message="Problem getting a value from a column")
            if value != OBIIdx_NA :
                value_in_result = PyLong_FromLongLong(value)
                result[elements_names[i]] = value_in_result
                if all_NA :
                    all_NA = False
        if all_NA :
            result = None
        return result
    
    cpdef set_item_idx(self, index_t line_nb, object elt_id, object value) :
        global obi_errno
        cdef   bytes elt_name
        if value is None :
            value = OBIIdx_NA
        if type(elt_id) == int :
            if obi_set_index_with_elt_idx_and_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, elt_id, <index_t> value) < 0 :
                obi_errno_to_exception(line_nb=line_nb, elt_id=elt_id, error_message="Problem setting a value in a column")
        else :
            elt_name = tobytes(elt_id)
            if obi_set_index_with_elt_name_and_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, elt_name, <index_t> value) < 0 :
                obi_errno_to_exception(line_nb=line_nb, elt_id=elt_id, error_message="Problem setting a value in a column")

    cpdef set_line_idx(self, index_t line_nb, object values):
        if values is None :
            for element_name in self._elements_names :
                self.set_item_idx(line_nb, element_name, None)
        else :
            for element_name in values :
                self.set_item_idx(line_nb, element_name, values[element_name])

