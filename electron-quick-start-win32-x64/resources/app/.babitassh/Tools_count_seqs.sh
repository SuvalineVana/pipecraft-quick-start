#!/bin/bash 

echo "### Counting sequences ###"
echo ""

#Set working directory
USER_HOME=$(eval echo ~${SUDO_USER})

if [ -e ${USER_HOME}/.var_babitas/fasta_location.txt ] && [ -e ${USER_HOME}/.var_babitas/fastq_location.txt ]; then
WorkingDirectory=$(awk 'BEGIN{FS=OFS="/"} NF{NF--};1' < ${USER_HOME}/.var_babitas/fasta_location.txt)
fasta=$(cat ${USER_HOME}/.var_babitas/fasta_location.txt)
fastq=$(cat ${USER_HOME}/.var_babitas/fastq_location.txt)

cd $WorkingDirectory
			if [ "$?" = "0" ]; then
 			echo ""
			else
			touch ${USER_HOME}/.var_babitas/tools_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi

size=$(echo $(cat $fastq | wc -l) / 4 | bc)

echo ""
echo "FASTA file = $fasta"
echo ""
echo "########################"
echo "Your FASTA file contains" 
grep -c "^>" $fasta 
echo "sequences" 
echo "########################"


echo ""
echo "FASTQ file = $fastq"
echo ""
echo "###############################"
echo "Your FASTQ file contains" 
echo $size 
echo "sequences" 
echo "###############################"
echo "You may close this window now!"
			if [ "$?" = "0" ]; then
 			touch ${USER_HOME}/.var_babitas/tools_finished.txt
			rm ${USER_HOME}/.var_babitas/fasta_location.txt
			rm ${USER_HOME}/.var_babitas/fastq_location.txt
			exit 1
			else
			touch ${USER_HOME}/.var_babitas/tools_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi




else if [ -e ${USER_HOME}/.var_babitas/fasta_location.txt ]; then
WorkingDirectory=$(awk 'BEGIN{FS=OFS="/"} NF{NF--};1' < ${USER_HOME}/.var_babitas/fasta_location.txt)
fasta=$(cat ${USER_HOME}/.var_babitas/fasta_location.txt)

cd $WorkingDirectory
			if [ "$?" = "0" ]; then
 			echo ""
			else
			touch ${USER_HOME}/.var_babitas/tools_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi
echo ""
echo "FASTA file = $fasta"
echo ""
echo "###############################"
echo "Your FASTA file contains" 
grep -c "^>" $fasta 
echo "sequences" 
echo "###############################"
echo "You may close this window now!"

			if [ "$?" = "0" ]; then
 			touch ${USER_HOME}/.var_babitas/tools_finished.txt 
			rm ${USER_HOME}/.var_babitas/fasta_location.txt
			else
			touch ${USER_HOME}/.var_babitas/tools_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi



	else if [ -e ${USER_HOME}/.var_babitas/fastq_location.txt ]; then
	WorkingDirectory=$(awk 'BEGIN{FS=OFS="/"} NF{NF--};1' < ${USER_HOME}/.var_babitas/fastq_location.txt)
	fastq=$(cat ${USER_HOME}/.var_babitas/fastq_location.txt)

	cd $WorkingDirectory
			if [ "$?" = "0" ]; then
 			echo ""
			else
			touch ${USER_HOME}/.var_babitas/tools_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi


	size=$(echo $(cat $fastq | wc -l) / 4 | bc)
	

	echo ""
	echo "FASTQ file = $fastq"
	echo ""
	echo "###############################"
	echo "Your FASTQ file contains" 
	echo $size 
	echo "sequences" 
	echo "###############################"
	echo "You may close this window now!"
			if [ "$?" = "0" ]; then
 			touch ${USER_HOME}/.var_babitas/tools_finished.txt 
			rm ${USER_HOME}/.var_babitas/fastq_location.txt
			else
			touch ${USER_HOME}/.var_babitas/tools_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi


	fi
fi
fi
















