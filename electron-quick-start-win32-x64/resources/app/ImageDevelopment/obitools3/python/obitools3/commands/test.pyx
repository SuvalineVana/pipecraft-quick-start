#cython: language_level=3

from obitools3.apps.progress cimport ProgressBar  # TODO I absolutely don't understand why it doesn't work without that line
from obitools3.dms.view import View, Line_selection
from obitools3.dms.view.typed_view.view_NUC_SEQS import View_NUC_SEQS
from obitools3.dms import DMS
from obitools3.dms.column import Column
from obitools3.dms.taxo import Taxonomy
from obitools3.utils cimport str2bytes
from obitools3.dms.capi.obitypes cimport OBI_INT, \
                                         OBI_FLOAT, \
                                         OBI_BOOL, \
                                         OBI_CHAR, \
                                         OBI_STR, \
                                         OBI_SEQ
                                         
from obitools3.dms.capi.obiview cimport NUC_SEQUENCE_COLUMN, \
                                        ID_COLUMN, \
                                        DEFINITION_COLUMN, \
                                        QUALITY_COLUMN, \
                                        COUNT_COLUMN

import shutil
import string
import random
from cpython.exc cimport PyErr_CheckSignals


VIEW_TYPES = [b"", b"NUC_SEQS_VIEW"]
COL_TYPES = [OBI_INT, OBI_FLOAT, OBI_BOOL, OBI_CHAR, OBI_STR, OBI_SEQ]
SPECIAL_COLUMNS = [NUC_SEQUENCE_COLUMN, ID_COLUMN, DEFINITION_COLUMN, QUALITY_COLUMN]

#TAXDUMP = "" TODO path=?
TAXTEST = b"taxtest"
 
NAME_MAX_LEN = 200
COL_COMMENTS_MAX_LEN = 2048
MAX_INT = 2147483647    # used to generate random float values
 
 
__title__="Tests if the obitools are working properly"


default_config = {
                 }


def test_taxo(config, infos):
    tax1 = Taxonomy.open_taxdump(infos['dms'], config['obi']['taxo'])
    tax1.write(TAXTEST)
    tax2 = Taxonomy.open(infos['dms'], TAXTEST)
    assert len(tax1) == len(tax2), "Length of written taxonomy != length of read taxdump : "+str(len(tax2))+" != "+str(len(tax1))
    
    i = 0
    for x in range(config['test']['nbtests']):
        idx = random.randint(0, len(tax1)-1)
        t1 = tax1.get_taxon_by_idx(idx)
        taxid1 = t1.taxid
        t2 = tax2.get_taxon_by_idx(idx)
        taxid2 = t2.taxid
        assert t1 == t2, "Taxon gotten from written taxonomy with index != taxon read from taxdump : "+str(t2)+" != "+str(t1)
        t1 = tax1[taxid1]
        t2 = tax2[taxid2]
        assert t1 == t2, "Taxon gotten from written taxonomy with taxid != taxon read from taxdump : "+str(t2)+" != "+str(t1)
        i+=1
        if (i%(config['test']['nbtests']/10)) == 0 :
            print("Testing taxonomy functions......"+str(i*100/config['test']['nbtests'])+"%")

    tax1.close()
    tax2.close()


def random_length(max_len):
    return random.randint(1, max_len)


def random_bool(config):
    return random.choice([True, False])


def random_bool_tuples(config):
    l=[]
    for i in range(random.randint(1, config['test']['tuplemaxlen'])) :
        l.append(random.choice([None, random_bool(config)]))
    return tuple(l)


def random_char(config):
    return str2bytes(random.choice(string.ascii_lowercase))


def random_char_tuples(config):
    l=[]
    for i in range(random.randint(1, config['test']['tuplemaxlen'])) :
        l.append(random.choice([None, random_char(config)]))
    return tuple(l)


def random_float(config):
    return random.randint(0, MAX_INT) + random.random()


def random_float_tuples(config):
    l=[]
    for i in range(random.randint(1, config['test']['tuplemaxlen'])) :
        l.append(random.choice([None, random_float(config)]))
    return tuple(l)


def random_int(config):
    return random.randint(0, config['test']['maxlinenb'])


def random_int_tuples(config):
    l=[]
    for i in range(random.randint(1, config['test']['tuplemaxlen'])) :
        l.append(random.choice([None, random_int(config)]))
    return tuple(l)


def random_seq(config):
    return str2bytes(''.join(random.choice(['a','t','g','c']) for i in range(random_length(config['test']['seqmaxlen']))))


def random_seq_tuples(config):
    l=[]
    for i in range(random.randint(1, config['test']['tuplemaxlen'])) :
        l.append(random.choice([None, random_seq(config)]))
    return tuple(l)


def random_bytes(config):
    return random_bytes_with_max_len(config['test']['strmaxlen'])


