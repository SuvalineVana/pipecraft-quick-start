#!/bin/bash 


echo "### BLAST ###"
echo ""
echo "When using the incorporated tools, please cite as follows:"
echo ""
echo "blastn - Camacho, C., et al., 2009. BLAST plus: architecture and applications. BMC Bioinformatics 10."
echo "www.ncbi.nlm.nih.gov/books/NBK279690/"
echo ""
echo "mothur - Schloss, P.D., et al., 2009. Introducing mothur: Open-Source, Platform-Independent, Community-Supported Software for Describing and Comparing Microbial Communities. Applied and Environmental Microbiology 75, 7537-7541."
echo "Distributed under the GNU General Public License version 2 by the Free Software Foundation"
echo "www.mothur.org"
echo "________________________________________________"


USER_HOME=$(eval echo ~${SUDO_USER})

	

#Set working directory
WorkingDirectory=$(awk 'BEGIN{FS=OFS="/"} NF{NF--};1' < ${USER_HOME}/.var_babitas/rep_set.txt)
		if [ "$?" = "0" ]; then
 		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi


cd $WorkingDirectory
		if [ "$?" = "0" ]; then
 		echo "Working directory="$WorkingDirectory
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi



### Representative sequences

### Method = abundance
if grep -q 'Abundance' ${USER_HOME}/.var_babitas/rep_set_method.txt; then

echo "# Choose representative sequences"
echo "# Method = abundance"
# select cluster file and filtered fasta file (either the file that was submitted to gene extraction or the file that was outputted by some gene extractor. The difference will be first file containing the conservative genes, the other one includes just a specific region).

cluster_file=$(cat ${USER_HOME}/.var_babitas/cluster_file.txt)
filtered_fasta=$(cat ${USER_HOME}/.var_babitas/rep_set.txt)

mothur "#unique.seqs(fasta=$filtered_fasta, outputdir=Temp)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Blast_error.txt && exit
		else
		echo ""
		fi

cd Temp
mv *.names getoturep.names
mv getoturep.names ..
cd ..
rm -r Temp




#Making mothur list from cluster file
tr "\t" "," < $cluster_file | tr "\n" "\t" | sed -e 's/,\t/\t/g' > mothur.list
grep -c "" $cluster_file | sed 's/^/0.03\t/' > OTUnr.temp 
cat OTUnr.temp mothur.list > mothur_with_count.temp && rm OTUnr.temp
tr "\n" "\t" < mothur_with_count.temp > mothur_with_count.list && rm mothur_with_count.temp
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

mothur "#get.oturep(list=mothur_with_count.list, fasta=$filtered_fasta, name=getoturep.names, method=abundance)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Blast_error.txt && exit
		else
		echo ""
		fi

mv mothur_with_count.0.03.rep.fasta Rep_seqs_ABUNDANCE.fasta
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi


rm mothur_with_count.0.03.rep.names

#Delete mothur_logfiles
if ls mothur.*.logfile 1> /dev/null 2>&1; then
	rm *.logfile
fi


	#Set rep_set file variable
	rep_set=$"Rep_seqs_ABUNDANCE.fasta"
	echo "Representative sequences = "$rep_set
	echo ""



### Method = longest
else if grep -q 'Longest' ${USER_HOME}/.var_babitas/rep_set_method.txt; then
echo "# Choose representative sequences"
echo "# Method = longest"
echo "..."

cluster_file=$(cat ${USER_HOME}/.var_babitas/cluster_file.txt)
filtered_fasta=$(cat ${USER_HOME}/.var_babitas/rep_set.txt)

	#If using usearch clusters, then remove ";sample=*" from cluster seq names
	if grep -q ";sample=" $cluster_file; then
	gawk 'BEGIN {FS=OFS="\t"}{for (i=1; i<=NF; ++i) gsub(";sample=.*", "", $i); print}' < $cluster_file > c.temp
				if [ "$?" = "0" ]; then
				echo ""
				else
				touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
				fi

	mv c.temp $cluster_file
				if [ "$?" = "0" ]; then
				echo ""
				else
				touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
				fi
	fi

python ${USER_HOME}/.babitassh/Extract_longest_rep_seq.py $cluster_file $filtered_fasta

	#Set rep_set file variable
	rep_set=$"Rep_seqs_LONGEST.fasta"
	echo "Representative sequences = "$rep_set
	echo ""


### Method = select
else if grep -q 'Select' ${USER_HOME}/.var_babitas/rep_set_method.txt; then

	#Set rep_set file variable
	rep_set=$(cat ${USER_HOME}/.var_babitas/rep_set.txt)
	echo "Representative sequences = "$rep_set
	echo ""
fi
fi
fi

######################################################################################################
######################################################################################################
### RUN BLAST ###### RUN BLAST ###### RUN BLAST ###### RUN BLAST ###### RUN BLAST ###### RUN BLAST ###
######################################################################################################
######################################################################################################
if grep -q 'BLAST' ${USER_HOME}/.var_babitas/assignment.txt; then
echo "### BLAST ###"

#Set BLAST parameters
	task=$(cat ${USER_HOME}/.var_babitas/task.txt)
	strands=$(cat ${USER_HOME}/.var_babitas/strands.txt)
	threads=$(cat ${USER_HOME}/.var_babitas/threads.txt)
	e_value=$(cat ${USER_HOME}/.var_babitas/e_value.txt)
	word_size=$(cat ${USER_HOME}/.var_babitas/word_size.txt)
	reward=$(cat ${USER_HOME}/.var_babitas/reward.txt)
	penalty=$(cat ${USER_HOME}/.var_babitas/penalty.txt)
	gap_open=$(cat ${USER_HOME}/.var_babitas/gap_open.txt)
	gap_ex=$(cat ${USER_HOME}/.var_babitas/gap_ex.txt)
	dbs_mode=$(cat ${USER_HOME}/.var_babitas/dbs_mode.txt)
	num_of_dbs=$(cat ${USER_HOME}/.var_babitas/num_of_dbs.txt)
	

	echo ""
	echo "task = "$task
	echo "strands = "$strands
	echo "threads = "$threads
	echo "e value = "$e_value
	echo "word size = "$word_size
	echo "reward = "$reward
	echo "penalty = "$penalty
	echo "gap open = "$gap_open
	echo "Run BLAST databases = $dbs_mode (no. of databases = $num_of_dbs)"

	if grep -q -v 'megablast' ${USER_HOME}/.var_babitas/task.txt; then
	echo "gap extend = "$gap_ex
	fi

	echo ""

