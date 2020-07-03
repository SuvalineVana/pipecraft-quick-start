#cython: language_level=3
 

__OBIDMS_COLUMN_CLASS__ = {}


from ..capi.obitypes cimport name_data_type, \
                             obitype_t, \
                             obiversion_t, \
                             OBI_QUAL

from ..capi.obidms cimport obi_import_column

from ..capi.obidmscolumn cimport OBIDMS_column_header_p, \
                                 obi_close_column, \
                                 obi_get_elements_names, \
                                 obi_column_write_comments
                                     
from ..capi.obiutils cimport obi_format_date
 
from ..capi.obiview cimport obi_view_add_column, \
                            obi_view_get_pointer_on_column_in_view, \
                            Obiview_p, \
                            NUC_SEQUENCE_COLUMN, \
                            QUALITY_COLUMN, \
                            REVERSE_SEQUENCE_COLUMN, \
                            REVERSE_QUALITY_COLUMN


from ..object cimport OBIDeactivatedInstanceError

from obitools3.utils cimport tobytes, \
                             bytes2str, \
                             str2bytes, \
                             str2bytes_object, \
                             bytes2str_object, \
                             clean_empty_values_from_object
 
from obitools3.dms.column import typed_column
 
from libc.stdlib  cimport free
 
import importlib
import inspect
import pkgutil
import json


