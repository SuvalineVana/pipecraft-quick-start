#cython: language_level=3


cdef dict __VIEW_CLASS__= {}


from libc.stdlib  cimport malloc

from ..capi.obiview cimport Alias_column_pair_p, \
                            obi_new_view, \
                            obi_open_view, \
                            obi_clone_view, \
                            obi_rollback_view, \
                            obi_save_and_close_view, \
                            obi_view_get_pointer_on_column_in_view, \
                            obi_view_delete_column, \
                            obi_view_create_column_alias, \
                            obi_view_write_comments, \
                            obi_delete_view
                           
from ..capi.obidmscolumn cimport OBIDMS_column_p
from ..capi.obidms cimport OBIDMS_p

from obitools3.utils cimport tobytes, \
                             str2bytes, \
                             bytes2str, \
                             tostr, \
                             bytes2str_object, \
                             str2bytes_object, \
                             clean_empty_values_from_object, \
                             get_obitype
   
from ..object cimport OBIDeactivatedInstanceError

from obitools3.dms.view import typed_view

from ..capi.obitypes cimport is_a_DNA_seq, \
                             OBI_VOID, \
                             OBI_BOOL, \
                             OBI_CHAR, \
                             OBI_FLOAT, \
                             OBI_INT, \
                             OBI_QUAL, \
                             OBI_SEQ, \
                             OBI_STR

from ..capi.obidms cimport obi_import_view

from obitools3.format.tab import TabFormat

import importlib
import inspect
import pkgutil
import json


