#!/bin/bash

echo "### Quality filtering/assembling ###"
echo ""
echo "When using the incorporated tools, please cite as follows:"

echo "mothur - Schloss, P.D., et al., 2009. Introducing mothur: Open-Source, Platform-Independent, Community-Supported Software for Describing and Comparing Microbial Communities. Applied and Environmental Microbiology 75, 7537-7541."
echo "Distributed under the GNU General Public License version 2 by the Free Software Foundation"
echo "www.mothur.org"
echo ""
echo "vsearch - github.com/torognes/vsearch"
echo "Copyright (C) 2014-2015, Torbjorn Rognes, Frederic Mahe and Tomas Flouri."
echo "Distributed under the GNU General Public License version 3 by the Free Software Foundation"
echo ""
echo "PANDAseq - Masella, A.P., et al., 2012. PANDAseq: PAired-eND Assembler for Illumina sequences. BMC Bioinformatics 13."
echo "Distributed under the GNU General Public License version 3 by the Free Software Foundation"
echo "github.com/neufeld/pandaseq"
echo ""
echo "FLASH - Magoc, T., Salzberg, S.L., 2011. FLASH: fast length adjustment of short reads to improve genome assemblies. Bioinformatics 27, 2957-2963."
echo "Distributed under the GNU General Public License version 3 by the Free Software Foundation"
echo "ccb.jhu.edu/software/FLASH/"
echo "________________________________________________"




#Set working directory
USER_HOME=$(eval echo ~${SUDO_USER})

WorkingDirectory=$(awk 'BEGIN{FS=OFS="/"} NF{NF--};1' < ${USER_HOME}/.var_babitas/R1_location.txt)
cd $WorkingDirectory

#Set R1 and R2.fastq files as variables
R1fastq=$(cat ${USER_HOME}/.var_babitas/R1_location.txt)
R2fastq=$(cat ${USER_HOME}/.var_babitas/R2_location.txt)

#Convert fastq to PHRED+33
if [ -e ${USER_HOME}/.var_babitas/phred64.txt ]; then
vsearch --fastq_convert $R1fastq --fastq_ascii 64 --fastq_asciiout 33 --fastqout R1_33.fastq
			if [ "$?" = "0" ]; then
 			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi
			
vsearch --fastq_convert $R2fastq --fastq_ascii 64 --fastq_asciiout 33 --fastqout R2_33.fastq
			if [ "$?" = "0" ]; then
 			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi
			
R1fastq=$(find ${USER_HOME} -name "R1_33.fastq")
R2fastq=$(find ${USER_HOME} -name "R2_33.fastq")
	else
	R1fastq=$(cat ${USER_HOME}/.var_babitas/R1_location.txt)
	R2fastq=$(cat ${USER_HOME}/.var_babitas/R2_location.txt)
fi

R1_size=$(echo $(cat $R1fastq | wc -l) / 4 | bc)

echo "input R1 = $R1fastq"
echo "input R2 = $R2fastq"
echo "Input sequence count = $R1_size"
echo "Working directory =" $WorkingDirectory
echo ""

#############################################################################
#############################################################################
###First perform quality TRIMMING with mothur, then ASSEMBLE with PANDAseq###
#############################################################################
#############################################################################
if grep -q 'First perform quality TRIMMING with mothur, then ASSEMBLE with PANDAseq' ${USER_HOME}/.var_babitas/workflow_chosen.txt; then

echo "## Workflow = First perform quality TRIMMING with mothur, then ASSEMBLE with PANDAseq ##"
echo ""

#Set trimming options
qwindowaverage=$(cat ${USER_HOME}/.var_babitas/qwindowaverage.txt)
qwindowsize=$(cat ${USER_HOME}/.var_babitas/qwindowsize.txt)
minlength=$(cat ${USER_HOME}/.var_babitas/minlenght.txt)
maxambig=$(cat ${USER_HOME}/.var_babitas/maxambig.txt)
maxhomop=$(cat ${USER_HOME}/.var_babitas/maxhomop.txt)
processors=$(cat ${USER_HOME}/.var_babitas/processors.txt)

#Set assembling options
p_minOverlap=$(cat ${USER_HOME}/.var_babitas/p_minOverlap.txt)
p_maxOverlap=$(cat ${USER_HOME}/.var_babitas/p_maxOverlap.txt)
p_maxlength=$(cat ${USER_HOME}/.var_babitas/p_maxlength.txt)
p_minphred=$(cat ${USER_HOME}/.var_babitas/p_minphred.txt)
p_minlength=$(cat ${USER_HOME}/.var_babitas/p_minlength.txt)

echo "Trimming options ->"
echo "qwindowaverage =" $qwindowaverage
echo "qwindowsize =" $qwindowsize
echo "minlength =" $minlength
echo "maxambig =" $maxambig
echo "maxhomop =" $maxhomop
echo "processors =" $processors
echo ""

echo "Assembling options ->"
echo "minOverlap =" $p_minOverlap
echo "maxOverlap =" $p_maxOverlap
echo "maxlength =" $p_maxlength
echo "minphred ="  $p_minphred
echo "minlength =" $p_minlength


#Renaming fastq files (needed for PANDAseq assembler)
echo "# Renaming fastq files (needed for PANDAseq assembler) ..."
tr " " "Ã" < $R1fastq > R1r.fastq
mothur "#fastq.info(fastq=R1r.fastq)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
		else
		echo ""
		fi

if [ -e R1r.fastq ]; then
rm R1r.fastq
fi

tr " " "Ã" < $R2fastq > R2r.fastq
mothur "#fastq.info(fastq=R2r.fastq)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
		else
		echo ""
		fi

if [ -e R2r.fastq ]; then
rm R2r.fastq
fi


#Trimming with mothur
echo "# Trimming with mothur ... "

mothur "#trim.seqs(fasta=R1r.fasta, qfile=R1r.qual, qwindowaverage=$qwindowaverage, qwindowsize=$qwindowsize, minlength=$minlength, maxambig=$maxambig, maxhomop=$maxhomop, processors=$processors)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
		else
		echo ""
		fi


mothur "#trim.seqs(fasta=R2r.fasta, qfile=R2r.qual, qwindowaverage=$qwindowaverage, qwindowsize=$qwindowsize, minlength=$minlength, maxambig=$maxambig, maxhomop=$maxhomop, processors=$processors)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
		else
		echo ""
		fi


#Converting fasta and qual back to fastq
mothur "#make.fastq(fasta=R1r.trim.fasta, qfile=R1r.trim.qual)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
		else
		echo ""
		fi

mothur "#make.fastq(fasta=R2r.trim.fasta, qfile=R2r.trim.qual)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
		else
		echo ""
		fi


#Renaming R1 and R2 back to original names so that Pandaseq can work
tr "Ã" " " < R1r.trim.fastq > R1r.trim_x.fastq && tr "_" ":" < R1r.trim_x.fastq > R1r.trim.fastq_nameOK.fastq && rm R1r.trim_x.fastq
tr "Ã" " " < R2r.trim.fastq > R2r.trim_x.fastq && tr "_" ":" < R2r.trim_x.fastq > R2r.trim.fastq_nameOK.fastq && rm R2r.trim_x.fastq

#Sorting out only paired R1 and R2 sequences (singles into separate fastq)
echo "# Sorting out only paired R1 and R2 sequences"
echo "..."

python ${USER_HOME}/.babitassh/fastqCombinePairedEnd.txt R1r.trim.fastq_nameOK.fastq R2r.trim.fastq_nameOK.fastq
			if [ "$?" = "0" ]; then
 			echo "#done (with fastqCombinePairedEnd.py - github.com/enormandeau/Scripts/blob/master/fastqCombinePairedEnd.py - distributed under the GNU General Public License version 3 by the Free Software Foundation)"
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi

#Sorting R1 and R2 sequences to match for assembling
cat R1r.trim.fastq_nameOK.fastq_pairs_R1.fastq | paste - - - - | sort -k1,1 -t " " | tr "\t" "\n" > R1.trim_pairs_sorted_to_assembling.fastq

cat R2r.trim.fastq_nameOK.fastq_pairs_R2.fastq | paste - - - - | sort -k1,1 -t " " | tr "\t" "\n" > R2.trim_pairs_sorted_to_assembling.fastq



#Starting to assemble sequneces with PandaSeq
echo ""
echo "# Assembling sequneces with PandaSeq ..."
echo "pandaseq -f R1.trim_pairs_sorted_to_assembling.fastq -r R2.trim_pairs_sorted_to_assembling.fastq -F -B -o $p_minOverlap -O $p_maxOverlap -L $p_maxlength -C min_phred:$p_minphred -l $p_minlength -g PANDAseq.log > mothurTrim_pandaMerge.fastq"
echo "..."

pandaseq -f R1.trim_pairs_sorted_to_assembling.fastq -r R2.trim_pairs_sorted_to_assembling.fastq -F -B -o $p_minOverlap -O $p_maxOverlap -L $p_maxlength -C min_phred:$p_minphred -l $p_minlength -g PANDAseq.log > mothurTrim_pandaMerge.fastq
			if [ "$?" = "0" ]; then
 			echo "Assembling sequneces with PANDAseq, done"
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi

#Delete scrap
rm R1r.fasta
rm R1r.qual
rm R2r.fasta
rm R2r.qual
rm R1r.scrap.fasta
rm R1r.scrap.qual
rm R2r.scrap.fasta
rm R2r.scrap.qual
rm R1r.trim.fasta
rm R1r.trim.qual
rm R2r.trim.fasta
rm R2r.trim.qual
rm R1r.trim.fastq
rm R2r.trim.fastq




	if [ -e mothurTrim_pandaMerge.fastq ]; then
		touch ${USER_HOME}/.var_babitas/Trimming_finished.txt
		out_size=$(echo $(cat mothurTrim_pandaMerge.fastq | wc -l) / 4 | bc)
		echo ""
		echo "##########################"
		echo "DONE"
		echo "############################"
		echo "First perform quality TRIMMING with mothur, then ASSEMBLE with PANDAseq, finished"
		echo "##############################"
		echo "output = mothurTrim_pandaMerge.fastq, contains $out_size sequences"
		echo "################################"
		echo "You may close this window now!"

			else 
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt
			echo "ERROR ..."
	fi

fi


##############################################################################
##############################################################################
###First perform quality TRIMMING with vsearch, then ASSEMBLE with PANDAseq###
##############################################################################
##############################################################################
if grep -q 'First perform quality TRIMMING with vsearch, then ASSEMBLE with PANDAseq' ${USER_HOME}/.var_babitas/workflow_chosen.txt; then

echo "## Workflow = First perform quality TRIMMING with vsearch, then ASSEMBLE with PANDAseq ##"
echo ""

#Set trimming options
v_truncqual=$(cat ${USER_HOME}/.var_babitas/v_truncqual.txt)
v_maxee=$(cat ${USER_HOME}/.var_babitas/v_maxee.txt)
v_maxee_rate=$(cat ${USER_HOME}/.var_babitas/v_maxee_rate.txt)
v_minlen=$(cat ${USER_HOME}/.var_babitas/v_minlen.txt)
v_maxambig=$(cat ${USER_HOME}/.var_babitas/v_maxambig.txt)

#Set assembling options
p_minOverlap=$(cat ${USER_HOME}/.var_babitas/p_minOverlap.txt)
p_maxOverlap=$(cat ${USER_HOME}/.var_babitas/p_maxOverlap.txt)
p_maxlength=$(cat ${USER_HOME}/.var_babitas/p_maxlength.txt)
p_minphred=$(cat ${USER_HOME}/.var_babitas/p_minphred.txt)
p_minlength=$(cat ${USER_HOME}/.var_babitas/p_minlength.txt)

echo "Trimming options ->"
echo "truncqual =" $v_truncqual
echo "maxee =" $v_maxee
echo "maxee_rate =" $v_maxee_rate
echo "minlen =" $v_minlen
echo "maxambig =" $v_maxambig
echo ""

echo "Assembling options ->"
echo "minOverlap =" $p_minOverlap
echo "maxOverlap =" $p_maxOverlap
echo "maxlength =" $p_maxlength
echo "minphred ="  $p_minphred
echo "minlength =" $p_minlength


#Renaming fastq files (needed for PANDAseq assembler)
echo "# Renaming fastq files (needed for PANDAseq assembler) ..."
echo ""

tr " " "Ã" < $R1fastq > R1r.fastq
tr " " "Ã" < $R2fastq > R2r.fastq




#Trimming with vsearch
echo "# Trimming with vsearch ... "
echo "vsearch --fastq_filter R1r.fastq --fastq_truncqual $v_truncqual --fastq_maxee $v_maxee --fastq_maxee_rate $v_maxee_rate --fastq_minlen $v_minlen --fastq_maxns $v_maxambig --fastqout_discarded R1_discarded.fastq --fastqout R1r.trim.fastq"

vsearch --fastq_filter R1r.fastq --fastq_truncqual $v_truncqual --fastq_maxee $v_maxee --fastq_maxee_rate $v_maxee_rate --fastq_minlen $v_minlen --fastq_maxns $v_maxambig --fastqout_discarded R1_discarded.fastq --fastqout R1r.trim.fastq
			if [ "$?" = "0" ]; then
 			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi

echo "vsearch --fastq_filter R2r.fastq --fastq_truncqual $v_truncqual --fastq_maxee $v_maxee --fastq_maxee_rate $v_maxee_rate --fastq_minlen $v_minlen --fastq_maxns $v_maxambig --fastqout_discarded R2_discarded.fastq --fastqout R2r.trim.fastq"

vsearch --fastq_filter R2r.fastq --fastq_truncqual $v_truncqual --fastq_maxee $v_maxee --fastq_maxee_rate $v_maxee_rate --fastq_minlen $v_minlen --fastq_maxns $v_maxambig --fastqout_discarded R2_discarded.fastq --fastqout R2r.trim.fastq
			if [ "$?" = "0" ]; then
 			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi

#Renaming R1 and R2 back to original names so that PANDAseq can work 
tr "Ã" " " < R1r.trim.fastq > R1r.trim_x.fastq && tr "_" ":" < R1r.trim_x.fastq > R1r.trim.fastq_nameOK.fastq && rm R1r.trim_x.fastq
tr "Ã" " " < R2r.trim.fastq > R2r.trim_x.fastq && tr "_" ":" < R2r.trim_x.fastq > R2r.trim.fastq_nameOK.fastq && rm R2r.trim_x.fastq

