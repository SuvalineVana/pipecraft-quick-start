#!/bin/sh

gunzip *fastq.gz

for f in *fastq
do
    echo "Processing" $f
    input=$f
    output='/input/mothur-quality-filter-output/'
    #logname='mothur-quality-filter-output/'$f'_log.txt'
    echo $output
    mothur "#set.dir(output=$output);fastq.info(fastq=$input)"
done

cd $output

for fa in *fasta
do 
    mothur "#trim.seqs(fasta=$fa $qwindowaverage $qwindowsize $maxambig $qthreshold $minlength $maxlength $processors)"
done