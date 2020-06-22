#!/bin/sh
echo $ENV_FILE_TEST
$TRIMMOMATIC -version
mkdir trimmomatic-quality-filter-output

for f in *fastq*
do
	echo "Processing $f"
    input=$f
    output='trimmomatic-quality-filter-output/'$f
    logname='trimmomatic-quality-filter-output/'$f'_log'
    #echo $output
    #echo $logname
    $TRIMMOMATIC SE -phred33 -trimlog $logname $input $output $LEADING $TRAILING $MINLEN $AVG
done