#Sorting out only paired R1 and R2 sequences (singles into separate fastq)
echo "# Sorting out only paired R1 and R2 sequences"
echo "..."
python ${USER_HOME}/.babitassh/fastqCombinePairedEnd.txt R1r.trim.fastq_nameOK.fastq R2r.trim.fastq_nameOK.fastq
			if [ "$?" = "0" ]; then
 			echo "#done (with fastqCombinePairedEnd.py - github.com/enormandeau/Scripts/blob/master/fastqCombinePairedEnd.py - distributed under the GNU General Public License version 3 by the Free Software Foundation)"
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi

#Sorting R1 and R2 sequences to match for assembling
cat R1r.trim.fastq_nameOK.fastq_pairs_R1.fastq | paste - - - - | sort -k1,1 -t " " | tr "\t" "\n" > R1.trim_pairs_sorted_to_assembling.fastq

cat R2r.trim.fastq_nameOK.fastq_pairs_R2.fastq | paste - - - - | sort -k1,1 -t " " | tr "\t" "\n" > R2.trim_pairs_sorted_to_assembling.fastq




#Starting to assemble sequneces with PandaSeq
echo ""
echo "# Assembling sequneces with PandaSeq ..."
echo "pandaseq -f R1.trim_pairs_sorted_to_assembling.fastq -r R2.trim_pairs_sorted_to_assembling.fastq -F -B -o $p_minOverlap -O $p_maxOverlap -L $p_maxlength -C min_phred:$p_minphred -l $p_minlength -g PANDAseq.log > vsearchTrim_pandaMerge.fastq"

pandaseq -f R1.trim_pairs_sorted_to_assembling.fastq -r R2.trim_pairs_sorted_to_assembling.fastq -F -B -o $p_minOverlap -O $p_maxOverlap -L $p_maxlength -C min_phred:$p_minphred -l $p_minlength -g PANDAseq.log > vsearchTrim_pandaMerge.fastq
			if [ "$?" = "0" ]; then
 			echo "Assembling sequneces with PandaSeq, done"
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi



	

	if [ -e vsearchTrim_pandaMerge.fastq ]; then
		touch ${USER_HOME}/.var_babitas/Trimming_finished.txt
		out_size=$(echo $(cat vsearchTrim_pandaMerge.fastq | wc -l) / 4 | bc)
		rm R1r.fastq && rm R2r.fastq
		echo ""
		echo "##########################"
		echo "DONE"
		echo "############################"
		echo "First perform quality TRIMMING with vsearch, then ASSEMBLE with PANDAseq, finished"
		echo "##############################"
		echo "output = vsearchTrim_pandaMerge.fastq, contains $out_size sequences"
		echo "################################"
		echo "You may close this window now!"

			else 
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt
			echo "ERROR ..."
	fi

fi


##########################################################################
##########################################################################
###First perform quality TRIMMING with mothur, then ASSEMBLE with FLASH###
##########################################################################
##########################################################################
if grep -q 'First perform quality TRIMMING with mothur, then ASSEMBLE with FLASH' ${USER_HOME}/.var_babitas/workflow_chosen.txt && [ -e ${USER_HOME}/.var_babitas/f_maxOverlap.txt ]; then

echo "## Workflow = First perform quality TRIMMING with mothur, then ASSEMBLE with FLASH ##"
echo ""

#Set trimming options
qwindowaverage=$(cat ${USER_HOME}/.var_babitas/qwindowaverage.txt)
qwindowsize=$(cat ${USER_HOME}/.var_babitas/qwindowsize.txt)
minlength=$(cat ${USER_HOME}/.var_babitas/minlenght.txt)
maxambig=$(cat ${USER_HOME}/.var_babitas/maxambig.txt)
maxhomop=$(cat ${USER_HOME}/.var_babitas/maxhomop.txt)
processors=$(cat ${USER_HOME}/.var_babitas/processors.txt)

#Set assembling options
f_minOverlap=$(cat ${USER_HOME}/.var_babitas/f_minOverlap.txt)
f_maxOverlap=$(cat ${USER_HOME}/.var_babitas/f_maxOverlap.txt)
f_mismatchRatio=$(cat ${USER_HOME}/.var_babitas/f_mismatchRatio.txt)

echo "Trimming options ->"
echo "qwindowaverage =" $qwindowaverage
echo "qwindowsize =" $qwindowsize
echo "minlength =" $minlength
echo "maxambig =" $maxambig
echo "maxhomop =" $maxhomop
echo "processors =" $processors
echo ""
echo "Assembling options ->"
echo "minOverlap =" $f_minOverlap
echo "maxOverlap =" $f_maxOverlap
echo "mismatchRatio =" $f_mismatchRatio


#Rename fastq inputs
cp $R1fastq R1r.fastq
cp $R2fastq R2r.fastq

#Fastq files to fasta and qual
mothur "#fastq.info(fastq=R1r.fastq)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
		else
		echo ""
		fi

mothur "#fastq.info(fastq=R2r.fastq)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
		else
		echo ""
		fi


rm R1r.fastq
rm R2r.fastq

#Trimming with mothur
echo "# Trimming with mothur ... "

mothur "#trim.seqs(fasta=R1r.fasta, qfile=R1r.qual, qwindowaverage=$qwindowaverage, qwindowsize=$qwindowsize, minlength=$minlength, maxambig=$maxambig, maxhomop=$maxhomop, processors=$processors)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
		else
		echo ""
		fi

mothur "#trim.seqs(fasta=R2r.fasta, qfile=R2r.qual, qwindowaverage=$qwindowaverage, qwindowsize=$qwindowsize, minlength=$minlength, maxambig=$maxambig, maxhomop=$maxhomop, processors=$processors)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
		else
		echo ""
		fi

#Converting fasta and qual back to fastq
mothur "#make.fastq(fasta=R1r.trim.fasta, qfile=R1r.trim.qual)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
		else
		echo ""
		fi

mothur "#make.fastq(fasta=R2r.trim.fasta, qfile=R2r.trim.qual)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
		else
		echo ""
		fi

#Sorting out only paired R1 and R2 sequences (singles into separate fastq)
echo "# Sorting out only paired R1 and R2 sequences"
echo "..."

python ${USER_HOME}/.babitassh/fastqCombinePairedEnd.txt R1r.trim.fastq R2r.trim.fastq
			if [ "$?" = "0" ]; then
 			echo "#done (with fastqCombinePairedEnd.py - github.com/enormandeau/Scripts/blob/master/fastqCombinePairedEnd.py - distributed under the GNU General Public License version 3 by the Free Software Foundation)"
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi

#Sorting R1 and R2 sequences to match for assembling
cat R1r.trim.fastq_pairs_R1.fastq | paste - - - - | sort -k1,1 -t " " | tr "\t" "\n" > R1.trim_pairs_sorted_to_assembling.fastq

cat R2r.trim.fastq_pairs_R2.fastq | paste - - - - | sort -k1,1 -t " " | tr "\t" "\n" > R2.trim_pairs_sorted_to_assembling.fastq



#Starting to assemble sequneces with FLASH
echo ""
echo "# Assembling sequneces with FLASH ..."
echo "flash R1.trim_pairs_sorted_to_assembling.fastq R2.trim_pairs_sorted_to_assembling.fastq -m $f_minOverlap -M $f_maxOverlap -x $f_mismatchRatio -o FLASH -O > FLASH.log"

flash R1.trim_pairs_sorted_to_assembling.fastq R2.trim_pairs_sorted_to_assembling.fastq -m $f_minOverlap -M $f_maxOverlap -x $f_mismatchRatio -o FLASH -O > FLASH.log
			if [ "$?" = "0" ]; then
 			echo "Assembling sequneces with FLASH, done"
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi

mv FLASH.extendedFrags.fastq mothurTrim_flashMerge.fastq

rm R1r.fasta
rm R1r.qual
rm R2r.fasta
rm R2r.qual
rm R1r.scrap.fasta
rm R1r.scrap.qual
rm R2r.scrap.fasta
rm R2r.scrap.qual
rm R1r.trim.fasta
rm R1r.trim.qual
rm R2r.trim.fasta
rm R2r.trim.qual
rm R1r.trim.fastq
rm R2r.trim.fastq



		if [ -e mothurTrim_flashMerge.fastq ]; then
			touch ${USER_HOME}/.var_babitas/Trimming_finished.txt
			out_size=$(echo $(cat mothurTrim_flashMerge.fastq | wc -l) / 4 | bc)
			echo ""
			echo "##########################"
			echo "DONE"
			echo "############################"
			echo "First perform quality TRIMMING with mothur, then ASSEMBLE with FLASH with MaxOverlap, finished"
			echo "##############################"
			echo "output = mothurTrim_flashMerge.fastq, contains $out_size sequences"
			echo "################################"
			echo "You may close this window now!"

				else 
				touch ${USER_HOME}/.var_babitas/Trimming_error.txt
				echo "ERROR ..."
		fi


	else
	if grep -q 'First perform quality TRIMMING with mothur, then ASSEMBLE with FLASH' ${USER_HOME}/.var_babitas/workflow_chosen.txt && [ -e ${USER_HOME}/.var_babitas/averRead.txt ]; then

	echo "## Workflow = First perform quality TRIMMING with mothur, then ASSEMBLE with FLASH ##"
	echo ""

	
	#Set trimming options
	qwindowaverage=$(cat ${USER_HOME}/.var_babitas/qwindowaverage.txt)
	qwindowsize=$(cat ${USER_HOME}/.var_babitas/qwindowsize.txt)
	minlength=$(cat ${USER_HOME}/.var_babitas/minlenght.txt)
	maxambig=$(cat ${USER_HOME}/.var_babitas/maxambig.txt)
	maxhomop=$(cat ${USER_HOME}/.var_babitas/maxhomop.txt)
	processors=$(cat ${USER_HOME}/.var_babitas/processors.txt)

	#Set assembling options
	f_minOverlap=$(cat ${USER_HOME}/.var_babitas/f_minOverlap.txt)
	f_mismatchRatio=$(cat ${USER_HOME}/.var_babitas/f_mismatchRatio.txt)
	averRead=$(cat ${USER_HOME}/.var_babitas/averRead.txt)
	averFragment=$(cat ${USER_HOME}/.var_babitas/averFragment.txt)
	standardDeviation=$(cat ${USER_HOME}/.var_babitas/standardDeviation.txt)

	echo "Trimming options ->"
	echo "qwindowaverage =" $qwindowaverage
	echo "qwindowsize =" $qwindowsize
	echo "minlength =" $minlength
	echo "maxambig =" $maxambig
	echo "maxhomop =" $maxhomop
	echo "processors =" $processors
	echo ""
	echo "Assembling options ->"
	echo "minOverlap =" $f_minOverlap
	echo "mismatchRatio =" $f_mismatchRatio
	echo "averRead =" $averRead
	echo "averFragment ="  $averFragment
	echo "standardDeviation =" $standardDeviation


	#Rename fastq inputs
	cp $R1fastq R1r.fastq
	cp $R2fastq R2r.fastq

	#Fastq files to fasta and qual
	mothur "#fastq.info(fastq=R1r.fastq)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
		else
		echo ""
		fi

	mothur "#fastq.info(fastq=R2r.fastq)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
		else
		echo ""
		fi

	rm R1r.fastq
	rm R2r.fastq

	#Trimming with mothur
	echo ""
	echo "# Trimming with mothur ..."
	mothur "#trim.seqs(fasta=R1r.fasta, qfile=R1r.qual, qwindowaverage=$qwindowaverage, qwindowsize=$qwindowsize, minlength=$minlength, maxambig=$maxambig, maxhomop=$maxhomop, processors=$processors)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
		else
		echo ""
		fi

	mothur "#trim.seqs(fasta=R2r.fasta, qfile=R2r.qual, qwindowaverage=$qwindowaverage, qwindowsize=$qwindowsize, minlength=$minlength, maxambig=$maxambig, maxhomop=$maxhomop, processors=$processors)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
		else
		echo ""
		fi

	#Converting fasta and qual back to fastq
	mothur "#make.fastq(fasta=R1r.trim.fasta, qfile=R1r.trim.qual)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
		else
		echo ""
		fi

	mothur "#make.fastq(fasta=R2r.trim.fasta, qfile=R2r.trim.qual)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
		else
		echo ""
		fi

	#Sorting out only paired R1 and R2 sequences (singles into separate fastq)
	echo "# Sorting out only paired R1 and R2 sequences"
	echo "..."
	python ${USER_HOME}/.babitassh/fastqCombinePairedEnd.txt R1r.trim.fastq R2r.trim.fastq
			if [ "$?" = "0" ]; then
 			echo "#done (with fastqCombinePairedEnd.py - github.com/enormandeau/Scripts/blob/master/fastqCombinePairedEnd.py - distributed under the GNU General Public License version 3 by the Free Software Foundation)"
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi

	#Sorting R1 and R2 sequences to match for assembling
	cat R1r.trim.fastq_pairs_R1.fastq | paste - - - - | sort -k1,1 -t " " | tr "\t" "\n" > R1.trim_pairs_sorted_to_assembling.fastq

	cat R2r.trim.fastq_pairs_R2.fastq | paste - - - - | sort -k1,1 -t " " | tr "\t" "\n" > R2.trim_pairs_sorted_to_assembling.fastq


		
	#Starting to assemble sequneces with FLASH
	echo ""
	echo "# Assembling sequneces with FLASH ..."
	echo "flash R1.trim_pairs_sorted_to_assembling.fastq R2.trim_pairs_sorted_to_assembling.fastq -m $f_minOverlap -x $f_mismatchRatio -r $averRead -f $averFragment -s $standardDeviation -o FLASH -O > FLASH.log"

	flash R1.trim_pairs_sorted_to_assembling.fastq R2.trim_pairs_sorted_to_assembling.fastq -m $f_minOverlap -x $f_mismatchRatio -r $averRead -f $averFragment -s $standardDeviation -o FLASH -O > FLASH.log
			if [ "$?" = "0" ]; then
 			echo "Assembling sequneces with FLASH, done"
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi
	
	mv FLASH.extendedFrags.fastq mothurTrim_flashMerge.fastq

	rm R1r.fasta
	rm R1r.qual
	rm R2r.fasta
	rm R2r.qual
	rm R1r.scrap.fasta
	rm R1r.scrap.qual
	rm R2r.scrap.fasta
	rm R2r.scrap.qual
	rm R1r.trim.fasta
	rm R1r.trim.qual
	rm R2r.trim.fasta
	rm R2r.trim.qual
	rm R1r.trim.fastq
	rm R2r.trim.fastq

	
	
		if [ -e mothurTrim_flashMerge.fastq ]; then
			touch ${USER_HOME}/.var_babitas/Trimming_finished.txt
			out_size=$(echo $(cat mothurTrim_flashMerge.fastq | wc -l) / 4 | bc)
			echo ""
			echo "##########################"
			echo "DONE"
			echo "############################"
			echo "First perform quality TRIMMING with mothur, then ASSEMBLE with FLASH with averRead, finished"
			echo "##############################"
			echo "output = mothurTrim_flashMerge.fastq, contains $out_size sequences"
			echo "################################"
			echo "You may close this window now!"

				else 
				touch ${USER_HOME}/.var_babitas/Trimming_error.txt
				echo "ERROR ..."
		fi


	fi