cdef class Column(OBIWrapper) :
    '''
    The obitools3.dms.column.Column class wraps a C instance of a column in the context of a View 
    '''

    cdef inline OBIDMS_column_p pointer(self) :
        return <OBIDMS_column_p>(<OBIDMS_column_p*>(self._pointer))[0]


    @staticmethod
    cdef type get_column_class(obitype_t obitype, bint multi_elts, bint tuples):
        '''
        Internal function returning the python class representing 
        a column for a given obitype.
        '''
        return __OBIDMS_COLUMN_CLASS__[(obitype, multi_elts, tuples)][0]


    @staticmethod
    cdef type get_python_type(obitype_t obitype, bint multi_elts):  # TODO
        '''
        Internal function returning the python type representing 
        an instance for a given obitype.
        '''
        return __OBIDMS_COLUMN_CLASS__[(obitype, multi_elts)][1]


    @staticmethod
    def import_column(object dms_1, object dms_2, object column_name, obiversion_t version_number):
        cdef obiversion_t new_version
        new_version = obi_import_column(tobytes(dms_1), tobytes(dms_2), tobytes(column_name), version_number)
        if new_version < 0 :
            raise Exception("Error importing a column")
        return new_version


    @staticmethod
    def new_column(View      view,
                   object    column_name,
                   obitype_t data_type,
                   index_t   nb_elements_per_line=1,
                   list      elements_names=None,
                   bint      tuples=False,
                   bint      to_eval=False,
                   object    associated_column_name=b"",
                   int       associated_column_version=-1,
                   object    comments={},
                   object    alias=b""):
        # TODO indexer_name?
        
        cdef bytes  column_name_b = tobytes(column_name)
        cdef bytes  alias_b = tobytes(alias)
        cdef bytes  comments_b = str2bytes(json.dumps(bytes2str_object(comments)))
        cdef bytes  associated_column_name_b = tobytes(associated_column_name)
        cdef list   elements_names_s
        cdef bytes  elements_names_b
        cdef char*  elements_names_p
        cdef object elt_name
        cdef str    elt_name_s
        
        if not view.active() :
            raise OBIDeactivatedInstanceError()
 
        if alias_b == b"" :
            alias_b = column_name_b
        
        if elements_names is not None:
            elements_names_s = []
            for elt_name in elements_names :
                if type(elt_name) != bytes and type(elt_name) != str :
                    elements_names_s.append(str(elt_name))
                else :
                    elements_names_s.append(elt_name)
            elements_names_b = b';'.join([tobytes(x) for x in elements_names_s])
            elements_names_p = elements_names_b
        else:
            elements_names_p = NULL
        
        if data_type == OBI_QUAL:
            if associated_column_name_b == b"":
                if column_name == QUALITY_COLUMN:
                    if NUC_SEQUENCE_COLUMN not in view:
                         raise RuntimeError("Cannot create column %s in view %s: trying to create quality column but no NUC_SEQ column to associate it with in the view" % (bytes2str(column_name_b),
                                                                               bytes2str(view.name)))
                    associated_column_name_b = NUC_SEQUENCE_COLUMN
                    associated_column_version = view[NUC_SEQUENCE_COLUMN].version
                elif column_name == REVERSE_QUALITY_COLUMN:
                    if REVERSE_SEQUENCE_COLUMN not in view:
                         raise RuntimeError("Cannot create column %s in view %s: trying to create reverse quality column but no REVERSE_SEQUENCE column to associate it with in the view" % (bytes2str(column_name_b),
                                                                               bytes2str(view.name)))
                    associated_column_name_b = REVERSE_SEQUENCE_COLUMN
                    associated_column_version = view[REVERSE_SEQUENCE_COLUMN].version
        
        if (obi_view_add_column(view                      = view.pointer(),
                                column_name               = column_name_b,
                                version_number            = -1,
                                alias                     = alias_b,
                                data_type                 = <obitype_t>data_type,
                                nb_lines                  = len(view),
                                nb_elements_per_line      = nb_elements_per_line,
                                elements_names            = elements_names_p,
                                elt_names_formatted       = False,
                                tuples                    = tuples,
                                to_eval                   = to_eval,
                                indexer_name              = NULL,
                                associated_column_name    = associated_column_name_b,
                                associated_column_version = associated_column_version,
                                comments                  = comments_b,
                                create                    = True)<0):
            raise RuntimeError("Cannot create column %s in view %s" % (bytes2str(column_name_b),
                                                                       bytes2str(view.name)))

        return Column.open(view, alias_b)
 
 
    @staticmethod
    def open(View view,
             object column_name):
        cdef bytes            column_name_b = tobytes(column_name)
        cdef OBIDMS_column_p* column_pp
        cdef OBIDMS_column_p  column_p
        cdef Column           column
        cdef obitype_t        column_type
        cdef type             column_class
        
        if not view.active() :
            raise OBIDeactivatedInstanceError()
        
        column_pp = obi_view_get_pointer_on_column_in_view(view.pointer(), 
                                                           column_name_b)
        
        if column_pp == NULL:
            raise KeyError("Cannot access to column %s in view %s" % (
                    bytes2str(column_name_b),
                    bytes2str(view.name)
                ))
        
        column_p = column_pp[0]
        column_type = column_p.header.returned_data_type
        column_class = Column.get_column_class(column_type, (column_p.header.nb_elements_per_line > 1), column_p.header.tuples)
        column = OBIWrapper.new_wrapper(column_class, column_pp)
        
        column._view = view
        column._alias = column_name_b
        column._elements_names = column.read_elements_names()
        view.register(column)

        return column

    
    @OBIWrapper.checkIsActive
    def add_to_view(self,
                    View   view,
                    object column_name=None) :
        
        cdef bytes alias   
        cdef OBIDMS_column_p column_p = self.pointer()
        
        if not view.active() :
            raise OBIDeactivatedInstanceError()
        
        if (column_name is None):
            alias = self._alias
        else:
            alias = tobytes(column_name)
                       
        if (obi_view_add_column(view                      = view.pointer(),
                                column_name               = column_p.header.name,
                                version_number            = column_p.header.version,
                                alias                     = alias,
                                data_type                 = <obitype_t>0,
                                nb_lines                  = -1,
                                nb_elements_per_line      = -1,
                                elements_names            = NULL,
                                elt_names_formatted       = False,
                                tuples                    = False,
                                to_eval                   = False,
                                indexer_name              = NULL,
                                associated_column_name    = NULL,
                                associated_column_version = -1,
                                comments                  = NULL,
                                create                    = False) < 0):
            raise RuntimeError("Cannot insert column %s (%s@%d) into view %s" %
                               ( bytes2str(alias),
                                 bytes2str(column_p.header.name),
                                 column_p.header.version,
                                 bytes2str(view.name)
                               ))
            
        view.register(self)
        
    
    @OBIWrapper.checkIsActive
    def __len__(self):
        '''
        implements the len() function for the Column class
         
            @rtype: `int`
        '''
        return self.lines_used
     
    
    @OBIWrapper.checkIsActive 
    def __sizeof__(self):
        '''
        returns the size of the C object wrapped by the Column instance
        '''
        cdef OBIDMS_column_header_p header = self.pointer().header
        return header.header_size + header.data_size
     
    
    @OBIWrapper.checkIsActive 
    def __iter__(self):
        cdef index_t line_nb
        for line_nb in range(self.lines_used):
            yield self.get_line(line_nb)

    
    # TODO check time efficiency with and without
    @OBIWrapper.checkIsActive
    def __setitem__(self, index_t line_nb, object value):
        self.set_line(line_nb, value)


    @OBIWrapper.checkIsActive
    def __getitem__(self, index_t line_nb):
        return self.get_line(line_nb)
  
    
    @OBIWrapper.checkIsActive             
    def __str__(self) :
        cdef str    to_print
        cdef object line
        to_print = ''
        for line in self :
            to_print = to_print + str(line) + "\n"
        return to_print
 
    
    @OBIWrapper.checkIsActive
    def __repr__(self) :
        cdef bytes s
        s = self._alias + b", data type: " + self.data_type
        return bytes2str(s)

         
    def close(self):  # TODO discuss, can't be called bc then bug when closing view that tries to close it in C
    
        cdef OBIDMS_column_p pointer

        if self.active() :
            pointer = self.pointer()
            self._view.unregister(self)
            OBIWrapper.close(self)      
            #if obi_close_column(pointer) < 0 :
            #    raise Exception("Problem closing column %s" % bytes2str(self.name))
 
 
    cdef read_elements_names(self):
        cdef char* elts_names_b
        cdef list  elts_names_list
        if not self.active() :
            raise OBIDeactivatedInstanceError()
        elts_names_b = obi_get_elements_names(self.pointer())
        if elts_names_b == NULL:
            raise Exception("Error reading the elements names of a column")
        elts_names_list = elts_names_b.split(b';')
        free(elts_names_b)
        return elts_names_list
    
    
    # Column alias property getter and setter
    @property
    def name(self):
        if not self.active() :
            raise OBIDeactivatedInstanceError()
        return self._alias
    @name.setter
    def name(self, object new_alias):  # @DuplicatedSignature
        if not self.active() :
            raise OBIDeactivatedInstanceError()
        self._view.rename_column(self._alias, new_alias)

    # elements_names property getter
    @property
    def elements_names(self):
        return self._elements_names
 
    # nb_elements_per_line property getter
    @property
    def nb_elements_per_line(self):
        if not self.active() :
            raise OBIDeactivatedInstanceError()
        return self.pointer().header.nb_elements_per_line
 
    # data_type property getter
    @property
    def data_type(self):
        if not self.active() :
            raise OBIDeactivatedInstanceError()
        return name_data_type(self.data_type_int)
 
    # data_type integer code property getter
    @property
    def data_type_int(self):
        if not self.active() :
            raise OBIDeactivatedInstanceError()
        return self.pointer().header.returned_data_type

    # original_name property getter
    @property
    def original_name(self):
        if not self.active() :
            raise OBIDeactivatedInstanceError()
        return self.pointer().header.name
 
    # version property getter
    @property
    def version(self):
        if not self.active() :
            raise OBIDeactivatedInstanceError()
        return self.pointer().header.version
 
    # lines_used property getter
    @property
    def lines_used(self):
        if not self.active() :
            raise OBIDeactivatedInstanceError()
        return self.pointer().header.lines_used
 
    # tuples property getter
    @property
    def tuples(self):
        if not self.active() :
            raise OBIDeactivatedInstanceError()
        return self.pointer().header.tuples

    # to_eval property getter
    @property
    def to_eval(self):
        if not self.active() :
            raise OBIDeactivatedInstanceError()
        return self.pointer().header.to_eval

    # creation_date property getter
    @property
    def creation_date(self):
        if not self.active() :
            raise OBIDeactivatedInstanceError()
        return obi_format_date(self.pointer().header.creation_date)

    # comments property getter
    @property
    def comments(self):
        return Column_comments(self)
    @comments.setter
    def comments(self, object value):
        Column_comments(self, value)

          
