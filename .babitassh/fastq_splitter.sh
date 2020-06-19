#!/bin/bash -e

USER_HOME=$(eval echo ~${SUDO_USER})

#Set working directory
WorkingDirectory=$(awk 'BEGIN{FS=OFS="/"} NF{NF--};1' < ${USER_HOME}/.var_babitas/R1_location.txt)
		if [ "$?" = "0" ]; then
 		echo "Working directory = $WorkingDirectory"
		else
		touch ${USER_HOME}/.var_babitas/fastq_splitter_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi


#Enter working directory
cd $WorkingDirectory
		if [ "$?" = "0" ]; then
 		echo ""
		else
		touch ${USER_HOME}/.var_babitas/fastq_splitter_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi


#Set R1 and R2 input variable
inputR1=$(cat ${USER_HOME}/.var_babitas/R1_location.txt)
inputR2=$(cat ${USER_HOME}/.var_babitas/R2_location.txt)


#Set part-size variable
size=$(cat ${USER_HOME}/.var_babitas/split_fastq.txt)



#############################
#Split R1 and R2 fastq files#
#############################
perl ${USER_HOME}/.babitassh/fastq-splitter.pl --part-size $size --measure count $inputR1
if [ "$?" = "0" ]; then
 		echo "Read1, splitting done"
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/fastq_splitter_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi

perl ${USER_HOME}/.babitassh/fastq-splitter.pl --part-size $size --measure count $inputR2
		if [ "$?" = "0" ]; then
 		echo "Read2, splitting done"
		echo ""
		echo "Splitting FINISHED"
		echo ""
		echo "You may close this window now!"
		echo ""
		touch ${USER_HOME}/.var_babitas/fastq_splitter_finished.txt
		else
		touch ${USER_HOME}/.var_babitas/fastq_splitter_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi



