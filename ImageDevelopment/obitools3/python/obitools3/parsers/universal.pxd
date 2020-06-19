#cython: language_level=3

from ..utils cimport str2bytes

from ..files.universalopener cimport uopen
from ..files.linebuffer cimport LineBuffer
from obitools3.dms.obiseq cimport Nuc_Seq