#!/bin/bash

echo "### DEMULTILPEXING ###"
echo ""
echo "When using the incorporated tools, please cite as follows:"
echo ""
echo "mothur (v1.36.1) - Schloss, P.D., et al., 2009. Introducing mothur: Open-Source, Platform-Independent, Community-Supported Software for Describing and Comparing Microbial Communities. Applied and Environmental Microbiology 75, 7537-7541."
echo "Distributed under the GNU General Public License version 2 by the Free Software Foundation"
echo "www.mothur.org"
echo ""
echo "OBITools (v1.2.9) - Boyer F., Mercier C., Bonin A., et al., 2016. OBITOOLS: a UNIX-inspired software package for DNA metabarcoding. Molecular Ecology Resources 16, 176-182."
echo "Distributed under the CeCILL free software licence version 2"
echo "metabarcoding.org//obitools/doc/index.html"
echo ""
echo "vsearch (v1.11.1) - github.com/torognes/vsearch"
echo "Copyright (C) 2014-2015, Torbjorn Rognes, Frederic Mahe and Tomas Flouri."
echo "Distributed under the GNU General Public License version 3 by the Free Software Foundation"
echo ""
echo "Fastx Toolkit (v0.0.14) - hannonlab.cshl.edu/fastx_toolkit"
echo "Distributed under the Affero GPL (AGPL) version 3 by the Free Software Foundation"
echo ""
echo "fqgrep (v0.4.4) - github.com/indraniel/fqgrep"
echo "Copyright (c) 2011-2016, Indraniel Das"
echo "________________________________________________"
echo ""


USER_HOME=$(eval echo ~${SUDO_USER})
####################################
#Set working directory
WorkingDirectory=$(awk 'BEGIN{FS=OFS="/"} NF{NF--};1' < ${USER_HOME}/.var_babitas/dem_input_location.txt)
		if [ "$?" = "0" ]; then
 		echo "Working directory = $WorkingDirectory"
		else
		touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt && echo "ERROR occured" && echo "Close this window" && exit 1
		fi


####################################
#Enter working directory

cd $WorkingDirectory
	if [ "$?" = "0" ]; then
	echo ""
	else
	touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt && echo "ERROR occured" && echo "Close this window" && exit 1
	fi


####################################
#Set INPUT variable
if [ -e ${USER_HOME}/.var_babitas/dem_input_location.txt ]; then
	dem_input=$(cat ${USER_HOME}/.var_babitas/dem_input_location.txt)
	format=$(cat ${USER_HOME}/.var_babitas/dem_input_location.txt | (awk 'BEGIN{FS=OFS="."} {print $NF}';))
	echo "Input="$dem_input

	#count fastq seqs
	if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
		fastq_size=$(echo $(cat $dem_input | wc -l) / 4 | bc)
		echo "   #Input fastq contains $fastq_size sequences"
	fi

	#count fasta seqs
	if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
		fasta_size=$(grep -c "^>" $dem_input)
		echo "   #Input fasta contains $fasta_size sequences"
	fi

else
	touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt
	echo "ERROR"
	echo "No input found" && exit 1
fi


#Set oligos variable
if [ -e ${USER_HOME}/.var_babitas/oligos_location.txt ]; then
	oligos=$(cat ${USER_HOME}/.var_babitas/oligos_location.txt)
	echo "oligos="$oligos
else
	touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt
	echo "ERROR"
	echo "No oligos file found" && exit 1
fi



#################################
### Renaming sequence headers ###
#################################
file=$(echo $dem_input | awk 'BEGIN{FS=OFS="."} NF{NF--};1') #remove input file extention
dem_input_name=$(echo $file | rev | awk 'BEGIN{FS=OFS="/"} {print $1}' | rev) #get on input file name wo path (and extention)
	
#Rename fastq
if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
	if [ -e "${USER_HOME}/.var_babitas/rename.txt" ]; then
		echo ""
		echo "# Renaming sequence headers ..."
		echo ""

		rename=$(cat ${USER_HOME}/.var_babitas/rename.txt)
		awk '{print (NR%4 == 1) ? "@'$rename'" ++i : $0}' < $dem_input > r_$dem_input_name.fastq
		echo "Renamed sequence headers to "$rename "..."
		echo ""
			
	else if [ -e "${USER_HOME}/.var_babitas/DoNotRename.txt" ]; then
		echo ""
		echo "# Sequence headers NOT RENAMED"
		echo ""
		cp $dem_input r_$dem_input_name.fastq

	else if [ -e "$dem_input" ]; then
		echo ""
		echo "# Renaming sequence headers ..."
		echo ""
		awk '{print (NR%4 == 1) ? "@Seq" ++i : $0}' < $dem_input > r_$dem_input_name.fastq
		echo "Renamed sequence headers to Seq1, Seq2, ..."
		echo ""
	fi
	fi
	fi  #renaming fastq

#Rename fasta
else if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
	if [ -e "${USER_HOME}/.var_babitas/rename.txt" ]; then
		echo ""
		echo "# Renaming sequence headers ..."
		echo ""

		rename=$(cat ${USER_HOME}/.var_babitas/rename.txt)
		awk '{print (NR%2 == 1) ? ">'$rename'" ++i : $0}' < $dem_input > r_$dem_input_name.fasta
		echo "Renamed sequence headers to "$rename "..."
		echo ""
			
	else if [ -e "${USER_HOME}/.var_babitas/DoNotRename.txt" ]; then
		echo "# Sequence headers NOT RENAMED"
		echo ""
		cp $dem_input r_$dem_input_name.fasta

	else if [ -e "$dem_input" ]; then
		echo ""
		echo "# Renaming sequence headers ..."
		echo ""
		awk '{print (NR%2 == 1) ? ">Seq" ++i : $0}' < $dem_input > r_$dem_input_name.fasta
		echo "Renamed sequence headers to Seq1, Seq2, ..."
		echo ""
	fi
	fi
	fi  #renaming fasta

else #ERROR
	#input fastq not extended as fastq or fq / input fasta not extended as fasta or fa or txt
	touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt
	echo "ERROR"
	echo "input fastq not extended as fastq or fq / input fasta not extended as fasta or fa or txt" && exit 1

fi #fastq or fasta (else if)
fi #fastq or fasta




##########################################################
##########################################################
### Reorient reads to 5'-3'  and  set primer variables ###
##########################################################
##########################################################
if [ -e "${USER_HOME}/.var_babitas/pdiffs.txt" ]; then
pdiffs=$(cat ${USER_HOME}/.var_babitas/pdiffs.txt)
echo ""

	else if [ -e "${USER_HOME}/.var_babitas/errors.txt" ]; then
	pdiffs=$(cat ${USER_HOME}/.var_babitas/errors.txt)
	echo ""

	else
	pdiffs=$"0"
fi
fi