def random_bytes_tuples(config):
    l=[]
    for i in range(random.randint(1, config['test']['tuplemaxlen'])) :
        l.append(random.choice([None, random_bytes(config)]))
    return tuple(l)


def random_str_with_max_len(max_len):
    return ''.join(random.choice(string.ascii_lowercase) for i in range(random_length(max_len)))


def random_bytes_with_max_len(max_len):
    return str2bytes(random_str_with_max_len(max_len))


RANDOM_FUNCTIONS = [random_bool, random_char, random_bytes, random_float, random_int]
def random_comments(config):
    comments = {}
    for i in range(random_length(1000)):
        to_add = {random_bytes(config): random.choice(RANDOM_FUNCTIONS)(config)}
        if len(str(comments)) + len(str(to_add)) >= COL_COMMENTS_MAX_LEN:
            return comments
        else:
            comments.update(to_add)
    return comments
    
 
def random_column(infos):
    return random.choice(sorted(list(infos['view'].keys())))
 
 
def random_unique_name(infos):
    name = b""
    while name == b"" or name in infos['unique_names'] :
        name = random_bytes_with_max_len(NAME_MAX_LEN)
    infos['unique_names'].append(name)
    return name
 
 
def random_unique_element_name(config, infos):
    name = b""
    while name == b"" or name in infos['unique_names'] :
        name = random_bytes_with_max_len(config['test']['elt_name_max_len'])
    infos['unique_names'].append(name)
    return name
 
 
def print_test(config, sentence):
    if config['test']['verbose'] :
        print(sentence)
 
 
def test_set_and_get(config, infos):
    print_test(config, ">>> Set and get test")
    col_name = random_column(infos)
    col = infos['view'][col_name]
    element_names = col.elements_names
    data_type = col.data_type
    if data_type == b"OBI_QUAL" :
        print_test(config, "-")
        return
    idx = random_int(config)
    value = random.choice([None, infos['random_generator'][(data_type, col.tuples)](config)])
    if col.nb_elements_per_line > 1 :
        elt = random.choice(element_names)
        col[idx][elt] = value
        assert col[idx][elt] == value, "Column: "+repr(col)+"\nSet value != gotten value "+str(value)+" != "+str(col[idx][elt])
    elif col.tuples:
        col[idx] = value
        if value is None:
            totest = None
        else:
            totest = []
            for e in value:
                if e is not None and e != '':
                    totest.append(e)
            if len(totest) == 0:
                totest = None
            else:
                totest = tuple(totest)
        assert col[idx] == totest, "Column: "+repr(col)+"\nSet value != gotten value "+str(totest)+" != "+str(col[idx])
        if totest is not None:
            for i in range(len(totest)) :
                assert col[idx][i] == totest[i], "Column: "+repr(col)+"\nSet value[i] != gotten value[i] "+str(totest[i])+" != "+str(col[idx][i])
    else:
        col[idx] = value
        assert col[idx] == value, "Column: "+repr(col)+"\nSet value != gotten value "+str(value)+" != "+str(col[idx])
    
    print_test(config, ">>> Set and get test OK")


def test_add_col(config, infos):
    print_test(config, ">>> Add column test")
    #existing_col = random_bool(config)    # TODO doesn't work because of line count problem. See obiview.c line 1737
    #if existing_col and infos["view_names"] != [] :
    #    random_view = infos['dms'].open_view(random.choice(infos["view_names"]))
    #    random_column = random_view[random.choice(sorted(list(random_view.columns))]
    #    random_column_refs = random_column.refs
    #    if random_column_refs['name'] in infos['view'] :
    #        alias = random_unique_name(infos)
    #    else :
    #        alias = ''
    #    infos['view'].add_column(random_column_refs['name'], version_number=random_column_refs['version'], alias=alias, create=False)
    #    random_view.close()
    #else :
    create_random_column(config, infos)
    print_test(config, ">>> Add column test OK")


def test_delete_col(config, infos):
    print_test(config, ">>> Delete column test")
    if len(list(infos['view'].keys())) <= 1 :
        print_test(config, "-")
        return
    col_name = random_column(infos)
    if col_name in SPECIAL_COLUMNS :
        print_test(config, "-")
        return
    infos['view'].delete_column(col_name)
    print_test(config, ">>> Delete column test OK")


def test_col_alias(config, infos):
    print_test(config, ">>> Changing column alias test")
    col_name = random_column(infos)
    if col_name in SPECIAL_COLUMNS :
        print_test(config, "-")
        return
    infos['view'][col_name].name = random_unique_name(infos)
    print_test(config, ">>> Changing column alias test OK")
         
 
def test_new_view(config, infos):
    print_test(config, ">>> New view test")
    random_new_view(config, infos)
    print_test(config, ">>> New view test OK")
 
 
def random_test(config, infos):
    return random.choice(infos['tests'])(config, infos)
 
 