#Databases
	if [ -e ${USER_HOME}/.var_babitas/db1.txt ]; then
	db1=$(cat ${USER_HOME}/.var_babitas/db1.txt | sed -e 's/\.nhr//;s/\.nin//;s/\.nsq//')
	fi
	if [ -e ${USER_HOME}/.var_babitas/db2.txt ]; then
	db2=$(cat ${USER_HOME}/.var_babitas/db2.txt | sed -e 's/\.nhr//;s/\.nin//;s/\.nsq//')
	fi
	if [ -e ${USER_HOME}/.var_babitas/db3.txt ]; then
	db3=$(cat ${USER_HOME}/.var_babitas/db3.txt | sed -e 's/\.nhr//;s/\.nin//;s/\.nsq//')
	fi
	if [ -e ${USER_HOME}/.var_babitas/db4.txt ]; then
	db4=$(cat ${USER_HOME}/.var_babitas/db4.txt | sed -e 's/\.nhr//;s/\.nin//;s/\.nsq//')
	fi
	if [ -e ${USER_HOME}/.var_babitas/db5.txt ]; then
	db5=$(cat ${USER_HOME}/.var_babitas/db5.txt | sed -e 's/\.nhr//;s/\.nin//;s/\.nsq//')
	fi


#IF MEGABLAST, THEN NO GAP EXTEND OPTION - using default values.
if grep -q 'Together' ${USER_HOME}/.var_babitas/dbs_mode.txt; then
	if grep -q '1' ${USER_HOME}/.var_babitas/num_of_dbs.txt; then
		if grep -q 'megablast' ${USER_HOME}/.var_babitas/task.txt;then
			echo "# RUN BLAST with one database"
			echo "blastn -strand $strands -num_threads $threads -query $rep_set -db $db1 -out 10BestHits.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -outfmt=5"

			blastn -strand $strands -num_threads $threads -query $rep_set -db $db1 -out 10BestHits.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -outfmt=5
					if [ "$?" = "0" ]; then
					echo ""
					else
					touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
					fi
		else

	echo "# RUN BLAST with one database"
	echo "blastn -strand $strands -num_threads $threads -query $rep_set -db $db1 -out 10BestHits.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -gapextend=$gap_ex -outfmt=5"

	blastn -strand $strands -num_threads $threads -query $rep_set -db $db1 -out 10BestHits.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -gapextend=$gap_ex -outfmt=5
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi
		fi


		else if grep -q '2' ${USER_HOME}/.var_babitas/num_of_dbs.txt; then
			if grep -q 'megablast' ${USER_HOME}/.var_babitas/task.txt;then
				echo "# RUN BLAST with two databases"
				echo "blastn -strand $strands -num_threads $threads -query $rep_set -db '$db1 $db2' -out 10BestHits.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -outfmt=5"
				blastn -strand $strands -num_threads $threads -query $rep_set -db "$db1 $db2" -out 10BestHits.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -outfmt=5
						if [ "$?" = "0" ]; then
						echo ""
						else
						touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
						fi
	
			else

		echo "# RUN BLAST with two databases"
		echo "blastn -strand $strands -num_threads $threads -query $rep_set -db '$db1 $db2' -out 10BestHits.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -gapextend=$gap_ex -outfmt=5"

		blastn -strand $strands -num_threads $threads -query $rep_set -db "$db1 $db2" -out 10BestHits.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -gapextend=$gap_ex -outfmt=5
				if [ "$?" = "0" ]; then
				echo ""
				else
				touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
				fi
			fi


		else if grep -q '3' ${USER_HOME}/.var_babitas/num_of_dbs.txt; then
			if grep -q 'megablast' ${USER_HOME}/.var_babitas/task.txt;then
				echo "# RUN BLAST with three databases"
				echo "blastn -strand $strands -num_threads $threads -query $rep_set -db '$db1 $db2 $db3' -out 10BestHits.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -outfmt=5"
				blastn -strand $strands -num_threads $threads -query $rep_set -db "$db1 $db2 $db3" -out 10BestHits.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -outfmt=5
						if [ "$?" = "0" ]; then
						echo ""
						else
						touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
						fi
	
			else

		echo "# RUN BLAST with three databases"
		echo "blastn -strand $strands -num_threads $threads -query $rep_set -db '$db1 $db2 $db3' -out 10BestHits.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -gapextend=$gap_ex -outfmt=5"

			blastn -strand $strands -num_threads $threads -query $rep_set -db "$db1 $db2 $db3" -out 10BestHits.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -gapextend=$gap_ex -outfmt=5
					if [ "$?" = "0" ]; then
					echo ""
					else
					touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
					fi
			fi


		else if grep -q '4' ${USER_HOME}/.var_babitas/num_of_dbs.txt; then
			if grep -q 'megablast' ${USER_HOME}/.var_babitas/task.txt;then
				echo "# RUN BLAST with four databases"
				echo "blastn -strand $strands -num_threads $threads -query $rep_set -db '$db1 $db2 $db3 $db4' -out 10BestHits.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -outfmt=5"
				blastn -strand $strands -num_threads $threads -query $rep_set -db "$db1 $db2 $db3 $db4" -out 10BestHits.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -outfmt=5
						if [ "$?" = "0" ]; then
						echo ""
						else
						touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
						fi
	
			else

		echo "# RUN BLAST with four databases"
		echo "blastn -strand $strands -num_threads $threads -query $rep_set -db '$db1 $db2 $db3 $db4' -out 10BestHits.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -gapextend=$gap_ex -outfmt=5"

			blastn -strand $strands -num_threads $threads -query $rep_set -db "$db1 $db2 $db3 $db4" -out 10BestHits.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -gapextend=$gap_ex -outfmt=5
					if [ "$?" = "0" ]; then
					echo ""
					else
					touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
					fi
			fi



		else if grep -q '5' ${USER_HOME}/.var_babitas/num_of_dbs.txt; then
			if grep -q 'megablast' ${USER_HOME}/.var_babitas/task.txt;then
				echo "# RUN BLAST with five databases"
				echo "blastn -strand $strands -num_threads $threads -query $rep_set -db '$db1 $db2 $db3 $db4 $db5' -out 10BestHits.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -outfmt=5"
				blastn -strand $strands -num_threads $threads -query $rep_set -db "$db1 $db2 $db3 $db4 $db5" -out 10BestHits.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -outfmt=5
						if [ "$?" = "0" ]; then
						echo ""
						else
						touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
						fi
	
			else

		echo "# RUN BLAST with five databases"
		echo "blastn -strand $strands -num_threads $threads -query $rep_set -db '$db1 $db2 $db3 $db4 $db5' -out 10BestHits.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -gapextend=$gap_ex -outfmt=5"

			blastn -strand $strands -num_threads $threads -query $rep_set -db "$db1 $db2 $db3 $db4 $db5" -out 10BestHits.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -gapextend=$gap_ex -outfmt=5
					if [ "$?" = "0" ]; then
					echo ""
					else
					touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
					fi
			fi
	
		fi
		fi
		fi
		fi
	fi