if grep -q 'Mixed' ${USER_HOME}/.var_babitas/Seq_orientation.txt; then

	
	tr "\r" " " < ${USER_HOME}/.var_babitas/primers.prim | tr "\n" " " | sed -e 's/^ //g' | sed -e 's/ /\n/g' | awk '/F:_/ { print $0 }' | sed -e 's/F:_//g' | awk '{filename = sprintf("F_primer%d.txt", NR); print > filename; close(filename)}'

	tr "\r" " " < ${USER_HOME}/.var_babitas/primers.prim | tr "\n" " " | sed -e 's/^ //g' | sed -e 's/ /\n/g' | awk '/R:_/ { print $0 }' | sed -e 's/R:_//g' | awk '{filename = sprintf("R_primer%d.txt", NR); print > filename; close(filename)}'


	### MIXED orientation, single forward
	if grep -q 'single_forward' ${USER_HOME}/.var_babitas/oligos_format.txt || grep -q 'paired' ${USER_HOME}/.var_babitas/oligos_format.txt; then

	echo ""
	echo "### Reorienting all reads to 5'-3' based on primers ..."
	echo "Primer differences = $pdiffs - allowing $pdiffs mismatches to primer sequences"


		if [ -e "F_primer1.txt" ]; then
		tr --delete '\r' < F_primer1.txt | tr --delete '\n' > F_prim1.txt && rm F_primer1.txt
		F_prim1=$(cat F_prim1.txt)
			if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
			fqgrep -m $pdiffs -p $F_prim1 -e r_$dem_input_name.fastq > r_Reoriented_5-3.fastq
				if [ "$?" = "0" ]; then
	 			echo ""
				else
				touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt
				exit 1
				fi
			fi
			if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
			fqgrep -m $pdiffs -p $F_prim1 -e -f r_$dem_input_name.fasta > r_Reoriented_5-3.fasta
				if [ "$?" = "0" ]; then
	 			echo ""
				else
				touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt
				exit 1
				fi
			fi
		fi

		if [ -e "F_primer2.txt" ]; then
		tr --delete '\r' < F_primer2.txt | tr --delete '\n' > F_prim2.txt && rm F_primer2.txt
		F_prim2=$(cat F_prim2.txt)
			if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
			fqgrep -m $pdiffs -p $F_prim2 -e r_$dem_input_name.fastq >> r_Reoriented_5-3.fastq
			fi
			if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
			fqgrep -m $pdiffs -p $F_prim2 -e -f r_$dem_input_name.fasta >> r_Reoriented_5-3.fasta
			fi
		fi

		if [ -e "F_primer3.txt" ]; then
		tr --delete '\r' < F_primer3.txt | tr --delete '\n' > F_prim3.txt && rm F_primer3.txt
		F_prim3=$(cat F_prim3.txt)
			if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
			fqgrep -m $pdiffs -p $F_prim3 -e r_$dem_input_name.fastq >> r_Reoriented_5-3.fastq
			fi
			if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
			fqgrep -m $pdiffs -p $F_prim3 -e -f r_$dem_input_name.fasta >> r_Reoriented_5-3.fasta
			fi
		fi

		if [ -e "F_primer4.txt" ]; then
		tr --delete '\r' < F_primer4.txt | tr --delete '\n' > F_prim4.txt && rm F_primer4.txt
		F_prim4=$(cat F_prim4.txt)
			if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
			fqgrep -m $pdiffs -p $F_prim4 -e r_$dem_input_name.fastq >> r_Reoriented_5-3.fastq
			fi
			if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
			fqgrep -m $pdiffs -p $F_prim4 -e -f r_$dem_input_name.fasta >> r_Reoriented_5-3.fasta
			fi
		fi

		if [ -e "F_primer5.txt" ]; then
		tr --delete '\r' < F_primer5.txt | tr --delete '\n' > F_prim5.txt && rm F_primer5.txt
		F_prim5=$(cat F_prim5.txt)
			if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
			fqgrep -m $pdiffs -p $F_prim5 -e r_$dem_input_name.fastq >> r_Reoriented_5-3.fastq
			fi
			if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
			fqgrep -m $pdiffs -p $F_prim5 -e -f r_$dem_input_name.fasta >> r_Reoriented_5-3.fasta
			fi
		fi

		if [ -e "F_primer6.txt" ]; then
		tr --delete '\r' < F_primer6.txt | tr --delete '\n' > F_prim6.txt && rm F_primer6.txt
		F_prim6=$(cat F_prim6.txt)
			if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
			fqgrep -m $pdiffs -p $F_prim6 -e r_$dem_input_name.fastq >> r_Reoriented_5-3.fastq
			fi
			if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
			fqgrep -m $pdiffs -p $F_prim6 -e -f r_$dem_input_name.fasta >> r_Reoriented_5-3.fasta
			fi
		fi

		if [ -e "F_primer7.txt" ]; then
		tr --delete '\r' < F_primer7.txt | tr --delete '\n' > F_prim7.txt && rm F_primer7.txt
		F_prim7=$(cat F_prim7.txt)
			if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
			fqgrep -m $pdiffs -p $F_prim7 -e r_$dem_input_name.fastq >> r_Reoriented_5-3.fastq
			fi
			if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
			fqgrep -m $pdiffs -p $F_prim7 -e -f r_$dem_input_name.fasta >> r_Reoriented_5-3.fasta
			fi
		fi

		if [ -e "F_primer8.txt" ]; then
		tr --delete '\r' < F_primer8.txt | tr --delete '\n' > F_prim8.txt && rm F_primer8.txt
		F_prim8=$(cat F_prim8.txt)
			if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
			fqgrep -m $pdiffs -p $F_prim8 -e r_$dem_input_name.fastq >> r_Reoriented_5-3.fastq
			fi
			if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
			fqgrep -m $pdiffs -p $F_prim8 -e -f r_$dem_input_name.fasta >> r_Reoriented_5-3.fasta
			fi
		fi

		if [ -e "F_primer9.txt" ]; then
		tr --delete '\r' < F_primer9.txt | tr --delete '\n' > F_prim9.txt && rm F_primer9.txt
		F_prim9=$(cat F_prim9.txt)
			if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
			fqgrep -m $pdiffs -p $F_prim9 -e r_$dem_input_name.fastq >> r_Reoriented_5-3.fastq
			fi
			if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
			fqgrep -m $pdiffs -p $F_prim9 -e -f r_$dem_input_name.fasta >> r_Reoriented_5-3.fasta
			fi
		fi

		if [ -e "F_primer10.txt" ]; then
		tr --delete '\r' < F_primer10.txt | tr --delete '\n' > F_prim10.txt && rm F_primer10.txt
		F_prim10=$(cat F_prim10.txt)
			if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
			fqgrep -m $pdiffs -p $F_prim10 -e r_$dem_input_name.fastq >> r_Reoriented_5-3.fastq
			fi
			if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
			fqgrep -m $pdiffs -p $F_prim10 -e -f r_$dem_input_name.fasta >> r_Reoriented_5-3.fasta
			fi
		fi

		#reverse primers
		if [ -e "R_primer1.txt" ]; then
		tr --delete '\r' < R_primer1.txt | tr --delete '\n' > R_prim1.txt && rm R_primer1.txt
		R_prim1=$(cat R_prim1.txt)
			if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
			fqgrep -m $pdiffs -p $R_prim1 -e r_$dem_input_name.fastq > 3-5.fastq
			fastx_reverse_complement -Q33 -i 3-5.fastq >> r_Reoriented_5-3.fastq
			fi
			if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
			fqgrep -m $pdiffs -p $R_prim1 -e -f r_$dem_input_name.fasta > 3-5.fasta
			fastx_reverse_complement -Q33 -i 3-5.fasta >> r_Reoriented_5-3.fasta
			fi
		fi

		if [ -e "R_primer2.txt" ]; then
		tr --delete '\r' < R_primer2.txt | tr --delete '\n' > R_prim2.txt && rm R_primer2.txt
		R_prim2=$(cat R_prim2.txt)
			if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
			fqgrep -m $pdiffs -p $R_prim2 -e r_$dem_input_name.fastq > 3-5.fastq
			fastx_reverse_complement -Q33 -i 3-5.fastq >> r_Reoriented_5-3.fastq
			fi
			if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
			fqgrep -m $pdiffs -p $R_prim2 -e -f r_$dem_input_name.fasta > 3-5.fasta
			fastx_reverse_complement -Q33 -i 3-5.fasta >> r_Reoriented_5-3.fasta
			fi
		fi

		if [ -e "R_primer3.txt" ]; then
		tr --delete '\r' < R_primer3.txt | tr --delete '\n' > R_prim3.txt && rm R_primer3.txt
		R_prim3=$(cat R_prim3.txt)
			if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
			fqgrep -m $pdiffs -p $R_prim3 -e r_$dem_input_name.fastq > 3-5.fastq
			fastx_reverse_complement -Q33 -i 3-5.fastq >> r_Reoriented_5-3.fastq
			fi
			if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
			fqgrep -m $pdiffs -p $R_prim3 -e -f r_$dem_input_name.fasta > 3-5.fasta
			fastx_reverse_complement -Q33 -i 3-5.fasta >> r_Reoriented_5-3.fasta
			fi
		fi

		if [ -e "R_primer4.txt" ]; then
		tr --delete '\r' < R_primer4.txt | tr --delete '\n' > R_prim4.txt && rm R_primer4.txt
		R_prim4=$(cat R_prim4.txt)
			if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
			fqgrep -m $pdiffs -p $R_prim4 -e r_$dem_input_name.fastq > 3-5.fastq
			fastx_reverse_complement -Q33 -i 3-5.fastq >> r_Reoriented_5-3.fastq
			fi
			if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
			fqgrep -m $pdiffs -p $R_prim4 -e -f r_$dem_input_name.fasta > 3-5.fasta
			fastx_reverse_complement -Q33 -i 3-5.fasta >> r_Reoriented_5-3.fasta
			fi
		fi

		if [ -e "R_primer5.txt" ]; then
		tr --delete '\r' < R_primer5.txt | tr --delete '\n' > R_prim5.txt && rm R_primer5.txt
		R_prim5=$(cat R_prim5.txt)
			if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
			fqgrep -m $pdiffs -p $R_prim5 -e r_$dem_input_name.fastq > 3-5.fastq
			fastx_reverse_complement -Q33 -i 3-5.fastq >> r_Reoriented_5-3.fastq
			fi
			if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
			fqgrep -m $pdiffs -p $R_prim5 -e -f r_$dem_input_name.fasta > 3-5.fasta
			fastx_reverse_complement -Q33 -i 3-5.fasta >> r_Reoriented_5-3.fasta
			fi
		fi

		if [ -e "R_primer6.txt" ]; then
		tr --delete '\r' < R_primer6.txt | tr --delete '\n' > R_prim6.txt && rm R_primer6.txt
		R_prim6=$(cat R_prim6.txt)
			if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
			fqgrep -m $pdiffs -p $R_prim6 -e r_$dem_input_name.fastq > 3-5.fastq
			fastx_reverse_complement -Q33 -i 3-5.fastq >> r_Reoriented_5-3.fastq
			fi
			if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
			fqgrep -m $pdiffs -p $R_prim6 -e -f r_$dem_input_name.fasta > 3-5.fasta
			fastx_reverse_complement -Q33 -i 3-5.fasta >> r_Reoriented_5-3.fasta
			fi
		fi

		if [ -e "R_primer7.txt" ]; then
		tr --delete '\r' < R_primer7.txt | tr --delete '\n' > R_prim7.txt && rm R_primer7.txt
		R_prim7=$(cat R_prim7.txt)
			if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
			fqgrep -m $pdiffs -p $R_prim7 -e r_$dem_input_name.fastq > 3-5.fastq
			fastx_reverse_complement -Q33 -i 3-5.fastq >> r_Reoriented_5-3.fastq
			fi
			if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
			fqgrep -m $pdiffs -p $R_prim7 -e -f r_$dem_input_name.fasta > 3-5.fasta
			fastx_reverse_complement -Q33 -i 3-5.fasta >> r_Reoriented_5-3.fasta
			fi
		fi

		if [ -e "R_primer8.txt" ]; then
		tr --delete '\r' < R_primer8.txt | tr --delete '\n' > R_prim8.txt && rm R_primer8.txt
		R_prim8=$(cat R_prim8.txt)
			if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
			fqgrep -m $pdiffs -p $R_prim8 -e r_$dem_input_name.fastq > 3-5.fastq
			fastx_reverse_complement -Q33 -i 3-5.fastq >> r_Reoriented_5-3.fastq
			fi
			if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
			fqgrep -m $pdiffs -p $R_prim8 -e -f r_$dem_input_name.fasta > 3-5.fasta
			fastx_reverse_complement -Q33 -i 3-5.fasta >> r_Reoriented_5-3.fasta
			fi
		fi

		if [ -e "R_primer9.txt" ]; then
		tr --delete '\r' < R_primer9.txt | tr --delete '\n' > R_prim9.txt && rm R_primer9.txt
		R_prim9=$(cat R_prim9.txt)
			if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
			fqgrep -m $pdiffs -p $R_prim9 -e r_$dem_input_name.fastq > 3-5.fastq
			fastx_reverse_complement -Q33 -i 3-5.fastq >> r_Reoriented_5-3.fastq
			fi
			if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
			fqgrep -m $pdiffs -p $R_prim9 -e -f r_$dem_input_name.fasta > 3-5.fasta
			fastx_reverse_complement -Q33 -i 3-5.fasta >> r_Reoriented_5-3.fasta
			fi
		fi

		if [ -e "R_primer10.txt" ]; then
		tr --delete '\r' < R_primer10.txt | tr --delete '\n' > R_prim10.txt && rm R_primer10.txt
		R_prim10=$(cat R_prim10.txt)
			if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
			fqgrep -m $pdiffs -p $R_prim10 -e r_$dem_input_name.fastq > 3-5.fastq
			fastx_reverse_complement -Q33 -i 3-5.fastq >> r_Reoriented_5-3.fastq
			fi
			if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
			fqgrep -m $pdiffs -p $R_prim10 -e -f r_$dem_input_name.fasta > 3-5.fasta
			fastx_reverse_complement -Q33 -i 3-5.fasta >> r_Reoriented_5-3.fasta
			fi
		fi

		
		
		if [ -e "r_Reoriented_5-3.fastq" ] || [ -e "r_Reoriented_5-3.fasta" ]; then
		dem_input_name=$"Reoriented_5-3"
		
		echo "..."
		echo "Reads reoriented to 5'-3' using fqgrep (github.com/indraniel/fqgrep) and Fastx Toolkit (hannonlab.cshl.edu/fastx_toolkit/)."
		echo ""	
			else
			echo "### ERROR ###"
		fi



		#### MIXED orientation, single REVERSE
		else if grep -q 'single_reverse' ${USER_HOME}/.var_babitas/oligos_format.txt; then 
	
		echo ""
		echo "### Tag attached to reverse primer"
		echo "### Reorienting all reads to 3'-5' (for demultiplexing) based on primers [reads will be reoriented back to 5'-3' after demultiplexing] ..."
		echo "pdiffs = $pdiffs - allowing $pdiffs mismatches to primer sequences"


			#reverse primers
			if [ -e "R_primer1.txt" ]; then
			tr --delete '\r' < R_primer1.txt | tr --delete '\n' > R_prim1.txt
			R_prim1=$(cat R_prim1.txt)
				if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
				fqgrep -m $pdiffs -p $R_prim1 -e r_$dem_input_name.fastq > r_3-5.fastq
				fi
				if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
				fqgrep -m $pdiffs -p $R_prim1 -e -f r_$dem_input_name.fasta > r_3-5.fasta
				fi
			fi

			if [ -e "R_primer2.txt" ]; then
			tr --delete '\r' < R_primer2.txt | tr --delete '\n' > R_prim2.txt && rm R_primer2.txt
			R_prim2=$(cat R_prim2.txt)
				if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
				fqgrep -m $pdiffs -p $R_prim2 -e r_$dem_input_name.fastq >> r_3-5.fastq
				fi
				if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
				fqgrep -m $pdiffs -p $R_prim2 -e -f r_$dem_input_name.fasta >> r_3-5.fasta
				fi
			fi

			if [ -e "R_primer3.txt" ]; then
			tr --delete '\r' < R_primer3.txt | tr --delete '\n' > R_prim3.txt && rm R_primer3.txt
			R_prim3=$(cat R_prim3.txt)
				if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
				fqgrep -m $pdiffs -p $R_prim3 -e r_$dem_input_name.fastq >> r_3-5.fastq
				fi
				if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
				fqgrep -m $pdiffs -p $R_prim3 -e -f r_$dem_input_name.fasta >> r_3-5.fasta
				fi
			fi

			if [ -e "R_primer4.txt" ]; then
			tr --delete '\r' < R_primer4.txt | tr --delete '\n' > R_prim4.txt && rm R_primer4.txt
			R_prim4=$(cat R_prim4.txt)
				if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
				fqgrep -m $pdiffs -p $R_prim4 -e r_$dem_input_name.fastq >> r_3-5.fastq
				fi
				if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
				fqgrep -m $pdiffs -p $R_prim4 -e -f r_$dem_input_name.fasta >> r_3-5.fasta
				fi
			fi

			if [ -e "R_primer5.txt" ]; then
			tr --delete '\r' < R_primer5.txt | tr --delete '\n' > R_prim5.txt && rm R_primer5.txt
			R_prim5=$(cat R_prim5.txt)
				if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
				fqgrep -m $pdiffs -p $R_prim5 -e r_$dem_input_name.fastq >> r_3-5.fastq
				fi
				if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
				fqgrep -m $pdiffs -p $R_prim5 -e -f r_$dem_input_name.fasta >> r_3-5.fasta
				fi
			fi

			if [ -e "R_primer6.txt" ]; then
			tr --delete '\r' < R_primer6.txt | tr --delete '\n' > R_prim6.txt && rm R_primer6.txt
			R_prim6=$(cat R_prim6.txt)
				if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
				fqgrep -m $pdiffs -p $R_prim6 -e r_$dem_input_name.fastq >> r_3-5.fastq
				fi
				if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
				fqgrep -m $pdiffs -p $R_prim6 -e -f r_$dem_input_name.fasta >> r_3-5.fasta
				fi
			fi

			if [ -e "R_primer7.txt" ]; then
			tr --delete '\r' < R_primer7.txt | tr --delete '\n' > R_prim7.txt && rm R_primer7.txt
			R_prim7=$(cat R_prim7.txt)
				if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
				fqgrep -m $pdiffs -p $R_prim7 -e r_$dem_input_name.fastq >> r_3-5.fastq
				fi
				if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
				fqgrep -m $pdiffs -p $R_prim7 -e -f r_$dem_input_name.fasta >> r_3-5.fasta
				fi
			fi

			if [ -e "R_primer8.txt" ]; then
			tr --delete '\r' < R_primer8.txt | tr --delete '\n' > R_prim8.txt && rm R_primer8.txt
			R_prim8=$(cat R_prim8.txt)
				if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
				fqgrep -m $pdiffs -p $R_prim8 -e r_$dem_input_name.fastq >> r_3-5.fastq
				fi
				if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
				fqgrep -m $pdiffs -p $R_prim8 -e -f r_$dem_input_name.fasta >> r_3-5.fasta
				fi
			fi

			if [ -e "R_primer9.txt" ]; then
			tr --delete '\r' < R_primer9.txt | tr --delete '\n' > R_prim9.txt && rm R_primer9.txt
			R_prim9=$(cat R_prim9.txt)
				if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
				fqgrep -m $pdiffs -p $R_prim9 -e r_$dem_input_name.fastq >> r_3-5.fastq
				fi
				if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
				fqgrep -m $pdiffs -p $R_prim9 -e -f r_$dem_input_name.fasta >> r_3-5.fasta
				fi
			fi

			if [ -e "R_primer10.txt" ]; then
			tr --delete '\r' < R_primer10.txt | tr --delete '\n' > R_prim10.txt && rm R_primer10.txt
			R_prim10=$(cat R_prim10.txt)
				if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
				fqgrep -m $pdiffs -p $R_prim10 -e r_$dem_input_name.fastq >> r_3-5.fastq
				fi
				if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
				fqgrep -m $pdiffs -p $R_prim10 -e -f r_$dem_input_name.fasta >> r_3-5.fasta
				fi
			fi
	
	
	
			#forward
			if [ -e "F_primer1.txt" ]; then
			tr --delete '\r' < F_primer1.txt | tr --delete '\n' > F_prim1.txt 
			F_prim1=$(cat F_prim1.txt)
				if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
				fqgrep -m $pdiffs -p $F_prim1 -e r_$dem_input_name.fastq > r_Reoriented_5-3.fastq
				fastx_reverse_complement -Q33 -i r_Reoriented_5-3.fastq >> r_3-5.fastq
				fi
				if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
				fqgrep -m $pdiffs -p $F_prim1 -e -f r_$dem_input_name.fasta > r_Reoriented_5-3.fasta
				fastx_reverse_complement -Q33 -i r_Reoriented_5-3.fasta >> r_3-5.fasta
				fi
			fi

			if [ -e "F_primer2.txt" ]; then
			tr --delete '\r' < F_primer2.txt | tr --delete '\n' > F_prim2.txt && rm F_primer2.txt
			F_prim2=$(cat F_prim2.txt)
				if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
				fqgrep -m $pdiffs -p $F_prim2 -e r_$dem_input_name.fastq > r_Reoriented_5-3.fastq
				fastx_reverse_complement -Q33 -i r_Reoriented_5-3.fastq >> r_3-5.fastq
				fi
				if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
				fqgrep -m $pdiffs -p $F_prim2 -e -f r_$dem_input_name.fasta > r_Reoriented_5-3.fasta
				fastx_reverse_complement -Q33 -i r_Reoriented_5-3.fasta >> r_3-5.fasta
				fi
			fi

			if [ -e "F_primer3.txt" ]; then
			tr --delete '\r' < F_primer3.txt | tr --delete '\n' > F_prim3.txt && rm F_primer3.txt
			F_prim3=$(cat F_prim3.txt)
				if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
				fqgrep -m $pdiffs -p $F_prim3 -e r_$dem_input_name.fastq > r_Reoriented_5-3.fastq
				fastx_reverse_complement -Q33 -i r_Reoriented_5-3.fastq >> r_3-5.fastq
				fi
				if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
				fqgrep -m $pdiffs -p $F_prim3 -e -f r_$dem_input_name.fasta > r_Reoriented_5-3.fasta
				fastx_reverse_complement -Q33 -i r_Reoriented_5-3.fasta >> r_3-5.fasta
				fi
			fi

			if [ -e "F_primer4.txt" ]; then
			tr --delete '\r' < F_primer4.txt | tr --delete '\n' > F_prim4.txt && rm F_primer4.txt
			F_prim4=$(cat F_prim4.txt)
				if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
				fqgrep -m $pdiffs -p $F_prim4 -e r_$dem_input_name.fastq > r_Reoriented_5-3.fastq
				fastx_reverse_complement -Q33 -i r_Reoriented_5-3.fastq >> r_3-5.fastq
				fi
				if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
				fqgrep -m $pdiffs -p $F_prim4 -e -f r_$dem_input_name.fasta > r_Reoriented_5-3.fasta
				fastx_reverse_complement -Q33 -i r_Reoriented_5-3.fasta >> r_3-5.fasta
				fi
			fi

			if [ -e "F_primer5.txt" ]; then
			tr --delete '\r' < F_primer5.txt | tr --delete '\n' > F_prim5.txt && rm F_primer5.txt
			F_prim5=$(cat F_prim5.txt)
				if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
				fqgrep -m $pdiffs -p $F_prim5 -e r_$dem_input_name.fastq > r_Reoriented_5-3.fastq
				fastx_reverse_complement -Q33 -i r_Reoriented_5-3.fastq >> r_3-5.fastq
				fi
				if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
				fqgrep -m $pdiffs -p $F_prim5 -e -f r_$dem_input_name.fasta > r_Reoriented_5-3.fasta
				fastx_reverse_complement -Q33 -i r_Reoriented_5-3.fasta >> r_3-5.fasta
				fi
			fi

			if [ -e "F_primer6.txt" ]; then
			tr --delete '\r' < F_primer6.txt | tr --delete '\n' > F_prim6.txt && rm F_primer6.txt
			F_prim6=$(cat F_prim6.txt)
				if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
				fqgrep -m $pdiffs -p $F_prim6 -e r_$dem_input_name.fastq > r_Reoriented_5-3.fastq
				fastx_reverse_complement -Q33 -i r_Reoriented_5-3.fastq >> r_3-5.fastq
				fi
				if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
				fqgrep -m $pdiffs -p $F_prim6 -e -f r_$dem_input_name.fasta > r_Reoriented_5-3.fasta
				fastx_reverse_complement -Q33 -i r_Reoriented_5-3.fasta >> r_3-5.fasta
				fi
			fi

			if [ -e "F_primer7.txt" ]; then
			tr --delete '\r' < F_primer7.txt | tr --delete '\n' > F_prim7.txt && rm F_primer7.txt
			F_prim7=$(cat F_prim7.txt)
				if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
				fqgrep -m $pdiffs -p $F_prim7 -e r_$dem_input_name.fastq > r_Reoriented_5-3.fastq
				fastx_reverse_complement -Q33 -i r_Reoriented_5-3.fastq >> r_3-5.fastq
				fi
				if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
				fqgrep -m $pdiffs -p $F_prim7 -e -f r_$dem_input_name.fasta > r_Reoriented_5-3.fasta
				fastx_reverse_complement -Q33 -i r_Reoriented_5-3.fasta >> r_3-5.fasta
				fi
			fi

			if [ -e "F_primer8.txt" ]; then
			tr --delete '\r' < F_primer8.txt | tr --delete '\n' > F_prim8.txt && rm F_primer8.txt
			F_prim8=$(cat F_prim8.txt)
				if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
				fqgrep -m $pdiffs -p $F_prim8 -e r_$dem_input_name.fastq > r_Reoriented_5-3.fastq
				fastx_reverse_complement -Q33 -i r_Reoriented_5-3.fastq >> r_3-5.fastq
				fi
				if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
				fqgrep -m $pdiffs -p $F_prim8 -e -f r_$dem_input_name.fasta > r_Reoriented_5-3.fasta
				fastx_reverse_complement -Q33 -i r_Reoriented_5-3.fasta >> r_3-5.fasta
				fi
			fi

			if [ -e "F_primer9.txt" ]; then
			tr --delete '\r' < F_primer9.txt | tr --delete '\n' > F_prim9.txt && rm F_primer9.txt
			F_prim9=$(cat F_prim9.txt)
				if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
				fqgrep -m $pdiffs -p $F_prim9 -e r_$dem_input_name.fastq > r_Reoriented_5-3.fastq
				fastx_reverse_complement -Q33 -i r_Reoriented_5-3.fastq >> r_3-5.fastq
				fi
				if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
				fqgrep -m $pdiffs -p $F_prim9 -e -f r_$dem_input_name.fasta > r_Reoriented_5-3.fasta
				fastx_reverse_complement -Q33 -i r_Reoriented_5-3.fasta >> r_3-5.fasta
				fi
			fi

			if [ -e "F_primer10.txt" ]; then
			tr --delete '\r' < F_primer10.txt | tr --delete '\n' > F_prim10.txt && rm F_primer10.txt
			F_prim10=$(cat F_prim10.txt)
				if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
				fqgrep -m $pdiffs -p $F_prim10 -e r_$dem_input_name.fastq > r_Reoriented_5-3.fastq
				fastx_reverse_complement -Q33 -i r_Reoriented_5-3.fastq >> r_3-5.fastq
				fi
				if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
				fqgrep -m $pdiffs -p $F_prim10 -e -f r_$dem_input_name.fasta > r_Reoriented_5-3.fasta
				fastx_reverse_complement -Q33 -i r_Reoriented_5-3.fasta >> r_3-5.fasta
				fi
			fi

			
			if [ -e "r_3-5.fastq" ] || [ -e "r_3-5.fasta" ]; then
			dem_input_name=$"3-5"
		
			echo "..."
			echo "### Reads reoriented to 3'-5' using fqgrep (github.com/indraniel/fqgrep) and Fastx Toolkit (hannonlab.cshl.edu/fastx_toolkit/)."
			echo ""
				else 
				echo "### ERROR ###"
			fi

		


		fi
	fi

