#cython: language_level=3

cimport cython
from obitools3.dms.capi.obiview cimport NUC_SEQUENCE_COLUMN
from obitools3.utils cimport bytes2str, str2bytes, tobytes


# TODO quality offset option?
cdef class FastqFormat:
	
	def __init__(self, list tags=[], bint printNAKeys=False, bytes NAString=b"NA"):
		self.headerFormatter = HeaderFormat("fastq",
										    tags=tags,
										    printNAKeys=printNAKeys,
										    NAString=NAString)
		
	@cython.boundscheck(False)	
	def __call__(self, object data):
		
		cdef bytes quality	
		
		quality = None
		if hasattr(data, "quality_bytes"):
			quality = data.quality_bytes
		elif hasattr(data, "quality"):
			quality = tobytes(data.quality)
		if quality is None:
			raise AttributeError("No quality when exporting to fastq")  # TODO discuss
		
		return self.headerFormatter(data) + b"\n" + data[NUC_SEQUENCE_COLUMN] + b"\n+\n" + quality
