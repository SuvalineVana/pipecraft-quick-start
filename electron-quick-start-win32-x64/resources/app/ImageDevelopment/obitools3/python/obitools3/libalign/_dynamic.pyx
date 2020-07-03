#cython: language_level=3

'''
Created on 14 sept. 2009

@author: coissac
'''

from obitools3.libalign import AlignedSequence
from obitools3.libalign import Alignment
from copy import deepcopy


######
#
# Import standard memory management function to improve
# efficiency of the alignment code
#
#

    
cdef AlignMatrix* allocateMatrix(int hsize, int vsize,AlignMatrix *matrix=NULL):
    
    vsize+=1
    hsize+=1
    
    if matrix is NULL:
        matrix = <AlignMatrix*>malloc(sizeof(AlignMatrix))
        matrix.vsize=0
        matrix.hsize=0
        matrix.msize=0
        matrix.matrix=NULL
        matrix.bestVJump=NULL
        matrix.bestHJump=NULL
        
    if hsize > matrix.hsize:
        matrix.bestVJump = <int*>realloc(matrix.bestVJump,hsize * sizeof(int))
        matrix.hsize=hsize
        
    if vsize > matrix.vsize:
        matrix.bestHJump = <int*>realloc(matrix.bestHJump,vsize * sizeof(int))
        matrix.vsize=vsize
        
    if (hsize * vsize) > matrix.msize:
        matrix.msize = hsize * vsize
        matrix.matrix = <AlignCell*>realloc(matrix.matrix, matrix.msize * sizeof(AlignCell))
        
    return matrix

cdef void freeMatrix(AlignMatrix* matrix):
    if matrix is not NULL:
        if matrix.matrix is not NULL:
            free(matrix.matrix)
        if matrix.bestVJump is not NULL:
            free(matrix.bestVJump)
        if matrix.bestHJump is not NULL:
            free(matrix.bestHJump)
        free(matrix)
        
cdef void resetMatrix(AlignMatrix* matrix):
    if matrix is not NULL:
        if matrix.matrix is not NULL:
            bzero(<void*>matrix.matrix, matrix.msize * sizeof(AlignCell))
        if matrix.bestHJump is not NULL:
            memset(<void*>matrix.bestHJump,255,matrix.vsize * sizeof(int))
        if matrix.bestVJump is not NULL:
            memset(<void*>matrix.bestVJump,255,matrix.hsize * sizeof(int))
     
    
cdef alignSequence* allocateSequence(object bioseq, alignSequence* seq=NULL) except *:
    cdef bytes strseq
    cdef int i
    
    if seq is NULL:
        seq = <alignSequence*>malloc(sizeof(alignSequence))
        seq.length=0
        seq.buffsize=0
        seq.sequence=NULL
        seq.quality=NULL
        seq.hasQuality=False
    
    seq.length=len(bioseq)
    if seq.length > seq.buffsize:
        #seq.sequence = <char*>realloc(seq.sequence,sizeof(char)*seq.length)
        #seq.quality  = <double*>realloc(seq.quality,sizeof(double)*seq.length)
        seq.buffsize = seq.length
    
    # TODO optimisable...
    #strseq = bioseq.seq.lower()
    #memcpy(seq.sequence,<char*>strseq,seq.length)
    seq.sequence = bioseq.seq

    return seq

cdef void freeSequence(alignSequence* seq):
    if seq is not NULL:
        #if seq.sequence is not NULL:
        #    free(<void*>seq.sequence)
        #if seq.quality is not NULL:
        #    free(<void*>seq.quality)
        free(seq)
        
cdef alignPath* allocatePath(long l1,long l2,alignPath* path=NULL):
    cdef long length=l1+l2
    
    if path is NULL:
        path = <alignPath*>malloc(sizeof(alignPath))
        path.length=0
        path.buffsize=0
        path.path=NULL
        
    if length > path.buffsize:
        path.buffsize=length
        path.path=<long*>realloc(path.path,sizeof(long)*length)
        
    path.length=0
    path.vStart=0
    path.hStart=0
    
    return path

cdef void reversePath(alignPath* path):
        cdef long i
        cdef long j
        
        j=path.length
        for i in range(<long>(path.length/2)):  # TODO not sure about the cast
            j-=1
            path.path[i],path.path[j]=path.path[j],path.path[i]

cdef void freePath(alignPath* path):
    if path is not NULL:
        if path.path is not NULL:
            free(<void*>path.path)
        free(<void*>path)
  
    
cdef int aascii = ord(b'a')
cdef int _basecode[26]
   
cdef int bitCount(int x):
    cdef int i=0
    while(x):
        i+=1
        x&=x-1
    return i

cpdef bint iupacMatch(unsigned char a, unsigned char b):
    cdef bint m 

    if a==42:    # * ascii code
        a=110    # n ascii code

    if b==42:    # * ascii code
        b=110    # n ascii code

    m = _basecode[a - aascii] & _basecode[b - aascii]
    return m

cpdef unsigned char encodeBase(unsigned char lettre):
    return _basecode[lettre - aascii]

