#!/bin/bash

#Input = fastq or fasta file; and barcodes file (oligos file).
#Supported formats = fastq, fq, fasta, fa, txt.

#Demultiplex fastq/fasta based on the specified barcodes file (states the barcodes per sample; optionally also primers).
#Barcodes file has to be formatted as single-end barcodes.
#Examples of barcodes format in "barcodes_file_example.txt"

##########################################################
###Third-party applications:
#mothur
	#citation: Schloss PD et al. (2009) Introducing mothur: Open-Source, Platform-Independent, Community-Supported Software for Describing and Comparing Microbial Communities Appl Environ Microbiol 75:7537-7541
	#Distributed under the GNU General Public License version 3 by the Free Software Foundation"
    #https://github.com/mothur/mothur
#vsearch
	#citation: Rognes T, Flouri T, Nichols B, Quince C, Mahé F (2016) VSEARCH: a versatile open source tool for metagenomics PeerJ 4:e2584
	#Copyright (C) 2014-2020, Torbjorn Rognes, Frederic Mahe and Tomas Flouri
	#Distributed under the GNU General Public License version 3 by the Free Software Foundation
	#https://github.com/torognes/vsearch
##########################################################

############################### FOR TESTING
format=$"fastq" #need to detect format somehow (allowed extensions = fastq, fq, fasta, fa and txt)
#e.g. detectig format by reading the last string after .  --> format=$(cat input_location.txt | (awk 'BEGIN{FS=OFS="."} {print $NF}';))
input=$"5-3" #no file extension!
barcodes_file=$"oligos_single_rev.txt"
pdiffs=$"2"
bdiffs=$"1"
tdiffs=$"6"
processors=$"1"
tag_attached_to=$"rev" #options = rev, fwd
###############################

#If file extension is fq, then rename to fastq (for consistency)
if [[ $format == "fq" ]]; then
	mv $input.$format $input.fastq
	format=$"fastq"
fi
#If file extension is fa or txt, then rename to fasta (for consistency)
if [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
	mv $input.$format $input.fasta
	format=$"fasta"
fi
	
###### SINGLE END BARCODES DEMUX
#FASTQ input
if [[ $format == "fastq" ]]; then
	#Check if headers contain ':'. If yes, then replace : with _ (mothur does not like : )
	if grep -q ":" ; then
		echo "WARNING: sequence headers contain ':', replacing with '_'."
		awk 'NR%4==1{gsub(":","_",$0)}; {print $0}' $input.$format > $input.renamed.fastq
		#Replace variables
		input=$input.renamed
	fi < <(head -1 $input.$format) #use of process substitution to overwrite variables
	
	if [[ $tag_attached_to == "rev" ]]; then #If tag with rev primer, then reverse complement seqs
		vsearch --fastx_revcomp $input.$format --fastqout $input.rc.fastq
		#Extract fasta and qual from fastq
		mothur "#fastq.info(fastq=$input.rc.fastq)"
		#Rename fasta and qual files
		mv $input.rc.fasta $input.fasta
		mv $input.rc.qual $input.qual
		rm $input.rc.fastq
	fi
	 
	if [[ $tag_attached_to == "fwd" ]]; then #If tag with fwd primer, then just extract fasta and qual for demultiplexing
		#Extract fasta and qual from fastq
		mothur "#fastq.info(fastq=$input.fastq)"
	fi
	
	#Demultiplex fasta file based on barcodes file
	mothur "#trim.seqs(fasta=$input.fasta, qfile=$input.qual, oligos=$barcodes_file, bdiffs=$bdiffs, pdiffs=$pdiffs, tdiffs=$tdiffs, processors=$processors)"
	#Rename unidentified sequences
	mv $input.scrap.fasta unidentified.fasta
	
	#rename groups file
	mv $input.groups demux.groups
	
	#Check if sequences were demultiplexed; i.e. does $input.trim.fasta contain any sequences
	if [ -s $input.trim.fasta ]; then
		echo ""
	else
		echo "Seqs not assigned to samples. Please check barcodes file. Quitting" && rm demux.groups && exit 1
	fi
	
	#make new fastq from demuxed fasta and qual files
	mothur "#make.fastq(fasta=$input.trim.fasta, qfile=$input.trim.qual)"
	mv $input.trim.fastq demux_pool.fastq
	
	if [[ $tag_attached_to == "rev" ]]; then #reverse complement sequences back to original orientation (5'-3')
		vsearch --fastx_revcomp demux_pool.fastq --fastqout demux_pool.rc.fastq
		mv demux_pool.rc.fastq demux_pool.fastq
	fi

	#Generate FASTQ files per sample based on demux.groups file
	python demux_FASTX_based_on_groups.py demux_pool.fastq fastq
	rm Relabelled_input.fastx
	rm Relabelled_input.fastx.temp

	#Remove "sample=" from demuxed files
	mkdir demux_samples
	mv sample=*.fastq demux_samples
	cd demux_samples
	rename 's/sample=//' *.fastq
	
	#remove ";sample=" from fasta headers
	for f in *.fastq; do sed -i 's/;sample=.*//' $f ; done
fi

#FASTA input
if [[ $format == "fasta" ]]; then
	#Check if headers contain ':'. If yes, then replace : with _ (mothur does not like : )
	if grep -q ":" ; then
		echo "WARNING: sequence headers contain ':', replacing with '_'."
		sed -e 's/:/_/g' $input.$format > $input.renamed.fasta
		#Replace variables
		input=$input.renamed
	fi < <(head -1 $input.$format) #use of process substitution to overwrite variables
	
	if [[ $tag_attached_to == "rev" ]]; then #If tag with rev primer, then reverse complement seqs
		vsearch --fastx_revcomp $input.fasta --fastaout $input.rc.fasta
		#Rename fasta and qual files
		mv $input.rc.fasta $input.fasta
	fi
	#Note: If tag with fwd primer, then just proceed with the input fasta

	#Demultiplex fasta file based on barcodes file
	mothur "#trim.seqs(fasta=$input.fasta, oligos=$barcodes_file, bdiffs=$bdiffs, pdiffs=$pdiffs, tdiffs=$tdiffs, processors=$processors)"
	#Rename unidentified sequences
	mv $input.scrap.fasta unidentified.fasta
	
	#rename groups file
	mv $input.groups demux.groups
	#Rename demultiplexed fasta file
	mv $input.trim.fasta demux_pool.fasta
	
	#Check if sequences were demultiplexed; i.e. does demux_pool.fasta contain any sequences
	if [ -s demux_pool.fasta ]; then
		echo ""
	else
		echo "Seqs not assigned to samples. Please check barcodes file. Quitting" && rm demux.groups && exit 1
	fi

	#Generate FASTQ files per sample based on demux.groups file
	python demux_FASTX_based_on_groups.py demux_pool.fasta fasta
	rm Relabelled_input.fastx
	rm Relabelled_input.fastx.temp

	#Remove "sample=" from demuxed files
	mkdir demux_samples
	mv sample=*.fasta demux_samples
	cd demux_samples
	rename 's/sample=//' *.fasta
	
	#remove ";sample=" from fasta headers
	for f in *.fasta; do sed -i 's/;sample=.*//' $f ; done
fi

#remove redundant files
cd ..
[ -f $input.scrap.qual ] && rm $input.scrap.qual
[ -f $input.trim.qual ] && rm $input.trim.qual
[ -f $input.qual ] && rm $input.qual
[ -f $input.trim.fasta ] && rm $input.trim.fasta
rm mothur.*.logfile

#Done, demultiplexed files in 'demux_samples' folder
