#!/bin/sh
start=`date +%s`

#unzip fastq.qz file(s) for mothur
gunzip *fastq.gz


output='/input/mothur-quality-filter-output/'
rm -r -f $output

#Split fastq file(s) into fasta and qual file(s)
for f in *fastq
do
    echo "Processing" $f
    #logname='mothur-quality-filter-output/'$f'_log.txt'
    # , outputdir=/input/mothur-quality-filter-output/
    mothur "#fastq.info(fastq=$f, outputdir=$output)" &
done
wait

#move to output folder
cd $output

#trim sequences using user set parameters
for fa in *fasta
do 
    qfile=$(echo $fa | sed 's/.fasta/.qual/g')
    mothur "#trim.seqs(fasta=$fa $qwindowaverage $qwindowsize $maxambig $qthreshold $minlength $maxlength $processors, qfile=$qfile)" &
done
wait

# pwd
# find . -type f \! -name "*scrap*" -delete
# ls


# #merge qual and fasta file(s) back into fastq file(s)
# #https://github.com/mothur/mothur/issues/681
# for fa in *trim.fasta
# do 
#     qfile=$(echo $fa | sed 's/.fasta/.qual/g')
#     echo $qfile
#     mothur "#make.fastq(fasta=$fa, qfile=$qfile)" &
# done

#remove all unnecessary file(s)
end=`date +%s`
runtime=$((end-start))
echo $runtime