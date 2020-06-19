#cython: language_level=3

from obitools3.apps.progress cimport ProgressBar  # @UnresolvedImport
from obitools3.dms import DMS
from obitools3.dms.view.typed_view.view_NUC_SEQS cimport View_NUC_SEQS
from obitools3.dms.column.column cimport Column
from obitools3.dms.capi.obiview cimport QUALITY_COLUMN
from obitools3.dms.capi.obitypes cimport OBI_QUAL
from obitools3.apps.optiongroups import addMinimalInputOption, addMinimalOutputOption
from obitools3.uri.decode import open_uri
from obitools3.apps.config import logger
from obitools3.libalign._qsassemble import QSolexaReverseAssemble
from obitools3.libalign._qsrassemble import QSolexaRightReverseAssemble
from obitools3.libalign._solexapairend import buildConsensus, buildJoinedSequence
from obitools3.dms.obiseq cimport Nuc_Seq
from obitools3.libalign.shifted_ali cimport Kmer_similarity, Ali_shifted
from obitools3.dms.capi.obiview cimport REVERSE_SEQUENCE_COLUMN, REVERSE_QUALITY_COLUMN

import sys
import os

from cpython.exc cimport PyErr_CheckSignals

__title__="Aligns paired-ended reads"



def addOptions(parser):

    addMinimalInputOption(parser)
    addMinimalOutputOption(parser)
 
    group = parser.add_argument_group('obi alignpairedend specific options')

    group.add_argument('-R', '--reverse-reads',
                     action="store", dest="alignpairedend:reverse",
                     metavar="<URI>",
                     default=None,
                     type=str,
                     help="URI to the reverse reads if they are in a different view than the forward reads")

    group.add_argument('--score-min',
                     action="store", dest="alignpairedend:smin",
                     metavar="#.###",
                     default=None,
                     type=float,
                     help="Minimum score for keeping alignments")

#     group.add_argument('-A', '--true-ali',
#                        action="store_true", dest="alignpairedend:trueali",
#                        default=False,
#                        help="Performs gap free end alignment of sequences instead of using kmers to compute alignments (slower).")

    group.add_argument('-k', '--kmer-size',
                       action="store", dest="alignpairedend:kmersize",
                       metavar="#",
                       default=3,
                       type=int,
                       help="K-mer size for kmer comparisons, between 1 and 4 (default: 3)")


la = QSolexaReverseAssemble()
ra = QSolexaRightReverseAssemble()
cdef object buildAlignment(object direct, object reverse):
    
    if len(direct)==0 or len(reverse)==0:
        return None
    
    la.seqA = direct
    la.seqB = reverse
    
    ali=la()
    ali.direction='left'

    ra.seqA = direct
    ra.seqB = reverse

    rali=ra()
    rali.direction='right'
     
    if ali.score < rali.score:
        ali = rali
    
    return ali
    

def alignmentIterator(entries, aligner): 
    
    if type(entries) == list:
        two_views = True
        forward = entries[0]
        reverse = entries[1]
        entries_len = len(forward)
    else:
        two_views = False
        entries_len = len(entries)
    
    for i in range(entries_len):
                
        if two_views:
            seqF = forward[i]
            seqR = reverse[i]
        else:
            seqF = Nuc_Seq.new_from_stored(entries[i])
            seqR = Nuc_Seq(seqF.id, seqF[REVERSE_SEQUENCE_COLUMN], quality=seqF[REVERSE_QUALITY_COLUMN])
            seqR.index = i
        
        ali = aligner(seqF, seqR)
        
        if ali is None:
            continue
        
        yield ali


def run(config):
        
    DMS.obi_atexit()
    
    logger("info", "obi alignpairedend")
       
    # Open the input
    
    two_views = False
    forward = None
    reverse = None
    input = None
    
    input = open_uri(config['obi']['inputURI'])
    if input is None:
        raise Exception("Could not open input reads")
    if input[2] != View_NUC_SEQS:
        raise NotImplementedError('obi alignpairedend only works on NUC_SEQS views')    
    
    if "reverse" in config["alignpairedend"]:
        
        two_views = True
        
        forward = input[1]        
        
        rinput = open_uri(config["alignpairedend"]["reverse"])
        if rinput is None:
            raise Exception("Could not open reverse reads")
        if rinput[2] != View_NUC_SEQS:
            raise NotImplementedError('obi alignpairedend only works on NUC_SEQS views')
        
        reverse = rinput[1]
    
        if len(forward) != len(reverse):
            raise Exception("Error: the number of forward and reverse reads are different")
        
        entries = [forward, reverse]
        input_dms_name = [forward.dms.name, reverse.dms.name]
        input_view_name = [forward.name, reverse.name]
    
    else:
        entries = input[1]
        input_dms_name = [entries.dms.name]
        input_view_name = [entries.name]

    if two_views:
        entries_len = len(forward)
    else:
        entries_len = len(entries)
    
    # Open the output
    output = open_uri(config['obi']['outputURI'],
                      input=False,
                      newviewtype=View_NUC_SEQS)
    if output is None:
        raise Exception("Could not create output view")

    view = output[1]
    
    Column.new_column(view, QUALITY_COLUMN, OBI_QUAL)   #TODO output URI quality option?

    if 'smin' in config['alignpairedend']:
        smin = config['alignpairedend']['smin']
    else:
        smin = 0

    # Initialize the progress bar
    pb = ProgressBar(entries_len, config, seconde=5)
    
    #if config['alignpairedend']['trueali']:
    #    kmer_ali = False
    #    aligner = buildAlignment
    #else :
    kmer_ali = True
    if type(entries) == list:
        forward = entries[0]
        reverse = entries[1]
        aligner = Kmer_similarity(forward, \
                                  view2=reverse, \
                                  kmer_size=config['alignpairedend']['kmersize'], \
                                  reversed_column=None)
    else:
        aligner = Kmer_similarity(entries, \
                                  column2=entries[REVERSE_SEQUENCE_COLUMN], \
                                  qual_column2=entries[REVERSE_QUALITY_COLUMN], \
                                  kmer_size=config['alignpairedend']['kmersize'], \
                                  reversed_column=entries[b'reversed'])  # column created by the ngsfilter tool
        
    ba = alignmentIterator(entries, aligner)

    i = 0
    for ali in ba:
        
        pb(i)
        
        PyErr_CheckSignals()

        consensus = view[i]
               
        if not two_views:
            seqF = entries[i]
        else:
            seqF = forward[i]
                        
        if ali.score > smin and ali.consensus_len > 0 :
            buildConsensus(ali, consensus, seqF)
        else:
            if not two_views:
                seqR = Nuc_Seq(seqF.id, seqF[REVERSE_SEQUENCE_COLUMN], quality = seqF[REVERSE_QUALITY_COLUMN])
            else:
                seqR = reverse[i]
            buildJoinedSequence(ali, seqR, consensus, forward=seqF)
        
        consensus[b"smin"] = smin
           
        if kmer_ali :
            ali.free()
    
        i+=1

    pb(i, force=True)
    print("", file=sys.stderr)

    if kmer_ali :
        aligner.free()

    # Save command config in View and DMS comments
    command_line = " ".join(sys.argv[1:])
    view.write_config(config, "alignpairedend", command_line, input_dms_name=input_dms_name, input_view_name=input_view_name)
    output[0].record_command_line(command_line)

    #print("\n\nOutput view:\n````````````", file=sys.stderr)
    #print(repr(view), file=sys.stderr)
    
    input[0].close()
    if two_views:
        rinput[0].close()
    output[0].close()

    logger("info", "Done.")
    