#!/usr/bin/python

from sys import argv
print "#Rep seq;"

script, filename1= argv
from operator import itemgetter
import math


 
fasta=''
con = ''
seq=''
header=''
blast=''
header=''
blast_hits=''



with open ('10hits.txt', 'w') as input2:                
                from Bio.Blast import NCBIXML
                File=open(filename1,'rU')
                blast_records = NCBIXML.parse(File)
                for blast_record in blast_records:     
                    i = 0
                
                    if blast_record.alignments:
                            print blast_record.query
                            while i<10:        
                                    try:
                                        blast_hits=blast_hits+ '\t' +str(blast_record.alignments[i].title)+'\t'
                                        percentage=blast_record.alignments[i].hsps[0].identities*100/blast_record.alignments[i].hsps[0].align_length
                                        header=str(i)+'\t'+str(blast_record.alignments[i].title)+'+'+str(blast_record.alignments[i].hsps[0].score)+'+'+str(blast_record.alignments[i].hsps[0].expect)+'+'+str(blast_record.alignments[i].hsps[0].query_start)+'+'+str(blast_record.alignments[i].hsps[0].query_end)+'+'+str(blast_record.alignments[i].hsps[0].align_length)+'+'+str(blast_record.alignments[i].hsps[0].identities)+'+'+str(blast_record.alignments[i].hsps[0].gaps)+'+'+str(percentage)+'%'
                   
                                        blast_hits= blast_hits+header
                                    except IndexError:
                                        blast_hits=blast_hits+'\t'+'no hit'+'\t'
                                    i+=1
                    blast_hits=blast_hits+"\n"
                input2.write(blast_hits)
