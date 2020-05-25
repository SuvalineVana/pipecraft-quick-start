#cython: language_level=3


from libc.stdint cimport int32_t, int64_t, uint8_t

from posix.types cimport time_t


cdef extern from *:
    ctypedef char* const_char_p "const char*"


cdef extern from "encode.h" nogil:
    bint only_ATGC(const_char_p seq)
    bint only_IUPAC_DNA(const_char_p seq)
    bint is_a_DNA_seq(const_char_p seq)


cdef extern from "obitypes.h" nogil:

    enum OBIType:
        OBI_VOID,
        OBI_INT,
        OBI_FLOAT,
        OBI_BOOL,
        OBI_CHAR,
        OBI_QUAL,
        OBI_STR,
        OBI_SEQ,
        OBI_IDX

    
    ctypedef OBIType OBIType_t
    
    enum OBIBool:
        pass
    
    ctypedef OBIBool obibool_t
    ctypedef int32_t obiint_t
    ctypedef double  obifloat_t
    ctypedef char    obichar_t  
    ctypedef int64_t index_t

    ctypedef int32_t obiversion_t

    extern obiint_t      OBIInt_NA
    extern index_t       OBIIdx_NA
    extern obifloat_t    OBIFloat_NA
    extern obichar_t     OBIChar_NA
    extern obibool_t     OBIBool_NA
    extern const_char_p  OBISeq_NA
    extern const_char_p  OBIStr_NA
    extern const_char_p  OBIQual_char_NA
    extern uint8_t*      OBIQual_int_NA
    extern void*         OBITuple_NA

    const_char_p name_data_type(int data_type)

ctypedef OBIType_t obitype_t
