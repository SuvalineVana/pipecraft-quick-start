#cython: language_level=3

from obitools3.utils cimport str2bytes, bytes2str, tobytes, tostr
from ..capi.obidms cimport OBIDMS_p, obi_dms_get_full_path
                          
from ..capi.obitaxonomy cimport obi_taxonomy_exists, \
                                obi_read_taxonomy, \
                                obi_read_taxdump, \
                                obi_write_taxonomy, \
                                obi_close_taxonomy, \
                                obi_taxo_get_taxon_with_taxid, \
                                obi_taxo_add_local_taxon, \
                                obi_taxo_add_preferred_name_with_taxon, \
                                obi_taxo_rank_index_to_label, \
                                obi_taxo_get_species, \
                                obi_taxo_get_genus, \
                                obi_taxo_get_family, \
                                ecotx_t                
                                           
from cpython.pycapsule cimport PyCapsule_New, PyCapsule_GetPointer
import tarfile
from pathlib import Path
from libc.stdlib  cimport free


cdef class Taxonomy(OBIWrapper) :
    # TODO function to import taxonomy?
    
    cdef inline OBIDMS_taxonomy_p pointer(self) :
        return <OBIDMS_taxonomy_p>(self._pointer)        


    @staticmethod
    def exists(DMS dms, object name) :
        e = obi_taxonomy_exists(dms.pointer(), tobytes(name))
        if e < 0:
            raise RuntimeError("Error : Cannot check if taxonomy %s exists" 
                               % tostr(name))
        else:
            return e
    
    
    @staticmethod
    def list_taxos(DMS dms):
        
        cdef OBIDMS_p dms_p
        cdef const char* path
        
        dms_p = dms.pointer()
        path = obi_dms_get_full_path(dms_p, b"TAXONOMY")
        if path == NULL:
            raise RuntimeError("Cannot retrieve the taxonomy directory path")
        
        p = Path(bytes2str(path))
        free(path)
        
        for tax in p.glob("*") :
            yield str2bytes(tax.stem)


    @staticmethod
    def open(DMS dms, object name) :
        
        cdef void*    pointer
        cdef Taxonomy taxo
                
        pointer = <void*>obi_read_taxonomy(dms.pointer(), tobytes(name), True)        
        if pointer == NULL :
            raise RuntimeError("Error : Cannot read taxonomy %s" 
                               % tostr(name))

        taxo = OBIWrapper.new_wrapper(Taxonomy, pointer)

        dms.register(taxo)

        taxo._dms = dms
        taxo._name = tobytes(name)
        
        taxo._ranks = []
        for r in range((<OBIDMS_taxonomy_p>pointer).ranks.count) :
            taxo._ranks.append(obi_taxo_rank_index_to_label(r, (<OBIDMS_taxonomy_p>pointer).ranks))

        return taxo


    @staticmethod
    def open_taxdump(DMS dms, object path) :
        
        cdef void*    pointer
        cdef Taxonomy taxo
        cdef bytes    path_b
        cdef int      idx
        
        path_b = tobytes(path)
        folder_path = path_b

        if path_b.endswith(b"tar.gz") or path_b.endswith(b"tar"):
            idx = path_b.index(b".tar")
            folder_path = path_b[:idx]

        if path_b.endswith(b"tar.gz"):
            tar = tarfile.open(path_b, "r:gz")
            tar.extractall(path=tostr(folder_path))
            tar.close()
        elif path_b.endswith(b"tar"):
            tar = tarfile.open(path_b, "r:")
            tar.extractall(path=tostr(folder_path))
            tar.close()
            
        pointer = <void*>obi_read_taxdump(folder_path)        
        if pointer == NULL :
            raise RuntimeError("Error : Cannot read taxonomy %s" 
                               % tostr(folder_path))
        
        taxo = OBIWrapper.new_wrapper(Taxonomy, pointer)

        dms.register(taxo)

        taxo._dms = dms
        taxo._name = folder_path
        
        taxo._ranks = []
        for r in range((<OBIDMS_taxonomy_p>pointer).ranks.count) :
            taxo._ranks.append(obi_taxo_rank_index_to_label(r, (<OBIDMS_taxonomy_p>pointer).ranks))
                
        return taxo

    
    def __getitem__(self, object ref):     
        if type(ref) == int :
            return self.get_taxon_by_taxid(ref)
        else :
            raise NotImplementedError()


    cpdef Taxon get_taxon_by_taxid(self, int taxid):
        cdef ecotx_t* taxon_p
        cdef object   taxon_capsule        
        taxon_p = obi_taxo_get_taxon_with_taxid(self.pointer(), taxid)
        if taxon_p == NULL:
            raise Exception("Error getting a taxon with given taxid", taxid)
        taxon_capsule = PyCapsule_New(taxon_p, NULL, NULL)
        return Taxon(taxon_capsule, self)


    cpdef Taxon get_taxon_by_idx(self, int idx):
        cdef ecotx_t* taxa
        cdef ecotx_t* taxon_p
        cdef object   taxon_capsule
        if idx >= self.pointer().taxa.count :
            raise Exception("Error getting a taxon with given index: no taxid with this index", idx)
        taxa = self.pointer().taxa.taxon
        taxon_p = <ecotx_t*> (taxa+idx)
        taxon_capsule = PyCapsule_New(taxon_p, NULL, NULL)
        return Taxon(taxon_capsule, self)


    cpdef object get_species(self, int taxid):
        cdef ecotx_t* taxon_p
        cdef ecotx_t* species_p
        taxon_p = obi_taxo_get_taxon_with_taxid(self.pointer(), taxid)
        if taxon_p == NULL:
            raise Exception("Error getting a taxon with given taxid", taxid)
        species_p = obi_taxo_get_species(taxon_p, self.pointer())
        if species_p == NULL :
            return None
        else :
            return <int>(species_p.taxid)


    cpdef object get_genus(self, int taxid):
        cdef ecotx_t* taxon_p
        cdef ecotx_t* genus_p
        taxon_p = obi_taxo_get_taxon_with_taxid(self.pointer(), taxid)
        if taxon_p == NULL:
            raise Exception("Error getting a taxon with given taxid", taxid)
        genus_p = obi_taxo_get_genus(taxon_p, self.pointer())
        if genus_p == NULL :
            return None
        else :
            return <int>(genus_p.taxid)


    cpdef object get_family(self, int taxid):
        cdef ecotx_t* taxon_p
        cdef ecotx_t* family_p
        taxon_p = obi_taxo_get_taxon_with_taxid(self.pointer(), taxid)
        if taxon_p == NULL:
            raise Exception("Error getting a taxon with given taxid", taxid)
        family_p = obi_taxo_get_family(taxon_p, self.pointer())
        if family_p == NULL :
            return None
        else :
            return <int>(family_p.taxid)


    cpdef bytes get_scientific_name(self, int taxid):
        cdef ecotx_t* taxon_p
        taxon_p = obi_taxo_get_taxon_with_taxid(self.pointer(), taxid)
        if taxon_p == NULL:
            raise Exception("Error getting a taxon with given taxid", taxid)
        return taxon_p.name
    
    
    cpdef bytes get_rank(self, int taxid):
        cdef ecotx_t* taxon_p
        taxon_p = obi_taxo_get_taxon_with_taxid(self.pointer(), taxid)
        if taxon_p == NULL:
            raise Exception("Error getting a taxon with given taxid", taxid)
        return self._ranks[taxon_p.rank]


    cpdef object get_taxon_at_rank(self, int taxid, object rank):
        if isinstance(rank, str) or isinstance(rank, bytes):
            rank = self._ranks.index(tobytes(rank))
        try:
            return [x.taxid for x in self.parental_tree_iterator(taxid) if x.rank_idx==rank][0]
        except IndexError:
            return None

    
    def __len__(self):
        return self.pointer().taxa.count


    def __iter__(self):
         
        cdef ecotx_t* taxa
        cdef ecotx_t* taxon_p
        cdef object   taxon_capsule
        cdef int      t
 
        taxa = self.pointer().taxa.taxon
 
        # Yield each taxid
        for t in range(self.pointer().taxa.count):
            taxon_p = <ecotx_t*> (taxa+t)
            taxon_capsule = PyCapsule_New(taxon_p, NULL, NULL)
            yield Taxon(taxon_capsule, self)


    cpdef write(self, object prefix) :
        if obi_write_taxonomy(self._dms.pointer(), self.pointer(), tobytes(prefix)) < 0 :
            raise Exception("Error writing the taxonomy to binary files")
    
    
    cpdef int add_taxon(self, str name, str rank_name, int parent_taxid, int min_taxid=10000000) :
        cdef int taxid
        taxid = obi_taxo_add_local_taxon(self.pointer(), tobytes(name), tobytes(rank_name), parent_taxid, min_taxid)
        if taxid < 0 :
            raise Exception("Error adding a new taxon to the taxonomy")
        else :
            return taxid


    def close(self) :        
        if self.active() :
            self._dms.unregister(self)
            OBIWrapper.close(self)      
            if (obi_close_taxonomy(self.pointer()) < 0) :
                raise Exception("Problem closing the taxonomy %s" % 
                                self._name)


    # name property getter
    @property
    def name(self):
        return self._name
    
    
    def parental_tree_iterator(self, int taxid):
        """
           return parental tree for given taxonomic id starting from
           first ancestor to the root.
        """
        cdef Taxon taxon
        try:
            taxon = self.get_taxon_by_taxid(taxid)
        except:
            raise StopIteration
        if taxon is not None:
            while taxon.taxid != 1:
                yield taxon
                taxon = taxon.parent
            yield taxon
        else:
            raise StopIteration


    def is_ancestor(self, int ancestor_taxid, int taxid):
        return ancestor_taxid in [x.taxid for x in self.parental_tree_iterator(taxid)]


    def last_common_taxon(self, *taxids):
        
        cdef list  t1
        cdef list  t2
        cdef Taxon x
        cdef int   count
        cdef int   i
        cdef int   ancestor
        
        if not taxids:
            return None
        if len(taxids)==1:
            return taxids[0]
                
        if len(taxids)==2:
            t1 = [x.taxid for x in self.parental_tree_iterator(taxids[0])]
            t2 = [x.taxid for x in self.parental_tree_iterator(taxids[1])]
            t1.reverse()
            t2.reverse()
            
            count = min(len(t1),len(t2))
            i=0
            while(i < count and t1[i]==t2[i]):
                i+=1
            i-=1
                        
            return t1[i]
        
        ancestor = taxids[0]
        for taxon in taxids[1:]:
            ancestor = self.last_common_taxon(ancestor, taxon)

        return ancestor

    
