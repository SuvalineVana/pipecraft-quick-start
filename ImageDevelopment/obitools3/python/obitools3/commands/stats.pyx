#cython: language_level=3

from obitools3.apps.progress cimport ProgressBar  # @UnresolvedImport
from obitools3.dms import DMS
from obitools3.uri.decode import open_uri
from obitools3.apps.optiongroups import addMinimalInputOption, addTaxonomyOption
from obitools3.dms.view import RollbackException
from obitools3.apps.config import logger
from obitools3.dms.capi.obiview cimport COUNT_COLUMN
from obitools3.utils cimport tostr

from functools import reduce
import math
import time
import sys
from cpython.exc cimport PyErr_CheckSignals


__title__="Compute basic statistics for attribute values."

'''
`obi stats` computes basic statistics for attribute values of sequence records.
The sequence records can be categorized or not using one or several ``-c`` options.
By default, only the number of sequence records and the total count are computed for each category. 
Additional statistics can be computed for attribute values in each category, such as:

    - minimum value (``-m`` option) 
    - maximum value (``-M`` option) 
    - mean value (``-a`` option) 
    - variance (``-v`` option) 
    - standard deviation (``-s`` option)
    
The result is a contingency table with the different categories in rows, and the 
computed statistics in columns. 
'''


# TODO: when is the taxonomy possibly used?

 
def addOptions(parser):
    
    addMinimalInputOption(parser)
    addTaxonomyOption(parser)

    group=parser.add_argument_group('obi stats specific options')

    group.add_argument('-c','--category-attribute',
                       action="append", dest="stats:categories",
                             metavar="<Attribute Name>",
                             default=[],
                             help="Attribute used to categorize the records.")
    
    group.add_argument('-m','--min',
                       action="append", dest="stats:minimum",
                       metavar="<Attribute Name>",
                       default=[],
                       help="Compute the minimum value of attribute for each category.")
    
    group.add_argument('-M','--max',
                       action="append", dest="stats:maximum",
                       metavar="<Attribute Name>",
                       default=[],
                       help="Compute the maximum value of attribute for each category.")

    group.add_argument('-a','--mean',
                       action="append", dest="stats:mean",
                       metavar="<Attribute Name>",
                       default=[],
                       help="Compute the mean value of attribute for each category.")

    group.add_argument('-v','--variance',
                       action="append", dest="stats:var",
                       metavar="<Attribute Name>",
                       default=[],
                       help="Compute the variance of attribute for each category.")

    group.add_argument('-s','--std-dev',
                       action="append", dest="stats:sd",
                       metavar="<Attribute Name>",
                       default=[],
                       help="Compute the standard deviation of attribute for each category.")


def statistics(values, attributes, func):
    
    stat={}
    lstat={}
    
    for var in attributes:
        if var in values:
            stat[var]={}
            lstat[var]=0
            for c in values[var]:
                v = values[var][c]
                m = func(v)
                stat[var][c]=m
                lm=len(str(m))
                if lm > lstat[var]:
                    lstat[var]=lm
                
    return stat, lstat


def minimum(values, options):
    return statistics(values, options['minimum'], min)
    

def maximum(values, options):
    return statistics(values, options['maximum'], max)


def mean(values, options):
    def average(v):
        s = reduce(lambda x,y:x+y,v,0)
        return float(s)/len(v)
    return statistics(values, options['mean'], average)


def variance(v):
    if len(v)==1: 
        return 0 
    s = reduce(lambda x,y:(x[0]+y,x[1]+y**2),v,(0.,0.))
    return s[1]/(len(v)-1) - s[0]**2/len(v)/(len(v)-1)


def varpop(values, options):
    return statistics(values, options['var'], variance)
    

def sd(values, options):
    def stddev(v):
        return math.sqrt(variance(v))
    return statistics(values, options['sd'], stddev)

 
