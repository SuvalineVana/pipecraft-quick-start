#cython: language_level=3

from urllib.parse import urlparse, urlunparse, parse_qs, ParseResultBytes
from os.path import isdir, isfile, basename, join

import sys

from obitools3.dms.dms import DMS

from obitools3.parsers.fasta import fastaNucIterator
from obitools3.parsers.fastq import fastqIterator
from obitools3.parsers.tab import tabIterator
from obitools3.parsers.ngsfilter import ngsfilterIterator
from obitools3.parsers.embl import emblIterator
from obitools3.parsers.genbank import genbankIterator
from obitools3.parsers.universal import entryIteratorFactory

from obitools3.writers.fasta import FastaNucWriter
from obitools3.writers.fastq import FastqWriter
from obitools3.writers.tab import TabWriter
from obitools3.format.fasta import FastaFormat
from obitools3.format.fastq import FastqFormat
from obitools3.format.tab import TabFormat

from obitools3.dms.obiseq import Nuc_Seq
from obitools3.apps.config import getConfiguration,logger
from obitools3.apps.temp import get_temp_dms
from obitools3.utils cimport tobytes, count_entries  # TODO tobytes because can't read options as bytes

from obitools3.files.universalopener cimport uopen

from obitools3.dms.capi.obierrno cimport obi_errno, \
                                         OBIVIEW_ALREADY_EXISTS_ERROR


class MalformedURIException(RuntimeError):
    pass

cdef open_dms(bytes path, bint create=False):
    """
    Opens a DMS from the path part of an URI
    """
    cdef int pos=1
    cdef bytes dmspath
    cdef bytes dmsdirname
    cdef bytes dmsname

    while(pos>0):
        pos = path.find(b"/",pos)
        if pos>0:
            dmspath=path[0:pos]
        else:
            dmspath=path
        if not isdir(dmspath):
            dmsdirname=dmspath+b".obidms"
            if isdir(dmsdirname):
                dmsname=basename(dmspath)
                if isfile(join(dmsdirname,dmsname+b"_infos")):
                    dms = DMS.open(dmspath)
                    if pos > 0:
                        return(dms,path[pos+1:])
                    else:
                        return(dms,b'')
            elif create:
                dms=DMS.new(dmspath)
                if pos > 0:
                    return(dms,path[pos+1:])
                else:
                    return(dms,b'')
                
        pos=pos+1
    return None


def open_dms_element(DMS dms, 
                     bytes path, 
                     bint create=False,
                     type newviewtype=View):
    """
    """
    cdef list path_parts = path.split(b'/')

    # The URI is only composed of a DMS
    if not path:
        return (dms,dms)
    
    # The URI targets a taxonomy
    # dms:dmspath/taxonomy/taxoname[/taxid]
    if path_parts[0]==b"taxonomy":
        if len(path_parts) > 1:
            if Taxonomy.exists(dms, path_parts[1]):
                taxo = Taxonomy.open(dms, path_parts[1])
                if len(path_parts) == 3:
                    taxon=taxo[int(path_parts[2])]
                    return (dms, taxon)
                elif len(path_parts) > 3:
                    raise MalformedURIException('Malformed Taxonomy URI')
            else:
                return (dms, path_parts[1])   # return prefix for creation eventually
            return (dms, taxo)

    # The URI targets a view
    # dms:dmspath/viewname[/columnname|#line|*[/#line|columnname|*[/subcolumn]]]
    
    if create:
        view = newviewtype.new(dms,path_parts[0])
    else:
        view = newviewtype.open(dms,path_parts[0])
        
    if len(path_parts) > 1:
        if path_parts[1]==b'*':
            if len(path_parts) == 2:
                return (dms,view)
            else:
                column = view[path_parts[2]]
                if len(path_parts) == 3:
                    return (dms,column)
                elif len(path_parts) == 4:
                    raise NotImplementedError()
                else:
                    raise MalformedURIException('Malformed View  * URI')
        try:
            part = int(path_parts[1])
        except ValueError:
            part = path_parts[1]
        part = view[part]
    else:
        return (dms,view)
        
    if len(path_parts) > 2:    
        if isinstance(part, Column):
            if path_parts[2]==b"*":
                if len(path_parts) == 4:
                    raise NotImplementedError()
                elif len(path_parts) == 3:
                    return (dms,part)
                else:
                    raise MalformedURIException('Malformed View * URI')
            else:
                subpart = part[int(path_parts[2])]
        else:
            subpart = part[path_parts[2]]
    else:
        return (dms,part)
    
    if len(path_parts) > 3:
        try:
            subsubpart = int(path_parts[3])
        except ValueError:
            subsubpart = path_parts[3]
        subsubpart = subpart[subsubpart]
    else:
        return (dms,subpart)
    
    # URI with too many sub-parts
    if len(path_parts) > 4:
            raise MalformedURIException('Malformed View URI')
    
    return (dms, subsubpart)
                         

