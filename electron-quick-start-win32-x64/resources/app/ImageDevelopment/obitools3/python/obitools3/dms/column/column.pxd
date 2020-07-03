#cython: language_level=3


from ..capi.obitypes     cimport index_t, \
                                 obitype_t
                                 
from ..capi.obidmscolumn cimport OBIDMS_column_p
                                                                 
from ..view.view cimport View
 
from ..object cimport OBIWrapper                          

 
cdef dict __OBIDMS_COLUMN_CLASS__


cdef class Column(OBIWrapper) :
 
    cdef View  _view
    cdef bytes _alias
    cdef list  _elements_names
    
    cdef inline OBIDMS_column_p pointer(self)
    cdef read_elements_names(self)
    
    @staticmethod
    cdef type get_column_class(obitype_t obitype, bint multi_elts, bint tuples)

    @staticmethod
    cdef type get_python_type(obitype_t obitype, bint multi_elts)

cdef class Column_comments(dict):
    cdef Column  _column


cdef class Column_multi_elts(Column) :

    # The type of [values] can be dict, Column_line, or any other class with values referenced by keys with an iterator [for key in values]
    cpdef set_line(self, index_t line_nb, object values)


cdef class Column_line:
 
    cdef Column    _column
    cdef index_t   _index
    
    cpdef list keys(self)
    cpdef list items(self)
    cpdef dict dict(self)
    cpdef bytes bytes(self)  
    cpdef update(self, object data)
     
    
cdef register_column_class(obitype_t obitype,
                           bint multi_elts,
                           bint tuples,
                           type obiclass, 
                           type python)

cdef register_all_column_classes()