def random_view_type():
    return random.choice(VIEW_TYPES)
 
 
def random_col_type():
    return random.choice(COL_TYPES)    
 
 
def fill_column(config, infos, col) :
    data_type = col.data_type
    element_names = col.elements_names
     
    if len(element_names) > 1 :
        for i in range(random_int(config)) :
            for j in range(len(element_names)) :
                col[i][element_names[j]] = random.choice([None, infos['random_generator'][(data_type, col.tuples)](config)])
    else :
        for i in range(random_int(config)) :
            r = random.choice([None, infos['random_generator'][(data_type, col.tuples)](config)])
            col[i] = r


def create_random_column(config, infos) :
    alias = random.choice([b'', random_unique_name(infos)])
    tuples = random.choice([True, False])
    if not tuples :
        nb_elements_per_line=random.randint(1, config['test']['maxelts'])
        elements_names = []
        for i in range(nb_elements_per_line) :
            elements_names.append(random_unique_element_name(config, infos))
        elements_names = random.choice([None, elements_names])
    else :
        nb_elements_per_line = 1
        elements_names = None
    name = random_unique_name(infos)
    data_type = random_col_type()
    
    column = Column.new_column(infos['view'], 
                               name, 
                               data_type, 
                               nb_elements_per_line=nb_elements_per_line,
                               elements_names=elements_names,
                               tuples=tuples,
                               comments=random_comments(config),
                               alias=alias
                               )   
    
    if alias != b'' :
        assert infos['view'][alias] == column
    else :
        assert infos['view'][name] == column

    return column
 
 
def fill_view(config, infos):
    for i in range(random.randint(1, config['test']['maxinicolcount'])) :
        col = create_random_column(config, infos)
        fill_column(config, infos, col)
 
 
def random_new_view(config, infos, first=False):
    v_to_clone = None
    line_selection = None
    quality_col = False     # TODO
    if not first:
        infos['view_names'].append(infos['view'].name)
        infos['view'].close()
        v_to_clone = View.open(infos['dms'], random.choice(infos["view_names"]))
        v_type = b""
        print_test(config, "View to clone: ")
        print_test(config, repr(v_to_clone))
        create_line_selection = random_bool(config)
        if create_line_selection and v_to_clone.line_count > 0:
            print_test(config, "New view with new line selection.")
            line_selection = Line_selection(v_to_clone)
            for i in range(random.randint(1, v_to_clone.line_count)) :
                line_selection.append(random.randint(0, v_to_clone.line_count-1))
            #print_test(config, "New line selection: "+str(line_selection))
    else :
        v_type = random_view_type()
     
    if line_selection is not None :
        infos['view'] = line_selection.materialize(random_unique_name(infos), comments=random_comments(config))
    elif v_to_clone is not None :
        infos['view'] = v_to_clone.clone(random_unique_name(infos), comments=random_comments(config))
    else :
        if v_type == "NUC_SEQS_VIEW" :
            infos['view'] = View_NUC_SEQS.new(infos['dms'], random_unique_name(infos), comments=random_comments(config))   # TODO quality column
        else :
            infos['view'] = View.new(infos['dms'], random_unique_name(infos), comments=random_comments(config))   # TODO quality column
        
    print_test(config, repr(infos['view']))
    if v_to_clone is not None :
        if line_selection is None:
            assert v_to_clone.line_count == infos['view'].line_count, "New view and cloned view don't have the same line count : "+str(v_to_clone.line_count)+" (view to clone line count) != "+str(infos['view'].line_count)+" (new view line count)"
        else :
            assert len(line_selection) == infos['view'].line_count, "New view with new line selection does not have the right line count : "+str(len(line_selection))+" (line selection length) != "+str(infos['view'].line_count)+" (new view line count)"
        v_to_clone.close()
    if first :
        fill_view(config, infos)


def create_test_obidms(config, infos):
    infos['dms'] = DMS.new(config['obi']['defaultdms'])


def ini_dms_and_first_view(config, infos):
    create_test_obidms(config, infos)
    random_new_view(config, infos, first=True)
    infos['view_names'] = []


