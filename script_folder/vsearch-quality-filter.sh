#!/bin/sh
vsearch -h
echo $ENV_FILE_TEST
#    vsearch --fastq_filter fastqfile [--reverse fastqfile] (--fastaout | --fastaout_discarded | --fastqout |
#   --fastqout_discarded --fastaout_rev|--fastaout_discarded_rev|--fastqout_rev|--fastqout_discarded_rev) outputfile [options]
rm -r  vsearch-quality-filter-output
mkdir vsearch-quality-filter-output

# for f in *fastq*
# do
# 	echo "Processing $f"
#     input=$f
#     output='vsearch-quality-filter-output/'$f
#     #logname='vsearch-quality-filter-output/'$f'_log'
#     #echo $output
#     #echo $logname
#     vsearch --fastq_filter $input --fastqout $output --fastq_maxee 1 --fastq_qmin 25
# done