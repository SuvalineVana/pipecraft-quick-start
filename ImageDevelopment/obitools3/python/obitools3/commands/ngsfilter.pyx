#cython: language_level=3

from obitools3.apps.progress cimport ProgressBar  # @UnresolvedImport
from obitools3.dms import DMS
from obitools3.dms.view import RollbackException
from obitools3.dms.view.typed_view.view_NUC_SEQS cimport View_NUC_SEQS
from obitools3.dms.column.column cimport Column, Column_line
from obitools3.apps.optiongroups import addMinimalInputOption, addMinimalOutputOption
from obitools3.uri.decode import open_uri
from obitools3.apps.config import logger
from obitools3.libalign._freeendgapfm import FreeEndGapFullMatch
from obitools3.libalign.apat_pattern import Primer_search
from obitools3.dms.obiseq cimport Nuc_Seq
from obitools3.dms.capi.obitypes cimport OBI_SEQ, OBI_QUAL
from obitools3.dms.capi.apat cimport MAX_PATTERN
from obitools3.dms.capi.obiview cimport REVERSE_SEQUENCE_COLUMN, REVERSE_QUALITY_COLUMN
from obitools3.utils cimport tobytes

from libc.stdint cimport INT32_MAX
from functools import reduce
import math
import sys
from cpython.exc cimport PyErr_CheckSignals


#REVERSE_SEQ_COLUMN_NAME = b"REVERSE_SEQUENCE"      # used by alignpairedend tool
#REVERSE_QUALITY_COLUMN_NAME = b"REVERSE_QUALITY"   # used by alignpairedend tool


__title__="Assigns sequence records to the corresponding experiment/sample based on DNA tags and primers"


def addOptions(parser):

    addMinimalInputOption(parser)
    addMinimalOutputOption(parser)
 
    group = parser.add_argument_group('obi ngsfilter specific options')

    group.add_argument('-t','--info-view',
                     action="store", dest="ngsfilter:info_view",
                     metavar="<URI>",
                     type=str,
                     default=None,
                     help="URI to the view containing the samples definition (with tags, primers, sample names,...)")

    group.add_argument('-R', '--reverse-reads',
                     action="store", dest="ngsfilter:reverse",
                     metavar="<URI>",
                     default=None,
                     type=str,
                     help="URI to the reverse reads if the paired-end reads haven't been aligned yet")

    group.add_argument('-u','--unidentified',
                     action="store", dest="ngsfilter:unidentified",
                     metavar="<URI>",
                     type=str,
                     default=None,
                     help="URI to the view used to store the sequences unassigned to any sample")

    group.add_argument('--no-tags',
                     action="store_true", dest="ngsfilter:notags",
                     default=False,
                     help="Use this option if your experiment does not use tags to identify samples")
    
    group.add_argument('-e','--error',
                     action="store", dest="ngsfilter:error",
                     metavar="###",
                     type=int,
                     default=2,
                     help="Number of errors allowed for matching primers [default = 2]")


