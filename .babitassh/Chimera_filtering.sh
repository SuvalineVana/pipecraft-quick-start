#!/bin/bash 


echo "### CHIMERA FILTERING ###"
echo ""
echo "When using the incorporated tools, please cite as follows:"
echo ""
echo "vsearch - github.com/torognes/vsearch"
echo "Copyright (C) 2014-2015, Torbjorn Rognes, Frederic Mahe and Tomas Flouri."
echo "Distributed under the GNU General Public License version 3 by the Free Software Foundation"
echo "________________________________________________"


USER_HOME=$(eval echo ~${SUDO_USER})

#Set INPUT file variable
	input=$(cat ${USER_HOME}/.var_babitas/input_file.txt)
	echo "input="$input

	if [ -e ${USER_HOME}/.var_babitas/AbundanceAnnotation.txt ]; then
	id=$(cat ${USER_HOME}/.var_babitas/AbundanceAnnotation.txt)
	fi
	

#Set working directory
WorkingDirectory=$(awk 'BEGIN{FS=OFS="/"} NF{NF--};1' < ${USER_HOME}/.var_babitas/input_file.txt)
		if [ "$?" = "0" ]; then
 		echo "Working directory="$WorkingDirectory
		else
		touch ${USER_HOME}/.var_babitas/Chimera_filtering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi


#Set reference database variable
if [ -e "${USER_HOME}/.var_babitas/reference_db.txt" ]; then
	if grep -q 'ITS1' ${USER_HOME}/.var_babitas/reference_db.txt; then
		db=$"${USER_HOME}/.babitassh/uchime_reference_dataset_01.12.2016.ITS1.fasta"
		echo "reference database="$db

		else if grep -q 'ITS2' ${USER_HOME}/.var_babitas/reference_db.txt; then
		db=$"${USER_HOME}/.babitassh/uchime_reference_dataset_01.12.2016.ITS2.fasta"

		else 
		db=$(cat ${USER_HOME}/.var_babitas/reference_db.txt)

		fi
	fi
fi


#Set abskew
if [ -e "${USER_HOME}/.var_babitas/abskew.txt" ]; then
abskew=$(cat ${USER_HOME}/.var_babitas/abskew.txt)
fi


#Set primers variables for removing multiprimer artefacts and cutting primers
if [ -e "${USER_HOME}/.var_babitas/primers_set.txt" ]; then

	echo ""
	
	if grep -q 'New' ${USER_HOME}/.var_babitas/primers_set.txt; then
		
		if [ -e "${USER_HOME}/.var_babitas/Forward1.txt" ]; then
		Forward1=$(cat ${USER_HOME}/.var_babitas/Forward1.txt)
		fi

		if [ -e "${USER_HOME}/.var_babitas/Forward2.txt" ]; then
		Forward2=$(cat ${USER_HOME}/.var_babitas/Forward2.txt)
		fi

		if [ -e "${USER_HOME}/.var_babitas/Forward3.txt" ]; then
		Forward3=$(cat ${USER_HOME}/.var_babitas/Forward3.txt)
		fi

		if [ -e "${USER_HOME}/.var_babitas/Forward4.txt" ]; then
		Forward4=$(cat ${USER_HOME}/.var_babitas/Forward4.txt)
		fi

		if [ -e "${USER_HOME}/.var_babitas/Forward5.txt" ]; then
		Forward5=$(cat ${USER_HOME}/.var_babitas/Forward5.txt)
		fi

		if [ -e "${USER_HOME}/.var_babitas/Forward6.txt" ]; then
		Forward6=$(cat ${USER_HOME}/.var_babitas/Forward6.txt)
		fi

		if [ -e "${USER_HOME}/.var_babitas/Forward7.txt" ]; then
		Forward7=$(cat ${USER_HOME}/.var_babitas/Forward7.txt)
		fi

		if [ -e "${USER_HOME}/.var_babitas/Forward8.txt" ]; then
		Forward8=$(cat ${USER_HOME}/.var_babitas/Forward8.txt)
		fi

		if [ -e "${USER_HOME}/.var_babitas/Forward9.txt" ]; then
		Forward9=$(cat ${USER_HOME}/.var_babitas/Forward9.txt)
		fi

		if [ -e "${USER_HOME}/.var_babitas/Forward10.txt" ]; then
		Forward10=$(cat ${USER_HOME}/.var_babitas/Forward10.txt)
		fi

		if [ -e "${USER_HOME}/.var_babitas/Forward11.txt" ]; then
		Forward11=$(cat ${USER_HOME}/.var_babitas/Forward11.txt)
		fi

		if [ -e "${USER_HOME}/.var_babitas/Forward12.txt" ]; then
		Forward12=$(cat ${USER_HOME}/.var_babitas/Forward12.txt)
		fi

		if [ -e "${USER_HOME}/.var_babitas/Forward13.txt" ]; then
		Forward13=$(cat ${USER_HOME}/.var_babitas/Forward13.txt)
		fi

		if [ -e "${USER_HOME}/.var_babitas/Reverse1.txt" ]; then
		Reverse1=$(cat ${USER_HOME}/.var_babitas/Reverse1.txt)
		fi

		if [ -e "${USER_HOME}/.var_babitas/Reverse2.txt" ]; then
		Reverse2=$(cat ${USER_HOME}/.var_babitas/Reverse2.txt)
		fi

		if [ -e "${USER_HOME}/.var_babitas/Reverse3.txt" ]; then
		Reverse3=$(cat ${USER_HOME}/.var_babitas/Reverse3.txt)
		fi

		if [ -e "${USER_HOME}/.var_babitas/Reverse4.txt" ]; then
		Reverse4=$(cat ${USER_HOME}/.var_babitas/Reverse4.txt)
		fi

		if [ -e "${USER_HOME}/.var_babitas/Reverse5.txt" ]; then
		Reverse5=$(cat ${USER_HOME}/.var_babitas/Reverse5.txt)
		fi

		if [ -e "${USER_HOME}/.var_babitas/Reverse6.txt" ]; then
		Reverse6=$(cat ${USER_HOME}/.var_babitas/Reverse6.txt)
		fi

		if [ -e "${USER_HOME}/.var_babitas/Reverse7.txt" ]; then
		Reverse7=$(cat ${USER_HOME}/.var_babitas/Reverse7.txt)
		fi

		if [ -e "${USER_HOME}/.var_babitas/Reverse8.txt" ]; then
		Reverse8=$(cat ${USER_HOME}/.var_babitas/Reverse8.txt)
		fi

		if [ -e "${USER_HOME}/.var_babitas/Reverse9.txt" ]; then
		Reverse9=$(cat ${USER_HOME}/.var_babitas/Reverse9.txt)
		fi

		if [ -e "${USER_HOME}/.var_babitas/Reverse10.txt" ]; then
		Reverse10=$(cat ${USER_HOME}/.var_babitas/Reverse10.txt)
		fi

		if [ -e "${USER_HOME}/.var_babitas/Reverse11.txt" ]; then
		Reverse11=$(cat ${USER_HOME}/.var_babitas/Reverse11.txt)
		fi

		if [ -e "${USER_HOME}/.var_babitas/Reverse12.txt" ]; then
		Reverse12=$(cat ${USER_HOME}/.var_babitas/Reverse12.txt)
		fi

		if [ -e "${USER_HOME}/.var_babitas/Reverse13.txt" ]; then
		Reverse13=$(cat ${USER_HOME}/.var_babitas/Reverse13.txt)
		fi

		else if grep -q 'Old' ${USER_HOME}/.var_babitas/primers_set.txt; then
			echo ""
			cd ${USER_HOME}/.var_babitas
			
			tr "\r" " " < primers.prim | tr "\n" " " | sed -e 's/^ //g' | sed -e 's/ /\n/g' | awk '/F:_/ { print $0 }' | sed -e 's/F:_//g' | awk '{filename = sprintf("F_primer%d.txt", NR); print > filename; close(filename)}'

			tr "\r" " " < primers.prim | tr "\n" " " | sed -e 's/^ //g' | sed -e 's/ /\n/g' | awk '/R:_/ { print $0 }' | sed -e 's/R:_//g' | awk '{filename = sprintf("R_primer%d.txt", NR); print > filename; close(filename)}'
	

			#Set primer variables
			if [ -e "${USER_HOME}/.var_babitas/F_primer1.txt" ]; then
			tr --delete '\r' < F_primer1.txt | tr --delete '\n' > F_prim1.txt 
			Forward1=$(cat F_prim1.txt)
			fi
			if [ -e "${USER_HOME}/.var_babitas/F_primer2.txt" ]; then
			tr --delete '\r' < F_primer2.txt | tr --delete '\n' > F_prim2.txt
			Forward2=$(cat F_prim2.txt)
			fi
			if [ -e "${USER_HOME}/.var_babitas/F_primer3.txt" ]; then
			tr --delete '\r' < F_primer3.txt | tr --delete '\n' > F_prim3.txt
			Forward3=$(cat F_prim3.txt)
			fi
			if [ -e "${USER_HOME}/.var_babitas/F_primer4.txt" ]; then
			tr --delete '\r' < F_primer4.txt | tr --delete '\n' > F_prim4.txt
			Forward4=$(cat F_prim4.txt)
			fi
			if [ -e "${USER_HOME}/.var_babitas/F_primer5.txt" ]; then
			tr --delete '\r' < F_primer5.txt | tr --delete '\n' > F_prim5.txt
			Forward5=$(cat F_prim5.txt)
			fi
			if [ -e "${USER_HOME}/.var_babitas/F_primer6.txt" ]; then
			tr --delete '\r' < F_primer6.txt | tr --delete '\n' > F_prim6.txt
			Forward6=$(cat F_prim6.txt)
			fi
			if [ -e "${USER_HOME}/.var_babitas/F_primer7.txt" ]; then
			tr --delete '\r' < F_primer7.txt | tr --delete '\n' > F_prim7.txt
			Forward7=$(cat F_prim7.txt)
				fi
			if [ -e "${USER_HOME}/.var_babitas/F_primer8.txt" ]; then
			tr --delete '\r' < F_primer8.txt | tr --delete '\n' > F_prim8.txt
			Forward8=$(cat F_prim8.txt)
			fi
			if [ -e "${USER_HOME}/.var_babitas/F_primer9.txt" ]; then
			tr --delete '\r' < F_primer9.txt | tr --delete '\n' > F_prim9.txt
			Forward9=$(cat F_prim9.txt)
			fi
			if [ -e "${USER_HOME}/.var_babitas/F_primer10.txt" ]; then
			tr --delete '\r' < F_primer10.txt | tr --delete '\n' > F_prim10.txt
			Forward10=$(cat F_prim10.txt)
			fi

			#reverse primers
			if [ -e "${USER_HOME}/.var_babitas/R_primer1.txt" ]; then
			tr --delete '\r' < ${USER_HOME}/.var_babitas/R_primer1.txt | tr --delete '\n' > R_prim1.txt
			Reverse1=$(cat R_prim1.txt)
			fi
			if [ -e "${USER_HOME}/.var_babitas/R_primer2.txt" ]; then
			tr --delete '\r' < R_primer2.txt | tr --delete '\n' > R_prim2.txt
			Reverse2=$(cat R_prim2.txt)
			fi
			if [ -e "${USER_HOME}/.var_babitas/R_primer3.txt" ]; then
			tr --delete '\r' < R_primer3.txt | tr --delete '\n' > R_prim3.txt
			Reverse3=$(cat R_prim3.txt)
			fi
			if [ -e "${USER_HOME}/.var_babitas/R_primer4.txt" ]; then
			tr --delete '\r' < R_primer4.txt | tr --delete '\n' > R_prim4.txt
			Reverse4=$(cat R_prim4.txt)
			fi
			if [ -e "${USER_HOME}/.var_babitas/R_primer5.txt" ]; then
			tr --delete '\r' < R_primer5.txt | tr --delete '\n' > R_prim5.txt
			Reverse5=$(cat R_prim5.txt)
			fi
			if [ -e "${USER_HOME}/.var_babitas/R_primer6.txt" ]; then
			tr --delete '\r' < R_primer6.txt | tr --delete '\n' > R_prim6.txt
			Reverse6=$(cat R_prim6.txt)
			fi
			if [ -e "${USER_HOME}/.var_babitas/R_primer7.txt" ]; then
			tr --delete '\r' < R_primer7.txt | tr --delete '\n' > R_prim7.txt
			Reverse7=$(cat R_prim7.txt)
			fi
			if [ -e "${USER_HOME}/.var_babitas/R_primer8.txt" ]; then
			tr --delete '\r' < R_primer8.txt | tr --delete '\n' > R_prim8.txt
			Reverse8=$(cat R_prim8.txt)
			fi
			if [ -e "${USER_HOME}/.var_babitas/R_primer9.txt" ]; then
			tr --delete '\r' < R_primer9.txt | tr --delete '\n' > R_prim9.txt
			Reverse9=$(cat R_prim9.txt)
			fi
			if [ -e "${USER_HOME}/.var_babitas/R_primer10.txt" ]; then
			tr --delete '\r' < R_primer10.txt | tr --delete '\n' > R_prim10.txt
			Reverse10=$(cat R_prim10.txt)

			fi
	
		fi
	fi
fi


cd $WorkingDirectory
		if [ "$?" = "0" ]; then
 		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Chimera_filtering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi




                               ##
                             ######
                           ##########
                         ##############
                       ##################
                     ######################
                   ##########################
                 ##############################
               ##################################
             ######################################
           #########################################
         ##############################################
       ##################################################
       ############### CHIMERA FILTERING ################
       ##################################################
   ##########################################################
 ##############################################################
############ denovo + ref + cut primers + multiprim ############
################################################################
################################################################
if [ -e "${USER_HOME}/.var_babitas/denovo.txt" ] && [ -e "${USER_HOME}/.var_babitas/reference_db.txt" ] && [ -e "${USER_HOME}/.var_babitas/multiprimer.txt" ] && [ -e "${USER_HOME}/.var_babitas/cut_primers.txt" ]; then
echo ""
echo "### Removing primers + Denovo + reference database chimera filtering ###"
echo "### + removing primer artefacts ###"
echo ""


