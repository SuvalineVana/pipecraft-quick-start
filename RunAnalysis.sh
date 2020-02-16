#!/bin/sh
# This is a comment!
cutadapt -a ADAPTER_FWD -A ADAPTER_REV -o out.1.fastq -p out.2.fastq reads.1.fastq reads.2.fastq

Single-end/R1 option	Corresponding option for R2
--adapter, -a	-A
--front, -g	-G
--anywhere, -b	-B
--cut, -u	-U