class Primer:
    
    collection={}
    
    def __init__(self, sequence, taglength, forward=True, max_errors=2, verbose=False, primer_pair_idx=0, primer_idx=0):
        '''
            
        @param sequence:
        @type sequence:
        @param direct:
        @type direct:
        '''
        
        assert sequence not in Primer.collection        \
            or Primer.collection[sequence]==taglength,  \
            "Primer %s must always be used with tags of the same length" % sequence
            
        Primer.collection[sequence]=taglength
        
        self.primer_pair_idx = primer_pair_idx
        self.primer_idx = primer_idx
        self.is_revcomp = False
        self.revcomp = None
        self.raw=sequence
        self.sequence = Nuc_Seq(b"primer", sequence)        
        self.lseq = len(self.sequence)
        self.max_errors=max_errors
        self.taglength=taglength
        self.forward = forward
        self.verbose=verbose
        
    def reverse_complement(self):
        p = Primer(self.raw,
                   self.taglength,
                   not self.forward,
                   verbose=self.verbose,
                   max_errors=self.max_errors,
                   primer_pair_idx=self.primer_pair_idx,
                   primer_idx=self.primer_idx)
        p.sequence=p.sequence.reverse_complement
        p.is_revcomp = True
        p.revcomp = None
        return p
    
    def __hash__(self):
        return hash(str(self.raw))
    
    def __eq__(self,primer):
        return self.raw==primer.raw 
    
    def __call__(self, sequence, same_sequence=False, pattern=0, begin=0):
        
        if len(sequence) <= self.lseq:
            return None
                
        ali = self.aligner.search_one_primer(sequence.seq, 
                                             self.primer_pair_idx, 
                                             self.primer_idx, 
                                             reverse_comp=self.is_revcomp, 
                                             same_sequence=same_sequence,
                                             pattern_ref=pattern,
                                             begin=begin)
        
        if ali is None:  # no match
            return None 
            
        errors, start = ali.first_encountered()
                
        if errors <= self.max_errors:
            end = start + self.lseq
            if self.taglength is not None:
                if self.sequence.is_revcomp:
                    if (len(sequence)-end) >= self.taglength:
                        tag_start = len(sequence) - end - self.taglength
                        tag = sequence.reverse_complement[tag_start:tag_start+self.taglength].seq
                    else:
                        tag=None
                else:
                    if start >= self.taglength:
                        tag = tobytes((sequence[start - self.taglength:start].seq).lower())  # turn back to lowercase because apat turned to uppercase
                    else:
                        tag=None
            else:
                tag=None
            
            return errors,start,end,tag

        return None 
    
    
    def __str__(self):
        return "%s: %s" % ({True:'D',False:'R'}[self.forward],self.raw)
    
    __repr__=__str__


cdef read_info_view(info_view, max_errors=2, verbose=False, not_aligned=False):
    infos = {}
    primer_list = []
    i=0
    for p in info_view:
        forward=Primer(p[b'forward_primer'],
                       len(p[b'forward_tag']) if (b'forward_tag' in p and p[b'forward_tag']!=None) else None,
                       True,
                       max_errors=max_errors,
                       verbose=verbose,
                       primer_pair_idx=i,
                       primer_idx=0)
        
        fp = infos.get(forward,{})
        infos[forward]=fp
        
        reverse=Primer(p[b'reverse_primer'],
                       len(p[b'reverse_tag']) if (b'reverse_tag' in p and p[b'reverse_tag']!=None) else None,
                       False,
                       max_errors=max_errors,
                       verbose=verbose,
                       primer_pair_idx=i,
                       primer_idx=1)

        primer_list.append((p[b'forward_primer'], p[b'reverse_primer']))
        
        rp = infos.get(reverse,{})
        infos[reverse]=rp
        
        if not_aligned:
            cf=forward
            cr=reverse
            
            cf.revcomp = forward.reverse_complement()
            cr.revcomp = reverse.reverse_complement()

            dpp=fp.get(cr,{})
            fp[cr]=dpp
            
            rpp=rp.get(cf,{})
            rp[cf]=rpp
        
        else:
            cf=forward.reverse_complement()
            cr=reverse.reverse_complement()
            
            dpp=fp.get(cr,{})
            fp[cr]=dpp
             
            rpp=rp.get(cf,{})
            rp[cf]=rpp

        tags = (p[b'forward_tag'] if (b'forward_tag' in p and p[b'forward_tag']!=None) else None,
                p[b'reverse_tag'] if (b'reverse_tag' in p and p[b'reverse_tag']!=None) else None)
        
        if tags != (None, None):
            assert tags not in dpp, \
               "Tag pair %s is already used with primer pairs: (%s,%s)" % (str(tags),forward,reverse)
        
        # Save additional data
        special_keys = [b'forward_primer', b'reverse_primer', b'forward_tag', b'reverse_tag']
        data={}
        for key in p:
            if key not in special_keys:
                data[key] = p[key]
                            
        dpp[tags] = data
        rpp[tags] = data
        
        i+=1
        
    return infos, primer_list
    

