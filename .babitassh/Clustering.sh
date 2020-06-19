#!/bin/bash 

echo "### CLUSTERING ###" 
echo ""
echo "When using the incorporated tools, please cite as follows:"
echo ""
echo "mothur (v1.36.1) - Schloss, P.D., et al., 2009. Introducing mothur: Open-Source, Platform-Independent, Community-Supported Software for Describing and Comparing Microbial Communities. Applied and Environmental Microbiology 75, 7537-7541."
echo "Distributed under the GNU General Public License version 2 by the Free Software Foundation"
echo "www.mothur.org"
echo ""
echo "vsearch (v1.11.1) - github.com/torognes/vsearch"
echo "Copyright (C) 2014-2015, Torbjorn Rognes, Frederic Mahe and Tomas Flouri."
echo "Distributed under the GNU General Public License version 3 by the Free Software Foundation"
echo ""
echo "CD-HIT (v4.6) - Fu, L., et al., 2012. CD-HIT: accelerated for clustering the next-generation sequencing data. Bioinformatics 28, 3150-3152."
echo "Distributed under the GNU General Public License by the Free Software Foundation"
echo "weizhongli-lab.org/cd-hit/"
echo ""
echo "swarm (v2.1.8) - Mahe, F., et al., 2015. Swarm v2: highly-scalable and high-resolution amplicon clustering. PeerJ 3:e1420 doi.org/10.7717/peerj.1420"
echo "Copyright (C) 2012-2016 Torbjorn Rognes and Frederic Mahe"
echo "Distributed under the GNU AFFERO GENERAL PUBLIC LICENSE version 3 by the Free Software Foundation"
echo "github.com/torognes/swarm"
echo "________________________________________________"

USER_HOME=$(eval echo ~${SUDO_USER})


###Set INPUT file###

#SINGLE FILE
if [ -e ${USER_HOME}/.var_babitas/input_for_clustering.txt ]; then

WorkingDirectory=$(awk 'BEGIN{FS=OFS="/"} NF{NF--};1' < ${USER_HOME}/.var_babitas/input_for_clustering.txt)
		if [ "$?" = "0" ]; then
		echo ""
		echo "Working directory = "$WorkingDirectory
		else
		touch ${USER_HOME}/.var_babitas/Clustering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi


echo $WorkingDirectory > ${USER_HOME}/.var_babitas/WD.txt
cd $WorkingDirectory
		if [ "$?" = "0" ]; then
 		input_for_clustering=$(cat ${USER_HOME}/.var_babitas/input_for_clustering.txt)
		echo "Input = $input_for_clustering"
#Check for unallowed characters in input file
			if grep -q "\." $input_for_clustering || grep -q "\," $input_for_clustering || grep -q "\;" $input_for_clustering || grep -q "\:" $input_for_clustering || grep -q "\ " $input_for_clustering; then
				echo "   Input fasta file contains unallowed characters (.,:; or space), replacing with _ "
				echo ""
				tr "." "_" < $input_for_clustering > $input_for_clustering.temp
				tr "," "_" < $input_for_clustering.temp > $input_for_clustering
				tr ":" "_" < $input_for_clustering > $input_for_clustering.temp
				tr " " "_" < $input_for_clustering.temp > $input_for_clustering
				tr ";" "_" < $input_for_clustering > $input_for_clustering.temp
				mv $input_for_clustering.temp $input_for_clustering
			fi
#Delete \r from fasta file (uc_converter does not like that)
			if grep -q $'\r' $input_for_clustering; then
				sed -i 's/\r//g' $input_for_clustering
			fi

		else
		touch ${USER_HOME}/.var_babitas/Clustering_error.txt && echo "ERROR occured" 1>&2 && echo "Can't enter to the directory" && exit 1

		fi


#Groups file variable
	if [ -e ${USER_HOME}/.var_babitas/groups_file.txt ]; then
		groups=$(cat ${USER_HOME}/.var_babitas/groups_file.txt)
		echo "Groups file = $groups"

#Check for unallowed characters in input groups file
		if grep -q "\." $groups || grep -q "\," $groups || grep -q "\:" $groups || grep -q "\;" $groups || grep -q "\ " $groups; then
			echo "   Input groups file contains unallowed characters (.,:; or space), replacing with _ "
			echo ""
			tr "." "_" < $groups > $groups.temp
			tr "," "_" < $groups.temp > $groups
			tr ":" "_" < $groups > $groups.temp
			tr " " "_" < $groups.temp > $groups
			tr ";" "_" < $groups > $groups.temp
			mv $groups.temp $groups
		fi
	fi




#MULTIPLE FILES
#else if MULTIPLE inputs, then MERGE FILES
	else if [ -e ${USER_HOME}/.var_babitas/fastaFile.txt ]; then

	
	#remove <p></p> characters from file
	sed -i 's/<p><\/p>//g' ${USER_HOME}/.var_babitas/fastaFile.txt
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Clustering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	WorkingDirectory=$(cat ${USER_HOME}/.var_babitas/fastaFile.txt | sed '/^\s*$/d' | head -n1 | awk 'BEGIN {FS="/"} {$NF=""; print $0}' | tr " " "/")
			if [ "$?" = "0" ]; then
			echo "Working directory = "$WorkingDirectory
			else
			touch ${USER_HOME}/.var_babitas/Clustering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi


	echo $WorkingDirectory > ${USER_HOME}/.var_babitas/WD.txt
	cd $WorkingDirectory

	#Merge fasta files
	echo ""
	echo "# Merging fasta files (according to input order, using cat)"
	echo "(output = MERGEDfasta.fasta; even if input was only a single file)"
	echo ""

	merge_fasta=$(cat ${USER_HOME}/.var_babitas/fastaFile.txt | sed '/^\s*$/d' | tr "\n" " " | tr "\r" " ")

	#Enter NEW LINE to the end of each file (so that the cat would work correctly)
	sed -i -e '$a\' $merge_fasta
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Clustering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi
	
	#merge fasta
	echo "cat "$merge_fasta
	cat $merge_fasta > MERGEDfasta.fasta
			if [ "$?" = "0" ]; then
	 		echo ""
			input_for_clustering=$"MERGEDfasta.fasta" 
			echo $WorkingDirectory"MERGEDfasta.fasta" > ${USER_HOME}/.var_babitas/input_for_clustering.txt


#Check for unallowed characters in input file
				if grep -q "\." $input_for_clustering || grep -q "\," $input_for_clustering || grep -q "\;" $input_for_clustering || grep -q "\:" $input_for_clustering || grep -q "\ " $input_for_clustering; then
					echo "   Input fasta file contains unallowed characters (.,:; or space), replacing with _ "
					echo ""
					tr "." "_" < $input_for_clustering > $input_for_clustering.temp
					tr "," "_" < $input_for_clustering.temp > $input_for_clustering
					tr ":" "_" < $input_for_clustering > $input_for_clustering.temp
					tr " " "_" < $input_for_clustering.temp > $input_for_clustering
					tr ";" "_" < $input_for_clustering > $input_for_clustering.temp
					mv $input_for_clustering.temp $input_for_clustering
				fi
				
#Delete \r from fasta file (uc_converter does not like that)
				if grep -q $'\r' $input_for_clustering; then
					sed -i 's/\r//g' $input_for_clustering
				fi

			else
			touch ${USER_HOME}/.var_babitas/Clustering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi


		if [ -e ${USER_HOME}/.var_babitas/groups_file.txt ]; then
			#Merge groups files
			echo "# Merging groups files (according to input order, using cat)"
			echo "(output = MERGEDgroups.groups; even if input was only a single file)"
			echo ""

			merge_groups=$(cat ${USER_HOME}/.var_babitas/groups_files.txt | tr "\n" " ")

			#Enter NEW LINE to the end of each file (so that the cat would work correctly)
			sed -i -e '$a\' $merge_groups
					if [ "$?" = "0" ]; then
					echo ""
					else
					touch ${USER_HOME}/.var_babitas/Clustering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
					fi

			
			echo "cat "$merge_groups

			cat $merge_groups > MERGEDgroups.groups
					if [ "$?" = "0" ]; then
			 		echo ""
					groups=$"MERGEDgroups.groups" 
					echo $WorkingDirectory"MERGEDgroups.groups" > ${USER_HOME}/.var_babitas/groups_file.txt

#Check for unallowed characters in input groups file
						if grep -q "\." $groups || grep -q "\," $groups || grep -q "\:" $groups || grep -q "\;" $groups || grep -q "\ " $groups; then
							echo "   Input groups file contains unallowed characters (.,:; or space), replacing with _ "
							echo ""
							tr "." "_" < $groups > $groups.temp
							tr "," "_" < $groups.temp > $groups
							tr ":" "_" < $groups > $groups.temp
							tr " " "_" < $groups.temp > $groups
							tr ";" "_" < $groups > $groups.temp
							mv $groups.temp $groups
						fi


					else
					touch ${USER_HOME}/.var_babitas/Clustering_error.txt && exit 1
					fi

			
		fi

	fi
fi
###############################