################################################################
### BLAST with separate runs ###### BLAST with separate runs ###
################################################################
else if grep -q 'Separate' ${USER_HOME}/.var_babitas/dbs_mode.txt; then
	if grep -q '2' ${USER_HOME}/.var_babitas/num_of_dbs.txt; then
				if grep -q 'megablast' ${USER_HOME}/.var_babitas/task.txt;then
					
### db1 ###
echo "# BLAST against database 1"
					echo "blastn -strand $strands -num_threads $threads -query $rep_set -db $db1 -out 10BestHitsDB1.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -outfmt=5"
					blastn -strand $strands -num_threads $threads -query $rep_set -db $db1 -out 10BestHitsDB1.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -outfmt=5
							if [ "$?" = "0" ]; then
							echo ""
							else
							touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
							fi
### db2 ###
echo "# BLAST against database 2"
					echo "blastn -strand $strands -num_threads $threads -query $rep_set -db $db2 -out 10BestHitsDB2.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -outfmt=5"
					blastn -strand $strands -num_threads $threads -query $rep_set -db $db2 -out 10BestHitsDB2.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -outfmt=5
							if [ "$?" = "0" ]; then
							echo ""
							else
							touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
							fi



	
				else

			echo "# RUN BLAST with two databases"

### db1 ###
			echo "# BLAST against database 1"
			echo "blastn -strand $strands -num_threads $threads -query $rep_set -db $db1 -out 10BestHitsDB1.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -gapextend=$gap_ex -outfmt=5"

			blastn -strand $strands -num_threads $threads -query $rep_set -db $db1 -out 10BestHitsDB1.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -gapextend=$gap_ex -outfmt=5
					if [ "$?" = "0" ]; then
					echo ""
					else
					touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
					fi


### db2 ###
			echo "# BLAST against database 2"
			echo "blastn -strand $strands -num_threads $threads -query $rep_set -db $db2 -out 10BestHitsDB2.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -gapextend=$gap_ex -outfmt=5"

			blastn -strand $strands -num_threads $threads -query $rep_set -db $db2 -out 10BestHitsDB2.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -gapextend=$gap_ex -outfmt=5
					if [ "$?" = "0" ]; then
					echo ""
					else
					touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
					fi
				fi



			else if grep -q '3' ${USER_HOME}/.var_babitas/num_of_dbs.txt; then
				if grep -q 'megablast' ${USER_HOME}/.var_babitas/task.txt;then
					

### db1 ###
					echo "# BLAST against database 1"
					echo "blastn -strand $strands -num_threads $threads -query $rep_set -db $db1 -out 10BestHitsDB1.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -outfmt=5"
					blastn -strand $strands -num_threads $threads -query $rep_set -db $db1 -out 10BestHitsDB1.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -outfmt=5
							if [ "$?" = "0" ]; then
							echo ""
							else
							touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
							fi

### db2 ###
					echo "# BLAST against database 2"
					echo "blastn -strand $strands -num_threads $threads -query $rep_set -db $db2 -out 10BestHitsDB2.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -outfmt=5"
					blastn -strand $strands -num_threads $threads -query $rep_set -db $db2 -out 10BestHitsDB2.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -outfmt=5
							if [ "$?" = "0" ]; then
							echo ""
							else
							touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
							fi


### db3 ###
					echo "# BLAST against database 3"
					echo "blastn -strand $strands -num_threads $threads -query $rep_set -db $db3 -out 10BestHitsDB3.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -outfmt=5"
					blastn -strand $strands -num_threads $threads -query $rep_set -db $db3 -out 10BestHitsDB3.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -outfmt=5
							if [ "$?" = "0" ]; then
							echo ""
							else
							touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
							fi


	
				else

			echo "# RUN BLAST with three databases"
### db1 ###
			echo "# BLAST against database 1"
			echo "blastn -strand $strands -num_threads $threads -query $rep_set -db $db1 -out 10BestHitsDB1.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -gapextend=$gap_ex -outfmt=5"

				blastn -strand $strands -num_threads $threads -query $rep_set -db $db1 -out 10BestHitsDB1.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -gapextend=$gap_ex -outfmt=5
						if [ "$?" = "0" ]; then
						echo ""
						else
						touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
						fi

### db2 ###
			echo "# BLAST against database 2"
			echo "blastn -strand $strands -num_threads $threads -query $rep_set -db $db2 -out 10BestHitsDB2.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -gapextend=$gap_ex -outfmt=5"

				blastn -strand $strands -num_threads $threads -query $rep_set -db $db2 -out 10BestHitsDB2.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -gapextend=$gap_ex -outfmt=5
						if [ "$?" = "0" ]; then
						echo ""
						else
						touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
						fi

### db3 ###
			echo "# BLAST against database 3"
			echo "blastn -strand $strands -num_threads $threads -query $rep_set -db $db3 -out 10BestHitsDB3.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -gapextend=$gap_ex -outfmt=5"

				blastn -strand $strands -num_threads $threads -query $rep_set -db $db3 -out 10BestHitsDB3.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -gapextend=$gap_ex -outfmt=5
						if [ "$?" = "0" ]; then
						echo ""
						else
						touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
						fi

				fi


			else if grep -q '4' ${USER_HOME}/.var_babitas/num_of_dbs.txt; then
				if grep -q 'megablast' ${USER_HOME}/.var_babitas/task.txt;then
					
### db1 ###
					echo "# BLAST against database 1"
					echo "blastn -strand $strands -num_threads $threads -query $rep_set -db $db1 -out 10BestHitsDB1.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -outfmt=5"
					blastn -strand $strands -num_threads $threads -query $rep_set -db $db1 -out 10BestHitsDB1.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -outfmt=5
							if [ "$?" = "0" ]; then
							echo ""
							else
							touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
							fi

### db2 ###
					echo "# BLAST against database 2"
					echo "blastn -strand $strands -num_threads $threads -query $rep_set -db $db2 -out 10BestHitsDB2.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -outfmt=5"
					blastn -strand $strands -num_threads $threads -query $rep_set -db $db2 -out 10BestHitsDB2.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -outfmt=5
							if [ "$?" = "0" ]; then
							echo ""
							else
							touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
							fi

### db3 ###
					echo "# BLAST against database 3"
					echo "blastn -strand $strands -num_threads $threads -query $rep_set -db $db3 -out 10BestHitsDB3.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -outfmt=5"
					blastn -strand $strands -num_threads $threads -query $rep_set -db $db3 -out 10BestHitsDB3.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -outfmt=5
							if [ "$?" = "0" ]; then
							echo ""
							else
							touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
							fi