#Removing primers
	echo ""
	echo "### Cutting primers"
	echo "# using sed;"
	
	echo ""

#Forward primers
	if [ -e "${USER_HOME}/.var_babitas/Forward1.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer1.txt" ]; then

		echo "searching and deleting fwd primer strings if they appear among the first 25 base pairs"
		sed --in-place=.backup "s/^.\{0,25\}$Forward1//g" $input
		echo "Removed forward primer "$Forward1
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward2.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer2.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward2//g" $input
		echo "Removed forward primer "$Forward2
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward3.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer3.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward3//g" $input
		echo "Removed forward primer "$Forward3
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward4.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer4.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward4//g" $input
		echo "Removed forward primer "$Forward4
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward5.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer5.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward5//g" $input
		echo "Removed forward primer "$Forward5
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward6.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer6.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward6//g" $input
		echo "Removed forward primer "$Forward6
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward7.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer7.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward7//g" $input
		echo "Removed forward primer "$Forward7
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward8.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer8.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward8//g" $input
		echo "Removed forward primer "$Forward8
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward9.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer9.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward9//g" $input
		echo "Removed forward primer "$Forward9
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward10.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer10.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward10//g" $input
		echo "Removed forward primer "$Forward10
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward11.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward11//g" $input
		echo "Removed forward primer "$Forward11
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward12.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward12//g" $input
		echo "Removed forward primer "$Forward12
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward13.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward13//g" $input
		echo "Removed forward primer "$Forward13
	fi


