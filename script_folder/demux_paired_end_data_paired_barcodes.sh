#!/bin/bash

#Input = paired-end fastq or fasta files; and barcodes file (oligos file).
#Supported formats = fastq, fq, fasta, fa, txt.npm

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
#seqkit
	#citation: W Shen, S Le, Y Li, F Hu. SeqKit: a cross-platform and ultrafast toolkit for FASTA/Q file manipulation. PLOS ONE. doi:10.1371/journal.pone.0163962.
	#Copyright © 2016-2019 Wei Shen, 2019 Oxford Nanopore Technologies
	#Distributed under the MIT License
	#https://github.com/shenwei356/seqkit/
##########################################################

############################### variables FOR local TESTING

echo $extension
echo $bdiffs
echo $pdiffs
echo $tdiffs
echo $barcodes_file
echo $dataFormat
echo $readType
inputR1=$(echo *R1*$extension)
inputR2=$(echo *R2*$extension)
echo $inputR1
echo $inputR2
#extension=$"fastq.gz"
#inputR1=$"/input/R1.fastq.gz" 
#inputR2=$"/input/R2.fastq.gz"
#barcodes_file=$",oligos=/input/oligos_paired.txt"
echo $barcodes_file
#bdiffs=$",bdiffs=1"
#pdiffs=$",pdiffs=2"
#tdiffs=$",tdiffs=5"
processors=$",processors=1"
###############################
#set -e

printf "\nPreparing files for demultiplexing ...\n"

#Write file name without extension
inputR1=$(echo $inputR1 | sed -e "s/.$extension//")
inputR2=$(echo $inputR2 | sed -e "s/.$extension//")

#Read user specified input extension
#If compressed, then decompress (keeping the compressed file, but overwriting if filename exists!)
check_compress=$(echo $extension | (awk 'BEGIN{FS=OFS="."} {print $NF}';))
if [[ $check_compress == "gz" ]] || [[ $check_compress == "zip" ]]; then
	pigz --decompress --force --keep $inputR1.$extension
	#Check errors
	if [ "$?" != "0" ]; then
		printf "\e[31m[ERROR]: R1 file decompressing failed! File not compressed as gz or zip. \nDecompressing other formats is not supported\n \nQuitting\n\e[0m" && exit
	fi
	pigz --decompress --force --keep $inputR2.$extension
	#Check errors
	if [ "$?" != "0" ]; then
		printf "\e[31m[ERROR]: R2 file decompressing failed! File not compressed as gz or zip. \nDecompressing other formats is not supported\n \nQuitting\n\e[0m" && exit
	fi
	extension=$(echo $extension | (awk 'BEGIN{FS=OFS="."} {print $(NF-1)}';))
fi



#If fastq file extension is fq, then rename to fastq (for consistency)
if [[ $extension == "fq" ]]; then
	printf "\e[35m   NOTE: 'fq' file extension will be renamed to 'fastq'\n\e[0m"
	mv $inputR1.$extension $inputR1.fastq
	#Check errors
	if [ "$?" != "0" ]; then
		printf "\e[31m[ERROR]: wrong input file format ($extension) specified\nQuitting\n\e[0m" && exit
	fi
	mv $inputR2.$extension $inputR2.fastq
	#Check errors
	if [ "$?" != "0" ]; then
		printf "\e[31m[ERROR]: wrong input file format ($extension) specified\nQuitting\n\e[0m" && exit
	fi
	extension=$"fastq"
	printf "\e[35m   $inputR1.$extension\n\e[0m"
	printf "\e[35m   $inputR2.$extension\n\e[0m"
fi
#If fasta file extension is fa, fas, fna, ffn, faa, frn, txt, then rename to fasta (for consistency)
if [[ $extension == "fa" ]] || [[ $extension == "fas" ]] || [[ $extension == "fna" ]] || [[ $extension == "ffn" ]] || [[ $extension == "faa" ]] || [[ $extension == "frn" ]] || [[ $extension == "txt" ]]; then
	printf "\e[35m   NOTE: input file extension will be renamed to 'fasta'\n\e[0m"
	mv $inputR1.$extension $inputR1.fasta
	#Check errors
	if [ "$?" != "0" ]; then
		printf "\e[31m[ERROR]: wrong input file format ($extension) specified\nQuitting\n\e[0m" && exit
	fi
	mv $inputR2.$extension $inputR2.fasta
	#Check errors
	if [ "$?" != "0" ]; then
		printf "\e[31m[ERROR]: wrong input file format ($extension) specified\nQuitting\n\e[0m" && exit
	fi
	extension=$"fasta"
	printf "\e[35m   $inputR1.$extension\n\e[0m"
	printf "\e[35m   $inputR2.$extension\n\e[0m"
fi

