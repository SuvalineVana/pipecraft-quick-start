#cython: language_level=3

cimport cython
from obitools3.dms.capi.obiview cimport NUC_SEQUENCE_COLUMN
from obitools3.utils cimport bytes2str


cdef class FastaFormat:
	
	def __init__(self, list tags=[], bint printNAKeys=False, bytes NAString=b"NA"):
		self.headerFormatter = HeaderFormat("fasta",
										    tags=tags,
										    printNAKeys=printNAKeys,
										    NAString=NAString)
		
	@cython.boundscheck(False)	
	def __call__(self, object data):
		cdef bytes brawseq      = data[NUC_SEQUENCE_COLUMN]
		cdef size_t lseq        = len(brawseq)
		cdef size_t k           = 0
		cdef list   lines       = []
		
		for k in range(0,lseq,60):
			lines.append(brawseq[k:(k+60)])
			
		brawseq = b'\n'.join(lines)
		
		return self.headerFormatter(data) + b"\n" + brawseq
					
