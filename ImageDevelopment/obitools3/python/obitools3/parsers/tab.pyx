#cython: language_level=3

'''
Created on feb 20th 2018

@author: cmercier
'''

import types
from obitools3.utils cimport __etag__


def tabIterator(lineiterator, 
                bint header = False,
                bytes sep = None,
                bytes dec = b".",          # TODO don't know how to use this to parse
                bint stripwhite=True,
                bint blanklineskip=True,
                bytes commentchar=b"#",
                bytes nastring=b"NA",
                int skip=0,
                only=None,
                firstline=None,
                int buffersize=100000000
                ):
    
    cdef LineBuffer lb
    cdef int        lines_to_skip, ionly, read
    cdef list       data
    cdef dict       view_line
    cdef list       keys
    cdef list       key_types
        
    keys = []
    key_types = []
    skipped = 0
    read = 0
    
    if only is None:
        ionly = -1
    else:
        ionly = int(only)
        
    if isinstance(lineiterator, (str, bytes)):
        lineiterator=uopen(lineiterator)        
    if isinstance(lineiterator, LineBuffer):
        iterator = iter(lineiterator)
    else:
        if hasattr(lineiterator, "readlines"):
            iterator = iter(LineBuffer(lineiterator, buffersize))
        elif hasattr(lineiterator, '__next__'):
            iterator = lineiterator
        else:
            raise Exception("Invalid line iterator")
    
    if firstline is None:
        line = next(iterator)
    else:
        line = firstline       
    
    while True:
        
        if (not line.strip() and blanklineskip) or line[:1] == commentchar:
            line = next(iterator)
        
        if ionly >= 0 and read >= ionly:
            break

        if not keys:
            if header:
                # TODO read types eventually
                keys = line.split(sep)
                keys = [x.strip() for x in keys]
                line = next(iterator)
                continue
            else:
                # TODO ??? default column names? like R?
                keys = [i for i in range(len(line.split(sep)))]
                
        while skipped < skip :
            line = next(iterator)
            skipped += 1

        view_line = {}
        
        # Parse
        data = line.split(sep)

        if stripwhite or key_types:
            data = [x.strip() for x in data]
        
        for i in range(len(data)):
            if key_types:  # TODO handle None when key types are actually read
                view_line[keys[i]] = key_types[i](data[i])
            else:
                view_line[keys[i]] = __etag__(data[i], nastring=nastring)
        
        yield view_line
        
        read+=1
        
        line = next(iterator)
    
        
        