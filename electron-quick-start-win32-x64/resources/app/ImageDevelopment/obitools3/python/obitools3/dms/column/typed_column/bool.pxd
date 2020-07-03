# #cython: language_level=3


from ...capi.obitypes cimport index_t

from ..column cimport Column, \
                      Column_multi_elts


cdef class Column_bool(Column) :

    cpdef object get_line(self, index_t line_nb)
    cpdef set_line(self, index_t line_nb, object value)


cdef class Column_multi_elts_bool(Column_multi_elts) :

    cpdef object get_item(self, index_t line_nb, object elt_id)
    cpdef object get_line(self, index_t line_nb)
    cpdef set_item(self, index_t line_nb, object elt_id, object value)
    
    
cdef class Column_tuples_bool(Column):

    cpdef object get_line(self, index_t line_nb)
    cpdef set_line(self, index_t line_nb, object value)
    
    
    
    
    
# cdef class Column_line_bool(Column_line) :
#         
#     @staticmethod
#     cdef bool obibool_t2bool(obibool_t value)
#     
#     @staticmethod
#     cdef bool2obibool_t(bool value)
#     
#     cpdef bool get_bool_item_by_name(self,bytes element_name)
#     cpdef bool get_bool_item_by_idx(self,index_t index)
#     cpdef set_bool_item_by_name(self,bytes element_name,bool value)
#     cpdef set_bool_item_by_idx(self,index_t index,bool value)
# 
#       
# #    cdef obibool_t [:]    _data_view
#