cdef class View(OBIWrapper) :

    cdef inline Obiview_p pointer(self) :
        return <Obiview_p>(self._pointer)        
    
    @staticmethod
    # TODO try cdef again
    def get_view_class(bytes view_type):
        global __VIEW_CLASS__
        return __VIEW_CLASS__.get(view_type, View) 
 
 
    @staticmethod
    def import_view(object dms_1, object dms_2, object view_name_1, object view_name_2):
        if obi_import_view(tobytes(dms_1), tobytes(dms_2), tobytes(view_name_1), tobytes(view_name_2)) < 0 :
            raise Exception("Error importing a view")


    @staticmethod
    def delete_view(DMS dms, object view_name):
        if (obi_delete_view(dms.pointer(), tobytes(view_name)) < 0):
            raise Exception("Error deleting a view")
        
    
    @staticmethod
    def new(DMS dms, 
            object view_name, 
            object comments={}):

        cdef bytes view_name_b = tobytes(view_name)
        cdef bytes comments_b
        cdef str   message
        cdef void* pointer

        cdef View view  # @DuplicatedSignature

        comments_b = str2bytes(json.dumps(bytes2str_object(comments)))

        pointer = <void*>obi_new_view(<OBIDMS_p>dms._pointer, 
                                      view_name_b, 
                                      NULL, 
                                      NULL, 
                                      comments_b)
        
        if pointer == NULL :
            message = "Error : Cannot create view %s" % bytes2str(view_name_b)
            raise RuntimeError(message)
        
        view = OBIWrapper.new_wrapper(View, pointer)
        view._dms = dms
        dms.register(view)

        return view
    
          
    def clone(self, 
              object view_name, 
              object comments={}):
                          
        cdef bytes view_name_b = tobytes(view_name)
        cdef bytes comments_b
        cdef void* pointer
        cdef View  view
        
        if not self.active() :
            raise OBIDeactivatedInstanceError()
        
        comments_b = str2bytes(json.dumps(bytes2str_object(dict(comments))))  # TODO hmmmmm function in View_comments class probably
                 
        pointer = <void*> obi_clone_view(self._dms.pointer(), 
                                         self.pointer(), 
                                         view_name_b, 
                                         NULL, 
                                         comments_b)
 
        if pointer == NULL :
            raise RuntimeError("Error : Cannot clone view %s into view %s" 
                               % (str(self.name),
                                  bytes2str(view_name_b))
                              )
            
        view = OBIWrapper.new_wrapper(type(self), pointer)
        view._dms = self._dms
        self._dms.register(view)
                                
        return view
    
        
    @staticmethod
    def open(DMS dms,               # @ReservedAssignment
             object view_name):

        cdef bytes view_name_b = tobytes(view_name)
        cdef void* pointer
        cdef View  view
        cdef type  view_class
        
        pointer = <void*> obi_open_view(dms.pointer(), 
                                        view_name_b)                
                
        if pointer == NULL :
            raise RuntimeError("Error : Cannot open view %s" % bytes2str(view_name_b))
        
        view_class = View.get_view_class((<Obiview_p>pointer).infos.view_type)
        view = OBIWrapper.new_wrapper(view_class, pointer)
    
        view._dms = dms
        dms.register(view)
                
        return view
        
    
    def close(self):
        cdef Obiview_p pointer = self.pointer()
        
        if self.active() :
            self._dms.unregister(self)
            OBIWrapper.close(self)      
            if obi_save_and_close_view(pointer) < 0 :
                raise Exception("Problem closing view %s" % 
                                bytes2str(self.name))
    
    
    @OBIWrapper.checkIsActive
    def __repr__(self) :         
        cdef str s = "#View name:\n{name:s}\n#Line count:\n{line_count:d}\n#Columns:\n".format(name       = bytes2str(self.name),
                                                                                                                         line_count = self.line_count)
        for column_name in self.keys() :
            s = s + repr(self[column_name]) + '\n'
        return s
    
     
    def keys(self):
        
        cdef bytes               col_alias
        cdef int                 i
        cdef Obiview_p           pointer   = self.pointer()
        cdef int                 nb_column = pointer.infos.column_count
        cdef Alias_column_pair_p column_p  = pointer.infos.column_references
        
        if not self.active() :
            raise OBIDeactivatedInstanceError()

        for i in range(nb_column) :
            col_alias = column_p[i].alias
            yield col_alias


    def get_column(self,
                   object column_name):

        if not self.active() :
            raise OBIDeactivatedInstanceError()
                
        return Column.open(self, tobytes(column_name))


    def get_column_with_idx(self,
                            int column_idx):

        cdef Obiview_p           pointer   = self.pointer()
        cdef int                 nb_column = pointer.infos.column_count
        
        if not self.active() :
            raise OBIDeactivatedInstanceError()
        
        if column_idx > nb_column :
            raise IndexError(column_idx, "No column with this index")
                        
        return Column.open(self, pointer.infos.column_references[column_idx].alias)

    
    cpdef delete_column(self, 
                        object column_name,
                        bint delete_file=False) :

        cdef bytes column_name_b = tobytes(column_name)

        if not self.active() :
            raise OBIDeactivatedInstanceError()
 
        # Close the cython instance first
        col = self[column_name_b]
        col.close()
        
        # Remove the column from the view which closes the C structure
        if obi_view_delete_column(self.pointer(), column_name_b, delete_file) < 0 :
            raise RollbackException("Problem deleting column %s from a view",
                            bytes2str(column_name_b), self)


    cpdef rename_column(self, 
                        object current_name, 
                        object new_name):
                        
        cdef Column column
        cdef bytes current_name_b = tobytes(current_name)
        cdef bytes new_name_b     = tobytes(new_name)
        
        if not self.active() :
            raise OBIDeactivatedInstanceError()
        
        if (obi_view_create_column_alias(self.pointer(), 
                                         tobytes(current_name_b), 
                                         tobytes(new_name_b)) < 0) :
            raise RollbackException("Problem in renaming column %s to %s" % (
                                bytes2str(current_name_b),
                                bytes2str(new_name_b)), self)


    # TODO warning, not multithreading compliant
    cpdef Column rewrite_column_with_diff_attributes(self,
                                                     object    column_name,
                                                     obitype_t new_data_type=<obitype_t>OBI_VOID,
                                                     index_t   new_nb_elements_per_line=0,
                                                     list      new_elements_names=None,
                                                     bint      rewrite_last_line=False) :
        
        cdef Column  old_column                                             
        cdef Column  new_column
        cdef index_t length = len(self)
        cdef column_name_b = tobytes(column_name)

        if rewrite_last_line is False:
            length-=1
            
        if not self.active() :
            raise OBIDeactivatedInstanceError()

        old_column = self.get_column(column_name_b)

        if new_data_type == 0 :
            new_data_type = old_column.data_type
        
        if new_nb_elements_per_line == 0 :
            new_nb_elements_per_line = old_column.nb_elements_per_line
        
        if new_elements_names is None :
            new_elements_names = old_column._elements_names

        new_column = Column.new_column(self, old_column.pointer().header.name, new_data_type, 
                                       nb_elements_per_line=new_nb_elements_per_line, elements_names=new_elements_names, 
                                       comments=old_column.comments, alias=column_name_b+tobytes('___new___'))
        
        switch_to_dict = old_column.nb_elements_per_line == 1 and new_nb_elements_per_line > 1
        ori_key = old_column._elements_names[0]
        
        for i in range(length) :
            if switch_to_dict :
                new_column[i] = {ori_key: old_column[i]}
            else:
                new_column[i] = old_column[i]

        # Remove old column from view
        self.delete_column(column_name_b, delete_file=True)

        # Rename new
        new_column.name = column_name_b
        
        return new_column


    cpdef Line_selection new_selection(self, list lines=None):
        if not self.active() :
            raise OBIDeactivatedInstanceError()
        return Line_selection(self, lines)

    
    @OBIWrapper.checkIsActive
    def __iter__(self):
        # Iteration on each line of all columns
        
        # Declarations
        cdef index_t line_nb
        
        # Yield each line    
        for line_nb in range(self.line_count) :
            yield Line(self, line_nb)

    
    # TODO test time gain without
    @OBIWrapper.checkIsActive
    def __getitem__(self, object ref) :
        if type(ref) == int :
            return Line(self, ref)
        else :  # TODO assume str or bytes for optimization (discuss)
            return self.get_column(ref)    # note: slow, always better to keep column ref in a variable            

    
    @OBIWrapper.checkIsActive
    def __setitem__(self, index_t idx, object item) :
        cdef Column col
        line = self[idx]
        for k in item :
            # If setting from another View Line and the column doesn't exist, create it based on the informations from the other View
            # TODO use clone_column
            if isinstance(item, Line) and tostr(k) not in self:
                col = item.view[k]
                Column.new_column(self, 
                                  col.original_name, 
                                  col.data_type_int, 
                                  nb_elements_per_line = col.nb_elements_per_line,
                                  elements_names = col._elements_names,
                                  tuples = col.tuples,
                                  to_eval = col.to_eval,
                                  comments = col.comments,
                                  alias=k
                                 )
            line[k] = item[k]
    
    
    @OBIWrapper.checkIsActive
    def __contains__(self, object column_name):
        return (tobytes(column_name) in self.keys())
    
    
    @OBIWrapper.checkIsActive
    def __len__(self):
        return(self.line_count)

    
    @OBIWrapper.checkIsActive
    def __str__(self) :
        cdef Line line
        cdef str to_print
        to_print = ""
        for line in self :
            to_print = to_print + str(line) + "\n"
        return to_print

    
    @staticmethod
    def _config_to_dict(dict config, str command_name, str command_line, list input_str=None, list input_dms_name=None, list input_view_name=None):
        INVALID_KEYS = ["__root_config__", "module", "nocreatedms", "logger", "defaultdms", "inputview", "outputview", "log", "loglevel", "progress", "verbose"]
        comments = {}
        comments["obi"] = {k: config["obi"][k] for k in config["obi"] if k not in INVALID_KEYS}
        comments[command_name] = config[command_name]      # TODO or discuss update instead of nested dict
        comments["command_line"] = command_line
        if input_str is None and input_dms_name is None and input_view_name is None:
            raise Exception("Can't build view configuration with None input")  # TODO discuss
        if (input_dms_name is not None and input_view_name is not None and len(input_dms_name) != len(input_view_name)) or \
            (input_dms_name is None and input_view_name is not None) or \
            (input_dms_name is not None and input_view_name is None):
            raise Exception("Error building view configuration: there must be as many input DMS names as input view names")  # TODO discuss
        comments["input_dms_name"] = input_dms_name
        comments["input_view_name"] = input_view_name
        if input_str is None:
            input_str = []
            for i in range(len(input_view_name)):
                input_str.append(tostr(input_dms_name[i])+"/"+tostr(input_view_name[i]))
        comments["input_str"] = input_str
        return bytes2str_object(comments)

    
    @staticmethod
    def print_config(dict config, str command_name, str command_line, list input_str=None, list input_dms_name=None, list input_view_name=None):
        config_dict = View._config_to_dict(config, command_name, command_line, \
                                           input_str=input_str, input_dms_name=input_dms_name, input_view_name=input_view_name)
        # Clean virtually empty values
        config_dict = clean_empty_values_from_object(config_dict, exclude=[View_comments.KEEP_KEYS])
        # Convert to json string
        comments_json = json.dumps(config_dict)
        return str2bytes(comments_json)


    @staticmethod
    def get_config_dict(dict config, str command_name, str command_line, list input_str=None, list input_dms_name=None, list input_view_name=None):
        config_dict = View._config_to_dict(config, command_name, command_line, \
                                           input_str=input_str, input_dms_name=input_dms_name, input_view_name=input_view_name)
        # Clean virtually empty values
        config_dict = clean_empty_values_from_object(config_dict, exclude=[View_comments.KEEP_KEYS])
        return config_dict
        
    
    @OBIWrapper.checkIsActive
    def write_config(self, dict config, str command_name, str command_line, list input_str=None, list input_dms_name=None, list input_view_name=None):
        self.comments = View._config_to_dict(config, command_name, command_line, \
                                           input_str=input_str, input_dms_name=input_dms_name, input_view_name=input_view_name)
        

    # command and view history DOT graph property getter in the form of a list (to remove duplicate elements afterwards)
    @property
    def dot_history_graph_list(self):
        history = []
        view_history = self.view_history
        history.append(b"\tnode [shape=record]\n")
        history.append(b"\tcompound=true\n")
        for i in range(len(view_history)):
            level = view_history[i]
            for input in level:
                # Command node
                command = b"\""+level[input][b"command_line"]+b"\""
                s = b"\t"
                s+=command
                s+=b" [style=filled, color=lightblue]\n"
                history.append(s)
                if len(input) > 1:
                    # Create invisible node
                    invi_node_name_no_quotes = b"_".join(input)
                    invi_node_name_quotes = b"\""+ invi_node_name_no_quotes + b"\""
                    s = b"\t"
                    s+=invi_node_name_quotes
                    s+=b" [width=0, style=invis, shape=point]\n"
                    history.append(s)
                    # Connect all inputs to the invisible node
                    for elt in input:
                        s = b"\t"
                        s = s+b"\""+elt+b"\""
                        s+=b" -> "
                        s+=invi_node_name_quotes
                        s+=b" [arrowhead=none]\n"
                        history.append(s)
                    to_connect_to_command = invi_node_name_no_quotes
                else:
                    to_connect_to_command = input[0]
                # Color node if input element is a taxonomy (to do for output nodes too if taxonomy history is to be recorded)
                for elt in input:
                    if b"taxonomy" in elt:
                        s = b"\t"
                        s = s+b"\""+elt+b"\""
                        s+=b" [style=filled, color=navajowhite]\n"
                        history.append(s)
                # Connect input to command
                s = b"\t"
                s = s+b"\""+to_connect_to_command+b"\""
                s+=b" -> "
                s+=command
                s+=b"\n"
                history.append(s)
                # Connect command to output
                s = b"\t"
                s+=command
                s+=b" -> "
                s = s+b"\""+level[input][b"output"]+b"\""
                s+=b"\n"
                history.append(s)
        return history


    # command history DOT graph property getter in the form of a bytes string
    @property
    def dot_history_graph(self):
        uniq_graph = []
        for elt in self.dot_history_graph_list:
            if elt not in uniq_graph:
                uniq_graph.append(elt)
        uniq_graph.insert(0, b"digraph \""+self.name+b"\" {\n")
        uniq_graph.append(b"}")
        return b"".join(uniq_graph)


    # ASCII command history graph property getter
    @property
    def ascii_history(self):
        arrow = b"\t|\n\tV\n"
        s = b""
        first = True
        for level in self.view_history:
            command_list = [level[input][b"command_line"] for input in level.keys()]
            if not first:
                s+=arrow
            else:
                first=False
            for command in command_list:
                s+=command
                s+=b"\n"
        return s


    # bash command history property getter
    @property
    def bash_history(self):
        s = b"#!/bin/bash\n\n"
        first = True
        for level in self.view_history:
            command_list = [level[input][b"command_line"] for input in level.keys()]
            for command in command_list:
                s+=command
                s+=b"\n"
        return s


    # View and command history property getter
    @property
    def view_history(self):
        if not self.active() :
            raise OBIDeactivatedInstanceError()
        current_level = [self]
        history = []
        while current_level[0] is not None:   # TODO not sure about robustness
            top_level = []
            level_dict = {}
            for element in current_level:
                if element is not None:
                    if element.comments[b"input_dms_name"] is not None :
                        for i in range(len(element.comments[b"input_dms_name"])) :
                            if element.comments[b"input_dms_name"][i] == element.dms.name and b"/" not in element.comments[b"input_view_name"][i]:  # Same DMS and not a special element like a taxonomy
                                top_level.append(element.dms[element.comments[b"input_view_name"][i]])
                            else:
                                top_level.append(None)
                    else:
                        top_level.append(None)
                    level_dict[tuple(element.comments[b"input_str"])] = {}
                    level_dict[tuple(element.comments[b"input_str"])][b"output"] = element.dms.name+b"/"+element.name
                    level_dict[tuple(element.comments[b"input_str"])][b"command_line"] = element.comments[b"command_line"]
            history.insert(0, level_dict)
            current_level = top_level
        return history


    # Width (column count) property getter
    @property
    def width(self):
        if not self.active() :
            raise OBIDeactivatedInstanceError()
        return self.pointer().infos.column_count

    
    # DMS property getter
    @property
    def dms(self):
        if not self.active() :
            raise OBIDeactivatedInstanceError()
        return self._dms
    
    
    # line_count property getter
    @property
    def line_count(self):
        if not self.active() :
            raise OBIDeactivatedInstanceError()
        return self.pointer().infos.line_count

    # read_only state property getter
    @property
    def read_only(self):
        if not self.active() :
            raise OBIDeactivatedInstanceError()
        return self.pointer().read_only

    # name property getter
    @property
    def name(self):
        if not self.active() :
            raise OBIDeactivatedInstanceError()
        return <bytes> self.pointer().infos.name

    # view type property getter
    @property
    def type(self):  # @ReservedAssignment
        if not self.active() :
            raise OBIDeactivatedInstanceError()
        return <bytes> self.pointer().infos.view_type

    # comments property getter
    @property
    def comments(self):
        return View_comments(self)
    @comments.setter
    def comments(self, object value):
        View_comments(self, value)
        
                  