fi

###########################################################################
###########################################################################
###First perform quality TRIMMING with vsearch, then ASSEMBLE with FLASH###
###########################################################################
###########################################################################

if grep -q 'First perform quality TRIMMING with vsearch, then ASSEMBLE with FLASH' ${USER_HOME}/.var_babitas/workflow_chosen.txt && [ -e ${USER_HOME}/.var_babitas/f_maxOverlap.txt ]; then

echo "## Workflow = First perform quality TRIMMING with vsearch, then ASSEMBLE with FLASH ##"
echo ""

#Set trimming options
v_truncqual=$(cat ${USER_HOME}/.var_babitas/v_truncqual.txt)
v_maxee=$(cat ${USER_HOME}/.var_babitas/v_maxee.txt)
v_maxee_rate=$(cat ${USER_HOME}/.var_babitas/v_maxee_rate.txt)
v_minlen=$(cat ${USER_HOME}/.var_babitas/v_minlen.txt)
v_maxambig=$(cat ${USER_HOME}/.var_babitas/v_maxambig.txt)

echo "Trimming options ->"
echo "truncqual =" $v_truncqual
echo "maxee =" $v_maxee
echo "maxee_rate =" $v_maxee
echo "minlen =" $v_minlen
echo "maxambig =" $v_maxambig
echo ""

#Trimming with vsearch
echo "# Trimming with vsearch"
echo "vsearch --fastq_filter $R1fastq --fastq_truncqual $v_truncqual --fastq_maxee $v_maxee --fastq_maxee_rate $v_maxee_rate --fastq_minlen $v_minlen --fastq_maxns $v_maxambig --fastqout_discarded R1_discarded.fastq --fastqout R1r.trim.fastq"

vsearch --fastq_filter $R1fastq --fastq_truncqual $v_truncqual --fastq_maxee $v_maxee --fastq_maxee_rate $v_maxee_rate --fastq_minlen $v_minlen --fastq_maxns $v_maxambig --fastqout_discarded R1_discarded.fastq --fastqout R1r.trim.fastq
			if [ "$?" = "0" ]; then
 			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi

echo ""
echo "vsearch --fastq_filter $R2fastq --fastq_truncqual $v_truncqual --fastq_maxee $v_maxee --fastq_maxee_rate $v_maxee_rate --fastq_minlen $v_minlen --fastq_maxns $v_maxambig --fastqout_discarded R2_discarded.fastq --fastqout R2r.trim.fastq"

vsearch --fastq_filter $R2fastq --fastq_truncqual $v_truncqual --fastq_maxee $v_maxee --fastq_maxee_rate $v_maxee_rate --fastq_minlen $v_minlen --fastq_maxns $v_maxambig --fastqout_discarded R2_discarded.fastq --fastqout R2r.trim.fastq
			if [ "$?" = "0" ]; then
 			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi

#Sorting out only paired R1 and R2 sequences (singles into separate fastq)
echo "# Sorting out only paired R1 and R2 sequences"
echo "..."

python ${USER_HOME}/.babitassh/fastqCombinePairedEnd.txt R1r.trim.fastq R2r.trim.fastq
			if [ "$?" = "0" ]; then
 			echo "#done (with fastqCombinePairedEnd.py - github.com/enormandeau/Scripts/blob/master/fastqCombinePairedEnd.py - distributed under the GNU General Public License version 3 by the Free Software Foundation)"
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi

#Sorting R1 and R2 sequences to match for assembling
cat R1r.trim.fastq_pairs_R1.fastq | paste - - - - | sort -k1,1 -t " " | tr "\t" "\n" > R1.trim_pairs_sorted_to_assembling.fastq

cat R2r.trim.fastq_pairs_R2.fastq | paste - - - - | sort -k1,1 -t " " | tr "\t" "\n" > R2.trim_pairs_sorted_to_assembling.fastq

#Set assembling options
f_minOverlap=$(cat ${USER_HOME}/.var_babitas/f_minOverlap.txt)
f_maxOverlap=$(cat ${USER_HOME}/.var_babitas/f_maxOverlap.txt)
f_mismatchRatio=$(cat ${USER_HOME}/.var_babitas/f_mismatchRatio.txt)

echo ""
echo "Assembling options ->"
echo "minOverlap =" $f_minOverlap
echo "maxOverlap =" $f_maxOverlap
echo "mismatchRatio = "$f_mismatchRatio
echo ""


#Starting to assemble sequneces with FLASH
echo "# Assembling sequneces with FLASH ..."
echo "flash R1.trim_pairs_sorted_to_assembling.fastq R2.trim_pairs_sorted_to_assembling.fastq -m $f_minOverlap -M $f_maxOverlap -x $f_mismatchRatio -o FLASH -O > FLASH.log"

flash R1.trim_pairs_sorted_to_assembling.fastq R2.trim_pairs_sorted_to_assembling.fastq -m $f_minOverlap -M $f_maxOverlap -x $f_mismatchRatio -o FLASH -O > FLASH.log
		if [ "$?" = "0" ]; then
		touch ${USER_HOME}/.var_babitas/Trimming_finished.txt
		
		mv FLASH.extendedFrags.fastq vsearchTrim_flashMerge.fastq
		out_size=$(echo $(cat vsearchTrim_flashMerge.fastq | wc -l) / 4 | bc)
		echo ""
		echo "##########################"
		echo "DONE"
		echo "############################"
		echo "First perform quality TRIMMING with vsearch, then ASSEMBLE with FLASH (with MaxOverlap), finished"
		echo "##############################"
		echo "output = vsearchTrim_flashMerge.fastq, contains $out_size sequences"
		echo "################################"
		echo "You may close this window now!"

			else 
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
		fi




	else
	if grep -q 'First perform quality TRIMMING with vsearch, then ASSEMBLE with FLASH' ${USER_HOME}/.var_babitas/workflow_chosen.txt && [ -e ${USER_HOME}/.var_babitas/averRead.txt ]; then

	echo "## Workflow = First perform quality TRIMMING with vsearch, then ASSEMBLE with FLASH ##"
	echo "" 

	
	#Set trimming options
	v_truncqual=$(cat ${USER_HOME}/.var_babitas/v_truncqual.txt)
	v_maxee=$(cat ${USER_HOME}/.var_babitas/v_maxee.txt)
	v_maxee_rate=$(cat ${USER_HOME}/.var_babitas/v_maxee_rate.txt)
	v_minlen=$(cat ${USER_HOME}/.var_babitas/v_minlen.txt)
	v_maxambig=$(cat ${USER_HOME}/.var_babitas/v_maxambig.txt)

	echo "Trimming options ->"
	echo "truncqual = $v_truncqual"
	echo "maxee = $v_maxee"
	echo "maxee_rate = $v_maxee_rate"
	echo "minlength = $v_minlen"
	echo "maxambig = $v_maxambig"
	echo ""

	#Trimming with vsearch
	echo "vsearch --fastq_filter $R1fastq --fastq_truncqual $v_truncqual --fastq_maxee $v_maxee --fastq_maxee_rate $v_maxee_rate --fastq_minlen $v_minlen --fastq_maxns $v_maxambig --fastqout_discarded R1_discarded.fastq --fastqout R1r.trim.fastq"

	vsearch --fastq_filter $R1fastq --fastq_truncqual $v_truncqual --fastq_maxee $v_maxee --fastq_maxee_rate $v_maxee_rate --fastq_minlen $v_minlen --fastq_maxns $v_maxambig --fastqout_discarded R1_discarded.fastq --fastqout R1r.trim.fastq
			if [ "$?" = "0" ]; then
 			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi

	echo "vsearch --fastq_filter $R2fastq --fastq_truncqual $v_truncqual --fastq_maxee $v_maxee --fastq_maxee_rate $v_maxee_rate --fastq_minlen $v_minlen --fastq_maxns $v_maxambig --fastqout_discarded R2_discarded.fastq --fastqout R2r.trim.fastq"

	vsearch --fastq_filter $R2fastq --fastq_truncqual $v_truncqual --fastq_maxee $v_maxee --fastq_maxee_rate $v_maxee_rate --fastq_minlen $v_minlen --fastq_maxns $v_maxambig --fastqout_discarded R2_discarded.fastq --fastqout R2r.trim.fastq
			if [ "$?" = "0" ]; then
 			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi


	#Sorting out only paired R1 and R2 sequences (singles into separate fastq)
	echo "# Sorting out only paired R1 and R2 sequences"
	echo "..."
	
	python ${USER_HOME}/.babitassh/fastqCombinePairedEnd.txt R1r.trim.fastq R2r.trim.fastq
			if [ "$?" = "0" ]; then
 			echo "#done (with fastqCombinePairedEnd.py - github.com/enormandeau/Scripts/blob/master/fastqCombinePairedEnd.py - distributed under the GNU General Public License version 3 by the Free Software Foundation)"
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi

	#Sorting R1 and R2 sequences to match for assembling
	cat R1r.trim.fastq_pairs_R1.fastq | paste - - - - | sort -k1,1 -t " " | tr "\t" "\n" > R1.trim_pairs_sorted_to_assembling.fastq

	cat R2r.trim.fastq_pairs_R2.fastq | paste - - - - | sort -k1,1 -t " " | tr "\t" "\n" > R2.trim_pairs_sorted_to_assembling.fastq

	#Set assembling options
	f_minOverlap=$(cat ${USER_HOME}/.var_babitas/f_minOverlap.txt)
	f_mismatchRatio=$(cat ${USER_HOME}/.var_babitas/f_mismatchRatio.txt)
	averRead=$(cat ${USER_HOME}/.var_babitas/averRead.txt)
	averFragment=$(cat ${USER_HOME}/.var_babitas/averFragment.txt)
	standardDeviation=$(cat ${USER_HOME}/.var_babitas/standardDeviation.txt)

	echo ""
	echo "Assembling options ->"
	echo "minOverlap =" $f_minOverlap
	echo "mismatchRatio =" $f_mismatchRatio
	echo "averRead = $averRead"
	echo "averFragment = $averFragment"
	echo "standardDeviation = $standardDeviation"
	echo ""
		
	#Starting to assemble sequneces with FLASH
	echo "# Assembling sequneces with FLASH ..."
	echo "flash R1.trim_pairs_sorted_to_assembling.fastq R2.trim_pairs_sorted_to_assembling.fastq -m $f_minOverlap -x $f_mismatchRatio -r $averRead -f $averFragment -s $standardDeviation -o FLASH -O > FLASH.log"

	flash R1.trim_pairs_sorted_to_assembling.fastq R2.trim_pairs_sorted_to_assembling.fastq -m $f_minOverlap -x $f_mismatchRatio -r $averRead -f $averFragment -s $standardDeviation -o FLASH -O > FLASH.log
		if [ "$?" = "0" ]; then
		touch ${USER_HOME}/.var_babitas/Trimming_finished.txt
		mv FLASH.extendedFrags.fastq vsearchTrim_flashMerge.fastq
		out_size=$(echo $(cat vsearchTrim_flashMerge.fastq | wc -l) / 4 | bc)
		echo ""
		echo "##########################"
		echo "DONE"
		echo "############################"
		echo "First perform quality TRIMMING with vsearch, then ASSEMBLE with FLASH (with averRead), finished"
		echo "##############################"
		echo "output = vsearchTrim_flashMerge.fastq, contains $out_size sequences"
		echo "################################"
		echo "You may close this window now!"

			else 
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
		fi


	fi
fi






#############################################################################
#############################################################################
###First perform quality TRIMMING with vsearch, then ASSEMBLE with vsearch###
#############################################################################
#############################################################################

if grep -q 'First perform quality TRIMMING with vsearch, then ASSEMBLE with vsearch' ${USER_HOME}/.var_babitas/workflow_chosen.txt; then
echo "## Workflow = First perform quality TRIMMING with vsearch, then ASSEMBLE with vsearch ##"
echo ""

#Set trimming options
v_truncqual=$(cat ${USER_HOME}/.var_babitas/v_truncqual.txt)
v_maxee=$(cat ${USER_HOME}/.var_babitas/v_maxee.txt)
v_maxee_rate=$(cat ${USER_HOME}/.var_babitas/v_maxee_rate.txt)
v_minlen=$(cat ${USER_HOME}/.var_babitas/v_minlen.txt)
v_maxambig=$(cat ${USER_HOME}/.var_babitas/v_maxambig.txt)

echo "Trimming options ->"
echo "truncqual =" $v_truncqual
echo "maxee =" $v_maxee
echo "maxee_rate =" $v_maxee_rate
echo "minlength =" $v_minlen
echo "maxambig =" $v_maxambig
echo ""

#Trimming with vsearch
echo "# Trimming with vsearch"
echo "vsearch --fastq_filter $R1fastq --fastq_truncqual $v_truncqual --fastq_maxee $v_maxee --fastq_maxee_rate $v_maxee_rate --fastq_minlen $v_minlen --fastq_maxns $v_maxambig --fastqout R1r.trim.fastq --fastqout_discarded R1_discarded.fastq"

