#cython: language_level=3

from obitools3.apps.progress cimport ProgressBar  # @UnresolvedImport
from obitools3.dms import DMS
from obitools3.dms.view.view cimport View, Line_selection
from obitools3.uri.decode import open_uri
from obitools3.apps.optiongroups import addMinimalInputOption, addTaxonomyOption, addMinimalOutputOption
from obitools3.dms.view import RollbackException
from obitools3.apps.config import logger
from obitools3.utils cimport tobytes, str2bytes

from functools import reduce
import time
import re
import sys
import ast
from cpython.exc cimport PyErr_CheckSignals

 
__title__="Grep view lines that match the given predicates"


# TODO should sequences that have a grepped attribute at None be grepped or not? (in obi1 they are but....)

 
def addOptions(parser):
    
    addMinimalInputOption(parser)
    addTaxonomyOption(parser)
    addMinimalOutputOption(parser)

    group=parser.add_argument_group("obi grep specific options")
 
    group.add_argument("--predicate", "-p",
                       action="append", dest="grep:grep_predicates",
                       metavar="<PREDICATE>",
                       default=[],
                       type=str,
                       help="Python boolean expression to be evaluated in the "
                            "sequence/line context. The attribute name can be "
                            "used in the expression as a variable name. "
                            "An extra variable named 'sequence' or 'line' refers "
                            "to the sequence or line object itself. "
                            "Several -p options can be used on the same "
                            "command line.")
 
    group.add_argument("-S", "--sequence",
                       action="store", dest="grep:seq_pattern",
                       metavar="<REGULAR_PATTERN>",
                       type=str,
                       help="Regular expression pattern used to select "
                            "the sequence. The pattern is case insensitive.")
    
    group.add_argument("-D", "--definition",
                       action="store", dest="grep:def_pattern",
                       metavar="<REGULAR_PATTERN>",
                       type=str,
                       help="Regular expression pattern used to select "
                            "the definition of the sequence. The pattern is case insensitive.")
    
    group.add_argument("-I", "--identifier",
                       action="store", dest="grep:id_pattern",
                       metavar="<REGULAR_PATTERN>",
                       type=str,
                       help="Regular expression pattern used to select "
                            "the identifier of the sequence. The pattern is case insensitive.")
    
    group.add_argument("--id-list",
                       action="store", dest="grep:id_list",
                       metavar="<FILE_NAME>",
                       type=str,
                       help="File containing the identifiers of the sequences to select.")

    group.add_argument("-a", "--attribute",
                       action="append", dest="grep:attribute_patterns",
                       type=str,
                       default=[],
                       metavar="<ATTRIBUTE_NAME>:<REGULAR_PATTERN>",
                       help="Regular expression pattern matched against "
                            "the attributes of the sequence. "
                            "The pattern is case sensitive. "
                            "Several -a options can be used on the same "
                            "command line.")
    
    group.add_argument("-A", "--has-attribute",
                       action="append", dest="grep:attributes",
                       type=str,
                       default=[],
                       metavar="<ATTRIBUTE_NAME>",
                       help="Select records with the attribute <ATTRIBUTE_NAME> "
                            "defined (not set to NA value). "
                            "Several -a options can be used on the same "
                            "command line.")
    
    group.add_argument("-L", "--lmax",
                       action="store", dest="grep:lmax",
                       metavar="<MAX_LENGTH>",
                       type=int,
                       help="Keep sequences shorter than MAX_LENGTH.")
                             
    group.add_argument("-l", "--lmin",
                       action="store", dest="grep:lmin",
                       metavar="<MIN_LENGTH>",
                       type=int,
                       help="Keep sequences longer than MIN_LENGTH.")
    
    group.add_argument("-v", "--invert-selection",
                       action="store_true", dest="grep:invert_selection",
                       default=False,
                       help="Invert the selection.")


    group=parser.add_argument_group("Taxonomy filtering specific options")  #TODO put somewhere else? not in grep
 
    group.add_argument('--require-rank',
                       action="append", dest="grep:required_ranks",
                       metavar="<RANK_NAME>",
                       type=str,
                       default=[],
                       help="Select sequences with a taxid that is or has "
                            "a parent of rank <RANK_NAME>.")
     
    group.add_argument('-r', '--required',
                       action="append", dest="grep:required_taxids",
                       metavar="<TAXID>",
                       type=int,
                       default=[],
                       help="Select the sequences having the ancestor of taxid <TAXID>. "
                            "If several ancestors are specified (with \n'-r taxid1 -r taxid2'), "
                            "the sequences having at least one of them are selected.")
     
    # TODO useless option equivalent to -r -v?
    group.add_argument('-i','--ignore',
                     action="append", dest="grep:ignored_taxids",
                     metavar="<TAXID>",
                     type=int,
                     default=[],
                     help="Ignore the sequences having the ancestor of taxid <TAXID>. "
                          "If several ancestors are specified (with \n'-r taxid1 -r taxid2'), "
                          "the sequences having at least one of them are ignored.")


