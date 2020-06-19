# #cython: language_level=3
 

from ...capi.obitypes cimport index_t

from ..column cimport Column, \
                      Column_multi_elts


cdef class Column_float(Column) :

    cpdef object get_line(self, index_t line_nb)
    cpdef set_line(self, index_t line_nb, object value)


cdef class Column_multi_elts_float(Column_multi_elts) :

    cpdef object get_item(self, index_t line_nb, object elt_id)
    cpdef object get_line(self, index_t line_nb)
    cpdef set_item(self, index_t line_nb, object elt_id, object value)


cdef class Column_tuples_float(Column):

    cpdef object get_line(self, index_t line_nb)
    cpdef set_line(self, index_t line_nb, object value)