### Collapse homopolymers ###
if [ -e ${USER_HOME}/.var_babitas/homop_nr.txt ]; then

	collapse_homop_to=$(cat ${USER_HOME}/.var_babitas/homop_nr.txt)

	echo ""
	echo "# Collapsing homopolymers to $collapse_homop_to base pairs"
	echo ""


	################
	#collapse homopolymers that are longer than 32 (longer homopolymers than 32 reduce the replacing speed later on very significantly)
	cp $input_for_clustering Homop_check.temp
	i="0"
	while [ $i -le 0 ]; do
		if grep -q -e '[G]\{32,\}' Homop_check.temp; then
			sed -r 's/GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG/GGGGGGGGGGGGGGGGGGGGGG/g' < Homop_check.temp > Homop_collapsed.temp
		else if grep -q -e '[C]\{32,\}' Homop_check.temp; then
			sed -r 's/CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC/CCCCCCCCCCCCCCCCCCCCCC/g' < Homop_check.temp > Homop_collapsed.temp
		else if grep -q -e '[A]\{32,\}' Homop_check.temp; then
			sed -r 's/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA/AAAAAAAAAAAAAAAAAAAAAA/g' < Homop_check.temp > Homop_collapsed.temp
		else if grep -q -e '[T]\{32,\}' Homop_check.temp; then
			sed -r 's/TTTTTTTTTTTTTTTTTTTTTTTTTTTTTT/TTTTTTTTTTTTTTTTTTTTTT/g' < Homop_check.temp > Homop_collapsed.temp
		
		else
			echo ""
			if [ -e Homop_collapsed.temp ]; then
				rm Homop_collapsed.temp
			fi
			i=$[ $i+1 ]
		fi
		fi
		fi
		fi
		
		if [ -e Homop_collapsed.temp ]; then
			if grep -q -e '[G]\{32,\}' Homop_collapsed.temp; then
				sed -r 's/GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG/GGGGGGGGGGGGGGGGGGGGGG/g' < Homop_collapsed.temp > Homop_check.temp
			else if grep -q -e '[C]\{32,\}' Homop_collapsed.temp; then
				sed -r 's/CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC/CCCCCCCCCCCCCCCCCCCCCC/g' < Homop_collapsed.temp > Homop_check.temp
			else if grep -q -e '[A]\{32,\}' Homop_collapsed.temp; then
				sed -r 's/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA/AAAAAAAAAAAAAAAAAAAAAA/g' < Homop_collapsed.temp > Homop_check.temp
			else if grep -q -e '[T]\{32,\}' Homop_collapsed.temp; then
				sed -r 's/TTTTTTTTTTTTTTTTTTTTTTTTTTTTTT/TTTTTTTTTTTTTTTTTTTTTT/g' < Homop_collapsed.temp > Homop_check.temp
			else
				echo ""
				mv Homop_collapsed.temp Homop_check.temp
				i=$[ $i+1 ]
			fi
			fi
			fi
			fi
		fi
		
	done
	################

	if grep -q '3' ${USER_HOME}/.var_babitas/homop_nr.txt; then
	collapse_homop_to=$"2"
	collapse_A="AAA"
	collapse_T="TTT"
	collapse_C="CCC"
	collapse_G="GGG"
	else if grep -q '4' ${USER_HOME}/.var_babitas/homop_nr.txt; then
	collapse_homop_to=$"3"
	collapse_A="AAAA"
	collapse_T="TTTT"
	collapse_C="CCCC"
	collapse_G="GGGG"
	else if grep -q '5' ${USER_HOME}/.var_babitas/homop_nr.txt; then
	collapse_homop_to=$"4"
	collapse_A="AAAAA"
	collapse_T="TTTTT"
	collapse_C="CCCCC"
	collapse_G="GGGGG"
	else if grep -q '6' ${USER_HOME}/.var_babitas/homop_nr.txt; then
	collapse_homop_to=$"5"
	collapse_A="AAAAAA"
	collapse_T="TTTTTT"
	collapse_C="CCCCCC"
	collapse_G="GGGGGG"
	else if grep -q '7' ${USER_HOME}/.var_babitas/homop_nr.txt; then
	collapse_homop_to=$"6"
	collapse_A="AAAAAAA"
	collapse_T="TTTTTTT"
	collapse_C="CCCCCCC"
	collapse_G="GGGGGGG"
	else if grep -q '8' ${USER_HOME}/.var_babitas/homop_nr.txt; then
	collapse_homop_to=$"7"
	collapse_A="AAAAAAAA"
	collapse_T="TTTTTTTT"
	collapse_C="CCCCCCCC"
	collapse_G="GGGGGGGG"
	else if grep -q '9' ${USER_HOME}/.var_babitas/homop_nr.txt; then
	collapse_homop_to=$"8"
	collapse_A="AAAAAAAAA"
	collapse_T="TTTTTTTTT"
	collapse_C="CCCCCCCCC"
	collapse_G="GGGGGGGGG"
	else if grep -q '10' ${USER_HOME}/.var_babitas/homop_nr.txt; then
	collapse_homop_to=$"9"
	collapse_A="AAAAAAAAAA"
	collapse_T="TTTTTTTTTT"
	collapse_C="CCCCCCCCCC"
	collapse_G="GGGGGGGGGG"
	else if grep -q '11' ${USER_HOME}/.var_babitas/homop_nr.txt; then
	collapse_homop_to=$"10"
	collapse_A="AAAAAAAAAAA"
	collapse_T="TTTTTTTTTTT"
	collapse_C="CCCCCCCCCCC"
	collapse_G="GGGGGGGGGGG"
	else if grep -q '12' ${USER_HOME}/.var_babitas/homop_nr.txt; then
	collapse_homop_to=$"11"
	collapse_A="AAAAAAAAAAAA"
	collapse_T="TTTTTTTTTTTT"
	collapse_C="CCCCCCCCCCCC"
	collapse_G="GGGGGGGGGGGG"
	else if grep -q '13' ${USER_HOME}/.var_babitas/homop_nr.txt; then
	collapse_homop_to=$"12"
	collapse_A="AAAAAAAAAAAAA"
	collapse_T="TTTTTTTTTTTTT"
	collapse_C="CCCCCCCCCCCCC"
	collapse_G="GGGGGGGGGGGGG"
	else if grep -q '14' ${USER_HOME}/.var_babitas/homop_nr.txt; then
	collapse_homop_to=$"13"
	collapse_A="AAAAAAAAAAAAAA"
	collapse_T="TTTTTTTTTTTTTT"
	collapse_C="CCCCCCCCCCCCCC"
	collapse_G="GGGGGGGGGGGGGG"
	else if grep -q '15' ${USER_HOME}/.var_babitas/homop_nr.txt; then
	collapse_homop_to=$"14"
	collapse_A="AAAAAAAAAAAAAAA"
	collapse_T="TTTTTTTTTTTTTTT"
	collapse_C="CCCCCCCCCCCCCCC"
	collapse_G="GGGGGGGGGGGGGGG"
	else if grep -q '16' ${USER_HOME}/.var_babitas/homop_nr.txt; then
	collapse_homop_to=$"15"
	collapse_A="AAAAAAAAAAAAAAAA"
	collapse_T="TTTTTTTTTTTTTTTT"
	collapse_C="CCCCCCCCCCCCCCCC"
	collapse_G="GGGGGGGGGGGGGGGG"
	else if grep -q '17' ${USER_HOME}/.var_babitas/homop_nr.txt; then
	collapse_homop_to=$"16"
	collapse_A="AAAAAAAAAAAAAAAAA"
	collapse_T="TTTTTTTTTTTTTTTTT"
	collapse_C="CCCCCCCCCCCCCCCCC"
	collapse_G="GGGGGGGGGGGGGGGGG"
	else if grep -q '18' ${USER_HOME}/.var_babitas/homop_nr.txt; then
	collapse_homop_to=$"17"
	collapse_A="AAAAAAAAAAAAAAAAAA"
	collapse_T="TTTTTTTTTTTTTTTTTT"
	collapse_C="CCCCCCCCCCCCCCCCCC"
	collapse_G="GGGGGGGGGGGGGGGGGG"
	else if grep -q '19' ${USER_HOME}/.var_babitas/homop_nr.txt; then
	collapse_homop_to=$"18"
	collapse_A="AAAAAAAAAAAAAAAAAAA"
	collapse_T="TTTTTTTTTTTTTTTTTTT"
	collapse_C="CCCCCCCCCCCCCCCCCCC"
	collapse_G="GGGGGGGGGGGGGGGGGGG"
	else if grep -q '20' ${USER_HOME}/.var_babitas/homop_nr.txt; then
	collapse_homop_to=$"19"
	collapse_A="AAAAAAAAAAAAAAAAAAAA"
	collapse_T="TTTTTTTTTTTTTTTTTTTT"
	collapse_C="CCCCCCCCCCCCCCCCCCCC"
	collapse_G="GGGGGGGGGGGGGGGGGGGG"
	else if grep -q '21' ${USER_HOME}/.var_babitas/homop_nr.txt; then
	collapse_homop_to=$"20"
	collapse_A="AAAAAAAAAAAAAAAAAAAAA"
	collapse_T="TTTTTTTTTTTTTTTTTTTTT"
	collapse_C="CCCCCCCCCCCCCCCCCCCCC"
	collapse_G="GGGGGGGGGGGGGGGGGGGGG"
	else if grep -q '22' ${USER_HOME}/.var_babitas/homop_nr.txt; then
	collapse_homop_to=$"21"
	collapse_A="AAAAAAAAAAAAAAAAAAAAAA"
	collapse_T="TTTTTTTTTTTTTTTTTTTTTT"
	collapse_C="CCCCCCCCCCCCCCCCCCCCCC"
	collapse_G="GGGGGGGGGGGGGGGGGGGGGG"
	else if grep -q '23' ${USER_HOME}/.var_babitas/homop_nr.txt; then
	collapse_homop_to=$"22"
	collapse_A="AAAAAAAAAAAAAAAAAAAAAAA"
	collapse_T="TTTTTTTTTTTTTTTTTTTTTTT"
	collapse_C="CCCCCCCCCCCCCCCCCCCCCCC"
	collapse_G="GGGGGGGGGGGGGGGGGGGGGGG"
	else if grep -q '24' ${USER_HOME}/.var_babitas/homop_nr.txt; then
	collapse_homop_to=$"23"
	collapse_A="AAAAAAAAAAAAAAAAAAAAAAAA"
	collapse_T="TTTTTTTTTTTTTTTTTTTTTTTT"
	collapse_C="CCCCCCCCCCCCCCCCCCCCCCCC"
	collapse_G="GGGGGGGGGGGGGGGGGGGGGGGG"
	else if grep -q '25' ${USER_HOME}/.var_babitas/homop_nr.txt; then
	collapse_homop_to=$"24"
	collapse_A="AAAAAAAAAAAAAAAAAAAAAAAAA"
	collapse_T="TTTTTTTTTTTTTTTTTTTTTTTTT"
	collapse_C="CCCCCCCCCCCCCCCCCCCCCCCCC"
	collapse_G="GGGGGGGGGGGGGGGGGGGGGGGGG"
	else if grep -q '26' ${USER_HOME}/.var_babitas/homop_nr.txt; then
	collapse_homop_to=$"25"
	collapse_A="AAAAAAAAAAAAAAAAAAAAAAAAAA"
	collapse_T="TTTTTTTTTTTTTTTTTTTTTTTTTT"
	collapse_C="CCCCCCCCCCCCCCCCCCCCCCCCCC"
	collapse_G="GGGGGGGGGGGGGGGGGGGGGGGGGG"
	else if grep -q '27' ${USER_HOME}/.var_babitas/homop_nr.txt; then
	collapse_homop_to=$"26"
	collapse_A="AAAAAAAAAAAAAAAAAAAAAAAAAAA"
	collapse_T="TTTTTTTTTTTTTTTTTTTTTTTTTTT"
	collapse_C="CCCCCCCCCCCCCCCCCCCCCCCCCCC"
	collapse_G="GGGGGGGGGGGGGGGGGGGGGGGGGGG"
	else if grep -q '28' ${USER_HOME}/.var_babitas/homop_nr.txt; then
	collapse_homop_to=$"27"
	collapse_A="AAAAAAAAAAAAAAAAAAAAAAAAAAAA"
	collapse_T="TTTTTTTTTTTTTTTTTTTTTTTTTTTT"
	collapse_C="CCCCCCCCCCCCCCCCCCCCCCCCCCCC"
	collapse_G="GGGGGGGGGGGGGGGGGGGGGGGGGGGG"
	else if grep -q '29' ${USER_HOME}/.var_babitas/homop_nr.txt; then
	collapse_homop_to=$"28"
	collapse_A="AAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
	collapse_T="TTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
	collapse_C="CCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
	collapse_G="GGGGGGGGGGGGGGGGGGGGGGGGGGGGG"
				fi
			fi
		fi
	fi
		fi
			fi
				fi
			fi
		fi
	fi
		fi
			fi
				fi
			fi
		fi
	fi
		fi
			fi
				fi
					fi
						fi
						fi
					fi
				fi
			fi
		fi
	fi
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Clustering_error.txt
		echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi


	count_A=$(grep -c "$collapse_A" $input_for_clustering)
	count_T=$(grep -c "$collapse_T" $input_for_clustering)
	count_C=$(grep -c "$collapse_C" $input_for_clustering)
	count_G=$(grep -c "$collapse_G" $input_for_clustering)

	echo "   Size $collapse_A or longer homopolymers in $count_A seqs"
	echo "   Size $collapse_T or longer homopolymers in $count_T seqs"
	echo "   Size $collapse_C or longer homopolymers in $count_C seqs"
	echo "   Size $collapse_G or longer homopolymers in $count_G seqs"


	#Remove all characters that occur more than N+1 times in a row
	sed -r "s/(A)\1+{$collapse_homop_to}/$collapse_A/g" < Homop_check.temp > collapse_A.temp
	sed -r "s/(T)\1+{$collapse_homop_to}/$collapse_T/g" < collapse_A.temp > collapse_AT.temp
	sed -r "s/(C)\1+{$collapse_homop_to}/$collapse_C/g" < collapse_AT.temp > collapse_ATC.temp
	sed -r "s/(G)\1+{$collapse_homop_to}/$collapse_G/g" < collapse_ATC.temp > Homop_collapsed.fasta
		if [ "$?" = "0" ]; then
		echo ""
			input_for_clustering=$"Homop_collapsed.fasta"
			rm collapse_A.temp
			rm collapse_AT.temp
			rm collapse_ATC.temp
			rm Homop_check.temp
		else
		touch ${USER_HOME}/.var_babitas/Clustering_error.txt
		echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi

	

	echo "# Homopolymers collapsed"
	echo "   # output = Homop_collapsed.fasta; using it as a input for clustering"
	echo ""
	echo "Proceeding with clustering"
	echo "__________________________"

