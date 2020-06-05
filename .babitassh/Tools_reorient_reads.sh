#!/bin/bash 



echo "### Reorienting reads to 5'-3' ###"
echo ""
echo "Fastx Toolkit - hannonlab.cshl.edu/fastx_toolkit"
echo "Distributed under the Affero GPL (AGPL) version 3 by the Free Software Foundation"
echo ""
echo "fqgrep - github.com/indraniel/fqgrep"
echo "Copyright (c) 2011-2016, Indraniel Das"
echo "________________________________________________"
echo ""

#Set working directory
USER_HOME=$(eval echo ~${SUDO_USER})


WorkingDirectory=$(awk 'BEGIN{FS=OFS="/"} NF{NF--};1' < ${USER_HOME}/.var_babitas/fastq5.txt)

fastq5=$(cat ${USER_HOME}/.var_babitas/fastq5.txt)
format=$(cat ${USER_HOME}/.var_babitas/fastq5.txt | (awk 'BEGIN{FS=OFS="."} {print $NF}';))

pdiffs=$(cat ${USER_HOME}/.var_babitas/mismatches.txt)


cd $WorkingDirectory
			if [ "$?" = "0" ]; then
 			echo ""
			else
			touch ${USER_HOME}/.var_babitas/tools_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi



tr "\r" " " < ${USER_HOME}/.var_babitas/primers.prim | tr "\n" " " | sed -e 's/^ //g' | sed -e 's/ /\n/g' | awk '/F:_/ { print $0 }' | sed -e 's/F:_//g' | awk '{filename = sprintf("F_primer%d.txt", NR); print > filename; close(filename)}'

	tr "\r" " " < ${USER_HOME}/.var_babitas/primers.prim | tr "\n" " " | sed -e 's/^ //g' | sed -e 's/ /\n/g' | awk '/R:_/ { print $0 }' | sed -e 's/R:_//g' | awk '{filename = sprintf("R_primer%d.txt", NR); print > filename; close(filename)}'



# Reorienting all reads to 5'-3' based on primers

