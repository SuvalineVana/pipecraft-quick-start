#!/bin/sh
start=`date +%s`

#Manage output folder
if [ -d "/input/vsearch-quality-filter-output" ]; then
    rm -r  /input/vsearch-quality-filter-output
fi
mkdir /input/vsearch-quality-filter-output

#For each fastq --fastq_filter with user parameters
echo "#Filtering sequneces with vsearch"
for f in *fastq*
do
    input=$f
    output='/input/vsearch-quality-filter-output/'$f
    vsearch --fastq_filter $input --fastqout $output $fastq_maxee $fastq_maxns $fastq_maxlen $fastq_minlen $fastq_truncqual $fastq_maxee_rate $fastq_qmin 2> /input/vsearch-quality-filter-output/quality-log
    #Modify output log
    echo "" & printf "%s\n\n" $input' Filter info:' & cat /input/vsearch-quality-filter-output/quality-log
done
#Remove unnecessary files
rm /input/vsearch-quality-filter-output/quality-log

echo "Sequences filtered with vsearch"

end=`date +%s`
runtime=$((end-start))
echo $runtime
###S ->  #compolsury options: --fastq_maxee, fastq_maxns, 
#optional: (cannot be as default vaules! Must be excluded if not selected): 
    # --fastq_maxee_rate, fastq_maxlen,  fastq_trunclen;
        #--fastq_minlen (default:1),
###S