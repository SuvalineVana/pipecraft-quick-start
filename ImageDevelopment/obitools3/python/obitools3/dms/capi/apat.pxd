#cython: language_level=3

from obitools3.dms.capi.obiview cimport Obiview_p
from obitools3.dms.capi.obidmscolumn cimport OBIDMS_column_p
from obitools3.dms.capi.obitypes cimport index_t

from libc.stdint  cimport int32_t, uint32_t, uint8_t


cdef extern from "libecoPCR/libapat/libstki.h" nogil:

    struct Stacki :
            int32_t    size
            int32_t    top
            int32_t    cursor
            int32_t*   val

    ctypedef Stacki* StackiPtr      


cdef extern from "libecoPCR/libapat/apat.h" nogil:

    extern int MAX_PATTERN

    struct Seq :
        char*      name
        int32_t    seqlen
        int32_t    seqsiz
        int32_t    datsiz
        int32_t    circular
        uint8_t*   data
        char*      cseq
        StackiPtr* hitpos
        StackiPtr* hiterr

    ctypedef Seq* SeqPtr


    struct Pattern :
        int       patlen
        int       maxerr
        char*     cpat
        int32_t*  patcode
        uint32_t* smat
        uint32_t  omask
        bint      hasIndel
        bint      ok

    ctypedef Pattern* PatternPtr


    int32_t ManberAll(Seq *pseq, Pattern *ppat, int patnum, int begin, int length)


cdef extern from "libecoPCR/ecoPCR.h" nogil:

    SeqPtr     ecoseq2apatseq(char* sequence, SeqPtr out, int32_t circular)
    int32_t    delete_apatseq(SeqPtr pseq)
    PatternPtr buildPattern(const char *pat, int32_t error_max)
    PatternPtr complementPattern(PatternPtr pat)