def addOptions(parser):
     
    # TODO put this common group somewhere else but I don't know where
    group=parser.add_argument_group('DMS and view options')
 
    group.add_argument('--default-dms','-d', 
                       action="store", dest="obi:defaultdms",
                       metavar='<DMS NAME>',
                       default="/tmp/test_dms",
                       type=str,
                       help="Name of the default DMS for reading and writing data. "
                            "Default: /tmp/test_dms")
    
    group.add_argument('--taxo','-t',     # TODO I don't understand why the option is not registered if it is not set
                       action="store", dest="obi:taxo",
                       metavar='<TAXDUMP PATH>',
                       default='',  # TODO not None because if it's None, the option is not entered in the option dictionary.
                       type=str,
                       help="Path to a taxdump to test the taxonomy.")

     
    group=parser.add_argument_group('obi test specific options')
 
    group.add_argument('--nb_tests','-n',
                       action="store", dest="test:nbtests",
                       metavar='<NB_TESTS>',
                       default=1000,
                       type=int,
                       help="Number of tests to carry out. "
                            "Default: 1000")
 
    group.add_argument('--seq_max_len','-s',
                       action="store", dest="test:seqmaxlen",
                       metavar='<SEQ_MAX_LEN>',
                       default=200,
                       type=int,
                       help="Maximum length of DNA sequences. "
                            "Default: 200")
 
    group.add_argument('--str_max_len','-r',
                       action="store", dest="test:strmaxlen",
                       metavar='<STR_MAX_LEN>',
                       default=200,
                       type=int,
                       help="Maximum length of character strings. "
                            "Default: 200")

    group.add_argument('--tuple_max_len','-u',
                       action="store", dest="test:tuplemaxlen",
                       metavar='<TUPLE_MAX_LEN>',
                       default=20,
                       type=int,
                       help="Maximum length of tuples. "
                            "Default: 200")
  
    group.add_argument('--max_ini_col_count','-o',
                       action="store", dest="test:maxinicolcount",
                       metavar='<MAX_INI_COL_COUNT>',
                       default=10,
                       type=int,
                       help="Maximum number of columns in the initial view. "
                            "Default: 10")
 
    group.add_argument('--max_line_nb','-l',
                       action="store", dest="test:maxlinenb",
                       metavar='<MAX_LINE_NB>',
                       default=10000,
                       type=int,
                       help="Maximum number of lines in a column. "
                            "Default: 10000")
 
    group.add_argument('--max_elts_per_line','-e',
                       action="store", dest="test:maxelts",
                       metavar='<MAX_ELTS_PER_LINE>',
                       default=20,
                       type=int,
                       help="Maximum number of elements per line in a column. "
                            "Default: 20")
 
    group.add_argument('--verbose','-v',
                       action="store_true", dest="test:verbose",
                       default=False,
                       help="Print the tests. "
                            "Default: Don't print the tests")
 
    group.add_argument('--seed','-g',
                       action="store", dest="test:seed",
                       metavar='<SEED>',
                       default=None,
                       help="Seed (use for reproducible tests). "
                            "Default: Seed is determined by Python")
 
def run(config):
     
    if 'seed' in config['test'] :
        random.seed(config['test']['seed'])
     
    infos = {'dms': None, 
             'view': None, 
             'view_names': None, 
             'unique_names': [],
             'random_generator': {
                                    (b"OBI_BOOL", False): random_bool, (b"OBI_BOOL", True): random_bool_tuples, 
                                    (b"OBI_CHAR", False): random_char, (b"OBI_CHAR", True): random_char_tuples, 
                                    (b"OBI_FLOAT", False): random_float, (b"OBI_FLOAT", True): random_float_tuples, 
                                    (b"OBI_INT", False): random_int, (b"OBI_INT", True): random_int_tuples, 
                                    (b"OBI_SEQ", False): random_seq, (b"OBI_SEQ", True): random_seq_tuples,
                                    (b"OBI_STR", False): random_bytes, (b"OBI_STR", True): random_bytes_tuples
                                  },
             'tests': [test_set_and_get, test_add_col, test_delete_col, test_col_alias, test_new_view]
            }
 
    # TODO ???
    config['test']['elt_name_max_len'] = int((COL_COMMENTS_MAX_LEN - config['test']['maxelts']) / config['test']['maxelts'])
 
    print("Initializing the DMS and the first view...")
     
    shutil.rmtree(config['obi']['defaultdms']+'.obidms', ignore_errors=True)
    
    ini_dms_and_first_view(config, infos)
    print_test(config, repr(infos['view']))
    
    i = 0
    for t in range(config['test']['nbtests']):
        PyErr_CheckSignals()
        random_test(config, infos)
        print_test(config, repr(infos['view']))
        i+=1
        if (i%(config['test']['nbtests']/10)) == 0 :
            print("Testing......"+str(i*100/config['test']['nbtests'])+"%")
            #lsof = subprocess.Popen("lsof | grep '/private/tmp/test_dms.obidms/'", stdin=subprocess.PIPE, shell=True )
            #lsof.communicate( b"LSOF\n" )
            #lsof = subprocess.Popen("lsof | wc -l", stdin=subprocess.PIPE, shell=True )
            #lsof.communicate( b"LSOF total\n" )
 
    #print(infos)
    
    if config['obi']['taxo'] != '' :
        test_taxo(config, infos)
    
    infos['view'].close()
    infos['dms'].close()
    shutil.rmtree(config['obi']['defaultdms']+'.obidms', ignore_errors=True)
     
    print("Done.")

        