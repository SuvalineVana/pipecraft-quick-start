#cython: language_level=3

from libc.stdint cimport uintptr_t

from obitools3.dms.capi.apat cimport SeqPtr, \
                                     PatternPtr, \
                                     ecoseq2apatseq, \
                                     ManberAll, \
                                     delete_apatseq, \
                                     buildPattern, \
                                     complementPattern


cdef class One_primer_search_result:
    
    cdef inline SeqPtr pointer(self) :
        return <SeqPtr>(self._pointer)        

    @staticmethod
    cdef new(SeqPtr apat_seq_p, int pattern_ref, int hit_count) :   # not __init__ method because need to pass pointer        
        result = One_primer_search_result()
        result._pointer = apat_seq_p
        result.pattern_ref = pattern_ref
        result.hit_count = hit_count
        return result
    
    cpdef first_encountered(self):
        cdef int i
        cdef int first
        cdef int first_index
        cdef int hit_pos
        cdef int error_count
        cdef SeqPtr pointer
        
        pointer = self.pointer()
        first = -1
        
        for i in range(self.hit_count):
            hit_pos = pointer.hitpos[self.pattern_ref].val[i]
            if first == -1 or hit_pos < first:
                first = hit_pos
                first_index = i
        error_count = pointer.hiterr[self.pattern_ref].val[first_index]
        return error_count, first


cdef class Primer_search:
   
    def __init__(self, list primers, int error_max) :
        cdef PatternPtr p1
        cdef PatternPtr p2
        cdef PatternPtr p3
        cdef PatternPtr p4   
        
        cdef PatternPtr test
        cdef uintptr_t test_i
        cdef bytes test_b
             
        self.apat_seq_p = NULL
        self.direct_primers = []
        self.revcomp_primers = []
        for i in range(len(primers)):
            p1 = buildPattern(primers[i][0], error_max)
            p2 = buildPattern(primers[i][1], error_max)
            p3 = complementPattern(p1)
            p4 = complementPattern(p2)
            self.direct_primers.append((<uintptr_t>p1, <uintptr_t>p2))
            self.revcomp_primers.append((<uintptr_t>p3, <uintptr_t>p4))
            

    cpdef One_primer_search_result search_one_primer(self, bytes sequence, 
                                                     int primer_pair_index, int primer_index, 
                                                     bint reverse_comp=False, 
                                                     bint same_sequence=False, 
                                                     int pattern_ref=0,
                                                     int begin=0) :
        '''
            begin = start of direct pattern if it was already searched + its length
        '''
        cdef One_primer_search_result result = None
        cdef PatternPtr primer_p
        cdef SeqPtr apat_seq_p
        cdef int hit_count
        
        if not same_sequence:
            self.apat_seq_p = <SeqPtr>(ecoseq2apatseq(sequence, self.apat_seq_p, 0))

        apat_seq_p = <SeqPtr>(self.apat_seq_p)
                
        if reverse_comp:
            primer_p = <PatternPtr>(<uintptr_t>(self.revcomp_primers[primer_pair_index][primer_index]))
        else:
            primer_p = <PatternPtr>(<uintptr_t>(self.direct_primers[primer_pair_index][primer_index]))
        
        begin = begin
        seqlen = (apat_seq_p.seqlen) - begin
                        
        hit_count = ManberAll(apat_seq_p, primer_p, pattern_ref, begin, seqlen)
                
        if hit_count:
            result = One_primer_search_result.new(apat_seq_p, pattern_ref, hit_count)
        else:
            result = None
        return result
    
    
    cpdef free(self):
        delete_apatseq(self.apat_seq_p)






#         min_error_count = -1
#         best_hit = -1
#         for i in range(hit_count):
#             error_count = apat_seq_p.hiterr[pattern_ref].val[i]
#             hit_pos = apat_seq_p.hitpos[pattern_ref].val[i]
#             if min_error_count < 0 or error_count < min_error_count:
#                 self.min_error_count = error_count
#                 self.best_hit = i

#     def __call__(self, bytes sequence):
#         # TODO declare things
#         # Search ALL primers in the direct direction
#         p1 = search_one_primer(self, sequence, True, False, same_sequence=False)
#         p2 = search_one_primer(self, sequence, False, False, same_sequence=True) 
#         
#         # Search each primer in both directions
#         # 1st direction
#         p1 = search_one_primer(self, sequence, True, False, same_sequence=False)
#         p2_revcomp = search_one_primer(self, sequence, False, True, same_sequence=True)
#         # 2nd direction
#         p2 = search_one_primer(self, sequence, False, False, same_sequence=True)
#         p1_revcomp = search_one_primer(self, sequence, True, True, same_sequence=True)
#         # Choose best hit (best score for direction and longest amplicon if multiple hits in one direction)
#         if p1.min_error_count + p2_revcomp.min_error_count < p2.min_error_count + p1_revcomp.min_error_count:
#             direct_hit = True
#             if p1.hit_count > 1:
#                 pos1 = min((pos, idx) for (idx, pos) in enumerate(p1.hit_pos))[0]
#             if p2_revcomp.hit_count > 1:
#                 pos2 = max((pos, idx) for (idx, pos) in enumerate(p2_revcomp.hit_pos))[0]
#         else:
#             direct_hit = False
#             if p2.hit_count > 1:
#                 pos1 = min((pos, idx) for (idx, pos) in enumerate(p2.hit_pos))[0]
#             if p2_revcomp.hit_count > 1:
#                 pos2 = max((pos, idx) for (idx, pos) in enumerate(p2_revcomp.hit_pos))[0]
        
