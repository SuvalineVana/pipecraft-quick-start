#cython: language_level=3

from obitools3.dms.capi.obiview cimport obi_new_view_nuc_seqs, \
                             obi_new_view_nuc_seqs_cloned_from_name, \
                             VIEW_TYPE_NUC_SEQS

from ..view cimport register_view_class

from obitools3.dms.obiseq cimport Nuc_Seq, Nuc_Seq_Stored

from obitools3.dms.dms cimport DMS

from obitools3.dms.capi.obitypes cimport index_t

from obitools3.utils cimport tobytes, bytes2str, str2bytes

from obitools3.dms.capi.obidms cimport OBIDMS_p

from obitools3.dms.object cimport OBIWrapper                          

import json


cdef class View_NUC_SEQS(View):
    
    @staticmethod
    def new(DMS dms, 
            object view_name, 
            dict comments={},
            bint quality=False):

        cdef bytes view_name_b = tobytes(view_name)
        cdef bytes comments_b
        cdef str message
        cdef void* pointer

        cdef View_NUC_SEQS view

        comments_b = str2bytes(json.dumps(comments))

        pointer = <void*>obi_new_view_nuc_seqs(<OBIDMS_p>dms._pointer, 
                                               view_name_b, 
                                               NULL, 
                                               NULL, 
                                               comments_b,
                                               quality,
                                               True)
        
        if pointer == NULL :
            message = "Error : Cannot create view %s" % bytes2str(view_name_b)
            raise RuntimeError(message)
        
        view = OBIWrapper.new_wrapper(View_NUC_SEQS, pointer)
        view._dms = dms
        dms.register(view)

        return view


    # TODO test time gain without
    @OBIWrapper.checkIsActive
    def __getitem__(self, object item) :
        if type(item) == int :
            return Nuc_Seq_Stored(self, item)
        else :  # TODO assume str or bytes for optimization?
            return self.get_column(item)    # TODO hyper lent dans la pratique


    @OBIWrapper.checkIsActive
    def __iter__(self):
        # Iteration on each line of all columns
        
        # Declarations
        cdef index_t line_nb
        
        # Yield each line    
        for line_nb in range(self.line_count) :
            yield Nuc_Seq_Stored(self, line_nb)
    

# TODO? test if efficiency gain
#    def __setitem__(self, index_t line_idx, Nuc_Seq sequence_obj) :
#        for key in sequence_obj :
#            self[line_idx][key] = sequence_obj[key]


def register_class() :
    register_view_class(VIEW_TYPE_NUC_SEQS, View_NUC_SEQS)

