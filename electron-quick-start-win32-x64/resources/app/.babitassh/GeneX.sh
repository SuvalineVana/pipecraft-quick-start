#!/bin/bash


echo "### Gene extraction ###"
echo ""
echo "When using the incorporated tools, please cite as follows:"
echo "ITS Extractor - Bengtsson-Palme J., et al., 2013. Improved software detection and extraction of ITS1 and ITS2 from ribosomal ITS sequences of fungi and other eukaryotes for analysis of environmental sequencing data. Methods in Ecology and Evolution 4, 914-919."
echo "Copyright (C) 2012-2014 Johan Bengtsson-Palme et al."
echo "Distributed under the GNU General Public License version 3 by the Free Software Foundation"
echo "microbiology.se/software/itsx/"
echo ""
echo "V-Xtractor - Hartmann M., et al., 2010. V-Xtractor: An open-source, high-throughput software tool to identify and extract hypervariable regions of small subunit (16 S/18 S) ribosomal RNA gene sequences. Journal of Microbiological Methods 83, 250-253."
echo "Copyright (C) Hartmann et al. 2010"
echo "Distributed under the GNU General Public License version 3 by the Free Software Foundation"
echo "www.microbiome.ch/Tools.html"
echo ""
echo "Metaxa2 - Bengtsson-Palme J., et al., 2015. Metaxa2: improved identification and taxonomic classification of small and large subunit rRNA in metagenomic data. Molecular Ecology Resources 15, 1403-1414."
echo "Copyright (C) 2011-2016 Johan Bengtsson-Palme et al."
echo "Distributed under the GNU General Public License version 3 by the Free Software Foundation"
echo "microbiology.se/software/metaxa2/"
echo ""
echo "mothur - Schloss, P.D., et al., 2009. Introducing mothur: Open-Source, Platform-Independent, Community-Supported Software for Describing and Comparing Microbial Communities. Applied and Environmental Microbiology 75, 7537-7541."
echo "Distributed under the GNU General Public License version 2 by the Free Software Foundation"
echo "www.mothur.org"
echo "____________________________________________________"

#Set working directory
USER_HOME=$(eval echo ~${SUDO_USER})

WorkingDirectory=$(awk 'BEGIN{FS=OFS="/"} NF{NF--};1' < ${USER_HOME}/.var_babitas/to_GeneX_location.txt)
		if [ "$?" = "0" ]; then
 		echo ""
		else
		touch ${USER_HOME}/.var_babitas/GeneX_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi
cd $WorkingDirectory
		if [ "$?" = "0" ]; then
 		echo ""
		else
		touch ${USER_HOME}/.var_babitas/GeneX_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi


#Set INPUT file
input=$(cat ${USER_HOME}/.var_babitas/to_GeneX_location.txt)



# INPUT unique or precluster
if grep -q 'ITS' ${USER_HOME}/.var_babitas/workflow.txt || grep -q 'SSU' ${USER_HOME}/.var_babitas/workflow.txt || grep -q 'LSU' ${USER_HOME}/.var_babitas/workflow.txt; then

	if [ -e ${USER_HOME}/.var_babitas/precluster.txt ]; then
	echo "### Preclustering sequences prior to extraction ###"

	precluster_id=$(cat ${USER_HOME}/.var_babitas/precluster.txt)

	echo "vsearch --cluster_fast $input --centroids preclustering_centroids.fasta --uc Pre-Clusters.uc --id $precluster_id --xsize --fasta_width 0"

	vsearch --cluster_fast $input --centroids preclustering_centroids.fasta --uc Pre-Clusters.uc --id $precluster_id --xsize --fasta_width 0
			if [ "$?" = "0" ]; then
	 		echo ""
			else
			touch ${USER_HOME}/.var_babitas/GeneX_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	#Convert uc file to cluster format and make names file based on cluster format for deunique command
	echo "# Converting uc file to cluster format and making names file based on cluster format for deunique.seqs command after extraction in finished (to maintain the seq abundance info)"

	python ${USER_HOME}/.babitassh/uc_converter_inout.py Pre-Clusters.uc Pre-Clusters.cluster
			if [ "$?" = "0" ]; then
	 		echo ""
			else
			touch ${USER_HOME}/.var_babitas/GeneX_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	
	tr "\t" ","  < Pre-Clusters.cluster |\
	tr "\r" " " |\
	sed -e 's/ //g' |\
	tr "\n" "\t" |\
	sed -e 's/,\t/\n/g' > second_column.temp
			if [ "$?" = "0" ]; then
	 		echo ""
			else
			touch ${USER_HOME}/.var_babitas/GeneX_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi


	sed 's/,.*//' < second_column.temp > first_column.temp
			if [ "$?" = "0" ]; then
	 		echo ""
			else
			touch ${USER_HOME}/.var_babitas/GeneX_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	pr -tm -J first_column.temp second_column.temp |awk '{print $1"\t"$2}' > precluster.names
			if [ "$?" = "0" ]; then
	 		echo ""
			else
			touch ${USER_HOME}/.var_babitas/GeneX_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	rm first_column.temp && rm second_column.temp


	input_unique=$"preclustering_centroids.fasta"
	names=$"precluster.names"


		else

		#Make unique.seqs
		echo ""
		echo "### Make unique seqs prior to extraction ###"
		mothur "#unique.seqs(fasta=$input)"
		echo ""


		#Set names file variable for deuniqe.seqs
		awk 'BEGIN {FS="."; OFS="."} NF{NF-=1};1' < ${USER_HOME}/.var_babitas/to_GeneX_location.txt | awk '{print $0".names "}' > ${USER_HOME}/.var_babitas/names_for_deunique.txt

		names=$(cat ${USER_HOME}/.var_babitas/names_for_deunique.txt)


		#Set unique input variable
		input_unique=$(echo $input | awk 'BEGIN{FS=OFS="."} {$NF="unique.fasta"}1')



	fi
fi



##################################################
##################################################
################# ITS extractor ##################
##################################################
##################################################
if grep -q 'ITS' ${USER_HOME}/.var_babitas/workflow.txt; then
echo ""
echo "### ITSx 1.0.11 ###"
echo "# Extracting ITS #"


#Set region variable
	if grep -q 'SSU' ${USER_HOME}/.var_babitas/ITSx_region.txt; then
	region=$"SSU"

		else if grep -q 'ITS1' ${USER_HOME}/.var_babitas/ITSx_region.txt; then
		region=$"ITS1"

			else if grep -q '5.8S' ${USER_HOME}/.var_babitas/ITSx_region.txt; then
			region=$"5.8S"

				else if grep -q 'ITS2' ${USER_HOME}/.var_babitas/ITSx_region.txt; then
				region=$"ITS2"

					else if grep -q 'LSU' ${USER_HOME}/.var_babitas/ITSx_region.txt; then
					region=$"LSU"

						else if grep -q 'All' ${USER_HOME}/.var_babitas/ITSx_region.txt; then
						region=$"all"

							else if grep -q 'Custom selection' ${USER_HOME}/.var_babitas/ITSx_region.txt; then						
							region=$(cat ${USER_HOME}/.var_babitas/ITSx_custom_regions/Selected_regions.txt)
						
							fi
						fi
					fi
				fi
			fi
		fi
	fi


#Set organism group variable
	if [ -e ${USER_HOME}/.var_babitas/ITSx_Fungi.txt ]; then
	groups=$"F"

		else if [ -e ${USER_HOME}/.var_babitas/ITSx_All_groups.txt ]; then
		groups=$"all"

			else if [ -e ${USER_HOME}/.var_babitas/ITSx_Custom.txt ]; then
			groups=$(cat ${USER_HOME}/.var_babitas/ITSx_selected_orgs2/Selected_organism_groups.list)
			fi
		fi
	fi

#Set cpu variable
cpus=$(cat ${USER_HOME}/.var_babitas/ITSx_cpus.txt)

echo ""
echo "region(s) = "$region
echo "Organism group(s) = $groups"
echo "CPUs = $cpus"
echo ""
echo "Submitting" $input_unique "to ITSx"



		### Running ITSx 1.0.11 ###### Running ITSx 1.0.11 ###### Running ITSx 1.0.11 ###
		### Running ITSx 1.0.11 ###### Running ITSx 1.0.11 ###### Running ITSx 1.0.11 ###

echo "..."
echo " "

echo "ITSx -i $input_unique --save_regions $region -t $groups --cpu $cpus -o ITSx_out --complement F --graphical F --preserve T"
echo ""

ITSx -i $input_unique --complement F --graphical F --save_regions $region -t $groups --cpu $cpus --preserve T -o ITSx_out

		if [ "$?" = "0" ]; then
		echo ""
 		
		else
		touch ${USER_HOME}/.var_babitas/GeneX_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi


#Deunique sequences (sequences were uniqued prior to GeneX)
	echo ""
	echo "# Deunique sequences (sequences were uniqued prior to ITSx)"

	if [ -s $WorkingDirectory/ITSx_out.ITS1.fasta ]; then
		mothur "#deunique.seqs(fasta=ITSx_out.ITS1.fasta, name=$names)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""
			fi
	fi


	if [ -s $WorkingDirectory/ITSx_out.SSU.fasta ]; then
		mothur "#deunique.seqs(fasta=ITSx_out.SSU.fasta, name=$names)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""
			fi
	fi


	if [ -s $WorkingDirectory/ITSx_out.5_8S.fasta ]; then
		mothur "#deunique.seqs(fasta=ITSx_out.5_8S.fasta, name=$names)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""
			fi
	fi


	if [ -s $WorkingDirectory/ITSx_out.ITS2.fasta ]; then
		mothur "#deunique.seqs(fasta=ITSx_out.ITS2.fasta, name=$names)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""
			fi
	fi


	if [ -s $WorkingDirectory/ITSx_out.LSU.fasta ]; then
		mothur "#deunique.seqs(fasta=ITSx_out.LSU.fasta, name=$names)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""
			fi
	fi


	if [ -s $WorkingDirectory/ITSx_out.full.fasta ]; then
		mothur "#deunique.seqs(fasta=ITSx_out.full.fasta, name=$names)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""
			fi
	fi



	#Merge ITS1 + 5.8S + ITS2 seqs if those exist (because original ITSx output full ITS gives much less seqs)
	if [ -e $WorkingDirectory/ITSx_out.ITS2.redundant.fasta ] && [ -e $WorkingDirectory/ITSx_out.ITS1.redundant.fasta ] && [ -e $WorkingDirectory/ITSx_out.5_8S.redundant.fasta ]; then

	echo ""
	echo "# Merging ITSx outputs ITS1 + 5.8S + ITS2 to obtain FULL ITS region"
	echo " # Compare with original ITSx output (ITSx_out.full.redundant.fasta)"
	echo "  # if SSU or LSU has only few base pairs, ITSx does not detect those regions and does not include those in the full ITS output"
	echo ""

	tr "\n" "\t" < ITSx_out.ITS1.redundant.fasta | sed -e 's/>/\n>/g' | sed '/^\n*$/d' > ITS1.fasta 
	tr "\n" "\t" < ITSx_out.5_8S.redundant.fasta | sed -e 's/>/\n>/g' | sed '/^\n*$/d' > 5.8.fasta 
	tr "\n" "\t" < ITSx_out.ITS2.redundant.fasta | sed -e 's/>/\n>/g' | sed '/^\n*$/d' > ITS2.fasta 

	gawk 'BEGIN {FS=OFS="\t"} FNR==NR{a[$1]=$2;next} ($1 in a) {print $1,a[$1],$2}' ITS1.fasta 5.8.fasta > ITS1_5.8S.fasta

	gawk 'BEGIN {FS=OFS="\t"} FNR==NR{a[$1]=$2$3;next} ($1 in a) {print $1,a[$1],$2}' ITS1_5.8S.fasta ITS2.fasta > ITS1_5.8S_ITS2.fasta

	sed -e 's/\t/\n/' < ITS1_5.8S_ITS2.fasta | sed -e 's/\t//' > Full_ITS.fasta

	rm ITS1.fasta && rm 5.8.fasta && rm ITS2.fasta && rm ITS1_5.8S.fasta && rm ITS1_5.8S_ITS2.fasta

	echo "# done -> output = Full_ITS.fasta"
	echo ""

	fi




	if [ -e $WorkingDirectory/ITSx_out.ITS2.redundant.fasta ] || [ -e $WorkingDirectory/ITSx_out.ITS1.redundant.fasta ] || [ -e $WorkingDirectory/ITSx_out.SSU.redundant.fasta ] || [ -e $WorkingDirectory/ITSx_out.LSU.redundant.fasta ] || [ -e $WorkingDirectory/ITSx_out.full.redundant.fasta ] || [ -e $WorkingDirectory/ITSx_out.5_8S.redundant.fasta ]; then

		touch ${USER_HOME}/.var_babitas/GeneX_finished.txt
	
		echo ""
		echo "##########################"
		echo "DONE"
		echo "#############################"
		echo "ITSx finished"
		echo "################################"
		echo "Output = ITSx_out.*.redundant.fasta"
		echo "###################################"
		echo "You may close this window now!"
		
		else
		echo "ERROR occurred, ITSx_out.*.redundant.fasta NOT FOUND" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
	fi


fi





########################################
########################################
################# SSU ##################
########################################
############## V-Xtractor ############## 
########################################
if grep -q 'SSU' ${USER_HOME}/.var_babitas/workflow.txt && grep -q 'V-Xtractor' ${USER_HOME}/.var_babitas/program.txt; then

echo ""
echo "### V-Xtractor 2.1 ###"
echo "# Extracting SSU #"