def obi_compile_eval(str expr):
    
    class MyVisitor(ast.NodeTransformer):
        def visit_Str(self, node: ast.Str):
            result = ast.Bytes(s = node.s.encode('utf-8'))
            return ast.copy_location(result, node)
   
    expr = "obi_eval_result="+expr
    tree = ast.parse(expr)
    optimizer = MyVisitor()
    tree = optimizer.visit(tree)
    return compile(tree, filename="<ast>", mode="exec")

    
def obi_eval(compiled_expr, loc_env, line):

    exec(compiled_expr, {}, loc_env)
    obi_eval_result = loc_env["obi_eval_result"]
    return obi_eval_result
    

def Filter_generator(options, tax_filter):
    #taxfilter = taxonomyFilterGenerator(options)

    # Initialize conditions
    predicates = None
    if "grep_predicates" in options:
        predicates = [obi_compile_eval(p) for p in options["grep_predicates"]]
    attributes = None
    if "attributes" in options and len(options["attributes"]) > 0:
        attributes = options["attributes"]
    lmax = None
    if "lmax" in options:
        lmax = options["lmax"]
    lmin = None
    if "lmin" in options:
        lmin = options["lmin"]
    invert_selection = options["invert_selection"]
    id_set = None
    if "id_list" in options:
        id_set = set(x.strip() for x in open(options["id_list"]))

    # Initialize the regular expression patterns
    seq_pattern = None
    if "seq_pattern" in options:
        seq_pattern = re.compile(tobytes(options["seq_pattern"]), re.I)
    id_pattern = None
    if "id_pattern" in options:
        id_pattern = re.compile(tobytes(options["id_pattern"]))
    def_pattern = None
    if "def_pattern" in options:
        def_pattern = re.compile(tobytes(options["def_pattern"]))
    attribute_patterns={}
    if "attribute_patterns" in options and len(options["attribute_patterns"]) > 0:
        for p in options["attribute_patterns"]:
            attribute, pattern = p.split(":", 1)
            attribute_patterns[tobytes(attribute)] = re.compile(tobytes(pattern))
    
    def filter(line, loc_env):
        cdef bint good = True
        
        if seq_pattern and hasattr(line, "seq"):
            good = <bint>(seq_pattern.search(line.seq))
        
        if good and id_pattern and hasattr(line, "id"):
            good = <bint>(id_pattern.search(line.id))
            
        if good and id_set is not None and hasattr(line, "id"):
            good = line.id in id_set
            
        if good and def_pattern and hasattr(line, "definition"):
            good = <bint>(def_pattern.search(line.definition))
             
        if good and attributes:  # TODO discuss that we test not None
            good = reduce(lambda bint x, bint y: x and y,
                           (line[attribute] is not None for attribute in attributes),
                           True)
             
        if good and attribute_patterns:
            good = (reduce(lambda bint x, bint y : x and y, 
                        (line[attribute] is not None for attribute in attribute_patterns),
                        True)
                    and
                    reduce(lambda bint x, bint y: x and y,
                        (<bint>(attribute_patterns[attribute].search(tobytes(str(line[attribute]))))
                        for attribute in attribute_patterns), 
                        True)
                   )
                     
        if good and predicates:
            good = (reduce(lambda bint x, bint y: x and y,
                    (bool(obi_eval(p, loc_env, line))
                    for p in predicates), True))

        if good and lmin:
            good = len(line) >= lmin
             
        if good and lmax:
            good = len(line) <= lmax
         
        if good:
            good = tax_filter(line)
       
        if invert_selection :
            good = not good

        return good
    
    return filter


