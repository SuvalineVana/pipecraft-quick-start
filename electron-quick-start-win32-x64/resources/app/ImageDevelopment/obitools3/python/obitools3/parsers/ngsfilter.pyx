#cython: language_level=3

'''
Created on march 8th 2018

@author: cmercier
'''

from .tab import tabIterator
import types


def ngsfilterIterator(lineiterator, 
                      bytes sep = None,
                      bytes dec = b".",
                      bint stripwhite=True,
                      bint blanklineskip=True,
                      bytes commentchar=b"#",
                      bytes nastring=b"NA",
                      int skip=0,
                      only=None,
                      firstline=None,
                      int buffersize=100000000
                      ):
    
    cdef list  all_lines
    cdef bytes header 
    cdef bytes out_sep
        
    out_sep = b"\t"

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
    
    all_lines = [line for line in iterator]
    new_lines = []
        
    if firstline is not None:
        all_lines.insert(0, firstline)
        
    # Insert header for column names
    column_names = [b"experiment", b"sample", b"forward_tag", b"reverse_tag", b"forward_primer", b"reverse_primer"]
    header = out_sep.join(column_names)
    
    new_lines.append(header)
        
    for line in all_lines:
        split_line = line.split()
        tags = split_line.pop(2)
        tags = tags.split(b":")
        for t_idx in range(len(tags)):
            if tags[t_idx]==b"-" or tags[t_idx]==b"None" or tags[t_idx]==b"":
                tags[t_idx] = nastring
        if len(tags) == 1:          # Forward and reverse tags are the same
            tags.append(tags[0])
        split_line.insert(2, tags[0])
        split_line.insert(3, tags[1])
        new_lines.append(out_sep.join(split_line[0:6]))
    
    return tabIterator(iter(new_lines),
                       header = True,
                       sep = out_sep,
                       dec = dec,
                       stripwhite = stripwhite,
                       blanklineskip = blanklineskip,
                       commentchar = commentchar,
                       nastring = nastring,
                       skip = skip,
                       only = only,
                       firstline = None)