echo ""

	#Set HMM variable (-i)
	if grep -q 'Long' ${USER_HOME}/.var_babitas/HMM.txt; then
	hmm=$"-i long"

		else if grep -q 'Short' ${USER_HOME}/.var_babitas/HMM.txt; then
		hmm=$"-i short"

		fi
	fi



	#Set profiles (organism) variable (-h)
	if grep -q 'Fungi and Bacteria' ${USER_HOME}/.var_babitas/profiles.txt; then
		profiles1=$"-h /dependencies/vxtractor/HMMs/SSU/fungi/"
		profiles2=$"-h /dependencies/vxtractor/HMMs/SSU/bacteria/"

		else if grep -q 'Fungi and Archaea' ${USER_HOME}/.var_babitas/profiles.txt; then
		profiles1=$"-h /dependencies/vxtractor/HMMs/SSU/fungi/"
		profiles2=$"-h /dependencies/vxtractor/HMMs/SSU/archaea/"

			else if grep -q 'Archaea and Bacteria' ${USER_HOME}/.var_babitas/profiles.txt; then
			profiles1=$"-h /dependencies/vxtractor/HMMs/SSU/archaea/"
			profiles2=$"-h /dependencies/vxtractor/HMMs/SSU/bacteria/"

				else if grep -q 'Bacteria' ${USER_HOME}/.var_babitas/profiles.txt; then
				profiles1=$"-h /dependencies/vxtractor/HMMs/SSU/bacteria/"

			else if grep -q 'Fungi' ${USER_HOME}/.var_babitas/profiles.txt; then
			profiles1=$"-h /dependencies/vxtractor/HMMs/SSU/fungi/"

		else if grep -q 'Archaea' ${USER_HOME}/.var_babitas/profiles.txt; then
		profiles1=$"-h /dependencies/vxtractor/HMMs/SSU/archaea/"

	fi
		fi
			fi
				fi
			fi
		fi


	#Set target region variable (-r)
	
	if grep -q 'V1' ${USER_HOME}/.var_babitas/target_reg.txt; then
	target=$"-r V1"
	targetGrep=$"_V1_"
	else if grep -q 'V2' ${USER_HOME}/.var_babitas/target_reg.txt; then
	target=$"-r V2"
	targetGrep=$"_V2_"
	else if grep -q 'V3' ${USER_HOME}/.var_babitas/target_reg.txt; then
	target=$"-r V3"
	targetGrep=$"_V3_"
	else if grep -q 'V4' ${USER_HOME}/.var_babitas/target_reg.txt; then
	target=$"-r V4"
	targetGrep=$"_V4_"
	else if grep -q 'V5' ${USER_HOME}/.var_babitas/target_reg.txt; then
	target=$"-r V5"
	targetGrep=$"_V5_"
	else if grep -q 'V6' ${USER_HOME}/.var_babitas/target_reg.txt; then
	target=$"-r V6"
	targetGrep=$"_V6_"
	else if grep -q 'V7' ${USER_HOME}/.var_babitas/target_reg.txt; then
	target=$"-r V7"
	targetGrep=$"_V7_"
	else if grep -q 'V8' ${USER_HOME}/.var_babitas/target_reg.txt; then
	target=$"-r V8"
	targetGrep=$"_V8_"
	else if grep -q 'V9' ${USER_HOME}/.var_babitas/target_reg.txt; then
	target=$"-r V9"
	targetGrep=$"_V9_"


		else if grep -q 'Multiple selections' ${USER_HOME}/.var_babitas/target_reg.txt; then
			if [ -e ${USER_HOME}/.var_babitas/r1.txt ]; then
			r1=$(echo "-r " && cat ${USER_HOME}/.var_babitas/r1.txt)
			fi
			if [ -e ${USER_HOME}/.var_babitas/r2.txt ]; then
			r2=$(echo "-r " && cat ${USER_HOME}/.var_babitas/r2.txt)
			fi
			if [ -e ${USER_HOME}/.var_babitas/r3.txt ]; then
			r3=$(echo "-r " && cat ${USER_HOME}/.var_babitas/r3.txt)
			fi
			if [ -e ${USER_HOME}/.var_babitas/r4.txt ]; then
			r4=$(echo "-r " && cat ${USER_HOME}/.var_babitas/r4.txt)
			fi
			if [ -e ${USER_HOME}/.var_babitas/r5.txt ]; then
			r5=$(echo "-r " && cat ${USER_HOME}/.var_babitas/r5.txt)
			fi
			if [ -e ${USER_HOME}/.var_babitas/r6.txt ]; then
			r6=$(echo "-r " && cat ${USER_HOME}/.var_babitas/r6.txt)
			fi
			if [ -e ${USER_HOME}/.var_babitas/r7.txt ]; then
			r7=$(echo "-r " && cat ${USER_HOME}/.var_babitas/r7.txt)
			fi
			if [ -e ${USER_HOME}/.var_babitas/r8.txt ]; then
			r8=$(echo "-r " && cat ${USER_HOME}/.var_babitas/r8.txt)
			fi
			if [ -e ${USER_HOME}/.var_babitas/r9.txt ]; then
			r9=$(echo "-r " && cat ${USER_HOME}/.var_babitas/r9.txt)
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



# Extracting MULTIPLE REGIONs
# Extracting MULTIPLE REGIONs
# Extracting MULTIPLE REGIONs
	if grep -q 'Multiple selections' ${USER_HOME}/.var_babitas/target_reg.txt; then

	echo "# Extracting" $r1 $r2 $r3 $r4 $r5 $r6 $r7 $r8 $r9
	echo ""
	echo "vxtractor.pl $profiles1 $profiles2 $hmm $r1 $r2 $r3 $r4 $r5 $r6 $r7 $r8 $r9 -o VXtractor.output.fasta -c VXtractor.output.csv $input_unique"
	vxtractor.pl $profiles1 $profiles2 $hmm $r1 $r2 $r3 $r4 $r5 $r6 $r7 $r8 $r9 -o VXtractor.output.fasta -c VXtractor.output.csv $input_unique
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/GeneX_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi


		if [ -e ${USER_HOME}/.var_babitas/r1.txt ]; then
		r1grep=$(cat ${USER_HOME}/.var_babitas/r1.txt | sed -e 's/[.]//g' | sed -e 's/-/_/g' | sed -e 's/^/_/' | sed 's/$/_/')
		
		echo $r1grep | tr -d -c '_' | awk '{ print length; }' > $r1grep.temp

					if grep -q '2' $r1grep.temp; then
			grep -A1 $r1grep VXtractor.output.fasta | grep -v -- -- | grep -v 'V'[[:digit:]]$r1grep | grep -v $r1grep'V'[[:digit:]] | grep -A1 '>' | sed -e 's/^--//g' | sed '/^$/d' > $r1grep.fasta
				if [ -s $r1grep.fasta ]; then
				sed -e "s/$r1grep.*//g" < $r1grep.fasta > $r1grep.unique.fasta
				fi
			rm $r1grep.temp
			echo "Extracting only" $r1 "from VXtractor.output.fasta; output="$r1grep.fasta

			else if grep -q '3' $r1grep.temp; then
			grep -A1 $r1grep VXtractor.output.fasta | grep -v -- -- > $r1grep.fasta
				if [ -s $r1grep.fasta ]; then
				sed -e "s/$r1grep.*//g" < $r1grep.fasta > $r1grep.unique.fasta
				fi
			rm $r1grep.temp
			echo "Extracting only" $r1 "from VXtractor.output.fasta; output="$r1grep.fasta

			fi
			fi
		
		fi


		if [ -e ${USER_HOME}/.var_babitas/r2.txt ]; then
		r2grep=$(cat ${USER_HOME}/.var_babitas/r2.txt | sed -e 's/[.]//g' | sed -e 's/-/_/g' | sed -e 's/^/_/' | sed 's/$/_/')
				
		echo $r2grep | tr -d -c '_' | awk '{ print length; }' > $r2grep.temp

			if grep -q '2' $r2grep.temp; then
			grep -A1 $r2grep VXtractor.output.fasta | grep -v -- -- | grep -v 'V'[[:digit:]]$r2grep | grep -v $r2grep'V'[[:digit:]] | grep -A1 '>' | sed -e 's/^--//g' | sed '/^$/d' > $r2grep.fasta
				if [ -s $r2grep.fasta ]; then
				sed -e "s/$r2grep.*//g" < $r2grep.fasta > $r2grep.unique.fasta
				fi
			rm $r2grep.temp
			echo "Extracting only" $r2 "from VXtractor.output.fasta; output="$r2grep.fasta

			else if grep -q '3' $r2grep.temp; then
			grep -A1 $r2grep VXtractor.output.fasta | grep -v -- -- > $r2grep.fasta
				if [ -s $r2grep.fasta ]; then
				sed -e "s/$r2grep.*//g" < $r2grep.fasta > $r2grep.unique.fasta
				fi
			rm $r2grep.temp
			echo "Extracting only" $r2 "from VXtractor.output.fasta; output="$r2grep.fasta

			fi
			fi
		fi




		if [ -e ${USER_HOME}/.var_babitas/r3.txt ]; then
		r3grep=$(cat ${USER_HOME}/.var_babitas/r3.txt | sed -e 's/[.]//g' | sed -e 's/-/_/g' | sed -e 's/^/_/' | sed 's/$/_/')
		
		echo $r3grep | tr -d -c '_' | awk '{ print length; }' > $r3grep.temp

			if grep -q '2' $r3grep.temp; then
			grep -A1 $r3grep VXtractor.output.fasta | grep -v -- -- | grep -v 'V'[[:digit:]]$r3grep | grep -v $r3grep'V'[[:digit:]] | grep -A1 '>' | sed -e 's/^--//g' | sed '/^$/d' > $r3grep.fasta
				if [ -s $r3grep.fasta ]; then
				sed -e "s/$r3grep.*//g" < $r3grep.fasta > $r3grep.unique.fasta
				fi
			rm $r3grep.temp
			echo "Extracting only" $r3 "from VXtractor.output.fasta; output="$r3grep.fasta

			else if grep -q '3' $r3grep.temp; then
			grep -A1 $r3grep VXtractor.output.fasta | grep -v -- -- > $r3grep.fasta
				if [ -s $r3grep.fasta ]; then
				sed -e "s/$r3grep.*//g" < $r3grep.fasta > $r3grep.unique.fasta
				fi
			rm $r3grep.temp
			echo "Extracting only" $r3 "from VXtractor.output.fasta; output="$r3grep.fasta

			fi
			fi
		fi




		if [ -e ${USER_HOME}/.var_babitas/r4.txt ]; then
		r4grep=$(cat ${USER_HOME}/.var_babitas/r4.txt | sed -e 's/[.]//g' | sed -e 's/-/_/g' | sed -e 's/^/_/' | sed 's/$/_/')
		
		echo $r4grep | tr -d -c '_' | awk '{ print length; }' > $r4grep.temp

			if grep -q '2' $r4grep.temp; then
			grep -A1 $r4grep VXtractor.output.fasta | grep -v -- -- | grep -v 'V'[[:digit:]]$r4grep | grep -v $r4grep'V'[[:digit:]] | grep -A1 '>' | sed -e 's/^--//g' | sed '/^$/d' > $r4grep.fasta
				if [ -s $r4grep.fasta ]; then
				sed -e "s/$r4grep.*//g" < $r4grep.fasta > $r4grep.unique.fasta
				fi
			rm $r4grep.temp
			echo "Extracting only" $r4 "from VXtractor.output.fasta; output="$r4grep.fasta

			else if grep -q '3' $r4grep.temp; then
			grep -A1 $r4grep VXtractor.output.fasta | grep -v -- -- > $r4grep.fasta
				if [ -s $r4grep.fasta ]; then
				sed -e "s/$r4grep.*//g" < $r4grep.fasta > $r4grep.unique.fasta
				fi
			rm $r4grep.temp
			echo "Extracting only" $r4 "from VXtractor.output.fasta; output="$r4grep.fasta

			fi
			fi
		fi




		if [ -e ${USER_HOME}/.var_babitas/r5.txt ]; then
		r5grep=$(cat ${USER_HOME}/.var_babitas/r5.txt | sed -e 's/[.]//g' | sed -e 's/-/_/g' | sed -e 's/^/_/' | sed 's/$/_/')
		
		echo $r5grep | tr -d -c '_' | awk '{ print length; }' > $r5grep.temp

			if grep -q '2' $r5grep.temp; then
			grep -A1 $r5grep VXtractor.output.fasta | grep -v -- -- | grep -v 'V'[[:digit:]]$r5grep | grep -v $r5grep'V'[[:digit:]] | grep -A1 '>' | sed -e 's/^--//g' | sed '/^$/d' > $r5grep.fasta
				if [ -s $r5grep.fasta ]; then
				sed -e "s/$r5grep.*//g" < $r5grep.fasta > $r5grep.unique.fasta
				fi
			rm $r5grep.temp
			echo "Extracting only" $r5 "from VXtractor.output.fasta; output="$r5grep.fasta

			else if grep -q '3' $r5grep.temp; then
			grep -A1 $r5grep VXtractor.output.fasta | grep -v -- -- > $r5grep.fasta
				if [ -s $r5grep.fasta ]; then
				sed -e "s/$r5grep.*//g" < $r5grep.fasta > $r5grep.unique.fasta
				fi
			rm $r5grep.temp
			echo "Extracting only" $r5 "from VXtractor.output.fasta; output="$r5grep.fasta

			fi
			fi
		fi




		if [ -e ${USER_HOME}/.var_babitas/r6.txt ]; then
		r6grep=$(cat ${USER_HOME}/.var_babitas/r6.txt | sed -e 's/[.]//g' | sed -e 's/-/_/g' | sed -e 's/^/_/' | sed 's/$/_/')
		
		echo $r6grep | tr -d -c '_' | awk '{ print length; }' > $r6grep.temp

			if grep -q '2' $r6grep.temp; then
			grep -A1 $r6grep VXtractor.output.fasta | grep -v -- -- | grep -v 'V'[[:digit:]]$r6grep | grep -v $r6grep'V'[[:digit:]] | grep -A1 '>' | sed -e 's/^--//g' | sed '/^$/d' > $r6grep.fasta
				if [ -s $r6grep.fasta ]; then
				sed -e "s/$r6grep.*//g" < $r6grep.fasta > $r6grep.unique.fasta
				fi
			rm $r6grep.temp
			echo "Extracting only" $r6 "from VXtractor.output.fasta; output="$r6grep.fasta

			else if grep -q '3' $r6grep.temp; then
			grep -A1 $r6grep VXtractor.output.fasta | grep -v -- -- > $r6grep.fasta
				if [ -s $r6grep.fasta ]; then
				sed -e "s/$r6grep.*//g" < $r6grep.fasta > $r6grep.unique.fasta
				fi
			rm $r6grep.temp
			echo "Extracting only" $r6 "from VXtractor.output.fasta; output="$r6grep.fasta

			fi
			fi
		fi




		if [ -e ${USER_HOME}/.var_babitas/r7.txt ]; then
		r7grep=$(cat ${USER_HOME}/.var_babitas/r7.txt | sed -e 's/[.]//g' | sed -e 's/-/_/g' | sed -e 's/^/_/' | sed 's/$/_/')
		
		echo $r7grep | tr -d -c '_' | awk '{ print length; }' > $r7grep.temp

			if grep -q '2' $r7grep.temp; then
			grep -A1 $r7grep VXtractor.output.fasta | grep -v -- -- | grep -v 'V'[[:digit:]]$r7grep | grep -v $r7grep'V'[[:digit:]] | grep -A1 '>' | sed -e 's/^--//g' | sed '/^$/d' > $r7grep.fasta
				if [ -s $r7grep.fasta ]; then
				sed -e "s/$r7grep.*//g" < $r7grep.fasta > $r7grep.unique.fasta
				fi
			rm $r7grep.temp
			echo "Extracting only" $r7 "from VXtractor.output.fasta; output="$r7grep.fasta

			else if grep -q '3' $r7grep.temp; then
			grep -A1 $r7grep VXtractor.output.fasta | grep -v -- -- > $r7grep.fasta
				if [ -s $r7grep.fasta ]; then
				sed -e "s/$r7grep.*//g" < $r7grep.fasta > $r7grep.unique.fasta
				fi
			rm $r7grep.temp
			echo "Extracting only" $r7 "from VXtractor.output.fasta; output="$r7grep.fasta

			fi
			fi
		fi




		if [ -e ${USER_HOME}/.var_babitas/r8.txt ]; then
		r8grep=$(cat ${USER_HOME}/.var_babitas/r8.txt | sed -e 's/[.]//g' | sed -e 's/-/_/g' | sed -e 's/^/_/' | sed 's/$/_/')
		
		echo $r8grep | tr -d -c '_' | awk '{ print length; }' > $r8grep.temp

			if grep -q '2' $r8grep.temp; then
			grep -A1 $r8grep VXtractor.output.fasta | grep -v -- -- | grep -v 'V'[[:digit:]]$r8grep | grep -v $r8grep'V'[[:digit:]] | grep -A1 '>' | sed -e 's/^--//g' | sed '/^$/d' > $r8grep.fasta
				if [ -s $r8grep.fasta ]; then
				sed -e "s/$r8grep.*//g" < $r8grep.fasta > $r8grep.unique.fasta
				fi
			rm $r8grep.temp
			echo "Extracting only" $r8 "from VXtractor.output.fasta; output="$r8grep.fasta

			else if grep -q '3' $r8grep.temp; then
			grep -A1 $r8grep VXtractor.output.fasta | grep -v -- -- > $r8grep.fasta
				if [ -s $r8grep.fasta ]; then
				sed -e "s/$r8grep.*//g" < $r8grep.fasta > $r8grep.unique.fasta
				fi
			rm $r8grep.temp
			echo "Extracting only" $r8 "from VXtractor.output.fasta; output="$r8grep.fasta

			fi
			fi
		fi




		if [ -e ${USER_HOME}/.var_babitas/r9.txt ]; then
		r9grep=$(cat ${USER_HOME}/.var_babitas/r9.txt | sed -e 's/[.]//g' | sed -e 's/-/_/g' | sed -e 's/^/_/' | sed 's/$/_/')
		
		echo $r9grep | tr -d -c '_' | awk '{ print length; }' > $r9grep.temp

			if grep -q '2' $r9grep.temp; then
			grep -A1 $r9grep VXtractor.output.fasta | grep -v -- -- | grep -v 'V'[[:digit:]]$r9grep | grep -v $r9grep'V'[[:digit:]] | grep -A1 '>' | sed -e 's/^--//g' | sed '/^$/d' > $r9grep.fasta
				if [ -s $r9grep.fasta ]; then
				sed -e "s/$r9grep.*//g" < $r9grep.fasta > $r9grep.unique.fasta
				fi
			rm $r9grep.temp
			echo "Extracting only" $r9 "from VXtractor.output.fasta; output="$r9grep.fasta

			else if grep -q '3' $r9grep.temp; then
			grep -A1 $r9grep VXtractor.output.fasta | grep -v -- -- > $r9grep.fasta
				if [ -s $r9grep.fasta ]; then
				sed -e "s/$r9grep.*//g" < $r9grep.fasta > $r9grep.unique.fasta
				fi
			rm $r9grep.temp
			echo "Extracting only" $r9 "from VXtractor.output.fasta; output="$r9grep.fasta

			fi
			fi
		fi
		
		

	
		#Deunique sequences (sequences were uniqued prior to GeneX)

		if [ -s $r1grep.unique.fasta ]; then
			echo ""
			echo "# Deunique sequences ($r1grep.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=$r1grep.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv $r1grep.unique.redundant.fasta $r1grep.redundant.fasta
		
		fi



		if [ -s $r2grep.unique.fasta ]; then
			echo ""
			echo "# Deunique sequences ($r2grep.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=$r2grep.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv $r2grep.unique.redundant.fasta $r2grep.redundant.fasta
		
		fi



		if [ -s $r3grep.unique.fasta ]; then
			echo ""
			echo "# Deunique sequences ($r3grep.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=$r3grep.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv $r3grep.unique.redundant.fasta $r3grep.redundant.fasta
		
		fi



		if [ -s $r4grep.unique.fasta ]; then
			echo ""
			echo "# Deunique sequences ($r4grep.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=$r4grep.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv $r4grep.unique.redundant.fasta $r4grep.redundant.fasta
		
		fi



		if [ -s $r5grep.unique.fasta ]; then
			echo ""
			echo "# Deunique sequences ($r5grep.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=$r5grep.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv $r5grep.unique.redundant.fasta $r5grep.redundant.fasta
		
		fi



		if [ -s $r6grep.unique.fasta ]; then
			echo ""
			echo "# Deunique sequences ($r6grep.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=$r6grep.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv $r6grep.unique.redundant.fasta $r6grep.redundant.fasta
		
		fi



		if [ -s $r7grep.unique.fasta ]; then
			echo ""
			echo "# Deunique sequences ($r7grep.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=$r7grep.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv $r7grep.unique.redundant.fasta $r7grep.redundant.fasta
		
		fi



		if [ -s $r8grep.unique.fasta ]; then
			echo ""
			echo "# Deunique sequences ($r8grep.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=$r8grep.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv $r8grep.unique.redundant.fasta $r8grep.redundant.fasta
		
		fi



		if [ -s $r9grep.unique.fasta ]; then
			echo ""
			echo "# Deunique sequences ($r9grep.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=$r9grep.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv $r9grep.unique.redundant.fasta $r9grep.redundant.fasta
		
		fi