vsearch --fastq_filter $R1fastq --fastq_truncqual $v_truncqual --fastq_maxee $v_maxee --fastq_maxee_rate $v_maxee_rate --fastq_minlen $v_minlen --fastq_maxns $v_maxambig --fastqout R1r.trim.fastq --fastqout_discarded R1_discarded.fastq
			if [ "$?" = "0" ]; then
 			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi

echo "vsearch --fastq_filter $R2fastq --fastq_truncqual $v_truncqual --fastq_maxee $v_maxee --fastq_maxee_rate $v_maxee_rate --fastq_minlen $v_minlen --fastq_maxns $v_maxambig --fastqout R2r.trim.fastq --fastqout_discarded R2_discarded.fastq"

vsearch --fastq_filter $R2fastq --fastq_truncqual $v_truncqual --fastq_maxee $v_maxee --fastq_maxee_rate $v_maxee_rate --fastq_minlen $v_minlen --fastq_maxns $v_maxambig --fastqout R2r.trim.fastq --fastqout_discarded R2_discarded.fastq
			if [ "$?" = "0" ]; then
 			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi

#Sorting out only paired R1 and R2 sequences (singles into separate fastq)
echo "# Sorting out only paired R1 and R2 sequences"
echo "..."
python ${USER_HOME}/.babitassh/fastqCombinePairedEnd.txt R1r.trim.fastq R2r.trim.fastq
			if [ "$?" = "0" ]; then
 			echo "#done (with fastqCombinePairedEnd.py - github.com/enormandeau/Scripts/blob/master/fastqCombinePairedEnd.py - distributed under the GNU General Public License version 3 by the Free Software Foundation)"
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi

#Sorting R1 and R2 sequences to match for assembling
cat R1r.trim.fastq_pairs_R1.fastq | paste - - - - | sort -k1,1 -t " " | tr "\t" "\n" > R1.trim_pairs_sorted_to_assembling.fastq

cat R2r.trim.fastq_pairs_R2.fastq | paste - - - - | sort -k1,1 -t " " | tr "\t" "\n" > R2.trim_pairs_sorted_to_assembling.fastq

#Set assembling options
va_minOverlap=$(cat ${USER_HOME}/.var_babitas/va_minOverlap.txt)
va_maxDiffs=$(cat ${USER_HOME}/.var_babitas/va_maxDiffs.txt)
va_minlen=$(cat ${USER_HOME}/.var_babitas/va_minlen.txt)
va_maxee=$(cat ${USER_HOME}/.var_babitas/va_maxee.txt)
va_maxambig=$(cat ${USER_HOME}/.var_babitas/va_maxambig.txt)
va_truncqual=$(cat ${USER_HOME}/.var_babitas/va_truncqual.txt)

echo ""
echo "Assembling options ->"
echo "minOverlap = $va_minOverlap"
echo "maxDiffs = $va_maxDiffs"
echo "minlength = $va_minlen"
echo "maxee = $va_maxee"
echo "maxambig = $va_maxambig"
echo "truncqual = $va_truncqual"


	if [ -e ${USER_HOME}/.var_babitas/va_allowstagger.txt ]; then
	va_allowstagger=$(cat ${USER_HOME}/.var_babitas/va_allowstagger.txt)
	echo "allowstagger = T"
	echo ""
	echo "# Assembling sequneces with vsearch ..."
	echo "vsearch --fastq_mergepairs R1.trim_pairs_sorted_to_assembling.fastq --reverse R2.trim_pairs_sorted_to_assembling.fastq --fastq_minovlen $va_minOverlap --maxdiffs $va_maxDiffs --fastq_minmergelen $va_minlen --fastq_maxee $va_maxee --fastq_maxns $va_maxambig --fastq_truncqual $va_truncqual --fastq_allowmergestagger --fastqout vsearchTrim_vsearchMerge.fastq --fastqout_notmerged_fwd notmerged_fwd.fastq --fastqout_notmerged_rev notmerged_rev.fastq"

	vsearch --fastq_mergepairs R1.trim_pairs_sorted_to_assembling.fastq --reverse R2.trim_pairs_sorted_to_assembling.fastq --fastq_minovlen $va_minOverlap --maxdiffs $va_maxDiffs --fastq_minmergelen $va_minlen --fastq_maxee $va_maxee --fastq_maxns $va_maxambig --fastq_truncqual $va_truncqual --fastq_allowmergestagger --fastqout vsearchTrim_vsearchMerge.fastq --fastqout_notmerged_fwd notmerged_fwd.fastq --fastqout_notmerged_rev notmerged_rev.fastq
			if [ "$?" = "0" ]; then
			touch ${USER_HOME}/.var_babitas/Trimming_finished.txt
			out_size=$(echo $(cat vsearchTrim_vsearchMerge.fastq | wc -l) / 4 | bc)
			echo ""
			echo "##########################"
			echo "DONE"
			echo "############################"
			echo "First perform quality TRIMMING with vsearch, then ASSEMBLE with vsearch, finished"
			echo "##############################"
			echo "output = vsearchTrim_vsearchMerge.fastq, contains $out_size sequences"
			echo "################################"
			echo "You may close this window now!"

				else 
				touch ${USER_HOME}/.var_babitas/Trimming_error.txt
				echo "An unexpected error has occurred!  Aborting." 1>&2
				exit 1
			fi


	else
	echo ""
	echo "# Assembling sequneces with vsearch ..."
	echo "vsearch --fastq_mergepairs R1.trim_pairs_sorted_to_assembling.fastq --reverse R2.trim_pairs_sorted_to_assembling.fastq --fastq_minovlen $va_minOverlap --maxdiffs $va_maxDiffs --fastq_minmergelen $va_minlen --fastq_maxee $va_maxee --fastq_maxns $va_maxambig --fastq_truncqual $va_truncqual --fastqout vsearchTrim_vsearchMerge.fastq --fastqout_notmerged_fwd notmerged_fwd.fastq --fastqout_notmerged_rev notmerged_rev.fastq"

	vsearch --fastq_mergepairs R1.trim_pairs_sorted_to_assembling.fastq --reverse R2.trim_pairs_sorted_to_assembling.fastq --fastq_minovlen $va_minOverlap --maxdiffs $va_maxDiffs --fastq_minmergelen $va_minlen --fastq_maxee $va_maxee --fastq_maxns $va_maxambig --fastq_truncqual $va_truncqual --fastqout vsearchTrim_vsearchMerge.fastq --fastqout_notmerged_fwd notmerged_fwd.fastq --fastqout_notmerged_rev notmerged_rev.fastq
			if [ "$?" = "0" ]; then
			touch ${USER_HOME}/.var_babitas/Trimming_finished.txt
			out_size=$(echo $(cat vsearchTrim_vsearchMerge.fastq | wc -l) / 4 | bc)
			echo ""
			echo "##########################"
			echo "DONE"
			echo "############################"
			echo "First perform quality TRIMMING with vsearch, then ASSEMBLE with vsearch, finished"
			echo "##############################"
			echo "output = vsearchTrim_vsearchMerge.fastq, contains $out_size sequences"
			echo "################################"
			echo "You may close this window now!"

				else 
				touch ${USER_HOME}/.var_babitas/Trimming_error.txt
				echo "An unexpected error has occurred!  Aborting." 1>&2
				exit 1
			fi


	fi	

fi





############################################################################
############################################################################
###First perform quality TRIMMING with mothur, then ASSEMBLE with vsearch###
############################################################################
############################################################################

if grep -q 'First perform quality TRIMMING with mothur, then ASSEMBLE with vsearch' ${USER_HOME}/.var_babitas/workflow_chosen.txt; then

echo "## Workflow = First perform quality TRIMMING with mothur, then ASSEMBLE with vsearch ##"
echo ""

#Set trimming options
qwindowaverage=$(cat ${USER_HOME}/.var_babitas/qwindowaverage.txt)
qwindowsize=$(cat ${USER_HOME}/.var_babitas/qwindowsize.txt)
minlength=$(cat ${USER_HOME}/.var_babitas/minlenght.txt)
maxambig=$(cat ${USER_HOME}/.var_babitas/maxambig.txt)
maxhomop=$(cat ${USER_HOME}/.var_babitas/maxhomop.txt)
processors=$(cat ${USER_HOME}/.var_babitas/processors.txt)

echo "Trimming options ->"
echo "qwindowaverage =" $qwindowaverage
echo "qwindowsize =" $qwindowsize
echo "minlength =" $minlength
echo "maxambig =" $maxambig
echo "maxhomop =" $maxhomop
echo "processors =" $processors
echo ""

#Renaming fastq files (needed for PANDAseq assembler)
echo "# Renaming fastq files (to avoid inconsistencies with mothur) ..."

tr " " "Ã" < $R1fastq > R1r.fastq
mothur "#fastq.info(fastq=R1r.fastq)" && rm R1r.fastq
tr " " "Ã" < $R2fastq > R2r.fastq
mothur "#fastq.info(fastq=R2r.fastq)" && rm R2r.fastq



#Trimming with mothur
echo "# Trimming with mothur ... "
mothur "#trim.seqs(fasta=R1r.fasta, qfile=R1r.qual, qwindowaverage=$qwindowaverage, qwindowsize=$qwindowsize, minlength=$minlength, maxambig=$maxambig, maxhomop=$maxhomop, processors=$processors)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
		else
		echo ""
		fi

mothur "#trim.seqs(fasta=R2r.fasta, qfile=R2r.qual, qwindowaverage=$qwindowaverage, qwindowsize=$qwindowsize, minlength=$minlength, maxambig=$maxambig, maxhomop=$maxhomop, processors=$processors)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
		else
		echo ""
		fi

#Converting fasta and qual back to fastq
echo "#Converting fasta and qual back to fastq"

mothur "#make.fastq(fasta=R1r.trim.fasta, qfile=R1r.trim.qual)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
		else
		echo ""
		fi

mothur "#make.fastq(fasta=R2r.trim.fasta, qfile=R2r.trim.qual)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
		else
		echo ""
		fi

#Renaming R1 and R2 back to original names
tr "Ã" " " < R1r.trim.fastq > R1r.trim_x.fastq && tr "_" ":" < R1r.trim_x.fastq > R1r.trim.fastq_nameOK.fastq && rm R1r.trim_x.fastq
tr "Ã" " " < R2r.trim.fastq > R2r.trim_x.fastq && tr "_" ":" < R2r.trim_x.fastq > R2r.trim.fastq_nameOK.fastq && rm R2r.trim_x.fastq

#Sorting out only paired R1 and R2 sequences (singles into separate fastq)
echo "# Sorting out only paired R1 and R2 sequences"
echo "..."
python ${USER_HOME}/.babitassh/fastqCombinePairedEnd.txt R1r.trim.fastq_nameOK.fastq R2r.trim.fastq_nameOK.fastq
			if [ "$?" = "0" ]; then
 			echo "#done (with fastqCombinePairedEnd.py - github.com/enormandeau/Scripts/blob/master/fastqCombinePairedEnd.py - distributed under the GNU General Public License version 3 by the Free Software Foundation)"
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi

#Sorting R1 and R2 sequences to match for assembling
cat R1r.trim.fastq_nameOK.fastq_pairs_R1.fastq | paste - - - - | sort -k1,1 -t " " | tr "\t" "\n" > R1.trim_pairs_sorted_to_assembling.fastq

cat R2r.trim.fastq_nameOK.fastq_pairs_R2.fastq | paste - - - - | sort -k1,1 -t " " | tr "\t" "\n" > R2.trim_pairs_sorted_to_assembling.fastq


#Set assembling options
va_minOverlap=$(cat ${USER_HOME}/.var_babitas/va_minOverlap.txt)
va_maxDiffs=$(cat ${USER_HOME}/.var_babitas/va_maxDiffs.txt)
va_minlen=$(cat ${USER_HOME}/.var_babitas/va_minlen.txt)
va_maxee=$(cat ${USER_HOME}/.var_babitas/va_maxee.txt)
va_maxambig=$(cat ${USER_HOME}/.var_babitas/va_maxambig.txt)
va_truncqual=$(cat ${USER_HOME}/.var_babitas/va_truncqual.txt)

