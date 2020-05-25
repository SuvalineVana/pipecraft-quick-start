#cython: language_level=3

from obitools3.utils cimport bytes2str, str2bytes, tostr, tobytes

from obitools3.dms.view.view cimport View

from obitools3.dms.column.column cimport Column

from .capi.obitypes cimport index_t, OBI_QUAL

from .capi.obiview cimport NUC_SEQUENCE_COLUMN, \
                           ID_COLUMN, \
                           DEFINITION_COLUMN, \
                           QUALITY_COLUMN, \
                           COUNT_COLUMN

from .capi.obiutils cimport reverse_complement_sequence

from obitools3.format.fasta import FastaFormat
from obitools3.format.fastq import FastqFormat


from cpython cimport array
import array
from copy import deepcopy
import math


SEQUENCE_COLUMN = b"SEQ"

SPECIAL_COLUMNS = [NUC_SEQUENCE_COLUMN, SEQUENCE_COLUMN, ID_COLUMN, DEFINITION_COLUMN, QUALITY_COLUMN]

QUALITY_ASCII_BASE = 33


cdef class Seq(dict) :
    def __init__(self, object id, object seq, object definition=None, object tags=None) :
        cdef object k 
        cdef bytes k_b
        self.id = id
        self.seq = seq
        self.definition = definition
        self._index = -1
        if tags is not None :
            for k in tags:
                k_b = tobytes(k)
                if k_b not in SPECIAL_COLUMNS:
                    # TODO discuss convert value to bytes if str
                    if type(tags[k]) == str:
                        self[k_b] = str2bytes(tags[k])
                    else:
                        self[k_b] = tags[k]

    @staticmethod
    def new_from_stored(Seq_Stored seq_to_clone) :
        cdef Seq  new_seq
        new_seq = Seq(seq_to_clone.id, seq_to_clone.seq, definition=seq_to_clone.definition, quality=seq_to_clone.quality, tags=seq_to_clone)
        new_seq._index = seq_to_clone._index
        return new_seq

    def __contains__(self, object key):
        return dict.__contains__(self, tobytes(key))

    def __getitem__(self, object ref):
        if type(ref) == int:
            return self.get_symbol_at(ref)
        elif type(ref) == slice:
            return self.get_slice(ref)
        else:
            return super(Seq, self).__getitem__(tobytes(ref))

    def __setitem__(self, object ref, object item):
            super(Seq, self).__setitem__(tobytes(ref), item)

    def __str__(self):
        return self.get_str()

    cpdef str get_str(self):
        return tostr(self.seq)
    
    def __len__(self):
        return len(self.seq)

    cpdef object clone(self):
        cdef object seq_class
        seq_class = type(self)
        seq = seq_class(self.id, self.seq, definition=self.definition, quality=self.quality, tags=self)
        return seq

    cpdef object get_slice(self, slice slice_to_get):
        cdef object new_seq
        cdef list   sliced_quality
        cdef type   seq_class
        seq_class = type(self)
        if QUALITY_COLUMN in self:
            sliced_quality = self.quality[slice_to_get]
        else:
            sliced_quality = None
        new_seq = seq_class(self.id+b"_SUB", self.seq[slice_to_get], definition=self.definition, quality=sliced_quality, tags=self) # TODO discuss suffix
        return new_seq

    cpdef get_symbol_at(self, int pos):
        return self.seq[pos:pos+1]

    # sequence id property getter and setter
    @property
    def id(self):  # @ReservedAssignment
        return self[ID_COLUMN]
    
    @id.setter
    def id(self, object new_id):  # @ReservedAssignment @DuplicatedSignature
        self[ID_COLUMN] = tobytes(new_id)
        
    # sequence property getter and setter
    @property
    def seq(self):
        return self[SEQUENCE_COLUMN]
    
    @seq.setter
    def seq(self, object new_seq):  # @DuplicatedSignature
        self[SEQUENCE_COLUMN] = tobytes(new_seq)
        
    # sequence definition property getter and setter
    @property
    def definition(self):
        return self[DEFINITION_COLUMN]
    
    @definition.setter
    def definition(self, object new_definition):  # @DuplicatedSignature
        if new_definition is not None:
            new_definition = tobytes(new_definition)
        self[DEFINITION_COLUMN] = new_definition

    # sequence index (for reference in a view eventually) property getter and setter
    @property
    def index(self):  # @ReservedAssignment
        return self._index

    @index.setter
    def index(self, int idx):  # @DuplicatedSignature
        self._index = idx

        
