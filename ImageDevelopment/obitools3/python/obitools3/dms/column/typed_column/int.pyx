#cython: language_level=3

from obitools3.dms.capi.obierrno cimport obi_errno

from ..column cimport register_column_class

from ...view.view cimport View

from obitools3.utils cimport tobytes, \
                             obi_errno_to_exception

from ...capi.obiview cimport obi_get_int_with_elt_name_and_col_p_in_view, \
                             obi_get_int_with_elt_idx_and_col_p_in_view, \
                             obi_set_int_with_elt_name_and_col_p_in_view, \
                             obi_set_int_with_elt_idx_and_col_p_in_view, \
                             obi_get_array_with_col_p_in_view, \
                             obi_set_array_with_col_p_in_view, \
                             Obiview_p

from ...capi.obidmscolumn cimport OBIDMS_column_p

from ...capi.obitypes     cimport OBI_INT, \
                                  OBIInt_NA, \
                                  OBITuple_NA, \
                                  obiint_t

from cpython.int cimport PyInt_FromLong

from libc.stdint cimport int32_t

from libc.stdlib  cimport malloc, free


cdef class Column_int(Column):

    @staticmethod
    def new(View    view,
            object  column_name,
            index_t nb_elements_per_line=1,
            object  elements_names=None,
            bint    tuples=False,
            object  comments={}):
        
        return Column.new_column(view, column_name, OBI_INT,
                                 nb_elements_per_line=nb_elements_per_line, 
                                 elements_names=elements_names, 
                                 tuples=tuples,
                                 comments=comments)


    cpdef object get_line(self, index_t line_nb):
        global obi_errno
        cdef   obiint_t value
        cdef   object result 
        value = obi_get_int_with_elt_idx_and_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, 0)
        obi_errno_to_exception(line_nb=line_nb, elt_id=None, error_message="Problem getting a value from a column")
        if value == OBIInt_NA :
            result = None
        else :
            result = PyInt_FromLong(value)
        return result
    
    
    cpdef set_line(self, index_t line_nb, object value):
        global obi_errno
        if value is None :
            value = OBIInt_NA
        if obi_set_int_with_elt_idx_and_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, 0, <obiint_t> value) < 0:
            obi_errno_to_exception(line_nb=line_nb, elt_id=None, error_message="Problem setting a value in a column")
 
 
cdef class Column_multi_elts_int(Column_multi_elts):
 
    cpdef object get_item(self, index_t line_nb, object elt_id) :
        global obi_errno
        cdef   obiint_t  value
        cdef   object    result
        cdef   bytes     elt_name
        if type(elt_id) == int :
            value = obi_get_int_with_elt_idx_and_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, elt_id)
        else :
            elt_name = tobytes(elt_id)
            value = obi_get_int_with_elt_name_and_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, elt_name)
        obi_errno_to_exception(line_nb=line_nb, elt_id=elt_id, error_message="Problem getting a value from a column")
        if value == OBIInt_NA :
            result = None
        else :
            result = PyInt_FromLong(value)
        return result
    
    cpdef object get_line(self, index_t line_nb) :
        global obi_errno
        cdef   obiint_t        value
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
            value = obi_get_int_with_elt_idx_and_col_p_in_view(view_p, column_p, line_nb, i)
            obi_errno_to_exception(line_nb=line_nb, elt_id=i, error_message="Problem getting a value from a column")
            if value != OBIInt_NA :
                value_in_result = PyInt_FromLong(value)
                result[elements_names[i]] = value_in_result
                if all_NA :
                    all_NA = False
        if all_NA :
            result = None
        return result
    
    cpdef set_item(self, index_t line_nb, object elt_id, object value) :
        global obi_errno
        cdef   bytes elt_name
        if value is None :
            value = OBIInt_NA
        if type(elt_id) == int :
            if obi_set_int_with_elt_idx_and_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, elt_id, <obiint_t> value) < 0 :
                obi_errno_to_exception(line_nb=line_nb, elt_id=elt_id, error_message="Problem setting a value in a column")
        else :
            elt_name = tobytes(elt_id)
            if obi_set_int_with_elt_name_and_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, elt_name, <obiint_t> value) < 0 :
                obi_errno_to_exception(line_nb=line_nb, elt_id=elt_id, error_message="Problem setting a value in a column")


cdef class Column_tuples_int(Column):
    
    cpdef object get_line(self, index_t line_nb) :
        global obi_errno
        cdef   obiint_t        value
        cdef   int             value_in_result
        cdef   object          result
        cdef   int32_t         i
        cdef   obiint_t*       array
        cdef   int32_t         value_length
        
        result = []
        
        array = <obiint_t*>obi_get_array_with_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, &value_length)
        obi_errno_to_exception(line_nb=line_nb, elt_id=None, error_message="Problem getting a value from a column")

        if array == OBITuple_NA :
            return None

        for i in range(value_length) :
            value = array[i]
            value_in_result = PyInt_FromLong(value)
            result.append(value_in_result)
        
        return tuple(result)


    cpdef set_line(self, index_t line_nb, object value) :
        global             obi_errno
        cdef   obiint_t*   array
        cdef   int32_t     value_length
        cdef   int32_t     i, j
        cdef   object      e
                
        value_length = 0
        if value is not None:
            for e in value:
                if e is not None:
                    value_length+=1
        if value is None or value_length == 0 :
            array = <obiint_t*>OBITuple_NA
        else:
            array = <obiint_t*>malloc(value_length * sizeof(obiint_t))
            if array == NULL:
                raise Exception("Problem allocating memory for an array to store a tuple")
                #raise RollbackException("Problem allocating memory for an array to store a tuple", self._view) # TODO can't import
            j=0
            for i in range(len(value)) :
                if value[i] is not None:
                    array[j] = <obiint_t>(value[i])
                    j+=1

        if obi_set_array_with_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, <obiint_t*> array, sizeof(obiint_t)*8, value_length) < 0 :
            obi_errno_to_exception(line_nb=line_nb, elt_id=None, error_message="Problem setting a value in a column")

        if array != <obiint_t*>OBITuple_NA:
            free(array)


def register_class():
    register_column_class(OBI_INT, False, False, Column_int, int)
    register_column_class(OBI_INT, True, False, Column_multi_elts_int, int)
    register_column_class(OBI_INT, False, True, Column_tuples_int, int)