echo ""
echo "Assembling options ->"
echo "minOverlap = $va_minOverlap"
echo "maxDiffs = $va_maxDiffs"
echo "minlength = $va_minlen"
echo "maxee = $va_maxee"
echo "maxambig = $va_maxambig"
echo "truncqual = $va_truncqual"

	if [ -e ${USER_HOME}/.var_babitas/va_allowstagger.txt ]; then
	va_allowstagger=$(cat ${USER_HOME}/.var_babitas/va_allowstagger.txt)
	
	echo "allowstagger = T"
	echo ""
	echo "# Assembling sequneces with vsearch ..."
	echo "vsearch --fastq_mergepairs R1.trim_pairs_sorted_to_assembling.fastq --reverse R2.trim_pairs_sorted_to_assembling.fastq --fastq_minovlen $va_minOverlap --maxdiffs $va_maxDiffs --fastq_minmergelen $va_minlen --fastq_maxee $va_maxee --fastq_maxns $va_maxambig --fastq_truncqual $va_truncqual --fastq_allowmergestagger --fastqout mothurTrim_vsearchMerge.fastq --fastqout_notmerged_fwd notmerged_fwd.fastq --fastqout_notmerged_rev notmerged_rev.fastq"

	vsearch --fastq_mergepairs R1.trim_pairs_sorted_to_assembling.fastq --reverse R2.trim_pairs_sorted_to_assembling.fastq --fastq_minovlen $va_minOverlap --maxdiffs $va_maxDiffs --fastq_minmergelen $va_minlen --fastq_maxee $va_maxee --fastq_maxns $va_maxambig --fastq_truncqual $va_truncqual --fastq_allowmergestagger --fastqout mothurTrim_vsearchMerge.fastq --fastqout_notmerged_fwd notmerged_fwd.fastq --fastqout_notmerged_rev notmerged_rev.fastq
			if [ "$?" = "0" ]; then
			touch ${USER_HOME}/.var_babitas/Trimming_finished.txt
			out_size=$(echo $(cat mothurTrim_vsearchMerge.fastq | wc -l) / 4 | bc)
			echo ""
			echo "##########################"
			echo "DONE"
			echo "############################"
			echo "First perform quality TRIMMING with mothur, then ASSEMBLE with vsearch, finished"
			echo "##############################"
			echo "output = mothurTrim_vsearchMerge.fastq, contains $out_size sequences"
			echo "################################"
			echo "You may close this window now!"

				else 
				touch ${USER_HOME}/.var_babitas/Trimming_error.txt
				echo "An unexpected error has occurred!  Aborting." 1>&2
				exit 1
			fi

	else
	echo ""
	echo "# Assembling sequneces with vsearch ..."
	echo "vsearch --fastq_mergepairs R1.trim_pairs_sorted_to_assembling.fastq --reverse R2.trim_pairs_sorted_to_assembling.fastq --fastq_minovlen $va_minOverlap --maxdiffs $va_maxDiffs --fastq_minmergelen $va_minlen --fastq_maxee $va_maxee --fastq_maxns $va_maxambig --fastq_truncqual $va_truncqual --fastqout mothurTrim_vsearchMerge.fastq --fastqout_notmerged_fwd notmerged_fwd.fastq --fastqout_notmerged_rev notmerged_rev.fastq"

	vsearch --fastq_mergepairs R1.trim_pairs_sorted_to_assembling.fastq --reverse R2.trim_pairs_sorted_to_assembling.fastq --fastq_minovlen $va_minOverlap --maxdiffs $va_maxDiffs --fastq_minmergelen $va_minlen --fastq_maxee $va_maxee --fastq_maxns $va_maxambig --fastq_truncqual $va_truncqual --fastqout mothurTrim_vsearchMerge.fastq --fastqout_notmerged_fwd notmerged_fwd.fastq --fastqout_notmerged_rev notmerged_rev.fastq
			if [ "$?" = "0" ]; then
			touch ${USER_HOME}/.var_babitas/Trimming_finished.txt
			out_size=$(echo $(cat mothurTrim_vsearchMerge.fastq | wc -l) / 4 | bc)
			echo ""
			echo "##########################"
			echo "DONE"
			echo "############################"
			echo "First perform quality TRIMMING with mothur, then ASSEMBLE with vsearch, finished"	
			echo "##############################"
			echo "output = mothurTrim_vsearchMerge.fastq, contains $out_size sequences"
			echo "################################"
			echo "You may close this window now!"

				else 
				touch ${USER_HOME}/.var_babitas/Trimming_error.txt
				echo "An unexpected error has occurred!  Aborting." 1>&2
				exit 1
			fi
	fi
fi




#############################################################################
#############################################################################
###First ASSEMBLE with PANDAseq, then perform quality TRIMMING with mothur###
#############################################################################
#############################################################################
if grep -q 'First ASSEMBLE with PANDAseq, then perform quality TRIMMING with mothur' ${USER_HOME}/.var_babitas/workflow_chosen.txt; then

echo "## Workflow = First ASSEMBLE with PANDAseq, then perform quality TRIMMING with mothur ##"
echo ""

#Set assembling options
p_minOverlap=$(cat ${USER_HOME}/.var_babitas/p_minOverlap.txt)
p_maxOverlap=$(cat ${USER_HOME}/.var_babitas/p_maxOverlap.txt)
p_maxlength=$(cat ${USER_HOME}/.var_babitas/p_maxlength.txt)
p_minphred=$(cat ${USER_HOME}/.var_babitas/p_minphred.txt)
p_minlength=$(cat ${USER_HOME}/.var_babitas/p_minlength.txt)

echo "Assembling options ->"
echo "minOverlap =" $p_minOverlap
echo "maxOverlap =" $p_maxOverlap
echo "maxlength =" $p_maxlength
echo "minphred ="  $p_minphred
echo "minlength =" $p_minlength
echo ""

#Starting to assemble sequneces with PandaSeq
echo "# Assembling sequneces with PandaSeq ..."
echo "pandaseq -f $R1fastq -r $R2fastq -F -B -o $p_minOverlap -O $p_maxOverlap -L $p_maxlength -C min_phred:$p_minphred -l $p_minlength -g PANDAseq.log > R1_R2_PANDAseq.fastq"

pandaseq -f $R1fastq -r $R2fastq -F -B -o $p_minOverlap -O $p_maxOverlap -L $p_maxlength -C min_phred:$p_minphred -l $p_minlength -g PANDAseq.log > R1_R2_PANDAseq.fastq
			if [ "$?" = "0" ]; then
 			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi


#Set trimming options
qwindowaverage=$(cat ${USER_HOME}/.var_babitas/qwindowaverage.txt)
qwindowsize=$(cat ${USER_HOME}/.var_babitas/qwindowsize.txt)
minlength=$(cat ${USER_HOME}/.var_babitas/minlenght.txt)
maxambig=$(cat ${USER_HOME}/.var_babitas/maxambig.txt)
maxhomop=$(cat ${USER_HOME}/.var_babitas/maxhomop.txt)
processors=$(cat ${USER_HOME}/.var_babitas/processors.txt)

echo "Trimming options ->"
echo "qwindowaverage =" $qwindowaverage
echo "qwindowsize =" $qwindowsize
echo "minlength =" $minlength
echo "maxambig =" $maxambig
echo "maxhomop =" $maxhomop
echo "processors =" $processors
echo ""

#Assembled fastq to fasta and qual
echo "# Assembled fastq to fasta and qual"

mothur "#fastq.info(fastq=R1_R2_PANDAseq.fastq)"
			if [ "$?" = "0" ]; then
 			echo "..."
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi

#Trimming with mothur
echo "# Trimming with mothur ..."

mothur "#trim.seqs(fasta=R1_R2_PANDAseq.fasta, qfile=R1_R2_PANDAseq.qual, qwindowaverage=$qwindowaverage, qwindowsize=$qwindowsize, minlength=$minlength, maxambig=$maxambig, maxhomop=$maxhomop, processors=$processors)"
			if [ "$?" = "0" ]; then
 			echo "Trimming with mothur, done"
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi

#Fasta and qual back to fastq
echo "# Fasta and qual back to fastq"

mothur "#make.fastq(fasta=R1_R2_PANDAseq.trim.fasta, qfile=R1_R2_PANDAseq.trim.qual)"
		if [ "$?" = "0" ]; then
		touch ${USER_HOME}/.var_babitas/Trimming_finished.txt
		mv R1_R2_PANDAseq.trim.fastq pandaMerge_mothurTrim.fastq
		out_size=$(echo $(cat pandaMerge_mothurTrim.fastq | wc -l) / 4 | bc)
		echo ""
		echo "##########################"
		echo "DONE"
		echo "############################"
		echo "First ASSEMBLE with PANDAseq, then perform quality TRIMMING with mothur, finished"
		echo "##############################"
		echo "output = pandaMerge_mothurTrim.fastq, contains $out_size sequences"
		echo "################################"
		echo "You may close this window now!"

			else 
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
		fi
fi


##############################################################################
##############################################################################
###First ASSEMBLE with PANDAseq, then perform quality TRIMMING with vsearch###
##############################################################################
##############################################################################
if grep -q 'First ASSEMBLE with PANDAseq, then perform quality TRIMMING with vsearch' ${USER_HOME}/.var_babitas/workflow_chosen.txt; then

echo "## Workflow = First ASSEMBLE with PANDAseq, then perform quality TRIMMING with vsearch ##"
echo ""

#Set assembling options
p_minOverlap=$(cat ${USER_HOME}/.var_babitas/p_minOverlap.txt)
p_maxOverlap=$(cat ${USER_HOME}/.var_babitas/p_maxOverlap.txt)
p_maxlength=$(cat ${USER_HOME}/.var_babitas/p_maxlength.txt)
p_minphred=$(cat ${USER_HOME}/.var_babitas/p_minphred.txt)
p_minlength=$(cat ${USER_HOME}/.var_babitas/p_minlength.txt)

echo "Assembling options ->"
echo "minOverlap =" $p_minOverlap
echo "maxOverlap =" $p_maxOverlap
echo "maxlength =" $p_maxlength
echo "minphred ="  $p_minphred
echo "minlength =" $p_minlength
echo ""

#Starting to assemble sequneces with PandaSeq
echo "# Assembling sequneces with PandaSeq ..."
echo "pandaseq -f $R1fastq -r $R2fastq -F -B -o $p_minOverlap -O $p_maxOverlap -L $p_maxlength -C min_phred:$p_minphred -l $p_minlength -g PANDAseq.log > R1_R2_PANDAseq.fastq"

pandaseq -f $R1fastq -r $R2fastq -F -B -o $p_minOverlap -O $p_maxOverlap -L $p_maxlength -C min_phred:$p_minphred -l $p_minlength -g PANDAseq.log > R1_R2_PANDAseq.fastq
			if [ "$?" = "0" ]; then
 			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi


#Set trimming options
v_truncqual=$(cat ${USER_HOME}/.var_babitas/v_truncqual.txt)
v_maxee=$(cat ${USER_HOME}/.var_babitas/v_maxee.txt)
v_maxee_rate=$(cat ${USER_HOME}/.var_babitas/v_maxee_rate.txt)
v_minlen=$(cat ${USER_HOME}/.var_babitas/v_minlen.txt)
v_maxambig=$(cat ${USER_HOME}/.var_babitas/v_maxambig.txt)

echo "Trimming options ->"
echo "truncqual =" $v_truncqual
echo "maxee =" $v_maxee
echo "maxee_rate =" $v_maxee_rate
echo "minlength =" $v_minlen
echo "maxambig =" $v_maxambig
echo ""

#Trimming with vsearch
echo "# Trimming with vsearch ... "
echo "vsearch --fastq_filter R1_R2_PANDAseq.fastq --fastq_truncqual $v_truncqual --fastq_maxee $v_maxee --fastq_maxee_rate $v_maxee_rate --fastq_minlen $v_minlen --fastq_maxns $v_maxambig --fastqout_discarded vsearchTrim_discarded.fastq --fastqout pandaMerge_vsearchTrim.fastq"

vsearch --fastq_filter R1_R2_PANDAseq.fastq --fastq_truncqual $v_truncqual --fastq_maxee $v_maxee --fastq_maxee_rate $v_maxee_rate --fastq_minlen $v_minlen --fastq_maxns $v_maxambig --fastqout_discarded vsearchTrim_discarded.fastq --fastqout pandaMerge_vsearchTrim.fastq
		if [ "$?" = "0" ]; then
		touch ${USER_HOME}/.var_babitas/Trimming_finished.txt
		out_size=$(echo $(cat pandaMerge_vsearchTrim.fastq | wc -l) / 4 | bc)
		echo ""
		echo "##########################"
		echo "DONE"
		echo "############################"
		echo "First ASSEMBLE with PANDAseq, then perform quality TRIMMING with vsearch, finished"
		echo "##############################"
		echo "output = pandaMerge_vsearchTrim.fastq, contains $out_size sequences"
		echo "################################"
		echo "You may close this window now!"

			else 
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
		fi
fi




##########################################################################
##########################################################################
###First ASSEMBLE with FLASH, then perform quality TRIMMING with mothur###
##########################################################################
##########################################################################
if grep -q 'First ASSEMBLE with FLASH, then perform quality TRIMMING with mothur' ${USER_HOME}/.var_babitas/workflow_chosen.txt && [ -e ${USER_HOME}/.var_babitas/f_maxOverlap.txt ]; then

echo "## Workflow = First ASSEMBLE with FLASH (with maxOverlap), then perform quality TRIMMING with mothur ##"
echo ""

#Set assembling options
f_minOverlap=$(cat ${USER_HOME}/.var_babitas/f_minOverlap.txt)
f_maxOverlap=$(cat ${USER_HOME}/.var_babitas/f_maxOverlap.txt)
f_mismatchRatio=$(cat ${USER_HOME}/.var_babitas/f_mismatchRatio.txt)

echo "Assembling options ->"
echo "minOverlap =" $p_minOverlap
echo "maxOverlap =" $p_maxOverlap
echo "mismatchRatio = $f_mismatchRatio" 

#Starting to assemble sequneces with FLASH
echo "# Assembling sequneces with FLASH ..."
echo "flash $R1fastq $R2fastq -m $f_minOverlap -M $f_maxOverlap -x $f_mismatchRatio -o FLASH -O > FLASH.log"

flash $R1fastq $R2fastq -m $f_minOverlap -M $f_maxOverlap -x $f_mismatchRatio -o FLASH -O > FLASH.log
			if [ "$?" = "0" ]; then
 			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi

mv FLASH.extendedFrags.fastq R1_R2_FLASH.fastq


#Set trimming options
qwindowaverage=$(cat ${USER_HOME}/.var_babitas/qwindowaverage.txt)
qwindowsize=$(cat ${USER_HOME}/.var_babitas/qwindowsize.txt)
minlength=$(cat ${USER_HOME}/.var_babitas/minlenght.txt)
maxambig=$(cat ${USER_HOME}/.var_babitas/maxambig.txt)
maxhomop=$(cat ${USER_HOME}/.var_babitas/maxhomop.txt)
processors=$(cat ${USER_HOME}/.var_babitas/processors.txt)

echo ""
echo "Trimming options ->"
echo "qwindowaverage =" $qwindowaverage
echo "qwindowsize =" $qwindowsize
echo "minlength =" $minlength
echo "maxambig =" $maxambig
echo "maxhomop =" $maxhomop
echo "processors =" $processors
echo ""

#Assembled fastq to fasta and qual
echo "# Assembled fastq to fasta and qual"

mothur "#fastq.info(fastq=R1_R2_FLASH.fastq)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
		else
		echo ""
		fi

#Trimming with mothur
echo "# Trimming with mothur ... "

mothur "#trim.seqs(fasta=R1_R2_FLASH.fasta, qfile=R1_R2_FLASH.qual, qwindowaverage=$qwindowaverage, qwindowsize=$qwindowsize, minlength=$minlength, maxambig=$maxambig, maxhomop=$maxhomop, processors=$processors)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
		else
		echo ""
		fi