######################################
### 5'-3' orientation, single forward#
######################################
else if grep -q '5_3' ${USER_HOME}/.var_babitas/Seq_orientation.txt; then
	
	#if paired barcodes or tag attached to forward primer
	if grep -q 'single_forward' ${USER_HOME}/.var_babitas/oligos_format.txt || grep -q 'paired' ${USER_HOME}/.var_babitas/oligos_format.txt; then
	
		#IF FASTQ
		if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
			echo "# Fastq to fasta"
			echo "vsearch --fastq_filter r_$dem_input_name.fastq --fasta_width 0 --fastaout r_$dem_input_name.fasta"
			
			vsearch --fastq_filter r_$dem_input_name.fastq --fasta_width 0 --fastaout r_$dem_input_name.fasta --fastq_qmax 99
			echo ""
		fi

	
		#IF FASTA
		if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
			echo ""
			#proceeding with r_$dem_input_name.fasta
		fi



	#### 5'-3' orientation, single REVERSE
	else if grep -q 'single_reverse' ${USER_HOME}/.var_babitas/oligos_format.txt; then

	echo "# Tag attached to reverse primer, making reverse complementary of 5'-3' oriented reads"

		#if FASTQ
		if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
		echo "vsearch --fastx_revcomp r_$dem_input_name.fastq --fasta_width 0 --fastaout r_3-5.fasta"
	
		vsearch --fastx_revcomp r_$dem_input_name.fastq --fasta_width 0 --fastaout r_3-5.fasta
				if [ "$?" = "0" ]; then
	 			echo ""
				else
				touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt
				echo "An unexpected error has occurred!"
				echo "Close this window"
				exit 1
				fi
		fi
		
		#if FASTA
		if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
		echo "vsearch --fastx_revcomp r_$dem_input_name.fasta --fasta_width 0 --fastaout r_3-5.fasta"
	
		vsearch --fastx_revcomp r_$dem_input_name.fasta --fasta_width 0 --fastaout r_3-5.fasta
				if [ "$?" = "0" ]; then
	 			echo ""
				else
				touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt
				echo "An unexpected error has occurred!"
				echo "Close this window"
				exit 1
				fi
		fi
		
		dem_input_name=$"3-5"

	fi
	fi
