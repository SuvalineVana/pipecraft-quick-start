#cython: language_level=3

'''
Created on 28 mars 2016

@author: coissac
'''

import zipfile
import bz2
import gzip

import io

cdef class MagicKeyFile:
    def __init__(self,stream,length=2):
        
        binary=stream
        self.stream = stream
        self.stream_mode = None 
        if hasattr(stream, "mode"):
            self.stream_mode = stream.mode
            if (not 'b' in stream.mode and 
                hasattr(stream, "buffer") and 
                'b' in stream.buffer.mode):
                binary=stream.buffer

        if (self.stream_mode is None and 
            not (hasattr(stream, 'headers') and 
                 hasattr(stream.headers, "keys") and
                 'Content-type' in stream.headers)):
            raise TypeError("stream does not present the good interface")
        
        self.binary=binary
        self.key=binary.read(length)
        self.keylength=length
        self.pos=0
        
    cpdef bytes read(self,int size=-1):
        cdef bytes r
        
        if self.pos < self.keylength:
            if size > (self.keylength - self.pos):
                size = size - self.keylength + self.pos
                r = self.key[self.pos:] + self.binary.read(size)
                self.pos=self.keylength + 1
            elif size >=0 :
                r = self.key[self.pos:(self.pos+size)]
                self.pos+=size
            else:
                r = self.key[self.pos:] + self.binary.read(size)
                self.pos=self.keylength + 1
        else:
            r = self.binary.read(size)
            
        return r

    cpdef bytes read1(self,int size=-1):
        return self.read(size)

    cpdef int tell(self):
        cdef int p
        
        if self.pos < self.keylength:
            p = self.pos 
        else:
            p = self.binary.tell()
        
        return p
    
    def __getattr__(self,name):
        return getattr(self.binary, name)
        

    
cdef class CompressedFile:
        
    def __init__(self,stream):
        cdef int            keylength
        cdef MagicKeyFile   magic
        cdef str            compressor
        cdef bytes          k 
        cdef object         c
        
        cdef dict compress = { 'zip' : (b'\x50\x4b\x03\x04',zipfile.ZipFile),
                               'bz2' : (b'\x42\x5a\x68',bz2.BZ2File),
                               'gz'  : (b'\x1f\x8b\x08',gzip.open)
                   }
        
        keylength = max([len(x[0]) for x in compress.values()])
        magic=MagicKeyFile(stream,keylength)
        
        self.accessor = None
        self.compressed = False

        for compressor in compress:
            k,c = compress[compressor]
            if magic.key.startswith(k):
                self.accessor = c(magic)
                self.compressed = True
        
        if self.accessor is None:
            if 'b' in magic.stream_mode:
                magic.binary.seek(0)
            self.accessor = magic
        
        if ((hasattr(stream, 'headers') and 
             hasattr(stream.headers, "keys") and
             'Content-type' in stream.headers and
             stream.headers['Content-type'].startswith('text/')) or
            'b' not in magic.stream_mode):
            self.accessor = io.TextIOWrapper(self.accessor)
        

    # compressed property getter
    @property
    def compressed(self) :
        '''
        Returns a boolean indicating whether the file is compressed
        
            @rtype: bint
        '''
        return self.compressed

    def __getattr__(self,name):
        return getattr(self.accessor, name)
    
    def __iter__(self):
        for x in self.accessor:
            yield x 