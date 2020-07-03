#!/bin/bash 



echo "### Generate circular consensus sequences (CCS) ###"
echo ""
echo "When using the incorporated tools, please cite as follows:"
echo ""
echo "pbccs (v2.0.2) - github.com/PacificBiosciences/unanimity; licence - github.com/PacificBiosciences/unanimity/blob/master/LICENSE"
echo "Copyright (c) 2016, Pacific Biosciences of California"
echo ""
echo "bax2bam (v0.08) - github.com/PacificBiosciences/pitchfork; licence - github.com/PacificBiosciences/pitchfork/blob/master/LICENSE"
echo "Copyright (c) 2016, Pacific Biosciences of California"
echo ""
echo "BBMap (v36.02) - github.com/BioInfoTools/BBMap; licence - github.com/BioInfoTools/BBMap/blob/master/license.txt"
echo "BBTools Copyright (c) 2014, The Regents of the University of California, through Lawrence Berkeley National Laboratory (subject to receipt of any required approvals from the U.S. Dept. of Energy)."
echo ""
echo "samtools (v1.3.1) - Li, H., et al., 2009. The Sequence Alignment/Map format and SAMtools. Bioinformatics 25, 2078-2079."
echo "Copyright (C) 2016 Genome Research Ltd."

echo "________________________________________________"

USER_HOME=$(eval echo ~${SUDO_USER})



#Set working directory
if [ -e ${USER_HOME}/.var_babitas/bax_input.txt ]; then
WorkingDirectory=$(awk 'BEGIN{FS=OFS="/"} NF{NF--};1' < ${USER_HOME}/.var_babitas/bax_input.txt | uniq)

	else if [ -e ${USER_HOME}/.var_babitas/bam_input.txt ]; then
	WorkingDirectory=$(awk 'BEGIN{FS=OFS="/"} NF{NF--};1' < ${USER_HOME}/.var_babitas/bam_input.txt)
	fi
fi


cd $WorkingDirectory
		if [ "$?" = "0" ]; then
 		echo "Working directory = "$WorkingDirectory
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/CCS_error.txt && echo "ERROR occured: Unable to open working directory" 1>&2 && echo "Close this window" && exit 1
		fi

#Echo CCS parameters
MinSNR=$(cat ${USER_HOME}/.var_babitas/MinSNR.txt)
MinRSc=$(cat ${USER_HOME}/.var_babitas/MinRSc.txt)
MinLen=$(cat ${USER_HOME}/.var_babitas/MinLen.txt)
MaxLen=$(cat ${USER_HOME}/.var_babitas/MaxLen.txt)
MinPass=$(cat ${USER_HOME}/.var_babitas/MinPass.txt)
MinAcc=$(cat ${USER_HOME}/.var_babitas/MinAcc.txt)
Zscore=$(cat ${USER_HOME}/.var_babitas/Zscore.txt)
MaxDF=$(cat ${USER_HOME}/.var_babitas/MaxDF.txt)

#Echo CCS parameters
echo "Minimum SNR = "$MinSNR
echo "Minimum Read Score = "$MinRSc
echo "Minimum Length = "$MinLen
echo "Maximum Length = "$MaxLen
echo "Minimum Number of Passes = "$MinPass
echo "Minimum Predicted Accuracy = "$MinAcc
echo "Minimum Z Score = "$Zscore
echo "Maximum Dropped Fraction = "$MaxDF
echo ""
	

#############################################
#############################################
############### bax.h5 to bam ###############
############### and make CCS ################
#############################################
if [ -e ${USER_HOME}/.var_babitas/bax_input.txt ]; then


#Set bax files variables
cat ${USER_HOME}/.var_babitas/bax_input.txt | sed '/^\s*$/d' | awk '{filename = sprintf("bax%d.temp", NR); print > filename; close(filename)}'

bax1=$(cat bax1.temp | tr "\n" " " | tr "\r" " " | sed -e 's/ //g')
bax2=$(cat bax2.temp | tr "\n" " " | tr "\r" " " | sed -e 's/ //g')
bax3=$(cat bax3.temp | tr "\n" " " | tr "\r" " " | sed -e 's/ //g')

rm bax1.temp
	if [ "$?" = "0" ]; then
	echo ""
	else
	touch ${USER_HOME}/.var_babitas/CCS_error.txt && echo "ERROR occured: make sure you have selected all three bax.h5 files" 1>&2 && echo "Close this window" && exit 1
	fi
rm bax2.temp
	if [ "$?" = "0" ]; then
	echo ""
	else
	touch ${USER_HOME}/.var_babitas/CCS_error.txt && echo "ERROR occured: make sure you have selected all three bax.h5 files" 1>&2 && echo "Close this window" && exit 1
	fi
rm bax3.temp
	if [ "$?" = "0" ]; then
	echo ""
	else
	touch ${USER_HOME}/.var_babitas/CCS_error.txt && echo "ERROR occured: make sure you have selected all three bax.h5 files" 1>&2 && echo "Close this window" && exit 1
	fi


#bax2bam
echo "# Converting bax to bam"
echo "bax2bam $bax1 $bax2 $bax3 -o bax2bam --subread"
echo "..."


cd $WorkingDirectory
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/CCS_error.txt && echo "ERROR occured: init-file" 1>&2 && echo "Close this window" && exit 1
		fi

#Export bax2bam libraries so that the program can work
export LD_LIBRARY_PATH=/dependencies/pitchfork/deployment/lib:$LD_LIBRARY_PATH
export PATH=/dependencies/pitchfork/deployment/bin:$PATH

#Run bax2bam
bax2bam $bax1 $bax2 $bax3 -o bax2bam --subread
		if [ "$?" = "0" ]; then
		echo "# done, output = bax2bam.subreads.bam"
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/CCS_error.txt && echo "ERROR occured; bax2bam program not found" 1>&2 && echo "Close this window" && exit 1
		fi




