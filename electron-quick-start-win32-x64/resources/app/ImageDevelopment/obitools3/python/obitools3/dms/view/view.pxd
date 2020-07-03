#cython: language_level=3


from ..capi.obiview cimport Obiview_p

from ..capi.obitypes cimport index_t, obitype_t

from ..object cimport OBIWrapper                          

from ..dms cimport DMS

from ..column.column cimport Column


cdef dict __OBIDMS_VIEW_CLASS__


cdef class View(OBIWrapper):
    
    cdef DMS _dms
    
    cdef inline Obiview_p pointer(self)   
        
    cpdef delete_column(self, 
                        object column_name,
                        bint delete_file=*)
    
    cpdef rename_column(self, 
                        object current_name, 
                        object new_name)
    
    cpdef Column rewrite_column_with_diff_attributes(self,
                                                     object    column_name,
                                                     obitype_t new_data_type=*,
                                                     index_t   new_nb_elements_per_line=*,
                                                     list      new_elements_names=*,
                                                     bint      rewrite_last_line=*)

    cpdef Line_selection new_selection(self,
                                       list lines=*)


cdef class View_comments(dict):
    cdef View _view
    
    
cdef class Line_selection(list):
    
    cdef View  _view
    cdef bytes _view_name
    
    cdef index_t* __build_binary_list__(self)

    cpdef View materialize(self,
                           object view_name,
                           object comments=*)


cdef class Line :

    cdef index_t _index
    cdef View    _view
    

cdef register_view_class(bytes view_type_name,
                         type view_class)

cdef register_all_view_classes()
