#!/bin/sh
cutadapt -h
echo $ENV_FILE_TEST
trim3 cutadapt -a AACCGGTT -o output.fastq input.fastq
trim5