cdef class Column_comments(dict):   # Not thread safe
    def __init__(self, Column column, value=None) :
        if not column.active() :
            raise OBIDeactivatedInstanceError()
        self._column = column
        if value is not None:
            self.update(value)     # TODO test and discuss not overwriting (could use replace bool)
        self._update_from_file()

    def _update_from_file(self):
        cdef bytes comments_json
        cdef str comments_json_str
        cdef OBIDMS_column_p column_p
        cdef Column column
        if not self._column.active() :
            raise OBIDeactivatedInstanceError()
        column = self._column
        column_p = <OBIDMS_column_p>(column.pointer())
        comments_json = <bytes> column_p.header.comments
        comments_json_str = bytes2str(comments_json)
        comments_dict = json.loads(comments_json_str)
        str2bytes_object(comments_dict)
        super(Column_comments, self).update(comments_dict)
        
    def __getitem__(self, object key):
        if not self._column.active() :
            raise OBIDeactivatedInstanceError()
        if type(key) == str:
            key = str2bytes(key)
        self._update_from_file()
        return super(Column_comments, self).__getitem__(key)

    def __setitem__(self, object key, object value):
        cdef OBIDMS_column_p column_p
        cdef Column column

        if not self._column.active() :
            raise OBIDeactivatedInstanceError()

        column = self._column
        column_p = <OBIDMS_column_p>(column.pointer())
        
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
        super(Column_comments, self).__setitem__(key, value_bytes)
        
        # Convert to str because json library doens't like bytes
        dict_str = {key:item for key,item in self.items()}
        dict_str = bytes2str_object(dict_str)
        
        # Convert to json string
        comments_json = json.dumps(dict_str)        

        # Write new comments
        if obi_column_write_comments(column_p, tobytes(comments_json)) < 0:
            raise Exception("Could not write column comments: %s", comments_json)

    def update(self, value):
        for k,v in value.items():
            self[k] = v

    def __contains__(self, key):
        return super(Column_comments, self).__contains__(tobytes(key))

    def __str__(self):
        return bytes2str(self._column.pointer().header.comments)


