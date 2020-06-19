#cython: language_level=3

from ..utils cimport str2bytes

from .header cimport parseHeader
from ..files.universalopener cimport uopen
from ..files.linebuffer cimport LineBuffer


    