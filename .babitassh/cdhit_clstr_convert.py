#!/usr/bin/python
import os

# Convert cdhit format --> 
F = open('Clusters_CDHIT.clstr') ## cdhit cluster
AC=''

fasta_dict = {}
fasta_dict = {}
from collections import OrderedDict
fasta_dict=OrderedDict(fasta_dict)

seq = ''
for line in F:
    if line[0] == '>' and seq == '':
        AC = line.split()[1]
    elif line[0] != '>':
        seq = seq + line.strip()
    elif line[0] == '>' and seq != '':
        fasta_dict[AC] = seq
        AC = line.split()[1]
        seq = ''
fasta_dict[AC] = seq
seqs = ''
with  open('Converted_clusters.clstr','w') as output: ##OUTPUT
    for i in fasta_dict.itervalues():
        i=i.split()
        for j in i:
            if j[0] == '>':
                seqs=seqs+j[1:]+"\t"
        seqs=seqs+'\n'
        seqs=seqs.replace(",","")
        output.write(seqs)
        seqs=''