fi





############################################################################################
############################################################################################
###################        ######################################        ###################
################### CD HIT ###################################### CD HIT ###################
###################        ######################################        ###################
############################################################################################
############################################################################################
if grep -q 'CDHIT' ${USER_HOME}/.var_babitas/program.txt; then

#Set CD-HIT variables
threads=$(cat ${USER_HOME}/.var_babitas/Threads.txt)
storing=$(cat ${USER_HOME}/.var_babitas/Storing.txt)
MinSize=$(cat ${USER_HOME}/.var_babitas/MinSize.txt)
MinLen=$(cat ${USER_HOME}/.var_babitas/MinLen.txt)
Mem=$(cat ${USER_HOME}/.var_babitas/Mem.txt)
LCutoff=$(cat ${USER_HOME}/.var_babitas/LCutoff.txt)
id=$(cat ${USER_HOME}/.var_babitas/id.txt)
Algor=$(cat ${USER_HOME}/.var_babitas/Algor.txt)


echo ""
echo "Threshold = "$id
echo "Minimum seq length = "$MinLen
echo "Minimum cluster size = "$MinSize
echo "LCutoff = "$LCutoff
echo "Memory = "$Mem
echo "Threads = "$threads
echo "Storing = "$storing
echo "Algorithm = "$Algor



#Run CDHIT-est
echo ""
echo "### Clustering with CDHIT ###"

cdhit-est -i $input_for_clustering -c $id -M $Mem -d 0 -l $MinLen -T $threads -B $storing -g $Algor -s $LCutoff -o Clusters_CDHIT
		if [ "$?" = "0" ]; then
 		echo ""
		mv Clusters_CDHIT Clusters_CDHIT.fasta
		else
		touch ${USER_HOME}/.var_babitas/Clustering_error.txt
		echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi


#Extract CDHIT rep seq headers
grep ">*\*" Clusters_CDHIT.clstr | sed -e 's/.*>//g' | sed -e 's/[.].*//g' > CDHIT_RepSeqs.names

#Sort Clusters_CDHIT.fasta according to CDHIT_RepSeqs.names so that they are aligned with the clstr file
echo $WorkingDirectory > ${USER_HOME}/.var_babitas/WD.txt

python ${USER_HOME}/.babitassh/sort_seqs_based_on_names_file.py #sort seqs based on names file
		if [ "$?" = "0" ]; then
 		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Clustering_error.txt
		echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi


#Convert CDHIT cluster to regular CLUSTER format
echo "#Converting CDHIT cluster format (may take a while)"
echo $WorkingDirectory > ${USER_HOME}/.var_babitas/WD.txt

python ${USER_HOME}/.babitassh/cdhit_clstr_convert.py
		if [ "$?" = "0" ]; then
 		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Clustering_error.txt
		echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi

#Delete ... , created by CDHIT
sed -e 's/...\t/\t/g' < Converted_clusters.clstr > Clusters2.cluster 

#Changing CDHIT cluster file so that the representative seq is the first one
gawk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' CDHIT_RepSeqs.names Clusters2.cluster | \

sed ':a;N;$!ba;s/\n/endlineN/g' | sed -e 's/\t/\n/g' | sed -e 's/endlineN/endlineN\n/g' | nawk '$1 in a {$1=$1 "X" ++a[$1]}{a[$1];print}' | sed 's/endlineNX/endlineN/' | sed 's/X.*//' | gawk '!a[$0]++' |sed 's/endlineN.*/endlineN/' | tr "\n" "\t" | sed -e 's/endlineN/\n/g' | sed -e 's/^\t//' | sed '/^\n*$/d' | sed -e 's/\t\t/\t/g' > Clusters.cluster

rm CDHIT_RepSeqs.names
rm Clusters2.cluster
rm Clusters_CDHIT.fasta


##### Adding OTU and seqs number info to the rep seqs headers
#extract only seq headers, and add \tOtu
grep ">" RepSeqs_CDHIT.temp | gawk '{ print $0 "\tOtu" NR }' > RepSeqs_CDHIT1.temp

#print number of sequences in cluster file
gawk '{ print NF }'< Clusters.cluster > NF.temp

#add sequence nr info to headers
gawk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "=" $0 }' RepSeqs_CDHIT1.temp NF.temp > headers.temp

#extract only seqs
grep -v ">" RepSeqs_CDHIT.temp > seqs.temp

#merge new headers with seqs
gawk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\n" $0 }' headers.temp seqs.temp > RepSeqs_CDHIT.fasta

rm seqs.temp
rm headers.temp
rm RepSeqs_CDHIT1.temp
rm NF.temp
#####


#MinSize = 1 - minimum allowed nubmer of sequences per cluster
if grep -q '1' ${USER_HOME}/.var_babitas/MinSize.txt; then


################
################
#Make OTU table#
################
################
	if [ -e ${USER_HOME}/.var_babitas/make_otu_tab.txt ]; then
		echo "# Making OTU table"

		cluster_file=$"Clusters.cluster"

		#Making mothur list from cluster file
		tr "\t" "," < $cluster_file | tr "\n" "\t" | sed -e 's/,\t/\t/g'  > mothur.list.temp

			gawk '{print substr($0,length,1)}' mothur.list.temp | if grep -q ","; then
			a=$(cat mothur.list.temp)
			echo "${a::-1}" > mothur.list
			rm mothur.list.temp

			else
			cp mothur.list.temp mothur.list
			fi

		grep -c "" < $cluster_file | sed 's/^/0.03\t/' > OTUnr.temp 
		cat OTUnr.temp mothur.list > mothur_with_count.temp && rm OTUnr.temp
		tr "\n" "\t" < mothur_with_count.temp > mothur_with_count.list && rm mothur_with_count.temp
					if [ "$?" = "0" ]; then
					echo ""
					else
					touch ${USER_HOME}/.var_babitas/Clustering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
					fi

		python ${USER_HOME}/.babitassh/Finding_groups_in_clustering.py $groups > groups.temp
					if [ "$?" = "0" ]; then
					rm groups.temp
					else
					touch ${USER_HOME}/.var_babitas/Clustering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
					fi


		mothur "#make.shared(list=mothur_with_count.list, group=Final.groups)" | tee lastlog.txt
					if grep -q 'ERROR' lastlog.txt; then
					echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Clustering_error.txt  && exit
					else
					echo ""
					fi


		#Transpose OTU table
			#delete label column and numOTUs column
		gawk 'FS=OFS="\t" {$1="";$3="";print}' mothur_with_count.shared | \
			#Transpoe
		gawk '
		{ 
			for (i=1; i<=NF; i++)  {
			a[NR,i] = $i
			}
		}
		NF>p { p = NF }
		END {    
			for(j=1; j<=p; j++) {
			str=a[1,j]
			for(i=2; i<=NR; i++){
				str=str" "a[i,j];
			}
			print str
			}
		}' | sed -e 's/ /\t/g' > OTU_table.temp
					if [ "$?" = "0" ]; then
					echo ""
					else
					touch ${USER_HOME}/.var_babitas/Clustering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
					fi

		#Representative seqs to OTU table
		tr "\n" "\t" < RepSeqs_CDHIT.fasta | sed -e 's/>/\n>/g' | sed '1 i\RepSeqID\tOTU_ID=seqs_no\tRepSeq' | sed '/^\n*$/d' > rep_seqs_to_OTU_table.temp

		awk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' OTU_table.temp rep_seqs_to_OTU_table.temp > OTU_table.txt
			if [ "$?" = "0" ]; then
				rm OTU_table.temp
				rm rep_seqs_to_OTU_table.temp
			else
				touch ${USER_HOME}/.var_babitas/Clustering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi
		echo ""
	fi #make OTU table


	if [ -e Clusters.cluster ] && [ -e RepSeqs_CDHIT.fasta ]; then
		if [ -e RepSeqs_CDHIT.temp ]; then
			rm RepSeqs_CDHIT.temp
		fi
		if [ -e mothur.list.temp ]; then
			rm mothur.list.temp
		fi
		if [ -e mothur.list ]; then
			rm mothur.list
		fi
		if [ -e mothur_with_count.list ]; then
			rm mothur_with_count.list
		fi
		if [ -e mothur_with_count.shared ]; then
			rm mothur_with_count.shared
		fi

		touch ${USER_HOME}/.var_babitas/Clustering_finished.txt
		echo ""
		echo "##########################"
		echo "DONE"
		echo "#############################"
		echo "Clustering finished"
		echo "################################"
		echo "Output clusters = Clusters.cluster"
		echo "CD-HIT formatted cluster = Clusters_CDHIT.clstr"
		echo "CD-HIT representative seqs = RepSeqs_CDHIT.fasta"
			if [ -e OTU_table.txt ] && [ -e ${USER_HOME}/.var_babitas/make_otu_tab.txt ]; then
				echo "OTU table = OTU_table.txt"
			fi
		echo "###################################"
		echo "You may close this window now!"
		else
		touch ${USER_HOME}/.var_babitas/Clustering_error.txt
		echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
	fi
	

