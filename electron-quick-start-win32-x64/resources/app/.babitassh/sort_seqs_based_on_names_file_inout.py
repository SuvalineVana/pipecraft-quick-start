#!/usr/bin/python
import os

from sys import argv
script, filename1, filename2, fileout = argv


F = open(filename1,'r')
Names = open(filename2, 'r')

fasta_dict = {}
seq = ''
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

new_dic={}
N= []
M = []
seq = ''
for line in Names:
    M.append(line.rstrip())

n=0
seqs=""
with  open(fileout,'w') as output:

    for j in M:
         i=">"+j.strip()
         try:#:if i in fasta_dict:
            seqs=seqs+'>'+j+ '\n'+fasta_dict[i]+'\n'
            output.write(seqs)
            seqs=""
         except:
            pass
