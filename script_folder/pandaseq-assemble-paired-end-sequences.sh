#!/bin/sh
start=`date +%s`

ls

pandaseq2=/pandaseq/pandaseq
pandaseq=/usr/local/bin/pandaseq
echo $pandaseq -h
$pandaseq -h
echo $pandaseq2 -h
$pandaseq2 -h

echo $o #minoverlap
echo $O #maxoverlap
echo $l #minlen
echo $L #maxlen
echo $writeUnpaired

# muutujad on kujul: -o 10 -O 50 -l 200 -L 300 , peaks saama otse commandis kasutada 

#Check writeUnpaired
if [ $writeUnpaired = "OFF" ]; then
  echo "works"
  U=""
else
  U="-U"
fi

echo "#Assembling sequneces with pandaseq"
for R1 in *R1*.fastq*
do
	echo "Processing $R1"
    R2=$(echo $R1 | sed 's/R1/R2/g')
    echo "Processing $R2"
    mergedName=$(echo $R1 | sed 's/R1/merged/g')
    output='/input/pandaseq-assemble-paired-end-sequences-output/'$mergedName
    # #logname='vsearch-quality-filter-output/'$f'_log.txt'
    #pandaseq -f $R1 -r $R2 -C -F -B $L $o $0 $l -g pandaseq_assembly.log > $output
    #this loop does not ye include saving outputs that did not merge
done
echo "Paired-end sequences assembled with pandaseq"
###S

#run pandaseq
#echo "#Assembling sequneces with pandaseq"
#     #loop ->
#     echo "#Assembling $R1 and $R2"
#     pandaseq -f $R1 -r $R2 -C -F -B -o $o -l $l -g pandaseq_assembly.log > $R1_$R2
 
#  #compolsury options: -o, -l
#     #optional (cannot be as default vaules! Must be excluded if not selected): 
#         #-O, min_phred, -L, -U, -k
        

# echo "done"
# echo "Paired-end sequences assembled with pandaseq"
###S

end=`date +%s`
runtime=$((end-start))
echo $runtime
