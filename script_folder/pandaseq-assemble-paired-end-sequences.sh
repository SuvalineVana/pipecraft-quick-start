#!/bin/sh
start=`date +%s`
mkdir pandaseq-assemble-paired-end-sequences-output

echo "#Assembling sequneces with pandaseq"
for R1 in *R1*.fastq*
do
    R2=$(echo $R1 | sed 's/R1/R2/g')
    mergedName=$(echo $R1 | sed 's/R1.*/merged.fastq/g')
    output='/input/pandaseq-assemble-paired-end-sequences-output/'$mergedName
    log='/input/pandaseq-assemble-paired-end-sequences-output/'$(echo $mergedName | sed 's/.fastq/_assembly_log.txt/g')
    unpaired='/input/pandaseq-assemble-paired-end-sequences-output/'$(echo $mergedName | sed 's/merged.*/unpaired.txt/g')
    
    #Check writeUnpaired
    if [ $writeUnpaired = "OFF" ]; then
      echo "works"
      U=""
    else
      U="-U "$unpaired
    fi

    pandaseq -F -B -f $R1 -r $R2 $o $l $O $L -g $log $U 1> $output
done
echo "Paired-end sequences assembled with pandaseq"
wait

end=`date +%s`
runtime=$((end-start))
echo $runtime