cdef tuple annotate(sequences, infos, no_tags, verbose=False):
        
    def sortMatch(match):
        if match[1] is None:
            return INT32_MAX
        else:
            return match[1][1]

    def sortReverseMatch(match):
        if match[1] is None:
            return -1
        else:
            return match[1][1]
    
    not_aligned = len(sequences) > 1
    sequences[0] = sequences[0].clone()

    if not_aligned:
        sequences[1] = sequences[1].clone()
        sequences[0][REVERSE_SEQUENCE_COLUMN] = sequences[1].seq             # used by alignpairedend tool
        sequences[0][REVERSE_QUALITY_COLUMN] = sequences[1].quality     # used by alignpairedend tool

    for seq in sequences:
        if hasattr(seq, "quality_array"): 
            q = -reduce(lambda x,y:x+y,(math.log10(z) for z in seq.quality_array),0)/len(seq.quality_array)*10
            seq[b'avg_quality']=q
            q = -reduce(lambda x,y:x+y,(math.log10(z) for z in seq.quality_array[0:10]),0)
            seq[b'head_quality']=q
            if len(seq.quality_array[10:-10]) :
                q = -reduce(lambda x,y:x+y,(math.log10(z) for z in seq.quality_array[10:-10]),0)/len(seq.quality_array[10:-10])*10
                seq[b'mid_quality']=q
            q = -reduce(lambda x,y:x+y,(math.log10(z) for z in seq.quality_array[-10:]),0)
            seq[b'tail_quality']=q
    
    # Try direct matching:
    directmatch = []
    for seq in sequences:
        new_seq = True
        pattern = 0
        for p in infos:
            if pattern == MAX_PATTERN:
                new_seq = True
                pattern = 0
            # Saving original primer as 4th member of the tuple to serve as correct key in infos dict even if it might be reversed complemented (not here)
            directmatch.append((p, p(seq, same_sequence=not new_seq, pattern=pattern), seq, p))
            new_seq = False
            pattern+=1
    
    # Choose match closer to the start of (one of the) sequence(s)
    directmatch = sorted(directmatch, key=sortMatch)
    all_direct_matches = directmatch
    directmatch = directmatch[0] if directmatch[0][1] is not None else None

    if directmatch is None:
        if not_aligned:
            sequences[0][REVERSE_SEQUENCE_COLUMN] = sequences[1].seq             # used by alignpairedend tool
            sequences[0][REVERSE_QUALITY_COLUMN] = sequences[1].quality     # used by alignpairedend tool
        sequences[0][b'error']=b'No primer match'
        return False, sequences[0]

    if id(directmatch[2]) == id(sequences[0]):
        first_match_first_seq = True
    else:
        first_match_first_seq = False
       
    match = directmatch[2][directmatch[1][1]:directmatch[1][2]]
    
    if not not_aligned:
        sequences[0][b'seq_length_ori']=len(sequences[0])
    
    if not not_aligned or first_match_first_seq:
        sequences[0] = sequences[0][directmatch[1][2]:]
    else:
        sequences[1] = sequences[1][directmatch[1][2]:]
        sequences[0][REVERSE_SEQUENCE_COLUMN] = sequences[1].seq           # used by alignpairedend tool
        sequences[0][REVERSE_QUALITY_COLUMN] = sequences[1].quality   # used by alignpairedend tool
    
    if directmatch[0].forward:
        sequences[0][b'direction']=b'forward'
        sequences[0][b'forward_errors']=directmatch[1][0]
        sequences[0][b'forward_primer']=directmatch[0].raw
        sequences[0][b'forward_match']=match.seq
        
    else:
        sequences[0][b'direction']=b'reverse'
        sequences[0][b'reverse_errors']=directmatch[1][0]
        sequences[0][b'reverse_primer']=directmatch[0].raw
        sequences[0][b'reverse_match']=match.seq

    # Keep only paired reverse primer
    infos = infos[directmatch[0]]
    reverse_primer = list(infos.keys())[0]
    direct_primer = directmatch[0]
        
    # If not aligned, look for other match in already computed matches (choose the one that makes the biggest amplicon)
    if not_aligned:
        i=1
        # TODO comment
        while i<len(all_direct_matches) and \
            (all_direct_matches[i][1] is None or \
             all_direct_matches[i][0].forward == directmatch[0].forward or \
             all_direct_matches[i][0] == directmatch[0] or \
             reverse_primer != all_direct_matches[i][0]) :
            i+=1
        if i < len(all_direct_matches):
            reversematch = all_direct_matches[i]
        else:
            reversematch = None
        
    # Cut reverse primer out of 1st matched seq if it contains it, because if it's also in the other sequence, the next step will "choose" only the one on the other sequence
    if not_aligned:
        # do it on same seq
        if first_match_first_seq:
            r = reverse_primer.revcomp(sequences[0])
        else:
            r = reverse_primer.revcomp(sequences[1]) 
        if r is not None: # found
            if first_match_first_seq :
                sequences[0] = sequences[0][:r[1]]
            else:
                sequences[1] = sequences[1][:r[1]]
                sequences[0][REVERSE_SEQUENCE_COLUMN] = sequences[1].seq           # used by alignpairedend tool
                sequences[0][REVERSE_QUALITY_COLUMN] = sequences[1].quality   # used by alignpairedend tool
        # do the same on the other seq
        if first_match_first_seq: 
            r = direct_primer.revcomp(sequences[1])
        else:
            r = direct_primer.revcomp(sequences[0])
        if r is not None: # found
            if first_match_first_seq:
                sequences[1] = sequences[1][:r[1]]
            else:
                sequences[0] = sequences[0][:r[1]] 
                sequences[0][REVERSE_SEQUENCE_COLUMN] = sequences[1].seq
                sequences[0][REVERSE_QUALITY_COLUMN] = sequences[1].quality
    
    
    # Look for other primer in the other direction on the sequence, or
    # If sequences are not already aligned and reverse primer not found in most likely sequence (the one without the forward primer), try matching on the same sequence than the first match (primer in the other direction)
    if not not_aligned or (not_aligned and (reversematch is None or reversematch[1] is None)):
        if not_aligned and first_match_first_seq:
            seq_to_match = sequences[1]
        else:
            seq_to_match = sequences[0]
        reversematch = []
        # Compute begin
        begin=directmatch[1][2]+1  # end of match + 1 on the same sequence
        # Try reverse matching on the other sequence:
        new_seq = True
        pattern = 0
        for p in infos:
            if pattern == MAX_PATTERN:
                new_seq = True
                pattern = 0
            if not_aligned:
                primer=p.revcomp
            else:
                primer=p
            # Saving original primer as 4th member of the tuple to serve as correct key in infos dict even if it might have been reversed complemented
            # (3rd member already used by directmatch)
            reversematch.append((primer, primer(seq_to_match, same_sequence=not new_seq, pattern=pattern, begin=begin), None, p))
            new_seq = False
            pattern+=1
        # Choose match closer to the end of the sequence
        reversematch = sorted(reversematch, key=sortReverseMatch, reverse=True)
        all_reverse_matches = reversematch
        reversematch = reversematch[0] if reversematch[0][1] is not None else None
        
    if reversematch is None and None not in infos:
        if directmatch[0].forward:
            message = b'No reverse primer match'
        else:
            message = b'No direct primer match'
        sequences[0][b'error']=message
        return False, sequences[0]
    
    if reversematch is None:
        sequences[0][b'status']=b'partial'
        
        if directmatch[0].forward:
            tags=(directmatch[1][3],None)
        else:
            tags=(None,directmatch[1][3])
            
        samples = infos[None]
        
    else:
        sequences[0][b'status']=b'full'
        
        if not not_aligned or first_match_first_seq:
            match = sequences[0][reversematch[1][1]:reversematch[1][2]]
        else:
            match = sequences[1][reversematch[1][1]:reversematch[1][2]]
        
        match = match.reverse_complement
        
        if not not_aligned:
            sequences[0] = sequences[0][0:reversematch[1][1]]
        elif first_match_first_seq:
            sequences[1] = sequences[1][reversematch[1][2]:]
            if not directmatch[0].forward:
                sequences[1] = sequences[1].reverse_complement
            sequences[0][REVERSE_SEQUENCE_COLUMN] = sequences[1].seq           # used by alignpairedend tool
            sequences[0][REVERSE_QUALITY_COLUMN] = sequences[1].quality   # used by alignpairedend tool
        else:
            sequences[0] = sequences[0][reversematch[1][2]:]
            
        if directmatch[0].forward:
            tags=(directmatch[1][3], reversematch[1][3])
            sequences[0][b'reverse_errors'] = reversematch[1][0]
            sequences[0][b'reverse_primer'] = reversematch[0].raw
            sequences[0][b'reverse_match'] = match.seq
        
        else:
            tags=(reversematch[1][3], directmatch[1][3])
            sequences[0][b'forward_errors'] = reversematch[1][0]
            sequences[0][b'forward_primer'] = reversematch[0].raw
            sequences[0][b'forward_match'] = match.seq
                
        if tags[0] is not None:
            sequences[0][b'forward_tag'] = tags[0]
        if tags[1] is not None:
            sequences[0][b'reverse_tag'] = tags[1]

        samples = infos[reversematch[3]]
        
    if not directmatch[0].forward:
        sequences[0] = sequences[0].reverse_complement
        sequences[0][b'reversed'] = True   # used by the alignpairedend tool (in kmer_similarity.c)

    sample=None
    if not no_tags:
        if tags[0] is not None:                                    # Direct  tag known
            if tags[1] is not None:                                # Reverse tag known
                sample = samples.get(tags, None)             
            else:                                                   # Only direct tag known
                s=[samples[x] for x in samples if x[0]==tags[0]]
                if len(s)==1:
                    sample=s[0]
                elif len(s)>1:
                    sequences[0][b'error']=b'Did not found reverse tag'
                    return False, sequences[0]
                else:
                    sample=None
        else: 
            if tags[1] is not None:                                 # Only reverse tag known
                s=[samples[x] for x in samples if x[1]==tags[1]]
                if len(s)==1:
                    sample=s[0]
                elif len(s)>1:
                    sequences[0][b'error']=b'Did not found forward tag'
                    return False, sequences[0]
                else:
                    sample=None
        
        if sample is None:
            sequences[0][b'error']=b"No tags found"
            return False, sequences[0]
    
        sequences[0].update(sample)
    
    if not not_aligned:
        sequences[0][b'seq_length']=len(sequences[0])
    
    return True, sequences[0]


