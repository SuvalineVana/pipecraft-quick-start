#!/usr/bin/python

from collections import defaultdict
data_dict = defaultdict(list)

script, filename1,filename2 = argv
from operator import itemgetter
import math

 

fasta_dict = {}
seq = ''
n=0

dictSeqLen = {} 
from collections import OrderedDict
fasta_dict=dict(fasta_dict)
seq = ''

AC=''
for k in filename1:
        F = open(k)
        for line in F:
                if line[0] == '>':
                    AC =line[]+"\n"
                elif line[0] != '>':
                    data_dict[AC].append(line)
 
with  open(filename2,'w') as output: