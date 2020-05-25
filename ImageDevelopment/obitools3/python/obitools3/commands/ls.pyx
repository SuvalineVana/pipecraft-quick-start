#cython: language_level=3

from obitools3.uri.decode import open_uri
from obitools3.apps.config import logger
from obitools3.dms import DMS
from obitools3.dms.taxo.taxo cimport Taxonomy
from obitools3.apps.optiongroups import addMinimalInputOption
from obitools3.utils cimport tostr, bytes2str_object

 
__title__="Print a preview of a DMS, view, column...."


def addOptions(parser):    
    addMinimalInputOption(parser)
    group = parser.add_argument_group('obi ls specific options')

    group.add_argument('-l',
                     action="store_true", dest="ls:longformat",
                     default=False,
                     help="Detailed list in long format with all metadata.")


def run(config):

    DMS.obi_atexit()
    
    logger("info", "obi ls")

    # Open the input
    input = open_uri(config['obi']['inputURI'])
    if input is None:
        raise Exception("Could not read input")
    if input[2] == DMS and not config['ls']['longformat']:
        dms = input[0]
        l = []
        for view in input[0]:
            l.append(tostr(view) + "\t(Date created: " + str(bytes2str_object(dms[view].comments["Date created"]))+")")
        l.sort()
        for v in l:
            print(v)
    else:
        print(repr(input[1]))
    if input[2] == DMS:
        taxolist = ["\n### Taxonomies:"]
        for t in Taxonomy.list_taxos(input[0]):
            taxolist.append("\t"+tostr(t))
        if len(taxolist) > 1:
            for t in taxolist:
                print(t)
    if config['ls']['longformat'] and len(input[1].comments) > 0:
        print("\n### Comments:")
        print(str(input[1].comments))
     
