#cython: language_level=3

'''
Created on 6 Nov. 2009

@author: coissac
'''

from ._dynamic cimport * 
from ._assemble cimport DirectAssemble
import array


cdef class QSolexaDirectAssemble(DirectAssemble):
            
    cdef double*       hError
    cdef double*       vError
    cdef object        a

    
    def __init__(self,match=4,mismatch=-4,opengap=-8,extgap=-2):
        """
         Rapport entre score de match et mismatch:
             si mismatch = - match / 3
             alors quand scrore temps vers 0 et qu'il est impossible de decider
             pas de penalisation (s'=0) 
             si mismatch < - match / 3 la non decidabilite est penalisee.
        """           
        DirectAssemble.__init__(self,match,mismatch,opengap,extgap)

        
    cdef double matchScore(self,int h, int v):
        cdef double score
        cdef double smatch
        cdef double smismatch
        cdef double hok=1-self.hError[h-1]
        cdef double vok=1-self.vError[v-1]
        score=iupacPartialMatch(self.hSeq.sequence[h-1],self.vSeq.sequence[v-1])
        smatch=((4*hok*vok-hok-vok)*(self._match-self._mismatch)+self._match+2*self._mismatch)/3
        smismatch=((hok+vok-4*hok*vok)*(self._match-self._mismatch)+2*self._match+7*self._mismatch)/9
        return smatch * score + smismatch * (1. - score)
        
    property seqA:
            def __get__(self):
                return self.horizontalSeq
            
            def __set__(self, seq):
                cdef object oaddresse,olength
                assert hasattr(seq, "quality_array"),"You must use sequence with quality indices"
                self.sequenceChanged=True
                self.horizontalSeq=seq
                self.hSeq=allocateSequence(self.horizontalSeq,self.hSeq)
                (oaddress,olength)=seq.quality_array.buffer_info()
                self.hError=<double*><unsigned long int>oaddress
                
    property seqB:
            def __get__(self):
                return self.verticalSeq
            
            def __set__(self, seq):
                cdef object oaddresse,olength
                assert hasattr(seq, "quality_array"),"You must use sequence with quality indices"
                self.sequenceChanged=True
                self.verticalSeq=seq
                self.vSeq=allocateSequence(self.verticalSeq,self.vSeq)
                (oaddress,olength)=seq.quality_array.buffer_info()
                self.vError=<double*><unsigned long int>oaddress 


cdef class QSolexaReverseAssemble(QSolexaDirectAssemble):    

    cdef double matchScore(self,int h, int v):
        cdef double score
        cdef double smatch
        cdef double smismatch
        cdef double hok=1-self.hError[h-1]
        cdef double vok=1-self.vError[self.vSeq.length - v]
        score=iupacPartialMatch(self.hSeq.sequence[h-1],self.vSeq.sequence[v-1])
        smatch=((4*hok*vok-hok-vok)*(self._match-self._mismatch)+self._match+2*self._mismatch)/3
        smismatch=((hok+vok-4*hok*vok)*(self._match-self._mismatch)+2*self._match+7*self._mismatch)/9
        return smatch * score + smismatch * (1. - score)


    property seqB:
    
            def __get__(self):
                return self.verticalSeq.wrapped
            
            def __set__(self, seq):
                cdef object oaddresse,olength
                assert hasattr(seq, "quality_array"),"You must use sequence with quality indices"
                self.sequenceChanged=True
                self.verticalSeq=seq.reverse_complement
                self.vSeq=allocateSequence(self.verticalSeq,self.vSeq)
                self.a = array.array('d', list(seq.quality_array))
                (oaddress,olength) = self.a.buffer_info()
                self.vError = <double*><unsigned long int>oaddress
                
