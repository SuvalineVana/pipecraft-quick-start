#cython: language_level=3

from obitools3.dms.capi.obidms       cimport OBIDMS_p
from libc.stdint  cimport int32_t


cdef extern from "obi_ecopcr.h" nogil:

    int obi_ecopcr(const char* input_dms_name,
                   const char* i_view_name,
                   const char* taxonomy_name,
                   const char* output_dms_name,
                   const char* o_view_name,
                   const char* o_view_comments,
                   const char* primer1,
                   const char* primer2,
                   int error_max,
                   int min_len,
                   int max_len,
                   int32_t* restrict_to_taxids,
                   int32_t* ignore_taxids,
                   int circular,
                   double salt_concentration,
                   int salt_correction_method,
                   int keep_nucleotides,
                   bint keep_primers,
                   bint kingdom_mode)

    