cdef class Taxon :    # TODO dict subclass?
    
    def __init__(self, object taxon_capsule, Taxonomy tax) :
        self._pointer = <ecotx_t*> PyCapsule_GetPointer(taxon_capsule, NULL)
        if self._pointer == NULL :
            raise Exception("Error reading a taxon (NULL pointer)")
        self._tax = tax
    
    
    # To test equality
    def __richcmp__(self, Taxon taxon2, int op):
        return (self.name == taxon2.name) and \
               (self.taxid == taxon2.taxid) and \
               (self.rank_idx == taxon2.rank_idx) and \
               (self.farest == taxon2.farest) and \
               (self.parent.taxid == taxon2.parent.taxid) and \
               (self.preferred_name == taxon2.preferred_name)


    # name property getter
    @property
    def name(self):
        return self._pointer.name

    # taxid property getter
    @property
    def taxid(self):
        return self._pointer.taxid

    # rank property getter
    @property
    def rank(self):
        return ((self._tax)._ranks)[(self._pointer).rank]

    # rank_idx property getter
    @property
    def rank_idx(self):
        return (self._pointer).rank

    # farest property getter
    @property
    def farest(self):
        return self._pointer.farest

    # parent property getter
    @property
    def parent(self):
        cdef object parent_capsule
        parent_capsule = PyCapsule_New(self._pointer.parent, NULL, NULL)
        return Taxon(parent_capsule, self._tax)

    # preferred name property getter and setter
    @property
    def preferred_name(self):
        if self._pointer.preferred_name != NULL :
            return bytes2str(self._pointer.preferred_name)

    @preferred_name.setter
    def preferred_name(self, str new_preferred_name) :  # @DuplicatedSignature
        if (obi_taxo_add_preferred_name_with_taxon(self._tax.pointer(), self._pointer, tobytes(new_preferred_name)) < 0) :
            raise Exception("Error adding a new preferred name to a taxon")

    def __repr__(self):
        d = {}
        d['taxid']          = self.taxid
        d['name']           = self.name
        d['rank']           = self.rank
        d['rank_idx']       = self.rank_idx
        d['preferred name'] = self.preferred_name
        d['parent']         = self.parent.taxid
        d['farest']         = self.farest
        return str(d)
    
    