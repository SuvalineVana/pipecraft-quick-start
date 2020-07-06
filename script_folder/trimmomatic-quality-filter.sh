#!/bin/sh
java -jar /Trimmomatic-0.39/trimmomatic-0.39.jar -version
if [ -d "trimmomatic-quality-filter-output" ]; then
    rm -r  trimmomatic-quality-filter-output
fi
mkdir trimmomatic-quality-filter-output
mkdir trimmomatic-logs
echo $windowSize
echo $requiredQuality

#SLIDING WINDOW VARIABLES SETUP
if [[ -n "${windowSize/[ ]*\n/}" ]] || [[ -n "${requiredQuality/[ ]*\n/}" ]]
then
    windowSize=$(echo $windowSize | sed 's/[^0-9]*//g')
    requiredQuality=$(echo $requiredQuality | sed 's/[^0-9]*//g')
    SLIDINGWINDOW='SLIDINGWINDOW:'$windowSize':'$requiredQuality
else
    SLIDINGWINDOW=""
fi


#Trimmomatic SE for each fastq in folder
for f in *fastq*
do
	echo "Processing $f"
    input=$f
    output='trimmomatic-quality-filter-output/'$f
    logname='/input/trimmomatic-logs/'$f'_log.txt'
    echo $output
    echo $logname
    java -jar /Trimmomatic-0.39/trimmomatic-0.39.jar SE -phred33 -trimlog $logname $input $output $SLIDINGWINDOW $LEADING $TRAILING $MINLEN $AVGQUAL
done
