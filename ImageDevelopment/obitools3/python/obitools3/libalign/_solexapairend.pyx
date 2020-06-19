#cython: language_level=3

from cpython cimport array

from .solexapairend import iterOnAligment
from .shifted_ali cimport Ali_shifted

from obitools3.dms.capi.obiview cimport Obiview_p, QUALITY_COLUMN, NUC_SEQUENCE_COLUMN, \
                                        REVERSE_SEQUENCE_COLUMN, REVERSE_QUALITY_COLUMN, \
                                        obi_set_qual_int_with_elt_idx_and_col_p_in_view, \
                                        obi_set_str_with_elt_idx_and_col_p_in_view
                                        
from obitools3.dms.capi.obidmscolumn cimport OBIDMS_column_p

from obitools3.dms.view.view cimport View
from obitools3.dms.column.column cimport Column

from math import log10


cdef class IterOnConsensus:

    cdef object _ali
    cdef int __seqASingle
    cdef int __seqBSingle
    cdef int __seqABMatch
    cdef int __seqAMismatch
    cdef int __seqBMismatch
    cdef int __seqAInsertion
    cdef int __seqBInsertion
    cdef int __seqADeletion
    cdef int __seqBDeletion
    cdef object __ioa
    cdef bint __firstSeqB

    def __cinit__(self,ali):
        self._ali=ali
        self.__seqASingle=0
        self.__seqBSingle=0
        self.__seqABMatch=0
        self.__seqAMismatch=0
        self.__seqBMismatch=0
        self.__seqAInsertion=0
        self.__seqBInsertion=0
        self.__seqADeletion=0
        self.__seqBDeletion=0

        self.__ioa = iterOnAligment(self._ali)
        self.__firstSeqB=False

    def get_seqASingle(self):
        return self.__seqASingle


    def get_seqBSingle(self):
        return self.__seqBSingle


    def get_seqABMatch(self):
        return self.__seqABMatch


    def get_seqAMismatch(self):
        return self.__seqAMismatch


    def get_seqBMismatch(self):
        return self.__seqBMismatch


    def get_seqAInsertion(self):
        return self.__seqAInsertion


    def get_seqBInsertion(self):
        return self.__seqBInsertion


    def get_seqADeletion(self):
        return self.__seqADeletion


    def get_seqBDeletion(self):
        return self.__seqBDeletion

    def __next__(self):
        cdef bytes snuc0
        cdef bytes snuc1
        cdef char* nuc0
        cdef char* nuc1
        cdef char* dash=b"-"
        cdef double score0
        cdef double score1
        cdef double h0
        cdef double h1

        while(1):
            
            snuc0,score0,snuc1,score1 = self.__ioa.__next__()
            nuc0=snuc0
            nuc1=snuc1
            if nuc0[0]==nuc1[0]:
                if nuc1[0]!=dash[0]:
                    self.__firstSeqB=True
                    self.__seqABMatch+=1
                    self.__seqBSingle=0
                    return (nuc0,score0*score1)
            else:
                h0 = score0 * (1-score1/3)
                h1 = score1 * (1-score0/3)
                if h0 < h1:

                    if nuc0[0]!=dash[0]:
                        self.__seqBSingle=0
                        if nuc1[0]==dash[0]:
                            if self.__firstSeqB:
                                self.__seqAInsertion+=1
                            else:
                                self.__seqASingle+=1
                        else:
                            self.__firstSeqB=True
                            self.__seqAMismatch+=1
                        if score1==1.0:    # Free end gap
                            return (nuc0,score0)
                        else:
                            return (nuc0,h0)
                    else:
                        self.__seqADeletion+=1
                else:
                    if nuc1[0]!=dash[0]:
                        self.__firstSeqB=True
                        if nuc0[0]==dash[0]:
                            self.__seqBInsertion+=1
                            self.__seqBSingle+=1
                        else:
                            self.__seqBMismatch+=1
                            self.__seqBSingle=0
                        if score0==1.0:    # Free end gap
                            return (nuc1,score1)
                        else:
                            return (nuc1,h1)
                    else:
                        self.__seqBSingle=0
                        self.__seqBDeletion+=1


    def __iter__(self):
        return self

    seqASingle = property(get_seqASingle, None, None, "direct's docstring")
    seqBSingle = property(get_seqBSingle, None, None, "reverse's docstring")
    seqABMatch = property(get_seqABMatch, None, None, "idem's docstring")
    seqAMismatch = property(get_seqAMismatch, None, None, "mismatchdirect's docstring")
    seqBMismatch = property(get_seqBMismatch, None, None, "mismatchreverse's docstring")
    seqAInsertion = property(get_seqAInsertion, None, None, "insertdirect's docstring")
    seqBInsertion = property(get_seqBInsertion, None, None, "insertreverse's docstring")
    seqADeletion = property(get_seqADeletion, None, None, "deletedirect's docstring")
    seqBDeletion = property(get_seqBDeletion, None, None, "deletereverse's docstring")


