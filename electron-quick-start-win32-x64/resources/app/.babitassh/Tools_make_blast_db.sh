#!/bin/bash 

echo "### Creating BLAST database ###"
echo " # using blastn application - Camacho, C., et al., 2009. BLAST plus: architecture and applications. BMC Bioinformatics 10."
echo "www.ncbi.nlm.nih.gov/books/NBK279690/"
echo ""


#Set working directory
USER_HOME=$(eval echo ~${SUDO_USER})

if [ -e ${USER_HOME}/.var_babitas/fasta12.txt ]; then

WorkingDirectory=$(awk 'BEGIN{FS=OFS="/"} NF{NF--};1' < ${USER_HOME}/.var_babitas/fasta12.txt)

fasta=$(cat ${USER_HOME}/.var_babitas/fasta12.txt)


cd $WorkingDirectory
			if [ "$?" = "0" ]; then
 			echo ""
			else
			touch ${USER_HOME}/.var_babitas/tools_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi




#Make BLAST database

makeblastdb -in $fasta -dbtype nucl -out $fasta.DB
		if [ "$?" = "0" ]; then
 		touch ${USER_HOME}/.var_babitas/tools_finished.txt
		echo ""
		echo "##########################"
		echo "DONE"
		echo "############################"
		echo "makeblastdb finished"
		echo "##############################"
		echo "Created 3 files (nhr, nin, nsq)"
		echo "output = $fasta.DB"
		echo "################################"
		echo "You may close this window now!"
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/tools_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi

fi












