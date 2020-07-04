#!/bin/sh
vsearch -h
echo $ENV_FILE_TEST


###S
#run vsearch
echo "#Assembling sequneces with vsearch"
    #loop ->
    echo "#Assembling $R1 and $R2"
	vsearch --fastq_mergepairs $R1 --reverse $R2 --fastq_minovlen $minovlen \
    --maxdiffs $maxdiffs --fastq_minmergelen $minmergelen \
    --fastq_maxee $maxee --fastq_maxns $maxns \
    --fastq_truncqual $truncqual --fastq_allowmergestagger \
    --fastqout $output \
    --fastqout_notmerged_fwd $notmerged_fwd \
    --fastqout_notmerged_rev $notmerged_rev
    #compolsury options: fastq_minovlen, fastq_minmergelen
    #optional (cannot be as default vaules! Must be excluded if not selected): 
        #fastqout_notmerged_fwd, fastqout_notmerged_rev, fastq_truncqual, fastq_allowmergestagger, fastq_maxns, fastq_maxee, maxdiffs
    #note: no trimming needed if using optional vsearch options here (e.g. maxee)

echo "done"
echo "Paired-end sequences assembled with flash"
###S