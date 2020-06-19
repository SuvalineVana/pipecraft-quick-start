# #cython: language_level=3
 

from ..capi.obitypes cimport index_t

from .column cimport Column, \
                      Column_multi_elts


cdef class Column_idx(Column) :

    cpdef object get_line_idx(self, index_t line_nb)
    cpdef set_line_idx(self, index_t line_nb, object value)


cdef class Column_multi_elts_idx(Column_multi_elts) :

    cpdef object get_item_idx(self, index_t line_nb, object elt_id)
    cpdef object get_line_idx(self, index_t line_nb)
    cpdef set_item_idx(self, index_t line_nb, object elt_id, object value)
    cpdef set_line_idx(self, index_t line_nb, object values)