fi
fi



##########################################
### Removing both duplicate occurences ###
##########################################
#if seq is found 2 times in a oriented file, then it's an artefact. 

#Needed only when reads have been reoiented
if grep -q 'Mixed' ${USER_HOME}/.var_babitas/Seq_orientation.txt; then
	#if FASTQ
	if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
		echo "# Searching for duplicate sequences. If exist, then removing (duplicates may occur if forward or reverse primer exist on both sequence ends)"
		echo "   # converting fastq to fasta" 
		echo "vsearch --fastq_filter r_$dem_input_name.fastq --fasta_width 0 --fastaout r_$dem_input_name.fasta"
		
		vsearch --fastq_filter r_$dem_input_name.fastq --fasta_width 0 --fastaout r_$dem_input_name.fasta --fastq_qmax 99
			if [ "$?" = "0" ]; then
			echo ""
			else
			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt && exit 1
			fi


		#remove redundant tabs and spaces from seq headers
		echo "   # searching for duplicate sequences"
		sed -e 's/\t//g;s/ //g' < r_$dem_input_name.fasta > r_$dem_input_name.fasta.temp
		rm r_$dem_input_name.fasta

		awk 'NR%2{printf "%s\t",$0;next;}1' r_$dem_input_name.fasta.temp | sort > sort.temp
		awk 'n=x[$1]{print n"\n"$0;} {x[$1]=$0;}' sort.temp > duplicates.temp
		comm -23 sort.temp duplicates.temp | sed -e 's/\t/\n/g' > r_$dem_input_name.fasta
			if [ "$?" = "0" ]; then
			dupl=$(wc -l duplicates.temp | awk '{print $1}')
			echo "   - found $dupl duplicate sequences and removed $dupl sequences"
			echo ""
			else
			echo "Removing duplicates ERROR"
			touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt
			exit 1
			fi

		rm r_$dem_input_name.fasta.temp
		rm sort.temp
		rm duplicates.temp

	fi


	#if FASTA
	if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then

		echo "# Searching for duplicate sequences. If exist, then removing (duplicates may occur if forward or reverse primer exist on both sequence ends)"

		#Input fasta file seq string to one line, and remove redundant tabs and spaces
		gawk '/^>/ {printf("\n%s\n",$0);next; } { printf("%s",$0);}  END {printf("\n");}' < r_$dem_input_name.fasta | sed '/^\n*$/d' | sed -e 's/\t//g;s/ //g' > r_$dem_input_name.fasta.temp

		rm r_$dem_input_name.fasta

		#Searching for duplicate sequences
		awk 'NR%2{printf "%s\t",$0;next;}1' r_$dem_input_name.fasta.temp | sort > sort.temp
		awk 'n=x[$1]{print n"\n"$0;} {x[$1]=$0;}' sort.temp > duplicates.temp
		comm -23 sort.temp duplicates.temp | sed -e 's/\t/\n/g' > r_$dem_input_name.fasta
			if [ "$?" = "0" ]; then
			dupl=$(wc -l duplicates.temp | awk '{print $1}')
			echo "   - found $dupl duplicate sequences and removed $dupl sequences"
			else
			echo "Removing duplicates ERROR"
			touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt
			exit 1
			fi

		rm r_$dem_input_name.fasta.temp
		rm sort.temp
		rm duplicates.temp
	fi
