#!/bin/sh
pandaseq -h
start=`date +%s`

echo $o #minoverlap
echo $O #maxoverlap
echo $l #minlen
echo $L #maxlen

# muutujad on kujul: -o 10 -O 50 -l 200 -L 300 , peaks saama otse commandis kasutada 


###S

#run pandaseq
echo "#Assembling sequneces with pandaseq"
    #loop ->
    echo "#Assembling $R1 and $R2"
    pandaseq -f $R1 -r $R2 -C -F -B -o $o -l $l -g pandaseq_assembly.log > $R1_$R2
 
 #compolsury options: -o, -l
    #optional (cannot be as default vaules! Must be excluded if not selected): 
        #-O, min_phred, -L, -U, -k
        

echo "done"
echo "Paired-end sequences assembled with pandaseq"
###S
