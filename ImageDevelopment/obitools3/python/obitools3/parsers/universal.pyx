#cython: language_level=3

import re 
from obitools3.parsers.fasta import fastaNucIterator
from obitools3.parsers.fastq import fastqIterator
from obitools3.parsers.tab import tabIterator
from obitools3.parsers.ngsfilter import ngsfilterIterator
from obitools3.parsers.embl import emblIterator
from obitools3.parsers.genbank import genbankIterator


oligore = re.compile(b"^[ACGTRYSWKMBDHVN]+$",re.I)
tagre   = re.compile(b"^([ACGTRYSWKMBDHVN]+|-)(:([ACGTRYSWKMBDHVN]+)|-)?$",re.I)

def is_ngsfilter_line(line):    # TODO doesn't work?
    try:
        parts = line.split()
        ok = tagre.match(parts[2])
        ok&= oligore.match(parts[3])
        ok&= oligore.match(parts[4])
        ok&= parts[5]==b"F" | parts[5]==b"T"
        return ok
    except:
        return False

def entryIteratorFactory(lineiterator, 
                          int skip=0,
                          only=None,
                          bytes seqtype=b'nuc',
                          int offset=-1,
                          bint noquality=False,
                          bint skiperror=True,
                          bint header=False,
                          bytes sep=None,
                          bytes dec=b'.',
                          bytes nastring=b"NA",
                          bint stripwhite=True,
                          bint blanklineskip=True,
                          bytes commentchar=b"#",
                          int buffersize=100000000):

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
        
    first=next(i)    

    format=b"tabular"
    
    try: 
        if first[:1]==b">":
            format=b"fasta"
        if first[:1]==b"@":
            format=b"fastq"
        elif first[0:3]==b'ID ':
            format=b"embl"
        elif first[0:6]==b'LOCUS ':
            format=b"genbank"
        elif first[0:8]==b'#@ecopcr':
            format=b"ecopcrfile"
        elif is_ngsfilter_line(first):
            format=b"ngsfilter"
    except IndexError:
        pass
            
    # TODO Temporary fix
    first=None
    lineiterator.seek(0)
    
    if format==b'fasta':
        if seqtype == b'nuc':
            return (fastaNucIterator(lineiterator,
                                    skip=skip,only=only,
                                    firstline=first,
                                    buffersize=buffersize,
                                    nastring=nastring),
                    Nuc_Seq,
                    format)
        else:
            raise NotImplementedError()
    elif format==b'fastq':
            return (fastqIterator(lineiterator,
                                 skip=skip,only=only,
                                 offset=offset,
                                 noquality=noquality,
                                 firstline=first,
                                 buffersize=buffersize,
                                 nastring=nastring),
                    Nuc_Seq,
                    format)
    elif format==b'tabular':
            return (tabIterator(lineiterator,
                                header = header,
                                sep = sep,
                                dec = dec,
                                stripwhite = stripwhite,
                                blanklineskip = blanklineskip,
                                commentchar = commentchar,
                                nastring=nastring,
                                skip = skip,
                                only = only,
                                firstline=first,
                                buffersize=buffersize),
                    dict,
                    format)
    elif format==b'ngsfilter':
            return (ngsfilterIterator(lineiterator,
                                      sep = sep,
                                      dec = dec,
                                      stripwhite = stripwhite,
                                      blanklineskip = blanklineskip,
                                      commentchar = commentchar,
                                      nastring=nastring,
                                      skip = skip,
                                      only = only,
                                      firstline=first,
                                      buffersize=buffersize),
                    dict,
                    format)

    elif format==b'embl':
            return (emblIterator(lineiterator, 
                                 skip=skip,
                                 only=only,
                                 firstline=first,
                                 buffersize=buffersize),
                    Nuc_Seq,
                    format)

    elif format==b'genbank':
            return (genbankIterator(lineiterator, 
                                    skip=skip,
                                    only=only,
                                    firstline=first,
                                    buffersize=buffersize),
                    Nuc_Seq,
                    format)
    
    raise NotImplementedError('File format iterator not implemented yet')

