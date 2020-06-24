#!/bin/sh
echo $ENV_FILE_TEST

if [ -d "vsearch-quality-filter-output" ]; then
    rm -r  vsearch-quality-filter-output
fi
mkdir vsearch-quality-filter-output

for f in *fastq*
do
	#echo "Processing $f"
    input=$f
    output='vsearch-quality-filter-output/'$f
    #logname='vsearch-quality-filter-output/'$f'_log.txt'
    vsearch --fastq_filter $input --fastqout $output --fastq_maxee 1 --fastq_maxns 5 --fastq_qmin 0 --fastq_qmax 41  2> info
    cat info
done

rm info