### MinSize > 1
	else 
		echo "# Keeping only clusters that contain >=$MinSize sequences"
		echo "gawk NF>=$MinSize < Clusters.cluster > Clusters.MinSize$MinSize.cluster"

		gawk "NF>=$MinSize" < Clusters.cluster > Clusters.MinSize$MinSize.cluster

		removed_seqs=$(awk "{if (NF<$MinSize) print NF}" Clusters.cluster | awk '{sum+=$1}END{print sum}')
		kept_seqs=$(awk '{print NF}' Clusters.MinSize$MinSize.cluster | awk '{sum+=$1}END{print sum}')
		removed_clusters=$(awk "{if (NF<$MinSize) print NF}" Clusters.cluster | wc -l)
		kept_clusters=$(awk "{if (NF>=$MinSize) print NF}" Clusters.cluster | wc -l)
		
		echo ""
		echo "# Removed $removed_clusters clusters that had less than $MinSize sequences ($removed_seqs seqs removed)"
		echo "# Kept $kept_clusters clusters with $kept_seqs sequences (Clusters.MinSize$MinSize.cluster)"
		echo ""


		#MinSize RepSeqs
		echo "# Selecting CD-HIT representative seqs for Clusters.MinSize$MinSize.cluster"
		echo "gawk {if (NF<$MinSize) print $1} Clusters.cluster > Seqs_to_remove.names"

		gawk "{if (NF<$MinSize) print $1}" Clusters.cluster > Seqs_to_remove.names

		mothur "#remove.seqs(fasta=RepSeqs_CDHIT.temp, accnos=Seqs_to_remove.names)"

		rm Seqs_to_remove.names

		
		##### Adding OTU and seqs number info to the rep seqs headers
		#extract only seq headers, and add\tOtu
		grep ">" RepSeqs_CDHIT.pick.temp | gawk '{ print $0 "\tOtu" NR }' > RepSeqs_CDHIT.pick1.temp 

		#print number of sequences in cluster file
		gawk '{ print NF }'< Clusters.MinSize$MinSize.cluster > NF.temp

		#add sequence nr info to headers
		gawk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "=" $0 }' RepSeqs_CDHIT.pick1.temp NF.temp > headers.temp

		#extract only seqs
		grep -v ">" RepSeqs_CDHIT.pick.temp > seqs.temp

		#merge new headers with seqs
		gawk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\n" $0 }' headers.temp seqs.temp > RepSeqs_CDHIT.MinSize$MinSize.fasta
				if [ "$?" = "0" ]; then
				rm seqs.temp
				rm headers.temp
				rm NF.temp
				rm RepSeqs_CDHIT.pick1.temp
				rm RepSeqs_CDHIT.pick.temp
				rm RepSeqs_CDHIT.temp
				echo ""
				else
				touch ${USER_HOME}/.var_babitas/Clustering_error.txt
				echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
				fi



		################
		################
		#Make OTU table#
		################
		################
		if [ -e ${USER_HOME}/.var_babitas/make_otu_tab.txt ]; then
			echo "# Making OTU table"
		
			cluster_file=$"Clusters.MinSize$MinSize.cluster"

			#Making mothur list from cluster file
			tr "\t" "," < $cluster_file | tr "\n" "\t" | sed -e 's/,\t/\t/g'  > mothur.list.temp

				gawk '{print substr($0,length,1)}' mothur.list.temp | if grep -q ","; then
				a=$(cat mothur.list.temp)
				echo "${a::-1}" > mothur.list
				rm mothur.list.temp

				else
				cp mothur.list.temp mothur.list
				fi

			grep -c "" < $cluster_file | sed 's/^/0.03\t/' > OTUnr.temp 
			cat OTUnr.temp mothur.list > mothur_with_count.temp && rm OTUnr.temp
			tr "\n" "\t" < mothur_with_count.temp > mothur_with_count.list && rm mothur_with_count.temp
						if [ "$?" = "0" ]; then
						echo ""
						else
						touch ${USER_HOME}/.var_babitas/Clustering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
						fi

			python ${USER_HOME}/.babitassh/Finding_groups_in_clustering.py $groups > groups.temp
						if [ "$?" = "0" ]; then
						rm groups.temp
						else
						touch ${USER_HOME}/.var_babitas/Clustering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
						fi


			mothur "#make.shared(list=mothur_with_count.list, group=Final.groups)" | tee lastlog.txt
						if grep -q 'ERROR' lastlog.txt; then
						echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Clustering_error.txt  && exit
						else
						echo ""
						fi


			#Transpose OTU table
				#delete label column and numOTUs column
			gawk 'FS=OFS="\t" {$1="";$3="";print}' mothur_with_count.shared | \
				#Transpose
			gawk '
			{ 
				for (i=1; i<=NF; i++)  {
				a[NR,i] = $i
				}
			}
			NF>p { p = NF }
			END {    
				for(j=1; j<=p; j++) {
				str=a[1,j]
				for(i=2; i<=NR; i++){
					str=str" "a[i,j];
				}
				print str
				}
			}' | sed -e 's/ /\t/g' > OTU_table.temp


		#Representative seqs to OTU table
		tr "\n" "\t" < RepSeqs_CDHIT.MinSize$MinSize.fasta | sed -e 's/>/\n>/g' | sed '1 i\RepSeqID\tOTU_ID=seqs_no\tRepSeq' | sed '/^\n*$/d' > rep_seqs_to_OTU_table.temp

		awk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' OTU_table.temp rep_seqs_to_OTU_table.temp > OTU_table.txt
				if [ "$?" = "0" ]; then
					rm OTU_table.temp
					rm rep_seqs_to_OTU_table.temp
				else
					touch ${USER_HOME}/.var_babitas/Clustering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
				fi

		fi #Make OTU table MinSize


				
				if [ -e Clusters.MinSize$MinSize.cluster ] && [ -e RepSeqs_CDHIT.MinSize$MinSize.fasta ]; then
					if [ -e mothur.list.temp ]; then
						rm mothur.list.temp
					fi
					if [ -e mothur.list ]; then
						rm mothur.list
					fi
					if [ -e mothur_with_count.list ]; then
						rm mothur_with_count.list
					fi
					if [ -e mothur_with_count.shared ]; then
						rm mothur_with_count.shared
					fi
				touch ${USER_HOME}/.var_babitas/Clustering_finished.txt
				echo ""
				echo "##########################"
				echo "DONE"
				echo "#############################"
				echo "Clustering finished"
				echo "################################"
				echo "Output clusters = Clusters.MinSize$MinSize.cluster"
				echo "Output clusters = Clusters_sort.cluster"
				echo "CD-HIT formatted cluster = Clusters_CDHIT.clstr"
				echo "CD-HIT representative seqs = RepSeqs_CDHIT.MinSize$MinSize.fasta"
				echo "CD-HIT representative seqs = RepSeqs_CDHIT.fasta"
					if [ -e OTU_table.txt ] && [ -e ${USER_HOME}/.var_babitas/make_otu_tab.txt ]; then
						echo "OTU table = OTU_table.txt"
					fi
				echo "###################################"
				echo "You may close this window now!"
				else
				touch ${USER_HOME}/.var_babitas/Clustering_error.txt
				echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
				fi
				

	fi
fi


############################################################################################
############################################################################################
###################         ######################################         #################
################### VSEARCH ###################################### VSEARCH #################
###################         ######################################         #################
############################################################################################
############################################################################################
if grep -q 'vsearch' ${USER_HOME}/.var_babitas/program.txt; then


#Set VSEARCH variables
threads=$(cat ${USER_HOME}/.var_babitas/Threads.txt)
MinSize=$(cat ${USER_HOME}/.var_babitas/MinSize.txt)
MinLen=$(cat ${USER_HOME}/.var_babitas/MinLen.txt)
id=$(cat ${USER_HOME}/.var_babitas/id.txt)
Algor=$(cat ${USER_HOME}/.var_babitas/Algor.txt)

echo ""
echo "Threshold = "$id
echo "MinLen = "$MinLen
echo "MinSize = "$MinSize
echo "Algorithm = "$Algor
echo "Threads = "$threads


#Run vsearch
echo ""
echo "### Clustering with vsearch ###"
echo "vsearch --cluster_fast $input_for_clustering --centroids vsearch_centroids.fasta --uc clustering.out.uc --minseqlength $MinLen --id $id --iddef $Algor --xsize --fasta_width 0"

vsearch --cluster_fast $input_for_clustering --centroids vsearch_cent.fasta --uc Clusters.uc --minseqlength $MinLen --id $id --iddef $Algor --xsize --fasta_width 0
		if [ "$?" = "0" ]; then
 		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Clustering_error.txt
		echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi


#Convert UC cluster to regular CLUSTER format
echo ""
echo "# Converting UC cluster to regular CLUSTER format (may take a while)"

echo $WorkingDirectory > ${USER_HOME}/.var_babitas/WD.txt

python ${USER_HOME}/.babitassh/uc_converter.py
		if [ "$?" = "0" ]; then
 		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Clustering_error.txt
		echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi


#Aligning Cluster file and RepSeqs file to the same order
mv Converted_Clusters.cluster Clusters.cluster


#Make names file based on OTU table
gawk 'BEGIN{FS="\t"}{print $1}' < Clusters.cluster > clusters.names

#Sort seqs based on names file
mv vsearch_cent.fasta Rep_seqs.temp
echo $WorkingDirectory > ${USER_HOME}/.var_babitas/WD.txt
python ${USER_HOME}/.babitassh/sort_seqs_based_on_names_file_usearch.py #input = Rep_seqs.temp; output = Rep_seqs_usearch.fasta
		if [ "$?" = "0" ]; then
 		mv Rep_seqs_usearch.fasta vsearch_centroids.temp
		else
		touch ${USER_HOME}/.var_babitas/Clustering_error.txt
		echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi


##### Adding OTU and seqs number info the the rep seqs headers
#extract only seq headers, and add\tOtu
grep ">" vsearch_centroids.temp | gawk '{ print $0 "\tOtu" NR }' > vsearch_centroids1.temp
		if [ "$?" = "0" ]; then
 		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Clustering_error.txt
		echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi

#print number of sequences in cluster file
gawk '{ print NF }'< Clusters.cluster > NF.temp
		if [ "$?" = "0" ]; then
 		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Clustering_error.txt
		echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi

#add sequence nr info to headers
gawk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "=" $0 }' vsearch_centroids1.temp NF.temp > headers.temp
		if [ "$?" = "0" ]; then
 		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Clustering_error.txt
		echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi

#extract only seqs
grep -v ">" vsearch_centroids.temp > seqs.temp
		if [ "$?" = "0" ]; then
 		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Clustering_error.txt
		echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi

#merge new headers with seqs
awk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\n" $0 }' headers.temp seqs.temp > vsearch_centroids.fasta
		if [ "$?" = "0" ]; then
 		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Clustering_error.txt
		echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi

rm seqs.temp
rm headers.temp
rm vsearch_centroids1.temp
rm NF.temp
#####


### MinSize = 1
	if grep -q '1' ${USER_HOME}/.var_babitas/MinSize.txt; then

	################
	################
	#Make OTU table#
	################
	################
		if [ -e ${USER_HOME}/.var_babitas/make_otu_tab.txt ]; then
			echo "# Making OTU table"
			
			cluster_file=$"Clusters.cluster"

			#Making mothur list from cluster file
			tr "\t" "," < $cluster_file | tr "\n" "\t" | sed -e 's/,\t/\t/g'  > mothur.list.temp

				gawk '{print substr($0,length,1)}' mothur.list.temp | if grep -q ","; then
				a=$(cat mothur.list.temp)
				echo "${a::-1}" > mothur.list
				rm mothur.list.temp

				else
				cp mothur.list.temp mothur.list
				fi

			grep -c "" < $cluster_file | sed 's/^/0.03\t/' > OTUnr.temp 
			cat OTUnr.temp mothur.list > mothur_with_count.temp && rm OTUnr.temp
			tr "\n" "\t" < mothur_with_count.temp > mothur_with_count.list && rm mothur_with_count.temp
						if [ "$?" = "0" ]; then
						echo ""
						else
						touch ${USER_HOME}/.var_babitas/Clustering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
						fi

			python ${USER_HOME}/.babitassh/Finding_groups_in_clustering.py $groups > groups.temp
						if [ "$?" = "0" ]; then
						rm groups.temp
						else
						touch ${USER_HOME}/.var_babitas/Clustering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
						fi


			mothur "#make.shared(list=mothur_with_count.list, group=Final.groups)" | tee lastlog.txt
						if grep -q 'ERROR' lastlog.txt; then
						echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Clustering_error.txt  && exit
						else
						echo ""
						fi


			#Transpose OTU table
				#delete label column and numOTUs column
			gawk 'FS=OFS="\t" {$1="";$3="";print}' mothur_with_count.shared | \
				#Transpoe
			gawk '
			{ 
				for (i=1; i<=NF; i++)  {
				a[NR,i] = $i
				}
			}
			NF>p { p = NF }
			END {    
				for(j=1; j<=p; j++) {
				str=a[1,j]
				for(i=2; i<=NR; i++){
					str=str" "a[i,j];
				}
				print str
				}
			}' | sed -e 's/ /\t/g' > OTU_table.temp
						if [ "$?" = "0" ]; then
						echo ""
						else
						touch ${USER_HOME}/.var_babitas/Clustering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
						fi

			#Representative seqs to OTU table
			tr "\n" "\t" < vsearch_centroids.fasta | sed -e 's/>/\n>/g' | sed '1 i\RepSeqID\tOTU_ID=seqs_no\tRepSeq' | sed '/^\n*$/d' > rep_seqs_to_OTU_table.temp

			awk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' OTU_table.temp rep_seqs_to_OTU_table.temp > OTU_table.txt
				if [ "$?" = "0" ]; then
					rm OTU_table.temp
					rm rep_seqs_to_OTU_table.temp
				else
					touch ${USER_HOME}/.var_babitas/Clustering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
				fi
			echo ""
		fi #OTU table
		
		#FINISH vsearch MinSize1
		if [ -e Clusters.cluster ] && [ -e vsearch_centroids.fasta ]; then
			if [ -e vsearch_centroids.temp ]; then
				rm vsearch_centroids.temp
			fi
			if [ -e clusters.names ]; then
				rm clusters.names
			fi
			if [ -e Rep_seqs.temp ]; then
				rm Rep_seqs.temp
			fi
			if [ -e mothur.list.temp ]; then
				rm mothur.list.temp
			fi
			if [ -e mothur.list ]; then
				rm mothur.list
			fi
			if [ -e mothur_with_count.list ]; then
				rm mothur_with_count.list
			fi
			if [ -e mothur_with_count.shared ]; then
				rm mothur_with_count.shared
			fi
			touch ${USER_HOME}/.var_babitas/Clustering_finished.txt
			echo ""
			echo "##########################"
			echo "DONE"
			echo "#############################"
			echo "Clustering finished"
			echo "################################"
			echo "Output clusters = Clusters.cluster"
			echo "UC formatted clusters = Clusters.uc"
			echo "Vsearch representative seqs = vsearch_centroids.fasta"
			if [ -e OTU_table.txt ] && [ -e ${USER_HOME}/.var_babitas/make_otu_tab.txt ]; then
				echo "OTU table = OTU_table.txt"
			fi
			echo "###################################"
			echo "You may close this window now!"
			else
			touch ${USER_HOME}/.var_babitas/Clustering_error.txt
			echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi
	


