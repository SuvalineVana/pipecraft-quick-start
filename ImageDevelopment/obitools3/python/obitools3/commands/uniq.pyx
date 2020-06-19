#cython: language_level=3

from obitools3.apps.progress cimport ProgressBar  # @UnresolvedImport
from obitools3.dms import DMS
from obitools3.dms.view.view cimport View
from obitools3.dms.obiseq cimport Nuc_Seq_Stored
from obitools3.dms.view import RollbackException
from obitools3.dms.view.typed_view.view_NUC_SEQS cimport View_NUC_SEQS
from obitools3.dms.column.column cimport Column, Column_line
from obitools3.dms.capi.obiview cimport QUALITY_COLUMN, COUNT_COLUMN, NUC_SEQUENCE_COLUMN, ID_COLUMN, TAXID_COLUMN, \
                                        TAXID_DIST_COLUMN, MERGED_TAXID_COLUMN, MERGED_COLUMN, MERGED_PREFIX, \
                                        REVERSE_QUALITY_COLUMN
from obitools3.dms.capi.obitypes cimport OBI_INT, OBI_STR, index_t
from obitools3.apps.optiongroups import addMinimalInputOption, \
                                        addMinimalOutputOption, \
                                        addTaxonomyOption, \
                                        addEltLimitOption
from obitools3.uri.decode import open_uri
from obitools3.apps.config import logger
from obitools3.utils cimport tobytes, tostr

import sys
from cpython.exc cimport PyErr_CheckSignals


__title__="Group sequence records together"

 
def addOptions(parser):
 
    addMinimalInputOption(parser)
    addTaxonomyOption(parser)
    addMinimalOutputOption(parser)
    addEltLimitOption(parser)
 
    group = parser.add_argument_group('obi uniq specific options')
 
    group.add_argument('--merge', '-m',
                       action="append", dest="uniq:merge",
                       metavar="<TAG NAME>",
                       default=[],
                       type=str,
                       help="Attributes to merge.") # note: must be a 1 elt/line column, but columns containing already merged information (name MERGED_*) are automatically remerged

    group.add_argument('--merge-ids', '-e',
                       action="store_true", dest="uniq:mergeids",
                       default=False,
                       help="Add the merged key with all ids of merged sequences.")
   
    group.add_argument('--category-attribute', '-c',
                        action="append", dest="uniq:categories",
                        metavar="<Attribute Name>",
                        default=[],
                        help="Add one attribute to the list of attributes "
                             "used to group sequences before dereplication "
                             "(option can be used several times).")


