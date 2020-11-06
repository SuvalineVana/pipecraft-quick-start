#!/bin/sh
start=`date +%s`


echo "This is Mothur Demulitplexer pre-script"
echo $bdiffs
echo $pdiffs
echo $tdiffs
echo $min_unique_size
echo $fwdPrimers
echo $revPrimers
echo $inputFilesArray
echo $oligosFile
echo $seqTech
echo $reOrient



end=`date +%s`
runtime=$((end-start))
echo $runtime