#### MinSize > 1
	else
		echo "# Keeping only clusters that contain >=$MinSize sequences"
		echo "gawk NF>=$MinSize < Clusters.cluster > Clusters.MinSize$MinSize.cluster"

		gawk "NF>=$MinSize" < Clusters.cluster > Clusters.MinSize$MinSize.cluster


		removed_seqs=$(gawk "{if (NF<$MinSize) print NF}" Clusters.cluster | gawk '{sum+=$1}END{print sum}')
		kept_seqs=$(gawk '{print NF}' Clusters.MinSize$MinSize.cluster | gawk '{sum+=$1}END{print sum}')
		removed_clusters=$(gawk "{if (NF<$MinSize) print NF}" Clusters.cluster | wc -l)
		kept_clusters=$(gawk "{if (NF>=$MinSize) print NF}" Clusters.cluster | wc -l)
		
		echo ""
		echo "# Removed $removed_clusters clusters that had less than $MinSize sequences ($removed_seqs seqs removed)"
		echo "# Kept $kept_clusters clusters with $kept_seqs sequences (Clusters.MinSize$MinSize.cluster)"
		echo ""


		#MinSize RepSeqs
		echo "# Selecting representative seqs for Clusters.MinSize$MinSize.cluster"
		echo "gawk {if (NF<$MinSize) print $1} Clusters.cluster > Seqs_to_remove.names"

		gawk "{if (NF<$MinSize) print $1}" Clusters.cluster > Seqs_to_remove.names

		mothur "#remove.seqs(fasta=vsearch_centroids.temp, accnos=Seqs_to_remove.names)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Clustering_error.txt  && exit
			else
			echo ""
			fi

		rm Seqs_to_remove.names

		echo ""

		#Sort seqs based on names file
		mv vsearch_centroids.pick.temp Rep_seqs.temp
		gawk 'BEGIN{FS="\t"}{print $1}' < Clusters.MinSize$MinSize.cluster > clusters_MinSize.names

		echo $WorkingDirectory > ${USER_HOME}/.var_babitas/WD.txt
		python ${USER_HOME}/.babitassh/sort_seqs_based_on_names_file_MinSizeCluster.py
				if [ "$?" = "0" ]; then
				##### Adding OTU and seqs number info the the rep seqs headers
				mv Rep_seqs.fasta vsearch_centroids.MinSize$MinSize.temp
				grep ">" vsearch_centroids.MinSize$MinSize.temp | gawk '{ print $0 "\tOtu" NR }' > vsearch_centroids.MinSize$MinSize.temp1
				gawk '{ print NF }'< Clusters.MinSize$MinSize.cluster > NFminsize.temp
				gawk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "=" $0 }' vsearch_centroids.MinSize$MinSize.temp1 NFminsize.temp > headers.temp
				grep -v ">" vsearch_centroids.MinSize$MinSize.temp > seqs.temp
				gawk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\n" $0 }' headers.temp seqs.temp > vsearch_centroids.MinSize$MinSize.fasta
				rm seqs.temp
				rm headers.temp
				rm vsearch_centroids.MinSize$MinSize.temp1
				rm vsearch_centroids.MinSize$MinSize.temp
				rm NFminsize.temp
				rm vsearch_centroids.temp
				rm clusters_MinSize.names
				rm Rep_seqs.temp
				rm clusters.names
				else
				touch ${USER_HOME}/.var_babitas/Clustering_error.txt
				echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
				fi
				
		

		################
		################
		#Make OTU table#
		################
		################
		if [ -e ${USER_HOME}/.var_babitas/make_otu_tab.txt ]; then
			echo "# Making OTU table"
			
			cluster_file=$"Clusters.MinSize$MinSize.cluster"

			#Making mothur list from cluster file
			tr "\t" "," < $cluster_file | tr "\n" "\t" | sed -e 's/,\t/\t/g'  > mothur.list.temp

				gawk '{print substr($0,length,1)}' mothur.list.temp | if grep -q ","; then
				a=$(cat mothur.list.temp)
				echo "${a::-1}" > mothur.list
				rm mothur.list.temp

				else
				cp mothur.list.temp mothur.list
				fi

			grep -c "" < $cluster_file | sed 's/^/0.03\t/' > OTUnr.temp 
			cat OTUnr.temp mothur.list > mothur_with_count.temp && rm OTUnr.temp
			tr "\n" "\t" < mothur_with_count.temp > mothur_with_count.list && rm mothur_with_count.temp
						if [ "$?" = "0" ]; then
						echo ""
						else
						touch ${USER_HOME}/.var_babitas/Clustering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
						fi

			
			python ${USER_HOME}/.babitassh/Finding_groups_in_clustering.py $groups > groups.temp
						if [ "$?" = "0" ]; then
						rm groups.temp
						else
						touch ${USER_HOME}/.var_babitas/Clustering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
						fi


			mothur "#make.shared(list=mothur_with_count.list, group=Final.groups)" | tee lastlog.txt
						if grep -q 'ERROR' lastlog.txt; then
						echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Clustering_error.txt  && exit
						else
						echo ""
						fi


			#Transpose OTU table
				#delete label column and numOTUs column
			gawk 'FS=OFS="\t" {$1="";$3="";print}' mothur_with_count.shared | \
				#Transpoe
			gawk '
			{ 
				for (i=1; i<=NF; i++)  {
				a[NR,i] = $i
				}
			}
			NF>p { p = NF }
			END {    
				for(j=1; j<=p; j++) {
				str=a[1,j]
				for(i=2; i<=NR; i++){
					str=str" "a[i,j];
				}
				print str
				}
			}' | sed -e 's/ /\t/g' > OTU_table.temp
						if [ "$?" = "0" ]; then
						echo ""
						else
						touch ${USER_HOME}/.var_babitas/Clustering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
						fi

			#Representative seqs to OTU table
			tr "\n" "\t" < vsearch_centroids.MinSize$MinSize.fasta | sed -e 's/>/\n>/g' | sed '1 i\RepSeqID\tOTU_ID=seqs_no\tRepSeq' | sed '/^\n*$/d' > rep_seqs_to_OTU_table.temp

			awk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' OTU_table.temp rep_seqs_to_OTU_table.temp > OTU_table.txt
				if [ "$?" = "0" ]; then
					rm OTU_table.temp
					rm rep_seqs_to_OTU_table.temp
				else
					touch ${USER_HOME}/.var_babitas/Clustering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
				fi
		fi #OTU table


				#FINISH vsearch MinSize > 1
				if [ -e Clusters.MinSize$MinSize.cluster ] && [ -e Clusters.MinSize$MinSize.cluster ]; then
					if [ -e mothur.list.temp ]; then
						rm mothur.list.temp
					fi
					if [ -e mothur.list ]; then
						rm mothur.list
					fi
					if [ -e mothur_with_count.list ]; then
						rm mothur_with_count.list
					fi
					if [ -e mothur_with_count.shared ]; then
						rm mothur_with_count.shared
					fi
					touch ${USER_HOME}/.var_babitas/Clustering_finished.txt
					echo ""
					echo "##########################"
					echo "DONE"
					echo "#############################"
					echo "Clustering finished"
					echo "################################"
					echo "Output clusters = Clusters.MinSize$MinSize.cluster"
					echo "Output clusters = Clusters.cluster"
					echo "UC formatted clusters = Clusters.uc"
					echo "Vsearch representative seqs = vsearch_centroids.MinSize$MinSize.fasta"
					echo "Vsearch representative seqs = vsearch_centroids.fasta"
					if [ -e OTU_table.txt ] && [ -e ${USER_HOME}/.var_babitas/make_otu_tab.txt ]; then
						echo "OTU table = OTU_table.txt"
					fi
					echo "###################################"
					echo "You may close this window now!"
					else
					touch ${USER_HOME}/.var_babitas/Clustering_error.txt
					echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
				fi
				
	fi #MinSize
fi #vsearch


############################################################################################
############################################################################################
###################       ######################################       #####################
################### SWARM ###################################### SWARM #####################
###################       ######################################       #####################
############################################################################################
############################################################################################
if grep -q 'swarm' ${USER_HOME}/.var_babitas/program.txt; then

#Set SWARM variables
id=$(cat ${USER_HOME}/.var_babitas/id.txt)
threads=$(cat ${USER_HOME}/.var_babitas/Threads.txt)
MinSize=$(cat ${USER_HOME}/.var_babitas/MinSize.txt)
MinLen=$(cat ${USER_HOME}/.var_babitas/MinLen.txt)

echo ""
echo "Threshold = "$id
echo "Minimum seq length = "$MinLen
echo "Minimum cluster size = "$MinSize
echo "Threads = "$threads

if [ -e ${USER_HOME}/.var_babitas/fastidious.txt ]; then
	fastidious=$(cat ${USER_HOME}/.var_babitas/fastidious.txt)
	echo "fastidious = TRUE"
fi

if [ -e ${USER_HOME}/.var_babitas/OTUmass.txt ]; then
	OTUmass=$(cat ${USER_HOME}/.var_babitas/OTUmass.txt)
	echo "Minimum mass of large OTU ="$OTUmass
fi

if [ -e ${USER_HOME}/.var_babitas/MismatchPenalty.txt ]; then
	MismatchPenalty=$(cat ${USER_HOME}/.var_babitas/MismatchPenalty.txt)
	echo "MismatchPenalty = "$MismatchPenalty
fi

if [ -e ${USER_HOME}/.var_babitas/MatchReward.txt ]; then
	MatchReward=$(cat ${USER_HOME}/.var_babitas/MatchReward.txt)
	echo "MatchReward = "$MatchReward
fi

if [ -e ${USER_HOME}/.var_babitas/GapOpen.txt ]; then
	GapOpen=$(cat ${USER_HOME}/.var_babitas/GapOpen.txt)
	echo "GapOpen = "$GapOpen
fi

if [ -e ${USER_HOME}/.var_babitas/GapExt.txt ]; then
	GapExt=$(cat ${USER_HOME}/.var_babitas/GapExt.txt)
	echo "GapExt = "$GapExt
fi


echo ""
echo "### Discarding sequences shorter than" $MinLen
echo "vsearch --sortbylength $input_for_clustering --output seqs_sorted.fasta --minseqlength $MinLen --fasta_width 0"