cdef class Nuc_Seq(Seq) :

    def __init__(self, object id, object seq, object definition=None, object quality=None, int offset=QUALITY_ASCII_BASE, object tags=None) :
        cdef object k 
        cdef bytes  k_b
        cdef int    q
        cdef list   q_proba_list
                
        self.id = id
        self.seq = seq
        self.definition = definition
        if quality is not None:
            self.set_quality(quality, offset=offset)
        
        self._is_revcomp = False
        
        if tags is not None:
            for k in tags:
                k_b = tobytes(k)
                if k_b not in SPECIAL_COLUMNS:
                    # TODO discuss convert value to bytes if str
                    if type(tags[k]) == str:
                        self[k_b] = str2bytes(tags[k])
                    else:
                        self[k_b] = tags[k]

    @staticmethod
    def new_from_stored(Nuc_Seq_Stored seq_to_clone) :
        cdef Nuc_Seq new_seq
        new_seq = Nuc_Seq(seq_to_clone.id, seq_to_clone.seq, definition=seq_to_clone.definition, quality=seq_to_clone.quality, tags=seq_to_clone)
        new_seq._index = seq_to_clone.index
        return new_seq

    # is_revcomp property getter and setter (boolean indicating whether the sequence was created by reverse complementing another sequence)
    @property
    def is_revcomp(self):
        return self._is_revcomp

    @is_revcomp.setter
    def is_revcomp(self, bint is_revcomp):  # @DuplicatedSignature
        self._is_revcomp = is_revcomp

    # nuc sequence property getter and setter
    @property
    def seq(self):
        return self[NUC_SEQUENCE_COLUMN]
    
    @seq.setter
    def seq(self, object new_seq):  # @DuplicatedSignature
        self[NUC_SEQUENCE_COLUMN] = tobytes(new_seq)
        
    # sequence quality property getter and setter
    @property
    def quality(self):
        if QUALITY_COLUMN in self:
            return self[QUALITY_COLUMN]
        else:
            return None
    
    cpdef set_quality(self, object new_quality, int offset=QUALITY_ASCII_BASE):
        cdef list quality_int
        if type(new_quality) == list:
            quality_int = new_quality
        elif type(new_quality) == str or type(new_quality) == bytes:
            quality_int = []
            for pos in range(len(new_quality)):
                quality_int.append(ord(new_quality[pos:pos+1])-offset)
        else:
            raise Exception("Sequence quality in unrecognized format:", type(new_quality))
        self[QUALITY_COLUMN] = quality_int

    # sequence quality array property getter and setter
    @property
    def quality_array(self):
        if self._quality_array is None:
            if QUALITY_COLUMN in self:
                self._quality_array = self.build_quality_array(self[QUALITY_COLUMN])
        return self._quality_array

    cpdef object build_quality_array(self, list quality):
        cdef int    q
        cdef list   q_proba_list
        cdef object qual_array
        q_proba_list = [(10.**(-q/10.)) for q in quality]
        return array.array('d', q_proba_list)

    # reverse complement property getter
    @property
    def reverse_complement(self):
        cdef bytes rev_comp
        cdef object seq_class
        if self._reverse_complement is None:
            rev_comp = self.build_reverse_complement()
            if QUALITY_COLUMN in self:
                reversed_quality = self.quality[::-1]
            else:
                reversed_quality = None
            seq = Nuc_Seq(self.id+b"_CMP", rev_comp, definition=self.definition, quality=reversed_quality, tags=self)
            seq.is_revcomp = True
            self._reverse_complement = seq
        return self._reverse_complement
    
    cpdef bytes build_reverse_complement(self) :
        cdef bytes rev_comp
        rev_comp = deepcopy(self[NUC_SEQUENCE_COLUMN]).lower()
        return <bytes>reverse_complement_sequence(rev_comp)        


cdef class Seq_Stored(Line) :

    def __getitem__(self, object ref):
        if type(ref) == int:
            return self.get_symbol_at(ref)
        elif type(ref) == slice:
            return self.get_slice(ref)
        else:
            return super(Seq_Stored, self).__getitem__(ref)

    cpdef object get_slice(self, slice slice_to_get):
        cdef object new_seq
        cdef list   sliced_quality
        cdef type   seq_class
        seq_class = type(self)
        if QUALITY_COLUMN in self:
            sliced_quality = self.quality[slice_to_get]
        else:
            sliced_quality = None
        new_seq = seq_class(self.id+b"_SUB", self.seq[slice_to_get], definition=self.definition, quality=sliced_quality, tags=self)  # TODO discuss suffix
        return new_seq

    cpdef get_symbol_at(self, int pos):
        return self.seq[pos:pos+1]

    # sequence id property getter and setter
    @property
    def id(self):               # @ReservedAssignment @DuplicatedSignature
        return self._view.get_column(ID_COLUMN).get_line(self.index)
    
    @id.setter
    def id(self, object new_id):   # @ReservedAssignment @DuplicatedSignature
        self._view.get_column(ID_COLUMN).set_line(self._index, tobytes(new_id))
        
    # sequence definition property getter and setter
    @property
    def definition(self):
        return self._view.get_column(DEFINITION_COLUMN).get_line(self.index)
    
    @definition.setter
    def definition(self, object new_def): # @DuplicatedSignature
        self._view.get_column(DEFINITION_COLUMN).set_line(self._index, tobytes(new_def))
    

cdef class Nuc_Seq_Stored(Seq_Stored) :
    
#    def __init__(self, View view, index_t line_nb) :
#        self = Seq_Stored.__init__(self, view, line_nb)
        #self._reverse_complement = None    # TODO unnecessary?
    
