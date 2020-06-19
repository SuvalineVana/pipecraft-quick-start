#cython: language_level=3

'''
Created on June 12th 2018

@author: coissac/mercier
'''


import logging
import re
from itertools import chain
from obitools3.utils cimport str2bytes

        
_featureMatcher = re.compile(b'^(FT|  )   [^ ].+\n((FT|  )    .+\n)+',re.M)
_featureCleaner = re.compile(b'^FT',re.M)

def textFeatureIterator(fttable):
    '''
    Iterate through a textual description of a feature table in a genbank
    or embl format. Return at each step a text representation of each individual
    feature composing the table.
    
    @param fttable:  a string corresponding to the feature table of a genbank
                     or an embl entry
                      
    @type fttable: C{str}
    
    @return: an iterator on str
    @rtype: iterator
    
    @see: L{ftParser}
    '''
    for m in _featureMatcher.finditer(fttable):
        t = m.group()
        t = _featureCleaner.sub(b'  ',t)
        yield t
   
        
_qualifierMatcher = re.compile(b'(?<=^ {21}/).+(\n {21}[^/].+)*',re.M)
_qualifierCleanner= re.compile(b"^ +",re.M)
        
def qualifierIterator(qualifiers):
    '''
    Parse a textual description of a feature in embl or genbank format
    as returned by the textFeatureIterator iterator and iterate through 
    the key, value qualified defining this location.
     
    @param qualifiers: substring containing qualifiers
    @type qualifiers: str
    
    @return: an iterator on tuple (key,value), where keys are C{str}
    @rtype: iterator
    '''
    for m in _qualifierMatcher.finditer(qualifiers):
        t = m.group()
        t = _qualifierCleanner.sub(b'',t)
        t = t.split(b'=',1)
        if len(t)==1:
            t = (t[0],None)
        else:
            if t[0]==b'translation':
                value = t[1].replace(b'\n',b'')
            else:
                value = t[1].replace(b'\n',b' ')
            try:
                value = eval(value)
                if type(value) == str:
                    value = str2bytes(value)
            except:
                pass
            t = (t[0],value)
        yield t
    
     
_ftmatcher = re.compile(b'(?<=^ {5})\S+')
_qualifiersMatcher = re.compile(b'^ +/.+',re.M+re.DOTALL)

def ftParser(feature):
    fttype = _ftmatcher.search(feature).group()
    qualifiers=_qualifiersMatcher.search(feature)
    if qualifiers is not None:
        qualifiers=qualifiers.group()
    else:
        qualifiers=b""
        logging.debug("Qualifiers regex not matching on \n=====\n%s\n========" % feature)

    return fttype,qualifiers       


class Feature(dict):
    
    def __init__(self,type):
        self._fttype=type

    def getFttype(self):
        return self._fttype

    def __str__(self):
        return repr(self)
    
    def __repr__(self):
        return str((self.ftType, dict.__repr__(self)))
    
    ftType = property(getFttype, None, None, "Feature type name")
       

def featureFactory(featureDescription):
    fttype,qualifiers = ftParser(featureDescription)
    feature = Feature(fttype)
    feature.raw  = featureDescription

    for k,v in qualifierIterator(qualifiers):
        feature.setdefault(k,[]).append(v)
        
    return feature
       
        
def featureIterator(featureTable,skipError=False):
    for tft in textFeatureIterator(featureTable):
        try:
            feature = featureFactory(tft)
        except AssertionError,e:
            logging.debug("Parsing error on feature :\n===============\n%s\n===============" % tft)
            if not skipError:
                raise e
            logging.debug("\t===> Error skipped")
            continue
            
        yield feature

        
def extractTaxon(bytes text, dict tags):
         
    s = next(featureIterator(text))
    s = [s]          
    
    t = set(int(v[6:]) for v in chain(*tuple(f[b'db_xref'] for f in s if b'db_xref' in f)) 
            if  v[0:6]==b'taxon:')
    if len(t)==1 :
        taxid=t.pop()
        if taxid >=0:
            tags[b'TAXID']=taxid      

    t = set(chain(*tuple(f[b'organism'] for f in s if b'organism' in f))) 
    if len(t)==1:
        tags[b'organism']=t.pop()
