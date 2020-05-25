from obitools3.dms.obiseq import Nuc_Seq_Stored, Nuc_Seq
from functools import reduce
import struct 
from copy import deepcopy


class GappedPositionException(Exception):
    pass

class AlignedSequence(Nuc_Seq):   # TODO discuss. can be both Nuc_Seq or Nuc_Seq_Stored....

    def __init__(self, seq) :
        self.wrapped = seq
        self._length=len(seq)
        self._gaps=[[self._length,0]]
        
    def clone(self):
        seq = AlignedSequence(self.wrapped)
        seq._gaps=deepcopy(self._gaps)
        seq._length=reduce(lambda x,y:x+y, (z[0]+z[1] for z in self._gaps),0)
        return seq

    def setGaps(self, value):
        '''
        Set gap vector to an AlignedSequence.
        
        Gap vector describes the gap positions on a sequence.
        It is a gap of couple. The first couple member is the count
        of sequence letter, the second one is the gap length. 
        @param value: a list of length 2 list describing gap positions
        @type value: list of couple
        '''
        assert isinstance(value, list),'Gap vector must be a list'
        assert reduce(lambda x,y: x and y,
                      (isinstance(z, list) and len(z)==2 for z in value),
                      True),"Value must be a list of length 2 list"
                       
        lseq = reduce(lambda x,y:x+y, (z[0] for z in value),0)
        assert lseq==len(self.wrapped),"Gap vector incompatible with the sequence"
        self._gaps = value
        self._length=reduce(lambda x,y:x+y, (z[0]+z[1] for z in value),0)

    def getGaps(self):
        return tuple(self._gaps)
    gaps = property(getGaps, setGaps, None, "Gaps's Docstring")

    def _getIndice(self,pos):
        i=0
        cpos=0
        for s,g in self._gaps:
            cpos+=s
            if cpos>pos:
                return i,pos-cpos+s
            cpos+=g 
            if cpos>pos:
                return i,-pos+cpos-g-1
            i+=1
        raise IndexError

    def getId(self):
        d = self.id or ("%s_ALN" % self.wrapped.id)
        return d

    def __len__(self):
        return self._length
    
    def get_str(self):
        return ''.join([x.decode('ascii') for x in self])
    
    def __iter__(self):
        def isymb():
            cpos=0
            for s,g in self._gaps:
                for x in range(s):
                    yield (self.wrapped[cpos+x])
                for x in range(g):
                    yield b"-"
                cpos+=s
        return isymb()
    
    def _posInWrapped(self,position):
        i,s=self._getIndice(position)
        if s<0:
            raise GappedPositionException
        value=self._gaps
        p=reduce(lambda x,y:x+y, (z[0] for z in value[:i]),0)+s
        return p

    def get_symbol_at(self,position):
        try:
            return self.wrapped.get_symbol_at(self._posInWrapped(position))
        except GappedPositionException:
            return b"-"
        
    def insertGap(self,position,count=1):
        if position==self._length:
            idx=len(self._gaps)-1
            p=-1
        else:
            idx,p = self._getIndice(position)

        if p >= 0:
            self._gaps.insert(idx, [p,count])
            self._gaps[idx+1][0]-=p
        else:
            self._gaps[idx][1]+=count
        self._length=reduce(lambda x,y:x+y, (z[0]+z[1] for z in self._gaps),0)
    

class Alignment(list):

    def _assertData(self,data):
#        assert isinstance(data, Nuc_Seq_Stored),'You must only add bioseq to an alignement' TODO
        if hasattr(self, '_alignlen'):
            assert self._alignlen==len(data),'All aligned sequences must have the same length'
        else:
            self._alignlen=len(data)
        return data  
            
    def clone(self):
        ali = Alignment(x.clone() for x in self)
        return ali
    
    def append(self,data):
        data = self._assertData(data)
        list.append(self,data)
        
    def __setitem__(self,index,data):
        
        data = self._assertData(data)
        list.__setitem__(self,index,data)
        
    def getSite(self,key):
        if isinstance(key,int):
            return [x[key] for x in self]
        
    def insertGap(self,position,count=1):
        for s in self:
            s.insertGap(position,count)
        
    def isFullGapSite(self,key):
        return reduce(lambda x,y: x and y,(z==b"-" for z in self.getSite(key)),True)
    
    def isGappedSite(self,key):
        return b"-" in self.getSite(key)

    def __str__(self):
        l = len(self[0])
        rep=""
        idmax = max(len(x.id) for x in self)+2
        template= "%%-%ds  %%-60s" % idmax
        for p in range(0,l,60):
            for s in self:
                rep+= (template % (s.id,s[p:p+60])).strip() + '\n'
            rep+="\n"
        return rep


def columnIterator(alignment):
    lali = len(alignment[0])
    for p in range(lali):
        c = []
        for x in alignment:
            c.append(x[p])
        yield c