cdef class View_comments(dict):   # Not thread safe

    KEEP_KEYS = [b"input_dms_name", b"input_view_name", b"input_str", "input_dms_name", "input_view_name", "input_str"]
    
    def __init__(self, View view, value=None) :
        if not view.active() :
            raise OBIDeactivatedInstanceError()
        self._view = view
        if value is not None:
            self.update(value)     # TODO test and discuss not overwriting (could use replace bool)
        self._update_from_file()
    
    def _update_from_file(self):
        cdef bytes comments_json
        cdef str comments_json_str
        cdef Obiview_p view_p
        cdef View view
        if not self._view.active() :
            raise OBIDeactivatedInstanceError()
        view = self._view
        view_p = <Obiview_p>(view.pointer())
        comments_json = <bytes> view_p.infos.comments
        comments_json_str = bytes2str(comments_json)
        comments_dict = json.loads(comments_json_str)
        comments_dict = str2bytes_object(comments_dict)
        super(View_comments, self).update(comments_dict)
        
    def __getitem__(self, object key):
        if not self._view.active() :
            raise OBIDeactivatedInstanceError()
        if type(key) == str:
            key = str2bytes(key)
        self._update_from_file()
        return super(View_comments, self).__getitem__(key)

    def __setitem__(self, object key, object value):
        cdef Obiview_p view_p
        cdef View view

        if not self._view.active() :
            raise OBIDeactivatedInstanceError()

        view = self._view
        view_p = <Obiview_p>(view.pointer())
         
        # Remove virtually empty values from the object    # TODO discuss
        clean_empty_values_from_object(value, exclude=[self.KEEP_KEYS])
        
        # If value is virtually empty, don't add it    # TODO discuss
        if (key not in self.KEEP_KEYS) and (value is None or len(value) == 0):
            return
        
        # Convert to bytes
        if type(key) == str:
            key = str2bytes(key)
        value_bytes = str2bytes_object(value)

        # Update dict with comments already written in file
        self._update_from_file()
       
        # Add new element  # TODO don't overwrite?
        super(View_comments, self).__setitem__(key, value_bytes)
                
        # Convert to str because json library doens't like bytes
        dict_str = {key:item for key,item in self.items()}
        dict_str = bytes2str_object(dict_str)
        
        # Convert to json string
        comments_json = json.dumps(dict_str)

        # Write new comments
        if obi_view_write_comments(view_p, tobytes(comments_json)) < 0:
            raise Exception("Could not write view comments, view:", view.name, "comments:", comments_json)

    def update(self, value):
        for k,v in value.items():
            self[k] = v

    def __contains__(self, key):
        return super(View_comments, self).__contains__(tobytes(key))
    
    def __str__(self):
        return bytes2str(self._view.pointer().infos.comments)


