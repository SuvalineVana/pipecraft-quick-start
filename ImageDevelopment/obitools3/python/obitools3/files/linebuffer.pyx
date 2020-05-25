#cython: language_level=3

'''
Created on 30 mars 2016

@author: coissac
'''

cdef class LineBuffer:

    def __init__(self, object fileobj, int size=100000000):
        self.fileobj=fileobj 
        self.size=size
    
    def __iter__(self):
        cdef list buff = self.fileobj.readlines(self.size)
        cdef object  l   # Can be str or bytes
        
        while buff:
            for l in buff:
                yield l
            buff = self.fileobj.readlines(self.size)
    
