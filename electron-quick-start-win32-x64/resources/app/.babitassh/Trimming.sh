#!/bin/bash 



echo "### Quality filtering ###"
echo ""
echo "When using the incorporated tools, please cite as follows:"
echo ""
echo "mothur - Schloss, P.D., et al., 2009. Introducing mothur: Open-Source, Platform-Independent, Community-Supported Software for Describing and Comparing Microbial Communities. Applied and Environmental Microbiology 75, 7537-7541."
echo "Distributed under the GNU General Public License version 2 by the Free Software Foundation"
echo "www.mothur.org"
echo ""
echo "vsearch - github.com/torognes/vsearch"
echo "Copyright (C) 2014-2015, Torbjorn Rognes, Frederic Mahe and Tomas Flouri."
echo "Distributed under the GNU General Public License version 3 by the Free Software Foundation"
echo ""
echo "OBITools (v1.2.9) - Boyer F., Mercier C., Bonin A., et al., 2016. OBITOOLS: a UNIX-inspired software package for DNA metabarcoding. Molecular Ecology Resources 16, 176-182."
echo "Distributed under the CeCILL free software licence version 2"
echo "metabarcoding.org//obitools/doc/index.html"
echo "________________________________________________"


USER_HOME=$(eval echo ~${SUDO_USER})

	

#Set working directory and input file variable
if [ -e ${USER_HOME}/.var_babitas/fastq_input.txt ]; then
	WorkingDirectory=$(awk 'BEGIN{FS=OFS="/"} NF{NF--};1' < ${USER_HOME}/.var_babitas/fastq_input.txt)
	
	input=$(cat ${USER_HOME}/.var_babitas/fastq_input.txt | awk 'BEGIN{FS=OFS="."} NF{NF--};1')

	format=$(cat ${USER_HOME}/.var_babitas/fastq_input.txt | (awk 'BEGIN{FS=OFS="."} {print $NF}';))

	cd $WorkingDirectory
			if [ "$?" = "0" ]; then
			echo "Working directory = "$WorkingDirectory
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/CCS_error.txt && echo "ERROR occured: Unable to open working directory" 1>&2 && echo "Close this window" && exit 1
			fi


	if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
		fastq_size=$(echo $(cat $input.fastq | wc -l) / 4 | bc)
		echo "Input = "$input.fastq
		echo "Input fastq contains $fastq_size sequences"
	fi
	
	if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
		fasta_size=$(grep -c "^>" $input.fasta)
		echo "Input = "$input.fasta
		echo "Input fasta contains $fasta_size sequences"
	fi

else 
	echo "# ERROR: no input file"
fi





############################
############################
### Trimming with mothur ###
############################
############################
if [ -e ${USER_HOME}/.var_babitas/qwindowaverage.txt ]; then



#Set trimming options
qwindowaverage=$(cat ${USER_HOME}/.var_babitas/qwindowaverage.txt)
qwindowsize=$(cat ${USER_HOME}/.var_babitas/qwindowsize.txt)
minlength=$(cat ${USER_HOME}/.var_babitas/minlenght.txt)
maxambig=$(cat ${USER_HOME}/.var_babitas/maxambig.txt)
maxhomop=$(cat ${USER_HOME}/.var_babitas/maxhomop.txt)
processors=$(cat ${USER_HOME}/.var_babitas/processors.txt)

echo "Filtering options ->"
echo "qwindowaverage =" $qwindowaverage
echo "qwindowsize =" $qwindowsize
echo "minlength =" $minlength
echo "maxambig =" $maxambig
echo "maxhomop =" $maxhomop
echo "processors =" $processors
echo ""


#Fastq files to fasta and qual
echo "# Fastq file to fasta and qual"

mothur "#fastq.info(fastq=$input.fastq)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
		else
		echo ""
		fi


#Trimming with mothur
echo "# Filtering with mothur ... "

mothur "#trim.seqs(fasta=$input.fasta, qfile=$input.qual, qwindowaverage=$qwindowaverage, qwindowsize=$qwindowsize, minlength=$minlength, maxambig=$maxambig, maxhomop=$maxhomop, processors=$processors)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
		else
		echo ""
		fi


	fasta_trim_size=$(grep -c "^>" $input.trim.fasta)
	

#Converting fasta and qual back to fastq
echo "# Converting fasta and qual back to fastq"

