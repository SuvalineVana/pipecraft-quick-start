#cython: language_level=3

cimport cython
from obitools3.dms.view.view cimport Line
from obitools3.utils cimport bytes2str_object, str2bytes, tobytes
from obitools3.dms.column.column cimport Column_line


cdef class TabFormat:
    
    def __init__(self, header=True, bytes NAString=b"NA", bytes sep=b"\t"):
        self.header = header
        self.first_line = True
        self.NAString = NAString
        self.sep = sep
        
    @cython.boundscheck(False)    
    def __call__(self, object data):
        
        line = []
        
        if self.first_line:
            self.tags = [k for k in data.keys()]
        
        for k in self.tags:
            
            if self.header and self.first_line:
                value = tobytes(k)
            else:
                value = data[k]
                if value is not None:
                    if type(value) == Column_line:
                        value = value.bytes()
                    else:
                        value = str2bytes(str(bytes2str_object(value))) # genius programming
                if value is None:
                    value = self.NAString
            
            line.append(value)
      	
        if self.first_line:
            self.first_line = False
      		
        return self.sep.join(value for value in line)
