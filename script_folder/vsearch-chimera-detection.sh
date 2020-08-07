#!/bin/sh
start=`date +%s`

denovo_filter(){
        for fastafile in *fastq
    do
        output='/input/vsearch-chimera-detection-output/'$f
        vsearch --uchime_denovo  $fastafile --nonchimeras outputfile  2> /input/vsearch-chimera-detection-output/quality-log
        #Modify output log
        echo "" & printf "%s\n\n" $fastafile' Chimera detection info:' & cat /input/vsearch-chimera-detection-output/quality-log
    done    
}

ref_filter(){
    for fastafile in *fastq
    do
        output='/input/vsearch-chimera-detection-output/'$f
        vsearch --uchime_ref  $fastafile --nonchimeras outputfile --db $database  2> /input/vsearch-chimera-detection-output/quality-log
        #Modify output log
        echo "" & printf "%s\n\n" $fastafile' Chimera detection info:' & cat /input/vsearch-chimera-detection-output/quality-log
    done    
}




echo "Chimera detection with vsearch"
end=`date +%s`
runtime=$((end-start))
echo $runtime