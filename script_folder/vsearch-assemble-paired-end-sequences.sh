#!/bin/sh
#vsearch -h
mkdir vsearch-assemble-paired-end-sequences-output
echo $fastq_minmergelen
echo $mergestagger
echo $fastq_minovlen
echo $fastq_maxdiffs

if [ $mergestagger == "ON" ]
then
    echo 'mergestagger ON'
    mergestagger='--fastq_allowmergestagger'
else
    echo 'mergestagger OFF'
    mergestagger='--fastq_nostagger'
fi

echo $mergestagger
echo "#Assembling sequneces with vsearch"

    # #loop ->
    # echo "#Assembling $R1 and $R2"
	# vsearch --fastq_mergepairs $R1 --reverse $R2 --fastq_minovlen $minovlen \
    # --maxdiffs $maxdiffs --fastq_minmergelen $minmergelen \
    # --fastq_maxee $maxee --fastq_maxns $maxns \
    # --fastq_truncqual $truncqual --fastq_allowmergestagger \
    # --fastqout $output \
    # --fastqout_notmerged_fwd $notmerged_fwd \
    # --fastqout_notmerged_rev $notmerged_rev
    # #compolsury options: fastq_minovlen, fastq_minmergelen
    # #optional (cannot be as default vaules! Must be excluded if not selected): 
    #     #fastqout_notmerged_fwd, fastqout_notmerged_rev, fastq_truncqual, fastq_allowmergestagger, fastq_maxns, fastq_maxee, maxdiffs
    # #note: no trimming needed if using optional vsearch options here (e.g. maxee)
for R1 in *R1*.fastq*
do
	echo "Processing $R1"
    R2=$(echo $R1 | sed 's/R1/R2/g')
    echo "Processing $R2"
    mergedName=$(echo $R1 | sed 's/R1/merged/g')
    output='/input/vsearch-assemble-paired-end-sequences-output/'$mergedName
    # #logname='vsearch-quality-filter-output/'$f'_log.txt'
    vsearch --fastq_mergepairs $R1 --reverse $R2 --fastqout $output $minovlen $fastq_minmergelen $fastq_maxdiffs $mergestagger 2> info
    cat info
done

echo "done"
echo "Paired-end sequences assembled with flash"
###S