#Fasta and qual back to fastq
mothur "#make.fastq(fasta=R1_R2_FLASH.trim.fasta, qfile=R1_R2_FLASH.trim.qual)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
		else
		touch ${USER_HOME}/.var_babitas/Trimming_finished.txt
		mv R1_R2_FLASH.trim.fastq flashMerge_mothurTrim.fastq
		out_size=$(echo $(cat flashMerge_mothurTrim.fastq | wc -l) / 4 | bc)
		echo ""
		echo "##########################"
		echo "DONE"
		echo "############################"
		echo "First ASSEMBLE with FLASH with maxOverlap, then perform quality TRIMMING with mothur, finished"
		echo "##############################"
		echo "output = flashMerge_mothurTrim.fastq, contains $out_size sequences"
		echo "################################"
		echo "You may close this window now!"
		fi



	else
	if grep -q 'First ASSEMBLE with FLASH, then perform quality TRIMMING with mothur' ${USER_HOME}/.var_babitas/workflow_chosen.txt && [ -e ${USER_HOME}/.var_babitas/averRead.txt ]; then

	echo "## Workflow = First ASSEMBLE with FLASH (with averRead), then perform quality TRIMMING with mothur ##"
	echo ""
	
	#Set assembling options
	f_minOverlap=$(cat ${USER_HOME}/.var_babitas/f_minOverlap.txt)
	f_mismatchRatio=$(cat ${USER_HOME}/.var_babitas/f_mismatchRatio.txt)
	averRead=$(cat ${USER_HOME}/.var_babitas/averRead.txt)
	averFragment=$(cat ${USER_HOME}/.var_babitas/averFragment.txt)
	standardDeviation=$(cat ${USER_HOME}/.var_babitas/standardDeviation.txt)

	echo "Assembling options ->"
	echo "minOverlap =" $p_minOverlap
	echo "maxOverlap =" $p_maxOverlap
	echo "averRead = $averRead"
	echo "averFragment = $averFragment"
	echo "standardDeviation = $standardDeviation"
	

	#Starting to assemble sequneces with FLASH
	echo "# Assembling sequneces with FLASH ..."
	echo "flash $R1fastq $R2fastq -m $f_minOverlap -x $f_mismatchRatio -r $averRead -f $averFragment -s $standardDeviation -o FLASH -O > FLASH.log"

	flash $R1fastq $R2fastq -m $f_minOverlap -x $f_mismatchRatio -r $averRead -f $averFragment -s $standardDeviation -o FLASH -O > FLASH.log
			if [ "$?" = "0" ]; then
 			echo "Assembling sequneces with FLASH, done"
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi
	
	mv FLASH.extendedFrags.fastq R1_R2_FLASH.fastq

	#Set trimming options
	qwindowaverage=$(cat ${USER_HOME}/.var_babitas/qwindowaverage.txt)
	qwindowsize=$(cat ${USER_HOME}/.var_babitas/qwindowsize.txt)
	minlength=$(cat ${USER_HOME}/.var_babitas/minlenght.txt)
	maxambig=$(cat ${USER_HOME}/.var_babitas/maxambig.txt)
	maxhomop=$(cat ${USER_HOME}/.var_babitas/maxhomop.txt)
	processors=$(cat ${USER_HOME}/.var_babitas/processors.txt)

	echo ""
	echo "Trimming options ->"
	echo "qwindowaverage =" $qwindowaverage
	echo "qwindowsize =" $qwindowsize
	echo "minlength =" $minlength
	echo "maxambig =" $maxambig
	echo "maxhomop =" $maxhomop
	echo "processors =" $processors
	echo ""

	#Assembled fastq to fasta and qual
	echo "# Assembled fastq to fasta and qual"

	mothur "#fastq.info(fastq=R1_R2_FLASH.fastq)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
		else
		echo ""
		fi

	#Trimming with mothur
	echo "# Trimming with mothur ... "

	mothur "#trim.seqs(fasta=R1_R2_FLASH.fasta, qfile=R1_R2_FLASH.qual, qwindowaverage=$qwindowaverage, qwindowsize=$qwindowsize, minlength=$minlength, maxambig=$maxambig, maxhomop=$maxhomop, processors=$processors)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
		else
		echo ""
		fi

	#Fasta and qual back to fastq
	mothur "#make.fastq(fasta=R1_R2_FLASH.trim.fasta, qfile=R1_R2_FLASH.trim.qual)"| tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
		else
		touch ${USER_HOME}/.var_babitas/Trimming_finished.txt
		mv R1_R2_FLASH.trim.fastq flashMerge_mothurTrim.fastq
		out_size=$(echo $(cat flashMerge_mothurTrim.fastq | wc -l) / 4 | bc)
		echo ""
		echo "##########################"
		echo "DONE"
		echo "############################"
		echo "First ASSEMBLE with FLASH with averRead, then perform quality TRIMMING with mothur, finished"
		echo "##############################"
		echo "output = flashMerge_mothurTrim.fastq, contains $out_size sequences"
		echo "################################"
		echo "You may close this window now!"
		fi
	fi
fi





###########################################################################
###########################################################################
###First ASSEMBLE with FLASH, then perform quality TRIMMING with vsearch###
###########################################################################
###########################################################################
if grep -q 'First ASSEMBLE with FLASH, then perform quality TRIMMING with vsearch' ${USER_HOME}/.var_babitas/workflow_chosen.txt && [ -e ${USER_HOME}/.var_babitas/f_maxOverlap.txt ]; then

echo "## Workflow = First ASSEMBLE with FLASH (with maxOverlap), then perform quality TRIMMING with vsearch"
echo ""

#Set assembling options
f_minOverlap=$(cat ${USER_HOME}/.var_babitas/f_minOverlap.txt)
f_maxOverlap=$(cat ${USER_HOME}/.var_babitas/f_maxOverlap.txt)
f_mismatchRatio=$(cat ${USER_HOME}/.var_babitas/f_mismatchRatio.txt)

echo "Assembling options ->"
echo "minOverlap =" $p_minOverlap
echo "maxOverlap =" $p_maxOverlap
echo "mismatchRatio = $f_mismatchRatio" 

#Starting to assemble sequneces with FLASH
echo "# Assembling sequneces with FLASH ..."
echo "flash $R1fastq $R2fastq -m $f_minOverlap -M $f_maxOverlap -x $f_mismatchRatio -o FLASH -O > FLASH.log"

flash $R1fastq $R2fastq -m $f_minOverlap -M $f_maxOverlap -x $f_mismatchRatio -o FLASH -O > FLASH.log
			if [ "$?" = "0" ]; then
 			echo "Assembling sequneces with FLASH, done"
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi

mv FLASH.extendedFrags.fastq R1_R2_FLASH.fastq

#Set trimming options
v_truncqual=$(cat ${USER_HOME}/.var_babitas/v_truncqual.txt)
v_maxee=$(cat ${USER_HOME}/.var_babitas/v_maxee.txt)
v_maxee_rate=$(cat ${USER_HOME}/.var_babitas/v_maxee_rate.txt)
v_minlen=$(cat ${USER_HOME}/.var_babitas/v_minlen.txt)
v_maxambig=$(cat ${USER_HOME}/.var_babitas/v_maxambig.txt)

echo ""
echo "Trimming options ->"
echo "truncqual =" $v_truncqual
echo "maxee =" $v_maxee
echo "maxee_rate =" $v_maxee_rate
echo "minlength =" $v_minlen
echo "maxambig =" $v_maxambig
echo ""

#Trimming with vsearch
echo "# Trimming with vsearch ... "
echo "vsearch --fastq_filter R1_R2_FLASH.fastq --fastq_truncqual $v_truncqual --fastq_maxee $v_maxee --fastq_maxee_rate $v_maxee_rate --fastq_minlen $v_minlen --fastq_maxns $v_maxambig --fastqout_discarded vsearchTrim_discarded.fastq --fastqout flashMerge_vsearchTrim.fastq"

vsearch --fastq_filter R1_R2_FLASH.fastq --fastq_truncqual $v_truncqual --fastq_maxee $v_maxee --fastq_maxee_rate $v_maxee_rate --fastq_minlen $v_minlen --fastq_maxns $v_maxambig --fastqout_discarded vsearchTrim_discarded.fastq --fastqout flashMerge_vsearchTrim.fastq
		if [ "$?" = "0" ]; then
		touch ${USER_HOME}/.var_babitas/Trimming_finished.txt
		out_size=$(echo $(cat flashMerge_vsearchTrim.fastq | wc -l) / 4 | bc)
		echo ""
		echo "##########################"
		echo "DONE"
		echo "############################"
		echo "First ASSEMBLE with FLASH (with maxOverlap), then perform quality TRIMMING with vsearch, finished"
		echo "##############################"
		echo "output = flashMerge_vsearchTrim.fastq, contains $out_size sequences"
		echo "################################"
		echo "You may close this window now!"

			else 
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
		fi



	else
	if grep -q 'First ASSEMBLE with FLASH, then perform quality TRIMMING with vsearch' ${USER_HOME}/.var_babitas/workflow_chosen.txt && [ -e ${USER_HOME}/.var_babitas/averRead.txt ]; then

	echo "## Workflow = First ASSEMBLE with FLASH (with averRead), then perform quality TRIMMING with vsearch ##"
	echo ""
	
	#Set assembling options
	f_minOverlap=$(cat ${USER_HOME}/.var_babitas/f_minOverlap.txt)
	f_mismatchRatio=$(cat ${USER_HOME}/.var_babitas/f_mismatchRatio.txt)
	averRead=$(cat ${USER_HOME}/.var_babitas/averRead.txt)
	averFragment=$(cat ${USER_HOME}/.var_babitas/averFragment.txt)
	standardDeviation=$(cat ${USER_HOME}/.var_babitas/standardDeviation.txt)

	echo "Assembling options ->"
	echo "minOverlap =" $p_minOverlap
	echo "maxOverlap =" $p_maxOverlap
	echo "averRead = $averRead"
	echo "averFragment = $averFragment"
	echo "standardDeviation = $standardDeviation"
	echo ""
		
	#Starting to assemble sequneces with FLASH
	echo "# Assembling sequneces with FLASH ..."
	echo "flash $R1fastq $R2fastq -m $f_minOverlap -x $f_mismatchRatio -r $averRead -f $averFragment -s $standardDeviation -o FLASH -O > FLASH.log"

	flash $R1fastq $R2fastq -m $f_minOverlap -x $f_mismatchRatio -r $averRead -f $averFragment -s $standardDeviation -o FLASH -O > FLASH.log
			if [ "$?" = "0" ]; then
 			echo "Assembling sequneces with FLASH, done"
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi
	
	mv FLASH.extendedFrags.fastq R1_R2_FLASH.fastq

	#Set trimming options
	v_truncqual=$(cat ${USER_HOME}/.var_babitas/v_truncqual.txt)
	v_maxee=$(cat ${USER_HOME}/.var_babitas/v_maxee.txt)
	v_maxee_rate=$(cat ${USER_HOME}/.var_babitas/v_maxee_rate.txt)
	v_minlen=$(cat ${USER_HOME}/.var_babitas/v_minlen.txt)
	v_maxambig=$(cat ${USER_HOME}/.var_babitas/v_maxambig.txt)

	
	echo ""
	echo "Trimming options ->"
	echo "truncqual =" $v_truncqual
	echo "maxee =" $v_maxee
	echo "maxee_rate =" $v_maxee_rate
	echo "minlength =" $v_minlen
	echo "maxambig =" $v_maxambig
	echo ""

	#Trimming with vsearch
	echo "# Trimming with vsearch ... "
	echo "vsearch --fastq_filter R1_R2_FLASH.fastq --fastq_truncqual $v_truncqual --fastq_maxee $v_maxee --fastq_maxee_rate $v_maxee_rate --fastq_minlen $v_minlen --fastq_maxns $v_maxambig --fastqout_discarded vsearchTrim_discarded.fastq --fastqout flashMerge_vsearchTrim.fastq"

	vsearch --fastq_filter R1_R2_FLASH.fastq --fastq_truncqual $v_truncqual --fastq_maxee $v_maxee --fastq_maxee_rate $v_maxee_rate --fastq_minlen $v_minlen --fastq_maxns $v_maxambig --fastqout_discarded vsearchTrim_discarded.fastq --fastqout flashMerge_vsearchTrim.fastq
			if [ "$?" = "0" ]; then
			touch ${USER_HOME}/.var_babitas/Trimming_finished.txt
			out_size=$(echo $(cat flashMerge_vsearchTrim.fastq | wc -l) / 4 | bc)
			echo ""
			echo "##########################"
			echo "DONE"
			echo "############################"
			echo "First ASSEMBLE with FLASH (with averRead), then perform quality TRIMMING with vsearch, finished"
			echo "##############################"
			echo "output = flashMerge_vsearchTrim.fastq, contains $out_size sequences"
			echo "################################"
			echo "You may close this window now!"

				else 
				touch ${USER_HOME}/.var_babitas/Trimming_error.txt
				echo "An unexpected error has occurred!  Aborting." 1>&2
				exit 1
			fi
	fi
fi




#############################################################################
#############################################################################
###First ASSEMBLE with vsearch, then perform quality TRIMMING with vsearch###
#############################################################################
#############################################################################
if grep -q 'First ASSEMBLE with vsearch, then perform quality TRIMMING with vsearch' ${USER_HOME}/.var_babitas/workflow_chosen.txt; then

echo "## Workflow = First ASSEMBLE with vsearch, then perform quality TRIMMING with vsearch ##"
echo ""

#Set assembling options
va_minOverlap=$(cat ${USER_HOME}/.var_babitas/va_minOverlap.txt)
va_maxDiffs=$(cat ${USER_HOME}/.var_babitas/va_maxDiffs.txt)
va_minlen=$(cat ${USER_HOME}/.var_babitas/va_minlen.txt)
va_maxee=$(cat ${USER_HOME}/.var_babitas/va_maxee.txt)
va_maxambig=$(cat ${USER_HOME}/.var_babitas/va_maxambig.txt)
va_truncqual=$(cat ${USER_HOME}/.var_babitas/va_truncqual.txt)