cdef merge_taxonomy_classification(View_NUC_SEQS o_view, Taxonomy taxonomy) :
    
    cdef int             taxid
    cdef Nuc_Seq_Stored  seq
    cdef list            m_taxids
    cdef bytes           k
    cdef object          tsp
    cdef object          tgn
    cdef object          tfa
    cdef object          sp_sn
    cdef object          gn_sn
    cdef object          fa_sn

    # Create columns
    if b"species" in o_view and o_view[b"species"].data_type_int != OBI_INT :
        o_view.delete_column(b"species")
    if b"species" not in o_view:
        Column.new_column(o_view, 
                          b"species", 
                          OBI_INT
                         )

    if b"genus" in o_view and o_view[b"genus"].data_type_int != OBI_INT :
        o_view.delete_column(b"genus")
    if b"genus" not in o_view:
        Column.new_column(o_view, 
                          b"genus", 
                          OBI_INT
                         )

    if b"family" in o_view and o_view[b"family"].data_type_int != OBI_INT :
        o_view.delete_column(b"family")
    if b"family" not in o_view:
        Column.new_column(o_view, 
                          b"family", 
                          OBI_INT
                         )

    if b"species_name" in o_view and o_view[b"species_name"].data_type_int != OBI_STR :
        o_view.delete_column(b"species_name")
    if b"species_name" not in o_view:
        Column.new_column(o_view, 
                          b"species_name", 
                          OBI_STR
                         )

    if b"genus_name" in o_view and o_view[b"genus_name"].data_type_int != OBI_STR :
        o_view.delete_column(b"genus_name")
    if b"genus_name" not in o_view:
        Column.new_column(o_view, 
                          b"genus_name", 
                          OBI_STR
                         )

    if b"family_name" in o_view and o_view[b"family_name"].data_type_int != OBI_STR :
        o_view.delete_column(b"family_name")
    if b"family_name" not in o_view:
        Column.new_column(o_view, 
                          b"family_name", 
                          OBI_STR
                         )

    if b"rank" in o_view and o_view[b"rank"].data_type_int != OBI_STR :
        o_view.delete_column(b"rank")
    if b"rank" not in o_view:
        Column.new_column(o_view, 
                          b"rank", 
                          OBI_STR
                         )

    if b"scientific_name" in o_view and o_view[b"scientific_name"].data_type_int != OBI_STR :
        o_view.delete_column(b"scientific_name")
    if b"scientific_name" not in o_view:
        Column.new_column(o_view, 
                          b"scientific_name", 
                          OBI_STR
                         )
        
    for seq in o_view:     
        PyErr_CheckSignals()   
        if MERGED_TAXID_COLUMN in seq :
            m_taxids = []            
            m_taxids_dict = seq[MERGED_TAXID_COLUMN]
            for k in m_taxids_dict.keys() :
                if m_taxids_dict[k] is not None:
                    m_taxids.append(int(k))
            taxid = taxonomy.last_common_taxon(*m_taxids)
            seq[TAXID_COLUMN] = taxid
            tsp = taxonomy.get_species(taxid)
            tgn = taxonomy.get_genus(taxid)
            tfa = taxonomy.get_family(taxid)
            
            if tsp is not None:
                sp_sn = taxonomy.get_scientific_name(tsp)
            else:
                sp_sn = None   # TODO was '###', discuss
                tsp = None     # TODO was '-1', discuss
                
            if tgn is not None:
                gn_sn = taxonomy.get_scientific_name(tgn)
            else:
                gn_sn = None
                tgn = None
                
            if tfa is not None:
                fa_sn = taxonomy.get_scientific_name(tfa)
            else:
                fa_sn = None
                tfa = None
                
            seq[b"species"] = tsp
            seq[b"genus"] = tgn
            seq[b"family"] = tfa
                
            seq[b"species_name"] = sp_sn
            seq[b"genus_name"] = gn_sn
            seq[b"family_name"] = fa_sn
            
            seq[b"rank"] = taxonomy.get_rank(taxid)
            seq[b"scientific_name"] = taxonomy.get_scientific_name(taxid)


