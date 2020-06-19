#cython: language_level=3

from obitools3.dms.capi.obierrno cimport obi_errno

from ..column cimport register_column_class

from ...view.view cimport View

from obitools3.utils cimport tobytes, \
                             obi_errno_to_exception

from ...capi.obiview cimport obi_get_float_with_elt_name_and_col_p_in_view, \
                             obi_get_float_with_elt_idx_and_col_p_in_view, \
                             obi_set_float_with_elt_name_and_col_p_in_view, \
                             obi_set_float_with_elt_idx_and_col_p_in_view, \
                             obi_get_array_with_col_p_in_view, \
                             obi_set_array_with_col_p_in_view, \
                             Obiview_p

from ...capi.obidmscolumn cimport OBIDMS_column_p

from ...capi.obitypes     cimport OBI_FLOAT, \
                                  OBIFloat_NA, \
                                  OBITuple_NA, \
                                  obifloat_t

from libc.stdint cimport int32_t

from libc.stdlib  cimport malloc, free


cdef class Column_float(Column):

    @staticmethod
    def new(View    view,
            object  column_name,
            index_t nb_elements_per_line=1,
            object  elements_names=None,
            bint    tuples=False,
            object  comments={}):
        
        return Column.new_column(view, column_name, OBI_FLOAT,
                                 nb_elements_per_line=nb_elements_per_line, 
                                 elements_names=elements_names, 
                                 tuples=tuples,
                                 comments=comments)

    cpdef object get_line(self, index_t line_nb):
        global obi_errno
        cdef   obifloat_t value
        cdef   object     result 
        value = obi_get_float_with_elt_idx_and_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, 0)
        obi_errno_to_exception(line_nb=line_nb, elt_id=None, error_message="Problem getting a value from a column")
        if value == OBIFloat_NA :
            result = None
        else :
            result = <double> value
        return result
    
    cpdef set_line(self, index_t line_nb, object value):
        global obi_errno
        if value is None :
            value = OBIFloat_NA
        if obi_set_float_with_elt_idx_and_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, 0, <obifloat_t> value) < 0:
            obi_errno_to_exception(line_nb=line_nb, elt_id=None, error_message="Problem setting a value in a column")
 
 
cdef class Column_multi_elts_float(Column_multi_elts):
 
    cpdef object get_item(self, index_t line_nb, object elt_id) :
        global obi_errno
        cdef   obifloat_t value
        cdef   object     result
        cdef   bytes      elt_name
        if type(elt_id) == int :
            value = obi_get_float_with_elt_idx_and_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, elt_id)
        else :
            elt_name = tobytes(elt_id)
            value = obi_get_float_with_elt_name_and_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, elt_name)
        obi_errno_to_exception(line_nb=line_nb, elt_id=elt_id, error_message="Problem getting a value from a column")
        if value == OBIFloat_NA :
            result = None
        else :
            result = <double> value
        return result
    
    cpdef object get_line(self, index_t line_nb) :
        global obi_errno
        cdef   obifloat_t      value
        cdef   double          value_in_result
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
            value = obi_get_float_with_elt_idx_and_col_p_in_view(view_p, column_p, line_nb, i)
            obi_errno_to_exception(line_nb=line_nb, elt_id=i, error_message="Problem getting a value from a column")
            if value != OBIFloat_NA :
                value_in_result = <double> value
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
            value = OBIFloat_NA
        if type(elt_id) == int :
            if obi_set_float_with_elt_idx_and_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, elt_id, <obifloat_t> value) < 0 :
                obi_errno_to_exception(line_nb=line_nb, elt_id=elt_id, error_message="Problem setting a value in a column")
        else :
            elt_name = tobytes(elt_id)
            if obi_set_float_with_elt_name_and_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, elt_name, <obifloat_t> value) < 0 :
                obi_errno_to_exception(line_nb=line_nb, elt_id=elt_id, error_message="Problem setting a value in a column")


cdef class Column_tuples_float(Column):
    
    cpdef object get_line(self, index_t line_nb) :
        global obi_errno
        cdef   obifloat_t      value
        cdef   double          value_in_result
        cdef   object          result
        cdef   int32_t         i
        cdef   obifloat_t*     array
        cdef   int32_t         value_length
        
        result = []
        
        array = <obifloat_t*>obi_get_array_with_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, &value_length)
        obi_errno_to_exception(line_nb=line_nb, elt_id=None, error_message="Problem getting a value from a column")

        if array == OBITuple_NA :
            return None

        for i in range(value_length) :
            value = array[i]
            value_in_result = <double> value
            result.append(value_in_result)
        
        return tuple(result)


    cpdef set_line(self, index_t line_nb, object value) :
        global             obi_errno
        cdef   obifloat_t* array
        cdef   int32_t     value_length
        cdef   int32_t     i, j
        cdef   object      e
            
        value_length = 0
        if value is not None:
            for e in value:
                if e is not None:
                    value_length+=1
        if value is None or value_length == 0 :
            array = <obifloat_t*>OBITuple_NA
        else:
            array = <obifloat_t*>malloc(value_length * sizeof(obifloat_t))
            if array == NULL:
                raise Exception("Problem allocating memory for an array to store a tuple")
                #raise RollbackException("Problem allocating memory for an array to store a tuple", self._view) # TODO can't import
            j=0
            for i in range(len(value)) :
                if value[i] is not None:
                    array[j] = <obifloat_t>(value[i])
                    j+=1
                    
        if obi_set_array_with_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, <obifloat_t*> array, sizeof(obifloat_t)*8, value_length) < 0 :
            obi_errno_to_exception(line_nb=line_nb, elt_id=None, error_message="Problem setting a value in a column")
                    
        if array != <obifloat_t*>OBITuple_NA:
            free(array)


def register_class():
    register_column_class(OBI_FLOAT, False, False, Column_float, float)    # TODO why not double?
    register_column_class(OBI_FLOAT, True, False, Column_multi_elts_float, float)    # TODO why not double?
    register_column_class(OBI_FLOAT, False, True, Column_tuples_float, float)