#     def __setitem__(self, object column_name, object value):
#         try:
#             super(Seq, self).__setitem__(column_name, value)
#         except CantGuessTypeException:
#             column_name_b = tobytes(column_name)
#             if column_name_b in SPECIAL_COLUMNS:
#                 self[column_name_b] = tags[column_name]

    cpdef set(self, object id, object seq, object definition=None, object quality=None, int offset=QUALITY_ASCII_BASE, object tags=None):
        cdef object k 
        cdef bytes  k_b
        cdef int    q
        cdef list   q_proba_list
        
        self[ID_COLUMN] = tobytes(id)
        self[NUC_SEQUENCE_COLUMN] = tobytes(seq)
        if definition is not None:
            self.definition = tobytes(definition)
        if quality is not None:
            if type(quality) == list:
                self.set_quality_int(quality)
            elif type(quality) == str or type(quality) == bytes:
                self.set_quality_char(quality, offset=offset)
            else:
                raise Exception("Sequence quality in unrecognized format")
            
        if tags is not None:
            for k in tags:
                k_b = tobytes(k)
                if k_b not in SPECIAL_COLUMNS:
                    if type(tags[k]) == str:
                        self[k_b] = str2bytes(tags[k])
                    else:
                        self[k_b] = tags[k]

    # seq property getter and setter
    @property
    def seq(self):
        if not self._view.read_only :
            return self._view.get_column(NUC_SEQUENCE_COLUMN).get_line(self.index)
        else:
            if self._seq is None:
                self._seq = self._view.get_column(NUC_SEQUENCE_COLUMN).get_line(self.index)
            return self._seq
    
    @seq.setter
    def seq(self, object new_seq): # @DuplicatedSignature
        self._view.get_column(NUC_SEQUENCE_COLUMN).set_line(self.index, tobytes(new_seq))

    cpdef set_quality_int(self, list new_qual):
        if QUALITY_COLUMN not in self:
            Column.new_column(self._view, QUALITY_COLUMN, OBI_QUAL)
        self._view.get_column(QUALITY_COLUMN).set_line(self.index, new_qual)

    cpdef set_quality_char(self, object new_qual, int offset=QUALITY_ASCII_BASE):
        if QUALITY_COLUMN not in self:
            Column.new_column(self._view, QUALITY_COLUMN, OBI_QUAL)
        self._view.get_column(QUALITY_COLUMN).set_str_line(self.index, tobytes(new_qual), offset=offset)

    # quality property getter and setter
    @property
    def quality(self):
        if QUALITY_COLUMN in self:
            return self._view.get_column(QUALITY_COLUMN).get_line(self.index)
        else:
            return None
    
    @quality.setter
    def quality(self, object new_qual): # @DuplicatedSignature
        if (new_qual is None) or (type(new_qual) == list) :     # TODO check that quality column exists
            self.set_quality_int(new_qual)
        # WARNING: default offset used
        elif (type(new_qual) == str) or (type(new_qual) == bytes)  :  # Quality is in str form
            self.set_quality_char(new_qual)
        else :
            raise Exception("Sequence quality in unrecognized format")

    # quality character string property getter
    # WARNING: default offset used
    @property
    def quality_bytes(self):
        if QUALITY_COLUMN in self:
            return self._view.get_column(QUALITY_COLUMN).get_bytes_line(self._index)
        else:
            return None

    # sequence quality array property getter and setter
    @property
    def quality_array(self):
        if self._quality_array is None:
            if QUALITY_COLUMN in self:
                self._quality_array = self.build_quality_array(self._view.get_column(QUALITY_COLUMN).get_line(self.index))
        return self._quality_array

    cpdef object build_quality_array(self, list quality):
        cdef int    q
        cdef list   q_proba_list
        cdef object qual_array
        q_proba_list = [(10.**(-q/10.)) for q in quality]
        return array.array('d', q_proba_list)

    # reverse complement property getter
    @property
    def reverse_complement(self):
        cdef bytes rev_comp
        cdef list  reversed_quality
        if self._reverse_complement is None:
            rev_comp = self.build_reverse_complement()
            if QUALITY_COLUMN in self:
                reversed_quality = self.quality[::-1]
            else:
                reversed_quality = None
            seq = Nuc_Seq(self.id+b"_CMP", rev_comp, definition=self.definition, quality=reversed_quality, tags=self)
            seq.is_revcomp = True
            self._reverse_complement = seq
        return self._reverse_complement
    
    cpdef bytes build_reverse_complement(self) :
        cdef bytes rev_comp
        rev_comp = deepcopy(self[NUC_SEQUENCE_COLUMN]).lower()
        return <bytes>reverse_complement_sequence(rev_comp)
    
    def __str__(self):
        return self.get_str()

    cpdef str get_str(self):
        return tostr(self._view.get_column(NUC_SEQUENCE_COLUMN).get_line(self.index))

    def __len__(self):
        return len(self._view.get_column(NUC_SEQUENCE_COLUMN).get_line(self.index))

    def __repr__(self):
        if self.quality is None:
            formatter = FastaFormat()
        else:
            formatter = FastqFormat()
        return bytes2str(formatter(self))