######################################################################################################
 

cdef class Column_multi_elts(Column) :
    
    @OBIWrapper.checkIsActive
    def __getitem__(self, index_t line_nb):
        return Column_line(self, line_nb)
    
    cpdef set_line(self, index_t line_nb, object values):
        cdef object value_ref
        cdef object values_iter
        if not self.active() :
            raise OBIDeactivatedInstanceError()
        if values is None or len(values) == 0 or (isinstance(values, Column_line) and values.is_NA()):
            for element_name in self._elements_names :
                self.set_item(line_nb, element_name, None)
        else :
            values_iter = xrange(len(values)) if isinstance(values, list) else values
            for value_ref in values_iter :
                self.set_item(line_nb, value_ref, values[value_ref])


######################################################################################################


cdef class Column_line :
 
    def __init__(self, Column column, index_t line_nb) :
        self._index = line_nb
        self._column = column
         

    def __getitem__(self, object elt_id) :
        return self._column.get_item(self._index, elt_id)


    def __setitem__(self, object elt_id, object value):
        self._column.set_item(self._index, elt_id, value)


    def get(self, object elt_id, object default=None):      # TODO returns default if None???
        if elt_id in self:
            return self._column.get_item(self._index, elt_id)
        else:
            return default
    
    
    def __len__(self):
        return self._column.nb_elements_per_line
         
        
    def __contains__(self, object elt_id):
        if type(elt_id) == int:
            return elt_id < self._column.nb_elements_per_line
        else:
            return (tobytes(elt_id) in self._column._elements_names)
 
 
    def __repr__(self) :
        return str(self._column.get_line(self._index))
 
 
    def is_NA(self):
        return self._column.get_line(self._index) is None
    
    
    def __iter__(self) :
        cdef list  elements_names
        cdef bytes element_name
        for element_name in self._column.get_line(self._index) :
            yield element_name
    
    
    cpdef list keys(self):    
    # TODO just returning all element names of the column would be faster but 
    # potentially lots of keys associated with None values on that given line.
    # get_line() methods don't return None values
        return [element_name for element_name in self._column.get_line(self._index)]
    

    cpdef list items(self):
        return [(k, self[k]) for k in self.keys()]
    
    
    cpdef dict dict(self):
        cdef dict d
        d = {}
        for k,v in self.items():
            d[k] = v
        return d
    
    
    def __str__(self):
        cdef dict d
        cdef str  s
        if self.is_NA():
            return ""
        d = {}
        for k,v in self.items():
            if type(v) == bytes:
                value = bytes2str(v)
            else:
                value = v
            d[bytes2str(k)] = value
        s = str(d)
        return s


    cpdef bytes bytes(self):
        cdef str   s
        cdef bytes b
        s = self.__str__()
        b = str2bytes(s)
        return b
        
        
    # column property getter
    @property
    def column(self):
        return self._column

    # index property getter
    @property
    def index(self):
        return self._index
        
    
    cpdef update(self, object data):
        if isinstance(data, dict):
            data=data.items()
        for key,value in data:
            if key in self:
                self[key]=value

 
######################################################################################################


cdef register_column_class(obitype_t obitype,
                           bint multi_elts,
                           bint tuples,
                           type obiclass,
                           type python_type):
    '''
    Each sub class of `OBIDMS_column` needs to be registered after its declaration
    to declare its relationship with an `OBIType_t`
    '''
    global __OBIDMS_COLUMN_CLASS__
    
    assert issubclass(obiclass, Column)
    
    __OBIDMS_COLUMN_CLASS__[(obitype, multi_elts, tuples)] = (obiclass, python_type)


cdef register_all_column_classes() :
    
    x = list(pkgutil.walk_packages(typed_column.__path__, prefix="obitools3.dms.column.typed_column."))
    all_modules = [importlib.import_module(a[1]) for a in x]
    for mod in all_modules :
        getattr(mod, 'register_class')()


register_all_column_classes()



    