cdef uniq_sequences(View_NUC_SEQS view, View_NUC_SEQS o_view, ProgressBar pb, list mergedKeys_list=None, Taxonomy taxonomy=None, bint mergeIds=False, list categories=None, int max_elts=1000000) :
     
    cdef int            i
    cdef int            k
    cdef int            k_count
    cdef int            o_idx
    cdef int            u_idx
    cdef int            i_idx
    cdef int            i_count
    cdef str            key_str
    cdef bytes          key
    cdef bytes          mkey
    cdef bytes          merged_col_name
    cdef bytes          o_id
    cdef bytes          i_id
    cdef set            mergedKeys_set
    cdef tuple          unique_id
    cdef list           catl
    cdef list           mergedKeys
    cdef list           mergedKeys_list_b
    cdef list           mergedKeys_m
    cdef list           str_merged_cols
    cdef list           merged_sequences
    cdef dict           uniques
    cdef dict           merged_infos
    cdef dict           mkey_infos
    cdef dict           merged_dict
    cdef dict           mkey_cols
    cdef Nuc_Seq_Stored i_seq
    cdef Nuc_Seq_Stored o_seq
    cdef Nuc_Seq_Stored u_seq
    cdef Column         i_col
    cdef Column         i_seq_col
    cdef Column         i_id_col
    cdef Column         i_taxid_col
    cdef Column         i_taxid_dist_col
    cdef Column         o_id_col
    cdef Column         o_taxid_dist_col
    cdef Column         o_merged_col
    cdef Column_line    i_mcol  
    cdef object         taxid_dist_dict
    cdef object         iter_view
    cdef object         mcol
    cdef object         to_merge
    cdef list           merged_list

    uniques = {}
    
    for column_name in view.keys():
        if column_name[:7] == b"MERGED_":
            info_to_merge = column_name[7:]
            if mergedKeys_list is not None:
                mergedKeys_list.append(tostr(info_to_merge))
            else:
                mergedKeys_list = [tostr(info_to_merge)]
    
    mergedKeys_list_b = []
    if mergedKeys_list is not None:
        for key_str in mergedKeys_list:
            mergedKeys_list_b.append(tobytes(key_str))
        mergedKeys_set=set(mergedKeys_list_b)
    else:
        mergedKeys_set=set() 
 
    if taxonomy is not None:
        mergedKeys_set.add(TAXID_COLUMN)
         
    mergedKeys = list(mergedKeys_set)
        
    k_count = len(mergedKeys)
     
    mergedKeys_m = []
    for k in range(k_count):
        mergedKeys_m.append(MERGED_PREFIX + mergedKeys[k])
     
    if categories is None:
        categories = []
 
    # Keep columns that are going to be used a lot in variables 
    i_seq_col = view[NUC_SEQUENCE_COLUMN]
    i_id_col = view[ID_COLUMN]
    if TAXID_COLUMN in view:
        i_taxid_col = view[TAXID_COLUMN]
    if TAXID_DIST_COLUMN in view:
        i_taxid_dist_col = view[TAXID_DIST_COLUMN]

 
    # First browsing
    i = 0
    o_idx = 0
    
    logger("info", "First browsing through the input")
    merged_infos = {}
    iter_view = iter(view)
    for i_seq in iter_view :
        PyErr_CheckSignals()
        pb(i)
         
        # This can't be done in the same line as the unique_id tuple creation because it generates a bug
        # where Cython (version 0.25.2) does not detect the reference to the categs_list variable and deallocates 
        # it at the beginning of the function.
        # (Only happens if categs_list is an optional parameter, which it is).
        catl = []
        for x in categories :
            catl.append(i_seq[x])    
          
        unique_id = tuple(catl) + (i_seq_col.get_line_idx(i),)
        #unique_id = tuple(i_seq[x] for x in categories) + (seq_col.get_line_idx(i),)  # The line that cython can't read properly
         
        if unique_id in uniques:
            uniques[unique_id].append(i)
        else:
            uniques[unique_id] = [i]

        for k in range(k_count):
            key = mergedKeys[k]
            mkey = mergedKeys_m[k]
            if mkey in i_seq:
                if mkey not in merged_infos:
                    merged_infos[mkey] = {}
                    mkey_infos = merged_infos[mkey]
                    mkey_infos['nb_elts'] = view[mkey].nb_elements_per_line
                    mkey_infos['elt_names'] = view[mkey].elements_names
            if key in i_seq:
                if mkey not in merged_infos:
                    merged_infos[mkey] = {}
                    mkey_infos = merged_infos[mkey]
                    mkey_infos['nb_elts'] = 1
                    mkey_infos['elt_names'] = [i_seq[key]]
                else:
                    mkey_infos = merged_infos[mkey]
                    if i_seq[key] not in mkey_infos['elt_names']:     # TODO make faster? but how?
                        mkey_infos['elt_names'].append(i_seq[key])
                        mkey_infos['nb_elts'] += 1
        i+=1

    # Create merged columns
    str_merged_cols = []
    mkey_cols = {}
    for k in range(k_count):
        key = mergedKeys[k]
        merged_col_name = mergedKeys_m[k]
        i_col = view[key]
        
        if merged_infos[merged_col_name]['nb_elts'] > max_elts:
            str_merged_cols.append(merged_col_name)
            Column.new_column(o_view,
                              merged_col_name,
                              OBI_STR,
                              to_eval=True,
                              comments=i_col.comments,
                              alias=merged_col_name
                             )

        else:
            Column.new_column(o_view,
                              merged_col_name,
                              OBI_INT,
                              nb_elements_per_line=merged_infos[merged_col_name]['nb_elts'],
                              elements_names=list(merged_infos[merged_col_name]['elt_names']),
                              comments=i_col.comments,
                              alias=merged_col_name
                             )
        
        mkey_cols[merged_col_name] = o_view[merged_col_name]

    # taxid_dist column
    if mergeIds and TAXID_COLUMN in mergedKeys:
        if len(view) > max_elts: #The number of different IDs corresponds to the number of sequences in the view
            str_merged_cols.append(TAXID_DIST_COLUMN)
            Column.new_column(o_view, 
                              TAXID_DIST_COLUMN, 
                              OBI_STR,
                              to_eval=True,
                              alias=TAXID_DIST_COLUMN
                             )
        else:
            Column.new_column(o_view, 
                              TAXID_DIST_COLUMN, 
                              OBI_INT,
                              nb_elements_per_line=len(view),
                              elements_names=[id for id in i_id_col],
                              alias=TAXID_DIST_COLUMN
                             )

    del(merged_infos)
    
    # Merged ids column
    if mergeIds :
        Column.new_column(o_view,
                          MERGED_COLUMN,
                          OBI_STR,
                          tuples=True,
                          alias=MERGED_COLUMN
                         )

    # Keep columns that are going to be used a lot in variables 
    o_id_col = o_view[ID_COLUMN]
    if TAXID_DIST_COLUMN in o_view:
        o_taxid_dist_col = o_view[TAXID_DIST_COLUMN]
    if MERGED_COLUMN in o_view:
        o_merged_col = o_view[MERGED_COLUMN]
        
    pb(len(view), force=True)
    print("")
    logger("info", "Second browsing through the input")
    # Initialize the progress bar
    pb = ProgressBar(len(uniques), seconde=5)
    o_idx = 0
    
    for unique_id in uniques :
        PyErr_CheckSignals()
        pb(o_idx)
        
        merged_sequences = uniques[unique_id]
        
        u_idx = uniques[unique_id][0]
        u_seq = view[u_idx]
        o_view[o_idx] = u_seq
        o_seq = o_view[o_idx]
        o_id = o_seq.id
        
        if mergeIds:
            merged_list = [view[idx].id for idx in merged_sequences]
            if MERGED_COLUMN in view: # merge all ids if there's already some merged ids info
                merged_list.extend(view[MERGED_COLUMN][idx] for idx in merged_sequences)
            merged_list = list(set(merged_list)) # deduplicate the list
            o_merged_col[o_idx] = merged_list

        o_seq[COUNT_COLUMN] = 0

        if TAXID_DIST_COLUMN in u_seq and i_taxid_dist_col[u_idx] is not None:
            taxid_dist_dict = i_taxid_dist_col[u_idx]
        else:
            taxid_dist_dict = {}           

        merged_dict = {}
        for mkey in mergedKeys_m:
            merged_dict[mkey] = {}

        for i_idx in merged_sequences:
                        
            i_id = i_id_col[i_idx]
            i_seq = view[i_idx]

            if COUNT_COLUMN not in i_seq or i_seq[COUNT_COLUMN] is None:
                i_count = 1
            else:
                i_count = i_seq[COUNT_COLUMN]
 
            o_seq[COUNT_COLUMN] += i_count
        
            for k in range(k_count):
                                
                key = mergedKeys[k]
                mkey = mergedKeys_m[k]
                
                if key==TAXID_COLUMN and mergeIds:
                    if TAXID_DIST_COLUMN in i_seq:
                        taxid_dist_dict.update(i_taxid_dist_col[i_idx])
                    if TAXID_COLUMN in i_seq:
                        taxid_dist_dict[i_id] = i_taxid_col[i_idx]

                # merge relevant keys
                if key in i_seq:
                    to_merge = i_seq[key]
                    if to_merge is not None:
                        if type(to_merge) != bytes:
                            to_merge = tobytes(str(to_merge))
                        mcol = merged_dict[mkey]
                        if to_merge not in mcol or mcol[to_merge] is None:
                            mcol[to_merge] = i_count
                        else:
                            mcol[to_merge] = mcol[to_merge] + i_count
                        o_seq[key] = None
                # merged infos already in seq: merge the merged infos
                if mkey in i_seq:
                    mcol = merged_dict[mkey] # dict
                    i_mcol = i_seq[mkey] # column line
                    if i_mcol.is_NA() == False:
                        for key2 in i_mcol:
                            if key2 not in mcol:
                                mcol[key2] = i_mcol[key2]
                            else:
                                mcol[key2] = mcol[key2] + i_mcol[key2]
            
            # Write taxid_dist
            if mergeIds and TAXID_COLUMN in mergedKeys:
                if TAXID_DIST_COLUMN in str_merged_cols:
                    o_taxid_dist_col[o_idx] = str(taxid_dist_dict)
                else:
                    o_taxid_dist_col[o_idx] = taxid_dist_dict
            
            # Write merged dicts
            for mkey in merged_dict: 
                if mkey in str_merged_cols:
                    mkey_cols[mkey][o_idx] = str(merged_dict[mkey])
                else:
                    mkey_cols[mkey][o_idx] = merged_dict[mkey]
                    # Sets NA values to 0  # TODO discuss, for now keep as None and test for None instead of testing for 0 in tools
                    #for key in mkey_cols[mkey][o_idx]:
                    #    if mkey_cols[mkey][o_idx][key] is None:
                    #        mkey_cols[mkey][o_idx][key] = 0
                            
            for key in i_seq.keys():
                # Delete informations that differ between the merged sequences
                # TODO make special columns list?
                if key != COUNT_COLUMN and key != ID_COLUMN and key != NUC_SEQUENCE_COLUMN and key in o_seq and o_seq[key] != i_seq[key] \
                    and key not in merged_dict :
                    o_seq[key] = None

        o_idx += 1
    
    # Deletes quality columns if there is one because the matching between sequence and quality will be broken (quality set to NA when sequence not)
    if QUALITY_COLUMN in view:
        o_view.delete_column(QUALITY_COLUMN)
    if REVERSE_QUALITY_COLUMN in view:
        o_view.delete_column(REVERSE_QUALITY_COLUMN)
    
    if taxonomy is not None:
        print("")  # TODO because in the middle of progress bar. Better solution?
        logger("info", "Merging taxonomy classification")
        merge_taxonomy_classification(o_view, taxonomy)