def buildConsensus(ali, seq, ref_tags=None):
    cdef list quality
    cdef char   aseq[1000]
    cdef int i=0
    cdef int j=0
    cdef char* cnuc
    cdef bytes nuc
    cdef double score
    cdef bytes sseq
    cdef double p
    cdef OBIDMS_column_p col_p
    cdef Obiview_p view_p
    cdef View view
    cdef Column column
    
    quality = []
        
    if type(ali) == Ali_shifted:
        view = seq.view
        view_p = view.pointer()
        column = view[QUALITY_COLUMN]
        col_p = column.pointer()
        # doesn't work because uint8_t* are forced into bytes by cython (nothing read/kept beyond 0 values)
        #obi_set_qual_int_with_elt_idx_and_col_p_in_view(view_p, col_p, seq.index, 0, ali.consensus_qual, ali.consensus_len)
        seq.set(ref_tags.id+b"_CONS", ali.consensus_seq, quality=ali.consensus_qual)
        seq[b'ali_length'] = ali.consensus_len
        seq[b'score_norm']=float(ali.score)/ali.consensus_len
        seq[b'shift']=ali.shift
    else:
        if len(ali[0])>999:   # TODO why?
            raise AssertionError,"Too long alignemnt"
    
        ic=IterOnConsensus(ali)
    
        for nuc,score in ic:
            cnuc=nuc
            quality.append(score)
            aseq[i]=cnuc[0]
            i+=1
    
        aseq[i]=0
    
        sseq=aseq
    
        # Reconvert quality from array of probabilities to array of raw quality values
        i=0
        for p in quality:
            quality[i] = min(42, round(-10*log10(p)))
            i+=1
        
        seq.set(ali[0].wrapped.id+b"_CONS", sseq, quality=quality)
        
        if hasattr(ali, "counter"):
            seq[b'alignement_id']=ali.counter
        seq[b'seq_a_single']=ic.seqASingle
        seq[b'seq_b_single']=ic.seqBSingle
        seq[b'seq_ab_match']=ic.seqABMatch
        seq[b'seq_a_mismatch']=ic.seqAMismatch
        seq[b'seq_b_mismatch']=ic.seqBMismatch
        seq[b'seq_a_insertion']=ic.seqAInsertion
        seq[b'seq_b_insertion']=ic.seqBInsertion-ic.seqBSingle
        seq[b'seq_a_deletion']=ic.seqADeletion
        seq[b'seq_b_deletion']=ic.seqBDeletion
        seq[b'ali_length']=len(seq)-ic.seqASingle-ic.seqBSingle
        if seq[b'ali_length']>0:
            seq[b'score_norm']=float(ali.score)/seq[b'ali_length']
        
        ref_tags = ali[0].wrapped

    if hasattr(ali, "direction"):
        seq[b'ali_direction']=ali.direction
    seq[b'score']=ali.score
    seq[b'mode']=b'alignment'

    for tag in ref_tags:
        if tag != REVERSE_SEQUENCE_COLUMN and tag != REVERSE_QUALITY_COLUMN and \
            tag != NUC_SEQUENCE_COLUMN and tag != QUALITY_COLUMN:
            seq[tag] = ref_tags[tag]

    return seq


def buildJoinedSequence(ali, reverse, seq, forward=None):
    if forward is not None:
        forward = forward
    else:
        forward = ali[0].wrapped
    s = forward.seq + reverse.seq     
    quality = forward.quality
    quality.extend(reverse.quality)
    seq.set(forward.id +b"_PairedEnd", s, definition=forward.definition, quality=quality)
    seq[b"score"]=ali.score
    seq[b"ali_direction"]=ali.direction
    seq[b"mode"]=b"joined"
    seq[b"pairedend_limit"]=len(forward)    
    for tag in forward:
        if tag != REVERSE_SEQUENCE_COLUMN and tag != REVERSE_QUALITY_COLUMN:
            seq[tag] = forward[tag]
    return seq

