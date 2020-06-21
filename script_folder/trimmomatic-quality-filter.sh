#!/bin/sh
echo $ENV_FILE_TEST
$TRIMMOMATIC -version

for f in *
do
	echo "Processing $f"
    $TRIMMOMATIC -version
done
