#!/bin/sh

#unzip fastq.qz file(s) for mothur
gunzip *fastq.gz

#Set output dir and split fastq file(s) into fasta and qual file(s)
for f in *fastq
do
    echo "Processing" $f
    input=$f
    output='/input/mothur-quality-filter-output/'
    #logname='mothur-quality-filter-output/'$f'_log.txt'
    echo $output
    mothur "#set.dir(output=$output);fastq.info(fastq=$input)" &
done

#move to output folder
cd $output

#trim sequences using user set parameters
for fa in *fasta
do 
    mothur "#trim.seqs(fasta=$fa $qwindowaverage $qwindowsize $maxambig $qthreshold $minlength $maxlength $processors)" &
done

#merge qual and fasta file(s) back into fastq file(s)
for fa in *fasta
do 
    qfile=$(echo $fa | sed 's/.fasta/.qual/g')
    echo $qfile
    mothur "#make.fastq(fasta=$fa, qfile=$qfile)" &
done

#remove all unnecessary file(s)