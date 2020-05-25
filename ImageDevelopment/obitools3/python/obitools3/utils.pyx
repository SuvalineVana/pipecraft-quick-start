#cython: language_level=3

from obitools3.dms.capi.obitypes cimport is_a_DNA_seq, \
                                         OBI_VOID, \
                                         OBI_BOOL, \
                                         OBI_CHAR, \
                                         OBI_FLOAT, \
                                         OBI_INT, \
                                         OBI_QUAL, \
                                         OBI_SEQ, \
                                         OBI_STR, \
                                         index_t

from obitools3.dms.capi.obierrno cimport OBI_LINE_IDX_ERROR, \
                                         OBI_ELT_IDX_ERROR, \
                                         obi_errno

from obitools3.files.uncompress cimport CompressedFile

import re
import mmap
import os
import glob
import gzip


cpdef bytes format_separator(bytes format):
    if format == b"fasta":
        return b"\n>"
    elif format == b"fastq":
        return b"\n@"
    elif format == b"ngsfilter" or format == b"tabular":
        return b"\n"
    elif format == b"genbank" or format == b"embl":
        return b"\n//"
    elif format == b"ecopcr":
        return b"\n[^#]"
    else:
        return None


cpdef int count_entries(file, bytes format):
    
    try:
        sep = format_separator(format)
        if sep is None:
            return -1
        sep = re.compile(sep)

        if type(file) == bytes and (format == b'genbank' or format == b'embl'): # file is actually a directory with multiple files
            files = []
            if format == b'embl':
                extensions = [b"*.dat"]
            elif format == b"genbank":
                extensions = [b"*.gbff"]
            
            for ext in extensions:
                for filename in glob.glob(os.path.join(file, ext)):
                    #if filename[:-3] == ".gz":
                    #    files.append(gzip.open(filename, "rb"))
                    #else:
                    files.append(open(filename, "rb"))
        else:
            files = [file]
        
        if len(files)==0:
            return -1
        
        total_count = 0
        for f in files:
            if type(f) == CompressedFile and f.compressed:
                return -1
            mmapped_file = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
            total_count += len(re.findall(sep, mmapped_file))
            if format != b"ngsfilter" and format != b"tabular":
                total_count += 1 # adding +1 for 1st entry because separators include \n (ngsfilter and tabular already count one more because of last \n)
            
    except:
        if len(files) > 1:
            for file in files:
                file.close()
        return -1
    
    if len(files) > 1:
        for f in files:
            f.close()
    
    return total_count


# TODO RollbackException?
cdef obi_errno_to_exception(index_t line_nb=-1, object elt_id=None, str error_message=None) :
    global obi_errno
    if obi_errno > 0 :
        if obi_errno == OBI_LINE_IDX_ERROR :
            raise IndexError(line_nb, None or error_message)
        elif obi_errno == OBI_ELT_IDX_ERROR :
            raise IndexError(elt_id, None or error_message)
        else :
            raise Exception(None or error_message)


cdef bytes str2bytes(str string):
    """
    Short cut to convert ascii encoded python string (str) to bytes 
    which can be easily converted to C-strings. 
    
        @param string: the python string to be converted.
        @type string: str
        @return a transcoded string
        @rtype: bytes 
    """
    return string.encode('ascii')

cdef str bytes2str(bytes string):
    """
    Short cut to convert bytes (C-strings) to ascii encoded python string (str).
    
        @param string: the binary (C-string) string to be converted.
        @type string: bytes
        @return an ascii transcoded string
        @rtype: str 
    """
    return string.decode('ascii')

cdef bytes tobytes(object string):
    """
    Short cut to convert ascii encoded string (str or bytes) to bytes 
    which can be easily converted to C-strings. 
    
        @param string: the python string to be converted.
        @type string: bytes or str
        @return a transcoded string
        @rtype: bytes 
    """
    if string is None:
        return None
    if isinstance(string, bytes):
        return string
    return str2bytes(string)


cdef str tostr(object string):
    """
    Short cut to convert ascii encoded string (str or bytes) to bytes 
    which can be easily converted to C-strings. 
    
        @param string: the python string to be converted.
        @type string: bytes or str
        @return a transcoded string
        @rtype: bytes 
    """
    if isinstance(string, str):
        return string
    return bytes2str(string)


cdef object bytes2str_object(object value):  # Only works if complex types are dict or list
    if isinstance(value, dict):
        items = [(k,v) for k,v in value.items()]
        for k, v in items:
            if isinstance(v, list) or isinstance(v, dict):
                value[k] = bytes2str_object(v)
            else:
                if type(v) == bytes:
                    value[k] = bytes2str(v)
            if type(k) == bytes:
                value[bytes2str(k)] = value.pop(k)
    elif isinstance(value, list):
        for i in range(len(value)):
            if isinstance(value[i], list) or isinstance(value[i], dict):
                value[i] = bytes2str_object(value[i])
            if type(value[i]) == bytes:
                value[i] = bytes2str(value[i])
    elif type(value) == bytes:
        value = bytes2str(value)
    return value


