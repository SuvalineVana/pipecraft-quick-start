#!/bin/sh
java -jar /Trimmomatic-0.39/trimmomatic-0.39.jar -version
if [ -d "trimmomatic-quality-filter-output" ]; then
    rm -r  trimmomatic-quality-filter-output
fi
mkdir trimmomatic-quality-filter-output
echo $windowSize
echo $requiredQuality

#SLIDING WINDOW VARIABLES SETUP
if [[$windowSize ==" "] || [$requiredQuality ==" "]]
then
    SLIDINGWINDOW=""
else
    windowSize=$(echo $windowSize | sed 's/[^0-9]*//g')
    requiredQuality=$(echo $requiredQuality | sed 's/[^0-9]*//g')
    echo $windowSize
    echo $requiredQuality
    SLIDINGWINDOW='SLIDINGWINDOW:'$windowSize':'$requiredQuality
    echo $SLIDINGWINDOW
fi

#Trimmomatic SE for each fastq in folder
for f in *fastq*
do
	echo "Processing $f"
    input=$f
    output='trimmomatic-quality-filter-output/'$f
    logname='trimmomatic-quality-filter-output/'$f'_log.txt'
    echo $output
    echo $logname
    java -jar /Trimmomatic-0.39/trimmomatic-0.39.jar SE -phred33 -trimlog $logname $input $output $SLIDINGWINDOW $LEADING $TRAILING $MINLEN $AVGQUAL
done
