#!/bin/bash 


USER_HOME=$(eval echo ~${SUDO_USER})

#Set working directory
if [ -e ${USER_HOME}/.var_babitas/bam_input.txt ]; then
WorkingDirectory=$(awk 'BEGIN{FS=OFS="/"} NF{NF--};1' < ${USER_HOME}/.var_babitas/bam_input.txt)

	else if [ -e ${USER_HOME}/.var_babitas/sff_input.txt ]; then
	WorkingDirectory=$(awk 'BEGIN{FS=OFS="/"} NF{NF--};1' < ${USER_HOME}/.var_babitas/sff_input.txt)
	fi
fi


cd $WorkingDirectory
		if [ "$?" = "0" ]; then
 		echo "Working directory = "$WorkingDirectory
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/tools_error.txt && echo "ERROR occured: Unable to open working directory" 1>&2 && echo "Close this window" && exit 1
		fi


####################
####################
### bam to fastq ###
####################
####################
if [ -e ${USER_HOME}/.var_babitas/bam_input.txt ]; then

echo "### Converting BAM to FASTQ format ###"
echo ""
echo "samtools - Li, H., et al., 2009. The Sequence Alignment/Map format and SAMtools. Bioinformatics 25, 2078-2079."
echo "samtools 1.3.1"
echo "Using htslib 1.3.1"
echo "Copyright (C) 2016 Genome Research Ltd."
echo "________________________________________________"
echo ""


#input
bam_input=$(cat ${USER_HOME}/.var_babitas/bam_input.txt  | sed -e 's/.bam//')
		if [ "$?" = "0" ]; then
 		echo ""
		else
		touch ${USER_HOME}/.var_babitas/tools_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi

#Convert bam to fastq
echo "samtools bam2fq $bam_input.bam > $bam_input.fastq"

samtools bam2fq $bam_input.bam > $bam_input.fastq
		if [ "$?" = "0" ]; then
		touch ${USER_HOME}/.var_babitas/tools_finished.txt
		echo ""
		echo "##########################"
		echo "DONE"
		echo "##############################"
		echo "output = $bam_input.fastq"
		echo "################################"
		echo "You may close this window now!"
		else
		touch ${USER_HOME}/.var_babitas/tools_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi




####################
####################
### sff to fastq ###
####################
####################
else if [ -e ${USER_HOME}/.var_babitas/sff_input.txt ]; then

echo "### Converting SFF to FASTQ format ###"
echo ""
echo "mothur - Schloss, P.D., et al., 2009. Introducing mothur: Open-Source, Platform-Independent, Community-Supported Software for Describing and Comparing Microbial Communities. Applied and Environmental Microbiology 75, 7537-7541."
echo "Distributed under the GNU General Public License version 2 by the Free Software Foundation"
echo "www.mothur.org"
echo "________________________________________________"
echo ""


#input
sff_input=$(cat ${USER_HOME}/.var_babitas/sff_input.txt | sed -e 's/.sff//')
		if [ "$?" = "0" ]; then
 		echo ""
		else
		touch ${USER_HOME}/.var_babitas/tools_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi

#Convert sff to fastq
mothur "#sffinfo(sff=$sff_input.sff)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/tools_error.txt && exit
		else
		echo ""
		fi


#Converting fasta and qual back to fastq

mothur "#make.fastq(fasta=$sff_input.fasta, qfile=$sff_input.qual)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/tools_error.txt && exit
		else
		touch ${USER_HOME}/.var_babitas/tools_finished.txt
		echo ""
		echo "##########################"
		echo "DONE"
		echo "##############################"
		echo "output = $sff_input.fastq"
		echo "################################"
		echo "You may close this window now!"
		fi

fi
fi