echo ""
	echo "### Reorienting all reads to 5'-3' based on primers ..."
	echo "Primer differences = $pdiffs"


		if [ -e "F_primer1.txt" ]; then
		tr --delete '\r' < F_primer1.txt | tr --delete '\n' > F_prim1.txt && rm F_primer1.txt
		F_prim1=$(cat F_prim1.txt)
			if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
			fqgrep -m $pdiffs -p $F_prim1 -e $fastq5 > Reoriented_5-3.fastq
			fi
			if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
			fqgrep -m $pdiffs -p $F_prim1 -e -f $fastq5 > Reoriented_5-3.fasta
			fi
		fi

		if [ -e "F_primer2.txt" ]; then
		tr --delete '\r' < F_primer2.txt | tr --delete '\n' > F_prim2.txt && rm F_primer2.txt
		F_prim2=$(cat F_prim2.txt)
			if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
			fqgrep -m $pdiffs -p $F_prim2 -e $fastq5 >> Reoriented_5-3.fastq
			fi
			if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
			fqgrep -m $pdiffs -p $F_prim2 -e -f $fastq5 >> Reoriented_5-3.fasta
			fi
		fi

		if [ -e "F_primer3.txt" ]; then
		tr --delete '\r' < F_primer3.txt | tr --delete '\n' > F_prim3.txt && rm F_primer3.txt
		F_prim3=$(cat F_prim3.txt)
			if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
			fqgrep -m $pdiffs -p $F_prim3 -e $fastq5 >> Reoriented_5-3.fastq
			fi
			if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
			fqgrep -m $pdiffs -p $F_prim3 -e -f $fastq5 >> Reoriented_5-3.fasta
			fi
		fi

		if [ -e "F_primer4.txt" ]; then
		tr --delete '\r' < F_primer4.txt | tr --delete '\n' > F_prim4.txt && rm F_primer4.txt
		F_prim4=$(cat F_prim4.txt)
			if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
			fqgrep -m $pdiffs -p $F_prim4 -e $fastq5 >> Reoriented_5-3.fastq
			fi
			if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
			fqgrep -m $pdiffs -p $F_prim4 -e -f $fastq5 >> Reoriented_5-3.fasta
			fi
		fi

		if [ -e "F_primer5.txt" ]; then
		tr --delete '\r' < F_primer5.txt | tr --delete '\n' > F_prim5.txt && rm F_primer5.txt
		F_prim5=$(cat F_prim5.txt)
			if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
			fqgrep -m $pdiffs -p $F_prim5 -e $fastq5 >> Reoriented_5-3.fastq
			fi
			if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
			fqgrep -m $pdiffs -p $F_prim5 -e -f $fastq5 >> Reoriented_5-3.fasta
			fi
		fi

		if [ -e "F_primer6.txt" ]; then
		tr --delete '\r' < F_primer6.txt | tr --delete '\n' > F_prim6.txt && rm F_primer6.txt
		F_prim6=$(cat F_prim6.txt)
			if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
			fqgrep -m $pdiffs -p $F_prim6 -e $fastq5 >> Reoriented_5-3.fastq
			fi
			if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
			fqgrep -m $pdiffs -p $F_prim6 -e -f $fastq5 >> Reoriented_5-3.fasta
			fi
		fi

		if [ -e "F_primer7.txt" ]; then
		tr --delete '\r' < F_primer7.txt | tr --delete '\n' > F_prim7.txt && rm F_primer7.txt
		F_prim7=$(cat F_prim7.txt)
			if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
			fqgrep -m $pdiffs -p $F_prim7 -e $fastq5 >> Reoriented_5-3.fastq
			fi
			if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
			fqgrep -m $pdiffs -p $F_prim7 -e -f $fastq5 >> Reoriented_5-3.fasta
			fi
		fi

		if [ -e "F_primer8.txt" ]; then
		tr --delete '\r' < F_primer8.txt | tr --delete '\n' > F_prim8.txt && rm F_primer8.txt
		F_prim8=$(cat F_prim8.txt)
			if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
			fqgrep -m $pdiffs -p $F_prim8 -e $fastq5 >> Reoriented_5-3.fastq
			fi
			if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
			fqgrep -m $pdiffs -p $F_prim8 -e -f $fastq5 >> Reoriented_5-3.fasta
			fi
		fi

		if [ -e "F_primer9.txt" ]; then
		tr --delete '\r' < F_primer9.txt | tr --delete '\n' > F_prim9.txt && rm F_primer9.txt
		F_prim9=$(cat F_prim9.txt)
			if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
			fqgrep -m $pdiffs -p $F_prim9 -e $fastq5 >> Reoriented_5-3.fastq
			fi
			if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
			fqgrep -m $pdiffs -p $F_prim9 -e -f $fastq5 >> Reoriented_5-3.fasta
			fi
		fi

		if [ -e "F_primer10.txt" ]; then
		tr --delete '\r' < F_primer10.txt | tr --delete '\n' > F_prim10.txt && rm F_primer10.txt
		F_prim10=$(cat F_prim10.txt)
			if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
			fqgrep -m $pdiffs -p $F_prim10 -e $fastq5 >> Reoriented_5-3.fastq
			fi
			if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
			fqgrep -m $pdiffs -p $F_prim10 -e -f $fastq5 >> Reoriented_5-3.fasta
			fi
		fi

		#reverse primers
		if [ -e "R_primer1.txt" ]; then
		tr --delete '\r' < R_primer1.txt | tr --delete '\n' > R_prim1.txt && rm R_primer1.txt
		R_prim1=$(cat R_prim1.txt)
			if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
			fqgrep -m $pdiffs -p $R_prim1 -e $fastq5 > 3-5.fastq
			fastx_reverse_complement -Q33 -i 3-5.fastq >> Reoriented_5-3.fastq
			fi
			if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
			fqgrep -m $pdiffs -p $R_prim1 -e -f $fastq5 > 3-5.fasta
			fastx_reverse_complement -Q33 -i 3-5.fasta >> Reoriented_5-3.fasta
			fi
		fi

		if [ -e "R_primer2.txt" ]; then
		tr --delete '\r' < R_primer2.txt | tr --delete '\n' > R_prim2.txt && rm R_primer2.txt
		R_prim2=$(cat R_prim2.txt)
			if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
			fqgrep -m $pdiffs -p $R_prim2 -e $fastq5 > 3-5.fastq
			fastx_reverse_complement -Q33 -i 3-5.fastq >> Reoriented_5-3.fastq
			fi
			if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
			fqgrep -m $pdiffs -p $R_prim2 -e -f $fastq5 > 3-5.fasta
			fastx_reverse_complement -Q33 -i 3-5.fasta >> Reoriented_5-3.fasta
			fi
		fi

		if [ -e "R_primer3.txt" ]; then
		tr --delete '\r' < R_primer3.txt | tr --delete '\n' > R_prim3.txt && rm R_primer3.txt
		R_prim3=$(cat R_prim3.txt)
			if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
			fqgrep -m $pdiffs -p $R_prim3 -e $fastq5 > 3-5.fastq
			fastx_reverse_complement -Q33 -i 3-5.fastq >> Reoriented_5-3.fastq
			fi
			if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
			fqgrep -m $pdiffs -p $R_prim3 -e -f $fastq5 > 3-5.fasta
			fastx_reverse_complement -Q33 -i 3-5.fasta >> Reoriented_5-3.fasta
			fi
		fi

		if [ -e "R_primer4.txt" ]; then
		tr --delete '\r' < R_primer4.txt | tr --delete '\n' > R_prim4.txt && rm R_primer4.txt
		R_prim4=$(cat R_prim4.txt)
			if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
			fqgrep -m $pdiffs -p $R_prim4 -e $fastq5 > 3-5.fastq
			fastx_reverse_complement -Q33 -i 3-5.fastq >> Reoriented_5-3.fastq
			fi
			if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
			fqgrep -m $pdiffs -p $R_prim4 -e -f $fastq5 > 3-5.fasta
			fastx_reverse_complement -Q33 -i 3-5.fasta >> Reoriented_5-3.fasta
			fi
		fi

		if [ -e "R_primer5.txt" ]; then
		tr --delete '\r' < R_primer5.txt | tr --delete '\n' > R_prim5.txt && rm R_primer5.txt
		R_prim5=$(cat R_prim5.txt)
			if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
			fqgrep -m $pdiffs -p $R_prim5 -e $fastq5 > 3-5.fastq
			fastx_reverse_complement -Q33 -i 3-5.fastq >> Reoriented_5-3.fastq
			fi
			if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
			fqgrep -m $pdiffs -p $R_prim5 -e -f $fastq5 > 3-5.fasta
			fastx_reverse_complement -Q33 -i 3-5.fasta >> Reoriented_5-3.fasta
			fi
		fi

		if [ -e "R_primer6.txt" ]; then
		tr --delete '\r' < R_primer6.txt | tr --delete '\n' > R_prim6.txt && rm R_primer6.txt
		R_prim6=$(cat R_prim6.txt)
			if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
			fqgrep -m $pdiffs -p $R_prim6 -e $fastq5 > 3-5.fastq
			fastx_reverse_complement -Q33 -i 3-5.fastq >> Reoriented_5-3.fastq
			fi
			if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
			fqgrep -m $pdiffs -p $R_prim6 -e -f $fastq5 > 3-5.fasta
			fastx_reverse_complement -Q33 -i 3-5.fasta >> Reoriented_5-3.fasta
			fi
		fi

		if [ -e "R_primer7.txt" ]; then
		tr --delete '\r' < R_primer7.txt | tr --delete '\n' > R_prim7.txt && rm R_primer7.txt
		R_prim7=$(cat R_prim7.txt)
			if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
			fqgrep -m $pdiffs -p $R_prim7 -e $fastq5 > 3-5.fastq
			fastx_reverse_complement -Q33 -i 3-5.fastq >> Reoriented_5-3.fastq
			fi
			if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
			fqgrep -m $pdiffs -p $R_prim7 -e -f $fastq5 > 3-5.fasta
			fastx_reverse_complement -Q33 -i 3-5.fasta >> Reoriented_5-3.fasta
			fi
		fi

		if [ -e "R_primer8.txt" ]; then
		tr --delete '\r' < R_primer8.txt | tr --delete '\n' > R_prim8.txt && rm R_primer8.txt
		R_prim8=$(cat R_prim8.txt)
			if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
			fqgrep -m $pdiffs -p $R_prim8 -e $fastq5 > 3-5.fastq
			fastx_reverse_complement -Q33 -i 3-5.fastq >> Reoriented_5-3.fastq
			fi
			if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
			fqgrep -m $pdiffs -p $R_prim8 -e -f $fastq5 > 3-5.fasta
			fastx_reverse_complement -Q33 -i 3-5.fasta >> Reoriented_5-3.fasta
			fi
		fi

		if [ -e "R_primer9.txt" ]; then
		tr --delete '\r' < R_primer9.txt | tr --delete '\n' > R_prim9.txt && rm R_primer9.txt
		R_prim9=$(cat R_prim9.txt)
			if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
			fqgrep -m $pdiffs -p $R_prim9 -e $fastq5 > 3-5.fastq
			fastx_reverse_complement -Q33 -i 3-5.fastq >> Reoriented_5-3.fastq
			fi
			if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
			fqgrep -m $pdiffs -p $R_prim9 -e -f $fastq5 > 3-5.fasta
			fastx_reverse_complement -Q33 -i 3-5.fasta >> Reoriented_5-3.fasta
			fi
		fi

		if [ -e "R_primer10.txt" ]; then
		tr --delete '\r' < R_primer10.txt | tr --delete '\n' > R_prim10.txt && rm R_primer10.txt
		R_prim10=$(cat R_prim10.txt)
			if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
			fqgrep -m $pdiffs -p $R_prim10 -e $fastq5 > 3-5.fastq
			fastx_reverse_complement -Q33 -i 3-5.fastq >> Reoriented_5-3.fastq
			fi
			if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
			fqgrep -m $pdiffs -p $R_prim10 -e -f $fastq5 > 3-5.fasta
			fastx_reverse_complement -Q33 -i 3-5.fasta >> Reoriented_5-3.fasta
			fi
		fi


if [ -e "F_prim1.txt" ]; then
rm F_prim*.txt
fi
if [ -e "R_prim1.txt" ]; then
rm R_prim*.txt
fi

		
		if [[ $format == "fastq" ]] || [[ $format == "fq" ]]; then
		echo ""
		echo "#############################"
		echo "DONE"
		echo "#############################"
		echo "output = Reoriented_5-3.fastq"
		echo "3'-5' oriented reads = 3-5.fastq"
		echo "#############################"
		echo "You may close this window now!"
		touch ${USER_HOME}/.var_babitas/tools_finished.txt

		else if [[ $format == "fasta" ]] || [[ $format == "fa" ]] || [[ $format == "txt" ]]; then
		echo ""
		echo "#############################"
		echo "DONE"
		echo "#############################"
		echo "output = Reoriented_5-3.fasta"
		echo "3'-5' oriented reads = 3-5.fasta"
		echo "#############################"
		echo "You may close this window now!"
		touch ${USER_HOME}/.var_babitas/tools_finished.txt




			else
			touch ${USER_HOME}/.var_babitas/tools_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			
		fi
		fi











