#!/usr/bin/python

import os
input_for_clustering = open(os.path.expanduser("~/.var_babitas/input_for_clustering.txt"))
groups_file = open(os.path.expanduser("~/.var_babitas/groups_file.txt"))
wd = open(os.path.expanduser("~/.var_babitas/WD.txt"))

for i in wd:
	wd1 = i

for i in input_for_clustering:
	input_for_clustering1 = i
	
for i in groups_file:
	groups_file1 = i



groups = open(os.path.normpath(str(groups_file1.rstrip('\n'))), "r") #Input groups
kokku = []
seq_dict = {}
groups_dict = {} 
for rida in groups:
    rida = rida.strip("\n").split("\t")
    kokku += [rida[0]]
    if rida[0] in seq_dict:
        print("WARNING: Sequence <", rida[0], "> happens multiple times in .groups file.")
    else:
        seq_dict[rida[0]]=(rida[1])
    if rida[1] in groups_dict:
        groups_dict[rida[1]]+=("\t" + rida[0])
    else:
        groups_dict[rida[1]]=(rida[0])
groups.close()



print ""
print "SAMPLE count in *.groups file =", str(len(groups_dict))
print "SEQUENCE count =", str(len(seq_dict))
print ""


print "List of SAMPLES =", (sorted(groups_dict))
print ""


import re
fasta = open(os.path.normpath(str(input_for_clustering1.rstrip('\n'))), "r")

OUTPUT = open(os.path.normpath(str(wd1.rstrip('\n')+str("/Relabelled_for_USEARCH.fasta"))), "w+")
for rida in fasta:
    if re.match(">", rida):
        voti = rida.strip("\n, >")
        if voti in seq_dict:
            head = ">" + voti + ";sample=" + seq_dict[voti] + "\n"
            OUTPUT.write(head)
        else:
            OUTPUT.write(">" + voti + "\n")
            print("ERROR: there is no sequence <", voti, "> in groups file!")
    else:
        OUTPUT.write(rida)
OUTPUT.close()
fasta.close()