fi #remove duplicates








########################################################################################################
########################################################################################################
###START DEMULTIPLEXING######START DEMULTIPLEXING######START DEMULTIPLEXING######START DEMULTIPLEXING###
########################################################################################################
########################################################################################################


################
### OBITools ###
################
if grep -q 'OBITools' ${USER_HOME}/.var_babitas/demultiplex_program.txt; then
PATH=$PATH:/dependencies/OBITools-1.2.9/OBITools-1.2.9/export/bin && export PATH

	echo "### Demultiplexing options:"

	if [ -e "${USER_HOME}/.var_babitas/errors.txt" ]; then
		errors=$(cat ${USER_HOME}/.var_babitas/errors.txt)
		echo "primer mismatches="$errors
	fi
	if [ -e "${USER_HOME}/.var_babitas/minuniquesize.txt" ]; then
		minuniquesize=$(cat ${USER_HOME}/.var_babitas/minuniquesize.txt)
		echo "minuniquesize="$minuniquesize
	fi



	#Demultiplexing
	echo ""
	echo "### Demultiplexing with OBITools ###"
	echo ""

	echo "ngsfilter -e $errors --tag-list $oligos --uppercase --unidentified unidentified.fasta r_$dem_input_name.fasta > Demultiplexed.fasta"
	echo ""

	ngsfilter -e $errors --tag-list $oligos --uppercase --unidentified unidentified.fasta r_$dem_input_name.fasta > Demultiplexed.fasta.temp
				if [ "$?" = "0" ]; then
				echo ""
				else
				touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt
				exit 1
				fi

	#keep only sample tag in the header 
	obiannotate -k sample --uppercase Demultiplexed.fasta.temp > Demultiplexed.temp
				if [ "$?" = "0" ]; then
				echo ""
				rm Demultiplexed.fasta.temp
				else
				touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt
				exit 1
				fi


	#Clean fasta header, delete "sample=.*"
	sed -e 's/ sample=.*; //g' < Demultiplexed.temp > Demultiplexed.fasta
	 
	 
	#script to make groups file based on fastq file that contains sample information
	grep "sample=" Demultiplexed.temp | sed -e 's/>//g;s/sample=//g;s/ /\t/g;s/;\t//g'> Demultiplexed.groups
				if [ "$?" = "0" ]; then
				echo ""
				rm Demultiplexed.temp
				else
				touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt
				echo "An unexpected error has occurred!"
				echo "Close this window"
				exit 1
				fi


