#!/usr/bin/python

#script usage: python script.py input format
#input = fastq or fastq file; format = specify format, fastq or fasta [example: python script.py input.fastq fastq]

#### ADD SAMPLE NAMES TO SEQ HEADERS based on groups file 
#### and then demux seqs to samples as based on the sample header of the sequence
### GROUPS FILE = demux.groups

import os
from Bio import SeqIO
import sys
from sys import argv
script, infile, informat = argv

### Read groups file
groups = open(r'demux.groups')
m = []
seq_dict = {}
groups_dict = {} 
for line in groups:
    line = line.strip("\n").split("\t")
    print(line)
    m += [line[0]]
    if line[0] in seq_dict:
        print("WARNING: Sequence <", line[0], "> appears multiple times in .groups file.")
    else:
        seq_dict[line[0]]=(line[1])
    if line[1] in groups_dict:
        groups_dict[line[1]]+=("\t" + line[0])
    else:
        groups_dict[line[1]]=(line[0])
groups.close()

### Add sample names to seq headers based on groups file ###
OUTPUT = open("Relabelled_input.fastx", "w+")
print(OUTPUT)
records = SeqIO.parse(infile, informat)
for record in records:
    if record.id in seq_dict:
        record.id = "%s;sample=%s%s" % (record.id, seq_dict[record.id], "\t")
        OUTPUT.write(record.format(informat))
OUTPUT.close()
#records.close()

cmd = "sed -e 's/\t.*//' Relabelled_input.fastx > Relabelled_input.fastx.temp"
os.system(cmd)
###################################################################

### Demux seqs to samples ###
records = SeqIO.parse("Relabelled_input.fastx.temp", informat)
collected = {}
for record in records:
	descr = record.description.split(";")[1] # ";" sets the delimeter, "1" sets the field where counting starts at 0 for the first field
	try:
		collected[descr].append(record)
	except KeyError:
		collected[descr] = [record ,]

file_name = "%s." + informat
file_path = os.getcwd() #sets the output file path to your current working directory

for (descr, records) in collected.items():  
	with open(os.path.join(file_path, file_name % descr), 'w') as f:
		SeqIO.write(records, f, informat)
#Done