cdef class Line :

    def __init__(self, View view, index_t line_nb) :
        self._index = line_nb
        self._view = view
    
    
    def __getitem__(self, object column_name) :
        return (self._view).get_column(tobytes(column_name))[self._index]


    def __setitem__(self, object column_name, object value):   # TODO discuss
        # TODO detect multiple elements (dict type)? put somewhere else? but more risky (in get)
        # TODO OBI_QUAL ?
        cdef type       value_type
        cdef obitype_t  value_obitype
        cdef bytes      value_b
        cdef bytes      column_name_b
        
        column_name_b = tobytes(column_name)
                
        # TODO use functions in utils
        
        #print(column_name, "value:", value, type(value))
        
        if column_name_b not in self._view :
            if value is None :
                return # TODO discuss. This means that columns aren't created until an identifiable type is found
                #raise RollbackException("Trying to create a column from a None value (can't guess type)", self)
            value_obitype = get_obitype(value)
            if value_obitype == OBI_VOID :
                raise CantGuessTypeException(value)
                #raise RollbackException("Could not guess the type of a value to create a new column", self._view)
            
            Column.new_column(self._view, column_name_b, value_obitype)
 
        (self._view).get_column(column_name_b).set_line(self._index, value)
 
 
    def __iter__(self):
        cdef bytes column_name
        for column_name in (self._view).keys() :
            yield column_name
 
 
    def keys(self):
        return self._view.keys()
 
 
    def __contains__(self, object column_name):
        return (tobytes(column_name) in self.keys())


    def __repr__(self):
        formatter = TabFormat(header=False)
        return bytes2str(formatter(self))


    # View property getter
    @property
    def view(self):
        return self._view

    # index property getter
    @property
    def index(self):
        return self._index


