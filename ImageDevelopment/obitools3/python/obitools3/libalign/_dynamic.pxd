#cython: language_level=3

cdef import from "stdlib.h":
    void* malloc(int size)  except NULL
    void* realloc(void* chunk,int size)  except NULL
    void free(void* chunk)
    
cdef import from "string.h":
    void bzero(void *s, size_t n)
    void memset(void* chunk,int car,int length)
    void memcpy(void* s1, void* s2, int n)
    
cdef struct AlignCell :
    double score
    int   path 
    
cdef struct AlignMatrix :
    AlignCell*  matrix
    int*        bestVJump
    int*        bestHJump
    int         msize
    int         vsize
    int         hsize
   


cdef AlignMatrix* allocateMatrix(int hsize, int vsize,AlignMatrix *matrix=?)

cdef void freeMatrix(AlignMatrix* matrix)

cdef void resetMatrix(AlignMatrix* matrix)


cdef struct alignSequence:
    long    length
    long    buffsize
    bint    hasQuality
    char*   sequence
    double* quality

cdef alignSequence* allocateSequence(object bioseq, alignSequence* seq=?) except *

cdef void freeSequence(alignSequence* seq)

cdef struct alignPath:
    long length
    long buffsize
    long vStart
    long hStart
    long *path
    
cdef alignPath* allocatePath(long l1,long l2,alignPath* path=?)

cdef void reversePath(alignPath* path)


cdef void freePath(alignPath* path)


cdef int bitCount(int x)
cpdef bint iupacMatch(unsigned char a, unsigned char b)
cpdef double iupacPartialMatch(unsigned char a, unsigned char b)
cpdef unsigned char encodeBase(unsigned char lettre)

cdef class DynamicProgramming:
    cdef AlignMatrix* matrix

    cdef object horizontalSeq 
    cdef object verticalSeq
    
    cdef alignSequence* hSeq
    cdef alignSequence* vSeq
    cdef alignPath*     path

    cdef double _opengap
    cdef double _extgap
    
    cdef object alignment
    
    cdef bint sequenceChanged
    cdef bint scoreChanged
    
    cdef int _vlen(self)
    cdef int _hlen(self)
    cdef int allocate(self) except -1
    cdef double doAlignment(self) except? 0
    cdef void reset(self)
    cdef inline int index(self, int x, int y)
    cdef inline bint _needToCompute(self)
    cdef void backtrack(self)
    cdef void clean(self)