mothur "#make.fastq(fasta=$input.trim.fasta, qfile=$input.trim.qual)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
		else
		touch ${USER_HOME}/.var_babitas/Trimming_finished.txt
		echo ""
		echo "##########################"
		echo "DONE"
		echo "############################"
		echo "Quality filtering with mothur, finished"
		echo "##############################"
		echo "output = $input.trim.fastq, contains $fasta_trim_size sequences"
		echo "################################"
		echo "You may close this window now!"
		fi



#Delete mothur_logfiles
if ls mothur.*.logfile 1> /dev/null 2>&1; then
	rm *.logfile
fi








#############################
#############################
### Trimming with VSEARCH ###
#############################
#############################
else if [ -e ${USER_HOME}/.var_babitas/v_maxee.txt ]; then

#Set trimming options
v_truncqual=$(cat ${USER_HOME}/.var_babitas/v_truncqual.txt)
v_maxee=$(cat ${USER_HOME}/.var_babitas/v_maxee.txt)
v_maxee_rate=$(cat ${USER_HOME}/.var_babitas/v_maxee_rate.txt)
v_minlen=$(cat ${USER_HOME}/.var_babitas/v_minlen.txt)
v_maxambig=$(cat ${USER_HOME}/.var_babitas/v_maxambig.txt)
qmax=$(cat ${USER_HOME}/.var_babitas/qmax.txt)

echo "Filtering options ->"
echo "truncqual =" $v_truncqual
echo "maxee =" $v_maxee
echo "maxee_rate =" $v_maxee_rate
echo "minlength =" $v_minlen
echo "maxambig =" $v_maxambig
echo "qmax =" $qmax
echo ""


echo "# Filtering with vsearch ... "
echo "vsearch --fastq_filter $input.fastq --fastq_qmax $qmax --fastq_truncqual $v_truncqual --fastq_maxee $v_maxee --fastq_maxee_rate $v_maxee_rate --fastq_minlen $v_minlen --fastq_maxns $v_maxambig --fastqout_discarded $input.scrap.fastq --fastqout $input.trim.fastq"

vsearch --fastq_filter $input.fastq --fastq_qmax $qmax --fastq_truncqual $v_truncqual --fastq_maxee $v_maxee --fastq_maxee_rate $v_maxee_rate --fastq_minlen $v_minlen --fastq_maxns $v_maxambig --fastqout_discarded $input.scrap.fastq --fastqout $input.trim.fastq
			if [ "$?" = "0" ]; then
			touch ${USER_HOME}/.var_babitas/Trimming_finished.txt
			fastq_trim_size=$(echo $(cat $input.trim.fastq | wc -l) / 4 | bc)
			echo ""
			echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Quality filtering with vsearch, finished"
			echo "##############################"
			echo "output = $input.trim.fastq, contains $fastq_trim_size sequences"
			echo "################################"
			echo "You may close this window now!"

				else 
				touch ${USER_HOME}/.var_babitas/Trimming_error.txt
				echo "An unexpected error has occurred!  Aborting." 1>&2
				exit 1
			fi



##############################
##############################
### Trimming with OBITools ###
##############################
##############################
else if [ -e ${USER_HOME}/.var_babitas/dist.txt ]; then
PATH=$PATH:/dependencies/OBITools-1.2.9/OBITools-1.2.9/export/bin && export PATH

#Set trimming options
dist=$(cat ${USER_HOME}/.var_babitas/dist.txt)
ratio=$(cat ${USER_HOME}/.var_babitas/ratio.txt)