echo "Assembling options ->"
echo "minOverlap =" $va_minOverlap
echo "maxDiffs =" $va_maxDiffs
echo "minlength =" $va_minlen
echo "maxee ="  $va_maxee
echo "maxambig =" $va_maxambig
echo "truncqual =" $va_truncqual

	if [ -e ${USER_HOME}/.var_babitas/va_allowstagger.txt ]; then
	va_allowstagger=$(cat ${USER_HOME}/.var_babitas/va_allowstagger.txt)
	
	echo "allowstagger = T"
	echo ""
	echo "# Assembling sequneces with vsearch ..."
	echo "vsearch --fastq_mergepairs $R1fastq --reverse $R2fastq --fastq_minovlen $va_minOverlap --maxdiffs $va_maxDiffs --fastq_minmergelen $va_minlen --fastq_maxee $va_maxee --fastq_maxns $va_maxambig --fastq_truncqual $va_truncqual --fastq_allowmergestagger --fastqout_notmerged_fwd notmerged_fwd.fastq --fastqout_notmerged_rev notmerged_rev.fastq --fastqout vsearchMerge.fastq"

	vsearch --fastq_mergepairs $R1fastq --reverse $R2fastq --fastq_minovlen $va_minOverlap --maxdiffs $va_maxDiffs --fastq_minmergelen $va_minlen --fastq_maxee $va_maxee --fastq_maxns $va_maxambig --fastq_truncqual $va_truncqual --fastq_allowmergestagger --fastqout_notmerged_fwd notmerged_fwd.fastq --fastqout_notmerged_rev notmerged_rev.fastq --fastqout vsearchMerge.fastq
			if [ "$?" = "0" ]; then
 			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi

	else
	echo ""
	echo "# Assembling sequneces with vsearch ..."
	echo "vsearch --fastq_mergepairs $R1fastq --reverse $R2fastq --fastq_minovlen $va_minOverlap --maxdiffs $va_maxDiffs --fastq_minmergelen $va_minlen --fastq_maxee $va_maxee --fastq_maxns $va_maxambig --fastq_truncqual $va_truncqual --fastqout_notmerged_fwd notmerged_fwd.fastq --fastqout_notmerged_rev notmerged_rev.fastq --fastqout vsearchMerge.fastq"

	vsearch --fastq_mergepairs $R1fastq --reverse $R2fastq --fastq_minovlen $va_minOverlap --maxdiffs $va_maxDiffs --fastq_minmergelen $va_minlen --fastq_maxee $va_maxee --fastq_maxns $va_maxambig --fastq_truncqual $va_truncqual --fastqout_notmerged_fwd notmerged_fwd.fastq --fastqout_notmerged_rev notmerged_rev.fastq --fastqout vsearchMerge.fastq
			if [ "$?" = "0" ]; then
 			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi
	fi	

#Set trimming options
v_truncqual=$(cat ${USER_HOME}/.var_babitas/v_truncqual.txt)
v_maxee=$(cat ${USER_HOME}/.var_babitas/v_maxee.txt)
v_maxee_rate=$(cat ${USER_HOME}/.var_babitas/v_maxee_rate.txt)
v_minlen=$(cat ${USER_HOME}/.var_babitas/v_minlen.txt)
v_maxambig=$(cat ${USER_HOME}/.var_babitas/v_maxambig.txt)

echo ""
echo "Trimming options ->"
echo "truncqual =" $v_truncqual
echo "maxee =" $v_maxee
echo "maxee_rate =" $v_maxee_rate
echo "minlength =" $v_minlen
echo "maxambig =" $v_maxambig
echo ""


echo "# Trimming with vsearch ... "
echo "vsearch --fastq_filter vsearchMerge.fastq --fastq_truncqual $v_truncqual --fastq_maxee $v_maxee --fastq_maxee_rate $v_maxee_rate --fastq_minlen $v_minlen --fastq_maxns $v_maxambig --fastqout_discarded vsearchTrim_discarded.fastq --fastqout vsearchMerge_vsearchTrim.fastq"

vsearch --fastq_filter vsearchMerge.fastq --fastq_truncqual $v_truncqual --fastq_maxee $v_maxee --fastq_maxee_rate $v_maxee_rate --fastq_minlen $v_minlen --fastq_maxns $v_maxambig --fastqout_discarded vsearchTrim_discarded.fastq --fastqout vsearchMerge_vsearchTrim.fastq
		if [ "$?" = "0" ]; then
		touch ${USER_HOME}/.var_babitas/Trimming_finished.txt
		out_size=$(echo $(cat vsearchMerge_vsearchTrim.fastq | wc -l) / 4 | bc)
		echo ""
		echo "##########################"
		echo "DONE"
		echo "############################"
		echo "First ASSEMBLE with vsearch, then perform quality TRIMMING with vsearch, finished"
		echo "##############################"
		echo "output = vsearchMerge_vsearchTrim.fastq, contains $out_size sequences"
		echo "################################"
		echo "You may close this window now!"

			else 
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
		fi
fi



############################################################################
############################################################################
###First ASSEMBLE with vsearch, then perform quality TRIMMING with mothur###
############################################################################
############################################################################
if grep -q 'First ASSEMBLE with vsearch, then perform quality TRIMMING with mothur' ${USER_HOME}/.var_babitas/workflow_chosen.txt; then

echo "## Workflow = First ASSEMBLE with vsearch, then perform quality TRIMMING with mothur ##"
echo ""

#Set assembling options
va_minOverlap=$(cat ${USER_HOME}/.var_babitas/va_minOverlap.txt)
va_maxDiffs=$(cat ${USER_HOME}/.var_babitas/va_maxDiffs.txt)
va_minlen=$(cat ${USER_HOME}/.var_babitas/va_minlen.txt)
va_maxee=$(cat ${USER_HOME}/.var_babitas/va_maxee.txt)
va_maxambig=$(cat ${USER_HOME}/.var_babitas/va_maxambig.txt)
va_truncqual=$(cat ${USER_HOME}/.var_babitas/va_truncqual.txt)

echo "Assembling options ->"
echo "minOverlap =" $va_minOverlap
echo "maxDiffs =" $va_maxDiffs
echo "minlength =" $va_minlen
echo "maxee ="  $va_maxee
echo "maxambig =" $va_maxambig
echo "truncqual =" $va_truncqual

	if [ -e ${USER_HOME}/.var_babitas/va_allowstagger.txt ]; then
	va_allowstagger=$(cat ${USER_HOME}/.var_babitas/va_allowstagger.txt)

	echo "allowstagger = T"
	echo ""
	echo "# Assembling sequneces with vsearch ..."
	echo "vsearch --fastq_mergepairs $R1fastq --reverse $R2fastq --fastq_minovlen $va_minOverlap --maxdiffs $va_maxDiffs --fastq_minmergelen $va_minlen --fastq_maxee $va_maxee --fastq_maxns $va_maxambig --fastq_truncqual $va_truncqual --fastq_allowmergestagger --fastqout_notmerged_fwd notmerged_fwd.fastq --fastqout_notmerged_rev notmerged_rev.fastq --fastqout vsearchMerge.fastq"

	vsearch --fastq_mergepairs $R1fastq --reverse $R2fastq --fastq_minovlen $va_minOverlap --maxdiffs $va_maxDiffs --fastq_minmergelen $va_minlen --fastq_maxee $va_maxee --fastq_maxns $va_maxambig --fastq_truncqual $va_truncqual --fastq_allowmergestagger --fastqout_notmerged_fwd notmerged_fwd.fastq --fastqout_notmerged_rev notmerged_rev.fastq --fastqout vsearchMerge.fastq
			if [ "$?" = "0" ]; then
 			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi

	else
	echo ""
	echo "# Assembling sequneces with vsearch ..."
	echo "vsearch --fastq_mergepairs $R1fastq --reverse $R2fastq --fastq_minovlen $va_minOverlap --maxdiffs $va_maxDiffs --fastq_minmergelen $va_minlen --fastq_maxee $va_maxee --fastq_maxns $va_maxambig --fastq_truncqual $va_truncqual --fastqout_notmerged_fwd notmerged_fwd.fastq --fastqout_notmerged_rev notmerged_rev.fastq --fastqout vsearchMerge.fastq"

	vsearch --fastq_mergepairs $R1fastq --reverse $R2fastq --fastq_minovlen $va_minOverlap --maxdiffs $va_maxDiffs --fastq_minmergelen $va_minlen --fastq_maxee $va_maxee --fastq_maxns $va_maxambig --fastq_truncqual $va_truncqual --fastqout_notmerged_fwd notmerged_fwd.fastq --fastqout_notmerged_rev notmerged_rev.fastq --fastqout vsearchMerge.fastq 
			if [ "$?" = "0" ]; then
 			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi
	fi


#Set trimming options
qwindowaverage=$(cat ${USER_HOME}/.var_babitas/qwindowaverage.txt)
qwindowsize=$(cat ${USER_HOME}/.var_babitas/qwindowsize.txt)
minlength=$(cat ${USER_HOME}/.var_babitas/minlenght.txt)
maxambig=$(cat ${USER_HOME}/.var_babitas/maxambig.txt)
maxhomop=$(cat ${USER_HOME}/.var_babitas/maxhomop.txt)
processors=$(cat ${USER_HOME}/.var_babitas/processors.txt)

echo ""
echo "Trimming options ->"
echo "qwindowaverage =" $qwindowaverage
echo "qwindowsize =" $qwindowsize
echo "minlength =" $minlength
echo "maxambig =" $maxambig
echo "maxhomop =" $maxhomop
echo "processors =" $processors
echo ""


#Assembled fastq to fasta and qual
echo "# Assembled fastq to fasta and qual"

mothur "#fastq.info(fastq=vsearchMerge.fastq)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
		else
		echo ""
		fi

#Trimming with mothur
echo "# Trimming with mothur ... "

mothur "#trim.seqs(fasta=vsearchMerge.fasta, qfile=vsearchMerge.qual, qwindowaverage=$qwindowaverage, qwindowsize=$qwindowsize, minlength=$minlength, maxambig=$maxambig, maxhomop=$maxhomop, processors=$processors)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
		else
		echo ""
		fi

#Fasta and qual back to fastq
mothur "#make.fastq(fasta=vsearchMerge.trim.fasta, qfile=vsearchMerge.trim.qual)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
		else
		touch ${USER_HOME}/.var_babitas/Trimming_finished.txt
		mv vsearchMerge.trim.fastq vsearchMerge_mothurTrim.fastq
		out_size=$(echo $(cat vsearchMerge_mothurTrim.fastq | wc -l) / 4 | bc)
		echo ""
		echo "##########################"
		echo "DONE"
		echo "############################"
		echo "First ASSEMBLE with vsearch, then perform quality TRIMMING with mothur, finished"
		echo "##############################"
		echo "output = vsearchMerge_mothurTrim.fastq, contains $out_size sequences"
		echo "################################"
		echo "You may close this window now!"
		fi

fi



################################
################################
### ASSEMBLING with PANDAseq ###
################################
################################
if grep -q 'ASSEMBLING with PANDAseq' ${USER_HOME}/.var_babitas/workflow_chosen.txt; then

echo "## Workflow = ASSEMBLING with PANDAseq ##"
echo ""

#Set assembling options
p_minOverlap=$(cat ${USER_HOME}/.var_babitas/p_minOverlap.txt)
p_maxOverlap=$(cat ${USER_HOME}/.var_babitas/p_maxOverlap.txt)
p_maxlength=$(cat ${USER_HOME}/.var_babitas/p_maxlength.txt)
p_minphred=$(cat ${USER_HOME}/.var_babitas/p_minphred.txt)
p_minlength=$(cat ${USER_HOME}/.var_babitas/p_minlength.txt)

echo "Assembling options ->"
echo "minOverlap =" $p_minOverlap
echo "maxOverlap =" $p_maxOverlap
echo "maxlength =" $p_maxlength
echo "minphred ="  $p_minphred
echo "minlength =" $p_minlength

#Starting to assemble sequneces with PandaSeq
echo "# Assembling sequneces with PandaSeq ..."
echo "pandaseq -f $R1fastq -r $R2fastq -F -B -o $p_minOverlap -O $p_maxOverlap -L $p_maxlength -C min_phred:$p_minphred -l $p_minlength -g PANDAseq.log > pandaMerge.fastq"

pandaseq -f $R1fastq -r $R2fastq -F -B -o $p_minOverlap -O $p_maxOverlap -L $p_maxlength -C min_phred:$p_minphred -l $p_minlength -g PANDAseq.log > pandaMerge.fastq
		if [ "$?" = "0" ]; then
		touch ${USER_HOME}/.var_babitas/Trimming_finished.txt
		out_size=$(echo $(cat pandaMerge.fastq | wc -l) / 4 | bc)
		echo ""
		echo "##########################"
		echo "DONE"
		echo "############################"
		echo "ASSEMBLING with PANDAseq, finished"
		echo "##############################"
		echo "output = pandaMerge.fastq, contains $out_size sequences"
		echo "################################"
		echo "You may close this window now!"

			else 
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
		fi
fi




############################
############################
###ASSEMBLING with FLASH ###
############################
############################
if grep -q 'ASSEMBLING with FLASH' ${USER_HOME}/.var_babitas/workflow_chosen.txt && [ -e ${USER_HOME}/.var_babitas/f_maxOverlap.txt ]; then

echo "## Workflow = ASSEMBLING with FLASH ##"
echo ""

#Set assembling options
f_minOverlap=$(cat ${USER_HOME}/.var_babitas/f_minOverlap.txt)
f_maxOverlap=$(cat ${USER_HOME}/.var_babitas/f_maxOverlap.txt)
f_mismatchRatio=$(cat ${USER_HOME}/.var_babitas/f_mismatchRatio.txt)

echo "Assembling options ->"
echo "minOverlap =" $f_minOverlap
echo "maxOverlap =" $f_maxOverlap
echo "mismatchRatio = $f_mismatchRatio"

#Starting to assemble sequneces with FLASH
echo ""
echo "# Assembling sequneces with FLASH ..."
echo "flash $R1fastq $R2fastq -m $f_minOverlap -M $f_maxOverlap -x $f_mismatchRatio -o FLASH -O > FLASH.log"

