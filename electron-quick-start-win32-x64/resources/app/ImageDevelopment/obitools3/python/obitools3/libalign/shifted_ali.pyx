#cython: language_level=3

from obitools3.dms.capi.obiview cimport NUC_SEQUENCE_COLUMN, QUALITY_COLUMN

from obitools3.dms.capi.kmer_similarity cimport kmer_similarity, Obi_ali_p, obi_free_shifted_ali
from obitools3.dms.view.typed_view.view_NUC_SEQS cimport View_NUC_SEQS
from obitools3.dms.column.column cimport Column

from libc.stdlib  cimport free


cdef class Ali_shifted:
            
    cdef inline Obi_ali_p pointer(self) :
        return <Obi_ali_p>(self._pointer)        
    
    @staticmethod
    cdef Ali_shifted new_ali(Obi_ali_p ali_p) :   # not __init__ method because need to pass pointer
        ali = Ali_shifted()
        ali._pointer = ali_p
        return ali

    @property
    def score(self):
        return self.pointer().score

    @property
    def consensus_len(self):
        return self.pointer().consensus_length

    @property
    def overlap_len(self):
        return self.pointer().overlap_length
    
    @property
    def consensus_seq(self):
        return self.pointer().consensus_seq

    @property
    def shift(self):
        return self.pointer().shift
    
    @property
    def consensus_qual(self):   # must return list because uint8_t* are forced into bytes by cython which won't keep beyond the first 0 value
        qual_list = []
        for i in range(self.consensus_len):
            qual_list.append((self.pointer().consensus_qual)[i])
        return qual_list

    @property
    def direction(self):
        return self.pointer().direction

    cpdef free(self):  # TODO allocated memory could be kept
        obi_free_shifted_ali(self.pointer())


cdef class Kmer_similarity:
    def __init__(self, View_NUC_SEQS view1, Column column1=None, Column qual_column1=None, \
                 View_NUC_SEQS view2=None, Column column2=None, Column qual_column2=None, \
                 uint8_t kmer_size=3, bint build_consensus=True, Column reversed_column=None) :
        cdef Column default_seq_col
        cdef Column default_qual_col
        if kmer_size < 1 or kmer_size > 3:
            raise Exception("Kmer size to compute kmer similarity must be >=1 or <=4")
        self.kmer_pos_array_p = NULL
        self.shift_array_p = NULL
        self.shift_count_array_p = NULL
        self.kmer_pos_array_height_a[0] = 0
        self.shift_array_height_a[0] = 0 
        self.shift_count_array_height_a[0] = 0
        self.kmer_size = kmer_size
        self.build_consensus = build_consensus
        self.view1_p = view1.pointer()
        if column1 is not None:
            self.column1_p = column1.pointer()
        else:
            if type(view1) != View_NUC_SEQS:
                raise Exception("Kmer similarity with no sequence column given must be given a NUC_SEQS view")
            default_seq_col = view1[NUC_SEQUENCE_COLUMN]
            self.column1_p = default_seq_col.pointer()
        if view2 is not None:
            self.view2_p = view2.pointer()
        else:
            view2 = view1
            self.view2_p = self.view1_p
        if column2 is not None:
            self.column2_p = column2.pointer()
        else:
            if type(view2) != View_NUC_SEQS:
                raise Exception("Kmer similarity with no sequence column given must be given a NUC_SEQS view")
            default_seq_col = view2[NUC_SEQUENCE_COLUMN]
            self.column2_p = default_seq_col.pointer()
        if qual_column1 is not None:
            self.qual_col1_p = qual_column1.pointer()
        else:
            if type(view1) != View_NUC_SEQS:
                raise Exception("Kmer similarity with no quality column given must be given a NUC_SEQS view")
            default_qual_col = view1[QUALITY_COLUMN]
            self.qual_col1_p = default_qual_col.pointer()
        if qual_column2 is not None:
            self.qual_col2_p = qual_column2.pointer()
        else:
            if type(view2) != View_NUC_SEQS:
                raise Exception("Kmer similarity with no quality column given must be given a NUC_SEQS view")
            default_qual_col = view2[QUALITY_COLUMN]
            self.qual_col2_p = default_qual_col.pointer()
        if reversed_column is None:
            self.reversed_col_p = NULL
        else:
            self.reversed_col_p = reversed_column.pointer()

    
    def __call__(self, object seq1, object seq2):
        cdef Obi_ali_p ali_p
        cdef Ali_shifted ali
        ali_p = kmer_similarity(self.view1_p, self.column1_p, seq1.index, 0, \
                               self.view2_p, self.column2_p, seq2.index, 0, \
                               self.qual_col1_p, self.qual_col2_p, \
                               self.reversed_col_p, \
                               self.kmer_size, \
                               &(self.kmer_pos_array_p), self.kmer_pos_array_height_a, \
                               &(self.shift_array_p), self.shift_array_height_a, \
                               &(self.shift_count_array_p), self.shift_count_array_height_a,
                               self.build_consensus)
        
        ali = Ali_shifted.new_ali(ali_p)
        return ali
    
    cpdef free(self):
        if self.kmer_pos_array_p is not NULL:
            free(self.kmer_pos_array_p)
            self.kmer_pos_array_height_a[0] = 0
        if (self.shift_array_p is not NULL) :
            free(self.shift_array_p)
            self.shift_array_height_a[0] = 0
        if (self.shift_count_array_p is not NULL) :
            free(self.shift_count_array_p)
            self.shift_count_array_height_a[0] = 0
        

