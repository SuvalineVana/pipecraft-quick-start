#!/bin/bash 

echo "### Renaming sequences ###"
echo " # using awk"
echo ""


#Set working directory
USER_HOME=$(eval echo ~${SUDO_USER})


#Rename fasta file
if [ -e ${USER_HOME}/.var_babitas/fasta7.txt ]; then


WorkingDirectory=$(awk 'BEGIN{FS=OFS="/"} NF{NF--};1' < ${USER_HOME}/.var_babitas/fasta7.txt)
fasta=$(cat ${USER_HOME}/.var_babitas/fasta7.txt)

rename_fasta=$(cat ${USER_HOME}/.var_babitas/rename.txt)

cd $WorkingDirectory
			if [ "$?" = "0" ]; then
 			echo ""
			else
			touch ${USER_HOME}/.var_babitas/tools_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi

echo "Renaming to -> $rename_fasta"
echo""

awk '{print (NR%2 == 1) ? ">'$rename_fasta'" ++i : $0}' < $fasta > $fasta.renamed.fasta
			if [ "$?" = "0" ]; then
			echo "#############################"
			echo "DONE"
			echo "#############################"
			echo "output = $fasta.renamed.fasta"
			echo "#############################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/tools_finished.txt
			else
			touch ${USER_HOME}/.var_babitas/tools_error.txt && echo "# ERROR #" 1>&2 && echo "Close this window" && exit 1
			fi



	#Rename fastq file
	else if [ -e ${USER_HOME}/.var_babitas/fastq7.txt ]; then

	WorkingDirectory=$(awk 'BEGIN {FS="/"} {$NF=""; print $0}' < ${USER_HOME}/.var_babitas/fastq7.txt | tr " " "/")
	fastq=$(cat ${USER_HOME}/.var_babitas/fastq7.txt)

	rename_fastq=$(cat ${USER_HOME}/.var_babitas/rename.txt)

	cd $WorkingDirectory
				if [ "$?" = "0" ]; then
	 			echo ""
				else
				touch ${USER_HOME}/.var_babitas/tools_error.txt 
				echo "An unexpected error has occurred!  Aborting." 1>&2
				exit 1
				fi

	echo "Renaming to -> $rename_fastq"
	echo""
	awk '{print (NR%4 == 1) ? "@'$rename_fastq'" ++i : $0}' < $fastq > $fastq.renamed.fastq
			if [ "$?" = "0" ]; then
			echo "#############################"
			echo "DONE"
			echo "#############################"
			echo "output = $fastq.renamed.fastq"
			echo "#############################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/tools_finished.txt
			else
			touch ${USER_HOME}/.var_babitas/tools_error.txt && echo "# ERROR #" 1>&2 && echo "Close this window" && exit 1
			fi

	fi
fi









