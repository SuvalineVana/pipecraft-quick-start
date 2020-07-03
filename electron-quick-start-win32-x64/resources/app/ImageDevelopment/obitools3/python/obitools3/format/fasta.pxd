from ..utils cimport bytes2str
from .header cimport HeaderFormat
from cython.view cimport array as cvarray

cdef class FastaFormat:

    cdef HeaderFormat headerFormatter
    
    cdef size_t  sequenceBufferLength
    cdef char*   sequenceBuffer
