#cython: language_level=3

from ..capi.obitaxonomy cimport ecotx_t, OBIDMS_taxonomy_p

from ..dms cimport DMS

from ..object cimport OBIWrapper                          


cdef class Taxonomy(OBIWrapper) :
    cdef bytes  _name
    cdef DMS    _dms
    cdef list   _ranks
    
    cdef inline OBIDMS_taxonomy_p pointer(self)

    cpdef Taxon get_taxon_by_idx(self, int idx)
    cpdef Taxon get_taxon_by_taxid(self, int taxid)
    cpdef write(self, object prefix)
    cpdef int add_taxon(self, str name, str rank_name, int parent_taxid, int min_taxid=*)
    cpdef object get_species(self, int taxid)
    cpdef object get_genus(self, int taxid)
    cpdef object get_family(self, int taxid)
    cpdef bytes get_scientific_name(self, int taxid)
    cpdef bytes get_rank(self, int taxid)
    cpdef object get_taxon_at_rank(self, int taxid, object rank)


cdef class Taxon :
    cdef ecotx_t*  _pointer
    cdef Taxonomy  _tax