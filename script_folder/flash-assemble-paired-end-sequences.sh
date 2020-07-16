#!/bin/sh
start=`date +%s`

#Check for output dir create and write assing to variables
if [ -d "/input/flash-assemble-paired-end-sequences-output" ]; then
    rm -r  /input/flash-assemble-paired-end-sequences-output
fi
mkdir /input/flash-assemble-paired-end-sequences-output
mkdir /input/flash-assemble-paired-end-sequences-output/singles_and_unpaired

outputDir='/input/flash-assemble-paired-end-sequences-output/'
singlesAndUnpairedDir='/input/flash-assemble-paired-end-sequences-output/singles_and_unpaired/'

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

#flash core
echo "#Assembling sequneces with flash"
cd $outputDir
for R1 in *R1*.fastq*
do
    R2=$(echo $R1 | sed 's/R1/R2/g')
    echo $R1
    echo $R2
    mergedName=$(echo $R1 | sed 's/R1.*/merged/g')
    outputdir='/input/flash-assemble-paired-end-sequences-output/'
    output='/input/flash-assemble-paired-end-sequences-output/'$mergedName
    log='/input/flash-assemble-paired-end-sequences-output/'$(echo $mergedName | sed 's/merged/assembly_log.txt/g')
    flash2 $R1 $R2 $m $x $r $f $M $p $s -d $outputdir -o $mergedName > $log
    rm $R1 $R2
    cat $log
    rm $log
done
wait

find . -name '*.hist*' -delete
for notCombined in *.notCombined*; do mv "$notCombined" "$singlesAndUnpairedDir$notCombined"; done
#find . -name '*.notCombined*' -delete
for f in *.extendedFrags*; do mv "$f" "$(echo "$f" | sed s/\.extendedFrags//)"; done

echo "Paired-end sequences assembled with flash"

end=`date +%s`
runtime=$((end-start))
echo $runtime

###S
#run flash
#flash manual: http://ccb.jhu.edu/software/FLASH/MANUAL
    # #loop ->
    # echo "#Assembling $R1 and $R2"
    # flash $R1 $R2 -m $m -x $x -r $r -f $f > FLASH.log
    # #compolsury options: -m, -x, -r, -f
    # #optional: -p, -M, -o, -s
###S


# echo $m
# echo $x
# echo $r
# echo $f
# echo $M
# echo $s
# echo $p
