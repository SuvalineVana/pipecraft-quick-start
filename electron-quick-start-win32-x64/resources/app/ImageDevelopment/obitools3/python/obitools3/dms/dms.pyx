#cython: language_level=3


from libc.stdlib  cimport free, atexit
from cpython.list cimport PyList_Size

from .capi.obidms cimport obi_open_dms, \
                          obi_create_dms, \
                          obi_close_dms, \
                          obi_dms_exists, \
                          obi_dms_get_full_path, \
                          obi_close_atexit, \
                          obi_dms_write_comments
                                                      
from .capi.obitypes cimport const_char_p
                            
from obitools3.utils cimport bytes2str, \
                             str2bytes, \
                             tobytes, \
                             tostr, \
                             bytes2str_object, \
                             str2bytes_object, \
                             clean_empty_values_from_object
                             
from .object cimport OBIDeactivatedInstanceError

from pathlib import Path

from .view import view
from .object import OBIWrapper

import json
import time


cdef class DMS(OBIWrapper):    
    
    cdef inline OBIDMS_p pointer(self) :
        return <OBIDMS_p>(self._pointer)
    
    
    @staticmethod
    def obi_atexit() :
        atexit(obi_close_atexit)
    
    
    @staticmethod
    def open_or_new(object dms_name) :
        cdef OBIDMS_p pointer
        cdef DMS dms
        cdef bytes dms_name_b = tobytes(dms_name)
        if DMS.exists(dms_name_b) :
            pointer = obi_open_dms(<const_char_p> dms_name_b, False)      
        else :
            pointer = obi_create_dms(<const_char_p> dms_name_b)  
        if pointer == NULL :
            raise Exception("Failed opening or creating an OBIDMS")
        dms = OBIWrapper.new_wrapper(DMS, pointer)
        return dms
    
    
    @staticmethod
    def exists(object dms_name) :
        cdef bytes dms_name_b = tobytes(dms_name)
        cdef int rep
        rep = obi_dms_exists(dms_name_b)
        if rep < 0 :
            raise RuntimeError("Error checking if a DMS exists")
        else :
            return bool(rep)
        
    
    @staticmethod
    def new(object dms_name) :
        cdef OBIDMS_p pointer
        cdef DMS dms
        cdef bytes dms_name_b = tobytes(dms_name)
        pointer = obi_create_dms(<const_char_p> dms_name_b)      
        if pointer == NULL :
            raise Exception("Failed creating an OBIDMS")
        dms = OBIWrapper.new_wrapper(DMS, pointer)
        return dms


    @staticmethod
    def open(object dms_name) :
        cdef OBIDMS_p pointer
        cdef DMS dms
        cdef bytes dms_name_b = tobytes(dms_name)
        pointer = obi_open_dms(<const_char_p> dms_name_b, False)      
        if pointer == NULL :
            raise Exception("Failed opening an OBIDMS")
        dms = OBIWrapper.new_wrapper(DMS, pointer)
        return dms
    
    
    def close(self) :
        '''
        Closes the DMS instance and free the associated memory
        
        The `close` method is automatically called by the object destructor.
        '''
        cdef OBIDMS_p pointer = self.pointer()
        if self.active() :
            OBIWrapper.close(self)
            if (obi_close_dms(pointer, False)) < 0 :
                raise Exception("Problem closing an OBIDMS")


    # name property getter
    @property
    def name(self) :
        '''
        Returns the name of the DMS instance
        
            @rtype: bytes
        '''
        return <bytes> self.pointer().dms_name


    # DMS full path property getter
    @property
    def full_path(self) :
        '''
        Returns the full path including the name with the extension of the DMS directory
        
            @rtype: bytes
        '''
        return <bytes> self.pointer().directory_path


    # DMS name with full path property getter
    @property
    def name_with_full_path(self) :
        '''
        Returns the full path with the name (meaning without the '.obidms' extension) of the DMS directory
        
            @rtype: bytes
        '''
        return <bytes> self.full_path[:-7]


    # command history DOT graph property getter in the form of a bytes string
    @property
    def dot_history_graph(self):
        complete_graph = []
        for view_name in self:
            complete_graph.extend(self[view_name].dot_history_graph_list)
        uniq_graph = []
        for elt in complete_graph:
            if elt not in uniq_graph:
                uniq_graph.append(elt)
        uniq_graph.insert(0, b"digraph \""+self.name+b"\" {\n")
        uniq_graph.append(b"}")
        return b"".join(uniq_graph)


    @OBIWrapper.checkIsActive
    def keys(self) :
        
        cdef const_char_p path = obi_dms_get_full_path(self.pointer(), b"VIEWS")
        
        if path == NULL:
            raise RuntimeError("Cannot retrieve the view database path")
        
        p = Path(bytes2str(path))
        
        free(path)
        
        for v in p.glob("*.obiview") :
            yield str2bytes(v.stem)


    @OBIWrapper.checkIsActive
    def values(self) :
        cdef bytes view_name
        for view_name in self.keys():
            yield self.get_view(view_name)
    
    
    @OBIWrapper.checkIsActive
    def items(self) :
        cdef bytes view_name
        for view_name in self.keys():
            yield (view_name, self.get_view(view_name))
    
    
    @OBIWrapper.checkIsActive
    def __contains__(self, key) :
        
        cdef str key_s = tostr(key)
        
        cdef const_char_p path = obi_dms_get_full_path(self.pointer(), b"VIEWS")
        p = Path(bytes2str(path),key_s)

        free(path)
        
        return p.with_suffix(".obiview").is_file()
    
    
    cpdef int view_count(self) :
        return PyList_Size(list(self.keys()))
    
    
    @OBIWrapper.checkIsActive
    def __len__(self) :
        return self.view_count()
    
    
    @OBIWrapper.checkIsActive
    def __getitem__(self, object view_name):
        return self.get_view(view_name)
    
    
    @OBIWrapper.checkIsActive
    def __iter__(self) :
        return self.keys()
    
    
    @OBIWrapper.checkIsActive
    def get_view(self, object view_name) :
        return view.View.open(self, view_name)


    @OBIWrapper.checkIsActive
    def __repr__(self):
        cdef str s 
        s=""
        for view_name in self.keys():
            s = s + repr(self.get_view(view_name)) + "\n"
        return s
    

    @OBIWrapper.checkIsActive    
    def record_command_line(self, command_line):
        t = time.asctime(time.localtime(time.time()))
        if "command_line_history" not in self.comments:
            l = []
        else:
            l = self.comments["command_line_history"]
        l.append({"command":command_line, "time":t})
        self.comments["command_line_history"] = l
        

    # comments property getter
    @property
    def comments(self):
        return DMS_comments(self)
    @comments.setter
    def comments(self, object value):
        DMS_comments(self, value)


    # bash command history property getter
    @property
    def bash_history(self):
        s = b"#!/bin/bash\n\n"
        first = True
        for command in self.command_line_history:
            s+=b"#"
            s+=command[b"time"]
            s+=b"\nobi "
            s+=command[b"command"]
            s+=b"\n"
        return s


    # command line history property getter
    @property
    def command_line_history(self):
        return self.comments[b"command_line_history"]

          