fi #OBITools first if



##############
### mothur ###
##############
if grep -q 'mothur' ${USER_HOME}/.var_babitas/demultiplex_program.txt; then
echo "### Demultiplexing with mothur ###"
echo ""

if [ -e "${USER_HOME}/.var_babitas/pdiffs.txt" ]; then
pdiffs=$(cat ${USER_HOME}/.var_babitas/pdiffs.txt)
echo "pdiffs="$pdiffs
fi
if [ -e "${USER_HOME}/.var_babitas/bdiffs.txt" ]; then
bdiffs=$(cat ${USER_HOME}/.var_babitas/bdiffs.txt)
echo "bdiffs="$bdiffs
fi
if [ -e "${USER_HOME}/.var_babitas/sdiffs.txt" ]; then
sdiffs=$(cat ${USER_HOME}/.var_babitas/sdiffs.txt)
echo "sdiffs="$sdiffs
fi
if [ -e "${USER_HOME}/.var_babitas/ldiffs.txt" ]; then
ldiffs=$(cat ${USER_HOME}/.var_babitas/ldiffs.txt)
echo "ldiffs="$ldiffs
fi
if [ -e "${USER_HOME}/.var_babitas/tdiffs.txt" ]; then
tdiffs=$(cat ${USER_HOME}/.var_babitas/tdiffs.txt)
echo "tdiffs="$tdiffs
fi
if [ -e "${USER_HOME}/.var_babitas/processors2.txt" ]; then
processors2=$(cat ${USER_HOME}/.var_babitas/processors2.txt)
fi
if [ -e "${USER_HOME}/.var_babitas/minuniquesize.txt" ]; then
minuniquesize=$(cat ${USER_HOME}/.var_babitas/minuniquesize.txt)
echo "minuniquesize="$minuniquesize
fi

echo ""



#bdiffs, pdiffs, sdiffs, ldiffs, tdiffs
if [ -e "${USER_HOME}/.var_babitas/dem_input_location.txt" ] && [ -e "${USER_HOME}/.var_babitas/pdiffs.txt" ] && [ -e "${USER_HOME}/.var_babitas/ldiffs.txt" ] && [ -e "${USER_HOME}/.var_babitas/sdiffs.txt" ] && [ -e "${USER_HOME}/.var_babitas/tdiffs.txt" ]; then


	#Demultiplexing
	
	mothur "#trim.seqs(fasta=r_$dem_input_name.fasta, oligos=$oligos, bdiffs=$bdiffs, pdiffs=$pdiffs, sdiffs=$sdiffs, ldiffs=$ldiffs, tdiffs=$tdiffs, processors=$processors2)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt && exit
		else
		echo ""
		fi


	sed 's/\t.*//' < r_$dem_input_name.trim.fasta > Demultiplexed.fasta
		mv r_$dem_input_name.groups Demultiplexed.groups



#bdiffs, pdiffs, sdiffs, ldiffs
else if [ -e "${USER_HOME}/.var_babitas/dem_input_location.txt" ] && [ -e "${USER_HOME}/.var_babitas/pdiffs.txt" ] && [ -e "${USER_HOME}/.var_babitas/ldiffs.txt" ] && [ -e "${USER_HOME}/.var_babitas/sdiffs.txt" ]; then


	#Demultiplexing
	
	mothur "#trim.seqs(fasta=r_$dem_input_name.fasta, oligos=$oligos, bdiffs=$bdiffs, pdiffs=$pdiffs, sdiffs=$sdiffs, ldiffs=$ldiffs, processors=$processors2)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt && exit
		else
		echo ""
		fi


	sed 's/\t.*//' < r_$dem_input_name.trim.fasta > Demultiplexed.fasta
		mv r_$dem_input_name.groups Demultiplexed.groups



#bdiffs, pdiffs, sdiffs, tdiffs
else if [ -e "${USER_HOME}/.var_babitas/dem_input_location.txt" ] && [ -e "${USER_HOME}/.var_babitas/pdiffs.txt" ] && [ -e "${USER_HOME}/.var_babitas/sdiffs.txt" ] && [ -e "${USER_HOME}/.var_babitas/tdiffs.txt" ]; then


	#Demultiplexing
	
	mothur "#trim.seqs(fasta=r_$dem_input_name.fasta, oligos=$oligos, bdiffs=$bdiffs, pdiffs=$pdiffs, sdiffs=$sdiffs, tdiffs=$tdiffs, processors=$processors2)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt && exit
		else
		echo ""
		fi


	sed 's/\t.*//' < r_$dem_input_name.trim.fasta > Demultiplexed.fasta
		mv r_$dem_input_name.groups Demultiplexed.groups



#bdiffs, pdiffs, ldiffs, tdiffs
else if [ -e "${USER_HOME}/.var_babitas/dem_input_location.txt" ] && [ -e "${USER_HOME}/.var_babitas/pdiffs.txt" ] && [ -e "${USER_HOME}/.var_babitas/ldiffs.txt" ] && [ -e "${USER_HOME}/.var_babitas/tdiffs.txt" ]; then


	#Demultiplexing
	
	mothur "#trim.seqs(fasta=r_$dem_input_name.fasta, oligos=$oligos, bdiffs=$bdiffs, pdiffs=$pdiffs, ldiffs=$ldiffs, tdiffs=$tdiffs, processors=$processors2)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt && exit
		else
		echo ""
		fi


	sed 's/\t.*//' < r_$dem_input_name.trim.fasta > Demultiplexed.fasta
		mv r_$dem_input_name.groups Demultiplexed.groups



#bdiffs, ldiffs, sdiffs, tdiffs
else if [ -e "${USER_HOME}/.var_babitas/dem_input_location.txt" ] && [ -e "${USER_HOME}/.var_babitas/ldiffs.txt" ] && [ -e "${USER_HOME}/.var_babitas/sdiffs.txt" ] && [ -e "${USER_HOME}/.var_babitas/tdiffs.txt" ]; then


	#Demultiplexing
	
	mothur "#trim.seqs(fasta=r_$dem_input_name.fasta, oligos=$oligos, bdiffs=$bdiffs, ldiffs=$ldiffs, sdiffs=$sdiffs, tdiffs=$tdiffs, processors=$processors2)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt && exit
		else
		echo ""
		fi


	sed 's/\t.*//' < r_$dem_input_name.trim.fasta > Demultiplexed.fasta
		mv r_$dem_input_name.groups Demultiplexed.groups



