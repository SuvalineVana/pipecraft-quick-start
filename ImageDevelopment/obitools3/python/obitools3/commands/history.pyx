#cython: language_level=3

from obitools3.apps.optiongroups import addMinimalInputOption
from obitools3.uri.decode import open_uri
from obitools3.dms import DMS
from obitools3.dms.view import View
from obitools3.utils cimport bytes2str

 
__title__="Command line histories and view history graphs"
 

def addOptions(parser):

    addMinimalInputOption(parser)
 
    group=parser.add_argument_group('obi history specific options')
 
    group.add_argument('--bash', '-b',
                     action="store_const", dest="history:format",
                     default="bash",
                     const="bash",
                     help="Print history in bash format")

    group.add_argument('--dot', '-d',
                     action="store_const", dest="history:format",
                     default="bash",
                     const="dot",
                     help="Print history in DOT format (default: bash format)")

    group.add_argument('--ascii', '-a',
                     action="store_const", dest="history:format",
                     default="bash",
                     const="ascii",
                     help="Print history in ASCII format (only for views; default: bash format)")
 

def run(config):
    
    cdef object entries
    
    DMS.obi_atexit()
    
    input = open_uri(config['obi']['inputURI'])
       
    entries = input[1]
    
    if config['history']['format'] == "bash" :
        print(bytes2str(entries.bash_history))
    elif config['history']['format'] == "dot" :
        print(bytes2str(entries.dot_history_graph))
    elif config['history']['format'] == "ascii" :
        if isinstance(entries, View):
            print(bytes2str(entries.ascii_history))
        else:
            raise Exception("ASCII history only available for views")
            