def Taxonomy_filter_generator(taxo, options):
    if taxo is not None:
        def tax_filter(seq):
            good = True
            if b'TAXID' in seq and seq[b'TAXID'] is not None:   # TODO use macro
                taxid = seq[b'TAXID']
                if "required_ranks" in options and options["required_ranks"]:
                    taxon_at_rank = reduce(lambda x,y: x and y,
                                           (taxo.get_taxon_at_rank(seq[b'TAXID'], rank) is not None
                                            for rank in options["required_ranks"]),
                                           True)
                    good = good and taxon_at_rank 
                if "required_taxids" in options and options["required_taxids"]:
                    good = good and reduce(lambda x,y: x or y,
                                           (taxo.is_ancestor(r, taxid) 
                                            for r in options["required_taxids"]),
                                           False)
                if "ignored_taxids" in options and options["ignored_taxids"]:
                    good = good and not reduce(lambda x,y: x or y,
                                               (taxo.is_ancestor(r,taxid) 
                                                for r in options["ignored_taxids"]),
                                               False)
            return good
    else:
        def tax_filter(seq):
            return True
    return tax_filter


def run(config):
     
    DMS.obi_atexit()
    
    logger("info", "obi grep")

    # Open the input
    input = open_uri(config["obi"]["inputURI"])
    if input is None:
        raise Exception("Could not read input view")
    i_dms = input[0]
    i_view = input[1]

    # Open the output: only the DMS
    output = open_uri(config['obi']['outputURI'],
                      input=False,
                      dms_only=True)
    if output is None:
        raise Exception("Could not create output view")
    o_dms = output[0]
    o_view_name_final = output[1]
    o_view_name = o_view_name_final
    
    # If the input and output DMS are not the same, create output view in input DMS first, then export it
    # to output DMS, making sure the temporary view name is unique in the input DMS 
    if i_dms != o_dms:
        i=0
        while o_view_name in i_dms:
            o_view_name = o_view_name_final+b"_"+str2bytes(str(i))
            i+=1        

    if 'taxoURI' in config['obi'] and config['obi']['taxoURI'] is not None:
        taxo_uri = open_uri(config["obi"]["taxoURI"])
        if taxo_uri is None or taxo_uri[2] == bytes:
            raise Exception("Couldn't open taxonomy")
        taxo = taxo_uri[1]
    else :
        taxo = None

    # Initialize the progress bar
    pb = ProgressBar(len(i_view), config, seconde=5)
 
    # Apply filter
    tax_filter = Taxonomy_filter_generator(taxo, config["grep"])
    filter = Filter_generator(config["grep"], tax_filter)
    selection = Line_selection(i_view)
    for i in range(len(i_view)):
        PyErr_CheckSignals()
        pb(i)
        line = i_view[i]
                 
        loc_env = {"sequence": line, "line": line, "taxonomy": taxo, "obi_eval_result": False}
        
        good = filter(line, loc_env)
 
        if good :
            selection.append(i)

    pb(i, force=True)
    print("", file=sys.stderr)

    # Create output view with the line selection
    try:
        o_view = selection.materialize(o_view_name)
    except Exception, e:
        raise RollbackException("obi grep error, rollbacking view: "+str(e), o_view)
    
    # Save command config in View and DMS comments
    command_line = " ".join(sys.argv[1:])
    input_dms_name=[input[0].name]
    input_view_name=[input[1].name]
    if 'taxoURI' in config['obi'] and config['obi']['taxoURI'] is not None:
        input_dms_name.append(config['obi']['taxoURI'].split("/")[-3])
        input_view_name.append("taxonomy/"+config['obi']['taxoURI'].split("/")[-1])
    o_view.write_config(config, "grep", command_line, input_dms_name=input_dms_name, input_view_name=input_view_name)
    o_dms.record_command_line(command_line)

    # If input and output DMS are not the same, export the temporary view to the output DMS
    # and delete the temporary view in the input DMS
    if i_dms != o_dms:
        o_view.close()
        View.import_view(i_dms.full_path[:-7], o_dms.full_path[:-7], o_view_name, o_view_name_final)
        o_view = o_dms[o_view_name_final]

    #print("\n\nOutput view:\n````````````", file=sys.stderr)
    #print(repr(o_view), file=sys.stderr)

    # If the input and the output DMS are different, delete the temporary imported view used to create the final view
    if i_dms != o_dms:
        View.delete_view(i_dms, o_view_name)
        o_dms.close()
    i_dms.close()

    logger("info", "Done.")
