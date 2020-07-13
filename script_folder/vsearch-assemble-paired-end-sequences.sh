#!/bin/sh
start=`date +%s`

if [ -d "/input/vsearch-assemble-paired-end-sequences-output" ]; then
    rm -r  /input/vsearch-assemble-paired-end-sequences-output
fi
mkdir /input/vsearch-assemble-paired-end-sequences-output
mkdir /input/vsearch-assemble-paired-end-sequences-output/singles_and_unpaired

#Resynchronize 2 fastq or fastq.gz files (R1 and R2) after they have been trimmed and cleaned
for R1 in *R1*.fastq*
do
    R2=$(echo $R1 | sed 's/R1/R2/g')
    echo "Resynchronizing $R1 and $R2"
    fastqCombinePairedEnd.py $R1 $R2
fi


#Clean-up after Resynchronization
# NCMV166_S153_L001_R1_001.fastq
# NCMV166_S153_L001_R2_001.fastq
# NCMV166_S153_L001_R1_001.fastq_pairs_R1.fastq
# NCMV166_S153_L001_R2_001.fastq_pairs_R2.fastq
# NCMV166_S153_L001_R1_001.fastq_singles.fastq 


# echo $fastq_minmergelen
# echo $mergestagger
# echo $fastq_minovlen
# echo $fastq_maxdiffs

#Check mergestaggering
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

for R1 in *R1*.fastq*
do
	echo "Processing $R1"
    R2=$(echo $R1 | sed 's/R1/R2/g')
    echo "Processing $R2"
    mergedName=$(echo $R1 | sed 's/R1.*/merged.fastq/g')
    output='/input/vsearch-assemble-paired-end-sequences-output/'$mergedName
    log='/input/vsearch-assemble-paired-end-sequences-output/'$(echo $mergedName | sed 's/merged.fastq/assembly_log.txt/g')
    vsearch --fastq_mergepairs $R1 --reverse $R2 --fastqout $output $minovlen $fastq_minmergelen $fastq_maxdiffs $mergestagger 2> $log
    cat $log
    #this loop does not ye include saving outputs that did not merge
done

echo "done"
echo "Paired-end sequences assembled with flash"

end=`date +%s`
runtime=$((end-start))
echo $runtime
###S

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