echo "Filtering options ->"
echo "distance =" $dist
echo "ratio =" $ratio
if [ -e ${USER_HOME}/.var_babitas/clust.txt ]; then
echo "cluster = T"
fi
if [ -e ${USER_HOME}/.var_babitas/head.txt ]; then
echo "head = T"
fi
echo ""

	#if input=fasta
	if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then

		if [ -e ${USER_HOME}/.var_babitas/o_maxambig.txt ]; then

		o_maxambig=$(cat ${USER_HOME}/.var_babitas/o_maxambig.txt)
		echo "# Max N's = $o_maxambig; filtering"

		mothur "#trim.seqs(fasta=$input.fasta, maxambig=$o_maxambig)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
	 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
			else
			echo ""
			fi


		mv $input.trim.fasta $input.maxambig$o_maxambig.fasta
		mothur "#unique.seqs(fasta=$input.maxambig$o_maxambig.fasta)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
		 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
				else
				echo ""
				fi

		

		echo "# Filtering with OBITools"
		echo ""
	
			if [ -e ${USER_HOME}/.var_babitas/clust.txt ] && [ -e ${USER_HOME}/.var_babitas/head.txt ]; then
			echo "obiclean -d $dist -r $ratio -C -H $input.maxambig$o_maxambig.unique.fasta > $input.obiclean.fasta"
			obiclean -d $dist -r $ratio -C -H $input.maxambig$o_maxambig.unique.fasta > $input.obiclean.temp
				if [ "$?" = "0" ]; then
	 			echo ""
				else
				touch ${USER_HOME}/.var_babitas/Trimming_error.txt
				exit 1
				fi

			obiannotate -k none $input.obiclean.temp > $input.obiclean.fasta
				if [ "$?" = "0" ]; then
				rm $input.obiclean.temp
	 			echo ""
				else
				touch ${USER_HOME}/.var_babitas/Trimming_error.txt
				exit 1
				fi

			mothur "#deunique.seqs(fasta=$input.obiclean.fasta, name=$input.maxambig$o_maxambig.names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
		 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
				else
				touch ${USER_HOME}/.var_babitas/Trimming_finished.txt
				fasta_trim_size=$(grep -c "^>" $input.obiclean.redundant.fasta)
				echo ""
				echo "##########################"
				echo "DONE"
				echo "############################"
				echo "Filtering with OBITools, finished"
				echo "##############################"
				echo "output = $input.obiclean.redundant.fasta, contains $fasta_trim_size sequences"
				echo "################################"
				echo "You may close this window now!"
				fi
		
			else if [ -e ${USER_HOME}/.var_babitas/head.txt ]; then
			echo "obiclean -d $dist -r $ratio -H $input.maxambig$o_maxambig.unique.fasta > $input.obiclean.fasta"
			obiclean -d $dist -r $ratio -H $input.maxambig$o_maxambig.unique.fasta > $input.obiclean.temp
				if [ "$?" = "0" ]; then
	 			echo ""
				else
				touch ${USER_HOME}/.var_babitas/Trimming_error.txt
				exit 1
				fi

			obiannotate -k none $input.obiclean.temp > $input.obiclean.fasta
				if [ "$?" = "0" ]; then
				rm $input.obiclean.temp
	 			echo ""
				else
				touch ${USER_HOME}/.var_babitas/Trimming_error.txt
				exit 1
				fi

			mothur "#deunique.seqs(fasta=$input.obiclean.fasta, name=$input.maxambig$o_maxambig.names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
		 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
				else
				touch ${USER_HOME}/.var_babitas/Trimming_finished.txt
				fasta_trim_size=$(grep -c "^>" $input.obiclean.redundant.fasta)
				echo ""
				echo "##########################"
				echo "DONE"
				echo "############################"
				echo "Filtering with OBITools, finished"
				echo "##############################"
				echo "output = $input.obiclean.redundant.fasta, contains $fasta_trim_size sequences"
				echo "################################"
				echo "You may close this window now!"
				fi

			else if [ -e ${USER_HOME}/.var_babitas/clust.txt ]; then
			echo "obiclean -d $dist -r $ratio -C $input.maxambig$o_maxambig.unique.fasta > $input.obiclean.fasta"
			obiclean -d $dist -r $ratio -C $input.maxambig$o_maxambig.unique.fasta > $input.obiclean.temp
				if [ "$?" = "0" ]; then
	 			echo ""
				else
				touch ${USER_HOME}/.var_babitas/Trimming_error.txt
				exit 1
				fi

			obiannotate -k none $input.obiclean.temp > $input.obiclean.fasta
				if [ "$?" = "0" ]; then
				rm $input.obiclean.temp
	 			echo ""
				else
				touch ${USER_HOME}/.var_babitas/Trimming_error.txt
				exit 1
				fi

			mothur "#deunique.seqs(fasta=$input.obiclean.fasta, name=$input.maxambig$o_maxambig.names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
		 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
				else
				touch ${USER_HOME}/.var_babitas/Trimming_finished.txt
				fasta_trim_size=$(grep -c "^>" $input.obiclean.redundant.fasta)
				echo ""
				echo "##########################"
				echo "DONE"
				echo "############################"
				echo "Filtering with OBITools, finished"
				echo "##############################"
				echo "output = $input.obiclean.redundant.fasta, contains $fasta_trim_size sequences"
				echo "################################"
				echo "You may close this window now!"
				fi


			else #if [ -e ${USER_HOME}/.var_babitas/o_maxambig.txt ]; then
			echo "obiclean -d $dist -r $ratio $input.maxambig$o_maxambig.unique.fasta > $input.obiclean.fasta"
			obiclean -d $dist -r $ratio $input.maxambig$o_maxambig.unique.fasta > $input.obiclean.temp
				if [ "$?" = "0" ]; then
	 			echo ""
				else
				touch ${USER_HOME}/.var_babitas/Trimming_error.txt
				exit 1
				fi

			obiannotate -k none $input.obiclean.temp > $input.obiclean.fasta
				if [ "$?" = "0" ]; then
				rm $input.obiclean.temp
	 			echo ""
				else
				touch ${USER_HOME}/.var_babitas/Trimming_error.txt
				exit 1
				fi

			mothur "#deunique.seqs(fasta=$input.obiclean.fasta, name=$input.maxambig$o_maxambig.names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
		 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
				else
				touch ${USER_HOME}/.var_babitas/Trimming_finished.txt
				fasta_trim_size=$(grep -c "^>" $input.obiclean.redundant.fasta)
				echo ""
				echo "##########################"
				echo "DONE"
				echo "############################"
				echo "Filtering with OBITools, finished"
				echo "##############################"
				echo "output = $input.obiclean.redundant.fasta, contains $fasta_trim_size sequences"
				echo "################################"
				echo "You may close this window now!"
				fi

				fi
				fi
				fi
				
			


	

	
		else #kui ei ole maxns

		mothur "#unique.seqs(fasta=$input.fasta)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
		 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
				else
				echo ""
				fi

		

		echo "# Filtering with OBITools"
		echo ""
	
			if [ -e ${USER_HOME}/.var_babitas/clust.txt ] && [ -e ${USER_HOME}/.var_babitas/head.txt ]; then
			echo "obiclean -d $dist -r $ratio -C -H $input.unique.fasta > $input.obiclean.fasta"
			obiclean -d $dist -r $ratio -C -H $input.unique.fasta > $input.obiclean.temp
				if [ "$?" = "0" ]; then
	 			echo ""
				else
				touch ${USER_HOME}/.var_babitas/Trimming_error.txt
				exit 1
				fi

			obiannotate -k none $input.obiclean.temp > $input.obiclean.fasta
				if [ "$?" = "0" ]; then
				rm $input.obiclean.temp
	 			echo ""
				else
				touch ${USER_HOME}/.var_babitas/Trimming_error.txt
				exit 1
				fi

			mothur "#deunique.seqs(fasta=$input.obiclean.fasta, name=$input.names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
		 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
				else
				touch ${USER_HOME}/.var_babitas/Trimming_finished.txt
				fasta_trim_size=$(grep -c "^>" $input.obiclean.redundant.fasta)
				echo ""
				echo "##########################"
				echo "DONE"
				echo "############################"
				echo "Filtering with OBITools, finished"
				echo "##############################"
				echo "output = $input.obiclean.redundant.fasta, contains $fasta_trim_size sequences"
				echo "################################"
				echo "You may close this window now!"
				fi
		
			else if [ -e ${USER_HOME}/.var_babitas/head.txt ]; then
			echo "obiclean -d $dist -r $ratio -H $input.unique.fasta > $input.obiclean.fasta"
			obiclean -d $dist -r $ratio -H $input.unique.fasta > $input.obiclean.temp
				if [ "$?" = "0" ]; then
	 			echo ""
				else
				touch ${USER_HOME}/.var_babitas/Trimming_error.txt
				exit 1
				fi

			obiannotate -k none $input.obiclean.temp > $input.obiclean.fasta
				if [ "$?" = "0" ]; then
				rm $input.obiclean.temp
	 			echo ""
				else
				touch ${USER_HOME}/.var_babitas/Trimming_error.txt
				exit 1
				fi

			mothur "#deunique.seqs(fasta=$input.obiclean.fasta, name=$input.names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
		 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
				else
				touch ${USER_HOME}/.var_babitas/Trimming_finished.txt
				fasta_trim_size=$(grep -c "^>" $input.obiclean.redundant.fasta)
				echo ""
				echo "##########################"
				echo "DONE"
				echo "############################"
				echo "Filtering with OBITools, finished"
				echo "##############################"
				echo "output = $input.obiclean.redundant.fasta, contains $fasta_trim_size sequences"
				echo "################################"
				echo "You may close this window now!"
				fi

			else if [ -e ${USER_HOME}/.var_babitas/clust.txt ]; then
			echo "obiclean -d $dist -r $ratio -C $input.unique.fasta > $input.obiclean.fasta"
			obiclean -d $dist -r $ratio -C $input.unique.fasta > $input.obiclean.temp
				if [ "$?" = "0" ]; then
	 			echo ""
				else
				touch ${USER_HOME}/.var_babitas/Trimming_error.txt
				exit 1
				fi

			obiannotate -k none $input.obiclean.temp > $input.obiclean.fasta
				if [ "$?" = "0" ]; then
				rm $input.obiclean.temp
	 			echo ""
				else
				touch ${USER_HOME}/.var_babitas/Trimming_error.txt
				exit 1
				fi

			mothur "#deunique.seqs(fasta=$input.obiclean.fasta, name=$input.names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
		 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
				else
				touch ${USER_HOME}/.var_babitas/Trimming_finished.txt
				fasta_trim_size=$(grep -c "^>" $input.obiclean.redundant.fasta)
				echo ""
				echo "##########################"
				echo "DONE"
				echo "############################"
				echo "Filtering with OBITools, finished"
				echo "##############################"
				echo "output = $input.obiclean.redundant.fasta, contains $fasta_trim_size sequences"
				echo "################################"
				echo "You may close this window now!"
				fi


			else 
			echo "obiclean -d $dist -r $ratio $input.unique.fasta > $input.obiclean.fasta"
			obiclean -d $dist -r $ratio $input.unique.fasta > $input.obiclean.temp
				if [ "$?" = "0" ]; then
	 			echo ""
				else
				touch ${USER_HOME}/.var_babitas/Trimming_error.txt
				exit 1
				fi

			obiannotate -k none $input.obiclean.temp > $input.obiclean.fasta
				if [ "$?" = "0" ]; then
				rm $input.obiclean.temp
	 			echo ""
				else
				touch ${USER_HOME}/.var_babitas/Trimming_error.txt
				exit 1
				fi

			mothur "#deunique.seqs(fasta=$input.obiclean.fasta, name=$input.names)" | tee lastlog.txt
				if grep -q 'ERROR' lastlog.txt; then
		 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
				else
				touch ${USER_HOME}/.var_babitas/Trimming_finished.txt
				fasta_trim_size=$(grep -c "^>" $input.obiclean.redundant.fasta)
				echo ""
				echo "##########################"
				echo "DONE"
				echo "############################"
				echo "Filtering with OBITools, finished"
				echo "##############################"
				echo "output = $input.obiclean.redundant.fasta, contains $fasta_trim_size sequences"
				echo "################################"
				echo "You may close this window now!"
				fi

			fi
			fi
			fi
		fi


		
	fi


	#if input=fastq
	if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then

		if [ -e ${USER_HOME}/.var_babitas/o_maxambig.txt ]; then
		o_maxambig=$(cat ${USER_HOME}/.var_babitas/o_maxambig.txt)
		echo "# Max N's = $o_maxambig; filtering"
		echo "fastq to fasta and filtering maxambig=$o_maxambig"
	
		mothur "#fastq.info(fastq=$input.fastq)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
	 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
			else
			echo ""
			fi

		mothur "#trim.seqs(fasta=$input.fasta, qfile=$input.qual, maxambig=$o_maxambig)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
	 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
			else
			echo ""
			fi

		mv $input.trim.fasta $input.fasta

		else
		echo "# fastq to fasta"
		mothur "#fastq.info(fastq=$input.fastq)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
	 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
			else
			echo ""
			fi
		fi


	echo "# Making unique sequences"
	mothur "#unique.seqs(fasta=$input.fasta)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
	 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
			else
			echo ""
			fi

	echo ""
	echo "# Filtering with OBITools"
	echo ""
	
		if [ -e ${USER_HOME}/.var_babitas/clust.txt ] && [ -e ${USER_HOME}/.var_babitas/head.txt ]; then
		echo "obiclean -d $dist -r $ratio -C -H $input.unique.fasta > $input.obiclean.fasta"
		obiclean -d $dist -r $ratio -C -H $input.unique.fasta > $input.obiclean.temp
			if [ "$?" = "0" ]; then
 			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt
			exit 1
			fi

		obiannotate -k none $input.obiclean.temp > $input.obiclean.fasta
			if [ "$?" = "0" ]; then
			rm $input.obiclean.temp
 			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt
			exit 1
			fi

		mothur "#deunique.seqs(fasta=$input.obiclean.fasta, name=$input.names)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
	 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
			else
			touch ${USER_HOME}/.var_babitas/Trimming_finished.txt
			fasta_trim_size=$(grep -c "^>" $input.obiclean.redundant.fasta)
			echo ""
			echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Filtering with OBITools, finished"
			echo "##############################"
			echo "output = $input.obiclean.redundant.fasta, contains $fasta_trim_size sequences"
			echo "################################"
			echo "You may close this window now!"
			fi
		
		else if [ -e ${USER_HOME}/.var_babitas/head.txt ]; then
		echo "obiclean -d $dist -r $ratio -H $input.unique.fasta > $input.obiclean.fasta"
		obiclean -d $dist -r $ratio -H $input.unique.fasta > $input.obiclean.temp
			if [ "$?" = "0" ]; then
 			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt
			exit 1
			fi

		obiannotate -k none $input.obiclean.temp > $input.obiclean.fasta
			if [ "$?" = "0" ]; then
			rm $input.obiclean.temp
 			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt
			exit 1
			fi

		mothur "#deunique.seqs(fasta=$input.obiclean.fasta, name=$input.names)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
	 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
			else
			touch ${USER_HOME}/.var_babitas/Trimming_finished.txt
			fasta_trim_size=$(grep -c "^>" $input.obiclean.redundant.fasta)
			echo ""
			echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Filtering with OBITools, finished"
			echo "##############################"
			echo "output = $input.obiclean.redundant.fasta, contains $fasta_trim_size sequences"
			echo "################################"
			echo "You may close this window now!"
			fi

		else if [ -e ${USER_HOME}/.var_babitas/clust.txt ]; then
		echo "obiclean -d $dist -r $ratio -C $input.unique.fasta > $input.obiclean.fasta"
		obiclean -d $dist -r $ratio -C $input.unique.fasta > $input.obiclean.temp
			if [ "$?" = "0" ]; then
 			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt
			exit 1
			fi

		obiannotate -k none $input.obiclean.temp > $input.obiclean.fasta
			if [ "$?" = "0" ]; then
			rm $input.obiclean.temp
 			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt
			exit 1
			fi

		mothur "#deunique.seqs(fasta=$input.obiclean.fasta, name=$input.names)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
	 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
			else
			touch ${USER_HOME}/.var_babitas/Trimming_finished.txt
			fasta_trim_size=$(grep -c "^>" $input.obiclean.redundant.fasta)
			echo ""
			echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Filtering with OBITools, finished"
			echo "##############################"
			echo "output = $input.obiclean.redundant.fasta, contains $fasta_trim_size sequences"
			echo "################################"
			echo "You may close this window now!"
			fi


		else 
		echo "obiclean -d $dist -r $ratio $input.unique.fasta > $input.obiclean.fasta"
		obiclean -d $dist -r $ratio $input.unique.fasta > $input.obiclean.temp
			if [ "$?" = "0" ]; then
 			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt
			exit 1
			fi

		obiannotate -k none $input.obiclean.temp > $input.obiclean.fasta
			if [ "$?" = "0" ]; then
			rm $input.obiclean.temp
 			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Trimming_error.txt
			exit 1
			fi

		mothur "#deunique.seqs(fasta=$input.obiclean.fasta, name=$input.names)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
	 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
			else
			touch ${USER_HOME}/.var_babitas/Trimming_finished.txt
			fasta_trim_size=$(grep -c "^>" $input.obiclean.redundant.fasta)
			echo ""
			echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Filtering with OBITools, finished"
			echo "##############################"
			echo "output = $input.obiclean.redundant.fasta, contains $fasta_trim_size sequences"
			echo "################################"
			echo "You may close this window now!"
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



