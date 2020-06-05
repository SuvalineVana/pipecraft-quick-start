#!/bin/bash 


#Set working directory
USER_HOME=$(eval echo ~${SUDO_USER})

if [ -e ${USER_HOME}/.var_babitas/fasta10.txt ]; then

	WorkingDirectory=$(awk 'BEGIN{FS=OFS="/"} NF{NF--};1' < ${USER_HOME}/.var_babitas/fasta10.txt)

	input=$(cat ${USER_HOME}/.var_babitas/fasta10.txt)


	cd $WorkingDirectory
			if [ "$?" = "0" ]; then
 			echo ""
			else
			touch ${USER_HOME}/.var_babitas/tools_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi

	else 
	echo "Error: no input" && exit 1

fi





### Representative sequences

### Method = abundance
if grep -q 'Abundance' ${USER_HOME}/.var_babitas/method.txt; then

echo "### Choosing representative sequences ###"
echo " # Method = abundance"
echo " # using mothur - Schloss, P.D., et al., 2009. Introducing mothur: Open-Source, Platform-Independent, Community-Supported Software for Describing and Comparing Microbial Communities. Applied and Environmental Microbiology 75, 7537-7541."
echo "Distributed under the GNU General Public License version 2 by the Free Software Foundation"
echo "www.mothur.org"
echo "____________________________________________________"
echo ""
# select cluster file and filtered fasta file (either the file that was submitted to gene extraction or the file that was outputted by some gene extractor. The difference will be first file containing the conservative genes, the other one includes just a specific region).

cluster=$(cat ${USER_HOME}/.var_babitas/cluster.txt)
fasta=$(cat ${USER_HOME}/.var_babitas/fasta10.txt)

mothur "#unique.seqs(fasta=$fasta, outputdir=Temp)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/tools_error.txt && exit
		else
		echo ""
		fi

cd Temp
mv *.names getoturep.names
mv getoturep.names ..
cd ..
rm -r Temp

#Making mothur list from cluster file
tr "\t" "," < $cluster | tr "\n" "\t" | sed -e 's/,\t/\t/g' > mothur.list
grep -c "" $cluster | sed 's/^/0.03\t/' > OTUnr.temp 
cat OTUnr.temp mothur.list > mothur_with_count.temp && rm OTUnr.temp
tr "\n" "\t" < mothur_with_count.temp > mothur_with_count.list && rm mothur_with_count.temp
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/tools_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

mothur "#get.oturep(list=mothur_with_count.list, fasta=$fasta, name=getoturep.names, method=abundance)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/tools_error.txt && exit
		else
		echo ""
		fi

mv mothur_with_count.0.03.rep.fasta Rep_seqs_ABUNDANCE.fasta
			if [ "$?" = "0" ]; then
			#Set rep_set file variable
			rep_set=$"Rep_seqs_ABUNDANCE.fasta"
			echo "Representative sequences = "$rep_set
			rm mothur_with_count.0.03.rep.names
			rm mothur.list
			rm mothur_with_count.list

			echo ""
			echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Representative sequences = "$rep_set
			echo "################################"
			echo "You may close this window now!"

				#Delete mothur_logfiles
				if ls mothur.*.logfile 1> /dev/null 2>&1; then
					rm *.logfile
				fi
			touch ${USER_HOME}/.var_babitas/tools_finished.txt
				else
			touch ${USER_HOME}/.var_babitas/tools_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi



########################
### Method = longest ###
########################
else if grep -q 'Longest' ${USER_HOME}/.var_babitas/method.txt; then
echo "### Choosing representative sequences ###"
echo " # Method = longest"
echo " # using custom python script"
echo "____________________________________________________"
echo ""

cluster=$(cat ${USER_HOME}/.var_babitas/cluster.txt)
fasta=$(cat ${USER_HOME}/.var_babitas/fasta10.txt)

python ${USER_HOME}/.babitassh/Extract_longest_rep_seq.py $cluster $fasta
			if [ "$?" = "0" ]; then
			#Set rep_set file variable
			rep_set=$"Rep_seqs_LONGEST.fasta"
			
 			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Representative sequences = "$rep_set
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/tools_finished.txt
				else
			touch ${USER_HOME}/.var_babitas/tools_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi



fi
fi



#Delete mothur_logfiles
if ls mothur.*.logfile 1> /dev/null 2>&1; then
	rm *.logfile
fi


