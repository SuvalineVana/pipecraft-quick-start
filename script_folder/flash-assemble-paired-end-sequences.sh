#!/bin/sh
start=`date +%s`

if [ -d "/input/flash-assemble-paired-end-sequences-output" ]; then
    rm -r  /input/flash-assemble-paired-end-sequences-output
fi
mkdir /input/flash-assemble-paired-end-sequences-output

# echo $m
# echo $x
# echo $r
# echo $f
# echo $M
# echo $s
# echo $p

flash2 -v

echo "#Assembling sequneces with flash"
for R1 in *R1*.fastq*
do
    R2=$(echo $R1 | sed 's/R1/R2/g')
    echo $R1
    echo $R2
    mergedName=$(echo $R1 | sed 's/R1.*/merged/g')
    outputdir='/input/flash-assemble-paired-end-sequences-output/'
    output='/input/flash-assemble-paired-end-sequences-output/'$mergedName
    log='/input/flash-assemble-paired-end-sequences-output/'$(echo $mergedName | sed 's/merged/assembly_log.txt/g')
    echo $log
    flash2 $R1 $R2 $m $x $r $f $M $p $s -d $outputdir -o $mergedName > $log
    cat $log
done
wait

cd /input/flash-assemble-paired-end-sequences-output
find . -name '*.hist*' -delete
find . -name '*.notCombined*' -delete
for f in *.extendedFrags*; do mv "$f" "$(echo "$f" | sed s/\.extendedFrags//)"; done

echo 'done'
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