### db4 ###
					echo "# BLAST against database 4"
					echo "blastn -strand $strands -num_threads $threads -query $rep_set -db $db4 -out 10BestHitsDB4.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -outfmt=5"
					blastn -strand $strands -num_threads $threads -query $rep_set -db $db4 -out 10BestHitsDB4.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -outfmt=5
							if [ "$?" = "0" ]; then
							echo ""
							else
							touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
							fi
	
				else

			echo "# RUN BLAST with four databases"
### db1 ###
			echo "# BLAST against database 1"
			echo "blastn -strand $strands -num_threads $threads -query $rep_set -db $db1 -out 10BestHitsDB1.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -gapextend=$gap_ex -outfmt=5"

				blastn -strand $strands -num_threads $threads -query $rep_set -db $db1 -out 10BestHitsDB1.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -gapextend=$gap_ex -outfmt=5
						if [ "$?" = "0" ]; then
						echo ""
						else
						touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
						fi

### db2 ###
			echo "# BLAST against database 2"
			echo "blastn -strand $strands -num_threads $threads -query $rep_set -db $db2 -out 10BestHitsDB2.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -gapextend=$gap_ex -outfmt=5"

				blastn -strand $strands -num_threads $threads -query $rep_set -db $db2 -out 10BestHitsDB2.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -gapextend=$gap_ex -outfmt=5
						if [ "$?" = "0" ]; then
						echo ""
						else
						touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
						fi


### db3 ###
			echo "# BLAST against database 3"
			echo "blastn -strand $strands -num_threads $threads -query $rep_set -db $db3 -out 10BestHitsDB3.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -gapextend=$gap_ex -outfmt=5"

				blastn -strand $strands -num_threads $threads -query $rep_set -db $db3 -out 10BestHitsDB3.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -gapextend=$gap_ex -outfmt=5
						if [ "$?" = "0" ]; then
						echo ""
						else
						touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
						fi


### db4 ###
			echo "# BLAST against database 4"
			echo "blastn -strand $strands -num_threads $threads -query $rep_set -db $db4 -out 10BestHitsDB4.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -gapextend=$gap_ex -outfmt=5"

				blastn -strand $strands -num_threads $threads -query $rep_set -db $db4 -out 10BestHitsDB4.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -gapextend=$gap_ex -outfmt=5
						if [ "$?" = "0" ]; then
						echo ""
						else
						touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
						fi

				fi



			else if grep -q '5' ${USER_HOME}/.var_babitas/num_of_dbs.txt; then
				if grep -q 'megablast' ${USER_HOME}/.var_babitas/task.txt;then
					
### db1 ###
					echo "# BLAST against database 1"
					echo "blastn -strand $strands -num_threads $threads -query $rep_set -db $db1 -out 10BestHitsDB1.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -outfmt=5"
					blastn -strand $strands -num_threads $threads -query $rep_set -db $db1 -out 10BestHitsDB1.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -outfmt=5
							if [ "$?" = "0" ]; then
							echo ""
							else
							touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
							fi

### db2 ###
					echo "# BLAST against database 2"
					echo "blastn -strand $strands -num_threads $threads -query $rep_set -db $db2 -out 10BestHitsDB2.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -outfmt=5"
					blastn -strand $strands -num_threads $threads -query $rep_set -db $db2 -out 10BestHitsDB2.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -outfmt=5
							if [ "$?" = "0" ]; then
							echo ""
							else
							touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
							fi


### db3 ###
					echo "# BLAST against database 3"
					echo "blastn -strand $strands -num_threads $threads -query $rep_set -db $db3 -out 10BestHitsDB3.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -outfmt=5"
					blastn -strand $strands -num_threads $threads -query $rep_set -db $db3 -out 10BestHitsDB3.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -outfmt=5
							if [ "$?" = "0" ]; then
							echo ""
							else
							touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
							fi


### db4 ###
					echo "# BLAST against database 4"
					echo "blastn -strand $strands -num_threads $threads -query $rep_set -db $db4 -out 10BestHitsDB4.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -outfmt=5"
					blastn -strand $strands -num_threads $threads -query $rep_set -db $db4 -out 10BestHitsDB4.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -outfmt=5
							if [ "$?" = "0" ]; then
							echo ""
							else
							touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
							fi


### db5 ###
					echo "# BLAST against database 5"
					echo "blastn -strand $strands -num_threads $threads -query $rep_set -db $db5 -out 10BestHitsDB5.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -outfmt=5"
					blastn -strand $strands -num_threads $threads -query $rep_set -db $db5 -out 10BestHitsDB5.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -outfmt=5
							if [ "$?" = "0" ]; then
							echo ""
							else
							touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
							fi

	
				else

			echo "# RUN BLAST with five databases"
### db1 ###
			echo "# BLAST against database 1"
			echo "blastn -strand $strands -num_threads $threads -query $rep_set -db $db1 -out 10BestHitsDB1.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -gapextend=$gap_ex -outfmt=5"

				blastn -strand $strands -num_threads $threads -query $rep_set -db $db1 -out 10BestHitsDB1.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -gapextend=$gap_ex -outfmt=5
						if [ "$?" = "0" ]; then
						echo ""
						else
						touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
						fi

### db2 ###
			echo "# BLAST against database 2"
			echo "blastn -strand $strands -num_threads $threads -query $rep_set -db $db2 -out 10BestHitsDB2.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -gapextend=$gap_ex -outfmt=5"

				blastn -strand $strands -num_threads $threads -query $rep_set -db $db2 -out 10BestHitsDB2.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -gapextend=$gap_ex -outfmt=5
						if [ "$?" = "0" ]; then
						echo ""
						else
						touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
						fi


### db3 ###
			echo "# BLAST against database 3"
			echo "blastn -strand $strands -num_threads $threads -query $rep_set -db $db3 -out 10BestHitsDB3.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -gapextend=$gap_ex -outfmt=5"

				blastn -strand $strands -num_threads $threads -query $rep_set -db $db3 -out 10BestHitsDB3.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -gapextend=$gap_ex -outfmt=5
						if [ "$?" = "0" ]; then
						echo ""
						else
						touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
						fi


### db4 ###
			echo "# BLAST against database 4"
			echo "blastn -strand $strands -num_threads $threads -query $rep_set -db $db4 -out 10BestHitsDB4.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -gapextend=$gap_ex -outfmt=5"

				blastn -strand $strands -num_threads $threads -query $rep_set -db $db4 -out 10BestHitsDB4.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -gapextend=$gap_ex -outfmt=5
						if [ "$?" = "0" ]; then
						echo ""
						else
						touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
						fi


