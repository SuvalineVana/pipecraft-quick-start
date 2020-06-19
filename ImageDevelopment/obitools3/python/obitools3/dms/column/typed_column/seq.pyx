#cython: language_level=3

from obitools3.dms.capi.obierrno cimport obi_errno

from ..column cimport register_column_class

from ...view.view cimport View

from ..column cimport Column

from obitools3.utils cimport tobytes, \
                             obi_errno_to_exception

from ...capi.obiview cimport obi_get_seq_with_elt_name_and_col_p_in_view, \
                             obi_get_seq_with_elt_idx_and_col_p_in_view, \
                             obi_set_seq_with_elt_name_and_col_p_in_view, \
                             obi_set_seq_with_elt_idx_and_col_p_in_view, \
                             obi_get_array_with_col_p_in_view, \
                             obi_set_array_with_col_p_in_view, \
                             obi_get_array_with_col_p_in_view, \
                             obi_set_array_with_col_p_in_view, \
                             Obiview_p

from ...capi.obidmscolumn cimport OBIDMS_column_p

from ...capi.obitypes     cimport OBI_SEQ, \
                                  OBISeq_NA, \
                                  OBITuple_NA

from libc.stdint cimport int32_t
from libc.stdlib  cimport calloc, free
from libc.string  cimport strcpy


cdef class Column_seq(Column_idx):

    @staticmethod
    def new(View    view,
            object  column_name,
            index_t nb_elements_per_line=1,
            object  elements_names=None,
            bint    tuples=False,
            object  comments={}):
        
        return Column.new_column(view, column_name, OBI_SEQ,
                                 nb_elements_per_line=nb_elements_per_line, 
                                 elements_names=elements_names, 
                                 tuples=tuples,
                                 comments=comments)


    cpdef object get_line(self, index_t line_nb):
        global obi_errno
        cdef   char*  value
        cdef   object result
        value = obi_get_seq_with_elt_idx_and_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, 0)
        obi_errno_to_exception(line_nb=line_nb, elt_id=None, error_message="Problem getting a value from a column")
        if value == OBISeq_NA :
            result = None
        else :   # TODO
            try:
                result = <bytes> value
            finally:
                free(value)
        return result


    cpdef set_line(self, index_t line_nb, object value):
        global obi_errno
        cdef   char* value_b
        cdef   bytes value_bytes
        
        if value is None :
            value_b = <char*>OBISeq_NA
        else :
            value_bytes = tobytes(value)
            value_b = <char*>value_bytes
        
        if obi_set_seq_with_elt_idx_and_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, 0, value_b) < 0:
            obi_errno_to_exception(line_nb=line_nb, elt_id=None, error_message="Problem setting a value in a column")
 
 
cdef class Column_multi_elts_seq(Column_multi_elts_idx):
 
    cpdef object get_item(self, index_t line_nb, object elt_id) :
        global obi_errno
        cdef   char*  value
        cdef   object result
        if type(elt_id) == int :
            value = obi_get_seq_with_elt_idx_and_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, elt_id)
        else :
            elt_name = tobytes(elt_id)
            value = obi_get_seq_with_elt_name_and_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, elt_name)
        obi_errno_to_exception(line_nb=line_nb, elt_id=elt_id, error_message="Problem getting a value from a column")
        if value == OBISeq_NA :
            result = None
        else :
            try:
                result = <bytes> value
            finally:
                free(value)
        return result


    cpdef object get_line(self, index_t line_nb) :
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
            value = obi_get_seq_with_elt_idx_and_col_p_in_view(view_p, column_p, line_nb, i)
            obi_errno_to_exception(line_nb=line_nb, elt_id=i, error_message="Problem getting a value from a column")
            if value != OBISeq_NA :
                try:
                    value_in_result = <bytes> value
                finally:
                    free(value)    
                result[elements_names[i]] = value_in_result
                if all_NA :
                    all_NA = False
        if all_NA :
            result = None
        return result


    cpdef set_item(self, index_t line_nb, object elt_id, object value):
        global obi_errno
        cdef   bytes elt_name
        cdef   char* value_b
        cdef   bytes value_bytes
        
        if value is None :
            value_b = <char*>OBISeq_NA
        else :
            value_bytes = tobytes(value)
            value_b = <char*>value_bytes
        
        if type(elt_id) == int :
            if obi_set_seq_with_elt_idx_and_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, elt_id, value_b) < 0:
                obi_errno_to_exception(line_nb=line_nb, elt_id=elt_id, error_message="Problem setting a value in a column")
        
        else :
            elt_name = tobytes(elt_id)
            if obi_set_seq_with_elt_name_and_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, elt_name, value_b) < 0:
                obi_errno_to_exception(line_nb=line_nb, elt_id=elt_id, error_message="Problem setting a value in a column")


cdef class Column_tuples_seq(Column_idx):
    
    cpdef object get_line(self, index_t line_nb) :
        global obi_errno
        cdef   const char*     value
        cdef   bytes           value_in_result
        cdef   object          result
        cdef   int32_t         i
        cdef   const char*     array
        cdef   int32_t         value_length
        
        result = []
        
        array = <const char*>obi_get_array_with_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, &value_length)
        obi_errno_to_exception(line_nb=line_nb, elt_id=None, error_message="Problem getting a value from a column")
        
        if array == OBITuple_NA :
            return None
        
        i = 0
        # First value
        value_in_result = <bytes> array
        result.append(value_in_result)
        while i+1 < value_length :
            if array[i] != b'\0' :
                i+=1
            else :
                value = array+i+1
                value_in_result = <bytes> value
                result.append(value_in_result)
                i+=1
        
        return tuple(result)
    
    cpdef set_line(self, index_t line_nb, object value) :
        global           obi_errno
        cdef   char*     array
        cdef   int32_t   value_length
        cdef   int32_t   i
        cdef   object    elt
        cdef   bytes     elt_b
                
        value_length = 0
        if value is not None:
            for i in range(len(value)) :
                if value[i] is not None and value[i] != '' :
                    value_length = value_length + len(value[i]) + 1   # Total size of the array with the '\0'               
        if value is None or value_length == 0 :
            array = <char*>OBITuple_NA
        else:
            array = <char*>calloc(value_length, sizeof(char))
            if array == NULL:
                raise Exception("Problem allocating memory for an array to store a tuple")
            #raise RollbackException("Problem allocating memory for an array to store a tuple", self._view) # TODO can't import
            i = 0
            for elt in value :
                if elt is not None and elt != '':
                    elt_b = tobytes(elt)
                    strcpy(array+i, <char*>elt_b)
                    i = i + len(elt_b) + 1

        if obi_set_array_with_col_p_in_view(self._view.pointer(), self.pointer(), line_nb, <char*> array, sizeof(char)*8, value_length) < 0 :
            obi_errno_to_exception(line_nb=line_nb, elt_id=None, error_message="Problem setting a value in a column")
        
        if array != <char*>OBITuple_NA:
            free(array)


def register_class():
    register_column_class(OBI_SEQ, False, False, Column_seq, bytes)
    register_column_class(OBI_SEQ, True, False, Column_multi_elts_seq, bytes)
    register_column_class(OBI_SEQ, False, True, Column_tuples_seq, bytes)

