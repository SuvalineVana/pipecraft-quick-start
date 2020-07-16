#!/bin/sh
start=`date +%s`

#Check for output dir create and write assing to variables
if [ -d "/input/pandaseq-assemble-paired-end-sequences-output" ]; then
    rm -r  /input/pandaseq-assemble-paired-end-sequences-output
fi
mkdir /input/pandaseq-assemble-paired-end-sequences-output
mkdir /input/pandaseq-assemble-paired-end-sequences-output/singles_and_unpaired

outputDir='/input/pandaseq-assemble-paired-end-sequences-output/'
singlesAndUnpairedDir='/input/pandaseq-assemble-paired-end-sequences-output/singles_and_unpaired/'

#Resynchronize 2 fastq files (R1 and R2, after they have been trimmed and cleaned)
for R1 in *R1*.fastq*
do
    R2=$(echo $R1 | sed 's/R1/R2/g')
    echo "Resynchronizing $R1 and $R2"
    fastqCombinePairedEnd.py $R1 $R2
done

#Rename and move synchronized outputs to proper folders
for fastqPairsR1 in *_pairs_R1.fastq; do mv "$fastqPairsR1" $outputDir"$(echo "$fastqPairsR1" | sed s/\_pairs_R1.fastq//)"; done
for fastqPairsR2 in *_pairs_R2.fastq; do mv "$fastqPairsR2" $outputDir"$(echo "$fastqPairsR2" | sed s/\_pairs_R2.fastq//)"; done
for fastqSingles in *_singles.fastq; do mv "$fastqSingles" "$singlesAndUnpairedDir$fastqSingles"; done

#Pandaseq core
echo "#Assembling sequneces with pandaseq"
cd $outputDir
for R1 in *R1*.fastq*
do
    R2=$(echo $R1 | sed 's/R1/R2/g')
    echo "Assembling $R1 and $R2"
    mergedName=$(echo $R1 | sed 's/R1.*/merged.fastq/g')
    output='/input/pandaseq-assemble-paired-end-sequences-output/'$mergedName
    log='/input/pandaseq-assemble-paired-end-sequences-output/'$(echo $mergedName | sed 's/merged.fastq/assembly_log.txt/g')
    unpaired='/input/pandaseq-assemble-paired-end-sequences-output/'$(echo $mergedName | sed 's/merged.*/unpaired.fastq/g')
    
    #Check writeUnpaired
    if [ $writeUnpaired = "OFF" ]; then U=""; else U="-U "$unpaired; fi
    
    pandaseq -F -B -f $R1 -r $R2 $o $l $O $L -g $log $U 1> $output
    rm $R1 $R2
    sed -n '/STAT/p' $log
done
echo "Paired-end sequences assembled with pandaseq"
wait
for unPaired in *unpaired.fastq*; do mv "$unPaired" "$singlesAndUnpairedDir$unPaired"; done

end=`date +%s`
runtime=$((end-start))
echo 'Total time:' $runtime 'seconds'
