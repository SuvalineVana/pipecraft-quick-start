#cython: language_level=3

'''
Created on 6 Nov. 2009

@author: coissac
'''


cdef class FreeEndGap(NWS):
            
    def __init__(self,match=4,mismatch=-6,opengap=-8,extgap=-2):
        NWS.__init__(self,match,mismatch,opengap,extgap)
        self.xsmax=0
        self.xmax=0
                
    cdef double doAlignment(self) except? 0:
        cdef int i  # vertical index
        cdef int j  # horizontal index
        cdef int idx
        cdef int idx0
        cdef int idx1
        cdef int jump
        cdef int delta
        cdef double score
        cdef double scoremax
        cdef int    path
        
        assert self.hSeq.length > self.vSeq.length, \
                "Sequence B must be shorter than sequence A"

        
        if self.needToCompute:
            self.allocate()
            self.reset()
            self.xsmax=0
            self.xmax=0
            
            for j in range(1,self.hSeq.length+1):
                idx = self.index(j,0)
                self.matrix.matrix[idx].score = 0
                self.matrix.matrix[idx].path  = j
                                
            for i in range(1,self.vSeq.length+1):
                idx = self.index(0,i)
                self.matrix.matrix[idx].score = self._opengap + (self._extgap * (i-1))
                self.matrix.matrix[idx].path  = -i
                
            idx0=self.index(-1,0)
            idx1=self.index(0,1)
            for i in range(1,self.vSeq.length+1):
                idx0+=1
                idx1+=1
                for j in range(1,self.hSeq.length+1):
                    
                    # 1 - came from diagonal
                    #idx = self.index(j-1,i-1)
                    idx = idx0
                    # print "computing cell : %d,%d --> %d/%d" % (j,i,self.index(j,i),self.matrix.msize),
                    scoremax = self.matrix.matrix[idx].score + \
                               self.matchScore(j,i)
                    path = 0

                    # print "so=%f sd=%f sm=%f" % (self.matrix.matrix[idx].score,self.matchScore(j,i),scoremax),

                    # 2 - open horizontal gap
                    # idx = self.index(j-1,i)
                    idx = idx1 - 1
                    score = self.matrix.matrix[idx].score+ \
                            self._opengap
                    if score > scoremax : 
                        scoremax = score
                        path = +1
                    
                    # 3 - open vertical gap
                    # idx = self.index(j,i-1)
                    idx = idx0 + 1
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
    
                    # idx = self.index(j,i)
                    idx = idx1
                    self.matrix.matrix[idx].score = scoremax
                    self.matrix.matrix[idx].path  = path 

                    if path == -1:
                        self.matrix.bestVJump[j]=i
                    elif path == +1 :
                        self.matrix.bestHJump[i]=j

                    if i==self.vSeq.length and scoremax > self.xsmax:
                        self.xsmax=scoremax
                        self.xmax=j
                    idx0+=1
                    idx1+=1
                                        
        self.sequenceChanged=False
        self.scoreChanged=False

        return self.xsmax
                   
    cdef void backtrack(self):
        #cdef list path=[]
        cdef int i
        cdef int j 
        cdef int p
        
        self.doAlignment()
        j=self.xmax
        i=self.vSeq.length
        self.path=allocatePath(i,j+1,self.path)
        
        if self.xmax<self.hSeq.length:
            self.path.path[self.path.length]=self.hSeq.length-self.xmax
            self.path.length+=1
            
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
                           
