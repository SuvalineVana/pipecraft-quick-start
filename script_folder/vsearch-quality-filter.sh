#!/bin/sh

if [ -d "vsearch-quality-filter-output" ]; then
    rm -r  vsearch-quality-filter-output
fi
mkdir vsearch-quality-filter-output

for f in *fastq*
do
    input=$f
    output='vsearch-quality-filter-output/'$f
    vsearch --fastq_filter $input --fastqout $output $fastq_maxee $fastq_maxns $fastq_maxlen $fastq_minlen $fastq_truncqual $fastq_maxee_rate $fastq_qmin 2> info
    cat info
done

###S ->  #compolsury options: --fastq_maxee, fastq_maxns, 
#optional: (cannot be as default vaules! Must be excluded if not selected): 
    # --fastq_maxee_rate, fastq_maxlen,  fastq_trunclen;
        #--fastq_minlen (default:1),


rm info