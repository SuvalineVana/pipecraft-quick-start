#!/bin/bash

#Input = paired-end fastq or fasta files; and barcodes file (oligos file).
#Supported formats = fastq, fq, fasta, fa, txt.

#Demultiplex paired-end fastq/fasta based on the specified barcodes file (states the barcodes per sample; optionally also primers).
#Barcodes file has to be formatted as paired-end barcodes.
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
inputR1=$"R1"
inputR2=$"R2"
barcodes_file=$"oligos_paired.txt"
bdiffs=$"1"
pdiffs=$"2"
tdiffs=$"6"
processors=$"1"
###############################

#If file extension is fq, then rename to fastq (for consistency)
if [[ $format == "fq" ]]; then
	mv $inputR1.$format $inputR1.fastq
	mv $inputR2.$format $inputR2.fastq
	format=$"fastq"
	echo $format
fi
#If file extension is fa or txt, then rename to fasta (for consistency)
if [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
	mv $inputR1.$format $inputR1.fasta
	mv $inputR2.$format $inputR2.fasta
	format=$"fasta"
fi
	
###### PAIRED BARCODES DEMUX; PAIRED-END DATA (R1 and R2)
###Pre-processing input based on format (fastq or fasta)
if [[ $format == "fastq" ]]; then
	#Check if headers contain ':'. If yes, then replace : with _ (mothur does not like : )
	if grep -q ":" ; then
		echo "WARNING: sequence headers contain ':', replacing with '_'."
		awk 'NR%4==1{gsub(":","_",$0)}; {print $0}' $inputR1.$format > $inputR1.renamed.$format
		awk 'NR%4==1{gsub(":","_",$0)}; {print $0}' $inputR2.$format > $inputR2.renamed.$format
		#Replace variables
		inputR1=$inputR1.renamed
		inputR2=$inputR2.renamed
	fi < <(head -1 $inputR1.$format) #use of process substitution to overwrite variables
	
	#Extract fasta from fastq
	vsearch --fastx_filter $inputR1.$format --fasta_width 0 --fastq_qmax 93 --fastaout $inputR1.fasta
	vsearch --fastx_filter $inputR2.$format --fasta_width 0 --fastq_qmax 93 --fastaout $inputR2.fasta
fi

if [[ $format == "fasta" ]]; then
	#Check if headers contain ':'. If yes, then replace : with _ (mothur does not like : )
	if grep -q ":" ; then
		echo "WARNING: sequence headers contain ':', replacing with '_'."
		sed -e 's/:/_/g' $inputR1.$format > $inputR1.renamed.$format
		sed -e 's/:/_/g' $inputR2.$format > $inputR2.renamed.$format
		#Replace variables
		inputR1=$inputR1.renamed
		inputR2=$inputR2.renamed
	fi < <(head -1 $inputR1.$format) #use of process substitution to overwrite variables
fi
#Edit seq headers: remove everything after space or tab (different R1 and R2 identifiers interrupt stitching)
sed -e 's/ .*//; s/\t.*//' $inputR1.fasta > R1.go.temp
sed -e 's/ .*//; s/\t.*//' $inputR2.fasta > R2.go.temp
###PRE-PROCESSING DONE: outputs are R1.go.temp AND R2.go.temp


###Reverse complement R2_file for stiching and demultiplexing
vsearch --fastx_revcomp R2.go.temp --fasta_width 0 --fastaout R2.go.rc.temp
	
#Stitch R1 and R2 seqs for demultiplexing (this is not assembly process with overlap region!)
tr "\n" "\t" < R1.go.temp | sed -e 's/>/\n>/g' | sed '/^\n*$/d' > R1.temp
tr "\n" "\t" < R2.go.rc.temp | sed -e 's/>/\n>/g' | sed '/^\n*$/d' > R2.go.rc.stitch.temp
gawk 'BEGIN {FS=OFS="\t"} FNR==NR{a[$1]=$2;next} ($1 in a) {print $1,a[$1],$2}' R1.temp R2.go.rc.stitch.temp > R1R2.temp
sed -e 's/\t/\n/' < R1R2.temp | sed -e 's/\t//' > R1R2.fasta
rm R2.go.rc.temp
rm R1.go.temp
rm R2.go.temp
rm R1R2.temp
rm R1.temp
rm R2.go.rc.stitch.temp

###Demultiplex fasta file based on barcodes file
mothur "#trim.seqs(fasta=R1R2.fasta, oligos=$barcodes_file, bdiffs=$bdiffs, pdiffs=$pdiffs, tdiffs=$tdiffs, processors=$processors, checkorient=t)"
[ -f R1R2.scrap.fasta ] && rm R1R2.scrap.fasta
[ -f R1R2.scrap.qual ] && rm R1R2.scrap.qual
[ -f R1R2.trim.qual ] && rm R1R2.trim.qual
	
#rename groups file
mv R1R2.groups demux.groups
	
#Check if sequences were demultiplexed
if [ -s R1R2.trim.fasta ]; then
	#remove redundant files
	rm R1R2.trim.fasta
	[ -f R1R2.fasta ] && rm R1R2.fasta
else
	echo "Seqs not assigned to samples. Please check barcodes file. Quitting" && rm demux.groups && exit 1
fi

###Generate FASTQ/FASTA files per sample based on demux.groups file
#demux R1
python demux_FASTX_based_on_groups.py $inputR1.$format $format
rm Relabelled_input.fastx
rm Relabelled_input.fastx.temp
#Move demux samples to demux_samples folder
mkdir demux_samples
mv sample=*.$format demux_samples
cd demux_samples
rename 's/sample=/R1./' *.$format
cd ..
#demux R2
python demux_FASTX_based_on_groups.py $inputR2.$format $format
rm Relabelled_input.fastx
rm Relabelled_input.fastx.temp
#Move demux samples to demux_samples folder
mv sample=*.$format demux_samples
cd demux_samples
rename 's/sample=/R2./' *.$format

#fix seq headers (remove ";sample=" from seq headers)
for f in *.$format; do sed -i 's/;sample=.*//' $f ; done

#delete redundant files
cd ..
[ -f $input.scrap.qual ] && rm $input.scrap.qual
[ -f $input.trim.qual ] && rm $input.trim.qual
[ -f $input.qual ] && rm $input.qual
[ -f $input.trim.fasta ] && rm $input.trim.fasta
rm mothur.*.logfile

#Done, demultiplexed files in 'demux_samples' folder
