#cython: language_level=3

'''
Created on 6 Nov. 2009

@author: coissac
'''


cdef class NWS(DynamicProgramming):
            
    def __init__(self,match=4,mismatch=-6,opengap=-8,extgap=-2):
        DynamicProgramming.__init__(self,opengap,extgap)
        self._match=match
        self._mismatch=mismatch
        
    cdef double matchScore(self,int h, int v):
        cdef double score
        score = iupacPartialMatch(self.hSeq.sequence[h-1],self.vSeq.sequence[v-1])
        return score * self._match + (1-score) * self._mismatch
        
    cdef double doAlignment(self) except? 0:
        cdef int i  # vertical index
        cdef int j  # horizontal index
        cdef int idx
        cdef int jump
        cdef int delta
        cdef double score 
        cdef double scoremax
        cdef int    path

        
        if self.needToCompute:
            self.allocate()
            self.reset()
            
            for j in range(1,self._hlen()+1):
                idx = self.index(j,0)
                self.matrix.matrix[idx].score = self._opengap + (self._extgap * (j-1))
                self.matrix.matrix[idx].path  = j
                                
            for i in range(1,self._vlen()+1):
                idx = self.index(0,i)
                self.matrix.matrix[idx].score = self._opengap + (self._extgap * (i-1))
                self.matrix.matrix[idx].path  = -i
                
            for i in range(1,self._vlen()+1):
                for j in range(1,self._hlen()+1):
                    
                    # 1 - came from diagonal
                    idx = self.index(j-1,i-1)
                    # print "computing cell : %d,%d --> %d/%d" % (j,i,self.index(j,i),self.matrix.msize),
                    scoremax = self.matrix.matrix[idx].score + \
                               self.matchScore(j,i)
                    path = 0

                    # print "so=%f sd=%f sm=%f" % (self.matrix.matrix[idx].score,self.matchScore(j,i),scoremax),

                    # 2 - open horizontal gap
                    idx = self.index(j-1,i)
                    score = self.matrix.matrix[idx].score + \
                            self._opengap
                    if score > scoremax : 
                        scoremax = score
                        path = +1
                    
                    # 3 - open vertical gap
                    idx = self.index(j,i-1)
                    score = self.matrix.matrix[idx].score + \
                            self._opengap
                    if score > scoremax : 
                        scoremax = score
                        path = -1
                        
                    # 4 - extend horizontal gap
                    jump = self.matrix.bestHJump[i]
                    if jump >= 0:
                        idx = self.index(jump,i)
                        delta = j-jump
                        score = self.matrix.matrix[idx].score + \
                                self._extgap * delta
                        if score > scoremax :
                            scoremax = score
                            path = delta+1 
                            
                    # 5 - extend vertical gap
                    jump = self.matrix.bestVJump[j]
                    if jump >= 0:
                        idx = self.index(j,jump)
                        delta = i-jump
                        score = self.matrix.matrix[idx].score + \
                                self._extgap * delta
                        if score > scoremax :
                            scoremax = score
                            path = -delta-1 
    
                    idx = self.index(j,i)
                    self.matrix.matrix[idx].score = scoremax
                    self.matrix.matrix[idx].path  = path 
                    
                    if path == -1:
                        self.matrix.bestVJump[j]=i
                    elif path == +1 :
                        self.matrix.bestHJump[i]=j
                    
        self.sequenceChanged=False
        self.scoreChanged=False

        idx = self.index(self._hlen(),self._vlen())
        return self.matrix.matrix[idx].score
                   
    cdef void backtrack(self):
        #cdef list path=[]
        cdef int i
        cdef int j 
        cdef int p
        
        self.doAlignment()
        i=self._vlen()
        j=self._hlen()
        self.path=allocatePath(i,j,self.path)
        
        while (i or j):
            p=self.matrix.matrix[self.index(j,i)].path
            self.path.path[self.path.length]=p
            self.path.length+=1
            #path.append(p)
            if p==0:
                i-=1
                j-=1
            elif p < 0:
                i+=p
            else:
                j-=p
                
        #path.reverse()
        #reversePath(self.path)
        self.path.hStart=0
        self.path.vStart=0
        
        #return 0,0,path
                           
    property match:
        def __get__(self):
            return self._match
        
        def __set__(self,match):
            self._match=match 
            self.scoreChanged=True
            
    property mismatch:
        def __get__(self):
            return self._mismatch
        
        def __set__(self,mismatch):
            self._mismatch=mismatch 
            self.scoreChanged=True
 
        
           