'''  
#TODO discuss returned object. Return a dict? or some class instance?
Reads an URI and returns a tuple containing:
    (1) The opened file or DMS, or the URI itself if nothing could be opened by the function
    (2) The opened view or iterator on the opened file or writer
    (3) The class of object returned or handled by (2)
    (4) The original URI in bytes
    (5) The number of entries (if input URI) or -1 if unavailable
'''
def open_uri(uri,
             bint input=True,
             type newviewtype=View,
             dms_only=False,
             force_file=False):
    
    cdef bytes urib = tobytes(uri)
    cdef bytes scheme
    cdef tuple dms
    cdef dict qualifiers
    cdef DMS default_dms
    
    if urib is None:
        urib = b""
    
    # Reformat URI if it was built with autocomplete
    urib = urib.replace(b".obidms", b"")
    urib = urib.replace(b".obiview", b"")
    urib = urib.replace(b".obicol", b"")
    urib = urib.replace(b"/VIEWS", b"")
    urib = urib.replace(b"TAXONOMY", b"taxonomy")
    
    config = getConfiguration()
    urip = urlparse(urib)
            
    if 'obi' not in config:
        config['obi']={}
    
    if not force_file and "defaultdms" in config["obi"]:
        default_dms=config["obi"]["defaultdms"]
    else:
        default_dms=None
        
    try:
        create=(not input) and (not config["obi"]["nocreatedms"])
    except KeyError:
        create=not input
    
    scheme = urip.scheme
    
    error = None
    
    if scheme==b"dms" or \
        (scheme==b"" and \
         (((not input) and "outputformat" not in config["obi"]) or \
         (input and "inputformat" not in config["obi"]))):   # TODO maybe not best way
        
        if default_dms is not None and b"/" not in urip.path:   # assuming view to open in default DMS (TODO discuss)
            dms=(default_dms, urip.path)
        else:
            dms = open_dms(urip.path, create)
        
        if dms is None and default_dms is not None:
            dms=(default_dms, urip.path)

        if dms is not None:
            if dms_only:
                return (dms[0],
                        dms[1],
                        type(dms[1]),
                        urlunparse(urip),
                        len(dms[0]))
            #if dms[1]:
            try:
                resource=open_dms_element(dms[0],
                                          dms[1],
                                          create,
                                          newviewtype)
                                
                scheme=b"dms"
                urip = ParseResultBytes(scheme=b"dms", 
                                        netloc=urip.netloc, 
                                        path=urip.path,
                                        params=urip.params, 
                                        query=urip.query, 
                                        fragment=urip.fragment)
                
                if default_dms is None:
                    config["obi"]["defaultdms"]=resource[0]
                                
                return (resource[0],
                        resource[1],
                        type(resource[1]),
                        urlunparse(urip),
                        len(resource[1]))
            except Exception as e:
                global obi_errno
                if obi_errno == OBIVIEW_ALREADY_EXISTS_ERROR:
                    raise Exception("View name already exists in this DMS")
                error=e
         
    if scheme==b"dms" :
        logger('Error','Could not open DMS URI: %s', uri)
        raise FileNotFoundError()

    if not urip.scheme:
        urib=b"file:"+urib
    
    if input:
        try:
            file = uopen(urip.path, mode='rb')
            logger('info','Opened file: %s', tostr(urip.path))
        except Exception as e:  # TODO discuss: if can't open file, return the character string itself
            file = tobytes(uri)
            iseq = urib
            objclass = bytes
    else:  # TODO update uopen to be able to write? 
        if urip.path:
            file = open(urip.path, 'wb')
        else:
            file = sys.stdout.buffer
        
    if file is not None:
        qualifiers=parse_qs(urip.query)
        
        if input and b'format' in qualifiers:
            format = qualifiers[b'format'][0]
        else:   # TODO discuss priorities
            if urip.scheme:
                format = urip.scheme
            else:
                try:
                    if input:
                        formatkey = "inputformat"
                    else:
                        formatkey = "outputformat"
                    format=config["obi"][formatkey]
                except KeyError:
                    format=None
                
        if b'seqtype' in qualifiers:
            seqtype=qualifiers[b'seqtype'][0]
        else:
            if format == b"ngsfilter" or format == b"tabular":  # TODO discuss
                seqtype=None
            else:
                try:
                    seqtype=config["obi"]["seqtype"]
                except KeyError:
                    seqtype=b"nuc"
        config["obi"]["seqtype"] = seqtype
        
        if b'skip' in qualifiers:
            skip=int(qualifiers[b"skip"][0])
        else:
            try:
                skip=config["obi"]["skip"]
            except KeyError:
                skip=0
        if skip < 0:    
            raise MalformedURIException('Malformed skip argument in URI')
        
        if b'only' in qualifiers:
            only=int(qualifiers[b"only"][0])
        else:
            try:
                only=config["obi"]["only"]
            except KeyError:
                only=None
        if only is not None and only <= 0:    
            raise MalformedURIException('Malformed only argument in URI')
        
        if b"skiperror" in qualifiers:
            try:
                skiperror=eval(qualifiers[b"skiperror"][0])
            except Exception as e:
                raise MalformedURIException('Malformed skiperror argument in URI')
        else:
            try:
                skiperror=config["obi"]["skiperror"]
            except KeyError:
                skiperror=True
        if not isinstance(skiperror, bool):    
            raise MalformedURIException('Malformed skiperror argument in URI')
      
        if b"noquality" in qualifiers:
            try:
                noquality=eval(qualifiers[b"noquality"][0])
            except Exception as e:
                raise MalformedURIException('Malformed noquality argument in URI')
        else:
            try:
                noquality=config["obi"]["noquality"]
            except KeyError:
                noquality=False
        if not isinstance(noquality, bool):    
            raise MalformedURIException('Malformed noquality argument in URI')
      
        if b"qualityformat" in qualifiers:
            if qualifiers[b"qualityformat"][0]==b"sanger":
                offset=33
            elif qualifiers[b"qualityformat"][0]==b"solexa":
                offset=64
        else:
            try:
                if config["obi"]["qualityformat"]==b"sanger":
                    offset=33
                elif config["obi"]["qualityformat"]==b"solexa":
                    offset=64
                #offset=config["obi"]["offset"]   # TODO discuss
            except KeyError:
                offset=33
        
        if b"header" in qualifiers:
            try:
                header=eval(qualifiers[b"header"][0])
            except Exception as e:
                raise MalformedURIException('Malformed header argument in URI')
        else:
            try:
                header=config["obi"]["header"]
            except KeyError:
                header=False
        if not isinstance(header, bool):    
            raise MalformedURIException('Malformed header argument in URI')
       
        if b"sep" in qualifiers:
            sep=tobytes(qualifiers[b"sep"][0][0])
        else:
            try:
                sep=tobytes(config["obi"]["sep"])
            except KeyError:
                sep=None
        
