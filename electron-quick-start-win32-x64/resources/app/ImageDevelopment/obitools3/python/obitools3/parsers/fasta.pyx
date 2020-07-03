#cython: language_level=3

'''
Created on 30 mars 2016

@author: coissac
'''

import types

from obitools3.dms.obiseq cimport Nuc_Seq


# def fastaIterator(lineiterator, 
#                   int skip=0,
#                   only=None,
#                   firstline=None,
#                   int buffersize=100000000
#                  ):
#     cdef str        ident
#     cdef str        definition
#     cdef dict       tags
#     cdef list       s
#     cdef bytes      sequence
#     cdef int        skipped, ionly, read
#     
#     if only is None:
#         ionly=-1
#     else:
#         ionly=int(only)
# 
#     if isinstance(lineiterator, (str, bytes)):
#         lineiterator=uopen(lineiterator)        
#     if isinstance(lineiterator, LineBuffer):
#         iterator = iter(lineiterator)
#     else:
#         if hasattr(lineiterator, "readlines"):
#             iterator = iter(LineBuffer(lineiterator, buffersize))
#         elif hasattr(lineiterator, '__next__'):
#             iterator = lineiterator
#         else:
#             raise Exception("Invalid line iterator")
#     
#     skipped = 0
#     i = iterator
#     
#     if firstline is None:
#         line = next(i)
#     else:
#         line = firstline
#         
#     while True:
#         
#         if ionly >= 0 and read >= ionly:
#             break
#                 
#         while skipped < skip :
#             line = next(i)
#             try:
#                 while line[0]!='>':
#                     line = next(i)
#             except StopIteration:
#                 pass
#             skipped += 1
# 
#         ident,tags,definition = parseHeader(line)
#         s = []
#         line = next(i)
#             
#         try:
#             while line[0]!='>':
#                 s.append(str2bytes(line)[0:-1])
#                 line = next(i)
#         
#         except StopIteration:
#             pass
#         
#         sequence  = b"".join(s)
# 
#         yield { "id"         : ident,
#                 "definition" : definition,
#                 "sequence"   : sequence,
#                 "quality"    : None,
#                 "offset"     : None,
#                 "tags"       : tags,
#                 "annotation" : {}
#               }
#         
#         read+=1

    
def fastaNucIterator(lineiterator, 
                     int skip=0,
                     only=None,
                     firstline=None,
                     int buffersize=100000000,
                     bytes nastring=b"NA"
                    ):
    
    cdef bytes      ident
    cdef bytes      definition
    cdef dict       tags
    cdef list       s
    cdef bytes      sequence
    cdef int        skipped, ionly, read
    cdef Nuc_Seq    seq
    
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

    skipped = 0
    read = 0
    
    if firstline is None:
        line = next(iterator)
    else:
        line = firstline       
    
    while True:
                
        if ionly >= 0 and read >= ionly:
            break
                
        while skipped < skip :
            line = next(iterator)
            try:
                while line[:1]!=b'>':
                    line = next(iterator)
            except StopIteration:
                pass
            skipped += 1

        ident,tags,definition = parseHeader(line, nastring=nastring)
        s = []
        line = next(iterator)
    
        try:
            while line[:1]!=b'>':
                s.append(line[0:-1])
                line = next(iterator)
        except StopIteration:
            pass
        
        sequence  = b"".join(s)        
        
        seq = Nuc_Seq(ident,
                      sequence,
                      definition=definition,
                      quality=None,
                      offset=-1,
                      tags=tags)
            
        yield seq
        
        read+=1
        
        