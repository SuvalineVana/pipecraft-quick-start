#cython: language_level=3

from obitools3.dms.dms cimport DMS
from obitools3.dms.view.view cimport View
from obitools3.dms.column.column cimport Column
from obitools3.dms.taxo.taxo cimport Taxonomy

from obitools3.utils cimport tobytes, tostr
from obitools3.files.universalopener cimport uopen

cdef open_dms(bytes path, bint create=?)
