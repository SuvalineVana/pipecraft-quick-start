#!/bin/sh
#cd Trimmomatic-0.39/
#java -jar trimmomatic-0.39.jar
echo $ENV_FILE_TEST
echo $TRIMMOMATIC
$TRIMMOMATIC PE 

MINLEN: Drop the read if it is below a specified length
AVGQUAL: Drop the read if the average quality is below the specified level