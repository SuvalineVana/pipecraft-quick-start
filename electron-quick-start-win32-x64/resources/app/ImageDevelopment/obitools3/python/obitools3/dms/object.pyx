#cython: language_level=3

import functools


__c_cython_mapping__ = {}


cdef class OBIObject:

    def __init__(self, __internalCall__) :
                
        if __internalCall__ != 987654 or \
           type(self) == OBIObject or \
           type(self) == OBIWrapper or \
           not isinstance(self, OBIObject) :
            
            raise RuntimeError('OBIObject constructor can not be called directly')
        
        self._dependent_objects = {}


    cdef register(self, OBIObject object):
        self._dependent_objects[id(object)] = object

        
    cdef unregister(self, OBIObject object):
        del self._dependent_objects[id(object)]
        

    def close(self):
    
        cdef OBIObject object
        cdef list      to_close = list((self._dependent_objects).values())
        
        for object in to_close:
            object.close()
        
        assert len(self._dependent_objects.values()) == 0


cdef class OBIWrapper(OBIObject) :
    '''
    The OBIWrapper class enables to wrap a C object representing a DMS or an element from a DMS.
    '''
    
    @staticmethod
    def checkIsActive(instance):
        '''
        Decorator function to check that an instance is still active (associated pointer not NULL)
        '''
        @functools.wraps(instance)
        def check(self,*args,**kargs):
            if self.dead:
                raise OBIDeactivatedInstanceError()            
            return instance(self,*args,**kargs)
        return check
    
    cdef inline size_t cid(self) :
        return <size_t>(self._pointer)
    

    cdef inline bint active(self) :
        return self._pointer != NULL


    def close(self):
        if (self._pointer != NULL):
            OBIObject.close(self)
            del __c_cython_mapping__[<size_t>self._pointer]
            self._pointer = NULL
            
        assert len(self._dependent_objects.values()) == 0


    def __dealloc__(self):
        '''
        Destructor of any OBI instance.
        
        The destructor automatically calls the `close` method and
        therefore closes and frees all associated objects and memory.
        '''
        self.close()

    @property
    def dead(self):
        return self._pointer==NULL
    
    @staticmethod
    cdef object new_wrapper(type constructor, void* pointer) :
    
        cdef OBIWrapper o
        
        if (<size_t>pointer in __c_cython_mapping__):
            #print("Pointer already in cython dict")
            return __c_cython_mapping__[<size_t>pointer]
        else:
            o = constructor(987654)
            o._pointer = pointer
            __c_cython_mapping__[<size_t>pointer] = o
            return o


cdef class OBIDeactivatedInstanceError(Exception):
    pass

