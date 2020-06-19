#cython: language_level=3

from .view.view cimport Line


cdef class Seq(dict) :

    cdef int _index
    cpdef object clone(self)
    cpdef str get_str(self)
    cpdef get_symbol_at(self, int pos)
    cpdef get_slice(self, slice slice_to_get)
    
    
cdef class Nuc_Seq(Seq) :
    
    cdef  Nuc_Seq _reverse_complement
    cdef  object  _quality_array
    cdef  bint    _is_revcomp
    cpdef set_quality(self, object new_quality, int offset=*)  
    cpdef object build_quality_array(self, list quality)
    cpdef bytes  build_reverse_complement(self)
    

cdef class Seq_Stored(Line) :

    cpdef get_symbol_at(self, int pos)
    cpdef get_slice(self, slice slice_to_get)


cdef class Nuc_Seq_Stored(Seq_Stored) :
    
    cdef  Nuc_Seq _reverse_complement
    cdef  object  _quality_array
    cdef  bytes   _seq
    
    cpdef set(self, object id, object seq, object definition=*, object quality=*, int offset=*, object tags=*)
    cpdef set_quality_int(self, list new_qual)
    cpdef set_quality_char(self, object new_qual, int offset=*)
    cpdef object build_quality_array(self, list quality)
    cpdef bytes build_reverse_complement(self)
    cpdef str get_str(self)