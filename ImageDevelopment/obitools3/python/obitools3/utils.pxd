#cython: language_level=3

from obitools3.dms.capi.obitypes cimport obitype_t, index_t

cpdef bytes format_separator(bytes format)
cpdef int count_entries(file, bytes format)

cdef obi_errno_to_exception(index_t line_nb=*, object elt_id=*, str error_message=*)

cdef bytes str2bytes(str string)
cdef str bytes2str(bytes string)
cdef bytes tobytes(object string)
cdef str tostr(object string)
cdef object bytes2str_object(object value)
cdef object str2bytes_object(object value)

cdef object clean_empty_values_from_object(object value, exclude=*)

cdef obitype_t get_obitype_single_value(object value)
cdef obitype_t update_obitype(obitype_t obitype, object new_value)
cdef obitype_t get_obitype_iterable_value(object value)
cdef obitype_t get_obitype(object value)

cdef object __etag__(bytes x, bytes nastring=*)