### db5 ###
			echo "# BLAST against database 5"
			echo "blastn -strand $strands -num_threads $threads -query $rep_set -db $db5 -out 10BestHitsDB5.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -gapextend=$gap_ex -outfmt=5"

				blastn -strand $strands -num_threads $threads -query $rep_set -db $db5 -out 10BestHitsDB5.xml -task $task -max_target_seqs 10 -evalue=$e_value -word_size=$word_size -reward=$reward -penalty=$penalty -gapopen=$gap_open -gapextend=$gap_ex -outfmt=5
						if [ "$?" = "0" ]; then
						echo ""
						else
						touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
						fi


				fi
	
			fi
			fi
			fi
		fi
fi
fi



##################################################################################
### Parse BLAST results from xml file ###### Parse BLAST results from xml file ###
##################################################################################
echo ""
echo "# Parsing BLAST results"
echo "..."

if grep -q 'Together' ${USER_HOME}/.var_babitas/dbs_mode.txt; then
	python ${USER_HOME}/.babitassh/Blast_parse.py 10BestHits.xml > parsed_seqs.list
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	#Extract first best hit from 10 best hits file
	gawk 'BEGIN{FS=OFS="\t"}{print $4}' < 10hits.txt | sed -e 's/^$/NO_BLAST_HIT/g' > BLAST_1st_best_hit.temp
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	grep ">" < $rep_set | sed -e 's/\r//g;s/>//g' > rep_set.list
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' rep_set.list BLAST_1st_best_hit.temp | sed '1 i\#RepSeqID; ###BLAST values = score|e value|query start|query end|align length|identities|gaps|id percentage'> BLAST_1st_best_hit.txt
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'BEGIN{FS=OFS="\t"}{print $3$4,$6$7,$9$10,$12$13,$15$16,$18$19,$21$22,$24$25,$27$28,$30$31}' < 10hits.txt | sed -e 's/^\t\t\t\t\t\t\t\t\t/NO_BLAST_HITS/g' > BLAST_10_best_hits.temp
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' rep_set.list BLAST_10_best_hits.temp | sed '1 i\#RepSeqID; ###BLAST values = score|e value|query start|query end|align length|identities|gaps|id percentage'> BLAST_10_best_hits.txt
			if [ "$?" = "0" ]; then
			touch ${USER_HOME}/.var_babitas/Blast_finished.txt
			echo ""
			echo "##########################"
			echo "DONE"
			echo "############################"
			echo "BLAST finished"
			echo "##############################"
			echo "output = BLAST_1st_best_hit.txt"
			echo "         BLAST_10_best_hits.txt"
			echo "################################"
			echo "You may close this window now!"
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi



################################
### SEPARATE db_mode parsing ###
################################
else if grep -q 'Separate' ${USER_HOME}/.var_babitas/dbs_mode.txt; then
	if grep -q '2' ${USER_HOME}/.var_babitas/num_of_dbs.txt; then

	### db1 ###

	python ${USER_HOME}/.babitassh/Blast_parse.py 10BestHitsDB1.xml > parsed_seqs.list
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	#Extract first best hit from 10 best hits file
	gawk 'BEGIN{FS=OFS="\t"}{print $4}' < 10hits.txt | sed -e 's/^$/NO_BLAST_HIT/g' > BLAST_1st_best_hit.temp
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	grep ">" < $rep_set | sed -e 's/\r//g;s/>//g' > rep_set.list
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' rep_set.list BLAST_1st_best_hit.temp | sed '1 i\#RepSeqID; ###BLAST values = score|e value|query start|query end|align length|identities|gaps|id percentage'> BLAST_1st_best_hitDB1.txt
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'BEGIN{FS=OFS="\t"}{print $3$4,$6$7,$9$10,$12$13,$15$16,$18$19,$21$22,$24$25,$27$28,$30$31}' < 10hits.txt | sed -e 's/^\t\t\t\t\t\t\t\t\t/NO_BLAST_HITS/g' > BLAST_10_best_hits.temp
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' rep_set.list BLAST_10_best_hits.temp | sed '1 i\#RepSeqID; ###BLAST values = score|e value|query start|query end|align length|identities|gaps|id percentage'> BLAST_10_best_hitsDB1.txt
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	
		### db2 ###