echo $extension
###### PAIRED BARCODES DEMUX; PAIRED-END DATA (R1 and R2)
###Pre-processing input based on extension (fastq or fasta)
#if input = fastq
if [[ $extension == "fastq" ]]; then
	#make list of original seqs names, R1
	awk 'NR % 4 == 1' $inputR1.$extension | sed -e 's/@//' > R1o.names
	#make list of original seqs names, R2
	awk 'NR % 4 == 1' $inputR2.$extension | sed -e 's/@//' > R2o.names
	
	#Rename sequences R1
	seqkit replace --quiet -p '.+' -r 'Seq{nr}' $inputR1.$extension > .R1.renamed.temp
	#Check errors
	if [ "$?" != "0" ]; then
		printf "\e[31m[ERROR 111]: check $inputR1.$extension\nQuitting\n\e[0m" && exit
	fi
	#Rename sequences R2
	seqkit replace --quiet -p '.+' -r 'Seq{nr}' $inputR2.$extension > .R2.renamed.temp
	#Check errors
	if [ "$?" != "0" ]; then
		printf "\e[31m[ERROR]: check $inputR2.$extension\nQuitting\n\e[0m" && exit
	fi
	
	#make list of renamed names 
	awk 'NR % 4 == 1' .R1.renamed.temp | sed -e 's/@//' > R1r.names
	awk 'NR % 4 == 1' .R2.renamed.temp | sed -e 's/@//' > R2r.names
	
	#merge names files 
		#(later used to keep the original headers at #Rename seqs back to original names based on R1.names and R2.names)
	awk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' R1r.names R1o.names > R1.names
	awk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' R2r.names R2o.names > R2.names
	rm R1o.names R1r.names R2o.names R2r.names
	
	#Extract fasta from fastq
	vsearch --fastx_filter .R1.renamed.temp --quiet --fasta_width 0 --fastq_qmax 93 --fastaout .R1.renamed.fasta
	#Check errors
	if [ "$?" != "0" ]; then
		printf "\e[31m[ERROR 134]: check $inputR1.$extension\nQuitting\n\e[0m" && exit
	fi
	vsearch --fastx_filter .R2.renamed.temp --quiet --fasta_width 0 --fastq_qmax 93 --fastaout .R2.renamed.fasta
	#Check errors
	if [ "$?" != "0" ]; then
		printf "\e[31m[ERROR]: check $inputR2.$extension\nQuitting\n\e[0m" && exit
	fi
#if input = fasta
elif [[ $extension == "fasta" ]]; then
	#make list of original seqs names
	grep ">" $inputR1.$extension | sed -e 's/>//' > R1o.names
	grep ">" $inputR2.$extension | sed -e 's/>//' > R2o.names
	
	#Rename sequences R1
	seqkit replace --quiet -p '.+' -r 'Seq{nr}' $inputR1.$extension > .R1.renamed.temp
	#Check errors
	if [ "$?" != "0" ]; then
		printf "\e[31m[ERROR 151]: check $inputR1.$extension\nQuitting\n\e[0m" && exit
	fi
	#Rename sequences R2
	seqkit replace --quiet -p '.+' -r 'Seq{nr}' $inputR2.$extension > .R2.renamed.temp
	#Check errors
	if [ "$?" != "0" ]; then
		printf "\e[31m[ERROR]: check $inputR2.$extension\nQuitting\n\e[0m" && exit
	fi

	#make list of renamed names 
	grep ">" .R1.renamed.temp | sed -e 's/>//' > R1r.names
	grep ">" .R2.renamed.temp | sed -e 's/>//' > R2r.names
	
	#merge names files 
		#(later used to keep the original headers at #Rename seqs back to original names based on R1.names and R2.names)
	awk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' R1r.names R1o.names > R1.names
	awk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' R2r.names R2o.names > R2.names
	rm R1o.names R1r.names R2o.names R2r.names
	
	cp .R1.renamed.temp .R1.renamed.fasta
	cp .R2.renamed.temp .R2.renamed.fasta
	
#else = error. Not supported file extension
else
	printf "\e[31m[ERROR]: $extension files extension ($extension) is not supported\nFiles as $extension.gz? Please fix\nQuitting\n\e[0m" && exit
fi
###PRE-PROCESSING DONE

###Reverse complement R2_file for stiching and demultiplexing
vsearch --fastx_revcomp .R2.renamed.fasta --quiet --fasta_width 0 --fastaout .R2.renamed.fasta.rc
#Check errors
if [ "$?" != "0" ]; then
	printf "\e[31m[ERROR]: check $inputR2.$extension\nQuitting\n\e[0m" && exit
fi
	
