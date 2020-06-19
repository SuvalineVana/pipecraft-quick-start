#cython: language_level=3

from obitools3.apps.progress cimport ProgressBar  # @UnresolvedImport
from obitools3.dms.taxo.taxo cimport Taxonomy
from obitools3.dms.view.typed_view.view_NUC_SEQS cimport View_NUC_SEQS


cdef merge_taxonomy_classification(View_NUC_SEQS o_view, Taxonomy taxonomy)
cdef uniq_sequences(View_NUC_SEQS view, View_NUC_SEQS o_view, ProgressBar pb, list mergedKeys_list=*, Taxonomy taxonomy=*, bint mergeIds=*, list categories=*, int max_elts=*)