vsearch --sortbylength $input_for_clustering --output Seqs_MinLen$MinLen.fasta --minseqlength $MinLen --fasta_width 0
		if [ "$?" = "0" ]; then
 		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Clustering_error.txt
		echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi

#Dereplicate for abundance annotation required by swarm
echo "### Dereplicating for abundance annotation required by swarm"
echo "vsearch --derep_fulllength Seqs_MinLen$MinLen.fasta --sizeout --output Dereplicated_for_swarm.fasta --fasta_width 0"

vsearch --derep_fulllength Seqs_MinLen$MinLen.fasta --sizeout --output Dereplicated_for_swarm.fasta --fasta_width 0 --uc derep.uc



#Run swarm
echo ""
echo "### Clustering with SWARM ###"
echo ""

	if [ -e ${USER_HOME}/.var_babitas/GapExt.txt ]; then
	
	echo "swarm Dereplicated_for_swarm.fasta -d $id -t $threads -o Clusters.list --mothur --statistics-file statistics.stat --seeds Swarm_RepSeqs.fasta -z -m $MatchReward -p $MismatchPenalty -g $GapOpen -e $GapExt"

	swarm Dereplicated_for_swarm.fasta -d $id -t $threads -o Clusters.list.temp --mothur --statistics-file statistics.stat --seeds Swarm_RepSeqs.temp -z -m $MatchReward -p $MismatchPenalty -g $GapOpen -e $GapExt
			if [ "$?" = "0" ]; then
	 		echo ""
			else
			touch ${USER_HOME}/.var_babitas/Clustering_error.txt
			echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi


		else if [ -e ${USER_HOME}/.var_babitas/fastidious.txt ]; then

		echo "swarm Dereplicated_for_swarm.fasta -d $id -t $threads -o Clusters.list --mothur --statistics-file statistics.stat --seeds Swarm_RepSeqs.fasta -z -f -b $OTUmass"
	
		swarm Dereplicated_for_swarm.fasta -d $id -t $threads -o Clusters.list.temp --mothur --statistics-file statistics.stat --seeds Swarm_RepSeqs.temp -z -f -b $OTUmass
			if [ "$?" = "0" ]; then
	 		echo ""
			else
			touch ${USER_HOME}/.var_babitas/Clustering_error.txt
			echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

		else 

		echo "swarm Dereplicated_for_swarm.fasta -d $id -t $threads -o Clusters.list --mothur --statistics-file statistics.stat --seeds Swarm_RepSeqs.fasta -z"

		swarm Dereplicated_for_swarm.fasta -d $id -t $threads -o Clusters.list.temp --mothur --statistics-file statistics.stat --seeds Swarm_RepSeqs.temp -z
			if [ "$?" = "0" ]; then
	 		echo ""
			else
			touch ${USER_HOME}/.var_babitas/Clustering_error.txt
			echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

		fi
	fi



#Remove size=; from cluster.list  file
gawk 'BEGIN{FS=OFS="\t"}{gsub(";size=[0-9]*;","", $0); print}' Clusters.list.temp > Clusters.list

#Convert MOTHUR cluster to regular CLUSTER format
tr "\t" "\n" < Clusters.list | tr "," "\t" | tail -n+3 > Dereplicate_Clusters.cluster && rm Clusters.list.temp && rm Clusters.list

###Add unique seqs info from derep.names to CLUSTER file
	#Discard singletones from derep.names file
echo ""
echo "# Swarm default cluster file contains only dereplicated reads"
echo "   Writing a cluster file (Swarm_cluster.cluster) that contains all reads"
echo ""

	#Convert derep.uc file to names file, to read unique seqs info and add it to CLUSTER file (for correct seqs count, and making correct OTU table)
python ${USER_HOME}/.babitassh/uc_converter_inout.py derep.uc derep.names
	if [ "$?" = "0" ]; then
		rm derep.uc
	else
		touch ${USER_HOME}/.var_babitas/Clustering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
	fi

gawk "NF>=2" derep.names > derep_no_singletones.names
	if [ "$?" = "0" ]; then
	 	rm derep.names
	else
		touch ${USER_HOME}/.var_babitas/Clustering_error.txt
		echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
	fi
	
	#Add unique seqs info from derep.names to CLUSTER file
if [ -s derep_no_singletones.names ]; then #only when all reads are not unique, i.e the no_singletones file is npt empty
	python ${USER_HOME}/.babitassh/expand_CLUSTER_accordingToNamesFile.py #output = Swarm_cluster.cluster #inputs = derep_no_singletones.names and Dereplicate_Clusters.cluster
		if [ "$?" = "0" ]; then
			rm derep_no_singletones.names
		else
			touch ${USER_HOME}/.var_babitas/Clustering_error.txt
			echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi
	else
	rm derep_no_singletones.names
	cp Dereplicate_Clusters.cluster Swarm_cluster.cluster
fi
	


##### Adding OTU info to the rep seqs headers
#extract only seq headers, and add \tOtu
grep ">" Swarm_RepSeqs.temp | gawk '{ print $0 "\tOtu" NR }' > headers.temp

#extract only seqs
grep -v ">" Swarm_RepSeqs.temp > seqs.temp

#merge new headers with seqs
gawk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\n" $0 }' headers.temp seqs.temp > Swarm_RepSeqs.fasta
rm headers.temp
rm seqs.temp
#####


### MinSize = 1
	if grep -q '1' ${USER_HOME}/.var_babitas/MinSize.txt; then

		################
		################
		#Make OTU table#
		################
		################
		if [ -e ${USER_HOME}/.var_babitas/make_otu_tab.txt ]; then
			echo "# Making OTU table (using Swarm_cluster.cluster)"
			cluster_file=$"Swarm_cluster.cluster"

			#Making mothur list from cluster file
			tr "\t" "," < $cluster_file | tr "\n" "\t" | sed -e 's/,\t/\t/g'  > mothur.list.temp

				gawk '{print substr($0,length,1)}' mothur.list.temp | if grep -q ","; then
					a=$(cat mothur.list.temp)
					echo "${a::-1}" > mothur.list
				else
					cp mothur.list.temp mothur.list
				fi

			grep -c "" < $cluster_file | sed 's/^/0.03\t/' > OTUnr.temp 
			cat OTUnr.temp mothur.list > mothur_with_count.temp && rm OTUnr.temp
			tr "\n" "\t" < mothur_with_count.temp > mothur_with_count.list && rm mothur_with_count.temp
						if [ "$?" = "0" ]; then
						echo ""
						else
						touch ${USER_HOME}/.var_babitas/Clustering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
						fi

			python ${USER_HOME}/.babitassh/Finding_groups_in_clustering.py $groups > groups.temp
						if [ "$?" = "0" ]; then
						rm groups.temp
						else
						touch ${USER_HOME}/.var_babitas/Clustering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
						fi


			mothur "#make.shared(list=mothur_with_count.list, group=Final.groups)" | tee lastlog.txt
						if grep -q 'ERROR' lastlog.txt; then
						echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Clustering_error.txt  && exit
						else
						echo ""
						fi


			#Transpose OTU table
				#delete label column and numOTUs column
			gawk 'FS=OFS="\t" {$1="";$3="";print}' mothur_with_count.shared | \
				#Transpoe
			gawk '
			{ 
				for (i=1; i<=NF; i++)  {
				a[NR,i] = $i
				}
			}
			NF>p { p = NF }
			END {    
				for(j=1; j<=p; j++) {
				str=a[1,j]
				for(i=2; i<=NR; i++){
					str=str" "a[i,j];
				}
				print str
				}
			}' | sed -e 's/ /\t/g' > OTU_table.temp
						if [ "$?" = "0" ]; then
						echo ""
						else
						touch ${USER_HOME}/.var_babitas/Clustering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
						fi

			#Representative seqs to OTU table
			tr "\n" "\t" < Swarm_RepSeqs.fasta | sed -e 's/>/\n>/g' | sed '1 i\RepSeqID\tOTU_ID\tRepSeq' | sed '/^\n*$/d' > rep_seqs_to_OTU_table.temp

			awk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' OTU_table.temp rep_seqs_to_OTU_table.temp > OTU_table.txt
				if [ "$?" = "0" ]; then
					rm OTU_table.temp
					rm rep_seqs_to_OTU_table.temp
				else
					touch ${USER_HOME}/.var_babitas/Clustering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
				fi
			echo ""
		fi #OTU table

		
		if [ -e Clusters.cluster ] && [ -e Swarm_RepSeqs.fasta ]; then
			if [ -e Swarm_RepSeqs.temp ]; then
				rm Swarm_RepSeqs.temp
			fi
			if [ -e mothur.list.temp ]; then
				rm mothur.list.temp
			fi
			if [ -e mothur.list ]; then
				rm mothur.list
			fi
			if [ -e mothur_with_count.list ]; then
				rm mothur_with_count.list
			fi
			if [ -e mothur_with_count.shared ]; then
				rm mothur_with_count.shared
			fi
		touch ${USER_HOME}/.var_babitas/Clustering_finished.txt
		echo ""
		echo "##########################"
		echo "DONE"
		echo "#############################"
		echo "Clustering finished"
		echo "################################"
		echo "Dereplicate clusters = Dereplicate_Clusters.cluster (swarm clusters only dereplicated sequences, so this cluster file contains only unique reads)"
		echo "Cluster file = Swarm_cluster.cluster (Cluster file that includes all reads)"
		echo "SWARM representative seqs = Swarm_RepSeqs.fasta"
			if [ -e OTU_table.txt ] && [ -e ${USER_HOME}/.var_babitas/make_otu_tab.txt ]; then
				echo "OTU table = OTU_table.txt"
			fi
		echo "###################################"
		echo "You may close this window now!"
		else
		touch ${USER_HOME}/.var_babitas/Clustering_error.txt
		echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi

		
