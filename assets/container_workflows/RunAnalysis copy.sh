#!/bin/sh
# This is a comment!
mothur/./mothur "#make.contigs(file=stability.files, processors=8); 
screen.seqs(fasta=current, maxambig=0, maxlength=275); 
unique.seqs(); count.seqs(name=current, group=current); 
align.seqs(fasta=current, reference=silva.v4.fasta); 
screen.seqs(fasta=current, count=current, start=1968, end=11550, maxhomop=8); 
filter.seqs(fasta=current, vertical=T, trump=.); 
pre.cluster(fasta=current, count=current, diffs=2); 
unique.seqs(fasta=current, count=current); 
chimera.vsearch(fasta=current, count=current, dereplicate=t); 
remove.seqs(fasta=current, accnos=current); 
classify.seqs(fasta=current, count=current, reference=trainset9_032012.pds.fasta, taxonomy=trainset9_032012.pds.tax, cutoff=80); 
remove.lineage(fasta=current, count=current, taxonomy=current, taxon=Chloroplast-Mitochondria-unknown-Archaea-Eukaryota); 
remove.groups(count=current, fasta=current, taxonomy=current, groups=Mock); dist.seqs(fasta=current, cutoff=0.03); 
cluster(column=current, count=current, cutoff=0.03); make.shared(list=current, count=current, label=0.03); 
classify.otu(list=current, count=current, taxonomy=current, label=0.03); phylotype(taxonomy=current); 
make.shared(list=current, count=current, label=1); classify.otu(list=current, count=current, taxonomy=current, label=1);"


