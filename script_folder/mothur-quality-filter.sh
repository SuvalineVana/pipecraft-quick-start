#!/bin/sh
start=`date +%s`

#unzip fastq.qz file(s) for mothur
gunzip *fastq.gz


output='/input/mothur-quality-filter-output/'
rm -r -f $output

# ##S
# #Renaming R1 and R2 fastq files so the files would be suitable for PandaSeq
# tr " " "Ã" < $R1fastq > R1r.fastq
# tr " " "Ã" < $R2fastq > R1r.fastq #loop and change to variables. These are inputs for the next step
# ##S

#Split fastq file(s) into fasta and qual file(s)
for f in *fastq
do
    echo "Processing" $f
    sed -i 's/ /Ã/g' $f
    #logname='mothur-quality-filter-output/'$f'_log.txt'
    mothur "#fastq.info(fastq=$f, outputdir=$output)" &
    sed -i 's/Ã/ /g' $f
done
wait

#move to output folder
cd $output

#trim sequences using user set parameters
for fa in *fasta
do 
    qfile=$(echo $fa | sed 's/.fasta/.qual/g')
    mothur "#trim.seqs(fasta=$fa $qwindowaverage $qwindowsize $maxambig $qthreshold $minlength $maxlength $processors, qfile=$qfile)" &
done
wait

pwd

for trim in *trim.fasta
do 
    qfile=$(echo $trim | sed 's/.fasta/.qual/g')
    mothur "#sort.seqs(fasta=$trim, qfile=$qfile)" &
done
wait



echo "making fastq"
# #merge qual and fasta file(s) back into fastq file(s)
# #https://github.com/mothur/mothur/issues/681
for fa in *trim.sorted.fasta
do 
    qfile=$(echo $fa | sed 's/.fasta/.qual/g')
    echo $qfile
    mothur "#make.fastq(fasta=$fa, qfile=$qfile)" &
done
wait
echo "fastq ready"

#Restore original Illumina headers
for fas in *.fastq
do
    sed -i 's/Ã/ /g' $fas
    sed -i 's/_/:/g' $fas   
done

#Delete all unnecessary files
find . -type f \! -name "*.fastq" -delete





# ###S
# #Renaming R1 and R2 back to original names (so that the assemblers could work)
# tr "Ã" " " < R1r.trim.fastq > R1r.trim_x.fastq
# tr "_" ":" < R1r.trim_x.fastq > R1r.trim.fastq_nameOK.fastq
# rm R1r.trim_x.fastq

# tr "Ã" " " < R2r.trim.fastq > R2r.trim_x.fastq
# tr "_" ":" < R2r.trim_x.fastq > R2r.trim.fastq_nameOK.fastq
# rm R2r.trim_x.fastq

# #Sorting out only paired R1 and R2 sequences (singles into separate fastq)
# #python code from github.com/enormandeau/Scripts/blob/master/fastqCombinePairedEnd.py 
# python fastqCombinePairedEnd.txt R1r.trim.fastq_nameOK.fastq R2r.trim.fastq_nameOK.fastq

# cat R1r.trim.fastq_nameOK.fastq_pairs_R1.fastq | paste - - - - | sort -k1,1 -t " " | tr "\t" "\n" > R1.trim_pairs_sorted_to_assembling.fastq
# cat R2r.trim.fastq_nameOK.fastq_pairs_R2.fastq | paste - - - - | sort -k1,1 -t " " | tr "\t" "\n" > R2.trim_pairs_sorted_to_assembling.fastq
# ###S

#remove all unnecessary file(s)
end=`date +%s`
runtime=$((end-start))
echo $runtime