def run(config):
        
    DMS.obi_atexit()
    
    logger("info", "obi ngsfilter")

    assert config['ngsfilter']['info_view'] is not None, "Option -t must be specified"

    # Open the input
    
    forward = None
    reverse = None
    input = None
    not_aligned = False
    
    input = open_uri(config['obi']['inputURI'])
    if input is None:
        raise Exception("Could not open input reads")
    if input[2] != View_NUC_SEQS:
        raise NotImplementedError('obi ngsfilter only works on NUC_SEQS views')

    if "reverse" in config["ngsfilter"]:
        
        forward = input[1]        
        
        rinput = open_uri(config["ngsfilter"]["reverse"])
        if rinput is None:
            raise Exception("Could not open reverse reads")
        if rinput[2] != View_NUC_SEQS:
            raise NotImplementedError('obi ngsfilter only works on NUC_SEQS views')
        
        reverse = rinput[1]
    
        if len(forward) != len(reverse):
            raise Exception("Error: the number of forward and reverse reads are different")
        
        entries = [forward, reverse]
        not_aligned = True

        input_dms_name = [forward.dms.name, reverse.dms.name]
        input_view_name = [forward.name, reverse.name]
    
    else:
        entries = input[1]
        input_dms_name = [entries.dms.name]
        input_view_name = [entries.name]

    
    if not_aligned:
        entries_len = len(forward)
    else:
        entries_len = len(entries)
    
    # Open the output
    output = open_uri(config['obi']['outputURI'],
                      input=False,
                      newviewtype=View_NUC_SEQS)
    
    if output is None:
        raise Exception("Could not create output view")
    
    o_view = output[1]
    
    # Open the view containing the informations about the tags and the primers
    info_input = open_uri(config['ngsfilter']['info_view'])
    if info_input is None:
        raise Exception("Could not read the view containing the informations about the tags and the primers")
    info_view = info_input[1]
    input_dms_name.append(info_input[0].name)   
    input_view_name.append(info_input[1].name)

    # Open the unidentified view
    if 'unidentified' in config['ngsfilter'] and config['ngsfilter']['unidentified'] is not None:  # TODO keyError if undefined problem
        unidentified_input = open_uri(config['ngsfilter']['unidentified'],
                                      input=False,
                                      newviewtype=View_NUC_SEQS)
        if unidentified_input is None:
            raise Exception("Could not open the view containing the unidentified reads")
        unidentified = unidentified_input[1]
    else:
        unidentified = None
        
    # Initialize the progress bar
    pb = ProgressBar(entries_len, config, seconde=5)

    # Check and store primers and tags
    infos, primer_list = read_info_view(info_view, max_errors=config['ngsfilter']['error'], verbose=False, not_aligned=not_aligned)   # TODO obi verbose option
    
    aligner = Primer_search(primer_list, config['ngsfilter']['error'])
    
    for p in infos:
        p.aligner = aligner
        for paired_p in infos[p]:
            paired_p.aligner = aligner
            if paired_p.revcomp is not None:
                paired_p.revcomp.aligner = aligner
    
    if not_aligned:   # create columns used by alignpairedend tool
        Column.new_column(o_view, REVERSE_SEQUENCE_COLUMN, OBI_SEQ)
        Column.new_column(o_view, REVERSE_QUALITY_COLUMN, OBI_QUAL, associated_column_name=REVERSE_SEQUENCE_COLUMN, associated_column_version=o_view[REVERSE_SEQUENCE_COLUMN].version)
        
        if unidentified is not None:
            Column.new_column(unidentified, REVERSE_SEQUENCE_COLUMN, OBI_SEQ)
            Column.new_column(unidentified, REVERSE_QUALITY_COLUMN, OBI_QUAL, associated_column_name=REVERSE_SEQUENCE_COLUMN, associated_column_version=unidentified[REVERSE_SEQUENCE_COLUMN].version)
    
    g = 0
    u = 0
    no_tags = config['ngsfilter']['notags']
    try:
        for i in range(entries_len):
            PyErr_CheckSignals()
            pb(i)
            if not_aligned:
                modseq = [Nuc_Seq.new_from_stored(forward[i]), Nuc_Seq.new_from_stored(reverse[i])]
            else:
                modseq = [Nuc_Seq.new_from_stored(entries[i])]
            good, oseq = annotate(modseq, infos, no_tags)
            if good:
                o_view[g].set(oseq.id, oseq.seq, definition=oseq.definition, quality=oseq.quality, tags=oseq)
                g+=1
            elif unidentified is not None:
                unidentified[u].set(oseq.id, oseq.seq, definition=oseq.definition, quality=oseq.quality, tags=oseq)
                u+=1
    except Exception, e:
        if unidentified is not None:
            raise RollbackException("obi ngsfilter error, rollbacking views: "+str(e), o_view, unidentified)
        else:
            raise RollbackException("obi ngsfilter error, rollbacking view: "+str(e), o_view)
    
    pb(i, force=True)
    print("", file=sys.stderr)

    # Save command config in View and DMS comments
    command_line = " ".join(sys.argv[1:])
    o_view.write_config(config, "ngsfilter", command_line, input_dms_name=input_dms_name, input_view_name=input_view_name)
    if unidentified is not None:
        unidentified.write_config(config, "ngsfilter", command_line, input_dms_name=input_dms_name, input_view_name=input_view_name)
        # Add comment about unidentified seqs
        unidentified.comments["info"] = "View containing sequences categorized as unidentified by the ngsfilter command"
    output[0].record_command_line(command_line)
    
    #print("\n\nOutput view:\n````````````", file=sys.stderr)
    #print(repr(o_view), file=sys.stderr)

    input[0].close()
    output[0].close()
    info_input[0].close()
    if unidentified is not None:
        unidentified_input[0].close()
    aligner.free()

    logger("info", "Done.")