### MinSize > 1
	else

		#MinSize - minimum allowed nubmer of sequences per cluster
		echo "# Keeping only clusters that contain >=$MinSize sequences"
		echo "gawk NF>=$MinSize < Swarm_cluster.cluster > Swarm_cluster.MinSize$MinSize.cluster"

		gawk "NF>=$MinSize" < Swarm_cluster.cluster > Swarm_cluster.MinSize$MinSize.cluster

		removed_seqs=$(gawk "{if (NF<$MinSize) print NF}" Swarm_cluster.cluster | gawk '{sum+=$1}END{print sum}')
		kept_seqs=$(gawk '{print NF}' Swarm_cluster.MinSize$MinSize.cluster | gawk '{sum+=$1}END{print sum}')
		removed_clusters=$(gawk "{if (NF<$MinSize) print NF}" Swarm_cluster.cluster | wc -l)
		kept_clusters=$(gawk "{if (NF>=$MinSize) print NF}" Swarm_cluster.cluster | wc -l)
		
		echo ""
		echo "# Removed $removed_clusters clusters that had less than $MinSize sequences ($removed_seqs seqs removed)"
		echo "# Kept $kept_clusters clusters with $kept_seqs sequences (Swarm_cluster.MinSize$MinSize.cluster)"
		echo ""



		#### MinSize rep-seqs ###
 
		#Make names file based on cluster file
		gawk 'BEGIN{FS="\t"}{print $1}' < Swarm_cluster.MinSize$MinSize.cluster > clusters.names

		
		#Sort seqs based on names file
		echo $WorkingDirectory > ${USER_HOME}/.var_babitas/WD.txt
		python ${USER_HOME}/.babitassh/sort_seqs_based_on_names_file_inout.py $input_for_clustering  clusters.names Swarm_RepSeqs_MinSize$MinSize.temp
		

		##### Adding OTU info to the rep seqs headers
		#extract only seq headers, and add\tOtu
		grep ">" Swarm_RepSeqs_MinSize$MinSize.temp | gawk '{ print $0 "\tOtu" NR }' > headers.temp

		#extract only seqs
		grep -v ">" Swarm_RepSeqs_MinSize$MinSize.temp > seqs.temp

		#merge new headers with seqs
		gawk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\n" $0 }' headers.temp seqs.temp > Swarm_RepSeqs_MinSize$MinSize.fasta
		rm headers.temp
		rm seqs.temp
		rm Swarm_RepSeqs.temp


		

		################
		#Make OTU table#
		################
		################
		if [ -e ${USER_HOME}/.var_babitas/make_otu_tab.txt ]; then
			echo "# Making OTU table (using Swarm_cluster.MinSize$MinSize.cluster)"
			cluster_file=$"Swarm_cluster.MinSize$MinSize.cluster"

			#Making mothur list from cluster file
			tr "\t" "," < $cluster_file | tr "\n" "\t" | sed -e 's/,\t/\t/g'  > mothur.list.temp

				gawk '{print substr($0,length,1)}' mothur.list.temp | if grep -q ","; then
				a=$(cat mothur.list.temp)
				echo "${a::-1}" > mothur.list
				

				else
				cp mothur.list.temp mothur.list
				fi

			grep -c "" < $cluster_file | sed 's/^/0.03\t/' > OTUnr.temp 
			cat OTUnr.temp mothur.list > mothur_with_count.temp && rm OTUnr.temp
			tr "\n" "\t" < mothur_with_count.temp > mothur_with_count.list && rm mothur_with_count.temp
						if [ "$?" = "0" ]; then
						echo ""
						else
						touch ${USER_HOME}/.var_babitas/Clustering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
						fi

			python ${USER_HOME}/.babitassh/Finding_groups_in_clustering.py $groups > groups.temp
						if [ "$?" = "0" ]; then
						rm groups.temp
						else
						touch ${USER_HOME}/.var_babitas/Clustering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
						fi


			mothur "#make.shared(list=mothur_with_count.list, group=Final.groups)" | tee lastlog.txt
						if grep -q 'ERROR' lastlog.txt; then
						echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Clustering_error.txt  && exit
						else
						echo ""
						fi


			#Transpose OTU table
				#delete label column and numOTUs column
			gawk 'FS=OFS="\t" {$1="";$3="";print}' mothur_with_count.shared | \
				#Transpoe
			gawk '
			{ 
				for (i=1; i<=NF; i++)  {
				a[NR,i] = $i
				}
			}
			NF>p { p = NF }
			END {    
				for(j=1; j<=p; j++) {
				str=a[1,j]
				for(i=2; i<=NR; i++){
					str=str" "a[i,j];
				}
				print str
				}
			}' | sed -e 's/ /\t/g' > OTU_table.temp
						if [ "$?" = "0" ]; then
						echo ""
						else
						touch ${USER_HOME}/.var_babitas/Clustering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
						fi

			#Representative seqs to OTU table
			tr "\n" "\t" < Swarm_RepSeqs_MinSize$MinSize.fasta | sed -e 's/>/\n>/g' | sed '1 i\RepSeqID\tOTU_ID\tRepSeq' | sed '/^\n*$/d' > rep_seqs_to_OTU_table.temp

			awk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' OTU_table.temp rep_seqs_to_OTU_table.temp > OTU_table.txt
				if [ "$?" = "0" ]; then
					rm OTU_table.temp
					rm rep_seqs_to_OTU_table.temp
				else
					touch ${USER_HOME}/.var_babitas/Clustering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
				fi
			echo ""
		fi #OTU table

				if [ -e Swarm_cluster.MinSize$MinSize.cluster ] && [ -e Swarm_RepSeqs_MinSize$MinSize.fasta ]; then
				touch ${USER_HOME}/.var_babitas/Clustering_finished.txt
				echo ""
					if [ -e clusters.names ]; then
						rm clusters.names
					fi
					if [ -e Swarm_RepSeqs_MinSize$MinSize.temp ]; then
						rm Swarm_RepSeqs_MinSize$MinSize.temp
					fi
					if [ -e mothur.list.temp ]; then
						rm mothur.list.temp
					fi
					if [ -e mothur.list ]; then
						rm mothur.list
					fi
					if [ -e mothur_with_count.list ]; then
						rm mothur_with_count.list
					fi
					if [ -e mothur_with_count.shared ]; then
						rm mothur_with_count.shared
					fi
					
				echo "##########################"
				echo "DONE"
				echo "#############################"
				echo "Clustering finished"
				echo "################################"
				echo "Cluster file = Swarm_cluster.cluster (Cluster file that includes all reads)"
				echo "MinSize$MinSize clusters = Swarm_cluster.MinSize$MinSize.cluster"
				echo "Dereplicate clusters = Dereplicate_Clusters.cluster (swarm clusters only dereplicated sequences, so this cluster file contains only unique reads)"
				echo "SWARM representative seqs = Swarm_RepSeqs.fasta"
				echo "SWARM representative seqs MinSize$MinSize = Swarm_RepSeqs_MinSize$MinSize.fasta"
					if [ -e OTU_table.txt ] && [ -e ${USER_HOME}/.var_babitas/make_otu_tab.txt ]; then
						echo "OTU table MinSize$MinSize = OTU_table.txt"
					fi
				echo "###################################"
				echo "You may close this window now!"
				else
				touch ${USER_HOME}/.var_babitas/Clustering_error.txt
				echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
				fi

	fi #MinSize
fi #swarm



############################################################################################
############################################################################################
##################            #################################            #################
##################   mothur   #################################   mothur   #################
##################            #################################            #################
############################################################################################
############################################################################################
if grep -q 'mothur' ${USER_HOME}/.var_babitas/program.txt; then
echo ""

#Set mothur variables
calc=$(cat ${USER_HOME}/.var_babitas/calc.txt)
echo "Distance calc = "$calc

countends=$(cat ${USER_HOME}/.var_babitas/countends.txt)
echo "countends = "$countends

Algor=$(cat ${USER_HOME}/.var_babitas/Algor.txt)
echo "Clustering algorithm = "$Algor

id=$(cat ${USER_HOME}/.var_babitas/id.txt)
echo "Cutoff = "$id

Precision=$(cat ${USER_HOME}/.var_babitas/Precision.txt)
echo "Precision = "$Precision

hard=$(cat ${USER_HOME}/.var_babitas/hard.txt)
echo "hard = "$hard

Processors=$(cat ${USER_HOME}/.var_babitas/Processors.txt)
echo "Processors = "$Processors
echo ""




#Distance matrix must be inputted for clustering to be successful
echo "# Making unique seqs"

mothur "#unique.seqs(fasta=$input_for_clustering)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Clustering_error.txt  && exit
			else
			echo ""
			fi


	input_unique=$(echo $input_for_clustering | awk 'BEGIN{FS=OFS="."} {$NF="unique.fasta"}1')
	input_name=$(echo $input_for_clustering | awk 'BEGIN{FS=OFS="."} {$NF="names"}1')




#Make distance matrix
echo""
echo "# Making distance matrix"

mothur "#dist.seqs(fasta=$input_unique, calc=$calc, countends=$countends, processors=$Processors)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Clustering_error.txt  && exit
			else
			echo ""
			fi

	input_dist=$(echo $input_unique | sed -e 's/.unique.fasta/.unique.dist/g')

#Cluster seqs
output_list=$(echo $input_unique | sed -e 's/.unique.fasta/.unique.*.list/g')
echo ""
echo "### Clustering with mothur ###"
echo ""

mothur "#cluster(column=$input_dist, name=$input_name, method=$Algor, cutoff=$id, hard=$hard, precision=$Precision)" | tee lastlog.txt

			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Clustering_error.txt  && exit
			else
			touch ${USER_HOME}/.var_babitas/Clustering_finished.txt
			echo ""
			echo "##########################"
			echo "DONE"
			echo "#############################"
			echo "Clustering finished"
			echo "################################"
			echo "Motur list formatted cluster output = "$output_list
			echo "###################################"
			echo "You may close this window now!"
			fi

fi



############################################################################################
############################################################################################
##################            #################################            #################
##################  USEARCH   #################################   USEARCH  #################
##################            #################################            #################
############################################################################################
############################################################################################
if grep -q 'usearch' ${USER_HOME}/.var_babitas/program.txt; then
echo ""
echo "#Using:"
echo "usearch (v8.1.1861) - Edgar, R.C., 2010. Search and clustering orders of magnitude faster than BLAST. Bioinformatics 26, 2460-2461."
echo "www.drive5.com/usearch/"
echo ""

usearch8=$(cat ${USER_HOME}/.var_babitas/usearch_location.loc)

#Set usearch variables
threads=$(cat ${USER_HOME}/.var_babitas/Threads.txt)
MinSize=$(cat ${USER_HOME}/.var_babitas/MinSize.txt)
MinLen=$(cat ${USER_HOME}/.var_babitas/MinLen.txt)
id=$(cat ${USER_HOME}/.var_babitas/id.txt)

echo ""
echo "Threshold = "$id
echo "Minimum seq length = "$MinLen
echo "Minimum cluster size = "$MinSize
echo "Threads = "$threads
echo ""


#Run usearch
	if grep -q 'UPARSE' ${USER_HOME}/.var_babitas/Algor.txt; then
	echo "### UPARSE ###"
	
	id2=$((100-$id))
	id3=$(echo "0."$id2)
	
	