#bdiffs, pdiffs, sdiffs
else if [ -e "${USER_HOME}/.var_babitas/dem_input_location.txt" ] && [ -e "${USER_HOME}/.var_babitas/pdiffs.txt" ] && [ -e "${USER_HOME}/.var_babitas/sdiffs.txt" ]; then


	#Demultiplexing
	
	mothur "#trim.seqs(fasta=r_$dem_input_name.fasta, oligos=$oligos, bdiffs=$bdiffs, pdiffs=$pdiffs, sdiffs=$sdiffs, processors=$processors2)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt && exit
		else
		echo ""
		fi


	sed 's/\t.*//' < r_$dem_input_name.trim.fasta > Demultiplexed.fasta
		mv r_$dem_input_name.groups Demultiplexed.groups



#bdiffs, pdiffs, ldiffs
else if [ -e "${USER_HOME}/.var_babitas/dem_input_location.txt" ] && [ -e "${USER_HOME}/.var_babitas/pdiffs.txt" ] && [ -e "${USER_HOME}/.var_babitas/ldiffs.txt" ]; then


	#Demultiplexing
	
	mothur "#trim.seqs(fasta=r_$dem_input_name.fasta, oligos=$oligos, bdiffs=$bdiffs, pdiffs=$pdiffs, ldiffs=$ldiffs, processors=$processors2)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt && exit
		else
		echo ""
		fi


	sed 's/\t.*//' < r_$dem_input_name.trim.fasta > Demultiplexed.fasta
		mv r_$dem_input_name.groups Demultiplexed.groups



#bdiffs, pdiffs, tdiffs
else if [ -e "${USER_HOME}/.var_babitas/dem_input_location.txt" ] && [ -e "${USER_HOME}/.var_babitas/pdiffs.txt" ] && [ -e "${USER_HOME}/.var_babitas/tdiffs.txt" ]; then


	#Demultiplexing
	
	mothur "#trim.seqs(fasta=r_$dem_input_name.fasta, oligos=$oligos, bdiffs=$bdiffs, pdiffs=$pdiffs, tdiffs=$tdiffs, processors=$processors2)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt && exit
		else
		echo ""
		fi


	sed 's/\t.*//' < r_$dem_input_name.trim.fasta > Demultiplexed.fasta
		mv r_$dem_input_name.groups Demultiplexed.groups



#bdiffs, sdiffs, ldiffs
else if [ -e "${USER_HOME}/.var_babitas/dem_input_location.txt" ] && [ -e "${USER_HOME}/.var_babitas/ldiffs.txt" ] && [ -e "${USER_HOME}/.var_babitas/sdiffs.txt" ]; then


	#Demultiplexing
	
	mothur "#trim.seqs(fasta=r_$dem_input_name.fasta, oligos=$oligos, bdiffs=$bdiffs, ldiffs=$ldiffs, sdiffs=$sdiffs, processors=$processors2)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt && exit
		else
		echo ""
		fi


	sed 's/\t.*//' < r_$dem_input_name.trim.fasta > Demultiplexed.fasta
		mv r_$dem_input_name.groups Demultiplexed.groups



#bdiffs, sdiffs, tdiffs
else if [ -e "${USER_HOME}/.var_babitas/dem_input_location.txt" ] && [ -e "${USER_HOME}/.var_babitas/sdiffs.txt" ] && [ -e "${USER_HOME}/.var_babitas/tdiffs.txt" ]; then


	#Demultiplexing
	
	mothur "#trim.seqs(fasta=r_$dem_input_name.fasta, oligos=$oligos, bdiffs=$bdiffs, sdiffs=$sdiffs, tdiffs=$tdiffs, processors=$processors2)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt && exit
		else
		echo ""
		fi


	sed 's/\t.*//' < r_$dem_input_name.trim.fasta > Demultiplexed.fasta
		mv r_$dem_input_name.groups Demultiplexed.groups



#bdiffs, ldiffs, tdiffs
else if [ -e "${USER_HOME}/.var_babitas/dem_input_location.txt" ] && [ -e "${USER_HOME}/.var_babitas/ldiffs.txt" ] && [ -e "${USER_HOME}/.var_babitas/ldiffs.txt" ]; then


	#Demultiplexing
	
	mothur "#trim.seqs(fasta=r_$dem_input_name.fasta, oligos=$oligos, bdiffs=$bdiffs, ldiffs=$ldiffs, tdiffs=$tdiffs, processors=$processors2)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt && exit
		else
		echo ""
		fi


	sed 's/\t.*//' < r_$dem_input_name.trim.fasta > Demultiplexed.fasta
		mv r_$dem_input_name.groups Demultiplexed.groups



#bdiffs, pdiffs
else if [ -e "${USER_HOME}/.var_babitas/dem_input_location.txt" ] && [ -e "${USER_HOME}/.var_babitas/pdiffs.txt" ]; then


	#Demultiplexing
	
	mothur "#trim.seqs(fasta=r_$dem_input_name.fasta, oligos=$oligos, bdiffs=$bdiffs, pdiffs=$pdiffs, processors=$processors2)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt && exit
		else
		echo ""
		fi


	sed 's/\t.*//' < r_$dem_input_name.trim.fasta > Demultiplexed.fasta
		mv r_$dem_input_name.groups Demultiplexed.groups



#bdiffs, sdiffs
else if [ -e "${USER_HOME}/.var_babitas/dem_input_location.txt" ] && [ -e "${USER_HOME}/.var_babitas/sdiffs.txt" ]; then


	#Demultiplexing
	
	mothur "#trim.seqs(fasta=r_$dem_input_name.fasta, oligos=$oligos, bdiffs=$bdiffs, sdiffs=$sdiffs, processors=$processors2)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt && exit
		else
		echo ""
		fi


	sed 's/\t.*//' < r_$dem_input_name.trim.fasta > Demultiplexed.fasta
		mv r_$dem_input_name.groups Demultiplexed.groups



#bdiffs, ldiffs
else if [ -e "${USER_HOME}/.var_babitas/dem_input_location.txt" ] && [ -e "${USER_HOME}/.var_babitas/ldiffs.txt" ]; then


	#Demultiplexing
	
	mothur "#trim.seqs(fasta=r_$dem_input_name.fasta, oligos=$oligos, bdiffs=$bdiffs, ldiffs=$ldiffs, processors=$processors2)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt && exit
		else
		echo ""
		fi


	sed 's/\t.*//' < r_$dem_input_name.trim.fasta > Demultiplexed.fasta
		mv r_$dem_input_name.groups Demultiplexed.groups



#bdiffs, tdiffs
else if [ -e "${USER_HOME}/.var_babitas/dem_input_location.txt" ] && [ -e "${USER_HOME}/.var_babitas/tdiffs.txt" ]; then


	#Demultiplexing
	
	mothur "#trim.seqs(fasta=r_$dem_input_name.fasta, oligos=$oligos, bdiffs=$bdiffs, tdiffs=$tdiffs, processors=$processors2)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt && exit
		else
		echo ""
		fi


	sed 's/\t.*//' < r_$dem_input_name.trim.fasta > Demultiplexed.fasta
		mv r_$dem_input_name.groups Demultiplexed.groups



#bdiffs
else if [ -e "${USER_HOME}/.var_babitas/dem_input_location.txt" ] && [ -e "${USER_HOME}/.var_babitas/bdiffs.txt" ]; then


	#Demultiplexing
	
	mothur "#trim.seqs(fasta=r_$dem_input_name.fasta, oligos=$oligos, bdiffs=$bdiffs, processors=$processors2)" | tee lastlog.txt
		if grep -q 'ERROR' lastlog.txt; then
 		echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt && exit
		else
		echo ""
		fi


	sed 's/\t.*//' < r_$dem_input_name.trim.fasta > Demultiplexed.fasta
	mv r_$dem_input_name.groups Demultiplexed.groups




else 

echo "ERROR, no parametres specified" | tee ${USER_HOME}/.var_babitas/demultiplexing_error.txt

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


fi #mothur first if





#If minuniquesize.txt, then - discard unique sequences with an abundancevalue smaller than $minuniquesize
if [ -e ${USER_HOME}/.var_babitas/minuniquesize.txt ]; then
echo "### Discarding sequences with an abundance value smaller than" $minuniquesize

