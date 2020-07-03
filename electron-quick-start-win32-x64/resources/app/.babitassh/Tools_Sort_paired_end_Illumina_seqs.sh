#!/bin/bash 

#Set working directory
USER_HOME=$(eval echo ~${SUDO_USER})

WorkingDirectory=$(awk 'BEGIN{FS=OFS="/"} NF{NF--};1' < ${USER_HOME}/.var_babitas/R1_location.txt)
cd $WorkingDirectory
		if [ "$?" = "0" ]; then
 		echo ""
		else
		touch ${USER_HOME}/.var_babitas/tools_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi


#Set R1 and R2.fastq files as variables
R1fastq=$(cat ${USER_HOME}/.var_babitas/R1_location.txt)
R2fastq=$(cat ${USER_HOME}/.var_babitas/R2_location.txt)



#Sorting out only paired R1 and R2 sequences (singles into separate fastq)
echo "### Sorting out only paired R1 and R2 sequences ###"
echo ""
echo "using fastqCombinePairedEnd.py"
echo "github.com/enormandeau/Scripts/blob/master/fastqCombinePairedEnd.py"
echo "Distributed under the GNU General Public License version 3 by the Free Software Foundation"
echo "____________________________________________________"
echo ""
echo ""
echo "R1 = $R1fastq"
echo "R2 = $R2fastq"
echo ""

python ${USER_HOME}/.babitassh/fastqCombinePairedEnd2.txt $R1fastq $R2fastq
			if [ "$?" = "0" ]; then
 			echo ""
			else
			touch ${USER_HOME}/.var_babitas/tools_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi


#Sorting R1 and R2 sequences to match for assembling
cat $R1fastq.pairs_R1.fastq | paste - - - - | sort -k1,1 -t " " | tr "\t" "\n" > R1_pairs_sorted_for_assembling.fastq

cat $R2fastq.pairs_R2.fastq | paste - - - - | sort -k1,1 -t " " | tr "\t" "\n" > R2_pairs_sorted_for_assembling.fastq


	if [ "$?" = "0" ]; then
		touch ${USER_HOME}/.var_babitas/tools_finished.txt
		echo ""
		echo "##########################"
		echo "DONE"
		echo "##############################"
		echo "output = R1_pairs_sorted_for_assembling.fastq"
		echo "output = R2_pairs_sorted_for_assembling.fastq"
		echo "################################"
		echo "You may close this window now!"

			else 
			touch ${USER_HOME}/.var_babitas/tools_error.txt
			echo "ERROR ..."
	fi