cpdef double iupacPartialMatch(unsigned char a, unsigned char b):
    cdef int codeA
    cdef int codeB
    cdef int good
    cdef int all
    cdef double partial 
        
    if a==42:    # * ascii code
        a=110    # n ascii code

    if b==42:    # * ascii code
        b=110    # n ascii code

    codeA =  _basecode[a - aascii]
    codeB =  _basecode[b - aascii]
    good  =  bitCount(codeA & codeB)
    all   =  bitCount(codeA)  * bitCount(codeB)
    partial= <double>good / all 

    return partial
    
                
cdef class DynamicProgramming:

    def __init__(self,opengap,extgap):
        self.sequenceChanged=True
        self.scoreChanged=True

        self.matrix=NULL
        self.hSeq=NULL
        self.vSeq=NULL
        self.path=NULL
        
        self.horizontalSeq=None
        self.verticalSeq=None
        
        self._opengap=opengap
        self._extgap=extgap
        
    cdef int _vlen(self):
        return self.vSeq.length
        
    cdef int _hlen(self):
        return self.hSeq.length
        
    cdef int allocate(self) except -1:
        
        assert self.horizontalSeq is not None,'Sequence A must be set'
        assert self.verticalSeq is not None,'Sequence B must be set'
        
        cdef long lenH=self._hlen()
        cdef long lenV=self._vlen()

        self.matrix=allocateMatrix(lenH,lenV,self.matrix)
        return 0


    cdef double doAlignment(self) except? 0:
        pass
    
    cdef bint _needToCompute(self):
        return self.scoreChanged or self.sequenceChanged
    
    cdef void backtrack(self):
        pass
    
    property seqA:
            def __get__(self):
                return self.horizontalSeq
            
            def __set__(self, seq):
                self.sequenceChanged = True
                self.horizontalSeq = seq
                self.hSeq = allocateSequence(self.horizontalSeq, self.hSeq)
                
    property seqB:
            def __get__(self):
                return self.verticalSeq
            
            def __set__(self, seq):
                self.sequenceChanged = True
                self.verticalSeq = seq
                self.vSeq = allocateSequence(self.verticalSeq, self.vSeq)
                
    property opengap:
        def __get__(self):
            return self._opengap
        
        def __set__(self,opengap):
            self._opengap=opengap 
            self.scoreChanged=True
            
    property extgap:
        def __get__(self):
            return self._extgap
        
        def __set__(self,extgap):
            self._extgap=extgap 
            self.scoreChanged=True
            
    property needToCompute:
        def __get__(self):
            return self.scoreChanged or self.sequenceChanged

    property score:
        def __get__(self):
            return self.doAlignment()
                    
    cdef void reset(self):
        self.scoreChanged=True
        resetMatrix(self.matrix)
        
    cdef inline int index(self, int x, int y):
        return (self._hlen()+1) * y + x
    
    cdef void clean(self):
        freeMatrix(self.matrix)
        freeSequence(self.hSeq)
        freeSequence(self.vSeq)
        freePath(self.path)
        
    def __dealloc__(self):
        self.clean()
        
    def __call__(self):
        cdef list hgaps=[]
        cdef list vgaps=[]
        cdef list b
        cdef int  hp=0
        cdef int  vp=0
        cdef int  lenh=0
        cdef int  lenv=0
        cdef int  h,v,p
        cdef int  i
        cdef object ali
        cdef double score
                
        if self._needToCompute():
            score = self.doAlignment()
            self.backtrack()
            for i in range(self.path.length-1,-1,-1):
                p=self.path.path[i]
                if p==0:
                    hp+=1
                    vp+=1
                    lenh+=1
                    lenv+=1
                elif p>0:
                    hp+=p
                    lenh+=p
                    vgaps.append([vp,p])
                    vp=0
                else:
                    vp-=p
                    lenv-=p
                    hgaps.append([hp,-p])
                    hp=0
                
            if hp:
                hgaps.append([hp,0])
            if vp:
                vgaps.append([vp,0])
                
            if lenh < self._hlen():
                hseq=self.horizontalSeq[self.path.hStart:self.path.hStart+lenh]
            else:
                hseq=self.horizontalSeq
            
            hseq=AlignedSequence(hseq) 
            hseq.gaps=hgaps       
            
            if lenv < self._vlen():
                vseq=self.verticalSeq[self.path.vStart:self.path.vStart+lenv]
            else:
                vseq=self.verticalSeq
    
            vseq=AlignedSequence(vseq) 
            vseq.gaps=vgaps       
            
            ali=Alignment()
            ali.append(hseq)
            ali.append(vseq)
            
            ali.score=score
            self.alignment=ali
        ali=self.alignment.clone()
        ali.score=self.alignment.score
        return ali
  
        
            
            
# initialize iupac carray

__basecode=[1,14,2,13,0,0,4,11,0,0,12,0,3,15,0,0,0,5,6,8,8,7,9,0,10,0]            
for i in range(26):
    _basecode[i]=__basecode[i]
               
        