#bam to CCS
echo "# Generating CCS"
echo "ccs --minSnr=$MinSNR --minReadScore=$MinRSc --minLength=$MinLen --maxLength=$MaxLen --minPasses=$MinPass --minPredictedAccuracy=$MinAcc --minZScore=$Zscore --maxDropFraction=$MaxDF --force bax2bam.subreads.bam CCS_fullPass$MinPass.bam"

/dependencies/unanimity/build/ccs --minSnr=$MinSNR --minReadScore=$MinRSc --minLength=$MinLen --maxLength=$MaxLen --minPasses=$MinPass --minPredictedAccuracy=$MinAcc --minZScore=$Zscore --maxDropFraction=$MaxDF --force bax2bam.subreads.bam CCS_fullPass$MinPass.bam
		if [ "$?" = "0" ]; then

		#CCS.bam to two fastq files
		echo ""
		echo "# CCS.bam to fastq"
		echo "samtools bam2fq CCS_fullPass$MinPass.bam > CCS_fullPass$MinPass.fastq"
		samtools bam2fq CCS_fullPass$MinPass.bam > CCS_fullPass$MinPass.fastq
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/CCS_error.txt && echo "### samtools ERROR ###" 1>&2 && echo "Close this window" && exit 1
			fi


		echo "# CCS.bam to fastq with reformatted quality scores (0-41)"
		echo "# Using BBMap"
		echo ""
		echo "reformat.sh in=CCS_fullPass$MinPass.fastq out=reformatCCS_fullPass$MinPass.fastq qin=33 maxcalledquality=41 overwrite=true"

		${USER_HOME}/.babitassh/bbmap/reformat.sh in=CCS_fullPass$MinPass.fastq out=reformatCCS_fullPass$MinPass.fastq qin=33 maxcalledquality=41 overwrite=true
			if [ "$?" = "0" ]; then
			echo "# CCS.bam file converted to fastq (reformatCCS_fullPass$MinPass.fastq)"
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/CCS_error.txt && echo "# ERROR #" 1>&2 && echo "Close this window" && exit 1
			fi




		touch ${USER_HOME}/.var_babitas/CCS_finished.txt
		echo ""
		echo "##########################"
		echo "DONE"
		echo "############################"
		echo "CCS finished"
		echo "##############################"
		echo "output = CCS_fullPass$MinPass.bam"
		echo "output = CCS_fullPass$MinPass.fastq"
		echo "output = reformatCCS_fullPass$MinPass.fastq"
		echo "################################"
		echo "You may close this window now!"
		else
		touch ${USER_HOME}/.var_babitas/CCS_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi

fi




#############################################
#############################################
########## make CCS from BAM file ###########
#############################################
#############################################
if [ -e ${USER_HOME}/.var_babitas/bam_input.txt ]; then

bam_input=$(cat ${USER_HOME}/.var_babitas/bam_input.txt)
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/CCS_error.txt && echo "ERROR occured; no input" 1>&2 && echo "Close this window" && exit 1
		fi

#bam to CCS
echo "# Generating CCS"
echo "ccs --minSnr=$MinSNR --minReadScore=$MinRSc --minLength=$MinLen --maxLength=$MaxLen --minPasses=$MinPass --minPredictedAccuracy=$MinAcc --minZScore=$Zscore --maxDropFraction=$MaxDF --force $bam_input CCS_fullPass$MinPass.bam"

/dependencies/unanimity/build/ccs --minSnr=$MinSNR --minReadScore=$MinRSc --minLength=$MinLen --maxLength=$MaxLen --minPasses=$MinPass --minPredictedAccuracy=$MinAcc --minZScore=$Zscore --maxDropFraction=$MaxDF --force $bam_input CCS_fullPass$MinPass.bam
		if [ "$?" = "0" ]; then

		#CCS.bam to two fastq files
		echo ""
		echo "# CCS.bam to fastq"
		echo "samtools bam2fq CCS_fullPass$MinPass.bam > CCS_fullPass$MinPass.fastq"
		samtools bam2fq CCS_fullPass$MinPass.bam > CCS_fullPass$MinPass.fastq
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/CCS_error.txt && echo "### samtools ERROR ###" 1>&2 && echo "Close this window" && exit 1
			fi


		
		echo "# CCS.bam to fastq with reformatted quality scores (0-41)"
		echo "# Using BBMap"
		echo ""
		echo "reformat.sh in=CCS_fullPass$MinPass.fastq out=reformatCCS_fullPass$MinPass.fastq qin=33 maxcalledquality=41 overwrite=true"

		${USER_HOME}/.babitassh/bbmap/reformat.sh in=CCS_fullPass$MinPass.fastq out=reformatCCS_fullPass$MinPass.fastq qin=33 maxcalledquality=41 overwrite=true
			if [ "$?" = "0" ]; then
			echo "# CCS.bam file converted to fastq (reformatCCS_fullPass$MinPass.fastq)"
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/CCS_error.txt && echo "# ERROR #" 1>&2 && echo "Close this window" && exit 1
			fi



		touch ${USER_HOME}/.var_babitas/CCS_finished.txt
		echo ""
		echo "##########################"
		echo "DONE"
		echo "############################"
		echo "CCS finished"
		echo "##############################"
		echo "output = CCS_fullPass$MinPass.bam"
		echo "output = CCS_fullPass$MinPass.fastq"
		echo "output = reformatCCS_fullPass$MinPass.fastq"
		echo "################################"
		echo "You may close this window now!"
		else
		touch ${USER_HOME}/.var_babitas/CCS_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi

fi