def run(config):
     
    DMS.obi_atexit()
    
    logger("info", "obi stats")

    # Open the input
    input = open_uri(config['obi']['inputURI'])
    if input is None:
        raise Exception("Could not read input view")
    i_view = input[1]

    if 'taxoURI' in config['obi'] and config['obi']['taxoURI'] is not None:
        taxo_uri = open_uri(config['obi']['taxoURI'])
        if taxo_uri is None or taxo_uri[2] == bytes:
            raise Exception("Couldn't open taxonomy")
        taxo = taxo_uri[1]
    else :
        taxo = None

    statistics = set(config['stats']['minimum']) | set(config['stats']['maximum']) | set(config['stats']['mean'])
    total = 0
    catcount={}
    totcount={}
    values={}
    lcat=0
    
    # Initialize the progress bar
    pb = ProgressBar(len(i_view), config, seconde=5)
    
    for i in range(len(i_view)):
        PyErr_CheckSignals()
        pb(i)
        line = i_view[i]
        
        category = []
        for c in config['stats']['categories']:
            try:
                if taxo is not None:
                    loc_env = {'sequence': line, 'line': line, 'taxonomy': taxo}
                else:
                    loc_env = {'sequence': line, 'line': line}

                v = eval(c, loc_env, line)
                
                lv=len(str(v))
                if lv > lcat:
                    lcat=lv
                category.append(v)
            except:
                category.append(None)
                if 4 > lcat:
                    lcat=4

        category=tuple(category)
        catcount[category]=catcount.get(category,0)+1
        try: 
            totcount[category]=totcount.get(category,0)+line[COUNT_COLUMN]
        except KeyError:
            totcount[category]=totcount.get(category,0)+1
        for var in statistics:
            if var in line:
                v = line[var]
                if var not in values:
                    values[var]={}
                if category not in values[var]:
                    values[var][category]=[]
                values[var][category].append(v)    

    pb(i, force=True)
    print("", file=sys.stderr)
    
    mini, lmini = minimum(values, config['stats'])
    maxi, lmaxi = maximum(values, config['stats'])
    avg, lavg = mean(values, config['stats'])
    varp, lvarp = varpop(values, config['stats'])
    sigma, lsigma = sd(values, config['stats'])

    pcat = "%%-%ds" % lcat
    if config['stats']['minimum']:
        minvar= "min_%%-%ds" % max(len(x) for x in config['stats']['minimum'])
    else:
        minvar= "%s"
        
    if config['stats']['maximum']:
        maxvar= "max_%%-%ds" % max(len(x) for x in config['stats']['maximum'])
    else:
        maxvar= "%s"
        
    if config['stats']['mean']:
        meanvar= "mean_%%-%ds" % max(len(x) for x in config['stats']['mean'])
    else:
        meanvar= "%s"
        
    if config['stats']['var']:
        varvar= "var_%%-%ds" % max(len(x) for x in config['stats']['var'])
    else:
        varvar= "%s"
        
    if config['stats']['sd']:
        sdvar= "sd_%%-%ds" % max(len(x) for x in config['stats']['sd'])
    else:
        sdvar= "%s"
        
    hcat = "\t".join([pcat % x for x in config['stats']['categories']]) + "\t" +\
           "\t".join([minvar % x for x in config['stats']['minimum']])  + "\t" +\
           "\t".join([maxvar % x for x in config['stats']['maximum']])  + "\t" +\
           "\t".join([meanvar % x for x in config['stats']['mean']])  + "\t" +\
           "\t".join([varvar % x for x in config['stats']['var']])  + "\t" +\
           "\t".join([sdvar % x for x in config['stats']['sd']]) + \
           "\t   count" + \
           "\t   total" 
    print(hcat)
    sorted_stats = sorted(catcount.items(), key = lambda kv:(totcount[kv[0]]), reverse=True)
    for i in range(len(sorted_stats)):
        c = sorted_stats[i][0]
        for v in c:
            if v is not None:
                print(pcat % tostr(v)+"\t", end="")
            else:
                print(pcat % str(v)+"\t", end="")
        for m in config['stats']['minimum']:
            print((("%%%dd" % lmini[m]) % mini[m][c])+"\t", end="")
        for m in config['stats']['maximum']:
            print((("%%%dd" % lmaxi[m]) % maxi[m][c])+"\t", end="")
        for m in config['stats']['mean']:
            print((("%%%df" % lavg[m]) % avg[m][c])+"\t", end="")
        for m in config['stats']['var']:
            print((("%%%df" % lvarp[m]) % varp[m][c])+"\t", end="")
        for m in config['stats']['sd']:
            print((("%%%df" % lsigma[m]) % sigma[m][c])+"\t", end="")
        print("%7d" %catcount[c], end="")
        print("%9d" %totcount[c])

    input[0].close()
    
    logger("info", "Done.")
