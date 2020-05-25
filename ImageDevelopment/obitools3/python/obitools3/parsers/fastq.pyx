#cython: language_level=3

'''
Created on 30 mars 2016

@author: coissac
'''

from obitools3.dms.obiseq cimport Nuc_Seq


def fastqIterator(lineiterator, 
                  int skip=0,
                  only=None,
                  int offset=-1,
                  bint noquality=False,
                  firstline=None,
                  int buffersize=100000000,
                  bytes nastring=b"NA"
                 ):
    if noquality:
        return fastqWithoutQualityIterator(lineiterator,
                                           skip,only,
                                           firstline,
                                           buffersize,
                                           nastring)
    else:
        return fastqWithQualityIterator(lineiterator,
                                        skip,only,
                                        offset,
                                        firstline,
                                        buffersize,
                                        nastring)


def fastqWithQualityIterator(lineiterator, 
                  int skip=0,
                  only=None,
                  int offset=-1,
                  firstline=None,
                  int buffersize=100000000,
                  bytes nastring=b"NA"
                 ):
    
    cdef LineBuffer lb
    cdef bytes      ident
    cdef bytes      definition
    cdef dict       tags
    cdef bytes      sequence
    cdef bytes      quality
    cdef int        skipped, lines_to_skip, ionly, read, j
    
    if only is None:
        ionly=-1
    else:
        ionly=int(only)

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

    i = iterator
    lines_to_skip = skip*4 - (firstline is not None)
    
    for skipped in range(lines_to_skip):
        next(i)
    
    if skip > 0:
        firstline=None
    
    read=0
    
    if firstline is None:
        hline = next(i)
    else:
        hline = firstline
        
    for line in i:
        
        if ionly >= 0 and read >= ionly:
            break
        
        ident,tags,definition = parseHeader(hline, nastring=nastring)
        sequence  = line[0:-1]
        next(i)
        quality   = next(i)[0:-1]

        seq = Nuc_Seq(ident,
                      sequence,
                      definition=definition,
                      quality=quality,
                      offset=offset,
                      tags=tags)
        
        yield seq

        read+=1
        hline = next(i)
    

def fastqWithoutQualityIterator(lineiterator, 
                  int skip=0,
                  only=None,
                  firstline=None,
                  int buffersize=100000000,
                  bytes nastring=b"NA"
                 ):
    cdef bytes      ident
    cdef bytes      definition
    cdef dict       tags
    cdef bytes      sequence
    cdef bytes      quality
    cdef int        skipped, lines_to_skip, ionly, read
    cdef int        j
    
    if only is None:
        ionly=-1
    else:
        ionly=int(only)
    
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
    
    i = iterator
    lines_to_skip = skip*4 - (firstline is not None)
    
    for skipped in range(lines_to_skip):
        next(i)
     
    if skip > 0:
        firstline=None
    
    read=0
    
    if firstline is None:
        hline = next(i)
    else:
        hline = firstline
    
    for line in i:
                
        if ionly >= 0 and read >= ionly:
            break
       
        ident,tags,definition = parseHeader(hline, nastring=nastring)
        sequence  = line[0:-1]
        next(i)
        next(i)
                
        seq = Nuc_Seq(ident,
                      sequence,
                      definition=definition,
                      quality=None,
                      offset=-1,
                      tags=tags)
        
        yield seq
    
        read+=1
        hline = next(i)
        