flash $R1fastq $R2fastq -m $f_minOverlap -M $f_maxOverlap -x $f_mismatchRatio -o FLASH -O > FLASH.log
		if [ "$?" = "0" ]; then
		touch ${USER_HOME}/.var_babitas/Trimming_finished.txt
		mv FLASH.extendedFrags.fastq flashMerge.fastq
		out_size=$(echo $(cat flashMerge.fastq | wc -l) / 4 | bc)
		echo ""
		echo "##########################"
		echo "DONE"
		echo "############################"
		echo "ASSEMBLING with FLASH with maxOverlap, finished"
		echo "##############################"
		echo "output = flashMerge.fastq, contains $out_size sequences"
		echo "################################"
		echo "You may close this window now!"

			else 
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
		fi




	else
	if grep -q 'ASSEMBLING with FLASH' ${USER_HOME}/.var_babitas/workflow_chosen.txt && [ -e ${USER_HOME}/.var_babitas/averRead.txt ]; then

	echo "## Workflow = ASSEMBLING with FLASH ##"
	echo ""
		
	#Set assembling options
	f_minOverlap=$(cat ${USER_HOME}/.var_babitas/f_minOverlap.txt)
	f_mismatchRatio=$(cat ${USER_HOME}/.var_babitas/f_mismatchRatio.txt)
	averRead=$(cat ${USER_HOME}/.var_babitas/averRead.txt)
	averFragment=$(cat ${USER_HOME}/.var_babitas/averFragment.txt)
	standardDeviation=$(cat ${USER_HOME}/.var_babitas/standardDeviation.txt)

	echo "Assembling options ->"
	echo "minOverlap =" $f_minOverlap
	echo "maxOverlap =" $f_maxOverlap
	echo "averRead = $averRead"
	echo "averFragment = $averFragment"
	echo "standardDeviation = $standardDeviation"
	echo ""
		
	#Starting to assemble sequneces with FLASH
	echo "# Assembling sequneces with FLASH ..."
	echo "flash $R1fastq $R2fastq -m $f_minOverlap -x $f_mismatchRatio -r $averRead -f $averFragment -s $standardDeviation -o FLASH -O > FLASH.log"

	flash $R1fastq $R2fastq -m $f_minOverlap -x $f_mismatchRatio -r $averRead -f $averFragment -s $standardDeviation -o FLASH -O > FLASH.log
		if [ "$?" = "0" ]; then
		touch ${USER_HOME}/.var_babitas/Trimming_finished.txt
		mv FLASH.extendedFrags.fastq flashMerge.fastq
		out_size=$(echo $(cat flashMerge.fastq | wc -l) / 4 | bc)
		echo ""
		echo "##########################"
		echo "DONE"
		echo "############################"
		echo "ASSEMBLING with FLASH averRead, finished"
		echo "##############################"
		echo "output = flashMerge.fastq, contains $out_size sequences"
		echo "################################"
		echo "You may close this window now!"

			else 
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
		fi
	fi
fi



##############################
##############################
###ASSEMBLING with vsearch ###
##############################
##############################
if grep -q 'ASSEMBLING with vsearch' ${USER_HOME}/.var_babitas/workflow_chosen.txt; then

echo "## Workflow = ASSEMBLING with vsearch ##"
echo ""


#Set assembling options
va_minOverlap=$(cat ${USER_HOME}/.var_babitas/va_minOverlap.txt)
va_maxDiffs=$(cat ${USER_HOME}/.var_babitas/va_maxDiffs.txt)
va_minlen=$(cat ${USER_HOME}/.var_babitas/va_minlen.txt)
va_maxee=$(cat ${USER_HOME}/.var_babitas/va_maxee.txt)
va_maxambig=$(cat ${USER_HOME}/.var_babitas/va_maxambig.txt)
va_truncqual=$(cat ${USER_HOME}/.var_babitas/va_truncqual.txt)


echo "Minimum overlap =" $va_minOverlap
echo "Max differences =" $va_maxDiffs
echo "Minimum length =" $va_minlen
echo "E_max = " $va_maxee
echo "Max ambiguous = " $va_maxambig
echo "Trunc qual = " $va_truncqual

	if [ -e ${USER_HOME}/.var_babitas/va_allowstagger.txt ]; then
	va_allowstagger=$(cat ${USER_HOME}/.var_babitas/va_allowstagger.txt)

	echo "allowstagger = T"
	echo ""
	echo "# Assembling sequneces with vsearch ..."
	echo "vsearch --fastq_mergepairs $R1fastq --reverse $R2fastq --fastq_minovlen $va_minOverlap --maxdiffs $va_maxDiffs --fastq_minmergelen $va_minlen --fastq_maxee $va_maxee --fastq_maxns $va_maxambig --fastq_truncqual $va_truncqual --fastq_allowmergestagger --fastqout_notmerged_fwd notmerged_fwd.fastq --fastqout_notmerged_rev notmerged_rev.fastq --fastqout vsearchMerge.fastq"

	vsearch --fastq_mergepairs $R1fastq --reverse $R2fastq --fastq_minovlen $va_minOverlap --maxdiffs $va_maxDiffs --fastq_minmergelen $va_minlen --fastq_maxee $va_maxee --fastq_maxns $va_maxambig --fastq_truncqual $va_truncqual --fastq_allowmergestagger --fastqout_notmerged_fwd notmerged_fwd.fastq --fastqout_notmerged_rev notmerged_rev.fastq --fastqout vsearchMerge.fastq
		if [ "$?" = "0" ]; then
		touch ${USER_HOME}/.var_babitas/Trimming_finished.txt
		out_size=$(echo $(cat vsearchMerge.fastq | wc -l) / 4 | bc)
		echo ""
		echo "##########################"
		echo "DONE"
		echo "############################"
		echo "ASSEMBLING with vsearch, finished"
		echo "##############################"
		echo "output = vsearchMerge.fastq, contains $out_size sequences"
		echo "################################"
		echo "You may close this window now!"

			else 
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
		fi

	else
	echo ""
	echo "# Assembling sequneces with vsearch ..."
	echo "vsearch --fastq_mergepairs $R1fastq --reverse $R2fastq --fastq_minovlen $va_minOverlap --maxdiffs $va_maxDiffs --fastq_minmergelen $va_minlen --fastq_maxee $va_maxee --fastq_maxns $va_maxambig --fastq_truncqual $va_truncqual --fastqout_notmerged_fwd notmerged_fwd.fastq --fastqout_notmerged_rev notmerged_rev.fastq --fastqout vsearchMerge.fastq "

	vsearch --fastq_mergepairs $R1fastq --reverse $R2fastq --fastq_minovlen $va_minOverlap --maxdiffs $va_maxDiffs --fastq_minmergelen $va_minlen --fastq_maxee $va_maxee --fastq_maxns $va_maxambig --fastq_truncqual $va_truncqual --fastqout_notmerged_fwd notmerged_fwd.fastq --fastqout_notmerged_rev notmerged_rev.fastq --fastqout vsearchMerge.fastq 
		if [ "$?" = "0" ]; then
		touch ${USER_HOME}/.var_babitas/Trimming_finished.txt
		out_size=$(echo $(cat vsearchMerge.fastq | wc -l) / 4 | bc)
		echo ""
		echo "##########################"
		echo "DONE"
		echo "############################"
		echo "ASSEMBLING with vsearch, finished"
		echo "##############################"
		echo "output = vsearchMerge.fastq, contains $out_size sequences"
		echo "################################"
		echo "You may close this window now!"

			else 
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
		fi
	fi
fi




######################################################
######################################################
###Only quality TRIMMING with mothur, no assembling###
######################################################
######################################################
if grep -q 'Only quality TRIMMING with mothur, no assembling' ${USER_HOME}/.var_babitas/workflow_chosen.txt; then

echo "## Workflow = Only quality TRIMMING with mothur, no assembling ##"
echo ""

#Set trimming options
qwindowaverage=$(cat ${USER_HOME}/.var_babitas/qwindowaverage.txt)
qwindowsize=$(cat ${USER_HOME}/.var_babitas/qwindowsize.txt)
minlength=$(cat ${USER_HOME}/.var_babitas/minlenght.txt)
maxambig=$(cat ${USER_HOME}/.var_babitas/maxambig.txt)
maxhomop=$(cat ${USER_HOME}/.var_babitas/maxhomop.txt)
processors=$(cat ${USER_HOME}/.var_babitas/processors.txt)

echo "Trimming options ->"
echo "qwindowaverage =" $qwindowaverage
echo "qwindowsize =" $qwindowsize
echo "minlength =" $minlength
echo "maxambig =" $maxambig
echo "maxhomop =" $maxhomop
echo "processors =" $processors
echo ""

#Rename fastq inputs
cp $R1fastq R1r.fastq
cp $R2fastq R2r.fastq

#Fastq files to fasta and qual
echo "# Fastq files to fasta and qual"

mothur "#fastq.info(fastq=R1r.fastq)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
		else
		echo ""
		fi

mothur "#fastq.info(fastq=R2r.fastq)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
		else
		echo ""
		fi

rm R1r.fastq
rm R2r.fastq

#Trimming with mothur
echo "# Trimming with mothur ... "

mothur "#trim.seqs(fasta=R1r.fasta, qfile=R1r.qual, qwindowaverage=$qwindowaverage, qwindowsize=$qwindowsize, minlength=$minlength, maxambig=$maxambig, maxhomop=$maxhomop, processors=$processors)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
		else
		echo ""
		fi

mothur "#trim.seqs(fasta=R2r.fasta, qfile=R2r.qual, qwindowaverage=$qwindowaverage, qwindowsize=$qwindowsize, minlength=$minlength, maxambig=$maxambig, maxhomop=$maxhomop, processors=$processors)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
		else
		echo ""
		fi

#Converting fasta and qual back to fastq
echo "# Converting fasta and qual back to fastq"

mothur "#make.fastq(fasta=R1r.trim.fasta, qfile=R1r.trim.qual)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
		else
		echo ""
		fi

mothur "#make.fastq(fasta=R2r.trim.fasta, qfile=R2r.trim.qual)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
		else
		echo ""
		fi

mv R1r.trim.fastq R1_mothurTrim.fastq
mv R2r.trim.fastq R2_mothurTrim.fastq
		if [ "$?" = "0" ]; then
		touch ${USER_HOME}/.var_babitas/Trimming_finished.txt
		R1out_size=$(echo $(cat R1_mothurTrim.fastq | wc -l) / 4 | bc)
		R1out_size=$(echo $(cat R2_mothurTrim.fastq | wc -l) / 4 | bc)
		echo ""
		echo "##########################"
		echo "DONE"
		echo "############################"
		echo "Only quality TRIMMING with mothur, no assembling, finished"
		echo "##############################"
		echo "output R1 = R1_mothurTrim.fastq, contains $R1out_size sequences"
		echo "output R2 = R2_mothurTrim.fastq, contains $R2out_size sequences"
		echo "################################"
		echo "You may close this window now!"

			else 
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
		fi
fi




#######################################################
#######################################################
###Only quality TRIMMING with vsearch, no assembling###
#######################################################
#######################################################
if grep -q 'Only quality TRIMMING with vsearch, no assembling' ${USER_HOME}/.var_babitas/workflow_chosen.txt; then

echo "## Workflow = Only quality TRIMMING with vsearch, no assembling ##"
echo ""

#Set trimming options
v_truncqual=$(cat ${USER_HOME}/.var_babitas/v_truncqual.txt)
v_maxee=$(cat ${USER_HOME}/.var_babitas/v_maxee.txt)
v_maxee_rate=$(cat ${USER_HOME}/.var_babitas/v_maxee_rate.txt)
v_minlen=$(cat ${USER_HOME}/.var_babitas/v_minlen.txt)
v_maxambig=$(cat ${USER_HOME}/.var_babitas/v_maxambig.txt)

	echo "Trimming options ->"
	echo "truncqual =" $v_truncqual
	echo "maxee =" $v_maxee
	echo "maxee_rate =" $v_maxee_rate
	echo "minlength =" $v_minlen
	echo "maxambig =" $v_maxambig
	echo ""

echo "# Trimming with vsearch ... "
echo "vsearch --fastq_filter $R1fastq --fastq_truncqual $v_truncqual --fastq_maxee $v_maxee --fastq_maxee_rate $v_maxee_rate --fastq_minlen $v_minlen --fastq_maxns $v_maxambig --fastqout_discarded vsearchTrim_discarded.fastq --fastqout R1_vsearchTrim.fastq"

vsearch --fastq_filter $R1fastq --fastq_truncqual $v_truncqual --fastq_maxee $v_maxee --fastq_maxee_rate $v_maxee_rate --fastq_minlen $v_minlen --fastq_maxns $v_maxambig --fastqout_discarded vsearchTrim_discarded.fastq --fastqout R1_vsearchTrim.fastq
			if [ "$?" = "0" ]; then
 			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi

echo ""
echo "vsearch --fastq_filter $R2fastq --fastq_truncqual $v_truncqual --fastq_maxee $v_maxee --fastq_maxee_rate $v_maxee_rate --fastq_minlen $v_minlen --fastq_maxns $v_maxambig --fastqout_discarded vsearchTrim_discarded.fastq --fastqout R2_vsearchTrim.fastq"

vsearch --fastq_filter $R2fastq --fastq_truncqual $v_truncqual --fastq_maxee $v_maxee --fastq_maxee_rate $v_maxee_rate --fastq_minlen $v_minlen --fastq_maxns $v_maxambig --fastqout_discarded vsearchTrim_discarded.fastq --fastqout R2_vsearchTrim.fastq
		if [ "$?" = "0" ]; then
		touch ${USER_HOME}/.var_babitas/Trimming_finished.txt
		R1out_size=$(echo $(cat R1_vsearchTrim.fastq | wc -l) / 4 | bc)
		R2out_size=$(echo $(cat R2_vsearchTrim.fastq | wc -l) / 4 | bc)
		echo ""
		echo "##########################"
		echo "DONE"
		echo "############################"
		echo "Only quality TRIMMING with vsearch, no assembling, finished"
		echo "##############################"
		echo "output R1 = R1_vsearchTrim.fastq, contains $R1out_size sequences"
		echo "output R2 = R2_vsearchTrim.fastq, contains $R2out_size sequences"
		echo "################################"
		echo "You may close this window now!"

			else 
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
		fi
fi



#Delete mothur_logfiles
if ls mothur.*.logfile 1> /dev/null 2>&1; then
	rm *.logfile
fi

