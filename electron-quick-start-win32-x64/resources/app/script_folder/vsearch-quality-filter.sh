#!/bin/sh

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
    vsearch --fastq_filter $input --fastqout $output $fastq_maxee $fastq_maxns $fastq_maxlen $fastq_minlen $fastq_truncqual $fastq_maxee_rate $fastq_qmin 2> info
    cat info
done

rm info