#     cpdef dict get_view_infos(self, str view_name) :
#         
#         cdef Obiview_infos_p      view_infos_p
#         cdef dict                 view_infos_d
#         cdef Alias_column_pair_p  column_refs
#         cdef int                  i, j
#         cdef str                  column_name
# 
#         view_infos_p = obi_view_map_file(self._pointer, 
#                                          tobytes(view_name))
#         view_infos_d = {}
#         view_infos_d["name"] = bytes2str(view_infos_p.name)
#         view_infos_d["comments"] = bytes2str(view_infos_p.comments)
#         view_infos_d["view_type"] = bytes2str(view_infos_p.view_type)
#         view_infos_d["column_count"] = <int> view_infos_p.column_count
#         view_infos_d["line_count"] = <int> view_infos_p.line_count
#         view_infos_d["created_from"] = bytes2str(view_infos_p.created_from)
#         view_infos_d["creation_date"] = bytes2str(obi_format_date(view_infos_p.creation_date))
#         if (view_infos_p.all_lines) :
#             view_infos_d["line_selection"] = None
#         else :
#             view_infos_d["line_selection"] = {}
#             view_infos_d["line_selection"]["column_name"] = bytes2str((view_infos_p.line_selection).column_name)
#             view_infos_d["line_selection"]["version"] = <int> (view_infos_p.line_selection).version
#         view_infos_d["column_references"] = {}
#         column_references = view_infos_p.column_references
#         for j in range(view_infos_d["column_count"]) :
#             column_name = bytes2str((column_references[j]).alias)
#             view_infos_d["column_references"][column_name] = {}
#             view_infos_d["column_references"][column_name]["original_name"] = bytes2str((column_references[j]).column_refs.column_name)
#             view_infos_d["column_references"][column_name]["version"] = (column_references[j]).column_refs.version
#         
#         obi_view_unmap_file(self._pointer, view_infos_p)
# 
#         return view_infos_d