python ${USER_HOME}/.babitassh/Blast_parse.py 10BestHitsDB2.xml > parsed_seqs.list
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	#Extract first best hit from 10 best hits file
	gawk 'BEGIN{FS=OFS="\t"}{print $4}' < 10hits.txt | sed -e 's/^$/NO_BLAST_HIT/g' > BLAST_1st_best_hit.temp
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	grep ">" < $rep_set | sed -e 's/\r//g;s/>//g' > rep_set.list
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' rep_set.list BLAST_1st_best_hit.temp | sed '1 i\#RepSeqID; ###BLAST values = score|e value|query start|query end|align length|identities|gaps|id percentage'> BLAST_1st_best_hitDB2.txt
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'BEGIN{FS=OFS="\t"}{print $3$4,$6$7,$9$10,$12$13,$15$16,$18$19,$21$22,$24$25,$27$28,$30$31}' < 10hits.txt | sed -e 's/^\t\t\t\t\t\t\t\t\t/NO_BLAST_HITS/g' > BLAST_10_best_hits.temp
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' rep_set.list BLAST_10_best_hits.temp | sed '1 i\#RepSeqID; ###BLAST values = score|e value|query start|query end|align length|identities|gaps|id percentage'> BLAST_10_best_hitsDB2.txt
			if [ "$?" = "0" ]; then
			touch ${USER_HOME}/.var_babitas/Blast_finished.txt
			echo ""
			echo "##########################"
			echo "DONE"
			echo "############################"
			echo "BLAST finished"
			echo "##############################"
			echo "output = BLAST_1st_best_hitDB1.txt"
			echo "         BLAST_10_best_hitsDB1.txt"
			echo "         BLAST_1st_best_hitDB2.txt"
			echo "         BLAST_10_best_hitsDB2.txt"
			echo "################################"
			echo "You may close this window now!"
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi



	else if grep -q '3' ${USER_HOME}/.var_babitas/num_of_dbs.txt; then
	
	### db1 ###

	python ${USER_HOME}/.babitassh/Blast_parse.py 10BestHitsDB1.xml > parsed_seqs.list
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	#Extract first best hit from 10 best hits file
	gawk 'BEGIN{FS=OFS="\t"}{print $4}' < 10hits.txt | sed -e 's/^$/NO_BLAST_HIT/g' > BLAST_1st_best_hit.temp
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	grep ">" < $rep_set | sed -e 's/\r//g;s/>//g' > rep_set.list
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' rep_set.list BLAST_1st_best_hit.temp | sed '1 i\#RepSeqID; ###BLAST values = score|e value|query start|query end|align length|identities|gaps|id percentage'> BLAST_1st_best_hitDB1.txt
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'BEGIN{FS=OFS="\t"}{print $3$4,$6$7,$9$10,$12$13,$15$16,$18$19,$21$22,$24$25,$27$28,$30$31}' < 10hits.txt | sed -e 's/^\t\t\t\t\t\t\t\t\t/NO_BLAST_HITS/g' > BLAST_10_best_hits.temp
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' rep_set.list BLAST_10_best_hits.temp | sed '1 i\#RepSeqID; ###BLAST values = score|e value|query start|query end|align length|identities|gaps|id percentage'> BLAST_10_best_hitsDB1.txt
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	
		### db2 ###

	python ${USER_HOME}/.babitassh/Blast_parse.py 10BestHitsDB2.xml > parsed_seqs.list
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	#Extract first best hit from 10 best hits file
	gawk 'BEGIN{FS=OFS="\t"}{print $4}' < 10hits.txt | sed -e 's/^$/NO_BLAST_HIT/g' > BLAST_1st_best_hit.temp
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	grep ">" < $rep_set | sed -e 's/\r//g;s/>//g' > rep_set.list
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' rep_set.list BLAST_1st_best_hit.temp | sed '1 i\#RepSeqID; ###BLAST values = score|e value|query start|query end|align length|identities|gaps|id percentage'> BLAST_1st_best_hitDB2.txt
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'BEGIN{FS=OFS="\t"}{print $3$4,$6$7,$9$10,$12$13,$15$16,$18$19,$21$22,$24$25,$27$28,$30$31}' < 10hits.txt | sed -e 's/^\t\t\t\t\t\t\t\t\t/NO_BLAST_HITS/g' > BLAST_10_best_hits.temp
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' rep_set.list BLAST_10_best_hits.temp | sed '1 i\#RepSeqID; ###BLAST values = score|e value|query start|query end|align length|identities|gaps|id percentage'> BLAST_10_best_hitsDB2.txt
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi



		### db3 ###
	python ${USER_HOME}/.babitassh/Blast_parse.py 10BestHitsDB3.xml > parsed_seqs.list
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	#Extract first best hit from 10 best hits file
	gawk 'BEGIN{FS=OFS="\t"}{print $4}' < 10hits.txt | sed -e 's/^$/NO_BLAST_HIT/g' > BLAST_1st_best_hit.temp
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	grep ">" < $rep_set | sed -e 's/\r//g;s/>//g' > rep_set.list
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' rep_set.list BLAST_1st_best_hit.temp | sed '1 i\#RepSeqID; ###BLAST values = score|e value|query start|query end|align length|identities|gaps|id percentage'> BLAST_1st_best_hitDB3.txt
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'BEGIN{FS=OFS="\t"}{print $3$4,$6$7,$9$10,$12$13,$15$16,$18$19,$21$22,$24$25,$27$28,$30$31}' < 10hits.txt | sed -e 's/^\t\t\t\t\t\t\t\t\t/NO_BLAST_HITS/g' > BLAST_10_best_hits.temp
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' rep_set.list BLAST_10_best_hits.temp | sed '1 i\#RepSeqID; ###BLAST values = score|e value|query start|query end|align length|identities|gaps|id percentage'> BLAST_10_best_hitsDB3.txt
			if [ "$?" = "0" ]; then
			touch ${USER_HOME}/.var_babitas/Blast_finished.txt
			echo ""
			echo "##########################"
			echo "DONE"
			echo "############################"
			echo "BLAST finished"
			echo "##############################"
			echo "output = BLAST_1st_best_hitDB1.txt"
			echo "         BLAST_10_best_hitsDB1.txt"
			echo "         BLAST_1st_best_hitDB2.txt"
			echo "         BLAST_10_best_hitsDB2.txt"
			echo "         BLAST_1st_best_hitDB3.txt"
			echo "         BLAST_10_best_hitsDB3.txt"
			echo "################################"
			echo "You may close this window now!"
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi







	else if grep -q '4' ${USER_HOME}/.var_babitas/num_of_dbs.txt; then
	
	### db1 ###

	python ${USER_HOME}/.babitassh/Blast_parse.py 10BestHitsDB1.xml > parsed_seqs.list
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	#Extract first best hit from 10 best hits file
	gawk 'BEGIN{FS=OFS="\t"}{print $4}' < 10hits.txt | sed -e 's/^$/NO_BLAST_HIT/g' > BLAST_1st_best_hit.temp
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	grep ">" < $rep_set | sed -e 's/\r//g;s/>//g' > rep_set.list
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' rep_set.list BLAST_1st_best_hit.temp | sed '1 i\#RepSeqID; ###BLAST values = score|e value|query start|query end|align length|identities|gaps|id percentage'> BLAST_1st_best_hitDB1.txt
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'BEGIN{FS=OFS="\t"}{print $3$4,$6$7,$9$10,$12$13,$15$16,$18$19,$21$22,$24$25,$27$28,$30$31}' < 10hits.txt | sed -e 's/^\t\t\t\t\t\t\t\t\t/NO_BLAST_HITS/g' > BLAST_10_best_hits.temp
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' rep_set.list BLAST_10_best_hits.temp | sed '1 i\#RepSeqID; ###BLAST values = score|e value|query start|query end|align length|identities|gaps|id percentage'> BLAST_10_best_hitsDB1.txt
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	
		### db2 ###

	python ${USER_HOME}/.babitassh/Blast_parse.py 10BestHitsDB2.xml > parsed_seqs.list
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	#Extract first best hit from 10 best hits file
	gawk 'BEGIN{FS=OFS="\t"}{print $4}' < 10hits.txt | sed -e 's/^$/NO_BLAST_HIT/g' > BLAST_1st_best_hit.temp
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	grep ">" < $rep_set | sed -e 's/\r//g;s/>//g' > rep_set.list
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' rep_set.list BLAST_1st_best_hit.temp | sed '1 i\#RepSeqID; ###BLAST values = score|e value|query start|query end|align length|identities|gaps|id percentage'> BLAST_1st_best_hitDB2.txt
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'BEGIN{FS=OFS="\t"}{print $3$4,$6$7,$9$10,$12$13,$15$16,$18$19,$21$22,$24$25,$27$28,$30$31}' < 10hits.txt | sed -e 's/^\t\t\t\t\t\t\t\t\t/NO_BLAST_HITS/g' > BLAST_10_best_hits.temp
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' rep_set.list BLAST_10_best_hits.temp | sed '1 i\#RepSeqID; ###BLAST values = score|e value|query start|query end|align length|identities|gaps|id percentage'> BLAST_10_best_hitsDB2.txt
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi



		### db3 ###
	python ${USER_HOME}/.babitassh/Blast_parse.py 10BestHitsDB3.xml > parsed_seqs.list
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	#Extract first best hit from 10 best hits file
	gawk 'BEGIN{FS=OFS="\t"}{print $4}' < 10hits.txt | sed -e 's/^$/NO_BLAST_HIT/g' > BLAST_1st_best_hit.temp
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	grep ">" < $rep_set | sed -e 's/\r//g;s/>//g' > rep_set.list
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' rep_set.list BLAST_1st_best_hit.temp | sed '1 i\#RepSeqID; ###BLAST values = score|e value|query start|query end|align length|identities|gaps|id percentage'> BLAST_1st_best_hitDB3.txt
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'BEGIN{FS=OFS="\t"}{print $3$4,$6$7,$9$10,$12$13,$15$16,$18$19,$21$22,$24$25,$27$28,$30$31}' < 10hits.txt | sed -e 's/^\t\t\t\t\t\t\t\t\t/NO_BLAST_HITS/g' > BLAST_10_best_hits.temp
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' rep_set.list BLAST_10_best_hits.temp | sed '1 i\#RepSeqID; ###BLAST values = score|e value|query start|query end|align length|identities|gaps|id percentage'> BLAST_10_best_hitsDB3.txt
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi



		### db4 ###
	python ${USER_HOME}/.babitassh/Blast_parse.py 10BestHitsDB4.xml > parsed_seqs.list
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	#Extract first best hit from 10 best hits file
	gawk 'BEGIN{FS=OFS="\t"}{print $4}' < 10hits.txt | sed -e 's/^$/NO_BLAST_HIT/g' > BLAST_1st_best_hit.temp
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	grep ">" < $rep_set | sed -e 's/\r//g;s/>//g' > rep_set.list
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' rep_set.list BLAST_1st_best_hit.temp | sed '1 i\#RepSeqID; ###BLAST values = score|e value|query start|query end|align length|identities|gaps|id percentage'> BLAST_1st_best_hitDB4.txt
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'BEGIN{FS=OFS="\t"}{print $3$4,$6$7,$9$10,$12$13,$15$16,$18$19,$21$22,$24$25,$27$28,$30$31}' < 10hits.txt | sed -e 's/^\t\t\t\t\t\t\t\t\t/NO_BLAST_HITS/g' > BLAST_10_best_hits.temp
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' rep_set.list BLAST_10_best_hits.temp | sed '1 i\#RepSeqID; ###BLAST values = score|e value|query start|query end|align length|identities|gaps|id percentage'> BLAST_10_best_hitsDB4.txt
			if [ "$?" = "0" ]; then
			touch ${USER_HOME}/.var_babitas/Blast_finished.txt
			echo ""
			echo "##########################"
			echo "DONE"
			echo "############################"
			echo "BLAST finished"
			echo "##############################"
			echo "output = BLAST_1st_best_hitDB1.txt"
			echo "         BLAST_10_best_hitsDB1.txt"
			echo "         BLAST_1st_best_hitDB2.txt"
			echo "         BLAST_10_best_hitsDB2.txt"
			echo "         BLAST_1st_best_hitDB3.txt"
			echo "         BLAST_10_best_hitsDB3.txt"
			echo "         BLAST_1st_best_hitDB4.txt"
			echo "         BLAST_10_best_hitsDB4.txt"
			echo "################################"
			echo "You may close this window now!"
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi







	else if grep -q '5' ${USER_HOME}/.var_babitas/num_of_dbs.txt; then
	
	### db1 ###

	python ${USER_HOME}/.babitassh/Blast_parse.py 10BestHitsDB1.xml > parsed_seqs.list
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	#Extract first best hit from 10 best hits file
	gawk 'BEGIN{FS=OFS="\t"}{print $4}' < 10hits.txt | sed -e 's/^$/NO_BLAST_HIT/g' > BLAST_1st_best_hit.temp
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	grep ">" < $rep_set | sed -e 's/\r//g;s/>//g' > rep_set.list
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' rep_set.list BLAST_1st_best_hit.temp | sed '1 i\#RepSeqID; ###BLAST values = score|e value|query start|query end|align length|identities|gaps|id percentage'> BLAST_1st_best_hitDB1.txt
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'BEGIN{FS=OFS="\t"}{print $3$4,$6$7,$9$10,$12$13,$15$16,$18$19,$21$22,$24$25,$27$28,$30$31}' < 10hits.txt | sed -e 's/^\t\t\t\t\t\t\t\t\t/NO_BLAST_HITS/g' > BLAST_10_best_hits.temp
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' rep_set.list BLAST_10_best_hits.temp | sed '1 i\#RepSeqID; ###BLAST values = score|e value|query start|query end|align length|identities|gaps|id percentage'> BLAST_10_best_hitsDB1.txt
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	
		### db2 ###

	python ${USER_HOME}/.babitassh/Blast_parse.py 10BestHitsDB2.xml > parsed_seqs.list
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	#Extract first best hit from 10 best hits file
	gawk 'BEGIN{FS=OFS="\t"}{print $4}' < 10hits.txt | sed -e 's/^$/NO_BLAST_HIT/g' > BLAST_1st_best_hit.temp
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	grep ">" < $rep_set | sed -e 's/\r//g;s/>//g' > rep_set.list
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' rep_set.list BLAST_1st_best_hit.temp | sed '1 i\#RepSeqID; ###BLAST values = score|e value|query start|query end|align length|identities|gaps|id percentage'> BLAST_1st_best_hitDB2.txt
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'BEGIN{FS=OFS="\t"}{print $3$4,$6$7,$9$10,$12$13,$15$16,$18$19,$21$22,$24$25,$27$28,$30$31}' < 10hits.txt | sed -e 's/^\t\t\t\t\t\t\t\t\t/NO_BLAST_HITS/g' > BLAST_10_best_hits.temp
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' rep_set.list BLAST_10_best_hits.temp | sed '1 i\#RepSeqID; ###BLAST values = score|e value|query start|query end|align length|identities|gaps|id percentage'> BLAST_10_best_hitsDB2.txt
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi



		### db3 ###
	python ${USER_HOME}/.babitassh/Blast_parse.py 10BestHitsDB3.xml > parsed_seqs.list
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	#Extract first best hit from 10 best hits file
	gawk 'BEGIN{FS=OFS="\t"}{print $4}' < 10hits.txt | sed -e 's/^$/NO_BLAST_HIT/g' > BLAST_1st_best_hit.temp
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	grep ">" < $rep_set | sed -e 's/\r//g;s/>//g' > rep_set.list
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' rep_set.list BLAST_1st_best_hit.temp | sed '1 i\#RepSeqID; ###BLAST values = score|e value|query start|query end|align length|identities|gaps|id percentage'> BLAST_1st_best_hitDB3.txt
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'BEGIN{FS=OFS="\t"}{print $3$4,$6$7,$9$10,$12$13,$15$16,$18$19,$21$22,$24$25,$27$28,$30$31}' < 10hits.txt | sed -e 's/^\t\t\t\t\t\t\t\t\t/NO_BLAST_HITS/g' > BLAST_10_best_hits.temp
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' rep_set.list BLAST_10_best_hits.temp | sed '1 i\#RepSeqID; ###BLAST values = score|e value|query start|query end|align length|identities|gaps|id percentage'> BLAST_10_best_hitsDB3.txt
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi



		### db4 ###
	python ${USER_HOME}/.babitassh/Blast_parse.py 10BestHitsDB4.xml > parsed_seqs.list
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	#Extract first best hit from 10 best hits file
	gawk 'BEGIN{FS=OFS="\t"}{print $4}' < 10hits.txt | sed -e 's/^$/NO_BLAST_HIT/g' > BLAST_1st_best_hit.temp
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	grep ">" < $rep_set | sed -e 's/\r//g;s/>//g' > rep_set.list
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' rep_set.list BLAST_1st_best_hit.temp | sed '1 i\#RepSeqID; ###BLAST values = score|e value|query start|query end|align length|identities|gaps|id percentage'> BLAST_1st_best_hitDB4.txt
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'BEGIN{FS=OFS="\t"}{print $3$4,$6$7,$9$10,$12$13,$15$16,$18$19,$21$22,$24$25,$27$28,$30$31}' < 10hits.txt | sed -e 's/^\t\t\t\t\t\t\t\t\t/NO_BLAST_HITS/g' > BLAST_10_best_hits.temp
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' rep_set.list BLAST_10_best_hits.temp | sed '1 i\#RepSeqID; ###BLAST values = score|e value|query start|query end|align length|identities|gaps|id percentage'> BLAST_10_best_hitsDB4.txt
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi



		### db5 ###
	python ${USER_HOME}/.babitassh/Blast_parse.py 10BestHitsDB5.xml > parsed_seqs.list
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	#Extract first best hit from 10 best hits file
	gawk 'BEGIN{FS=OFS="\t"}{print $4}' < 10hits.txt | sed -e 's/^$/NO_BLAST_HIT/g' > BLAST_1st_best_hit.temp
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	grep ">" < $rep_set | sed -e 's/\r//g;s/>//g' > rep_set.list
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' rep_set.list BLAST_1st_best_hit.temp | sed '1 i\#RepSeqID; ###BLAST values = score|e value|query start|query end|align length|identities|gaps|id percentage'> BLAST_1st_best_hitDB5.txt
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'BEGIN{FS=OFS="\t"}{print $3$4,$6$7,$9$10,$12$13,$15$16,$18$19,$21$22,$24$25,$27$28,$30$31}' < 10hits.txt | sed -e 's/^\t\t\t\t\t\t\t\t\t/NO_BLAST_HITS/g' > BLAST_10_best_hits.temp
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	gawk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' rep_set.list BLAST_10_best_hits.temp | sed '1 i\#RepSeqID; ###BLAST values = score|e value|query start|query end|align length|identities|gaps|id percentage'> BLAST_10_best_hitsDB5.txt
			if [ "$?" = "0" ]; then
			touch ${USER_HOME}/.var_babitas/Blast_finished.txt
			echo ""
			echo "##########################"
			echo "DONE"
			echo "############################"
			echo "BLAST finished"
			echo "##############################"
			echo "output = BLAST_1st_best_hitDB1.txt"
			echo "         BLAST_10_best_hitsDB1.txt"
			echo "         BLAST_1st_best_hitDB2.txt"
			echo "         BLAST_10_best_hitsDB2.txt"
			echo "         BLAST_1st_best_hitDB3.txt"
			echo "         BLAST_10_best_hitsDB3.txt"
			echo "         BLAST_1st_best_hitDB4.txt"
			echo "         BLAST_10_best_hitsDB4.txt"
			echo "         BLAST_1st_best_hitDB5.txt"
			echo "         BLAST_10_best_hitsDB5.txt"
			echo "################################"
			echo "You may close this window now!"
			else
			touch ${USER_HOME}/.var_babitas/Blast_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi


	fi
	fi
	fi
	fi