cdef class DMS_comments(dict):   # Not thread safe
    def __init__(self, DMS dms, value=None) :
        if not dms.active() :
            raise OBIDeactivatedInstanceError()
        self._dms = dms
        if value is not None:
            self.update(value)     # TODO test and discuss not overwriting (could use replace bool)
        self._update_from_file()

    def _update_from_file(self):
        cdef bytes comments_json
        cdef str comments_json_str
        cdef OBIDMS_p dms_p
        cdef DMS dms
        if not self._dms.active() :
            raise OBIDeactivatedInstanceError()
        dms = self._dms
        dms_p = <OBIDMS_p>(dms.pointer())
        comments_json = <bytes> dms_p.infos.comments
        comments_json_str = bytes2str(comments_json)
        comments_dict = json.loads(comments_json_str)
        str2bytes_object(comments_dict)
        super(DMS_comments, self).update(comments_dict)
        
    def __getitem__(self, object key):
        if not self._dms.active() :
            raise OBIDeactivatedInstanceError()
        if type(key) == str:
            key = str2bytes(key)
        self._update_from_file()
        return super(DMS_comments, self).__getitem__(key)

    def __setitem__(self, object key, object value):
        cdef OBIDMS_p dms_p
        cdef DMS dms

        if not self._dms.active() :
            raise OBIDeactivatedInstanceError()

        dms = self._dms
        dms_p = <OBIDMS_p>(dms.pointer())

        # Remove virtually empty values from the object    # TODO discuss
        clean_empty_values_from_object(value)
        
        # If value is virtually empty, don't add it    # TODO discuss
        if value is None or len(value) == 0:
            return

        # Convert to bytes
        if type(key) == str:
            key = str2bytes(key)
        value_bytes = str2bytes_object(value)

       # Update dict with comments already written in file
        self._update_from_file()
        
        # Add new element  # TODO don't overwrite?
        super(DMS_comments, self).__setitem__(key, value_bytes)

        # Convert to str because json library doens't like bytes
        dict_str = {key:item for key,item in self.items()}
        dict_str = bytes2str_object(dict_str)
        
        # Convert to json string
        comments_json = json.dumps(dict_str)
        
        # Write new comments
        if obi_dms_write_comments(dms_p, tobytes(comments_json)) < 0:
            raise Exception("Could not write DMS comments, DMS:", dms.name, "comments:", comments_json)

    def update(self, value):
        for k,v in value.items():
            self[k] = v
      
    def __contains__(self, key):
        return super(DMS_comments, self).__contains__(tobytes(key))

    def __str__(self):
        return bytes2str(self._dms.pointer().infos.comments)

        
        
    