# #cython: language_level=3
 

from ...capi.obitypes cimport index_t

from ..column_idx cimport Column_idx, \
                          Column_multi_elts_idx


cdef class Column_qual(Column_idx) :

    cpdef object get_line(self, index_t line_nb)
    cpdef object get_bytes_line(self, index_t line_nb, int offset=*)
    cpdef set_line(self, index_t line_nb, object value)
    cpdef set_bytes_line(self, index_t line_nb, object value, int offset=*)


cdef class Column_multi_elts_qual(Column_multi_elts_idx) :

    cpdef object get_item(self, index_t line_nb, object elt_id)
    cpdef object get_bytes_item(self, index_t line_nb, object elt_id, int offset=*)
    cpdef object get_line(self, index_t line_nb)
    cpdef object get_bytes_line(self, index_t line_nb, int offset=*)
    cpdef set_item(self, index_t line_nb, object elt_id, object value)
    cpdef set_bytes_item(self, index_t line_nb, object elt_id, object value, int offset=*)
    