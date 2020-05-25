#cython: language_level=3

'''
Created on June 12th 2018

@author: coissac/mercier
'''


import types
import re
import sys
import os
import glob

from obitools3.files.universalopener cimport uopen
from obitools3.utils cimport tostr
from obitools3.dms.obiseq cimport Nuc_Seq
from .embl_genbank_features import extractTaxon # TODO cimport

from libc.stdlib  cimport free, malloc, realloc
from libc.string cimport strcpy, strlen


_featureMatcher = re.compile(b'(^FT  .*\n)+', re.M)
_cleanFT       = re.compile(b'^FT',re.M)

_headerMatcher = re.compile(b'^ID.+(?=\nFH  )', re.DOTALL)
_seqMatcher    = re.compile(b'(^    ).+(?=//\n)', re.DOTALL + re.M)
_cleanSeq      = re.compile(b'[ \n0-9]+')
_acMatcher     = re.compile(b'(?<=^AC   ).+',re.M)
_deMatcher     = re.compile(b'(^DE   .+\n)+',re.M)
_cleanDe       = re.compile(b'(^|\n)DE +')


def emblParser(bytes text):
    
    cdef Nuc_Seq seq
        
    try:
        header = _headerMatcher.search(text).group()

        ft     = _featureMatcher.search(text).group()
        ft     = _cleanFT.sub(b'  ',ft)
        
        s      = _seqMatcher.search(text).group()
        s      = _cleanSeq.sub(b'', s).upper()

        acs    = _acMatcher.search(text).group()
        acs    = acs.replace(b';', b' ')
        acs    = acs.split()
        ac     = acs[0]
        acs    = acs[1:]

        de     = _deMatcher.search(header).group()
        de     = _cleanDe.sub(b' ', de).strip().strip(b'.')

    except Exception as e:
        print("\nCould not import sequence id:", text.split()[1], "(error raised:", e, ")")
        # Do not raise any Exception if you need the possibility to resume the generator
        # (Python generators can't resume after any exception is raised)
        return None
        
    tags = {}
    extractTaxon(ft, tags)
        
    seq = Nuc_Seq(ac,
                  s,
                  definition=de,
                  quality=None,
                  offset=-1,
                  tags=tags)
    
    return seq


def emblIterator_file(lineiterator, 
                      int skip=0,
                      only=None,
                      firstline=None,
                      int buffersize=100000000
                      ):
    cdef int        lines_to_skip, ionly, read
    cdef Nuc_Seq    seq
    cdef char*      entry = NULL
    cdef size_t     entry_buffer_size 
    cdef int        entry_len
    cdef int        line_len   
    
    entry_buffer_size = 2048
    
    entry = <char*> malloc(entry_buffer_size*sizeof(char)) 

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
        
        if ionly >= 0 and read >= ionly-1:
            break
                
        while skipped < skip:
            line = next(iterator)
            try:
                while line[:2] != b'//':
                    line = next(iterator)
                line = next(iterator)
            except StopIteration:
                break
            skipped += 1

        try:
            entry_len = 0
            while line[:2] != b'//':
                line_len = strlen(line)
                while (entry_len + line_len) >= entry_buffer_size:
                    entry_buffer_size*=2
                    entry = <char*>realloc(entry, entry_buffer_size)
                strcpy(entry+entry_len, line)
                entry_len+=line_len
                line = next(iterator)
            # Add last line too because need the // flag to parse
            line_len = strlen(line)
            while (entry_len + line_len) >= entry_buffer_size:
                entry_buffer_size*=2
                entry = <char*>realloc(entry, entry_buffer_size)
            strcpy(entry+entry_len, line)
            line = next(iterator)
        except StopIteration:
            break
                
        seq = emblParser(entry)
                
        yield seq
        read+=1
    
    yield seq
    
    free(entry)
        

def emblIterator_dir(dir_path, 
                     int skip=0,
                     only=None,
                     firstline=None,
                     int buffersize=100000000
                     ):
    path = dir_path
    read = 0
    read_files = 0
    files = [filename for filename in glob.glob(os.path.join(path, b'*.dat*'))]
    for filename in files:
        if read==only:
            return
        print("Parsing file %s (%d/%d)" % (tostr(filename), read_files, len(files)))
        f = uopen(filename)
        if only is not None:
            only_f = only-read
        else:
            only_f = None
        for seq in emblIterator_file(f, skip=skip, only=only_f, buffersize=buffersize):
            yield seq
            read+=1
        read_files+=1


def emblIterator(obj, 
                 int skip=0,
                 only=None,
                 firstline=None,
                 int buffersize=100000000
                ):
    if type(obj) == bytes or type(obj) == str :
        return emblIterator_dir(obj, skip=skip, only=only, firstline=firstline, buffersize=buffersize)
    else:
        return emblIterator_file(obj, skip=skip, only=only, firstline=firstline, buffersize=buffersize)


