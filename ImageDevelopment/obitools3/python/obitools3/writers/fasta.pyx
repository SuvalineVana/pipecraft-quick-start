#cython: language_level=3

'''
Created on oct 12th 2018

@author: celine.mercier.bioinfo@gmail.com
'''

    
cdef class FastaNucWriter:
    
    def __init__(self, 
                 object formatter, 
                 object output_object, 
                 int skip=0,
                 only=None):
                        
        if only is None:
            self.only = -1
        else:
            self.only = int(only)

        self.formatter = formatter
        self.output = output_object
        self.skip = skip
        self.skipped = 0
        self.read = 0
    
    def __call__(self, object seq):
        if self.only > -1 and self.read == self.only:
            raise StopIteration
        if self.skip > 0 and self.skipped < self.skip:
            self.skipped += 1
            return
        self.output.write(self.formatter(seq))
        self.output.write(b"\n")  # TODO is that clean?
        self.read += 1