#Stitch R1 and R2 seqs for demultiplexing (this is not assembly process with overlap!)
tr "\n" "\t" < .R1.renamed.fasta | sed -e 's/>/\n>/g' | sed '/^\n*$/d' > .R1.temp
tr "\n" "\t" < .R2.renamed.fasta.rc | sed -e 's/>/\n>/g' | sed '/^\n*$/d' > .R2.temp
gawk 'BEGIN {FS=OFS="\t"} FNR==NR{a[$1]=$2;next} ($1 in a) {print $1,a[$1],$2}' .R1.temp .R2.temp > .R1R2.temp
sed -e 's/\t/\n/' < .R1R2.temp | sed -e 's/\t//' > .R1R2.fasta
rm .R1R2.temp
rm .R1.temp
rm .R2.temp
rm .R1.renamed.fasta
rm .R2.renamed.fasta.rc
rm .R2.renamed.fasta
#out = .R1R2.fasta for generating groups file with mothur

###Generate groups file for demultiplexing files to samples 
mothur --quiet "#trim.seqs(fasta=.R1R2.fasta, checkorient=t $barcodes_file $bdiffs $pdiffs $tdiffs $processors)" &> /dev/null
#relevant outputs = .R1R2.trim.fasta and .R1R2.groups (will be renamed to demux.groups)

#remove redundant files
[ -f .R1R2.scrap.fasta ] && rm .R1R2.scrap.fasta
[ -f .R1R2.scrap.qual ] && rm .R1R2.scrap.qual
[ -f .R1R2.trim.qual ] && rm .R1R2.trim.qual

#Check if sequences were demultiplexed
if [ -s .R1R2.trim.fasta ]; then
	#remove redundant files
	rm .R1R2.trim.fasta
	[ -f .R1R2.fasta ] && rm .R1R2.fasta
else
	printf "\e[31m[ERROR]: Seqs not assigned to samples. Please check barcodes file\nQuitting\n\e[0m" && rm demux.groups && exit
fi

#rename groups file
mv .R1R2.groups demux.groups

###Generate FASTQ/FASTA files per sample based on demux.groups file
#demux R1
printf "\nDemultiplexing R1\n"
python3 /execute/demux_FASTX_based_on_groupsFile.py .R1.renamed.temp $extension
#Check errors
if [ "$?" != "0" ]; then
	printf "\e[31m[ERROR 226]: check $inputR1.$extension\nQuitting\n\e[0m" && exit
fi
#remove redundant files
rm Relabelled_input.fastx
rm Relabelled_input.fastx.temp
[ -f .R1.renamed.temp ] && rm .R1.renamed.temp
#Move demux samples to demux_samples folder
if [ -d demux_samples ]; then
	printf "\e[35m   NOTE: 'demux_samples' directory exists in working folder. Deleting and making a new one\n\e[0m"
	rm -r demux_samples
fi
#make demux_samples folder and move all demultiplexed saples there
mkdir demux_samples
mv sample=*.$extension demux_samples
cd demux_samples
#rename sample file names
rename 's/sample=//' *.$extension
rename "s/.$extension/.R1.$extension/" *.$extension
cd ..

#demux R2
printf "Demultiplexing R2\n"
python3 /execute/demux_FASTX_based_on_groupsFile.py .R2.renamed.temp $extension
#Check errors
if [ "$?" != "0" ]; then
	printf "\e[31m[ERROR]: check $inputR2.$extension\nQuitting\n\e[0m" && exit
fi
#remove redundant files
rm Relabelled_input.fastx
rm Relabelled_input.fastx.temp
[ -f .R2.renamed.temp ] && rm .R2.renamed.temp
#Move demux samples to demux_samples folder
mv sample=*.$extension demux_samples
cd demux_samples
#rename sample file names
rename 's/sample=/R2./' *.$extension
rename "s/.$extension/.R2.$extension/" R2.*.$extension
rename "s/R2.//" R2.*.$extension

###fix seq headers (remove ";sample=" from seq headers)
for f in *.$extension; do sed -i 's/;sample=.*//' $f ; done
#Rename seqs back to original names based on R1.names and R2.names
for f in *.R1.$extension; do
	seqkit replace --quiet -p "(.+)" -r '{kv}' -k ../R1.names $f > $f.txt
	#Check errors
	if [ "$?" != "0" ]; then
		printf "\e[31m[ERROR]: failed at final renaming stage while working with $inputR1.$extension\nQuitting\n\e[0m" && exit
	fi
	mv $f.txt $f
	
done
for f in *.R2.$extension; do
	seqkit replace --quiet -p "(.+)" -r '{kv}' -k ../R2.names $f > $f.txt
	#Check errors
	if [ "$?" != "0" ]; then
		printf "\e[31m[ERROR]: failed at final renaming stage while working with $inputR2.$extension\nQuitting\n\e[0m" && exit
	fi
	mv $f.txt $f
done

###Stats for the demultiplexed sequences
printf "\n\e[1mDemultiplexed files\e[0m:\n"
seqkit stats *.$extension

###delete redundant files
cd ..
[ -f R1.names ] && rm R1.names
[ -f R2.names ] && rm R2.names
rm mothur.*.logfile

###Done, demultiplexed files in 'demux_samples' folder
printf "\n\e[1mReady. Demultiplexed files in 'demux_samples' folder\n\n\e[0m"