if [ -s Demultiplexed.fasta ]; then
echo "vsearch --derep_fulllength Demultiplexed.fasta --minuniquesize $minuniquesize --sizeout --output NotUniques.fasta --fasta_width 0"
vsearch --derep_fulllength Demultiplexed.fasta --minuniquesize $minuniquesize --sizeout --output NotUniques.fasta --fasta_width 0
			if [ "$?" = "0" ]; then
 			echo ""
			else
			touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt
			echo "An unexpected error has occurred!"
			echo "Close this window"
			exit 1
			fi

	if [ -s NotUniques.fasta ]; then
		echo "vsearch --search_exact Demultiplexed.fasta --db NotUniques.fasta --matched Demultiplexed_MinUniqueSize$minuniquesize.fasta --fasta_width 0 --xsize"
	vsearch --search_exact Demultiplexed.fasta --db NotUniques.fasta --matched Demultiplexed_MinUniqueSize$minuniquesize.fasta --fasta_width 0 --xsize
			if [ "$?" = "0" ]; then
 			echo ""
			else
			touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt
			echo "An unexpected error has occurred!"
			echo "Close this window"
			exit 1
			fi
	else 
		echo "### All sequences are less abundant that $minuniquesize"
		echo "Demultiplexed_MinUniqueSize$minuniquesize.fasta not generated"
		echo ""
		rm NotUniques.fasta
		fi

else
echo "ERROR"
echo "Demultiplexed fasta file is EMPTY, no seqs were assigned to samples"
touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt && exit 1

fi
fi







#If Demultiplex = 3'-5' then convert it to 5'-3'

if grep -q 'single_reverse' ${USER_HOME}/.var_babitas/oligos_format.txt && [ -e ${USER_HOME}/.var_babitas/minuniquesize.txt ] && [ -s Demultiplexed_MinUniqueSize$minuniquesize.fasta ]; then
	
	echo ""
	echo "### Reoriente reads to 5'-3' using vsearch (github.com/torognes/vsearch)"

	
		echo "mv Demultiplexed_MinUniqueSize$minuniquesize.fasta Demultiplexed_MinUniqueSizeX.fasta"
		echo "vsearch --fastx_revcomp Demultiplexed_MinUniqueSizeX.fasta --fasta_width 0 --fastaout Demultiplexed_MinUniqueSize$minuniquesize.fasta"
		echo ""

		mv Demultiplexed_MinUniqueSize$minuniquesize.fasta Demultiplexed_MinUniqueSizeX.fasta

		vsearch --fastx_revcomp Demultiplexed_MinUniqueSizeX.fasta --fasta_width 0 --fastaout Demultiplexed_MinUniqueSize$minuniquesize.fasta
				if [ "$?" = "0" ]; then
	 			echo ""
				rm Demultiplexed_MinUniqueSizeX.fasta
				else
				touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt
				echo "An unexpected error has occurred!"
				echo "Close this window"
				exit 1
				fi
	


	echo "mv Demultiplexed.fasta Demultiplexed.rc.fasta"
	echo "vsearch --fastx_revcomp Demultiplexed.rc.fasta --fasta_width 0 --fastaout Demultiplexed.fasta"
	mv Demultiplexed.fasta Demultiplexed.rc.fasta
	vsearch --fastx_revcomp Demultiplexed.rc.fasta --fasta_width 0 --fastaout Demultiplexed.fasta
			if [ "$?" = "0" ]; then
 			echo ""
			rm Demultiplexed.rc.fasta
			else
			touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt
			echo "An error has occurred!"
			echo "Empty output files? Check oligos file and primers"
			echo "Close this window"
			exit 1
			fi




		else if grep -q 'single_reverse' ${USER_HOME}/.var_babitas/oligos_format.txt && [ -s Demultiplexed.fasta ]; then
			
		echo ""
		echo "### Reoriente reads to 5'-3' using vsearch"
		echo "mv Demultiplexed.fasta Demultiplexed.rc.fasta"
		echo "vsearch --fastx_revcomp Demultiplexed.rc.fasta --fasta_width 0 --fastaout Demultiplexed.fasta"

		mv Demultiplexed.fasta Demultiplexed.rc.fasta
		vsearch --fastx_revcomp Demultiplexed.rc.fasta --fasta_width 0 --fastaout Demultiplexed.fasta
			if [ "$?" = "0" ]; then
 			echo ""
			rm Demultiplexed.rc.fasta
			else
			touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt
			echo "An error has occurred!"
			echo "Empty output files? Check oligos file and primers"
			echo "Close this window"
			exit 1
			fi
			
		

		fi
fi


if [ -s Demultiplexed.fasta ];then
	echo ""
	else
	echo "ERROR"
	echo "Demultiplexed fasta file is EMPTY, no seqs were assigned to samples"
	touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt && exit 1
fi



#Delete mothur_logfiles
if ls mothur.*.logfile 1> /dev/null 2>&1; then
	rm *.logfile
fi




############################################################
### DELETE parameter and some herein created .txt files ####
############################################################
if [ -e "lastlog.txt" ]; then
rm lastlog.txt
fi
if [ -e "F_prim1.txt" ]; then
rm F_prim*.txt
fi
if [ -e "R_prim1.txt" ]; then
rm R_prim*.txt
fi


#Delete scrap files
if [ -e "r_$dem_input_name.scrap.fasta" ]; then
	mv r_$dem_input_name.scrap.fasta unidentified.fasta
fi
if [ -e "r_Reoriented_5-3.trim.fasta" ]; then
	rm r_Reoriented_5-3.trim.fasta
fi
if [ -e "3-5.fastq" ]; then
	mv 3-5.fastq 3-5_oriented_seqs.fastq
fi
if [ -e "r_Reoriented_5-3.fasta" ]; then
	mv r_Reoriented_5-3.fasta r_Reoriented_5-3_input_for_demultiplexing.fasta
fi
if [ -e "r_$dem_input_name.trim.fasta" ]; then
	rm r_$dem_input_name.trim.fasta 
fi
if [ -e "r_$dem_input_name.fasta" ]; then
	mv r_$dem_input_name.fasta r_$dem_input_name.input_for_demultiplexing.fasta
fi
if [ -e "3-5.fasta" ]; then
	mv 3-5.fasta 3-5_oriented_seqs.fasta
fi





if [ -e "Demultiplexed_MinUniqueSize$minuniquesize.fasta" ]; then
	
	touch ${USER_HOME}/.var_babitas/demultiplex_finished.txt
	demultiplexed_size=$(grep -c "^>" Demultiplexed_MinUniqueSize$minuniquesize.fasta)
	if [ -e "${USER_HOME}/.var_babitas/DoNotRename.txt" ]; then
		if [ -e r_$dem_input_name.fasta ]; then
			rm r_$dem_input_name.fasta
		fi
		if [ -e r_$dem_input_name.fastq ]; then
			rm r_$dem_input_name.fastq
		fi
	fi
	
	echo "##########################"
	echo "DONE"
	echo "############################"
	echo "Demultiplexing finished"
	echo "##############################"
	echo "output fasta = Demultiplexed_MinUniqueSize$minuniquesize.fasta, contains $demultiplexed_size sequences"
	echo "output groups = Demultiplexed.groups"
	echo "unidentified = unidentified.fasta"
	echo "################################"
	echo "You may close this window now!"

	else if [ -e "Demultiplexed.fasta" ]; then
		
		touch ${USER_HOME}/.var_babitas/demultiplex_finished.txt
		demultiplexed_size=$(grep -c "^>" Demultiplexed.fasta)
		if [ -e "${USER_HOME}/.var_babitas/DoNotRename.txt" ]; then
			if [ -e r_$dem_input_name.fasta ]; then
				rm r_$dem_input_name.fasta
			fi
			if [ -e r_$dem_input_name.fastq ]; then
				rm r_$dem_input_name.fastq
			fi
		fi
		echo "##########################"
		echo "DONE"
		echo "############################"
		echo "Demultiplexing finished"
		echo "##############################"
		echo "output fasta = Demultiplexed.fasta, contains $demultiplexed_size sequences"
		echo "output groups = Demultiplexed.groups"
		echo "unidentified = unidentified.fasta"
		echo "################################"
		echo "You may close this window now!"
	fi
fi