#        if b"quote" in qualifiers:
#            pass

        if b"dec" in qualifiers:
            dec=tobytes(qualifiers[b"dec"][0][0])
        else:
            try:
                dec=tobytes(config["obi"]["dec"])
            except KeyError:
                dec=b"."

        if b"printna" in qualifiers:
            try:
                printna=eval(qualifiers[b"printna"][0])
            except Exception as e:
                raise MalformedURIException("Malformed 'print NA' argument in URI")
        else:
            try:
                printna=config["obi"]["printna"]
            except KeyError:
                printna=False
        
        if b"nastring" in qualifiers:
            nastring=tobytes(qualifiers[b"nastring"][0])
        else:
            try:
                if input:
                    nakey = "inputnastring"
                else:
                    nakey = "outputnastring"
                nastring=tobytes(config["obi"][nakey])
            except KeyError:
                nastring=b'NA'
                
        if b"stripwhite" in qualifiers:
            try:
                stripwhite=eval(qualifiers[b"stripwhite"][0])
            except Exception as e:
                raise MalformedURIException('Malformed stripwhite argument in URI')
        else:
            try:
                stripwhite=config["obi"]["stripwhite"]
            except KeyError:
                stripwhite=True
        if not isinstance(stripwhite, bool):    
            raise MalformedURIException('Malformed stripwhite argument in URI')
        
        if b"blanklineskip" in qualifiers:
            try:
                blanklineskip=eval(qualifiers[b"blanklineskip"][0])
            except Exception as e:
                raise MalformedURIException('Malformed blanklineskip argument in URI')
        else:
            try:
                blanklineskip=config["obi"]["blanklineskip"]
            except KeyError:
                blanklineskip=True
        if not isinstance(blanklineskip, bool):    
            raise MalformedURIException('Malformed blanklineskip argument in URI')
        
        if b"commentchar" in qualifiers:
            commentchar=tobytes(qualifiers[b"commentchar"][0][0])
        else:
            try:
                commentchar=tobytes(config["obi"]["commentchar"])
            except KeyError:
                commentchar=b'#'

        if format is not None:
            if seqtype==b"nuc":
                objclass = Nuc_Seq    # Nuc_Seq_Stored? TODO
                if format==b"fasta":
                    if input:
                        iseq = fastaNucIterator(file, 
                                                skip=skip, 
                                                only=only,
                                                nastring=nastring)
                    else:
                        iseq = FastaNucWriter(FastaFormat(printNAKeys=printna, NAString=nastring), 
                                              file,
                                              skip=skip,
                                              only=only)
                elif format==b"fastq":
                    if input:
                        iseq = fastqIterator(file,
                                             skip=skip, 
                                             only=only,
                                             offset=offset,
                                             noquality=noquality,
                                             nastring=nastring)
                    else:
                        iseq = FastqWriter(FastqFormat(printNAKeys=printna, NAString=nastring), 
                                           file,
                                           skip=skip,
                                           only=only)
                elif format==b"embl":
                    if input:
                        iseq = emblIterator(file, 
                                            skip=skip, 
                                            only=only)
                    else:
                        raise NotImplementedError('Output sequence file format not implemented')
                elif format==b"genbank":
                    if input:
                        iseq = genbankIterator(file, 
                                               skip=skip, 
                                               only=only)
                    else:
                        raise NotImplementedError('Output sequence file format not implemented')
                else:
                    raise NotImplementedError('Sequence file format not implemented')
            elif seqtype==b"prot":
                raise NotImplementedError()
            elif format==b"tabular":
                objclass = dict
                if input:
                    iseq = tabIterator(file,
                                       header = header,
                                       sep = sep,
                                       dec = dec,
                                       stripwhite = stripwhite,
                                       blanklineskip = blanklineskip,
                                       commentchar = commentchar,
                                       nastring=nastring,
                                       skip = skip,
                                       only = only)
                else:
                    iseq = TabWriter(TabFormat(header=header, NAString=nastring, sep=sep), 
                                               file,
                                               skip=skip,
                                               only=only,
                                               header=header)
            elif format==b"ngsfilter":
                objclass = dict
                if input:
                    iseq = ngsfilterIterator(file,
                                             sep = sep,
                                             dec = dec,
                                             stripwhite = stripwhite,
                                             blanklineskip = blanklineskip,
                                             commentchar = commentchar,
                                             nastring=nastring,
                                             skip = skip,
                                             only = only)
                else:
                    raise NotImplementedError('Output sequence file format not implemented')
        else:
            if input:
                iseq, objclass, format = entryIteratorFactory(file,
                                                              skip, only,
                                                              seqtype,
                                                              offset,
                                                              noquality,
                                                              skiperror,
                                                              header,
                                                              sep,
                                                              dec,
                                                              nastring,
                                                              stripwhite,
                                                              blanklineskip,
                                                              commentchar)
            else:    # default export is in fasta? or tab? TODO
                objclass = Nuc_Seq   # Nuc_Seq_Stored? TODO
                iseq = FastaNucWriter(FastaFormat(printNAKeys=printna, NAString=nastring), 
                                      file,
                                      skip=skip,
                                      only=only)
        
        #tmpdms = get_temp_dms()
        
        entry_count = -1
        if input:
            entry_count = count_entries(file, format)
        
        return (file, iseq, objclass, urib, entry_count)