#Reverse primers
	if [ -e "${USER_HOME}/.var_babitas/Reverse1.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer1.txt" ]; then

		echo "searching and deleting rev primer strings (rc) if they appear among the last 25 base pairs"

		#reverse complement of reverse primer
		Reverse1_rc=$(echo $Reverse1 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse1_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse1
	fi


	if [ -e "${USER_HOME}/.var_babitas/Reverse2.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer2.txt" ]; then
		#reverse complement of reverse primer
		Reverse2_rc=$(echo $Reverse2 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse2_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse2
	fi


	if [ -e "${USER_HOME}/.var_babitas/Reverse3.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer3.txt" ]; then
		#reverse complement of reverse primer
		Reverse3_rc=$(echo $Reverse3 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse3_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse3
	fi


	if [ -e "${USER_HOME}/.var_babitas/Reverse4.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer4.txt" ]; then
		#reverse complement of reverse primer
		Reverse4_rc=$(echo $Reverse4 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse4_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse4
	fi


	if [ -e "${USER_HOME}/.var_babitas/Reverse5.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer5.txt" ]; then
		#reverse complement of reverse primer
		Reverse5_rc=$(echo $Reverse5 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse5_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse5
	fi


	if [ -e "${USER_HOME}/.var_babitas/Reverse6.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer6.txt" ]; then
		#reverse complement of reverse primer
		Reverse6_rc=$(echo $Reverse6 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse6_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse6
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse7.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer7.txt" ]; then
		#reverse complement of reverse primer
		Reverse7_rc=$(echo $Reverse7 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse7_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse7
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse8.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer8.txt" ]; then
		#reverse complement of reverse primer
		Reverse8_rc=$(echo $Reverse8 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse8_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse8
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse9.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer9.txt" ]; then
		#reverse complement of reverse primer
		Reverse9_rc=$(echo $Reverse9 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse9_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse9
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse10.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer10.txt" ]; then
		#reverse complement of reverse primer
		Reverse10_rc=$(echo $Reverse10 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse10_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse10
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse11.txt" ]; then
		#reverse complement of reverse primer
		Reverse11_rc=$(echo $Reverse11 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse11_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse11
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse12.txt" ]; then
		#reverse complement of reverse primer
		Reverse12_rc=$(echo $Reverse12 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse12_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse12
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse13.txt" ]; then
		#reverse complement of reverse primer
		Reverse13_rc=$(echo $Reverse13 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse13_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse13
	fi




#Denovo
echo ""
echo "# Abundance annotation for de novo chimera filtering"
echo "# id="$id
echo "vsearch --cluster_fast $input --id $id --centroids centroids.fasta --sizeout"

vsearch --cluster_fast $input --id $id --centroids centroids.fasta --sizeout
	if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Chimera_filtering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
	fi

echo ""
echo "# Sort by size"
echo "vsearch --sortbysize centroids.fasta --output sortbysize.fasta"

vsearch --sortbysize centroids.fasta --output sortbysize.fasta
	if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Chimera_filtering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
	fi

echo ""
echo "# De novo chimera detection"
echo "# abskew="$abskew
echo "vsearch --uchime_denovo sortbysize.fasta --abskew $abskew --chimeras chimeras_denovo.fasta --nonchimeras nonchimeras_denovo.fasta"

vsearch --uchime_denovo sortbysize.fasta --abskew $abskew --chimeras chimeras_denovo.fasta --nonchimeras nonchimeras_denovo.fasta
	if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Chimera_filtering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
	fi


	#vsearch DECLUSTER
	echo "# vsearch DECLUSTER"
	echo "vsearch --usearch_global $input --db nonchimeras_denovo.fasta --id $id --fasta_width 0 --matched Filtered_ChimerasDenovo.fasta --notmatched ChimerasDenovo.fasta"

	vsearch --usearch_global $input --db nonchimeras_denovo.fasta --id $id --fasta_width 0 --matched Filtered_ChimerasDenovo.fasta --notmatched ChimerasDenovo.fasta
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Chimera_filtering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi


echo ""
echo "### Reference db chimera filtering"
echo "# db="$db
echo ""
echo "vsearch --uchime_ref Filtered_ChimerasDenovo.fasta --db $db --fasta_width 0 --chimeras ChimerasRef.fasta --nonchimeras Filtered_ChimerasDenovoRef.fasta --xsize"

	vsearch --uchime_ref Filtered_ChimerasDenovo.fasta --db $db --fasta_width 0 --chimeras ChimerasRef.fasta --nonchimeras Filtered_ChimerasDenovoRef.fasta --xsize
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Chimera_filtering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi




###Fasta to oneline for removing primer artifacts
	echo ""
	echo "### Removing primer artifacts"
	echo "# using 'sed --in-place /PRIMER/d'"
	echo ""

#Forward primers
	tr "\n" "@" < Filtered_ChimerasDenovoRef.fasta | sed -e 's/@>/\n>/g' > Chimera_filtered_oneline.fasta

	if [ -e "${USER_HOME}/.var_babitas/Forward1.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer1.txt" ]; then
	sed --in-place "/$Forward1/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward1
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward2.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer2.txt" ]; then
	sed --in-place "/$Forward2/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward2
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward3.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer3.txt" ]; then
	sed --in-place "/$Forward3/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward3
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward4.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer4.txt" ]; then
	sed --in-place "/$Forward4/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward4
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward5.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer5.txt" ]; then
	sed --in-place "/$Forward5/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward5
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward6.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer6.txt" ]; then
	sed --in-place "/$Forward6/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward6
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward7.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer7.txt" ]; then
	sed --in-place "/$Forward7/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward7
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward8.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer8.txt" ]; then
	sed --in-place "/$Forward8/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward8
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward9.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer9.txt" ]; then
	sed --in-place "/$Forward9/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward9
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward10.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer10.txt" ]; then
	sed --in-place "/$Forward10/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward10
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward11.txt" ]; then
	sed --in-place "/$Forward11/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward11
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward12.txt" ]; then
	sed --in-place "/$Forward12/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward12
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward13.txt" ]; then
	sed --in-place "/$Forward13/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward13
	fi

	
#Reverse primers
	if [ -e "${USER_HOME}/.var_babitas/Reverse1.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer1.txt" ]; then
	#make reverse complement to reverse primer
	Reverse1_rc=$(echo $Reverse1 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse1_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse1
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse2.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer2.txt" ]; then
	#make reverse complement to reverse primer
	Reverse2_rc=$(echo $Reverse2 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse2_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse2
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse3.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer3.txt" ]; then
	#make reverse complement to reverse primer
	Reverse3_rc=$(echo $Reverse3 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse3_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse3
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse4.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer4.txt" ]; then
	#make reverse complement to reverse primer
	Reverse4_rc=$(echo $Reverse4 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse4_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse4
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse5.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer5.txt" ]; then
	#make reverse complement to reverse primer
	Reverse5_rc=$(echo $Reverse5 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse5_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse5
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse6.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer6.txt" ]; then
	#make reverse complement to reverse primer
	Reverse6_rc=$(echo $Reverse6 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse6_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse6
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse7.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer7.txt" ]; then
	#make reverse complement to reverse primer
	Reverse7_rc=$(echo $Reverse7 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse7_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse7
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse8.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer8.txt" ]; then
	#make reverse complement to reverse primer
	Reverse8_rc=$(echo $Reverse8 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse8_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse8
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse9.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer9.txt" ]; then
	#make reverse complement to reverse primer
	Reverse9_rc=$(echo $Reverse9 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse9_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse9
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse10.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer10.txt" ]; then
	#make reverse complement to reverse primer
	Reverse10_rc=$(echo $Reverse10 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse10_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse10
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse11.txt" ]; then
	#make reverse complement to reverse primer
	Reverse11_rc=$(echo $Reverse11 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse11_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Reverse11
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse12.txt" ]; then
	#make reverse complement to reverse primer
	Reverse12_rc=$(echo $Reverse12 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse12_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Reverse12
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse13.txt" ]; then
	#make reverse complement to reverse primer
	Reverse13_rc=$(echo $Reverse13 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse13_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Reverse13
	fi

#Chimera_filtered_oneline.fasta to regular fasta
sed -e 's/@/\n/g' < Chimera_filtered_oneline.fasta | sed '/^\n*$/d' > Filtered_ChimerasDenovoRef_Multiprim.fasta

	if [ -e Chimera_filtered_oneline.fasta ]; then
	rm Chimera_filtered_oneline.fasta
	fi



touch ${USER_HOME}/.var_babitas/Chimera_filtering_finished.txt

input_seqs=$(grep -c "^>" $input)
output_seqs=$(grep -c "^>" Filtered_ChimerasDenovoRef_Multiprim.fasta)
output_seqs2=$(grep -c "^>" Filtered_ChimerasDenovo.fasta)
output_seqs3=$(grep -c "^>" Filtered_ChimerasDenovoRef.fasta)

echo ""
echo "Input fasta file = $input_seqs sequences"
echo "Output (Filtered_ChimerasDenovoRef_Multiprim.fasta) file = $output_seqs sequences"
echo ""
echo "   (Filtered_ChimerasDenovo.fasta = $output_seqs2 sequences)"
echo "   (Filtered_ChimerasDenovoRef.fasta = $output_seqs3 sequences)"
echo ""

echo "##########################"
echo "DONE"
echo "############################"
echo "Primers cut"
echo "Chimera filtering finished"
echo "##############################"
echo "output = Filtered_ChimerasDenovoRef_Multiprim.fasta"
echo "################################"
echo "You may close this window now!"
		




##################################################
##################################################
############ denovo + ref + multiprim ############
##################################################
##################################################
else if [ -e "${USER_HOME}/.var_babitas/denovo.txt" ] && [ -e "${USER_HOME}/.var_babitas/reference_db.txt" ] && [ -e "${USER_HOME}/.var_babitas/multiprimer.txt" ]; then
echo ""
echo "### Denovo + reference database chimera filtering ###"
echo "### + removing primer artefacts ###"
echo ""

echo "# Abundance annotation for de novo chimera filtering"
echo "# id="$id
echo "vsearch --cluster_fast $input --id $id --centroids centroids.fasta --sizeout"

vsearch --cluster_fast $input --id $id --centroids centroids.fasta --sizeout
	if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Chimera_filtering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
	fi

echo ""
echo "# Sort by size"
echo "vsearch --sortbysize centroids.fasta --output sortbysize.fasta"

vsearch --sortbysize centroids.fasta --output sortbysize.fasta
	if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Chimera_filtering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
	fi

echo ""
echo "# De novo chimera detection"
echo "# abskew="$abskew
echo "vsearch --uchime_denovo sortbysize.fasta --abskew $abskew --chimeras chimeras_denovo.fasta --nonchimeras nonchimeras_denovo.fasta"

vsearch --uchime_denovo sortbysize.fasta --abskew $abskew --chimeras chimeras_denovo.fasta --nonchimeras nonchimeras_denovo.fasta
	if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Chimera_filtering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
	fi


	#vsearch DECLUSTER
	echo "# vsearch DECLUSTER"
	echo "vsearch --usearch_global $input --db nonchimeras_denovo.fasta --id $id --fasta_width 0 --matched Filtered_ChimerasDenovo.fasta --notmatched ChimerasDenovo.fasta"

	vsearch --usearch_global $input --db nonchimeras_denovo.fasta --id $id --fasta_width 0 --matched Filtered_ChimerasDenovo.fasta --notmatched ChimerasDenovo.fasta
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Chimera_filtering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi


echo ""
echo "### Reference db chimera filtering"
echo "# db="$db
echo ""
echo "vsearch --uchime_ref Filtered_ChimerasDenovo.fasta --db $db --fasta_width 0 --chimeras ChimerasRef.fasta --nonchimeras Filtered_ChimerasDenovoRef.fasta --xsize"

	vsearch --uchime_ref Filtered_ChimerasDenovo.fasta --db $db --fasta_width 0 --chimeras ChimerasRef.fasta --nonchimeras Filtered_ChimerasDenovoRef.fasta --xsize
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Chimera_filtering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi



###Fasta to oneline for removing primer artifacts
	echo ""
	echo "### Removing primer artifacts"
	echo "# using 'sed --in-place /PRIMER/d'"
	echo ""

#Forward primers
	tr "\n" "@" < Filtered_ChimerasDenovoRef.fasta | sed -e 's/@>/\n>/g' > Chimera_filtered_oneline.fasta

	if [ -e "${USER_HOME}/.var_babitas/Forward1.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer1.txt" ]; then
	sed --in-place "/$Forward1/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward1
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward2.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer2.txt" ]; then
	sed --in-place "/$Forward2/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward2
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward3.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer3.txt" ]; then
	sed --in-place "/$Forward3/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward3
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward4.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer4.txt" ]; then
	sed --in-place "/$Forward4/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward4
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward5.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer5.txt" ]; then
	sed --in-place "/$Forward5/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward5
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward6.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer6.txt" ]; then
	sed --in-place "/$Forward6/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward6
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward7.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer7.txt" ]; then
	sed --in-place "/$Forward7/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward7
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward8.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer8.txt" ]; then
	sed --in-place "/$Forward8/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward8
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward9.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer9.txt" ]; then
	sed --in-place "/$Forward9/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward9
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward10.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer10.txt" ]; then
	sed --in-place "/$Forward10/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward10
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward11.txt" ]; then
	sed --in-place "/$Forward11/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward11
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward12.txt" ]; then
	sed --in-place "/$Forward12/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward12
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward13.txt" ]; then
	sed --in-place "/$Forward13/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward13
	fi

	
#Reverse primers
	if [ -e "${USER_HOME}/.var_babitas/Reverse1.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer1.txt" ]; then
	#make reverse complement to reverse primer
	Reverse1_rc=$(echo $Reverse1 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse1_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse1
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse2.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer2.txt" ]; then
	#make reverse complement to reverse primer
	Reverse2_rc=$(echo $Reverse2 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse2_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse2
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse3.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer3.txt" ]; then
	#make reverse complement to reverse primer
	Reverse3_rc=$(echo $Reverse3 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse3_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse3
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse4.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer4.txt" ]; then
	#make reverse complement to reverse primer
	Reverse4_rc=$(echo $Reverse4 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse4_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse4
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse5.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer5.txt" ]; then
	#make reverse complement to reverse primer
	Reverse5_rc=$(echo $Reverse5 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse5_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse5
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse6.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer6.txt" ]; then
	#make reverse complement to reverse primer
	Reverse6_rc=$(echo $Reverse6 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse6_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse6
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse7.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer7.txt" ]; then
	#make reverse complement to reverse primer
	Reverse7_rc=$(echo $Reverse7 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse7_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse7
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse8.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer8.txt" ]; then
	#make reverse complement to reverse primer
	Reverse8_rc=$(echo $Reverse8 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse8_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse8
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse9.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer9.txt" ]; then
	#make reverse complement to reverse primer
	Reverse9_rc=$(echo $Reverse9 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse9_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse9
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse10.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer10.txt" ]; then
	#make reverse complement to reverse primer
	Reverse10_rc=$(echo $Reverse10 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse10_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse10
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse11.txt" ]; then
	#make reverse complement to reverse primer
	Reverse11_rc=$(echo $Reverse11 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse11_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Reverse11
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse12.txt" ]; then
	#make reverse complement to reverse primer
	Reverse12_rc=$(echo $Reverse12 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse12_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Reverse12
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse13.txt" ]; then
	#make reverse complement to reverse primer
	Reverse13_rc=$(echo $Reverse13 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse13_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Reverse13
	fi

#Chimera_filtered_oneline.fasta to regular fasta
sed -e 's/@/\n/g' < Chimera_filtered_oneline.fasta | sed '/^\n*$/d' > Filtered_ChimerasDenovoRef_Multiprim.fasta

	if [ -e Chimera_filtered_oneline.fasta ]; then
	rm Chimera_filtered_oneline.fasta
	fi




touch ${USER_HOME}/.var_babitas/Chimera_filtering_finished.txt

input_seqs=$(grep -c "^>" $input)
output_seqs=$(grep -c "^>" Filtered_ChimerasDenovoRef_Multiprim.fasta)
output_seqs2=$(grep -c "^>" Filtered_ChimerasDenovo.fasta)
output_seqs3=$(grep -c "^>" Filtered_ChimerasDenovoRef.fasta)

echo ""
echo "Input fasta file = $input_seqs sequences"
echo "Output (Filtered_ChimerasDenovoRef_Multiprim.fasta) file = $output_seqs sequences"
echo ""
echo "   (Filtered_ChimerasDenovo.fasta = $output_seqs2 sequences)"
echo "   (Filtered_ChimerasDenovoRef.fasta = $output_seqs3 sequences)"
echo ""

echo "##########################"
echo "DONE"
echo "############################"
echo "Chimera filtering finished"
echo "##############################"
echo "output = Filtered_ChimerasDenovoRef_Multiprim.fasta"
echo "################################"
echo "You may close this window now!"
		

##################################################
##################################################
############### CHIMERA FILTERING ################
##################################################
########## cut primers + denovo + ref ############
##################################################
##################################################
else if [ -e "${USER_HOME}/.var_babitas/denovo.txt" ] && [ -e "${USER_HOME}/.var_babitas/reference_db.txt" ] && [ -e "${USER_HOME}/.var_babitas/cut_primers.txt" ]; then
#Removing primers
	echo ""
	echo "### Cutting primers"
	echo "# using sed;"
	echo ""

#Forward primers
	if [ -e "${USER_HOME}/.var_babitas/Forward1.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer1.txt" ]; then
		echo "searching and deleting fwd primer strings if they appear among the first 25 base pairs"
		sed --in-place=.backup "s/^.\{0,25\}$Forward1//g" $input
		echo "Removed forward primer "$Forward1
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward2.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer2.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward2//g" $input
		echo "Removed forward primer "$Forward2
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward3.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer3.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward3//g" $input
		echo "Removed forward primer "$Forward3
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward4.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer4.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward4//g" $input
		echo "Removed forward primer "$Forward4
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward5.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer5.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward5//g" $input
		echo "Removed forward primer "$Forward5
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward6.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer6.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward6//g" $input
		echo "Removed forward primer "$Forward6
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward7.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer7.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward7//g" $input
		echo "Removed forward primer "$Forward7
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward8.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer8.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward8//g" $input
		echo "Removed forward primer "$Forward8
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward9.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer9.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward9//g" $input
		echo "Removed forward primer "$Forward9
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward10.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer10.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward10//g" $input
		echo "Removed forward primer "$Forward10
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward11.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward11//g" $input
		echo "Removed forward primer "$Forward11
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward12.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward12//g" $input
		echo "Removed forward primer "$Forward12
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward13.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward13//g" $input
		echo "Removed forward primer "$Forward13
	fi


#Reverse primers
	if [ -e "${USER_HOME}/.var_babitas/Reverse1.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer1.txt" ]; then
		echo "searching and deleting rev primer strings (rc) if they appear among the last 25 base pairs"
		#reverse complement of reverse primer
		Reverse1_rc=$(echo $Reverse1 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse1_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse1
	fi


	if [ -e "${USER_HOME}/.var_babitas/Reverse2.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer2.txt" ]; then
		#reverse complement of reverse primer
		Reverse2_rc=$(echo $Reverse2 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse2_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse2
	fi


	if [ -e "${USER_HOME}/.var_babitas/Reverse3.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer3.txt" ]; then
		#reverse complement of reverse primer
		Reverse3_rc=$(echo $Reverse3 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse3_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse3
	fi


	if [ -e "${USER_HOME}/.var_babitas/Reverse4.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer4.txt" ]; then
		#reverse complement of reverse primer
		Reverse4_rc=$(echo $Reverse4 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse4_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse4
	fi


	if [ -e "${USER_HOME}/.var_babitas/Reverse5.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer5.txt" ]; then
		#reverse complement of reverse primer
		Reverse5_rc=$(echo $Reverse5 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse5_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse5
	fi


	if [ -e "${USER_HOME}/.var_babitas/Reverse6.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer6.txt" ]; then
		#reverse complement of reverse primer
		Reverse6_rc=$(echo $Reverse6 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse6_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse6
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse7.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer7.txt" ]; then
		#reverse complement of reverse primer
		Reverse7_rc=$(echo $Reverse7 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse7_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse7
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse8.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer8.txt" ]; then
		#reverse complement of reverse primer
		Reverse8_rc=$(echo $Reverse8 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse8_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse8
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse9.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer9.txt" ]; then
		#reverse complement of reverse primer
		Reverse9_rc=$(echo $Reverse9 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse9_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse9
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse10.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer10.txt" ]; then
		#reverse complement of reverse primer
		Reverse10_rc=$(echo $Reverse10 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse10_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse10
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse11.txt" ]; then
		#reverse complement of reverse primer
		Reverse11_rc=$(echo $Reverse11 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse11_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse11
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse12.txt" ]; then
		#reverse complement of reverse primer
		Reverse12_rc=$(echo $Reverse12 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse12_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse12
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse13.txt" ]; then
		#reverse complement of reverse primer
		Reverse13_rc=$(echo $Reverse13 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse13_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse13
	fi


#devovo
echo ""
echo "### Denovo + reference database chimera filtering ###"
echo ""

echo "# Abundance annotation for de novo chimera filtering"
echo "# id="$id
echo "vsearch --cluster_fast $input --id $id --centroids centroids.fasta --sizeout"

vsearch --cluster_fast $input --id $id --centroids centroids.fasta --sizeout
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Chimera_filtering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi

echo ""
echo "# Sort by size"
echo "vsearch --sortbysize centroids.fasta --output sortbysize.fasta"

vsearch --sortbysize centroids.fasta --output sortbysize.fasta
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Chimera_filtering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi

echo ""
echo "# De novo chimera detection"
echo "# abskew="$abskew
echo "vsearch --uchime_denovo sortbysize.fasta --abskew $abskew --chimeras chimeras_denovo.fasta --nonchimeras nonchimeras_denovo.fasta"

vsearch --uchime_denovo sortbysize.fasta --abskew $abskew --chimeras chimeras_denovo.fasta --nonchimeras nonchimeras_denovo.fasta
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Chimera_filtering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi


	#vsearch DECLUSTER
	echo "# vsearch DECLUSTER"
	echo "vsearch --usearch_global $input --db nonchimeras_denovo.fasta --id $id --fasta_width 0 --matched Filtered_ChimerasDenovo.fasta --notmatched ChimerasDenovo.fasta"

	vsearch --usearch_global $input --db nonchimeras_denovo.fasta --id $id --fasta_width 0 --matched Filtered_ChimerasDenovo.fasta --notmatched ChimerasDenovo.fasta
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Chimera_filtering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi


echo ""
echo "### Reference db chimera filtering"
echo "# db="$db
echo ""
echo "vsearch --uchime_ref Filtered_ChimerasDenovo.fasta --db $db --fasta_width 0 --chimeras ChimerasRef.fasta --nonchimeras Filtered_ChimerasDenovoRef.fasta --xsize"

	vsearch --uchime_ref Filtered_ChimerasDenovo.fasta --db $db --fasta_width 0 --chimeras ChimerasRef.fasta --nonchimeras Filtered_ChimerasDenovoRef.fasta --xsize
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Chimera_filtering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi


touch ${USER_HOME}/.var_babitas/Chimera_filtering_finished.txt

input_seqs=$(grep -c "^>" $input)
output_seqs=$(grep -c "^>" Filtered_ChimerasDenovoRef.fasta)
output_seqs2=$(grep -c "^>" Filtered_ChimerasDenovo.fasta)

echo ""
echo "Input fasta file = $input_seqs sequences"
echo "Output (Filtered_ChimerasDenovoRef.fasta) file = $output_seqs sequences"
echo "   (Filtered_ChimerasDenovo.fasta = $output_seqs2 sequences)"
echo ""

echo "##########################"
echo "DONE"
echo "############################"
echo "Primers cut"
echo "Chimera filtering finished"
echo "##############################"
echo "output = Filtered_ChimerasDenovoRef.fasta"
echo "################################"
echo "You may close this window now!"

##################################################
##################################################
############### CHIMERA FILTERING ################
##################################################
########## cut primers + denovo + mp  ############
##################################################
##################################################
else if [ -e "${USER_HOME}/.var_babitas/denovo.txt" ] && [ -e "${USER_HOME}/.var_babitas/multiprimer.txt" ] && [ -e "${USER_HOME}/.var_babitas/cut_primers.txt" ]; then

#Removing primers
	echo ""
	echo "### Cutting primers"
	echo "# using sed;"
	
	
	echo ""

#Forward primers
	if [ -e "${USER_HOME}/.var_babitas/Forward1.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer1.txt" ]; then
		echo "searching and deleting fwd primer strings if they appear among the first 25 base pairs"
		sed --in-place=.backup "s/^.\{0,25\}$Forward1//g" $input
		echo "Removed forward primer "$Forward1
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward2.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer2.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward2//g" $input
		echo "Removed forward primer "$Forward2
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward3.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer3.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward3//g" $input
		echo "Removed forward primer "$Forward3
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward4.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer4.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward4//g" $input
		echo "Removed forward primer "$Forward4
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward5.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer5.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward5//g" $input
		echo "Removed forward primer "$Forward5
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward6.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer6.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward6//g" $input
		echo "Removed forward primer "$Forward6
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward7.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer7.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward7//g" $input
		echo "Removed forward primer "$Forward7
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward8.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer8.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward8//g" $input
		echo "Removed forward primer "$Forward8
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward9.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer9.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward9//g" $input
		echo "Removed forward primer "$Forward9
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward10.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer10.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward10//g" $input
		echo "Removed forward primer "$Forward10
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward11.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward11//g" $input
		echo "Removed forward primer "$Forward11
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward12.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward12//g" $input
		echo "Removed forward primer "$Forward12
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward13.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward13//g" $input
		echo "Removed forward primer "$Forward13
	fi


#Reverse primers
	if [ -e "${USER_HOME}/.var_babitas/Reverse1.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer1.txt" ]; then
		echo "searching and deleting rev primer strings (rc) if they appear among the last 25 base pairs"
		#reverse complement of reverse primer
		Reverse1_rc=$(echo $Reverse1 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse1_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse1
	fi


	if [ -e "${USER_HOME}/.var_babitas/Reverse2.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer2.txt" ]; then
		#reverse complement of reverse primer
		Reverse2_rc=$(echo $Reverse2 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse2_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse2
	fi


	if [ -e "${USER_HOME}/.var_babitas/Reverse3.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer3.txt" ]; then
		#reverse complement of reverse primer
		Reverse3_rc=$(echo $Reverse3 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse3_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse3
	fi


	if [ -e "${USER_HOME}/.var_babitas/Reverse4.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer4.txt" ]; then
		#reverse complement of reverse primer
		Reverse4_rc=$(echo $Reverse4 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse4_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse4
	fi


	if [ -e "${USER_HOME}/.var_babitas/Reverse5.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer5.txt" ]; then
		#reverse complement of reverse primer
		Reverse5_rc=$(echo $Reverse5 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse5_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse5
	fi


	if [ -e "${USER_HOME}/.var_babitas/Reverse6.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer6.txt" ]; then
		#reverse complement of reverse primer
		Reverse6_rc=$(echo $Reverse6 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse6_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse6
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse7.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer7.txt" ]; then
		#reverse complement of reverse primer
		Reverse7_rc=$(echo $Reverse7 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse7_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse7
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse8.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer8.txt" ]; then
		#reverse complement of reverse primer
		Reverse8_rc=$(echo $Reverse8 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse8_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse8
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse9.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer9.txt" ]; then
		#reverse complement of reverse primer
		Reverse9_rc=$(echo $Reverse9 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse9_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse9
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse10.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer10.txt" ]; then
		#reverse complement of reverse primer
		Reverse10_rc=$(echo $Reverse10 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse10_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse10
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse11.txt" ]; then
		#reverse complement of reverse primer
		Reverse11_rc=$(echo $Reverse11 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse11_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse11
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse12.txt" ]; then
		#reverse complement of reverse primer
		Reverse12_rc=$(echo $Reverse12 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse12_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse12
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse13.txt" ]; then
		#reverse complement of reverse primer
		Reverse13_rc=$(echo $Reverse13 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse13_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse13
	fi



#devovo
echo ""
echo "### Denovo + reference database chimera filtering ###"
echo ""

echo "# Abundance annotation for de novo chimera filtering"
echo "# id="$id
echo "vsearch --cluster_fast $input --id $id --centroids centroids.fasta --sizeout"

vsearch --cluster_fast $input --id $id --centroids centroids.fasta --sizeout
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Chimera_filtering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi

echo ""
echo "# Sort by size"
echo "vsearch --sortbysize centroids.fasta --output sortbysize.fasta"

vsearch --sortbysize centroids.fasta --output sortbysize.fasta
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Chimera_filtering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi

echo ""
echo "# De novo chimera detection"
echo "# abskew="$abskew
echo "vsearch --uchime_denovo sortbysize.fasta --abskew $abskew --chimeras chimeras_denovo.fasta --nonchimeras nonchimeras_denovo.fasta"

vsearch --uchime_denovo sortbysize.fasta --abskew $abskew --chimeras chimeras_denovo.fasta --nonchimeras nonchimeras_denovo.fasta
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Chimera_filtering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi


	#vsearch DECLUSTER
	echo "# vsearch DECLUSTER"
	echo "vsearch --usearch_global $input --db nonchimeras_denovo.fasta --id $id --fasta_width 0 --matched Filtered_ChimerasDenovo.fasta --notmatched ChimerasDenovo.fasta"

	vsearch --usearch_global $input --db nonchimeras_denovo.fasta --id $id --fasta_width 0 --matched Filtered_ChimerasDenovo.fasta --notmatched ChimerasDenovo.fasta
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Chimera_filtering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi




###Fasta to oneline for removing primer artifacts
	echo ""
	echo "### Removing primer artifacts"
	echo "# using 'sed --in-place /PRIMER/d'"
	echo ""

#Forward primers
	tr "\n" "@" < Filtered_ChimerasDenovo.fasta | sed -e 's/@>/\n>/g' > Chimera_filtered_oneline.fasta

	if [ -e "${USER_HOME}/.var_babitas/Forward1.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer1.txt" ]; then
	sed --in-place "/$Forward1/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward1
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward2.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer2.txt" ]; then
	sed --in-place "/$Forward2/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward2
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward3.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer3.txt" ]; then
	sed --in-place "/$Forward3/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward3
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward4.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer4.txt" ]; then
	sed --in-place "/$Forward4/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward4
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward5.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer5.txt" ]; then
	sed --in-place "/$Forward5/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward5
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward6.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer6.txt" ]; then
	sed --in-place "/$Forward6/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward6
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward7.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer7.txt" ]; then
	sed --in-place "/$Forward7/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward7
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward8.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer8.txt" ]; then
	sed --in-place "/$Forward8/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward8
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward9.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer9.txt" ]; then
	sed --in-place "/$Forward9/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward9
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward10.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer10.txt" ]; then
	sed --in-place "/$Forward10/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward10
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward11.txt" ]; then
	sed --in-place "/$Forward11/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward11
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward12.txt" ]; then
	sed --in-place "/$Forward12/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward12
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward13.txt" ]; then
	sed --in-place "/$Forward13/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward13
	fi

	
#Reverse primers
	if [ -e "${USER_HOME}/.var_babitas/Reverse1.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer1.txt" ]; then
	#make reverse complement to reverse primer
	Reverse1_rc=$(echo $Reverse1 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse1_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse1
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse2.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer2.txt" ]; then
	#make reverse complement to reverse primer
	Reverse2_rc=$(echo $Reverse2 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse2_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse2
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse3.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer3.txt" ]; then
	#make reverse complement to reverse primer
	Reverse3_rc=$(echo $Reverse3 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse3_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse3
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse4.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer4.txt" ]; then
	#make reverse complement to reverse primer
	Reverse4_rc=$(echo $Reverse4 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse4_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse4
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse5.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer5.txt" ]; then
	#make reverse complement to reverse primer
	Reverse5_rc=$(echo $Reverse5 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse5_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse5
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse6.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer6.txt" ]; then
	#make reverse complement to reverse primer
	Reverse6_rc=$(echo $Reverse6 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse6_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse6
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse7.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer7.txt" ]; then
	#make reverse complement to reverse primer
	Reverse7_rc=$(echo $Reverse7 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse7_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse7
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse8.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer8.txt" ]; then
	#make reverse complement to reverse primer
	Reverse8_rc=$(echo $Reverse8 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse8_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse8
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse9.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer9.txt" ]; then
	#make reverse complement to reverse primer
	Reverse9_rc=$(echo $Reverse9 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse9_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse9
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse10.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer10.txt" ]; then
	#make reverse complement to reverse primer
	Reverse10_rc=$(echo $Reverse10 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse10_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse10
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse11.txt" ]; then
	#make reverse complement to reverse primer
	Reverse11_rc=$(echo $Reverse11 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse11_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Reverse11
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse12.txt" ]; then
	#make reverse complement to reverse primer
	Reverse12_rc=$(echo $Reverse12 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse12_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Reverse12
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse13.txt" ]; then
	#make reverse complement to reverse primer
	Reverse13_rc=$(echo $Reverse13 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse13_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Reverse13
	fi

#Chimera_filtered_oneline.fasta to regular fasta
sed -e 's/@/\n/g' < Chimera_filtered_oneline.fasta | sed '/^\n*$/d' > Filtered_ChimerasDenovo_Multiprim.fasta

	if [ -e Chimera_filtered_oneline.fasta ]; then
	rm Chimera_filtered_oneline.fasta
	fi


touch ${USER_HOME}/.var_babitas/Chimera_filtering_finished.txt

input_seqs=$(grep -c "^>" $input)
output_seqs=$(grep -c "^>" Filtered_ChimerasDenovo_Multiprim.fasta)
output_seqs2=$(grep -c "^>" Filtered_ChimerasDenovo.fasta)

echo ""
echo "Input fasta file = $input_seqs sequences"
echo "Output (Filtered_ChimerasDenovo_Multiprim.fasta) file = $output_seqs sequences"
echo "   (Filtered_ChimerasDenovo.fasta = $output_seqs2 sequences)"
echo ""

echo "##########################"
echo "DONE"
echo "############################"
echo "Primers cut"
echo "Chimera filtering finished"
echo "##############################"
echo "output = Filtered_ChimerasDenovo_Multiprim.fasta"
echo "################################"
echo "You may close this window now!"

##################################################
##################################################
############### CHIMERA FILTERING ################
##################################################
##########   cut primers + ref + mp   ############
##################################################
##################################################
else if [ -e "${USER_HOME}/.var_babitas/reference_db.txt" ] && [ -e "${USER_HOME}/.var_babitas/multiprimer.txt" ] && [ -e "${USER_HOME}/.var_babitas/cut_primers.txt" ]; then

#Removing primers
	echo ""
	echo "### Cutting primers"
	echo "# using sed;"
	
	echo ""

#Forward primers
	if [ -e "${USER_HOME}/.var_babitas/Forward1.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer1.txt" ]; then
		echo "searching and deleting fwd primer strings if they appear among the first 25 base pairs"
		sed --in-place=.backup "s/^.\{0,25\}$Forward1//g" $input
		echo "Removed forward primer "$Forward1
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward2.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer2.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward2//g" $input
		echo "Removed forward primer "$Forward2
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward3.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer3.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward3//g" $input
		echo "Removed forward primer "$Forward3
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward4.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer4.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward4//g" $input
		echo "Removed forward primer "$Forward4
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward5.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer5.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward5//g" $input
		echo "Removed forward primer "$Forward5
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward6.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer6.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward6//g" $input
		echo "Removed forward primer "$Forward6
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward7.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer7.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward7//g" $input
		echo "Removed forward primer "$Forward7
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward8.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer8.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward8//g" $input
		echo "Removed forward primer "$Forward8
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward9.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer9.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward9//g" $input
		echo "Removed forward primer "$Forward9
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward10.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer10.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward10//g" $input
		echo "Removed forward primer "$Forward10
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward11.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward11//g" $input
		echo "Removed forward primer "$Forward11
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward12.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward12//g" $input
		echo "Removed forward primer "$Forward12
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward13.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward13//g" $input
		echo "Removed forward primer "$Forward13
	fi


#Reverse primers
	if [ -e "${USER_HOME}/.var_babitas/Reverse1.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer1.txt" ]; then
		echo "searching and deleting rev primer strings (rc) if they appear among the last 25 base pairs"
		#reverse complement of reverse primer
		Reverse1_rc=$(echo $Reverse1 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse1_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse1
	fi


	if [ -e "${USER_HOME}/.var_babitas/Reverse2.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer2.txt" ]; then
		#reverse complement of reverse primer
		Reverse2_rc=$(echo $Reverse2 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse2_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse2
	fi


	if [ -e "${USER_HOME}/.var_babitas/Reverse3.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer3.txt" ]; then
		#reverse complement of reverse primer
		Reverse3_rc=$(echo $Reverse3 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse3_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse3
	fi


	if [ -e "${USER_HOME}/.var_babitas/Reverse4.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer4.txt" ]; then
		#reverse complement of reverse primer
		Reverse4_rc=$(echo $Reverse4 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse4_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse4
	fi


	if [ -e "${USER_HOME}/.var_babitas/Reverse5.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer5.txt" ]; then
		#reverse complement of reverse primer
		Reverse5_rc=$(echo $Reverse5 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse5_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse5
	fi


	if [ -e "${USER_HOME}/.var_babitas/Reverse6.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer6.txt" ]; then
		#reverse complement of reverse primer
		Reverse6_rc=$(echo $Reverse6 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse6_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse6
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse7.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer7.txt" ]; then
		#reverse complement of reverse primer
		Reverse7_rc=$(echo $Reverse7 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse7_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse7
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse8.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer8.txt" ]; then
		#reverse complement of reverse primer
		Reverse8_rc=$(echo $Reverse8 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse8_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse8
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse9.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer9.txt" ]; then
		#reverse complement of reverse primer
		Reverse9_rc=$(echo $Reverse9 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse9_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse9
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse10.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer10.txt" ]; then
		#reverse complement of reverse primer
		Reverse10_rc=$(echo $Reverse10 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse10_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse10
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse11.txt" ]; then
		#reverse complement of reverse primer
		Reverse11_rc=$(echo $Reverse11 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse11_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse11
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse12.txt" ]; then
		#reverse complement of reverse primer
		Reverse12_rc=$(echo $Reverse12 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse12_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse12
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse13.txt" ]; then
		#reverse complement of reverse primer
		Reverse13_rc=$(echo $Reverse13 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse13_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse13
	fi


#ref
echo ""
echo "### Reference db chimera filtering"
echo "# db="$db
echo ""
echo "vsearch --uchime_ref $input --db $db --fasta_width 0 --chimeras ChimerasRef.fasta --nonchimeras Filtered_ChimerasDenovoRef.fasta --xsize"

	vsearch --uchime_ref $input --db $db --fasta_width 0 --chimeras ChimerasRef.fasta --nonchimeras Filtered_ChimerasRef.fasta --xsize
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Chimera_filtering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi


		
###Fasta to oneline for removing primer artifacts
	echo ""
	echo "### Removing primer artifacts"
	echo "# using 'sed --in-place /PRIMER/d'"
	echo ""

#Forward primers
	tr "\n" "@" < Filtered_ChimerasRef.fasta | sed -e 's/@>/\n>/g' > Chimera_filtered_oneline.fasta

	if [ -e "${USER_HOME}/.var_babitas/Forward1.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer1.txt" ]; then
	sed --in-place "/$Forward1/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward1
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward2.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer2.txt" ]; then
	sed --in-place "/$Forward2/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward2
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward3.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer3.txt" ]; then
	sed --in-place "/$Forward3/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward3
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward4.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer4.txt" ]; then
	sed --in-place "/$Forward4/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward4
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward5.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer5.txt" ]; then
	sed --in-place "/$Forward5/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward5
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward6.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer6.txt" ]; then
	sed --in-place "/$Forward6/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward6
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward7.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer7.txt" ]; then
	sed --in-place "/$Forward7/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward7
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward8.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer8.txt" ]; then
	sed --in-place "/$Forward8/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward8
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward9.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer9.txt" ]; then
	sed --in-place "/$Forward9/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward9
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward10.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer10.txt" ]; then
	sed --in-place "/$Forward10/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward10
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward11.txt" ]; then
	sed --in-place "/$Forward11/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward11
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward12.txt" ]; then
	sed --in-place "/$Forward12/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward12
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward13.txt" ]; then
	sed --in-place "/$Forward13/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward13
	fi

	
#Reverse primers
	if [ -e "${USER_HOME}/.var_babitas/Reverse1.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer1.txt" ]; then
	#make reverse complement to reverse primer
	Reverse1_rc=$(echo $Reverse1 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse1_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse1
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse2.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer2.txt" ]; then
	#make reverse complement to reverse primer
	Reverse2_rc=$(echo $Reverse2 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse2_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse2
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse3.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer3.txt" ]; then
	#make reverse complement to reverse primer
	Reverse3_rc=$(echo $Reverse3 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse3_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse3
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse4.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer4.txt" ]; then
	#make reverse complement to reverse primer
	Reverse4_rc=$(echo $Reverse4 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse4_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse4
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse5.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer5.txt" ]; then
	#make reverse complement to reverse primer
	Reverse5_rc=$(echo $Reverse5 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse5_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse5
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse6.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer6.txt" ]; then
	#make reverse complement to reverse primer
	Reverse6_rc=$(echo $Reverse6 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse6_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse6
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse7.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer7.txt" ]; then
	#make reverse complement to reverse primer
	Reverse7_rc=$(echo $Reverse7 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse7_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse7
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse8.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer8.txt" ]; then
	#make reverse complement to reverse primer
	Reverse8_rc=$(echo $Reverse8 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse8_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse8
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse9.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer9.txt" ]; then
	#make reverse complement to reverse primer
	Reverse9_rc=$(echo $Reverse9 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse9_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse9
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse10.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer10.txt" ]; then
	#make reverse complement to reverse primer
	Reverse10_rc=$(echo $Reverse10 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse10_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse10
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse11.txt" ]; then
	#make reverse complement to reverse primer
	Reverse11_rc=$(echo $Reverse11 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse11_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Reverse11
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse12.txt" ]; then
	#make reverse complement to reverse primer
	Reverse12_rc=$(echo $Reverse12 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse12_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Reverse12
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse13.txt" ]; then
	#make reverse complement to reverse primer
	Reverse13_rc=$(echo $Reverse13 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse13_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Reverse13
	fi

#Chimera_filtered_oneline.fasta to regular fasta
sed -e 's/@/\n/g' < Chimera_filtered_oneline.fasta | sed '/^\n*$/d' > Filtered_ChimerasRef_Multiprim.fasta

	if [ -e Chimera_filtered_oneline.fasta ]; then
	rm Chimera_filtered_oneline.fasta
	fi		
		
		
touch ${USER_HOME}/.var_babitas/Chimera_filtering_finished.txt
	
input_seqs=$(grep -c "^>" $input)
output_seqs=$(grep -c "^>" Filtered_ChimerasRef_Multiprim.fasta)
output_seqs2=$(grep -c "^>" Filtered_ChimerasRef.fasta)

echo ""
echo "Input fasta file = $input_seqs sequences"
echo "Output (Filtered_ChimerasRef_Multiprim.fasta) file = $output_seqs sequences"
echo "   (Filtered_ChimerasRef.fasta = $output_seqs2 sequences)"
echo ""
	
echo "##########################"
echo "DONE"
echo "############################"
echo "Primers cut"
echo "Chimera filtering finished"
echo "##############################"
echo "output = Filtered_ChimerasRef_Multiprim.fasta"
echo "################################"
echo "You may close this window now!"



##################################################
##################################################
############### CHIMERA FILTERING ################
##################################################
################ cut primer + mp #################
##################################################
##################################################
else if [ -e "${USER_HOME}/.var_babitas/cut_primers.txt" ] && [ -e "${USER_HOME}/.var_babitas/multiprimer.txt" ]; then

#Removing primers
	echo ""
	echo "### Cutting primers"
	echo "# using sed;"
	
	echo ""

#Forward primers
	if [ -e "${USER_HOME}/.var_babitas/Forward1.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer1.txt" ]; then
		echo "searching and deleting fwd primer strings if they appear among the first 25 base pairs"
		sed --in-place=.backup "s/^.\{0,25\}$Forward1//g" $input
		echo "Removed forward primer "$Forward1
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward2.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer2.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward2//g" $input
		echo "Removed forward primer "$Forward2
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward3.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer3.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward3//g" $input
		echo "Removed forward primer "$Forward3
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward4.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer4.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward4//g" $input
		echo "Removed forward primer "$Forward4
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward5.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer5.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward5//g" $input
		echo "Removed forward primer "$Forward5
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward6.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer6.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward6//g" $input
		echo "Removed forward primer "$Forward6
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward7.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer7.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward7//g" $input
		echo "Removed forward primer "$Forward7
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward8.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer8.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward8//g" $input
		echo "Removed forward primer "$Forward8
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward9.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer9.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward9//g" $input
		echo "Removed forward primer "$Forward9
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward10.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer10.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward10//g" $input
		echo "Removed forward primer "$Forward10
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward11.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward11//g" $input
		echo "Removed forward primer "$Forward11
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward12.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward12//g" $input
		echo "Removed forward primer "$Forward12
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward13.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward13//g" $input
		echo "Removed forward primer "$Forward13
	fi


#Reverse primers
	if [ -e "${USER_HOME}/.var_babitas/Reverse1.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer1.txt" ]; then
		echo "searching and deleting rev primer strings (rc) if they appear among the last 25 base pairs"
		#reverse complement of reverse primer
		Reverse1_rc=$(echo $Reverse1 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse1_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse1
	fi


	if [ -e "${USER_HOME}/.var_babitas/Reverse2.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer2.txt" ]; then
		#reverse complement of reverse primer
		Reverse2_rc=$(echo $Reverse2 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse2_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse2
	fi


	if [ -e "${USER_HOME}/.var_babitas/Reverse3.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer3.txt" ]; then
		#reverse complement of reverse primer
		Reverse3_rc=$(echo $Reverse3 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse3_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse3
	fi


	if [ -e "${USER_HOME}/.var_babitas/Reverse4.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer4.txt" ]; then
		#reverse complement of reverse primer
		Reverse4_rc=$(echo $Reverse4 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse4_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse4
	fi


	if [ -e "${USER_HOME}/.var_babitas/Reverse5.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer5.txt" ]; then
		#reverse complement of reverse primer
		Reverse5_rc=$(echo $Reverse5 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse5_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse5
	fi


	if [ -e "${USER_HOME}/.var_babitas/Reverse6.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer6.txt" ]; then
		#reverse complement of reverse primer
		Reverse6_rc=$(echo $Reverse6 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse6_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse6
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse7.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer7.txt" ]; then
		#reverse complement of reverse primer
		Reverse7_rc=$(echo $Reverse7 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse7_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse7
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse8.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer8.txt" ]; then
		#reverse complement of reverse primer
		Reverse8_rc=$(echo $Reverse8 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse8_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse8
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse9.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer9.txt" ]; then
		#reverse complement of reverse primer
		Reverse9_rc=$(echo $Reverse9 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse9_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse9
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse10.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer10.txt" ]; then
		#reverse complement of reverse primer
		Reverse10_rc=$(echo $Reverse10 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse10_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse10
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse11.txt" ]; then
		#reverse complement of reverse primer
		Reverse11_rc=$(echo $Reverse11 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse11_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse11
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse12.txt" ]; then
		#reverse complement of reverse primer
		Reverse12_rc=$(echo $Reverse12 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse12_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse12
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse13.txt" ]; then
		#reverse complement of reverse primer
		Reverse13_rc=$(echo $Reverse13 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse13_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse13
	fi



###Fasta to oneline for removing primer artifacts
	echo ""
	echo "### Removing primer artifacts"
	echo "# using 'sed --in-place /PRIMER/d'"
	echo ""

#Forward primers
	tr "\n" "@" < $input | sed -e 's/@>/\n>/g' > Chimera_filtered_oneline.fasta

	if [ -e "${USER_HOME}/.var_babitas/Forward1.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer1.txt" ]; then
	sed --in-place "/$Forward1/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward1
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward2.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer2.txt" ]; then
	sed --in-place "/$Forward2/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward2
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward3.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer3.txt" ]; then
	sed --in-place "/$Forward3/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward3
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward4.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer4.txt" ]; then
	sed --in-place "/$Forward4/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward4
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward5.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer5.txt" ]; then
	sed --in-place "/$Forward5/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward5
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward6.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer6.txt" ]; then
	sed --in-place "/$Forward6/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward6
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward7.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer7.txt" ]; then
	sed --in-place "/$Forward7/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward7
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward8.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer8.txt" ]; then
	sed --in-place "/$Forward8/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward8
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward9.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer9.txt" ]; then
	sed --in-place "/$Forward9/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward9
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward10.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer10.txt" ]; then
	sed --in-place "/$Forward10/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward10
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward11.txt" ]; then
	sed --in-place "/$Forward11/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward11
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward12.txt" ]; then
	sed --in-place "/$Forward12/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward12
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward13.txt" ]; then
	sed --in-place "/$Forward13/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward13
	fi

	
#Reverse primers
	if [ -e "${USER_HOME}/.var_babitas/Reverse1.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer1.txt" ]; then
	#make reverse complement to reverse primer
	Reverse1_rc=$(echo $Reverse1 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse1_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse1
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse2.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer2.txt" ]; then
	#make reverse complement to reverse primer
	Reverse2_rc=$(echo $Reverse2 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse2_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse2
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse3.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer3.txt" ]; then
	#make reverse complement to reverse primer
	Reverse3_rc=$(echo $Reverse3 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse3_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse3
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse4.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer4.txt" ]; then
	#make reverse complement to reverse primer
	Reverse4_rc=$(echo $Reverse4 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse4_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse4
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse5.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer5.txt" ]; then
	#make reverse complement to reverse primer
	Reverse5_rc=$(echo $Reverse5 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse5_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse5
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse6.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer6.txt" ]; then
	#make reverse complement to reverse primer
	Reverse6_rc=$(echo $Reverse6 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse6_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse6
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse7.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer7.txt" ]; then
	#make reverse complement to reverse primer
	Reverse7_rc=$(echo $Reverse7 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse7_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse7
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse8.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer8.txt" ]; then
	#make reverse complement to reverse primer
	Reverse8_rc=$(echo $Reverse8 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse8_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse8
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse9.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer9.txt" ]; then
	#make reverse complement to reverse primer
	Reverse9_rc=$(echo $Reverse9 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse9_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse9
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse10.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer10.txt" ]; then
	#make reverse complement to reverse primer
	Reverse10_rc=$(echo $Reverse10 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse10_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse10
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse11.txt" ]; then
	#make reverse complement to reverse primer
	Reverse11_rc=$(echo $Reverse11 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse11_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Reverse11
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse12.txt" ]; then
	#make reverse complement to reverse primer
	Reverse12_rc=$(echo $Reverse12 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse12_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Reverse12
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse13.txt" ]; then
	#make reverse complement to reverse primer
	Reverse13_rc=$(echo $Reverse13 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse13_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Reverse13
	fi

#Chimera_filtered_oneline.fasta to regular fasta
sed -e 's/@/\n/g' < Chimera_filtered_oneline.fasta | sed '/^\n*$/d' > Filtered_Multiprim.fasta

	if [ -e Chimera_filtered_oneline.fasta ]; then
	rm Chimera_filtered_oneline.fasta
	fi


touch ${USER_HOME}/.var_babitas/Chimera_filtering_finished.txt
		
input_seqs=$(grep -c "^>" $input)
output_seqs=$(grep -c "^>" Filtered_Multiprim.fasta)

echo ""
echo "Input fasta file = $input_seqs sequences"
echo "Output (Filtered_Multiprim.fasta) file = $output_seqs sequences"
echo ""

echo "##########################"
echo "DONE"
echo "############################"
echo "Primers cut"
echo "Multiprimer artifacts filtered"
echo "##############################"
echo "output = Filtered_Multiprim.fasta"
echo "################################"
echo "You may close this window now!"




##################################################
##################################################
############### CHIMERA FILTERING ################
##################################################
################ cut primer + ref #################
##################################################
##################################################
else if [ -e "${USER_HOME}/.var_babitas/cut_primers.txt" ] && [ -e "${USER_HOME}/.var_babitas/reference_db.txt" ]; then

#Removing primers
	echo ""
	echo "### Cutting primers"
	echo "# using sed;"
	
	echo ""

#Forward primers
	if [ -e "${USER_HOME}/.var_babitas/Forward1.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer1.txt" ]; then
		echo "searching and deleting fwd primer strings if they appear among the first 25 base pairs"
		sed --in-place=.backup "s/^.\{0,25\}$Forward1//g" $input
		echo "Removed forward primer "$Forward1
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward2.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer2.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward2//g" $input
		echo "Removed forward primer "$Forward2
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward3.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer3.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward3//g" $input
		echo "Removed forward primer "$Forward3
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward4.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer4.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward4//g" $input
		echo "Removed forward primer "$Forward4
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward5.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer5.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward5//g" $input
		echo "Removed forward primer "$Forward5
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward6.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer6.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward6//g" $input
		echo "Removed forward primer "$Forward6
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward7.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer7.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward7//g" $input
		echo "Removed forward primer "$Forward7
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward8.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer8.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward8//g" $input
		echo "Removed forward primer "$Forward8
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward9.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer9.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward9//g" $input
		echo "Removed forward primer "$Forward9
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward10.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer10.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward10//g" $input
		echo "Removed forward primer "$Forward10
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward11.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward11//g" $input
		echo "Removed forward primer "$Forward11
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward12.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward12//g" $input
		echo "Removed forward primer "$Forward12
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward13.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward13//g" $input
		echo "Removed forward primer "$Forward13
	fi


#Reverse primers
	if [ -e "${USER_HOME}/.var_babitas/Reverse1.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer1.txt" ]; then
		echo "searching and deleting rev primer strings (rc) if they appear among the last 25 base pairs"
		#reverse complement of reverse primer
		Reverse1_rc=$(echo $Reverse1 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse1_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse1
	fi


	if [ -e "${USER_HOME}/.var_babitas/Reverse2.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer2.txt" ]; then
		#reverse complement of reverse primer
		Reverse2_rc=$(echo $Reverse2 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse2_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse2
	fi


	if [ -e "${USER_HOME}/.var_babitas/Reverse3.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer3.txt" ]; then
		#reverse complement of reverse primer
		Reverse3_rc=$(echo $Reverse3 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse3_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse3
	fi


	if [ -e "${USER_HOME}/.var_babitas/Reverse4.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer4.txt" ]; then
		#reverse complement of reverse primer
		Reverse4_rc=$(echo $Reverse4 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse4_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse4
	fi


	if [ -e "${USER_HOME}/.var_babitas/Reverse5.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer5.txt" ]; then
		#reverse complement of reverse primer
		Reverse5_rc=$(echo $Reverse5 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse5_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse5
	fi


	if [ -e "${USER_HOME}/.var_babitas/Reverse6.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer6.txt" ]; then
		#reverse complement of reverse primer
		Reverse6_rc=$(echo $Reverse6 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse6_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse6
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse7.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer7.txt" ]; then
		#reverse complement of reverse primer
		Reverse7_rc=$(echo $Reverse7 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse7_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse7
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse8.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer8.txt" ]; then
		#reverse complement of reverse primer
		Reverse8_rc=$(echo $Reverse8 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse8_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse8
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse9.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer9.txt" ]; then
		#reverse complement of reverse primer
		Reverse9_rc=$(echo $Reverse9 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse9_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse9
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse10.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer10.txt" ]; then
		#reverse complement of reverse primer
		Reverse10_rc=$(echo $Reverse10 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse10_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse10
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse11.txt" ]; then
		#reverse complement of reverse primer
		Reverse11_rc=$(echo $Reverse11 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse11_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse11
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse12.txt" ]; then
		#reverse complement of reverse primer
		Reverse12_rc=$(echo $Reverse12 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse12_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse12
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse13.txt" ]; then
		#reverse complement of reverse primer
		Reverse13_rc=$(echo $Reverse13 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse13_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse13
	fi


#ref
echo ""
echo "### Reference db chimera filtering"
echo "# db="$db
echo ""
echo "vsearch --uchime_ref $input --db $db --fasta_width 0 --chimeras ChimerasRef.fasta --nonchimeras Filtered_ChimerasDenovoRef.fasta --xsize"

	vsearch --uchime_ref $input --db $db --fasta_width 0 --chimeras ChimerasRef.fasta --nonchimeras Filtered_ChimerasRef.fasta --xsize
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Chimera_filtering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi
		

touch ${USER_HOME}/.var_babitas/Chimera_filtering_finished.txt
		
input_seqs=$(grep -c "^>" $input)
output_seqs=$(grep -c "^>" Filtered_ChimerasRef.fasta)

echo ""
echo "Input fasta file = $input_seqs sequences"
echo "Output (Filtered_ChimerasRef.fasta) file = $output_seqs sequences"
echo ""

echo "##########################"
echo "DONE"
echo "############################"
echo "Primers cut"
echo "Chimera filtering finished"
echo "##############################"
echo "output = Filtered_ChimerasRef.fasta"
echo "################################"
echo "You may close this window now!"

##################################################
##################################################
############### CHIMERA FILTERING ################
##################################################
############## cut primer + denovo ###############
##################################################
##################################################
else if [ -e "${USER_HOME}/.var_babitas/cut_primers.txt" ] && [ -e "${USER_HOME}/.var_babitas/denovo.txt" ]; then

#Removing primers
	echo ""
	echo "### Cutting primers"
	echo "# using sed;"
	
	echo ""

#Forward primers
	if [ -e "${USER_HOME}/.var_babitas/Forward1.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer1.txt" ]; then
		echo "searching and deleting fwd primer strings if they appear among the first 25 base pairs"
		sed --in-place=.backup "s/^.\{0,25\}$Forward1//g" $input
		echo "Removed forward primer "$Forward1
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward2.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer2.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward2//g" $input
		echo "Removed forward primer "$Forward2
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward3.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer3.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward3//g" $input
		echo "Removed forward primer "$Forward3
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward4.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer4.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward4//g" $input
		echo "Removed forward primer "$Forward4
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward5.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer5.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward5//g" $input
		echo "Removed forward primer "$Forward5
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward6.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer6.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward6//g" $input
		echo "Removed forward primer "$Forward6
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward7.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer7.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward7//g" $input
		echo "Removed forward primer "$Forward7
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward8.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer8.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward8//g" $input
		echo "Removed forward primer "$Forward8
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward9.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer9.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward9//g" $input
		echo "Removed forward primer "$Forward9
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward10.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer10.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward10//g" $input
		echo "Removed forward primer "$Forward10
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward11.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward11//g" $input
		echo "Removed forward primer "$Forward11
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward12.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward12//g" $input
		echo "Removed forward primer "$Forward12
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward13.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward13//g" $input
		echo "Removed forward primer "$Forward13
	fi


#Reverse primers
	if [ -e "${USER_HOME}/.var_babitas/Reverse1.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer1.txt" ]; then
		echo "searching and deleting rev primer strings (rc) if they appear among the last 25 base pairs"
		#reverse complement of reverse primer
		Reverse1_rc=$(echo $Reverse1 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse1_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse1
	fi


	if [ -e "${USER_HOME}/.var_babitas/Reverse2.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer2.txt" ]; then
		#reverse complement of reverse primer
		Reverse2_rc=$(echo $Reverse2 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse2_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse2
	fi


	if [ -e "${USER_HOME}/.var_babitas/Reverse3.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer3.txt" ]; then
		#reverse complement of reverse primer
		Reverse3_rc=$(echo $Reverse3 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse3_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse3
	fi


	if [ -e "${USER_HOME}/.var_babitas/Reverse4.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer4.txt" ]; then
		#reverse complement of reverse primer
		Reverse4_rc=$(echo $Reverse4 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse4_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse4
	fi


	if [ -e "${USER_HOME}/.var_babitas/Reverse5.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer5.txt" ]; then
		#reverse complement of reverse primer
		Reverse5_rc=$(echo $Reverse5 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse5_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse5
	fi


	if [ -e "${USER_HOME}/.var_babitas/Reverse6.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer6.txt" ]; then
		#reverse complement of reverse primer
		Reverse6_rc=$(echo $Reverse6 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse6_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse6
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse7.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer7.txt" ]; then
		#reverse complement of reverse primer
		Reverse7_rc=$(echo $Reverse7 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse7_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse7
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse8.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer8.txt" ]; then
		#reverse complement of reverse primer
		Reverse8_rc=$(echo $Reverse8 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse8_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse8
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse9.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer9.txt" ]; then
		#reverse complement of reverse primer
		Reverse9_rc=$(echo $Reverse9 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse9_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse9
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse10.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer10.txt" ]; then
		#reverse complement of reverse primer
		Reverse10_rc=$(echo $Reverse10 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse10_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse10
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse11.txt" ]; then
		#reverse complement of reverse primer
		Reverse11_rc=$(echo $Reverse11 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse11_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse11
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse12.txt" ]; then
		#reverse complement of reverse primer
		Reverse12_rc=$(echo $Reverse12 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse12_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse12
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse13.txt" ]; then
		#reverse complement of reverse primer
		Reverse13_rc=$(echo $Reverse13 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse13_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse13
	fi


#devovo
echo ""
echo "### Denovo + reference database chimera filtering ###"
echo ""

echo "# Abundance annotation for de novo chimera filtering"
echo "# id="$id
echo "vsearch --cluster_fast $input --id $id --centroids centroids.fasta --sizeout"

vsearch --cluster_fast $input --id $id --centroids centroids.fasta --sizeout
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Chimera_filtering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi

echo ""
echo "# Sort by size"
echo "vsearch --sortbysize centroids.fasta --output sortbysize.fasta"

vsearch --sortbysize centroids.fasta --output sortbysize.fasta
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Chimera_filtering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi

echo ""
echo "# De novo chimera detection"
echo "# abskew="$abskew
echo "vsearch --uchime_denovo sortbysize.fasta --abskew $abskew --chimeras chimeras_denovo.fasta --nonchimeras nonchimeras_denovo.fasta"

vsearch --uchime_denovo sortbysize.fasta --abskew $abskew --chimeras chimeras_denovo.fasta --nonchimeras nonchimeras_denovo.fasta
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Chimera_filtering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi


	#vsearch DECLUSTER
	echo "# vsearch DECLUSTER"
	echo "vsearch --usearch_global $input --db nonchimeras_denovo.fasta --id $id --fasta_width 0 --matched Filtered_ChimerasDenovo.fasta --notmatched ChimerasDenovo.fasta"

	vsearch --usearch_global $input --db nonchimeras_denovo.fasta --id $id --fasta_width 0 --matched Filtered_ChimerasDenovo.fasta --notmatched ChimerasDenovo.fasta
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Chimera_filtering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi




touch ${USER_HOME}/.var_babitas/Chimera_filtering_finished.txt
	
input_seqs=$(grep -c "^>" $input)
output_seqs=$(grep -c "^>" Filtered_ChimerasDenovo.fasta)

echo ""
echo "Input fasta file = $input_seqs sequences"
echo "Output (Filtered_ChimerasDenovo.fasta) file = $output_seqs sequences"
echo ""

echo "##########################"
echo "DONE"
echo "############################"
echo "Primers cut"
echo "Chimera filtering finished"
echo "##############################"
echo "output = Filtered_ChimerasDenovo.fasta"
echo "################################"
echo "You may close this window now!"

##################################################
##################################################
############### CHIMERA FILTERING ################
##################################################
################## denovo + ref ##################
##################################################
##################################################
else if [ -e "${USER_HOME}/.var_babitas/denovo.txt" ] && [ -e "${USER_HOME}/.var_babitas/reference_db.txt" ]; then

#denovo
echo ""
echo "### Denovo + reference database chimera filtering ###"
echo ""

echo "# Abundance annotation for de novo chimera filtering"
echo "# id="$id
echo "vsearch --cluster_fast $input --id $id --centroids centroids.fasta --sizeout"

vsearch --cluster_fast $input --id $id --centroids centroids.fasta --sizeout
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Chimera_filtering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi

echo ""
echo "# Sort by size"
echo "vsearch --sortbysize centroids.fasta --output sortbysize.fasta"

vsearch --sortbysize centroids.fasta --output sortbysize.fasta
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Chimera_filtering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi

echo ""
echo "# De novo chimera detection"
echo "# abskew="$abskew
echo "vsearch --uchime_denovo sortbysize.fasta --abskew $abskew --chimeras chimeras_denovo.fasta --nonchimeras nonchimeras_denovo.fasta"

vsearch --uchime_denovo sortbysize.fasta --abskew $abskew --chimeras chimeras_denovo.fasta --nonchimeras nonchimeras_denovo.fasta
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Chimera_filtering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi


	#vsearch DECLUSTER
	echo "# vsearch DECLUSTER"
	echo "vsearch --usearch_global $input --db nonchimeras_denovo.fasta --id $id --fasta_width 0 --matched Filtered_ChimerasDenovo.fasta --notmatched ChimerasDenovo.fasta"

	vsearch --usearch_global $input --db nonchimeras_denovo.fasta --id $id --fasta_width 0 --matched Filtered_ChimerasDenovo.fasta --notmatched ChimerasDenovo.fasta
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Chimera_filtering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi


echo ""
echo "### Reference db chimera filtering"
echo "# db="$db
echo ""
echo "vsearch --uchime_ref Filtered_ChimerasDenovo.fasta --db $db --fasta_width 0 --chimeras ChimerasRef.fasta --nonchimeras Filtered_ChimerasDenovoRef.fasta --xsize"

	vsearch --uchime_ref Filtered_ChimerasDenovo.fasta --db $db --fasta_width 0 --chimeras ChimerasRef.fasta --nonchimeras Filtered_ChimerasDenovoRef.fasta --xsize
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Chimera_filtering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi





touch ${USER_HOME}/.var_babitas/Chimera_filtering_finished.txt

input_seqs=$(grep -c "^>" $input)
output_seqs=$(grep -c "^>" Filtered_ChimerasDenovoRef.fasta)
output_seqs2=$(grep -c "^>" Filtered_ChimerasDenovo.fasta)


echo ""
echo "Input fasta file = $input_seqs sequences"
echo "Output (Filtered_ChimerasDenovoRef.fasta) file = $output_seqs sequences"
echo "   (Filtered_ChimerasDenovo.fasta = $output_seqs2 sequences)"
echo ""

echo "##########################"
echo "DONE"
echo "############################"
echo "Chimera filtering finished"
echo "##############################"
echo "output = Filtered_ChimerasDenovoRef.fasta"
echo "################################"
echo "You may close this window now!"




##################################################
##################################################
############### CHIMERA FILTERING ################
##################################################
############### denovo + multiprim ###############
##################################################
##################################################
else if [ -e "${USER_HOME}/.var_babitas/denovo.txt" ] && [ -e "${USER_HOME}/.var_babitas/multiprimer.txt" ]; then

echo ""
echo "### Denovo chimera filtering + remove primer artefacts ###"
echo ""

echo "# Abundance annotation for de novo chimera filtering"
echo "# id="$id
echo "vsearch --cluster_fast $input --id $id --centroids centroids.fasta --sizeout"

vsearch --cluster_fast $input --id $id --centroids centroids.fasta --sizeout
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Chimera_filtering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi

echo ""
echo "# Sort by size"
echo "vsearch --sortbysize centroids.fasta --output sortbysize.fasta"

vsearch --sortbysize centroids.fasta --output sortbysize.fasta
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Chimera_filtering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi

echo ""
echo "# De novo chimera detection"
echo "# abskew="$abskew
echo "vsearch --uchime_denovo sortbysize.fasta --abskew $abskew --chimeras chimeras_denovo.fasta --nonchimeras nonchimeras_denovo.fasta"

vsearch --uchime_denovo sortbysize.fasta --abskew $abskew --chimeras chimeras_denovo.fasta --nonchimeras nonchimeras_denovo.fasta
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Chimera_filtering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi


	#vsearch DECLUSTER
	echo "# vsearch DECLUSTER"
	echo "vsearch --usearch_global $input --db nonchimeras_denovo.fasta --id $id --fasta_width 0 --matched Filtered_ChimerasDenovo.fasta --notmatched ChimerasDenovo.fasta"

	vsearch --usearch_global $input --db nonchimeras_denovo.fasta --id $id --fasta_width 0 --matched Filtered_ChimerasDenovo.fasta --notmatched ChimerasDenovo.fasta
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Chimera_filtering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi



###Fasta to oneline for removing primer artifacts
	echo ""
	echo "### Removing primer artifacts"
	echo "# using 'sed --in-place /PRIMER/d'"
	echo ""

#Forward primers
	tr "\n" "@" < Filtered_ChimerasDenovo.fasta | sed -e 's/@>/\n>/g' > Chimera_filtered_oneline.fasta

	if [ -e "${USER_HOME}/.var_babitas/Forward1.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer1.txt" ]; then
	sed --in-place "/$Forward1/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward1
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward2.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer2.txt" ]; then
	sed --in-place "/$Forward2/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward2
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward3.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer3.txt" ]; then
	sed --in-place "/$Forward3/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward3
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward4.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer4.txt" ]; then
	sed --in-place "/$Forward4/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward4
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward5.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer5.txt" ]; then
	sed --in-place "/$Forward5/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward5
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward6.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer6.txt" ]; then
	sed --in-place "/$Forward6/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward6
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward7.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer7.txt" ]; then
	sed --in-place "/$Forward7/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward7
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward8.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer8.txt" ]; then
	sed --in-place "/$Forward8/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward8
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward9.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer9.txt" ]; then
	sed --in-place "/$Forward9/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward9
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward10.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer10.txt" ]; then
	sed --in-place "/$Forward10/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward10
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward11.txt" ]; then
	sed --in-place "/$Forward11/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward11
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward12.txt" ]; then
	sed --in-place "/$Forward12/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward12
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward13.txt" ]; then
	sed --in-place "/$Forward13/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward13
	fi

	
#Reverse primers
	if [ -e "${USER_HOME}/.var_babitas/Reverse1.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer1.txt" ]; then
	#make reverse complement to reverse primer
	Reverse1_rc=$(echo $Reverse1 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse1_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse1
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse2.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer2.txt" ]; then
	#make reverse complement to reverse primer
	Reverse2_rc=$(echo $Reverse2 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse2_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse2
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse3.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer3.txt" ]; then
	#make reverse complement to reverse primer
	Reverse3_rc=$(echo $Reverse3 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse3_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse3
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse4.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer4.txt" ]; then
	#make reverse complement to reverse primer
	Reverse4_rc=$(echo $Reverse4 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse4_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse4
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse5.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer5.txt" ]; then
	#make reverse complement to reverse primer
	Reverse5_rc=$(echo $Reverse5 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse5_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse5
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse6.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer6.txt" ]; then
	#make reverse complement to reverse primer
	Reverse6_rc=$(echo $Reverse6 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse6_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse6
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse7.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer7.txt" ]; then
	#make reverse complement to reverse primer
	Reverse7_rc=$(echo $Reverse7 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse7_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse7
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse8.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer8.txt" ]; then
	#make reverse complement to reverse primer
	Reverse8_rc=$(echo $Reverse8 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse8_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse8
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse9.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer9.txt" ]; then
	#make reverse complement to reverse primer
	Reverse9_rc=$(echo $Reverse9 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse9_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse9
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse10.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer10.txt" ]; then
	#make reverse complement to reverse primer
	Reverse10_rc=$(echo $Reverse10 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse10_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse10
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse11.txt" ]; then
	#make reverse complement to reverse primer
	Reverse11_rc=$(echo $Reverse11 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse11_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Reverse11
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse12.txt" ]; then
	#make reverse complement to reverse primer
	Reverse12_rc=$(echo $Reverse12 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse12_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Reverse12
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse13.txt" ]; then
	#make reverse complement to reverse primer
	Reverse13_rc=$(echo $Reverse13 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse13_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Reverse13
	fi

#Chimera_filtered_oneline.fasta to regular fasta
sed -e 's/@/\n/g' < Chimera_filtered_oneline.fasta | sed '/^\n*$/d' > Filtered_ChimerasDenovo_Multiprim.fasta

	if [ -e Chimera_filtered_oneline.fasta ]; then
	rm Chimera_filtered_oneline.fasta
	fi



touch ${USER_HOME}/.var_babitas/Chimera_filtering_finished.txt

input_seqs=$(grep -c "^>" $input)
output_seqs=$(grep -c "^>" Filtered_ChimerasDenovo_Multiprim.fasta)
output_seqs2=$(grep -c "^>" Filtered_ChimerasDenovo.fasta)


echo ""
echo "Input fasta file = $input_seqs sequences"
echo "Output (Filtered_ChimerasDenovo_Multiprim.fasta) file = $output_seqs sequences"
echo "   (Filtered_ChimerasDenovo.fasta = $output_seqs2 sequences)"
echo ""

echo "##########################"
echo "DONE"
echo "############################"
echo "Chimera filtering finished"
echo "##############################"
echo "output = Filtered_ChimerasDenovo_Multiprim.fasta"
echo "################################"
echo "You may close this window now!"


##################################################
##################################################
############### CHIMERA FILTERING ################
##################################################
################# ref + multiprim ################
##################################################
##################################################
else if [ -e "${USER_HOME}/.var_babitas/reference_db.txt" ] && [ -e "${USER_HOME}/.var_babitas/multiprimer.txt" ]; then
echo "### Reference database chimera filtering + remove primer artefacts ###"
echo ""
echo "### Reference db chimera filtering"
echo "# db="$db
echo ""
echo "vsearch --uchime_ref $input --db $db --fasta_width 0 --chimeras ChimerasRef.fasta --nonchimeras Filtered_ChimerasRef.fasta --xsize"

	vsearch --uchime_ref $input --db $db --fasta_width 0 --chimeras ChimerasRef.fasta --nonchimeras Filtered_ChimerasRef.fasta --xsize
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Chimera_filtering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi



###Fasta to oneline for removing primer artifacts
	echo ""
	echo "### Removing primer artifacts"
	echo "# using 'sed --in-place /PRIMER/d'"
	echo ""

#Forward primers
	tr "\n" "@" < Filtered_ChimerasRef.fasta | sed -e 's/@>/\n>/g' > Chimera_filtered_oneline.fasta

	if [ -e "${USER_HOME}/.var_babitas/Forward1.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer1.txt" ]; then
	sed --in-place "/$Forward1/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward1
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward2.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer2.txt" ]; then
	sed --in-place "/$Forward2/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward2
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward3.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer3.txt" ]; then
	sed --in-place "/$Forward3/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward3
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward4.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer4.txt" ]; then
	sed --in-place "/$Forward4/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward4
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward5.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer5.txt" ]; then
	sed --in-place "/$Forward5/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward5
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward6.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer6.txt" ]; then
	sed --in-place "/$Forward6/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward6
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward7.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer7.txt" ]; then
	sed --in-place "/$Forward7/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward7
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward8.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer8.txt" ]; then
	sed --in-place "/$Forward8/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward8
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward9.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer9.txt" ]; then
	sed --in-place "/$Forward9/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward9
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward10.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer10.txt" ]; then
	sed --in-place "/$Forward10/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward10
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward11.txt" ]; then
	sed --in-place "/$Forward11/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward11
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward12.txt" ]; then
	sed --in-place "/$Forward12/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward12
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward13.txt" ]; then
	sed --in-place "/$Forward13/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward13
	fi

	
#Reverse primers
	if [ -e "${USER_HOME}/.var_babitas/Reverse1.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer1.txt" ]; then
	#make reverse complement to reverse primer
	Reverse1_rc=$(echo $Reverse1 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse1_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse1
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse2.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer2.txt" ]; then
	#make reverse complement to reverse primer
	Reverse2_rc=$(echo $Reverse2 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse2_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse2
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse3.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer3.txt" ]; then
	#make reverse complement to reverse primer
	Reverse3_rc=$(echo $Reverse3 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse3_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse3
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse4.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer4.txt" ]; then
	#make reverse complement to reverse primer
	Reverse4_rc=$(echo $Reverse4 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse4_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse4
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse5.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer5.txt" ]; then
	#make reverse complement to reverse primer
	Reverse5_rc=$(echo $Reverse5 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse5_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse5
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse6.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer6.txt" ]; then
	#make reverse complement to reverse primer
	Reverse6_rc=$(echo $Reverse6 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse6_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse6
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse7.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer7.txt" ]; then
	#make reverse complement to reverse primer
	Reverse7_rc=$(echo $Reverse7 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse7_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse7
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse8.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer8.txt" ]; then
	#make reverse complement to reverse primer
	Reverse8_rc=$(echo $Reverse8 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse8_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse8
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse9.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer9.txt" ]; then
	#make reverse complement to reverse primer
	Reverse9_rc=$(echo $Reverse9 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse9_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse9
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse10.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer10.txt" ]; then
	#make reverse complement to reverse primer
	Reverse10_rc=$(echo $Reverse10 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse10_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse10
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse11.txt" ]; then
	#make reverse complement to reverse primer
	Reverse11_rc=$(echo $Reverse11 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse11_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Reverse11
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse12.txt" ]; then
	#make reverse complement to reverse primer
	Reverse12_rc=$(echo $Reverse12 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse12_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Reverse12
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse13.txt" ]; then
	#make reverse complement to reverse primer
	Reverse13_rc=$(echo $Reverse13 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse13_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Reverse13
	fi

#Chimera_filtered_oneline.fasta to regular fasta
sed -e 's/@/\n/g' < Chimera_filtered_oneline.fasta | sed '/^\n*$/d' > Filtered_ChimerasRef_Multiprim.fasta

	if [ -e Chimera_filtered_oneline.fasta ]; then
	rm Chimera_filtered_oneline.fasta
	fi


touch ${USER_HOME}/.var_babitas/Chimera_filtering_finished.txt

input_seqs=$(grep -c "^>" $input)
output_seqs=$(grep -c "^>" Filtered_ChimerasRef_Multiprim.fasta)
output_seqs2=$(grep -c "^>" Filtered_ChimerasRef.fasta)


echo ""
echo "Input fasta file = $input_seqs sequences"
echo "Output (Filtered_ChimerasRef_Multiprim.fasta) file = $output_seqs sequences"
echo "   (Filtered_ChimerasRef.fasta = $output_seqs2 sequences)"
echo ""

echo "##########################"
echo "DONE"
echo "############################"
echo "Chimera filtering finished"
echo "##############################"
echo "output = Filtered_ChimerasRef_Multiprim.fasta"
echo "################################"
echo "You may close this window now!"


##################################################
##################################################
############### CHIMERA FILTERING ################
##################################################
##################### de novo ####################
##################################################
##################################################
else if [ -e "${USER_HOME}/.var_babitas/denovo.txt" ]; then

echo ""
echo "### Denovo chimera filtering ###"
echo ""

echo "# Abundance annotation for de novo chimera filtering"
echo "# id="$id
echo "vsearch --cluster_fast $input --id $id --centroids centroids.fasta --sizeout"

vsearch --cluster_fast $input --id $id --centroids centroids.fasta --sizeout
	if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Chimera_filtering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
	fi

echo ""
echo "# Sort by size"
echo "vsearch --sortbysize centroids.fasta --output sortbysize.fasta"

vsearch --sortbysize centroids.fasta --output sortbysize.fasta
	if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Chimera_filtering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
	fi

echo ""
echo "# De novo chimera detection"
echo "# abskew="$abskew
echo "vsearch --uchime_denovo sortbysize.fasta --abskew $abskew --chimeras chimeras_denovo.fasta --nonchimeras nonchimeras_denovo.fasta"

vsearch --uchime_denovo sortbysize.fasta --abskew $abskew --chimeras chimeras_denovo.fasta --nonchimeras nonchimeras_denovo.fasta
	if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Chimera_filtering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
	fi


	#vsearch DECLUSTER
	echo "# vsearch DECLUSTER"
	echo "vsearch --usearch_global $input --db nonchimeras_denovo.fasta --id $id --fasta_width 0 --matched Filtered_ChimerasDenovo.fasta --notmatched ChimerasDenovo.fasta"

	vsearch --usearch_global $input --db nonchimeras_denovo.fasta --id $id --fasta_width 0 --matched Filtered_ChimerasDenovo.fasta --notmatched ChimerasDenovo.fasta
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Chimera_filtering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi


	

touch ${USER_HOME}/.var_babitas/Chimera_filtering_finished.txt

input_seqs=$(grep -c "^>" $input)
output_seqs=$(grep -c "^>" Filtered_ChimerasDenovo.fasta)

echo ""
echo "Input fasta file = $input_seqs sequences"
echo "Output (Filtered_ChimerasDenovo.fasta) file = $output_seqs sequences"
echo ""

echo "##########################"
echo "DONE"
echo "############################"
echo "Chimera filtering finished"
echo "##############################"
echo "output = Filtered_ChimerasDenovo.fasta"
echo "################################"
echo "You may close this window now!"



##################################################
##################################################
############### CHIMERA FILTERING ################
##################################################
############### reference database ###############
##################################################
##################################################
else if [ -e "${USER_HOME}/.var_babitas/reference_db.txt" ]; then

echo ""
echo "### Reference db chimera filtering"
echo "# db="$db
echo ""
echo "vsearch --uchime_ref $input --db $db --fasta_width 0 --chimeras ChimerasRef.fasta --nonchimeras Filtered_ChimerasRef.fasta --xsize"

	vsearch --uchime_ref $input --db $db --fasta_width 0 --chimeras ChimerasRef.fasta --nonchimeras Filtered_ChimerasRef.fasta --xsize
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Chimera_filtering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi


touch ${USER_HOME}/.var_babitas/Chimera_filtering_finished.txt

input_seqs=$(grep -c "^>" $input)
output_seqs=$(grep -c "^>" Filtered_ChimerasRef.fasta)

echo ""
echo "Input fasta file = $input_seqs sequences"
echo "Output (Filtered_ChimerasRef.fasta) file = $output_seqs sequences"
echo ""

echo "##########################"
echo "DONE"
echo "############################"
echo "Chimera filtering finished"
echo "##############################"
echo "output = Filtered_ChimerasRef.fasta"
echo "################################"
echo "You may close this window now!"


##################################################
##################################################
############### CHIMERA FILTERING ################
##################################################
################## multiprimer ###################
##################################################
##################################################
else if [ -e "${USER_HOME}/.var_babitas/multiprimer.txt" ]; then

###Fasta to oneline for removing primer artifacts
	echo ""
	echo "### Removing primer artifacts"
	echo "# using 'sed --in-place /PRIMER/d'"
	echo ""

#Forward primers
	tr "\n" "@" < $input | sed -e 's/@>/\n>/g' > Chimera_filtered_oneline.fasta

	if [ -e "${USER_HOME}/.var_babitas/Forward1.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer1.txt" ]; then
	sed --in-place "/$Forward1/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward1
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward2.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer2.txt" ]; then
	sed --in-place "/$Forward2/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward2
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward3.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer3.txt" ]; then
	sed --in-place "/$Forward3/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward3
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward4.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer4.txt" ]; then
	sed --in-place "/$Forward4/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward4
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward5.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer5.txt" ]; then
	sed --in-place "/$Forward5/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward5
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward6.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer6.txt" ]; then
	sed --in-place "/$Forward6/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward6
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward7.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer7.txt" ]; then
	sed --in-place "/$Forward7/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward7
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward8.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer8.txt" ]; then
	sed --in-place "/$Forward8/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward8
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward9.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer9.txt" ]; then
	sed --in-place "/$Forward9/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward9
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward10.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer10.txt" ]; then
	sed --in-place "/$Forward10/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward10
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward11.txt" ]; then
	sed --in-place "/$Forward11/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward11
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward12.txt" ]; then
	sed --in-place "/$Forward12/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward12
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward13.txt" ]; then
	sed --in-place "/$Forward13/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Forward13
	fi

	
#Reverse primers
	if [ -e "${USER_HOME}/.var_babitas/Reverse1.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer1.txt" ]; then
	#make reverse complement to reverse primer
	Reverse1_rc=$(echo $Reverse1 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse1_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse1
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse2.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer2.txt" ]; then
	#make reverse complement to reverse primer
	Reverse2_rc=$(echo $Reverse2 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse2_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse2
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse3.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer3.txt" ]; then
	#make reverse complement to reverse primer
	Reverse3_rc=$(echo $Reverse3 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse3_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse3
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse4.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer4.txt" ]; then
	#make reverse complement to reverse primer
	Reverse4_rc=$(echo $Reverse4 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse4_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse4
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse5.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer5.txt" ]; then
	#make reverse complement to reverse primer
	Reverse5_rc=$(echo $Reverse5 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse5_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse5
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse6.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer6.txt" ]; then
	#make reverse complement to reverse primer
	Reverse6_rc=$(echo $Reverse6 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse6_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse6
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse7.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer7.txt" ]; then
	#make reverse complement to reverse primer
	Reverse7_rc=$(echo $Reverse7 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse7_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse7
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse8.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer8.txt" ]; then
	#make reverse complement to reverse primer
	Reverse8_rc=$(echo $Reverse8 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse8_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse8
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse9.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer9.txt" ]; then
	#make reverse complement to reverse primer
	Reverse9_rc=$(echo $Reverse9 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse9_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse9
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse10.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer10.txt" ]; then
	#make reverse complement to reverse primer
	Reverse10_rc=$(echo $Reverse10 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse10_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing rev primer "$Reverse10
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse11.txt" ]; then
	#make reverse complement to reverse primer
	Reverse11_rc=$(echo $Reverse11 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse11_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Reverse11
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse12.txt" ]; then
	#make reverse complement to reverse primer
	Reverse12_rc=$(echo $Reverse12 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse12_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Reverse12
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse13.txt" ]; then
	#make reverse complement to reverse primer
	Reverse13_rc=$(echo $Reverse13 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
	sed --in-place "/$Reverse13_rc/d" Chimera_filtered_oneline.fasta
	echo "Removed sequences containing fwd primer "$Reverse13
	fi

#Chimera_filtered_oneline.fasta to regular fasta
sed -e 's/@/\n/g' < Chimera_filtered_oneline.fasta | sed '/^\n*$/d' > Filtered_Multiprim.fasta

	if [ -e Chimera_filtered_oneline.fasta ]; then
	rm Chimera_filtered_oneline.fasta
	fi

touch ${USER_HOME}/.var_babitas/Chimera_filtering_finished.txt

input_seqs=$(grep -c "^>" $input)
output_seqs=$(grep -c "^>" Filtered_Multiprim.fasta)

echo ""
echo "Input fasta file = $input_seqs sequences"
echo "Output (Filtered_Multiprim.fasta) file = $output_seqs sequences"
echo ""
echo "##########################"
echo "DONE"
echo "############################"
echo "Chimera filtering finished"
echo "##############################"
echo "output = Filtered_Multiprim.fasta"
echo "################################"
echo "You may close this window now!"



##################################################
##################################################
################## Cut primers ###################
##################################################
##################################################
else if [ -e "${USER_HOME}/.var_babitas/cut_primers.txt" ]; then

#Removing primers
	echo ""
	echo "### Cutting primers"
	echo "# using sed;"
	
	echo ""

#Forward primers
	if [ -e "${USER_HOME}/.var_babitas/Forward1.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer1.txt" ]; then
		echo "searching and deleting fwd primer strings if they appear among the first 25 base pairs"
		sed --in-place=.backup "s/^.\{0,25\}$Forward1//g" $input
		echo "Removed forward primer "$Forward1
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward2.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer2.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward2//g" $input
		echo "Removed forward primer "$Forward2
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward3.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer3.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward3//g" $input
		echo "Removed forward primer "$Forward3
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward4.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer4.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward4//g" $input
		echo "Removed forward primer "$Forward4
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward5.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer5.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward5//g" $input
		echo "Removed forward primer "$Forward5
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward6.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer6.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward6//g" $input
		echo "Removed forward primer "$Forward6
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward7.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer7.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward7//g" $input
		echo "Removed forward primer "$Forward7
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward8.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer8.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward8//g" $input
		echo "Removed forward primer "$Forward8
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward9.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer9.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward9//g" $input
		echo "Removed forward primer "$Forward9
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward10.txt" ] || [ -e "${USER_HOME}/.var_babitas/F_primer10.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward10//g" $input
		echo "Removed forward primer "$Forward10
	fi


	if [ -e "${USER_HOME}/.var_babitas/Forward11.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward11//g" $input
		echo "Removed forward primer "$Forward11
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward12.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward12//g" $input
		echo "Removed forward primer "$Forward12
	fi

	if [ -e "${USER_HOME}/.var_babitas/Forward13.txt" ]; then
		sed --in-place "s/^.\{0,25\}$Forward13//g" $input
		echo "Removed forward primer "$Forward13
	fi


#Reverse primers
	if [ -e "${USER_HOME}/.var_babitas/Reverse1.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer1.txt" ]; then
		echo "searching and deleting rev primer strings (rc) if they appear among the last 25 base pairs"
		#reverse complement of reverse primer
		Reverse1_rc=$(echo $Reverse1 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse1_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse1
	fi


	if [ -e "${USER_HOME}/.var_babitas/Reverse2.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer2.txt" ]; then
		#reverse complement of reverse primer
		Reverse2_rc=$(echo $Reverse2 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse2_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse2
	fi


	if [ -e "${USER_HOME}/.var_babitas/Reverse3.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer3.txt" ]; then
		#reverse complement of reverse primer
		Reverse3_rc=$(echo $Reverse3 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse3_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse3
	fi


	if [ -e "${USER_HOME}/.var_babitas/Reverse4.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer4.txt" ]; then
		#reverse complement of reverse primer
		Reverse4_rc=$(echo $Reverse4 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse4_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse4
	fi


	if [ -e "${USER_HOME}/.var_babitas/Reverse5.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer5.txt" ]; then
		#reverse complement of reverse primer
		Reverse5_rc=$(echo $Reverse5 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse5_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse5
	fi


	if [ -e "${USER_HOME}/.var_babitas/Reverse6.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer6.txt" ]; then
		#reverse complement of reverse primer
		Reverse6_rc=$(echo $Reverse6 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse6_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse6
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse7.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer7.txt" ]; then
		#reverse complement of reverse primer
		Reverse7_rc=$(echo $Reverse7 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse7_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse7
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse8.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer8.txt" ]; then
		#reverse complement of reverse primer
		Reverse8_rc=$(echo $Reverse8 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse8_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse8
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse9.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer9.txt" ]; then
		#reverse complement of reverse primer
		Reverse9_rc=$(echo $Reverse9 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse9_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse9
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse10.txt" ] || [ -e "${USER_HOME}/.var_babitas/R_primer10.txt" ]; then
		#reverse complement of reverse primer
		Reverse10_rc=$(echo $Reverse10 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse10_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse10
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse11.txt" ]; then
		#reverse complement of reverse primer
		Reverse11_rc=$(echo $Reverse11 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse11_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse11
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse12.txt" ]; then
		#reverse complement of reverse primer
		Reverse12_rc=$(echo $Reverse12 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse12_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse12
	fi

	if [ -e "${USER_HOME}/.var_babitas/Reverse13.txt" ]; then
		#reverse complement of reverse primer
		Reverse13_rc=$(echo $Reverse13 | sed -e 's/\[/e/g;s/\]/v/g;s/e/\]/g;s/v/\[/g' | tr "[ATGC]" "[TACG]" | rev)
		sed --in-place "s/$Reverse13_rc.\{0,25\}$//g" $input
		echo "Removed reverse primer "$Reverse13
	fi


touch ${USER_HOME}/.var_babitas/Chimera_filtering_finished.txt

echo "##########################"
echo "DONE"
echo "############################"
echo "Primers cut"
echo "##############################"
echo "output = "$input
echo $input".backup = original input file"
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
						fi
					fi
				fi
			fi
		fi
	fi
fi





#Delete unnecessary files
if [ -e "${USER_HOME}/.var_babitas/F_primer1.txt" ]; then
rm ${USER_HOME}/.var_babitas/F_prim*
fi
if [ -e "${USER_HOME}/.var_babitas/R_primer1.txt" ]; then
rm ${USER_HOME}/.var_babitas/R_prim*
fi
if [ -e "${USER_HOME}/.var_babitas/abskew.txt" ]; then
rm ${USER_HOME}/.var_babitas/abskew.txt
fi
if [ -e "${USER_HOME}/.var_babitas/AbundanceAnnotatio.txt" ]; then
rm ${USER_HOME}/.var_babitas/AbundanceAnnotatio.txt
fi
if [ -e "${USER_HOME}/.var_babitas/denovo.txt" ]; then
rm ${USER_HOME}/.var_babitas/denovo.txt
fi
if [ -e "${USER_HOME}/.var_babitas/Forward1.txt" ]; then
rm ${USER_HOME}/.var_babitas/Forward*
fi
if [ -e "${USER_HOME}/.var_babitas/Reverse1.txt" ]; then
rm ${USER_HOME}/.var_babitas/Reverse*
fi
if [ -e "${USER_HOME}/.var_babitas/cut_primers.txt" ]; then
rm ${USER_HOME}/.var_babitas/cut_primers.txt
fi
if [ -e "${USER_HOME}/.var_babitas/multiprimer.txt" ]; then
rm ${USER_HOME}/.var_babitas/multiprimer.txt
fi
if [ -e "sortbysize.fasta" ]; then
rm sortbysize.fasta 
fi
if [ -e "centroids.fasta" ]; then
rm centroids.fasta 
fi
if [ -e "nonchimeras_denovo.fasta" ]; then
rm nonchimeras_denovo.fasta
fi
if [ -e "Chimera_filtered_oneline.fasta" ]; then
rm Chimera_filtered_oneline.fasta
fi
if [ -e "Chimera_filtered.rc.oneline_to5_3.fasta" ]; then
rm Chimera_filtered.rc.oneline_to5_3.fasta
fi