#V-Extractor FINISEHD_1!!!
if [ -s VXtractor.output.fasta ];then

		touch ${USER_HOME}/.var_babitas/GeneX_finished.txt
	
		echo ""
		echo "##########################"
		echo "DONE"
		echo "#############################"
		echo "V-Xtractor finished"
		echo "###################################"
		echo "You may close this window now!"
		
		else
		echo "ERROR occurred, VXtractor.output.fasta in BLANK" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
fi





# Extracting SINGLE REGION
# Extracting SINGLE REGION
# Extracting SINGLE REGION

	else
	echo "# Extracting" $target
	echo ""
	echo "vxtractor.pl $profiles1 $profiles2 $hmm $target -o VXtractor.output.fasta -c VXtractor.output.csv $input_unique"
	vxtractor.pl $profiles1 $profiles2 $hmm $target -o VXtractor.output.fasta -c VXtractor.output.csv $input_unique
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/GeneX_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi



	
		if grep -q 'All' ${USER_HOME}/.var_babitas/target_reg.txt; then
			grep -A1 _V1_ VXtractor.output.fasta | grep -v -- -- > _V1_.fasta
			grep -A1 _V2_ VXtractor.output.fasta | grep -v -- -- > _V2_.fasta
			grep -A1 _V3_ VXtractor.output.fasta | grep -v -- -- > _V3_.fasta
			grep -A1 _V4_ VXtractor.output.fasta | grep -v -- -- > _V4_.fasta
			grep -A1 _V5_ VXtractor.output.fasta | grep -v -- -- > _V5_.fasta
			grep -A1 _V6_ VXtractor.output.fasta | grep -v -- -- > _V6_.fasta
			grep -A1 _V7_ VXtractor.output.fasta | grep -v -- -- > _V7_.fasta
			grep -A1 _V8_ VXtractor.output.fasta | grep -v -- -- > _V8_.fasta
			grep -A1 _V9_ VXtractor.output.fasta | grep -v -- -- > _V9_.fasta

			if [ -s _V1_.fasta ]; then
			sed -e "s/_V1_.*//g" < _V1_.fasta > _V1_.unique.fasta
			echo ""
			echo "# Deunique sequences (_V1_.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=_V1_.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv _V1_.unique.redundant.fasta _V1_.redundant.fasta
			
			else 
			rm _V1_.fasta
			fi




			if [ -s _V2_.fasta ]; then
			sed -e "s/_V2_.*//g" < _V2_.fasta > _V2_.unique.fasta
			echo ""
			echo "# Deunique sequences (_V2_.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=_V2_.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv _V2_.unique.redundant.fasta _V2_.redundant.fasta
			
			else 
			rm _V2_.fasta
			fi



			if [ -s _V3_.fasta ]; then
			sed -e "s/_V3_.*//g" < _V3_.fasta > _V3_.unique.fasta
			echo ""
			echo "# Deunique sequences (_V3_.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=_V3_.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv _V3_.unique.redundant.fasta _V3_.redundant.fasta
			
			else 
			rm _V3_.fasta
			fi




			if [ -s _V4_.fasta ]; then
			sed -e "s/_V4_.*//g" < _V4_.fasta > _V4_.unique.fasta
			echo ""
			echo "# Deunique sequences (_V4_.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=_V4_.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv _V4_.unique.redundant.fasta _V4_.redundant.fasta
			
			else 
			rm _V4_.fasta
			fi




			if [ -s _V5_.fasta ]; then
			sed -e "s/_V5_.*//g" < _V5_.fasta > _V5_.unique.fasta
			echo ""
			echo "# Deunique sequences (_V5_.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=_V5_.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv _V5_.unique.redundant.fasta _V5_.redundant.fasta
			
			else 
			rm _V5_.fasta
			fi




			if [ -s _V6_.fasta ]; then
			sed -e "s/_V6_.*//g" < _V6_.fasta > _V6_.unique.fasta
			echo ""
			echo "# Deunique sequences (_V6_.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=_V6_.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv _V6_.unique.redundant.fasta _V6_.redundant.fasta
			
			else 
			rm _V6_.fasta
			fi




			if [ -s _V7_.fasta ]; then
			sed -e "s/_V7_.*//g" < _V7_.fasta > _V7_.unique.fasta
			echo ""
			echo "# Deunique sequences (_V7_.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=_V7_.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv _V7_.unique.redundant.fasta _V7_.redundant.fasta
			
			else 
			rm _V7_.fasta
			fi




			if [ -s _V8_.fasta ]; then
			sed -e "s/_V8_.*//g" < _V8_.fasta > _V8_.unique.fasta
			echo ""
			echo "# Deunique sequences (_V8_.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=_V8_.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv _V8_.unique.redundant.fasta _V8_.redundant.fasta
			
			else 
			rm _V8_.fasta
			fi




			if [ -s _V9_.fasta ]; then
			sed -e "s/_V9_.*//g" < _V9_.fasta > _V9_.unique.fasta
			echo ""
			echo "# Deunique sequences (_V9_.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=_V9_.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv _V9_.unique.redundant.fasta _V9_.redundant.fasta
			
			else 
			rm _V9_.fasta
			fi


				#V-Extractor FINISEHD_2!!!
				if [ -s $WorkingDirectory/VXtractor.output.fasta ];then

				touch ${USER_HOME}/.var_babitas/GeneX_finished.txt
	
				echo ""
				echo "##########################"
				echo "DONE"
				echo "#############################"
				echo "V-Xtractor finished"
				echo "###################################"
				echo "You may close this window now!"
		
				else
				echo "ERROR occurred, VXtractor.output.fasta is BLANK" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				fi



		####ELSE####
			else
			grep -A1 $targetGrep VXtractor.output.fasta | grep -v -- -- | grep -v 'V'[[:digit:]]$targetGrep | grep -v $targetGrep'V'[[:digit:]] | grep -A1 '>' | sed -e 's/^--//g' | sed '/^$/d' > $targetGrep.fasta

			sed -e "s/$targetGrep.*//g" < $targetGrep.fasta > $targetGrep.unique.fasta

			echo ""
			echo "# Deunique sequences ($targetGrep.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=$targetGrep.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv $targetGrep.unique.redundant.fasta $targetGrep.redundant.fasta


			#V-Extractor FINISEHD_2!!!
			if [ -e $targetGrep.redundant.fasta ];then

			touch ${USER_HOME}/.var_babitas/GeneX_finished.txt
	
			echo ""
			echo "##########################"
			echo "DONE"
			echo "#############################"
			echo "V-Xtractor finished"
			echo "###################################"
			echo "You may close this window now!"
		
			else
			echo "ERROR occurred, "$targetGrep".redundant.fasta NOT FOUND" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			fi

		fi





	fi

##########################################################################
##########################################################################
##########################################################################
############## Metaxa2 ############################ Metaxa2 ############## 
##########################################################################
##########################################################################
##########################################################################
else if grep -q 'SSU' ${USER_HOME}/.var_babitas/workflow.txt && grep -q 'Metaxa' ${USER_HOME}/.var_babitas/program.txt; then


echo ""
echo "### Metaxa 2.1.3 ###"
echo "# Extracting SSU #"
echo ""