def run(config):
    
    cdef tuple         input
    cdef tuple         output 
    cdef tuple         taxo_uri
    cdef Taxonomy      taxo
    cdef View_NUC_SEQS entries
    cdef View_NUC_SEQS o_view
    cdef ProgressBar   pb
    
    DMS.obi_atexit()
    
    logger("info","obi uniq")
    
    # Open the input
    input = open_uri(config['obi']['inputURI'])
    if input is None:
        raise Exception("Could not read input view")    
    if input[2] != View_NUC_SEQS:
        raise NotImplementedError('obi uniq only works on NUC_SEQS views')
    
    # Open the output
    output = open_uri(config['obi']['outputURI'],
                      input=False,
                      newviewtype=View_NUC_SEQS)
    if output is None:
        raise Exception("Could not create output view")
    
    entries = input[1]
    o_view = output[1]
    
    if 'taxoURI' in config['obi'] and config['obi']['taxoURI'] is not None:
        taxo_uri = open_uri(config['obi']['taxoURI'])
        if taxo_uri is None or taxo_uri[2] == bytes:
            raise RollbackException("Couldn't open taxonomy, rollbacking view", o_view)
        taxo = taxo_uri[1]
    else :
        taxo = None

    # Initialize the progress bar
    pb = ProgressBar(len(entries), config, seconde=5)
    
    try:
        uniq_sequences(entries, o_view, pb, mergedKeys_list=config['uniq']['merge'], taxonomy=taxo, mergeIds=config['uniq']['mergeids'], categories=config['uniq']['categories'], max_elts=config['obi']['maxelts'])       
    except Exception, e:
        raise RollbackException("obi uniq error, rollbacking view: "+str(e), o_view)
    
    pb(len(entries), force=True)
    print("", file=sys.stderr)

    # Save command config in View and DMS comments
    command_line = " ".join(sys.argv[1:])
    input_dms_name=[input[0].name]
    input_view_name=[input[1].name]
    if 'taxoURI' in config['obi'] and config['obi']['taxoURI'] is not None:
        input_dms_name.append(config['obi']['taxoURI'].split("/")[-3])
        input_view_name.append("taxonomy/"+config['obi']['taxoURI'].split("/")[-1])
    o_view.write_config(config, "uniq", command_line, input_dms_name=input_dms_name, input_view_name=input_view_name)
    output[0].record_command_line(command_line)

    #print("\n\nOutput view:\n````````````", file=sys.stderr)
    #print(repr(o_view), file=sys.stderr)
    
    input[0].close()
    output[0].close()

    logger("info", "Done.")