cdef class Line_selection(list):
    
    def __init__(self, View view, lines=None) :
        if view._pointer == NULL:
            raise Exception("Error: trying to create a line selection with an invalidated view")
        self._view = view
        self._view_name = view.name
        
        if lines is not None:
            self.extend(lines)
        
        
    def extend(self, iterable):
        cdef index_t i
        cdef index_t max_i = self._view.line_count
        
        for i in iterable:  # TODO this is already checked in C
            if i > max_i:
                raise RuntimeError("Error: trying to select line %d beyond the line count %d of view %s" %
                                   (i,
                                    max_i,
                                    self._view_name)
                                   )
            list.append(self,i)
        
        
    def append(self, index_t idx) :
        if idx >= self._view.line_count :
            raise IndexError("Error: trying to select line %d beyond the line count %d of view %s" %
                               (idx,
                                self._view.line_count,
                                bytes2str(self.name))
                               )
        list.append(self,idx)
        
        
    cdef index_t* __build_binary_list__(self):
        cdef index_t*        line_selection_p = NULL
        cdef int             i
        cdef size_t          l_selection = len(self)
                
        line_selection_p = <index_t*> malloc((l_selection + 1) * sizeof(index_t))   # +1 for the -1 flagging the end of the array
        for i in range(l_selection) :
                line_selection_p[i] = self[i]
        line_selection_p[l_selection] = -1      # flagging the end of the array

        return line_selection_p
        
        
    cpdef View materialize(self,
                           object view_name,
                           object comments={}):

        cdef bytes view_name_b = tobytes(view_name)
        cdef bytes comments_b
        cdef Obiview_p pointer
        cdef View view
                
        if not self._view.active() :
            raise OBIDeactivatedInstanceError()

        comments_b = str2bytes(json.dumps(bytes2str_object(comments)))
    
        pointer = obi_clone_view(self._view._dms.pointer(), 
                                 self._view.pointer(), 
                                 view_name_b,
                                 self.__build_binary_list__(), 
                                 comments_b)

        if pointer == NULL :
            raise RuntimeError("Error : Cannot clone view %s into view %s with new line selection" 
                               % (str(self._view.name),
                                  bytes2str(view_name_b))
                              )
        
        view = OBIWrapper.new_wrapper(type(self._view), pointer)
        view._dms = self._view._dms
        view._dms.register(view)
                
        return view


#############################################################


class RollbackException(Exception):
    def __init__(self, message, *views):
        super(RollbackException, self).__init__(message)
        for i in range(len(views)):
            view = <View>(views[i])
            if obi_rollback_view(<Obiview_p>(view.pointer())) < 0 :
                raise Exception("Error rollbacking view")
            if view.active() :
                view._dms.unregister(view)
                OBIWrapper.close(view)


class CantGuessTypeException(Exception):
    def __init__(self, object value) :
        raise Exception("Can't guess type to set value:", value)

#############################################################


cdef register_view_class(bytes view_type_name,
                         type  view_class):
    '''
    Each subclass of `dms.view` needs to be registered after its declaration
    '''
    global __VIEW_CLASS__

    assert issubclass(view_class, View)
    
    __VIEW_CLASS__[view_type_name] = view_class


cdef register_all_view_classes() :
    
    x = list(pkgutil.walk_packages(typed_view.__path__, prefix="obitools3.dms.view.typed_view."))
    all_modules = [importlib.import_module(a[1]) for a in x]
    for mod in all_modules :
        getattr(mod, 'register_class')()


register_all_view_classes()