#Set profiles (organism) variable (-t)
	if [ -e ${USER_HOME}/.var_babitas/profiles_all.txt ]; then
		t1=$"all"
		echo ""
		echo "Set of profiles = "$t1
		echo ""
	
	else 
		mkdir ${USER_HOME}/.var_babitas/Profiles

		if [ -e ${USER_HOME}/.var_babitas/profiles_euc.txt ]; then
		mv ${USER_HOME}/.var_babitas/profiles_euc.txt ${USER_HOME}/.var_babitas/Profiles/profiles_euc.txt
		fi
		if [ -e ${USER_HOME}/.var_babitas/profiles_chlor.txt ]; then
		mv ${USER_HOME}/.var_babitas/profiles_chlor.txt ${USER_HOME}/.var_babitas/Profiles/profiles_chlor.txt
		fi
		if [ -e ${USER_HOME}/.var_babitas/profiles_bac.txt ]; then
		mv ${USER_HOME}/.var_babitas/profiles_bac.txt ${USER_HOME}/.var_babitas/Profiles/profiles_bac.txt
		fi
		if [ -e ${USER_HOME}/.var_babitas/profiles_arc.txt ]; then
		mv ${USER_HOME}/.var_babitas/profiles_arc.txt ${USER_HOME}/.var_babitas/Profiles/profiles_arc.txt
		fi
		if [ -e ${USER_HOME}/.var_babitas/profiles_mito.txt ]; then
		mv ${USER_HOME}/.var_babitas/profiles_mito.txt ${USER_HOME}/.var_babitas/Profiles/profiles_mito.txt
		fi

		profiles=$(cat ${USER_HOME}/.var_babitas/Profiles/*.txt | tr "\n" "," | sed 's/.$//')	


		echo ""
		echo "Set of profiles = "$t1$profiles
		echo ""
	fi
	
	
	

#Set CPUs variable (--cpu)
	if [ -e ${USER_HOME}/.var_babitas/CPUs.txt ]; then
	cpus=$(cat ${USER_HOME}/.var_babitas/CPUs.txt)
	fi

	#Set mode variable (--mode)
	if grep -q 'Metagenome' ${USER_HOME}/.var_babitas/mode.txt; then
	mode=$"metagenome"
		else if grep -q 'Genome' ${USER_HOME}/.var_babitas/mode.txt; then
		mode=$"genome"
			else if grep -q 'Auto' ${USER_HOME}/.var_babitas/mode.txt; then
			mode=$"auto"
			fi
		fi
	fi


#Set sequence selection variables
	if [ -e ${USER_HOME}/.var_babitas/eval.txt ]; then
	eval=$(cat ${USER_HOME}/.var_babitas/eval.txt)
	fi

	if [ -e ${USER_HOME}/.var_babitas/score.txt ]; then
	score=$(echo "-S " && cat ${USER_HOME}/.var_babitas/score.txt)
	fi

	if [ -e ${USER_HOME}/.var_babitas/priority.txt ]; then
	priority=$(echo "--selection_priority " && cat ${USER_HOME}/.var_babitas/priority.txt)
	fi




#Run Metaxa v2.1.2
#Run Metaxa v2.1.2
#Run Metaxa v2.1.2

	if [ -e ${USER_HOME}/.var_babitas/eval.txt ]; then

	echo "metaxa2 -i $input_unique -o Metaxa.out1 --taxonomy F --complement F -E $eval $priority $score"
	echo "--cpu $cpus -g ssu --mode $mode --graphical F -t $t1$profiles --not_found T --align n --plus T"
	echo ""

	metaxa2 -i $input_unique -o Metaxa.out1 --taxonomy F --complement F -E $eval $priority $score --cpu $cpus -g ssu --mode $mode --graphical F -t $t1$profiles --not_found T --align n --plus T
			if [ "$?" = "0" ]; then
			echo ""
			touch ${USER_HOME}/.var_babitas/GeneX_finished.txt
			else
			touch ${USER_HOME}/.var_babitas/GeneX_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

		else 
		echo "metaxa2 -i $input_unique -o Metaxa.out1 --taxonomy F --complement F $priority"
		echo "$score --cpu $cpus -g ssu --mode $mode --graphical F -t $t1$profiles --not_found T --align n --plus T"

		metaxa2 -i $input_unique -o Metaxa.out1 --taxonomy F --complement F $priority $score --cpu $cpus -g ssu --mode $mode --graphical F -t $t1$profiles --not_found T --align n --plus T
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/GeneX_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	fi




#Delete added extra stuff after space in fasta headers and DEUNIQUE
	if [ -s Metaxa.out1.bacteria.fasta ]; then
	sed -e 's/ .*//g' < Metaxa.out1.bacteria.fasta | sed -e 's/_COMPLETE//g' > Metaxa.out.bacteria.fasta
	rm Metaxa.out1.bacteria.fasta
	
		if [ -s Metaxa.out.bacteria.fasta ];then
		echo ""
		echo "# Deunique sequences (Metaxa.out.bacteria.fasta) (sequences were uniqued prior to Metaxa2)"

		mothur "#deunique.seqs(fasta=Metaxa.out.bacteria.fasta, name=$names)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""	
			fi
		fi
		
	else 
		rm Metaxa.out1.bacteria.fasta

	fi



	if [ -s Metaxa.out1.archaea.fasta ]; then
	sed -e 's/ .*//g' < Metaxa.out1.archaea.fasta | sed -e 's/_COMPLETE//g' > Metaxa.out.archaea.fasta
	rm Metaxa.out1.archaea.fasta

		if [ -s Metaxa.out.archaea.fasta ];then
		echo ""
		echo "# Deunique sequences (Metaxa.out.archaea.fasta) (sequences were uniqued prior to Metaxa2)"

		mothur "#deunique.seqs(fasta=Metaxa.out.archaea.fasta, name=$names)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""	
			fi
		fi
	else 
		rm Metaxa.out1.archaea.fasta

	fi




	if [ -s Metaxa.out1.eukaryota.fasta ]; then
	sed -e 's/ .*//g' < Metaxa.out1.eukaryota.fasta | sed -e 's/_COMPLETE//g' > Metaxa.out.eukaryota.fasta
	rm Metaxa.out1.eukaryota.fasta

		if [ -s Metaxa.out.eukaryota.fasta ];then
		echo ""
		echo "# Deunique sequences (Metaxa.out.eukaryota.fasta) (sequences were uniqued prior to Metaxa2)"

		mothur "#deunique.seqs(fasta=Metaxa.out.eukaryota.fasta, name=$names)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""	
			fi
		fi
	else 
		rm Metaxa.out1.eukaryota.fasta
	fi




	if [ -s Metaxa.out1.chloroplast.fasta ]; then
	sed -e 's/ .*//g' < Metaxa.out1.chloroplast.fasta | sed -e 's/_COMPLETE//g' > Metaxa.out.chloroplast.fast
	rm Metaxa.out1.chloroplast.fasta

		if [ -s Metaxa.out.chloroplast.fasta ];then
		echo ""
		echo "# Deunique sequences (Metaxa.out.chloroplast.fasta) (sequences were uniqued prior to Metaxa2)"

		mothur "#deunique.seqs(fasta=Metaxa.out.chloroplast.fasta, name=$names)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""	
			fi
		fi
	else
		rm Metaxa.out1.chloroplast.fasta
	fi




	if [ -s Metaxa.out1.mitochondria.fasta ]; then
	sed -e 's/ .*//g' < Metaxa.out1.mitochondria.fasta | sed -e 's/_COMPLETE//g' > Metaxa.out.mitochondria.fasta
	rm Metaxa.out1.mitochondria.fasta

		if [ -s Metaxa.out.mitochondria.fasta ];then
		echo ""
		echo "# Deunique sequences (Metaxa.out.mitochondria.fasta) (sequences were uniqued prior to Metaxa2)"

		mothur "#deunique.seqs(fasta=Metaxa.out.mitochondria.fasta, name=$names)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""	
			fi
		fi
	else 
		rm Metaxa.out1.mitochondria.fasta
	fi


#Metaxa2 FINISHED!!!
			if [ -e Metaxa.out.bacteria.redundant.fasta ] || [ -e Metaxa.out.mitochondria.redundant.fasta ] || [ -e Metaxa.out.chloroplast.redundant.fasta ] || [ -e Metaxa.out.eukaryota.redundant.fasta ] || [ -e Metaxa.out.archaea.redundant.fasta ]; then
				touch ${USER_HOME}/.var_babitas/GeneX_finished.txt
				echo ""
				echo "##########################"
				echo "DONE"
				echo "#############################"
				echo "Metaxa2 finished"
				echo "###################################"
				echo "You may close this window now!"
			else
				echo "ERROR occurred, redundant output NOT FOUND" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			fi
fi
fi



########################################
########################################
################# LSU ##################
########################################
############## V-Xtractor ##############
########################################
if grep -q 'LSU' ${USER_HOME}/.var_babitas/workflow.txt && grep -q 'V-Xtractor' ${USER_HOME}/.var_babitas/program.txt; then


echo ""
echo "### V-Xtractor 2.1 ###"
echo "# Extracting LSU #"
echo ""

	#Set HMM variable (-i)
	if grep -q 'Long' ${USER_HOME}/.var_babitas/HMM.txt; then
	hmm=$"-i long"

		else if grep -q 'Short' ${USER_HOME}/.var_babitas/HMM.txt; then
		hmm=$"-i short"

		fi
	fi



	#Set profiles (organism) variable (-h)
	if grep -q 'Fungi and Bacteria' ${USER_HOME}/.var_babitas/profiles.txt; then
		profiles1=$"-h /dependencies/vxtractor/HMMs/LSU/fungi/"
		profiles2=$"-h /dependencies/vxtractor/HMMs/LSU/bacteria/"

		else if grep -q 'Fungi and Archaea' ${USER_HOME}/.var_babitas/profiles.txt; then
		profiles1=$"-h /dependencies/vxtractor/HMMs/LSU/fungi/"
		profiles2=$"-h /dependencies/vxtractor/HMMs/LSU/archaea/"

			else if grep -q 'Archaea and Bacteria' ${USER_HOME}/.var_babitas/profiles.txt; then
			profiles1=$"-h /dependencies/vxtractor/HMMs/LSU/archaea/"
			profiles2=$"-h /dependencies/vxtractor/HMMs/LSU/bacteria/"

				else if grep -q 'Bacteria' ${USER_HOME}/.var_babitas/profiles.txt; then
				profiles1=$"-h /dependencies/vxtractor/HMMs/LSU/bacteria/"

			else if grep -q 'Fungi' ${USER_HOME}/.var_babitas/profiles.txt; then
			profiles1=$"-h /dependencies/vxtractor/HMMs/LSU/fungi/"

		else if grep -q 'Archaea' ${USER_HOME}/.var_babitas/profiles.txt; then
		profiles1=$"-h /dependencies/vxtractor/HMMs/LSU/archaea/"

	fi
		fi
			fi
				fi
			fi
		fi


	#Set target region variable (-r)
	if grep -q 'V1' ${USER_HOME}/.var_babitas/target_reg.txt; then
	target=$"-r V01"
	targetGrep=$"_V01_"
	else if grep -q 'V2' ${USER_HOME}/.var_babitas/target_reg.txt; then
	target=$"-r V02"
	targetGrep=$"_V02_"
	else if grep -q 'V3' ${USER_HOME}/.var_babitas/target_reg.txt; then
	target=$"-r V03"
	targetGrep=$"_V03_"
	else if grep -q 'V4' ${USER_HOME}/.var_babitas/target_reg.txt; then
	target=$"-r V04"
	targetGrep=$"_V04_"
	else if grep -q 'V5' ${USER_HOME}/.var_babitas/target_reg.txt; then
	target=$"-r V05"
	targetGrep=$"_V05_"
	else if grep -q 'V6' ${USER_HOME}/.var_babitas/target_reg.txt; then
	target=$"-r V06"
	targetGrep=$"_V06_"
	else if grep -q 'V7' ${USER_HOME}/.var_babitas/target_reg.txt; then
	target=$"-r V07"
	targetGrep=$"_V07_"
	else if grep -q 'V8' ${USER_HOME}/.var_babitas/target_reg.txt; then
	target=$"-r V08"
	targetGrep=$"_V08_"
	else if grep -q 'V9' ${USER_HOME}/.var_babitas/target_reg.txt; then
	target=$"-r V09"
	targetGrep=$"_V09_"

		else if grep -q 'Multiple selections' ${USER_HOME}/.var_babitas/target_reg.txt; then
			if [ -e ${USER_HOME}/.var_babitas/r1.txt ]; then
			r1=$(echo " -r " && cat ${USER_HOME}/.var_babitas/r1.txt)
			fi
			if [ -e ${USER_HOME}/.var_babitas/r2.txt ]; then
			r2=$(echo " -r " && cat ${USER_HOME}/.var_babitas/r2.txt)
			fi
			if [ -e ${USER_HOME}/.var_babitas/r3.txt ]; then
			r3=$(echo " -r " && cat ${USER_HOME}/.var_babitas/r3.txt)
			fi
			if [ -e ${USER_HOME}/.var_babitas/r4.txt ]; then
			r4=$(echo " -r " && cat ${USER_HOME}/.var_babitas/r4.txt)
			fi
			if [ -e ${USER_HOME}/.var_babitas/r5.txt ]; then
			r5=$(echo " -r " && cat ${USER_HOME}/.var_babitas/r5.txt)
			fi
			if [ -e ${USER_HOME}/.var_babitas/r6.txt ]; then
			r6=$(echo " -r " && cat ${USER_HOME}/.var_babitas/r6.txt)
			fi
			if [ -e ${USER_HOME}/.var_babitas/r7.txt ]; then
			r7=$(echo " -r " && cat ${USER_HOME}/.var_babitas/r7.txt)
			fi
			if [ -e ${USER_HOME}/.var_babitas/r8.txt ]; then
			r8=$(echo " -r " && cat ${USER_HOME}/.var_babitas/r8.txt)
			fi
			if [ -e ${USER_HOME}/.var_babitas/r9.txt ]; then
			r9=$(echo " -r " && cat ${USER_HOME}/.var_babitas/r9.txt)
			fi
			if [ -e ${USER_HOME}/.var_babitas/r10.txt ]; then
			r10=$(echo " -r " && cat ${USER_HOME}/.var_babitas/r10.txt)
			fi
			if [ -e ${USER_HOME}/.var_babitas/r11.txt ]; then
			r11=$(echo " -r " && cat ${USER_HOME}/.var_babitas/r11.txt)
			fi
			if [ -e ${USER_HOME}/.var_babitas/r12.txt ]; then
			r12=$(echo " -r " && cat ${USER_HOME}/.var_babitas/r12.txt)
			fi
			if [ -e ${USER_HOME}/.var_babitas/r13.txt ]; then
			r13=$(echo " -r " && cat ${USER_HOME}/.var_babitas/r13.txt)
			fi
			if [ -e ${USER_HOME}/.var_babitas/r14.txt ]; then
			r14=$(echo " -r " && cat ${USER_HOME}/.var_babitas/r14.txt)
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




# Extracting MULTIPLE REGIONs
# Extracting MULTIPLE REGIONs
# Extracting MULTIPLE REGIONs
	if grep -q 'Multiple selections' ${USER_HOME}/.var_babitas/target_reg.txt; then

	echo "# Extracting" $r1 $r2 $r3 $r4 $r5 $r6 $r7 $r8 $r9 $r10 $r11 $r12 $r13 $r14
	echo ""
	echo "vxtractor.pl $profiles1 $profiles2 $hmm $r1 $r2 $r3 $r4 $r5 $r6 $r7 $r8 $r9 $r10 $r11 $r12 $r13 $r14 -o VXtractor.output.fasta -c VXtractor.output.csv $input_unique"
	vxtractor.pl $profiles1 $profiles2 $hmm $r1 $r2 $r3 $r4 $r5 $r6 $r7 $r8 $r9 $r10 $r11 $r12 $r13 $r14 -o VXtractor.output.fasta -c VXtractor.output.csv $input_unique
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/GeneX_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi


		if [ -e ${USER_HOME}/.var_babitas/r1.txt ]; then
		r1grep=$(cat ${USER_HOME}/.var_babitas/r1.txt | sed -e 's/[.]//g' | sed -e 's/-/_/g' | sed -e 's/^/_/' | sed 's/$/_/')
		
		echo $r1grep | tr -d -c '_' | awk '{ print length; }' > $r1grep.temp

			if grep -q '2' $r1grep.temp; then
			grep -A1 $r1grep VXtractor.output.fasta | grep -v -- -- | grep -v 'V'[[:digit:]][[:digit:]]$r1grep | grep -v $r1grep'V'[[:digit:]][[:digit:]] | grep -A1 '>' | sed -e 's/^--//g' | sed '/^$/d' > $r1grep.fasta
				if [ -s $r1grep.fasta ]; then
				sed -e "s/$r1grep.*//g" < $r1grep.fasta > $r1grep.unique.fasta
				fi
			rm $r1grep.temp
			echo "Extracting only" $r1 "from VXtractor.output.fasta; output="$r1grep.fasta

			else if grep -q '3' $r1grep.temp; then
			grep -A1 $r1grep VXtractor.output.fasta | grep -v -- -- > $r1grep.fasta
				if [ -s $r1grep.fasta ]; then
				sed -e "s/$r1grep.*//g" < $r1grep.fasta > $r1grep.unique.fasta
				fi
			rm $r1grep.temp
			echo "Extracting only" $r1 "from VXtractor.output.fasta; output="$r1grep.fasta

			fi
			fi
		
		fi


		if [ -e ${USER_HOME}/.var_babitas/r2.txt ]; then
		r2grep=$(cat ${USER_HOME}/.var_babitas/r2.txt | sed -e 's/[.]//g' | sed -e 's/-/_/g' | sed -e 's/^/_/' | sed 's/$/_/')
				
		echo $r2grep | tr -d -c '_' | awk '{ print length; }' > $r2grep.temp

			if grep -q '2' $r2grep.temp; then
			grep -A1 $r2grep VXtractor.output.fasta | grep -v -- -- | grep -v 'V'[[:digit:]][[:digit:]]$r2grep | grep -v $r2grep'V'[[:digit:]][[:digit:]] | grep -A1 '>' | sed -e 's/^--//g' | sed '/^$/d' > $r2grep.fasta
				if [ -s $r2grep.fasta ]; then
				sed -e "s/$r2grep.*//g" < $r2grep.fasta > $r2grep.unique.fasta
				fi
			rm $r2grep.temp
			echo "Extracting only" $r2 "from VXtractor.output.fasta; output="$r2grep.fasta

			else if grep -q '3' $r2grep.temp; then
			grep -A1 $r2grep VXtractor.output.fasta | grep -v -- -- > $r2grep.fasta
				if [ -s $r2grep.fasta ]; then
				sed -e "s/$r2grep.*//g" < $r2grep.fasta > $r2grep.unique.fasta
				fi
			rm $r2grep.temp
			echo "Extracting only" $r2 "from VXtractor.output.fasta; output="$r2grep.fasta

			fi
			fi
		fi




		if [ -e ${USER_HOME}/.var_babitas/r3.txt ]; then
		r3grep=$(cat ${USER_HOME}/.var_babitas/r3.txt | sed -e 's/[.]//g' | sed -e 's/-/_/g' | sed -e 's/^/_/' | sed 's/$/_/')
		
		echo $r3grep | tr -d -c '_' | awk '{ print length; }' > $r3grep.temp

			if grep -q '2' $r3grep.temp; then
			grep -A1 $r3grep VXtractor.output.fasta | grep -v -- -- | grep -v 'V'[[:digit:]][[:digit:]]$r3grep | grep -v $r3grep'V'[[:digit:]][[:digit:]] | grep -A1 '>' | sed -e 's/^--//g' | sed '/^$/d' > $r3grep.fasta
				if [ -s $r3grep.fasta ]; then
				sed -e "s/$r3grep.*//g" < $r3grep.fasta > $r3grep.unique.fasta
				fi
			rm $r3grep.temp
			echo "Extracting only" $r3 "from VXtractor.output.fasta; output="$r3grep.fasta

			else if grep -q '3' $r3grep.temp; then
			grep -A1 $r3grep VXtractor.output.fasta | grep -v -- -- > $r3grep.fasta
				if [ -s $r3grep.fasta ]; then
				sed -e "s/$r3grep.*//g" < $r3grep.fasta > $r3grep.unique.fasta
				fi
			rm $r3grep.temp
			echo "Extracting only" $r3 "from VXtractor.output.fasta; output="$r3grep.fasta

			fi
			fi
		fi




		if [ -e ${USER_HOME}/.var_babitas/r4.txt ]; then
		r4grep=$(cat ${USER_HOME}/.var_babitas/r4.txt | sed -e 's/[.]//g' | sed -e 's/-/_/g' | sed -e 's/^/_/' | sed 's/$/_/')
		
		echo $r4grep | tr -d -c '_' | awk '{ print length; }' > $r4grep.temp

			if grep -q '2' $r4grep.temp; then
			grep -A1 $r4grep VXtractor.output.fasta | grep -v -- -- | grep -v 'V'[[:digit:]][[:digit:]]$r4grep | grep -v $r4grep'V'[[:digit:]][[:digit:]] | grep -A1 '>' | sed -e 's/^--//g' | sed '/^$/d' > $r4grep.fasta
				if [ -s $r4grep.fasta ]; then
				sed -e "s/$r4grep.*//g" < $r4grep.fasta > $r4grep.unique.fasta
				fi
			rm $r4grep.temp
			echo "Extracting only" $r4 "from VXtractor.output.fasta; output="$r4grep.fasta

			else if grep -q '3' $r4grep.temp; then
			grep -A1 $r4grep VXtractor.output.fasta | grep -v -- -- > $r4grep.fasta
				if [ -s $r4grep.fasta ]; then
				sed -e "s/$r4grep.*//g" < $r4grep.fasta > $r4grep.unique.fasta
				fi
			rm $r4grep.temp
			echo "Extracting only" $r4 "from VXtractor.output.fasta; output="$r4grep.fasta

			fi
			fi
		fi




		if [ -e ${USER_HOME}/.var_babitas/r5.txt ]; then
		r5grep=$(cat ${USER_HOME}/.var_babitas/r5.txt | sed -e 's/[.]//g' | sed -e 's/-/_/g' | sed -e 's/^/_/' | sed 's/$/_/')
		
		echo $r5grep | tr -d -c '_' | awk '{ print length; }' > $r5grep.temp

			if grep -q '2' $r5grep.temp; then
			grep -A1 $r5grep VXtractor.output.fasta | grep -v -- -- | grep -v 'V'[[:digit:]][[:digit:]]$r5grep | grep -v $r5grep'V'[[:digit:]][[:digit:]] | grep -A1 '>' | sed -e 's/^--//g' | sed '/^$/d' > $r5grep.fasta
				if [ -s $r5grep.fasta ]; then
				sed -e "s/$r5grep.*//g" < $r5grep.fasta > $r5grep.unique.fasta
				fi
			rm $r5grep.temp
			echo "Extracting only" $r5 "from VXtractor.output.fasta; output="$r5grep.fasta

			else if grep -q '3' $r5grep.temp; then
			grep -A1 $r5grep VXtractor.output.fasta | grep -v -- -- > $r5grep.fasta
				if [ -s $r5grep.fasta ]; then
				sed -e "s/$r5grep.*//g" < $r5grep.fasta > $r5grep.unique.fasta
				fi
			rm $r5grep.temp
			echo "Extracting only" $r5 "from VXtractor.output.fasta; output="$r5grep.fasta

			fi
			fi
		fi




		if [ -e ${USER_HOME}/.var_babitas/r6.txt ]; then
		r6grep=$(cat ${USER_HOME}/.var_babitas/r6.txt | sed -e 's/[.]//g' | sed -e 's/-/_/g' | sed -e 's/^/_/' | sed 's/$/_/')
		
		echo $r6grep | tr -d -c '_' | awk '{ print length; }' > $r6grep.temp

			if grep -q '2' $r6grep.temp; then
			grep -A1 $r6grep VXtractor.output.fasta | grep -v -- -- | grep -v 'V'[[:digit:]][[:digit:]]$r6grep | grep -v $r6grep'V'[[:digit:]][[:digit:]] | grep -A1 '>' | sed -e 's/^--//g' | sed '/^$/d' > $r6grep.fasta
				if [ -s $r6grep.fasta ]; then
				sed -e "s/$r6grep.*//g" < $r6grep.fasta > $r6grep.unique.fasta
				fi
			rm $r6grep.temp
			echo "Extracting only" $r6 "from VXtractor.output.fasta; output="$r6grep.fasta

			else if grep -q '3' $r6grep.temp; then
			grep -A1 $r6grep VXtractor.output.fasta | grep -v -- -- > $r6grep.fasta
				if [ -s $r6grep.fasta ]; then
				sed -e "s/$r6grep.*//g" < $r6grep.fasta > $r6grep.unique.fasta
				fi
			rm $r6grep.temp
			echo "Extracting only" $r6 "from VXtractor.output.fasta; output="$r6grep.fasta

			fi
			fi
		fi




		if [ -e ${USER_HOME}/.var_babitas/r7.txt ]; then
		r7grep=$(cat ${USER_HOME}/.var_babitas/r7.txt | sed -e 's/[.]//g' | sed -e 's/-/_/g' | sed -e 's/^/_/' | sed 's/$/_/')
		
		echo $r7grep | tr -d -c '_' | awk '{ print length; }' > $r7grep.temp

			if grep -q '2' $r7grep.temp; then
			grep -A1 $r7grep VXtractor.output.fasta | grep -v -- -- | grep -v 'V'[[:digit:]][[:digit:]]$r7grep | grep -v $r7grep'V'[[:digit:]][[:digit:]] | grep -A1 '>' | sed -e 's/^--//g' | sed '/^$/d' > $r7grep.fasta
				if [ -s $r7grep.fasta ]; then
				sed -e "s/$r7grep.*//g" < $r7grep.fasta > $r7grep.unique.fasta
				fi
			rm $r7grep.temp
			echo "Extracting only" $r7 "from VXtractor.output.fasta; output="$r7grep.fasta

			else if grep -q '3' $r7grep.temp; then
			grep -A1 $r7grep VXtractor.output.fasta | grep -v -- -- > $r7grep.fasta
				if [ -s $r7grep.fasta ]; then
				sed -e "s/$r7grep.*//g" < $r7grep.fasta > $r7grep.unique.fasta
				fi
			rm $r7grep.temp
			echo "Extracting only" $r7 "from VXtractor.output.fasta; output="$r7grep.fasta

			fi
			fi
		fi




		if [ -e ${USER_HOME}/.var_babitas/r8.txt ]; then
		r8grep=$(cat ${USER_HOME}/.var_babitas/r8.txt | sed -e 's/[.]//g' | sed -e 's/-/_/g' | sed -e 's/^/_/' | sed 's/$/_/')
		
		echo $r8grep | tr -d -c '_' | awk '{ print length; }' > $r8grep.temp

			if grep -q '2' $r8grep.temp; then
			grep -A1 $r8grep VXtractor.output.fasta | grep -v -- -- | grep -v 'V'[[:digit:]][[:digit:]]$r8grep | grep -v $r8grep'V'[[:digit:]][[:digit:]] | grep -A1 '>' | sed -e 's/^--//g' | sed '/^$/d' > $r8grep.fasta
				if [ -s $r8grep.fasta ]; then
				sed -e "s/$r8grep.*//g" < $r8grep.fasta > $r8grep.unique.fasta
				fi
			rm $r8grep.temp
			echo "Extracting only" $r8 "from VXtractor.output.fasta; output="$r8grep.fasta

			else if grep -q '3' $r8grep.temp; then
			grep -A1 $r8grep VXtractor.output.fasta | grep -v -- -- > $r8grep.fasta
				if [ -s $r8grep.fasta ]; then
				sed -e "s/$r8grep.*//g" < $r8grep.fasta > $r8grep.unique.fasta
				fi
			rm $r8grep.temp
			echo "Extracting only" $r8 "from VXtractor.output.fasta; output="$r8grep.fasta

			fi
			fi
		fi




		if [ -e ${USER_HOME}/.var_babitas/r9.txt ]; then
		r9grep=$(cat ${USER_HOME}/.var_babitas/r9.txt | sed -e 's/[.]//g' | sed -e 's/-/_/g' | sed -e 's/^/_/' | sed 's/$/_/')
		
		echo $r9grep | tr -d -c '_' | awk '{ print length; }' > $r9grep.temp

			if grep -q '2' $r9grep.temp; then
			grep -A1 $r9grep VXtractor.output.fasta | grep -v -- -- | grep -v 'V'[[:digit:]][[:digit:]]$r9grep | grep -v $r9grep'V'[[:digit:]][[:digit:]] | grep -A1 '>' | sed -e 's/^--//g' | sed '/^$/d' > $r9grep.fasta
				if [ -s $r9grep.fasta ]; then
				sed -e "s/$r9grep.*//g" < $r9grep.fasta > $r9grep.unique.fasta
				fi
			rm $r9grep.temp
			echo "Extracting only" $r9 "from VXtractor.output.fasta; output="$r9grep.fasta

			else if grep -q '3' $r9grep.temp; then
			grep -A1 $r9grep VXtractor.output.fasta | grep -v -- -- > $r9grep.fasta
				if [ -s $r9grep.fasta ]; then
				sed -e "s/$r9grep.*//g" < $r9grep.fasta > $r9grep.unique.fasta
				fi
			rm $r9grep.temp
			echo "Extracting only" $r9 "from VXtractor.output.fasta; output="$r9grep.fasta

			fi
			fi
		fi




		if [ -e ${USER_HOME}/.var_babitas/r10.txt ]; then
		r10grep=$(cat ${USER_HOME}/.var_babitas/r10.txt | sed -e 's/[.]//g' | sed -e 's/-/_/g' | sed -e 's/^/_/' | sed 's/$/_/')
		
		echo $r10grep | tr -d -c '_' | awk '{ print length; }' > $r10grep.temp

			if grep -q '2' $r10grep.temp; then
			grep -A1 $r10grep VXtractor.output.fasta | grep -v -- -- | grep -v 'V'[[:digit:]][[:digit:]]$r10grep | grep -v $r10grep'V'[[:digit:]][[:digit:]] | grep -A1 '>' | sed -e 's/^--//g' | sed '/^$/d' > $r10grep.fasta
				if [ -s $r10grep.fasta ]; then
				sed -e "s/$r10grep.*//g" < $r10grep.fasta > $r10grep.unique.fasta
				fi
			rm $r10grep.temp
			echo "Extracting only" $r10 "from VXtractor.output.fasta; output="$r10grep.fasta

			else if grep -q '3' $r10grep.temp; then
			grep -A1 $r10grep VXtractor.output.fasta | grep -v -- -- > $r10grep.fasta
				if [ -s $r10grep.fasta ]; then
				sed -e "s/$r10grep.*//g" < $r10grep.fasta > $r10grep.unique.fasta
				fi
			rm $r10grep.temp
			echo "Extracting only" $r10 "from VXtractor.output.fasta; output="$r10grep.fasta

			fi
			fi
		fi




		if [ -e ${USER_HOME}/.var_babitas/r11.txt ]; then
		r11grep=$(cat ${USER_HOME}/.var_babitas/r11.txt | sed -e 's/[.]//g' | sed -e 's/-/_/g' | sed -e 's/^/_/' | sed 's/$/_/')
		
		echo $r11grep | tr -d -c '_' | awk '{ print length; }' > $r11grep.temp

			if grep -q '2' $r11grep.temp; then
			grep -A1 $r11grep VXtractor.output.fasta | grep -v -- -- | grep -v 'V'[[:digit:]][[:digit:]]$r11grep | grep -v $r11grep'V'[[:digit:]][[:digit:]] | grep -A1 '>' | sed -e 's/^--//g' | sed '/^$/d' > $r11grep.fasta
				if [ -s $r11grep.fasta ]; then
				sed -e "s/$r11grep.*//g" < $r11grep.fasta > $r11grep.unique.fasta
				fi
			rm $r11grep.temp
			echo "Extracting only" $r11 "from VXtractor.output.fasta; output="$r11grep.fasta

			else if grep -q '3' $r11grep.temp; then
			grep -A1 $r11grep VXtractor.output.fasta | grep -v -- -- > $r11grep.fasta
				if [ -s $r11grep.fasta ]; then
				sed -e "s/$r11grep.*//g" < $r11grep.fasta > $r11grep.unique.fasta
				fi
			rm $r11grep.temp
			echo "Extracting only" $r11 "from VXtractor.output.fasta; output="$r11grep.fasta

			fi
			fi
		fi




		if [ -e ${USER_HOME}/.var_babitas/r12.txt ]; then
		r12grep=$(cat ${USER_HOME}/.var_babitas/r12.txt | sed -e 's/[.]//g' | sed -e 's/-/_/g' | sed -e 's/^/_/' | sed 's/$/_/')
		
		echo $r12grep | tr -d -c '_' | awk '{ print length; }' > $r12grep.temp

			if grep -q '2' $r12grep.temp; then
			grep -A1 $r12grep VXtractor.output.fasta | grep -v -- -- | grep -v 'V'[[:digit:]][[:digit:]]$r12grep | grep -v $r12grep'V'[[:digit:]][[:digit:]] | grep -A1 '>' | sed -e 's/^--//g' | sed '/^$/d' > $r12grep.fasta
				if [ -s $r12grep.fasta ]; then
				sed -e "s/$r12grep.*//g" < $r12grep.fasta > $r12grep.unique.fasta
				fi
			rm $r12grep.temp
			echo "Extracting only" $r12 "from VXtractor.output.fasta; output="$r12grep.fasta

			else if grep -q '3' $r12grep.temp; then
			grep -A1 $r12grep VXtractor.output.fasta | grep -v -- -- > $r12grep.fasta
				if [ -s $r12grep.fasta ]; then
				sed -e "s/$r12grep.*//g" < $r12grep.fasta > $r12grep.unique.fasta
				fi
			rm $r12grep.temp
			echo "Extracting only" $r12 "from VXtractor.output.fasta; output="$r12grep.fasta

			fi
			fi
		fi




		if [ -e ${USER_HOME}/.var_babitas/r13.txt ]; then
		r13grep=$(cat ${USER_HOME}/.var_babitas/r13.txt | sed -e 's/[.]//g' | sed -e 's/-/_/g' | sed -e 's/^/_/' | sed 's/$/_/')
		
		echo $r13grep | tr -d -c '_' | awk '{ print length; }' > $r13grep.temp

			if grep -q '2' $r13grep.temp; then
			grep -A1 $r13grep VXtractor.output.fasta | grep -v -- -- | grep -v 'V'[[:digit:]][[:digit:]]$r13grep | grep -v $r13grep'V'[[:digit:]][[:digit:]] | grep -A1 '>' | sed -e 's/^--//g' | sed '/^$/d' > $r13grep.fasta
				if [ -s $r13grep.fasta ]; then
				sed -e "s/$r13grep.*//g" < $r13grep.fasta > $r13grep.unique.fasta
				fi
			rm $r13grep.temp
			echo "Extracting only" $r13 "from VXtractor.output.fasta; output="$r13grep.fasta

			else if grep -q '3' $r13grep.temp; then
			grep -A1 $r13grep VXtractor.output.fasta | grep -v -- -- > $r13grep.fasta
				if [ -s $r13grep.fasta ]; then
				sed -e "s/$r13grep.*//g" < $r13grep.fasta > $r13grep.unique.fasta
				fi
			rm $r13grep.temp
			echo "Extracting only" $r13 "from VXtractor.output.fasta; output="$r13grep.fasta

			fi
			fi
		fi




		if [ -e ${USER_HOME}/.var_babitas/r14.txt ]; then
		r14grep=$(cat ${USER_HOME}/.var_babitas/r14.txt | sed -e 's/[.]//g' | sed -e 's/-/_/g' | sed -e 's/^/_/' | sed 's/$/_/')
		
		echo $r14grep | tr -d -c '_' | awk '{ print length; }' > $r14grep.temp

			if grep -q '2' $r14grep.temp; then
			grep -A1 $r14grep VXtractor.output.fasta | grep -v -- -- | grep -v 'V'[[:digit:]][[:digit:]]$r14grep | grep -v $r14grep'V'[[:digit:]][[:digit:]] | grep -A1 '>' | sed -e 's/^--//g' | sed '/^$/d' > $r14grep.fasta
				if [ -s $r14grep.fasta ]; then
				sed -e "s/$r14grep.*//g" < $r14grep.fasta > $r14grep.unique.fasta
				fi
			rm $r14grep.temp
			echo "Extracting only" $r14 "from VXtractor.output.fasta; output="$r14grep.fasta

			else if grep -q '3' $r14grep.temp; then
			grep -A1 $r14grep VXtractor.output.fasta | grep -v -- -- > $r14grep.fasta
				if [ -s $r14grep.fasta ]; then
				sed -e "s/$r14grep.*//g" < $r14grep.fasta > $r14grep.unique.fasta
				fi
			rm $r14grep.temp
			echo "Extracting only" $r14 "from VXtractor.output.fasta; output="$r14grep.fasta

			fi
			fi
		fi


			

	
		#Deunique sequences (sequences were uniqued prior to GeneX)

		if [ -s $r1grep.unique.fasta ]; then
			echo ""
			echo "# Deunique sequences ($r1grep.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=$r1grep.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv $r1grep.unique.redundant.fasta $r1grep.redundant.fasta	
		fi



		if [ -s $r2grep.unique.fasta]; then
			echo ""
			echo "# Deunique sequences ($r2grep.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=$r2grep.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv $r2grep.unique.redundant.fasta $r2grep.redundant.fasta
		fi



		if [ -s $r3grep.unique.fasta ]; then
			echo ""
			echo "# Deunique sequences ($r3grep.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=$r3grep.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv $r3grep.unique.redundant.fasta $r3grep.redundant.fasta
		
		fi



		if [ -s $r4grep.unique.fasta ]; then
			echo ""
			echo "# Deunique sequences ($r4grep.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=$r4grep.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv $r4grep.unique.redundant.fasta $r4grep.redundant.fasta
		
		fi



		if [ -s $r5grep.unique.fasta ]; then
			echo ""
			echo "# Deunique sequences ($r5grep.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=$r5grep.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv $r5grep.unique.redundant.fasta $r5grep.redundant.fasta
		
		fi



		if [ -s $r6grep.unique.fasta ]; then
			echo ""
			echo "# Deunique sequences ($r6grep.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=$r6grep.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv $r6grep.unique.redundant.fasta $r6grep.redundant.fasta
		
		fi



		if [ -s $r7grep.unique.fasta ]; then
			echo ""
			echo "# Deunique sequences ($r7grep.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=$r7grep.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv $r7grep.unique.redundant.fasta $r7grep.redundant.fasta
		
		fi



		if [ -s $r8grep.unique.fasta ]; then
			echo ""
			echo "# Deunique sequences ($r8grep.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=$r8grep.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv $r8grep.unique.redundant.fasta $r8grep.redundant.fasta
		
		fi



		if [ -s $r9grep.unique.fasta ]; then
			echo ""
			echo "# Deunique sequences ($r9grep.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=$r9grep.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv $r9grep.unique.redundant.fasta $r9grep.redundant.fasta
		
		fi



		if [ -s $r10grep.unique.fasta ]; then
			echo ""
			echo "# Deunique sequences ($r10grep.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=$r10grep.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv $r10grep.unique.redundant.fasta $r10grep.redundant.fasta
		
		fi



		if [ -s $r11grep.unique.fasta ]; then
			echo ""
			echo "# Deunique sequences ($r11grep.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=$r11grep.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv $r11grep.unique.redundant.fasta $r11grep.redundant.fasta
		
		fi



		if [ -s $r12grep.unique.fasta ]; then
			echo ""
			echo "# Deunique sequences ($r12grep.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=$r12grep.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv $r12grep.unique.redundant.fasta $r12grep.redundant.fasta
		
		fi



		if [ -s $r13grep.unique.fasta ]; then
			echo ""
			echo "# Deunique sequences ($r13grep.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=$r13grep.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv $r13grep.unique.redundant.fasta $r13grep.redundant.fasta
		
		fi



		if [ -s $r14grep.unique.fasta ]; then
			echo ""
			echo "# Deunique sequences ($r14grep.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=$r14grep.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv $r14grep.unique.redundant.fasta $r14grep.redundant.fasta
		
		fi



#V-Extractor FINISEHD_1!!!
if [ -s VXtractor.output.fasta ]; then

		touch ${USER_HOME}/.var_babitas/GeneX_finished.txt
	
		echo ""
		echo "##########################"
		echo "DONE"
		echo "#############################"
		echo "V-Xtractor finished"
		echo "###################################"
		echo "You may close this window now!"
		
		else
		echo "ERROR occurred, VXtractor.output.fasta in BLANK" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
fi





# Extracting SINGLE REGION
# Extracting SINGLE REGION
# Extracting SINGLE REGION

	else
	echo "# Extracting" $target
	echo ""
	echo "vxtractor.pl $profiles1 $profiles2 $hmm $target -o VXtractor.output.fasta -c VXtractor.output.csv $input_unique"
	vxtractor.pl $profiles1 $profiles2 $hmm $target -o VXtractor.output.fasta -c VXtractor.output.csv $input_unique
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/GeneX_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi



	
		if grep -q 'All' ${USER_HOME}/.var_babitas/target_reg.txt; then
			grep -A1 _V01_ VXtractor.output.fasta | grep -v -- -- > _V01_.fasta
			grep -A1 _V02_ VXtractor.output.fasta | grep -v -- -- > _V02_.fasta
			grep -A1 _V03_ VXtractor.output.fasta | grep -v -- -- > _V03_.fasta
			grep -A1 _V04_ VXtractor.output.fasta | grep -v -- -- > _V04_.fasta
			grep -A1 _V05_ VXtractor.output.fasta | grep -v -- -- > _V05_.fasta
			grep -A1 _V06_ VXtractor.output.fasta | grep -v -- -- > _V06_.fasta
			grep -A1 _V07_ VXtractor.output.fasta | grep -v -- -- > _V07_.fasta
			grep -A1 _V08_ VXtractor.output.fasta | grep -v -- -- > _V08_.fasta
			grep -A1 _V09_ VXtractor.output.fasta | grep -v -- -- > _V09_.fasta
			grep -A1 _V10_ VXtractor.output.fasta | grep -v -- -- > _V10_.fasta
			grep -A1 _V11_ VXtractor.output.fasta | grep -v -- -- > _V11_.fasta
			grep -A1 _V12_ VXtractor.output.fasta | grep -v -- -- > _V12_.fasta
			grep -A1 _V13_ VXtractor.output.fasta | grep -v -- -- > _V13_.fasta
			grep -A1 _V14_ VXtractor.output.fasta | grep -v -- -- > _V14_.fasta
			grep -A1 _V15_ VXtractor.output.fasta | grep -v -- -- > _V15_.fasta

			if [ -s _V01_.fasta ]; then
			sed -e "s/_V01_.*//g" < _V01_.fasta > _V01_.unique.fasta
			echo ""
			echo "# Deunique sequences (_V01_.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=_V01_.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv _V01_.unique.redundant.fasta _V01_.redundant.fasta
			
			else 
			rm _V01_.fasta
			fi




			if [ -s _V02_.fasta ]; then
			sed -e "s/_V02_.*//g" < _V02_.fasta > _V02_.unique.fasta
			echo ""
			echo "# Deunique sequences (_V02_.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=_V02_.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv _V02_.unique.redundant.fasta _V02_.redundant.fasta
			
			else 
			rm _V02_.fasta
			fi



			if [ -s _V03_.fasta ]; then
			sed -e "s/_V03_.*//g" < _V03_.fasta > _V03_.unique.fasta
			echo ""
			echo "# Deunique sequences (_V03_.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=_V03_.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv _V03_.unique.redundant.fasta _V03_.redundant.fasta
			
			else 
			rm _V03_.fasta
			fi




			if [ -s _V04_.fasta ]; then
			sed -e "s/_V04_.*//g" < _V04_.fasta > _V04_.unique.fasta
			echo ""
			echo "# Deunique sequences (_V04_.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=_V04_.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv _V04_.unique.redundant.fasta _V04_.redundant.fasta
			
			else 
			rm _V04_.fasta
			fi




			if [ -s _V05_.fasta ]; then
			sed -e "s/_V05_.*//g" < _V05_.fasta > _V05_.unique.fasta
			echo ""
			echo "# Deunique sequences (_V05_.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=_V05_.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv _V05_.unique.redundant.fasta _V05_.redundant.fasta
			
			else 
			rm _V05_.fasta
			fi




			if [ -s _V06_.fasta ]; then
			sed -e "s/_V06_.*//g" < _V06_.fasta > _V06_.unique.fasta
			echo ""
			echo "# Deunique sequences (_V06_.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=_V06_.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv _V06_.unique.redundant.fasta _V06_.redundant.fasta
			
			else 
			rm _V06_.fasta
			fi




			if [ -s _V07_.fasta ]; then
			sed -e "s/_V07_.*//g" < _V07_.fasta > _V07_.unique.fasta
			echo ""
			echo "# Deunique sequences (_V07_.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=_V07_.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv _V07_.unique.redundant.fasta _V07_.redundant.fasta
			
			else 
			rm _V07_.fasta
			fi




			if [ -s _V08_.fasta ]; then
			sed -e "s/_V08_.*//g" < _V08_.fasta > _V08_.unique.fasta
			echo ""
			echo "# Deunique sequences (_V08_.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=_V08_.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv _V08_.unique.redundant.fasta _V08_.redundant.fasta
			
			else 
			rm _V08_.fasta
			fi




			if [ -s _V09_.fasta ]; then
			sed -e "s/_V09_.*//g" < _V09_.fasta > _V09_.unique.fasta
			echo ""
			echo "# Deunique sequences (_V09_.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=_V09_.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv _V09_.unique.redundant.fasta _V09_.redundant.fasta
			
			else 
			rm _V09_.fasta
			fi




			if [ -s _V10_.fasta ]; then
			sed -e "s/_V10_.*//g" < _V10_.fasta > _V10_.unique.fasta
			echo ""
			echo "# Deunique sequences (_V10_.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=_V10_.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv _V10_.unique.redundant.fasta _V10_.redundant.fasta
			
			else 
			rm _V10_.fasta
			fi




			if [ -s _V11_.fasta ]; then
			sed -e "s/_V11_.*//g" < _V11_.fasta > _V11_.unique.fasta
			echo ""
			echo "# Deunique sequences (_V11_.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=_V11_.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv _V11_.unique.redundant.fasta _V11_.redundant.fasta
			
			else 
			rm _V11_.fasta
			fi




			if [ -s _V12_.fasta ]; then
			sed -e "s/_V12_.*//g" < _V12_.fasta > _V12_.unique.fasta
			echo ""
			echo "# Deunique sequences (_V12_.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=_V12_.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv _V12_.unique.redundant.fasta _V12_.redundant.fasta
			
			else 
			rm _V12_.fasta
			fi




			if [ -s _V13_.fasta ]; then
			sed -e "s/_V13_.*//g" < _V13_.fasta > _V13_.unique.fasta
			echo ""
			echo "# Deunique sequences (_V13_.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=_V13_.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv _V13_.unique.redundant.fasta _V13_.redundant.fasta
			
			else 
			rm _V13_.fasta
			fi




			if [ -s _V14_.fasta ]; then
			sed -e "s/_V14_.*//g" < _V14_.fasta > _V14_.unique.fasta
			echo ""
			echo "# Deunique sequences (_V14_.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=_V14_.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv _V14_.unique.redundant.fasta _V14_.redundant.fasta
			
			else 
			rm _V14_.fasta
			fi




			if [ -s _V15_.fasta ]; then
			sed -e "s/_V15_.*//g" < _V15_.fasta > _V15_.unique.fasta
			echo ""
			echo "# Deunique sequences (_V15_.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=_V15_.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv _V15_.unique.redundant.fasta _V15_.redundant.fasta
			
			else 
			rm _V15_.fasta
			fi


				#V-Extractor FINISEHD_2!!!
				if [ -e $WorkingDirectory/VXtractor.output.fasta ];then

				touch ${USER_HOME}/.var_babitas/GeneX_finished.txt
	
				echo ""
				echo "##########################"
				echo "DONE"
				echo "#############################"
				echo "V-Xtractor finished"
				echo "###################################"
				echo "You may close this window now!"
		
				else
				echo "ERROR occurred, VXtractor.output.fasta NOT FOUND" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				fi



		####ELSE####
			else
			grep -A1 $targetGrep VXtractor.output.fasta | grep -v -- -- | grep -v 'V'[[:digit:]][[:digit:]]$targetGrep | grep -v $targetGrep'V'[[:digit:]][[:digit:]] | grep -A1 '>' | sed -e 's/^--//g' | sed '/^$/d' > $targetGrep.fasta

			sed -e "s/$targetGrep.*//g" < $targetGrep.fasta > $targetGrep.unique.fasta

			echo ""
			echo "# Deunique sequences ($targetGrep.unique.fasta) (sequences were uniqued prior to V-Xtractor)"

			mothur "#deunique.seqs(fasta=$targetGrep.unique.fasta, name=$names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
	 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
				else
				echo ""	
				fi

			mv $targetGrep.unique.redundant.fasta $targetGrep.redundant.fasta


			#V-Extractor FINISEHD_2!!!
			if [ -e $targetGrep.redundant.fasta ];then

			touch ${USER_HOME}/.var_babitas/GeneX_finished.txt
	
			echo ""
			echo "##########################"
			echo "DONE"
			echo "#############################"
			echo "V-Xtractor finished"
			echo "###################################"
			echo "You may close this window now!"
		
			else
			echo "ERROR occurred, "$targetGrep".redundant.fasta NOT FOUND" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			fi

		fi





	fi






#####################################
############## Metaxa2 ############## 
#####################################
else if grep -q 'LSU' ${USER_HOME}/.var_babitas/workflow.txt && grep -q 'Metaxa' ${USER_HOME}/.var_babitas/program.txt; then


echo ""
echo "### Metaxa 2.1.3 ###"
echo "# Extracting LSU #"
echo ""


	#Set profiles (organism) variable (-t)
	mkdir ${USER_HOME}/.var_babitas/Profiles

	if [ -e ${USER_HOME}/.var_babitas/profiles_all.txt ]; then
		t1=$"all"
		echo ""
		echo "Set of profiles = "$t1
		echo ""
	else
		if [ -e ${USER_HOME}/.var_babitas/profiles_euc.txt ]; then
		mv ${USER_HOME}/.var_babitas/profiles_euc.txt ${USER_HOME}/.var_babitas/Profiles/profiles_euc.txt
		fi
		if [ -e ${USER_HOME}/.var_babitas/profiles_chlor.txt ]; then
		mv ${USER_HOME}/.var_babitas/profiles_chlor.txt ${USER_HOME}/.var_babitas/Profiles/profiles_chlor.txt
		fi
		if [ -e ${USER_HOME}/.var_babitas/profiles_bac.txt ]; then
		mv ${USER_HOME}/.var_babitas/profiles_bac.txt ${USER_HOME}/.var_babitas/Profiles/profiles_bac.txt
		fi
		if [ -e ${USER_HOME}/.var_babitas/profiles_arc.txt ]; then
		mv ${USER_HOME}/.var_babitas/profiles_arc.txt ${USER_HOME}/.var_babitas/Profiles/profiles_arc.txt
		fi
		if [ -e ${USER_HOME}/.var_babitas/profiles_mito.txt ]; then
		mv ${USER_HOME}/.var_babitas/profiles_mito.txt ${USER_HOME}/.var_babitas/Profiles/profiles_mito.txt
		fi
		
		profiles=$(cat ${USER_HOME}/.var_babitas/Profiles/*.txt | tr "\n" "," | sed 's/.$//')
		echo ""
		echo "Set of profiles = "$profiles
		echo ""

	fi
	





	#Set CPUs variable (--cpu)
	if [ -e ${USER_HOME}/.var_babitas/CPUs.txt ]; then
	cpus=$(cat ${USER_HOME}/.var_babitas/CPUs.txt)
	fi

	#Set mode variable (--mode)
	if grep -q 'Metagenome' ${USER_HOME}/.var_babitas/mode.txt; then
	mode=$"metagenome"
		else if grep -q 'Genome' ${USER_HOME}/.var_babitas/mode.txt; then
		mode=$"genome"
			else if grep -q 'Auto' ${USER_HOME}/.var_babitas/mode.txt; then
			mode=$"auto"
			fi
		fi
	fi


	#Set sequence selection variables
	if [ -e ${USER_HOME}/.var_babitas/eval.txt ]; then
	eval=$(cat ${USER_HOME}/.var_babitas/eval.txt)
	fi

	if [ -e ${USER_HOME}/.var_babitas/score.txt ]; then
	score=$(echo "-S " && cat ${USER_HOME}/.var_babitas/score.txt)
	fi

	if [ -e ${USER_HOME}/.var_babitas/priority.txt ]; then
	priority=$(echo "--selection_priority " && cat ${USER_HOME}/.var_babitas/priority.txt)
	fi




	#Run Metaxa v2.1.2
	#Run Metaxa v2.1.2
	#Run Metaxa v2.1.2

	if [ -e ${USER_HOME}/.var_babitas/eval.txt ]; then

	echo "metaxa2 -i $input_unique -o Metaxa.out1 --taxonomy F --complement F -E $eval $priority $score --cpu $cpus -g lsu --mode $mode --graphical F -t $t1$profiles --not_found T --align n --plus T"
	echo ""
	
	metaxa2 -i $input_unique -o Metaxa.out1 --taxonomy F --complement F -E $eval $priority $score --cpu $cpus -g lsu --mode $mode --graphical F -t $t1$profiles --not_found T --align n --plus T
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/GeneX_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi

	else 
	echo "metaxa2 -i $input_unique -o Metaxa.out1 --taxonomy F --complement F $priority $score --cpu $cpus -g lsu --mode $mode --graphical F -t $t1$profiles --not_found T --align n --plus T"
	echo ""
	
	metaxa2 -i $input_unique -o Metaxa.out1 --taxonomy F --complement F $priority $score --cpu $cpus -g lsu --mode $mode --graphical F -t $t1$profiles --not_found T --align n --plus T
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/GeneX_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi

fi



#Delete added extra stuff after space in fasta headers and DEUNIQUE
	if [ -s Metaxa.out1.bacteria.fasta ]; then
	sed -e 's/ .*//g' < Metaxa.out1.bacteria.fasta | sed -e 's/_COMPLETE//g' > Metaxa.out.bacteria.fasta
	rm Metaxa.out1.bacteria.fasta
	
		if [ -s Metaxa.out.bacteria.fasta ];then
		echo ""
		echo "# Deunique sequences (Metaxa.out.bacteria.fasta) (sequences were uniqued prior to Metaxa2)"

		mothur "#deunique.seqs(fasta=Metaxa.out.bacteria.fasta, name=$names)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""	
			fi
		fi
	else
		rm Metaxa.out1.bacteria.fasta

	fi



	if [ -s Metaxa.out1.archaea.fasta ]; then
	sed -e 's/ .*//g' < Metaxa.out1.archaea.fasta | sed -e 's/_COMPLETE//g' > Metaxa.out.archaea.fasta
	rm Metaxa.out1.archaea.fasta

		if [ -s Metaxa.out.archaea.fasta ];then
		echo ""
		echo "# Deunique sequences (Metaxa.out.archaea.fasta) (sequences were uniqued prior to Metaxa2)"

		mothur "#deunique.seqs(fasta=Metaxa.out.archaea.fasta, name=$names)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""	
			fi
		fi
	else 
		rm Metaxa.out1.archaea.fasta

	fi




	if [ -s Metaxa.out1.eukaryota.fasta ]; then
	sed -e 's/ .*//g' < Metaxa.out1.eukaryota.fasta | sed -e 's/_COMPLETE//g' > Metaxa.out.eukaryota.fasta
	rm Metaxa.out1.eukaryota.fasta

		if [ -s Metaxa.out.eukaryota.fasta ];then
		echo ""
		echo "# Deunique sequences (Metaxa.out.eukaryota.fasta) (sequences were uniqued prior to Metaxa2)"

		mothur "#deunique.seqs(fasta=Metaxa.out.eukaryota.fasta, name=$names)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""	
			fi
		fi
	else 
		rm Metaxa.out1.eukaryota.fasta
	fi




	if [ -s Metaxa.out1.chloroplast.fasta ]; then
	sed -e 's/ .*//g' < Metaxa.out1.chloroplast.fasta | sed -e 's/_COMPLETE//g' > Metaxa.out.chloroplast.fast
	rm Metaxa.out1.chloroplast.fasta

		if [ -s Metaxa.out.chloroplast.fasta ];then
		echo ""
		echo "# Deunique sequences (Metaxa.out.chloroplast.fasta) (sequences were uniqued prior to Metaxa2)"

		mothur "#deunique.seqs(fasta=Metaxa.out.chloroplast.fasta, name=$names)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""	
			fi
		fi
	else 
		rm Metaxa.out1.chloroplast.fasta
	fi




	if [ -s Metaxa.out1.mitochondria.fasta ]; then
	sed -e 's/ .*//g' < Metaxa.out1.mitochondria.fasta | sed -e 's/_COMPLETE//g' > Metaxa.out.mitochondria.fasta
	rm Metaxa.out1.mitochondria.fasta

		if [ -s Metaxa.out.mitochondria.fasta ];then
		echo ""
		echo "# Deunique sequences (Metaxa.out.mitochondria.fasta) (sequences were uniqued prior to Metaxa2)"

		mothur "#deunique.seqs(fasta=Metaxa.out.mitochondria.fasta, name=$names)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""	
			fi
		fi
	else 
		rm Metaxa.out1.mitochondria.fasta
	fi


#Metaxa2 FINISHED!!!
			if [ -e Metaxa.out.bacteria.redundant.fasta ] || [ -e Metaxa.out.mitochondria.redundant.fasta ] || [ -e Metaxa.out.chloroplast.redundant.fasta ] || [ -e Metaxa.out.eukaryota.redundant.fasta ] || [ -e Metaxa.out.archaea.redundant.fasta ]; then
				touch ${USER_HOME}/.var_babitas/GeneX_finished.txt
				echo ""
				echo "##########################"
				echo "DONE"
				echo "#############################"
				echo "Metaxa2 finished"
				echo "###################################"
				echo "You may close this window now!"
			else
				echo "ERROR occurred, redundant output NOT FOUND" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			fi
fi
fi







##################################################
##################################################
################# CUT sequences ##################
##################################################
##################################################
if grep -q 'CUT' ${USER_HOME}/.var_babitas/workflow.txt; then

echo ""
echo "### Cutting sequences with mothur ###"
echo ""

#Set variables
	if [ -e ${USER_HOME}/.var_babitas/RemoveLast.txt ]; then
		RemoveLast=$(cat ${USER_HOME}/.var_babitas/RemoveLast.txt)
		echo "RemoveLast="$RemoveLast
	fi

	if [ -e ${USER_HOME}/.var_babitas/KeepFirst.txt ]; then
		KeepFirst=$(cat ${USER_HOME}/.var_babitas/KeepFirst.txt)
		echo "KeepFirst="$KeepFirst
	fi

	if [ -e ${USER_HOME}/.var_babitas/MinLen.txt ]; then
		MinLen=$(cat ${USER_HOME}/.var_babitas/MinLen.txt)
		echo "MinLen="$MinLen
	fi

	if [ -e ${USER_HOME}/.var_babitas/MaxLen.txt ]; then
		MaxLen=$(cat ${USER_HOME}/.var_babitas/MaxLen.txt)
		echo "MaxLen="$MaxLen
	fi

		
echo ""
echo ""
echo ""

#KeepFirst, RemoveLast, MinLen, MaxLen, RC
if [ -e ${USER_HOME}/.var_babitas/KeepFirst.txt ] && [ -e ${USER_HOME}/.var_babitas/RemoveLast.txt ] && [ -e ${USER_HOME}/.var_babitas/MinLen.txt ] && [ -e ${USER_HOME}/.var_babitas/MaxLen.txt ] && [ -e ${USER_HOME}/.var_babitas/rc.txt ]; then

	mothur "#trim.seqs(fasta=$input, flip=T, keepfirst=$KeepFirst, removelast=$RemoveLast, minlength=$MinLen, maxlength=$MaxLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/GeneX_finished.txt
			fi


#KeepFirst, RemoveLast, MinLen, MaxLen
else if [ -e ${USER_HOME}/.var_babitas/KeepFirst.txt ] && [ -e ${USER_HOME}/.var_babitas/RemoveLast.txt ] && [ -e ${USER_HOME}/.var_babitas/MinLen.txt ] && [ -e ${USER_HOME}/.var_babitas/MaxLen.txt ]; then

	mothur "#trim.seqs(fasta=$input, keepfirst=$KeepFirst, removelast=$RemoveLast, minlength=$MinLen, maxlength=$MaxLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/GeneX_finished.txt
			fi


#KeepFirst, RemoveLast, MinLen, RC
else if [ -e ${USER_HOME}/.var_babitas/KeepFirst.txt ] && [ -e ${USER_HOME}/.var_babitas/RemoveLast.txt ] && [ -e ${USER_HOME}/.var_babitas/MinLen.txt ] && [ -e ${USER_HOME}/.var_babitas/MaxLen.txt ] && [ -e ${USER_HOME}/.var_babitas/rc.txt ]; then

	mothur "#trim.seqs(fasta=$input, flip=T, keepfirst=$KeepFirst, removelast=$RemoveLast, minlength=$MinLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/GeneX_finished.txt
			fi


#KeepFirst, RemoveLast, MinLen
else if [ -e ${USER_HOME}/.var_babitas/KeepFirst.txt ] && [ -e ${USER_HOME}/.var_babitas/RemoveLast.txt ] && [ -e ${USER_HOME}/.var_babitas/MinLen.txt ]; then

	mothur "#trim.seqs(fasta=$input, keepfirst=$KeepFirst, removelast=$RemoveLast, minlength=$MinLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/GeneX_finished.txt
			fi


#KeepFirst, RemoveLast, MaxLen, RC
else if [ -e ${USER_HOME}/.var_babitas/KeepFirst.txt ] && [ -e ${USER_HOME}/.var_babitas/RemoveLast.txt ] && [ -e ${USER_HOME}/.var_babitas/MaxLen.txt ] && [ -e ${USER_HOME}/.var_babitas/rc.txt ]; then

	mothur "#trim.seqs(fasta=$input, flip=T, keepfirst=$KeepFirst, removelast=$RemoveLast, maxlength=$MaxLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/GeneX_finished.txt
			fi


#KeepFirst, RemoveLast, MaxLen
else if [ -e ${USER_HOME}/.var_babitas/KeepFirst.txt ] && [ -e ${USER_HOME}/.var_babitas/RemoveLast.txt ] && [ -e ${USER_HOME}/.var_babitas/MaxLen.txt ]; then

	mothur "#trim.seqs(fasta=$input, keepfirst=$KeepFirst, removelast=$RemoveLast, maxlength=$MaxLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/GeneX_finished.txt
			fi


#RemoveLast, MinLen, MaxLen, RC
else if [ -e ${USER_HOME}/.var_babitas/RemoveLast.txt ] && [ -e ${USER_HOME}/.var_babitas/MinLen.txt ] && [ -e ${USER_HOME}/.var_babitas/MaxLen.txt ] && [ -e ${USER_HOME}/.var_babitas/rc.txt ]; then

	mothur "#trim.seqs(fasta=$input, flip=T, removelast=$RemoveLast, minlength=$MinLen, maxlength=$MaxLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/GeneX_finished.txt
			fi


#RemoveLast, MinLen, MaxLen
else if [ -e ${USER_HOME}/.var_babitas/RemoveLast.txt ] && [ -e ${USER_HOME}/.var_babitas/MinLen.txt ] && [ -e ${USER_HOME}/.var_babitas/MaxLen.txt ]; then

	mothur "#trim.seqs(fasta=$input, removelast=$RemoveLast, minlength=$MinLen, maxlength=$MaxLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/GeneX_finished.txt
			fi


#KeepFirst, MinLen, MaxLen, RC
else if [ -e ${USER_HOME}/.var_babitas/KeepFirst.txt ] && [ -e ${USER_HOME}/.var_babitas/MinLen.txt ] && [ -e ${USER_HOME}/.var_babitas/MaxLen.txt ] && [ -e ${USER_HOME}/.var_babitas/rc.txt ]; then

	mothur "#trim.seqs(fasta=$input, flip=T, keepfirst=$KeepFirst, minlength=$MinLen, maxlength=$MaxLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/GeneX_finished.txt
			fi


#KeepFirst, MinLen, MaxLen
else if [ -e ${USER_HOME}/.var_babitas/KeepFirst.txt ] && [ -e ${USER_HOME}/.var_babitas/MinLen.txt ] && [ -e ${USER_HOME}/.var_babitas/MaxLen.txt ]; then

	mothur "#trim.seqs(fasta=$input, keepfirst=$KeepFirst, minlength=$MinLen, maxlength=$MaxLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/GeneX_finished.txt
			fi


#KeepFirst, RemoveLast, RC
else if [ -e ${USER_HOME}/.var_babitas/KeepFirst.txt ] && [ -e ${USER_HOME}/.var_babitas/RemoveLast.txt ] && [ -e ${USER_HOME}/.var_babitas/rc.txt ]; then

	mothur "#trim.seqs(fasta=$input, flip=T, keepfirst=$KeepFirst, removelast=$RemoveLast)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/GeneX_finished.txt
			fi


#KeepFirst, RemoveLast
else if [ -e ${USER_HOME}/.var_babitas/KeepFirst.txt ] && [ -e ${USER_HOME}/.var_babitas/RemoveLast.txt ]; then

	mothur "#trim.seqs(fasta=$input, keepfirst=$KeepFirst, removelast=$RemoveLast)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/GeneX_finished.txt
			fi


#KeepFirst, MinLen, RC
else if [ -e ${USER_HOME}/.var_babitas/KeepFirst.txt ] && [ -e ${USER_HOME}/.var_babitas/MinLen.txt ] && [ -e ${USER_HOME}/.var_babitas/rc.txt ]; then

	mothur "#trim.seqs(fasta=$input, flip=T, keepfirst=$KeepFirst, minlength=$MinLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/GeneX_finished.txt
			fi


#KeepFirst, MinLen
else if [ -e ${USER_HOME}/.var_babitas/KeepFirst.txt ] && [ -e ${USER_HOME}/.var_babitas/MinLen.txt ]; then

	mothur "#trim.seqs(fasta=$input, keepfirst=$KeepFirst, minlength=$MinLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/GeneX_finished.txt
			fi


#KeepFirst, MaxLen, RC
else if [ -e ${USER_HOME}/.var_babitas/KeepFirst.txt ] && [ -e ${USER_HOME}/.var_babitas/MaxLen.txt ] && [ -e ${USER_HOME}/.var_babitas/rc.txt ]; then

	mothur "#trim.seqs(fasta=$input, flip=T, keepfirst=$KeepFirst, maxlength=$MaxLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/GeneX_finished.txt
			fi


#KeepFirst, MaxLen
else if [ -e ${USER_HOME}/.var_babitas/KeepFirst.txt ] && [ -e ${USER_HOME}/.var_babitas/MaxLen.txt ] && [ -e ${USER_HOME}/.var_babitas/rc.txt ]; then

	mothur "#trim.seqs(fasta=$input, keepfirst=$KeepFirst, maxlength=$MaxLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/GeneX_finished.txt
			fi


#RemoveLast, MinLen, RC
else if [ -e ${USER_HOME}/.var_babitas/RemoveLast.txt ] && [ -e ${USER_HOME}/.var_babitas/MinLen.txt ] && [ -e ${USER_HOME}/.var_babitas/rc.txt ]; then

	mothur "#trim.seqs(fasta=$input, flip=T, removelast=$RemoveLast, minlength=$MinLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/GeneX_finished.txt
			fi


#RemoveLast, MinLen
else if [ -e ${USER_HOME}/.var_babitas/RemoveLast.txt ] && [ -e ${USER_HOME}/.var_babitas/MinLen.txt ]; then

	mothur "#trim.seqs(fasta=$input, removelast=$RemoveLast, minlength=$MinLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/GeneX_finished.txt
			fi


#RemoveLast, MaxLen, RC
else if [ -e ${USER_HOME}/.var_babitas/RemoveLast.txt ] && [ -e ${USER_HOME}/.var_babitas/MaxLen.txt ] && [ -e ${USER_HOME}/.var_babitas/rc.txt ]; then

	mothur "#trim.seqs(fasta=$input, flip=T, removelast=$RemoveLast, maxlength=$MaxLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/GeneX_finished.txt
			fi


#RemoveLast, MaxLen
else if [ -e ${USER_HOME}/.var_babitas/RemoveLast.txt ] && [ -e ${USER_HOME}/.var_babitas/MaxLen.txt ]; then

	mothur "#trim.seqs(fasta=$input, removelast=$RemoveLast, maxlength=$MaxLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/GeneX_finished.txt
			fi


#MinLen, MaxLen, RC
else if [ -e ${USER_HOME}/.var_babitas/MinLen.txt ] && [ -e ${USER_HOME}/.var_babitas/MaxLen.txt ] && [ -e ${USER_HOME}/.var_babitas/rc.txt ]; then

	mothur "#trim.seqs(fasta=$input, flip=T, minlength=$MinLen, maxlength=$MaxLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/GeneX_finished.txt
			fi


#MinLen, MaxLen
else if [ -e ${USER_HOME}/.var_babitas/MinLen.txt ] && [ -e ${USER_HOME}/.var_babitas/MaxLen.txt ]; then

	mothur "#trim.seqs(fasta=$input, minlength=$MinLen, maxlength=$MaxLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/GeneX_finished.txt
			fi




#KeepFirst, RC
else if [ -e ${USER_HOME}/.var_babitas/KeepFirst.txt ] && [ -e ${USER_HOME}/.var_babitas/rc.txt ]; then

	mothur "#trim.seqs(fasta=$input, flip=T, keepfirst=$KeepFirst)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/GeneX_finished.txt
			fi


#KeepFirst
else if [ -e ${USER_HOME}/.var_babitas/KeepFirst.txt ]; then

	mothur "#trim.seqs(fasta=$input, keepfirst=$KeepFirst)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/GeneX_finished.txt
			fi

#RemoveLast, RC
else if [ -e ${USER_HOME}/.var_babitas/RemoveLast.txt ] && [ -e ${USER_HOME}/.var_babitas/rc.txt ]; then

	mothur "#trim.seqs(fasta=$input, flip=T, removelast=$RemoveLast)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/GeneX_finished.txt
			fi


#RemoveLast
else if [ -e ${USER_HOME}/.var_babitas/RemoveLast.txt ]; then

	mothur "#trim.seqs(fasta=$input, removelast=$RemoveLast)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/GeneX_finished.txt
			fi


#MinLen, RC
else if [ -e ${USER_HOME}/.var_babitas/MinLen.txt ] && [ -e ${USER_HOME}/.var_babitas/rc.txt ]; then

	mothur "#trim.seqs(fasta=$input, flip=T, minlength=$MinLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/GeneX_finished.txt
			fi


#MinLen
else if [ -e ${USER_HOME}/.var_babitas/MinLen.txt ]; then

	mothur "#trim.seqs(fasta=$input, minlength=$MinLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/GeneX_finished.txt
			fi


#MaxLen, RC
else if  [ -e ${USER_HOME}/.var_babitas/MaxLen.txt ] && [ -e ${USER_HOME}/.var_babitas/rc.txt ]; then

	mothur "#trim.seqs(fasta=$input, flip=T, maxlength=$MaxLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/GeneX_finished.txt
			fi


#MaxLen
else if  [ -e ${USER_HOME}/.var_babitas/MaxLen.txt ]; then

	mothur "#trim.seqs(fasta=$input, maxlength=$MaxLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/GeneX_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/GeneX_finished.txt
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
				fi
			fi
		fi
	fi
fi






#Delete mothur_logfiles
if ls mothur.*.logfile 1> /dev/null 2>&1; then
	rm *.logfile
fi







#Delete unnecessary files
if [ -e "${USER_HOME}/.var_babitas/ITSx_selected_orgs2" ]; then
rm -r ${USER_HOME}/.var_babitas/ITSx_selected_orgs2
fi
if [ -e "${USER_HOME}/.var_babitas/ITSx_region.txt" ]; then
rm ${USER_HOME}/.var_babitas/ITSx_region.txt
fi
if [ -e "${USER_HOME}/.var_babitas/ITSx_cpus.txt" ]; then
rm ${USER_HOME}/.var_babitas/ITSx_cpus.txt
fi
if [ -e "${USER_HOME}/.var_babitas/ITSx_All_groups.txt" ]; then
rm ${USER_HOME}/.var_babitas/ITSx_All_groups.txt
fi
if [ -e "${USER_HOME}/.var_babitas/ITSx_Fungi.txt" ]; then
rm ${USER_HOME}/.var_babitas/ITSx_Fungi.txt
fi
if [ -e "${USER_HOME}/.var_babitas/ITSx_Custom.txt" ]; then
rm ${USER_HOME}/.var_babitas/ITSx_Custom.txt
fi
if [ -e "${USER_HOME}/.var_babitas/ITSx_custom_regions" ]; then
rm -r ${USER_HOME}/.var_babitas/ITSx_custom_regions
fi
if [ -e "${USER_HOME}/.var_babitas/r1.txt" ]; then
rm ${USER_HOME}/.var_babitas/r1.txt
fi
if [ -e "${USER_HOME}/.var_babitas/r2.txt" ]; then
rm ${USER_HOME}/.var_babitas/r2.txt
fi
if [ -e "${USER_HOME}/.var_babitas/r3.txt" ]; then
rm ${USER_HOME}/.var_babitas/r3.txt
fi
if [ -e "${USER_HOME}/.var_babitas/r4.txt" ]; then
rm ${USER_HOME}/.var_babitas/r4.txt
fi
if [ -e "${USER_HOME}/.var_babitas/r5.txt" ]; then
rm ${USER_HOME}/.var_babitas/r5.txt
fi
if [ -e "${USER_HOME}/.var_babitas/r6.txt" ]; then
rm ${USER_HOME}/.var_babitas/r6.txt
fi
if [ -e "${USER_HOME}/.var_babitas/r7.txt" ]; then
rm ${USER_HOME}/.var_babitas/r7.txt
fi
if [ -e "${USER_HOME}/.var_babitas/r8.txt" ]; then
rm ${USER_HOME}/.var_babitas/r8.txt
fi
if [ -e "${USER_HOME}/.var_babitas/r9.txt" ]; then
rm ${USER_HOME}/.var_babitas/r9.txt
fi
if [ -e "${USER_HOME}/.var_babitas/r10.txt" ]; then
rm ${USER_HOME}/.var_babitas/r10.txt
fi
if [ -e "${USER_HOME}/.var_babitas/r11.txt" ]; then
rm ${USER_HOME}/.var_babitas/r11.txt
fi
if [ -e "${USER_HOME}/.var_babitas/r12.txt" ]; then
rm ${USER_HOME}/.var_babitas/r12.txt
fi
if [ -e "${USER_HOME}/.var_babitas/r13.txt" ]; then
rm ${USER_HOME}/.var_babitas/r13.txt
fi
if [ -e "${USER_HOME}/.var_babitas/r14.txt" ]; then
rm ${USER_HOME}/.var_babitas/r14.txt
fi
if [ -e "${USER_HOME}/.var_babitas/HMM.txt" ]; then
rm ${USER_HOME}/.var_babitas/HMM.txt
fi
if [ -e "${USER_HOME}/.var_babitas/profiles.txt" ]; then
rm ${USER_HOME}/.var_babitas/profiles.txt
fi
if [ -e "${USER_HOME}/.var_babitas/program.txt" ]; then
rm ${USER_HOME}/.var_babitas/program.txt
fi
if [ -e "${USER_HOME}/.var_babitas/target_reg.txt" ]; then
rm ${USER_HOME}/.var_babitas/target_reg.txt
fi
if [ -e "${USER_HOME}/.var_babitas/Profiles" ]; then
rm -r ${USER_HOME}/.var_babitas/Profiles
fi
if [ -e "error.log" ]; then
rm error.log
fi

