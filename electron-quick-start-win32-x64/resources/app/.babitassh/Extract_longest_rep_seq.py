#!/usr/bin/python

import os
from sys import argv

script, filename1,filename2= argv
from operator import itemgetter
import math


from glob import glob
filename = glob(filename2) 
Cluster = open(filename1,'rU') 


fasta_dict = {}
seq = ''
for k in filename:
        F = open(k)
        for line in F:
                if line[0] == '>' and seq == '':
                        AC = line.split()[0]
                elif line[0] != '>':
                        seq = seq + line.strip()
                elif line[0] == '>' and seq != '':
                        fasta_dict[AC] = seq
                        AC = line.split()[0]
                        seq = ''
fasta_dict[AC] = seq


            
fasta_dict2 = {}
from collections import OrderedDict
fasta_dict2=OrderedDict(fasta_dict2)

seq = ''
M=[]
for line in Cluster:
        line=line.rstrip()
        M.append(line)
 
seqs=''
seqs = ''
seqs2=[]
clusters=[]
for i in M:
        for j in i.split():
            #if j[0] == '>':
                seqs=">"+j
                #print seqs
                if seqs in fasta_dict:
                        #print seqs
                        seqs2.append(seqs+'\n'+fasta_dict[seqs])
                        seqs=''
        clusters.append(seqs2)
        seqs2=[]
with  open('Rep_seqs_LONGEST.fasta','w') as output:
        for i in clusters:
          #print i      
          output.write(max(i, key=len)+'\n')