fi
fi


#Delete unnecessary files
if [ -e 10hits.txt ];then
rm 10hits.txt
fi
if [ -e parsed_seqs.list ];then
rm parsed_seqs.list
fi
if [ -e BLAST_1st_best_hit.temp ];then
rm BLAST_1st_best_hit.temp
fi
if [ -e rep_set.list ];then
rm rep_set.list
fi
if [ -e BLAST_10_best_hits.temp ];then
rm BLAST_10_best_hits.temp
fi
if [ -e getoturep.names ];then
rm getoturep.names
fi
if [ -e 10BestHitsDB5.txt ];then
rm 10BestHitsDB5.txt
fi
if [ -e 10BestHitsDB4.txt ];then
rm 10BestHitsDB4.txt
fi
if [ -e 10BestHitsDB3.txt ];then
rm 10BestHitsDB3.txt
fi
if [ -e 10BestHitsDB2.txt ];then
rm 10BestHitsDB2.txt
fi
if [ -e 10BestHitsDB1.txt ];then
rm 10BestHitsDB1.txt
fi


fi


######################################################################################################
######################################################################################################
### RUN Bayesian ###### RUN Bayesian ###### RUN Bayesian ###### RUN Bayesian ###### RUN Bayesian #####
######################################################################################################
######################################################################################################
if grep -q 'Bayesian' ${USER_HOME}/.var_babitas/assignment.txt; then
echo "### Naïve Bayesian classifier ###"

#Set parameters
	ksize=$(cat ${USER_HOME}/.var_babitas/ksize.txt)
	iters=$(cat ${USER_HOME}/.var_babitas/iters.txt)
	cutoff=$(cat ${USER_HOME}/.var_babitas/cutoff.txt)
	threads2=$(cat ${USER_HOME}/.var_babitas/threads2.txt)
	probs=$(cat ${USER_HOME}/.var_babitas/probs.txt)
	

	template=$(cat ${USER_HOME}/.var_babitas/template.txt)
	taxonomy=$(cat ${USER_HOME}/.var_babitas/taxonomy.txt)



mothur "#classify.seqs(fasta=$rep_set, template=$template, taxonomy=$taxonomy, method=wang, ksize=$ksize, iters=$iters, cutoff=$cutoff, probs=$probs, processors=$threads2)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Blast_error.txt && exit
		else
		touch ${USER_HOME}/.var_babitas/Blast_finished.txt
			echo ""
			echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Naïve Bayesian classifier finished"
			echo "##############################"
			echo "output = *.taxonomy file"
			echo "################################"
			echo "You may close this window now!"
		fi




fi