#relabel input file for usearch (to make OTU table)
		if [ -e ${USER_HOME}/.var_babitas/make_otu_tab.txt ]; then
		echo "# Relabeling input file for usearch ... (adding groups information for OTU table)"
		
			echo $WorkingDirectory > ${USER_HOME}/.var_babitas/WD.txt
			python ${USER_HOME}/.babitassh/relable_AddGroups.py > relable.error
				if [ "$?" = "0" ]; then
				echo " # done -> output = Relabelled_for_USEARCH.fasta"
				echo ""
					if grep -q 'ERROR' relable.error; then
					touch ${USER_HOME}/.var_babitas/Clustering_error.txt && echo "# ERROR occured: fasta and group file mismatch" 1>&2 && echo "Close this window" && exit 1
					else
					rm relable.error
					fi
				else
				touch ${USER_HOME}/.var_babitas/Clustering_error.txt && echo "### ERROR ###" 1>&2 && echo "Close this window" && exit 1
				fi
			
			
			#Sort by length, minseqlength
			echo "# Sort by length, minseqlength"
			echo "$usearch8 -sortbylength Relabelled_for_USEARCH.fasta -fastaout sortbylength_sorted.fasta -minseqlength $MinLen"		

			$usearch8 -sortbylength Relabelled_for_USEARCH.fasta -fastaout sortbylength_sorted.fasta -minseqlength $MinLen
				if [ "$?" = "0" ]; then
				echo ""
				else
				touch ${USER_HOME}/.var_babitas/Clustering_error.txt
				echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
				fi
			
		else #if not making an OTU table
			#Sort by length, minseqlength
			echo "# Sort by length, minseqlength"
			echo "$usearch8 -sortbylength $input_for_clustering -fastaout sortbylength_sorted.fasta -minseqlength $MinLen"		

			$usearch8 -sortbylength $input_for_clustering -fastaout sortbylength_sorted.fasta -minseqlength $MinLen
				if [ "$?" = "0" ]; then
				echo ""
				else
				touch ${USER_HOME}/.var_babitas/Clustering_error.txt
				echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
				fi
			
		fi #adding Groups info to seqs for OTU table 
		

		#Dereplicate
		echo "# Dereplicating"
		echo "$usearch8 -derep_fulllength sortbylength_sorted.fasta -fastaout sortbylength_uniques.fasta -sizeout -threads $threads"
		$usearch8 -derep_fulllength sortbylength_sorted.fasta -fastaout sortbylength_uniques.fasta -sizeout -threads $threads
			if [ "$?" = "0" ]; then
	 		echo ""
			else
			touch ${USER_HOME}/.var_babitas/Clustering_error.txt
			echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi


		#Cluster_otus, MinSize
		echo ""
		echo "### Clustering with usearch UPARSE ###"
		echo "$usearch8 -cluster_otus sortbylength_uniques.fasta -otu_radius_pct $id -otus Rep_seqs_usearch.fasta -uparseout uparseout.up -minsize $MinSize"

		$usearch8 -cluster_otus sortbylength_uniques.fasta -otu_radius_pct $id -otus Usearch_OTUs.fasta -uparseout uparseout.up -minsize $MinSize
			if [ "$?" = "0" ]; then
	 		echo ""
			else
			touch ${USER_HOME}/.var_babitas/Clustering_error.txt
			echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi


		#Make OTU table
		if [ -e ${USER_HOME}/.var_babitas/make_otu_tab.txt ]; then
			echo ""
			echo "# Making OTU table ... "
			echo "$usearch8 -usearch_global Relabelled_for_USEARCH.fasta -db Usearch_OTUs.fasta -strand plus -id $id3 -otutabout OTU_table.txt -threads $threads"
		
			#Rename Usearch_OTUs.fasta (add OTU id) to make OTU table
				#Seqs format to one line
			fasta_formatter -i Usearch_OTUs.fasta -w 0 > Usearch_OTUs.temp
				#Extract only headers and add OTU id
			grep "^>" Usearch_OTUs.temp | awk '{ print $0 ";OTU" NR }' > headers.temp
				#Extraxt only seqs
			grep -v "^>" Usearch_OTUs.temp > seqs.temp
				#Merge new headers and seqs
			awk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\n" $0 }' headers.temp seqs.temp > Rep_seqs.temp


			$usearch8 -usearch_global Relabelled_for_USEARCH.fasta -db Rep_seqs.temp -strand plus -id $id3 -otutabout OTU_table.temp -threads $threads
				if [ "$?" = "0" ]; then
				echo ""
				else
				touch ${USER_HOME}/.var_babitas/Clustering_error.txt
				echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
				fi
				
			#Sort Rep_seqs based on OTU table - need to remove everything after ; in fasta file
			sed -i 's/;.*//g' Rep_seqs.temp

				#Make names file based on OTU table
			gawk 'BEGIN{FS="\t"}{print $1}' < OTU_table.temp > clusters.names

				#Sort seqs based on names file
			echo $WorkingDirectory > ${USER_HOME}/.var_babitas/WD.txt
			python ${USER_HOME}/.babitassh/sort_seqs_based_on_names_file_usearch.py
			mv Rep_seqs_usearch.fasta Usearch_OTUs.fasta


			#Representative seqs to OTU table
			tr "\n" "\t" < Usearch_OTUs.fasta | sed -e 's/>/\n>/g' | sed '1 i\RepSeqID\tRepSeq' | sed '/^\n*$/d' > rep_seqs_to_OTU_table.temp

			awk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' OTU_table.temp rep_seqs_to_OTU_table.temp > OTU_table.txt && rm OTU_table.temp && rm rep_seqs_to_OTU_table.temp
			echo ""
				
		fi #OTU table


		if [ "$?" = "0" ] && [ -e Usearch_OTUs.fasta ] && [ -e uparseout.up ]; then
			touch ${USER_HOME}/.var_babitas/Clustering_finished.txt
			if [ -e clusters.names ]; then
				rm clusters.names
			fi
			if [ -e Usearch_OTUs.temp ]; then
				rm Usearch_OTUs.temp
			fi
			if [ -e headers.temp ]; then
				rm headers.temp
			fi
			if [ -e seqs.temp ]; then
				rm seqs.temp
			fi
			if [ -e Rep_seqs.temp ]; then
				rm Rep_seqs.temp
			fi
			echo ""
			echo "##########################"
			echo "DONE"
			echo "#############################"
			echo "Clustering finished"
			echo "################################"
			echo "Cluster file = uparseout.up"
			echo "Representative seq = Usearch_OTUs.fasta"
			if [ -e ${USER_HOME}/.var_babitas/make_otu_tab.txt ]; then
				echo "OTU table = OTU_table.txt"
			fi
			echo "###################################"
			echo "You may close this window now!"
		else
			touch ${USER_HOME}/.var_babitas/Clustering_error.txt
			echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi






################################################
#################### UCLUST #################### 
################################################

	else if grep -q 'UCLUST' ${USER_HOME}/.var_babitas/Algor.txt; then
		echo "### UCLUST ###"
		
		
#relabel input file for usearch (to make OTU table)
		if [ -e ${USER_HOME}/.var_babitas/make_otu_tab.txt ]; then
		echo "# Relabeling input file for usearch ... (adding groups information for OTU table)"

			echo $WorkingDirectory > ${USER_HOME}/.var_babitas/WD.txt
			python ${USER_HOME}/.babitassh/relable_AddGroups.py > relable.error
				if [ "$?" = "0" ]; then
				echo " # done -> output = Relabelled_for_USEARCH.fasta"
				echo ""
					if grep -q 'ERROR' relable.error; then
					touch ${USER_HOME}/.var_babitas/Clustering_error.txt && echo "# ERROR occured: fasta and group file mismatch" 1>&2 && echo "Close this window" && exit 1
					else
					rm relable.error
					fi
				else
				touch ${USER_HOME}/.var_babitas/Clustering_error.txt && echo "### ERROR ###" 1>&2 && echo "Close this window" && exit 1
				fi
	
			#Sort by length, minseqlength
			echo ""
			echo "# Sort by length, minseqlength"
			echo "usearch -sortbylength Relabelled_for_USEARCH.fasta -fastaout sortbylength_sorted.fasta -minseqlength $MinLen"

			usearch -sortbylength Relabelled_for_USEARCH.fasta -fastaout sortbylength_sorted.fasta -minseqlength $MinLen
				if [ "$?" = "0" ]; then
				echo ""
				else
				touch ${USER_HOME}/.var_babitas/Clustering_error.txt
				echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
				fi
				
		else #if not making OTU table
			#Sort by length, minseqlength
			echo ""
			echo "# Sort by length, minseqlength"
			echo "usearch -sortbylength $input_for_clustering -fastaout sortbylength_sorted.fasta -minseqlength $MinLen"

			usearch -sortbylength $input_for_clustering -fastaout sortbylength_sorted.fasta -minseqlength $MinLen
				if [ "$?" = "0" ]; then
				echo ""
				else
				touch ${USER_HOME}/.var_babitas/Clustering_error.txt
				echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
				fi
			
		fi #relabelling for OTU table


		#Cluster_fast
		echo ""
		echo "### Clustering with usearch UCLUST ###"
		echo "usearch -cluster_smallmem sortbylength_sorted.fasta -id $id -centroids Usearch_centroids.fasta -uc Clusters.uc -sizeout"

		usearch -cluster_smallmem sortbylength_sorted.fasta -id $id -centroids Usearch_centroids.fasta -uc Clusters.uc -sizeout
			if [ "$?" = "0" ]; then
	 		echo ""
			else
			touch ${USER_HOME}/.var_babitas/Clustering_error.txt
			echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

		#Sort by size
		echo "# Sort by size"
		echo "usearch -sortbysize Usearch_centroids.fasta -fastaout Rep_seqs_usearchMinSize$MinSize.fasta -minsize $MinSize"
		echo ""
		usearch -sortbysize Usearch_centroids.fasta -fastaout Rep_seqs_usearchMinSize$MinSize.fasta -minsize $MinSize
			if [ "$?" = "0" ]; then
	 		echo ""
			else
			touch ${USER_HOME}/.var_babitas/Clustering_error.txt
			echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi


		#Make OTU table
		if [ -e ${USER_HOME}/.var_babitas/make_otu_tab.txt ]; then
			echo ""
			echo "# Making OTU table ... "
			echo "usearch -usearch_global Relabelled_for_USEARCH.fasta -db Rep_seqs_usearchMinSize$MinSize.fasta -strand plus -otutabout OTU_table.txt -threads $threads"

			usearch -usearch_global Relabelled_for_USEARCH.fasta -db Rep_seqs_usearchMinSize$MinSize.fasta -strand plus -id $id -otutabout OTU_table.temp -threads $threads
				if [ "$?" = "0" ]; then
				echo ""
				else
				touch ${USER_HOME}/.var_babitas/Clustering_error.txt
				echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
				fi

			#MinSize cluster Rep_seqs sort
			fasta_formatter -i Rep_seqs_usearchMinSize$MinSize.fasta -w 0 > Rep_seqs.temp
				if [ "$?" = "0" ]; then
				rm Usearch_centroids.fasta
				else
				touch ${USER_HOME}/.var_babitas/Clustering_error.txt
				echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
				fi


			#Sort Rep_seqs based on OTU table - need to remove everything after ; in fasta file
			sed -i 's/;.*//g' Rep_seqs.temp

				#Make names file based on OTU table
			gawk 'BEGIN{FS="\t"}{print $1}' < OTU_table.temp > clusters.names

				#Sort seqs based on names file
			echo $WorkingDirectory > ${USER_HOME}/.var_babitas/WD.txt
			python ${USER_HOME}/.babitassh/sort_seqs_based_on_names_file_usearch.py #inputs = clusters.names and Rep_seqs.temp, out = Rep_seqs_usearch.fasta

			#Representative seqs to OTU table
			tr "\n" "\t" < Rep_seqs_usearch.fasta | sed -e 's/>/\n>/g' | sed '1 i\RepSeqID\tRepSeq' | sed '/^\n*$/d' > rep_seqs_to_OTU_table.temp

			awk 'NR==FNR{a[FNR]=$0; next} {print a[FNR] "\t" $0 }' OTU_table.temp rep_seqs_to_OTU_table.temp > OTU_table.txt
			echo ""
		
		fi #OTU table


			if [ "$?" = "0" ] && [ -e Clusters.uc ] && [ -e Rep_seqs_usearchMinSize$MinSize.fasta ]; then
			touch ${USER_HOME}/.var_babitas/Clustering_finished.txt
			if [ -e clusters.names ]; then
				rm clusters.names
			fi
			if [ -e Rep_seqs.temp ]; then
				rm Rep_seqs.temp
			fi
			if [ -e rep_seqs_to_OTU_table.temp ]; then
				rm rep_seqs_to_OTU_table.temp
			fi
			if [ -e OTU_table.temp ]; then
				rm OTU_table.temp
			fi
			if [ -e Centroids_sorted.fasta ]; then
				rm Centroids_sorted.fasta
			fi
			echo ""
			echo "##########################"
			echo "DONE"
			echo "#############################"
			echo "Clustering finished"
			echo "################################"
			echo "Cluster file = Clusters.uc"
			if [ -e ${USER_HOME}/.var_babitas/make_otu_tab.txt ]; then
				echo "OTU table = OTU_table.txt"
				echo "Representative seqs = Rep_seqs_usearch.fasta (usearch centroids)"
				rm Rep_seqs_usearchMinSize$MinSize.fasta
			else
				echo "Representative seqs = Rep_seqs_usearchMinSize$MinSize.fasta (usearch centroids)"
			fi
			echo "###################################"
			echo "You may close this window now!"
			else
			touch ${USER_HOME}/.var_babitas/Clustering_error.txt
			echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	fi
	fi

fi


#Delete mothur_logfiles
if ls mothur.*.logfile 1> /dev/null 2>&1; then
	rm *.logfile
fi



