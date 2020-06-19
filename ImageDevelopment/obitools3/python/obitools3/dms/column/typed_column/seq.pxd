# #cython: language_level=3
 

from ...capi.obitypes cimport index_t

from ..column_idx cimport Column_idx, \
                          Column_multi_elts_idx


cdef class Column_seq(Column_idx) :

    cpdef object get_line(self, index_t line_nb)
    cpdef set_line(self, index_t line_nb, object value)


cdef class Column_multi_elts_seq(Column_multi_elts_idx) :

    cpdef object get_item(self, index_t line_nb, object elt_id)
    cpdef object get_line(self, index_t line_nb)
    cpdef set_item(self, index_t line_nb, object elt_id, object value)


cdef class Column_tuples_seq(Column_idx):

    cpdef object get_line(self, index_t line_nb)
    cpdef set_line(self, index_t line_nb, object value)