cdef object str2bytes_object(object value):  # Only works if complex types are dict or list
    if isinstance(value, dict):
        items = [(k,v) for k,v in value.items()]
        for k, v in items:
            if isinstance(v, list) or isinstance(v, dict):
                value[k] = str2bytes_object(v)
            else:
                if type(v) == str:
                    value[k] = str2bytes(v)
            if type(k) == str:
                value[str2bytes(k)] = value.pop(k)
    elif isinstance(value, list):
        for i in range(len(value)):
            if isinstance(value[i], list) or isinstance(value[i], dict):
                value[i] = str2bytes_object(value[i])
            if type(value[i]) == str:
                value[i] = str2bytes(value[i])
    elif type(value) == str:
        value = str2bytes(value)
    return value


cdef object clean_empty_values_from_object(object value, exclude=[]):    # Only works if complex types are dict or list
    if isinstance(value, dict):
        items = [(k,v) for k,v in value.items()]
        for k, v in items:
            if isinstance(v, list) or isinstance(v, dict):
                value[k] = clean_empty_values_from_object(v)
            if (k not in exclude) and (v is None or (hasattr(v, '__len__') and len(v) == 0)):
                value.pop(k)
    elif isinstance(value, list):
        to_remove=[]
        for i in range(len(value)):
            if isinstance(value[i], list) or isinstance(value[i], dict):
                value[i] = clean_empty_values_from_object(value[i])
            if value[i] is None or (hasattr(value[i], '__len__') and len(value[i]) == 0):
                to_remove.append(value[i])
        for v in to_remove:
            value.remove(v)
    return value


cdef obitype_t get_obitype_single_value(object value) :

    cdef type       value_type
    cdef obitype_t  value_obitype
    
    if value is None :
        return OBI_VOID
    
    value_type = type(value)
    value_obitype = OBI_VOID
                
    if value_type == int :
        value_obitype = OBI_INT
    elif value_type == float :
        value_obitype = OBI_FLOAT
    elif value_type == bool :
        value_obitype = OBI_BOOL        
    elif value_type == str or value_type == bytes :
        if is_a_DNA_seq(tobytes(value)): #or value_type == Nuc_Seq or value_type == Nuc_Seq_Stored:  # TODO discuss
            value_obitype = OBI_SEQ
        elif len(value) == 1 :
            value_obitype = OBI_CHAR
        elif (len(value) > 1) :
            value_obitype = OBI_STR
    else :
        value_obitype = OBI_VOID
    
    return value_obitype


cdef obitype_t update_obitype(obitype_t obitype, object new_value) :
    
    cdef type new_type
    
    new_type = type(new_value)
    
    if obitype == OBI_INT :
        if new_type == float :
            return OBI_FLOAT
    # TODO BOOL vers INT/FLOAT
    elif new_type == str or new_type == bytes :
        if obitype == OBI_SEQ and is_a_DNA_seq(tobytes(new_value)) :
            pass
        else :
            return OBI_STR
    
    return obitype


cdef obitype_t get_obitype_iterable_value(object value) :
    
    cdef obitype_t value_obitype
    
    value_obitype = OBI_VOID
    
    for k in value :
        if value_obitype == OBI_VOID :
            value_obitype = get_obitype_single_value(value[k])
        else :
            value_obitype = update_obitype(value_obitype, value[k])
    
    return value_obitype


cdef obitype_t get_obitype(object value) :
    
    if type(value) == dict or type(value) == list or type(value) == tuple :
        return get_obitype_iterable_value(value)
    
    else :
        return get_obitype_single_value(value)


__re_int__      = re.compile(b"^[+-]?[0-9]+$")
__re_float__    = re.compile(b"^[+-]?[0-9]+(\.[0-9]*)?([eE][+-]?[0-9]+)?$")
__re_str__      = re.compile(b"""^"[^"]*"|'[^']*'$""")
__re_dict__     = re.compile(b"""^\{\ *
                                   (
                                       ("[^"]*"|'[^']*')
                                        \ *:\ *
                                       ([^,}]+|
                                        "[^"]*"|
                                        '[^']*'
                                       )
                                   )?
                                   (\ *,\ *
                                       ("[^"]*"|'[^']*')
                                        \ *:\ *
                                       ([^,}]+|
                                        "[^"]*"|
                                        '[^']*'
                                       )
                                    )*\ *\}$""", re.VERBOSE)

__re_val__ = re.compile(b"""(("[^"]*"|'[^']*') *: *([^,}]+|"[^"]*"|'[^']*') *[,}] *)""")

cdef object __etag__(bytes x, bytes nastring=b"NA"):
    cdef list elements
    cdef tuple i
    
    if x == nastring:
        v = None
    elif __re_int__.match(x):
        v=int(x)
    elif __re_float__.match(x):
        v=float(x)
    elif __re_str__.match(x):
        v=x[1:-1]
    elif x==b'None':
        v=None
    elif x==b'False':
        v=False
    elif x==b'True':
        v=True
    elif __re_dict__.match(x):
        elements=__re_val__.findall(x)
        v=dict([(i[1][1:-1],__etag__(i[2])) for i in elements])
    else:
        v=x
    return v
