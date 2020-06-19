#cython: language_level=3

from .obitypes     cimport const_char_p
from .obidms       cimport OBIDMS_p
from libc.stdint   cimport int32_t


cdef extern from "obidms_taxonomy.h" nogil:

    struct ecotxnode :
        int32_t           taxid
        int32_t           rank
        int32_t           farest
        ecotxnode*        parent
        char*             name
        char*             preferred_name

    ctypedef ecotxnode ecotx_t


    struct ecotxidx_t :   
        int32_t  count
        int32_t  max_taxid
        int32_t  buffer_size
        ecotx_t* taxon


    struct ecorankidx_t :   
        int32_t  count
        char**   label


    struct OBIDMS_taxonomy_t :
        ecorankidx_t* ranks
#        econameidx_t* names
        ecotxidx_t*   taxa

    ctypedef OBIDMS_taxonomy_t* OBIDMS_taxonomy_p
    
    
    int obi_taxonomy_exists(OBIDMS_p dms, const char* taxonomy_name)
    
    OBIDMS_taxonomy_p obi_read_taxonomy(OBIDMS_p dms, const_char_p taxonomy_name, bint read_alternative_names)

    OBIDMS_taxonomy_p obi_read_taxdump(const_char_p taxdump)
    
    int obi_write_taxonomy(OBIDMS_p dms, OBIDMS_taxonomy_p tax, const_char_p tax_name)

    int obi_close_taxonomy(OBIDMS_taxonomy_p taxonomy)
    
    ecotx_t* obi_taxo_get_parent_at_rank(ecotx_t* taxon, int32_t rankidx)
    
    ecotx_t* obi_taxo_get_taxon_with_taxid(OBIDMS_taxonomy_p taxonomy, int32_t taxid)
    
    bint obi_taxo_is_taxon_under_taxid(ecotx_t* taxon, int32_t other_taxid)
    
    ecotx_t* obi_taxo_get_species(ecotx_t* taxon, OBIDMS_taxonomy_p taxonomy)
    
    ecotx_t* obi_taxo_get_genus(ecotx_t* taxon, OBIDMS_taxonomy_p taxonomy)
    
    ecotx_t* obi_taxo_get_family(ecotx_t* taxon, OBIDMS_taxonomy_p taxonomy)
    
    ecotx_t* obi_taxo_get_kingdom(ecotx_t* taxon, OBIDMS_taxonomy_p taxonomy)
    
    ecotx_t* obi_taxo_get_superkingdom(ecotx_t* taxon, OBIDMS_taxonomy_p taxonomy)
    
    int obi_taxo_add_local_taxon(OBIDMS_taxonomy_p tax, const char* name, const char* rank_name, int32_t parent_taxid, int32_t min_taxid)

    int obi_taxo_add_preferred_name_with_taxid(OBIDMS_taxonomy_p tax, int32_t taxid, const char* preferred_name)

    int obi_taxo_add_preferred_name_with_taxon(OBIDMS_taxonomy_p tax, ecotx_t* taxon, const char* preferred_name)

    const char* obi_taxo_rank_index_to_label(int32_t rank_idx, ecorankidx_t* ranks)
    