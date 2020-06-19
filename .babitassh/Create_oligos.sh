#!/bin/bash -e

USER_HOME=$(eval echo ~${SUDO_USER})


#Make forward and reverse primer files
cd ${USER_HOME}/.var_babitas

#Degenerate positions to IUPAC codes
sed -e 's/\[CG\]/S/g;s/\[GC\]/S/g;s/\[AG\]/R/g;s/\[GA\]/R/g;s/\[CT\]/Y/g;s/\[TC\]/Y/g;s/\[AT\]/W/g;s/\[TA\]/W/g;s/\[GT\]/K/g;s/\[TG\]/K/g;s/\[AC\]/M/g;s/\[CA\]/M/g;s/\[CTG\]/B/g;s/\[CGT\]/B/g;s/\[GTC\]/B/g;s/\[GCT\]/B/g;s/\[TGC\]/B/g;s/\[TCG\]/B/g;s/\[AGT\]/D/g;s/\[ATG\]/D/g;s/\[GTA\]/D/g;s/\[GAT\]/D/g;s/\[TAG\]/D/g;s/\[TGA\]/D/g;s/\[ACT\]/H/g;s/\[ATC\]/H/g;s/\[CTA\]/H/g;s/\[CAT\]/H/g;s/\[TCA\]/H/g;s/\[TAC\]/H/g;s/\[ACG\]/V/g;s/\[AGC\]/V/g;s/\[CAG\]/V/g;s/\[CGA\]/V/g;s/\[GCA\]/V/g;s/\[GAC\]/V/g;s/\[ATCG\]/N/g;s/\[ATGC\]/N/g;s/\[AGCT\]/N/g;s/\[AGTC\]/N/g;s/\[ACTG\]/N/g;s/\[ACGT\]/N/g;s/\[TACG\]/N/g;s/\[TAGC\]/N/g;s/\[TGCA\]/N/g;s/\[TGAC\]/N/g;s/\[TCAG\]/N/g;s/\[TCGA\]/N/g;s/\[CTAG\]/N/g;s/\[CTGA\]/N/g;s/\[CGAT\]/N/g;s/\[CGTA\]/N/g;s/\[CATG\]/N/g;s/\[CAGT\]/N/g;s/\[GTCA\]/N/g;s/\[GTAC\]/N/g;s/\[GACT\]/N/g;s/\[GATC\]/N/g;s/\[GCTA\]/N/g;s/\[GCAT\]/N/g' < primers.prim > primersIUPAC.txt



tr "\r" " " < primersIUPAC.txt | tr "\n" " " | sed -e 's/^ //g' | sed -e 's/ /\n/g' | awk '/F:_/ { print $0 }' | sed -e 's/F:_//g' | awk '{filename = sprintf("F_primer%d.txt", NR); print > filename; close(filename)}'

tr "\r" " " < primersIUPAC.txt | tr "\n" " " | sed -e 's/^ //g' | sed -e 's/ /\n/g' | awk '/R:_/ { print $0 }' | sed -e 's/R:_//g' | awk '{filename = sprintf("R_primer%d.txt", NR); print > filename; close(filename)}'



#Set primer variables
if [ -e "${USER_HOME}/.var_babitas/F_primer1.txt" ]; then
tr --delete '\r' < F_primer1.txt | tr --delete '\n' > F_prim1.txt 
f1=$(cat F_prim1.txt)
fi
if [ -e "${USER_HOME}/.var_babitas/F_primer2.txt" ]; then
tr --delete '\r' < F_primer2.txt | tr --delete '\n' > F_prim2.txt
f2=$(cat F_prim2.txt)
fi
if [ -e "${USER_HOME}/.var_babitas/F_primer3.txt" ]; then
tr --delete '\r' < F_primer3.txt | tr --delete '\n' > F_prim3.txt
f3=$(cat F_prim3.txt)
fi
if [ -e "${USER_HOME}/.var_babitas/F_primer4.txt" ]; then
tr --delete '\r' < F_primer4.txt | tr --delete '\n' > F_prim4.txt
f4=$(cat F_prim4.txt)
fi
if [ -e "${USER_HOME}/.var_babitas/F_primer5.txt" ]; then
tr --delete '\r' < F_primer5.txt | tr --delete '\n' > F_prim5.txt
f5=$(cat F_prim5.txt)
fi
if [ -e "${USER_HOME}/.var_babitas/F_primer6.txt" ]; then
tr --delete '\r' < F_primer6.txt | tr --delete '\n' > F_prim6.txt
f6=$(cat F_prim6.txt)
fi
if [ -e "${USER_HOME}/.var_babitas/F_primer7.txt" ]; then
tr --delete '\r' < F_primer7.txt | tr --delete '\n' > F_prim7.txt
f7=$(cat F_prim7.txt)
fi
if [ -e "${USER_HOME}/.var_babitas/F_primer8.txt" ]; then
tr --delete '\r' < F_primer8.txt | tr --delete '\n' > F_prim8.txt
f8=$(cat F_prim8.txt)
fi
if [ -e "${USER_HOME}/.var_babitas/F_primer9.txt" ]; then
tr --delete '\r' < F_primer9.txt | tr --delete '\n' > F_prim9.txt
f9=$(cat F_prim9.txt)
fi
if [ -e "${USER_HOME}/.var_babitas/F_primer10.txt" ]; then
tr --delete '\r' < F_primer10.txt | tr --delete '\n' > F_prim10.txt
f10=$(cat F_prim10.txt)
fi

#reverse primers
if [ -e "${USER_HOME}/.var_babitas/R_primer1.txt" ]; then
tr --delete '\r' < ${USER_HOME}/.var_babitas/R_primer1.txt | tr --delete '\n' > R_prim1.txt
r1=$(cat R_prim1.txt)
fi
if [ -e "${USER_HOME}/.var_babitas/R_primer2.txt" ]; then
tr --delete '\r' < R_primer2.txt | tr --delete '\n' > R_prim2.txt
r2=$(cat R_prim2.txt)
fi
if [ -e "${USER_HOME}/.var_babitas/R_primer3.txt" ]; then
tr --delete '\r' < R_primer3.txt | tr --delete '\n' > R_prim3.txt
r3=$(cat R_prim3.txt)
fi
if [ -e "${USER_HOME}/.var_babitas/R_primer4.txt" ]; then
tr --delete '\r' < R_primer4.txt | tr --delete '\n' > R_prim4.txt
r4=$(cat R_prim4.txt)
fi
if [ -e "${USER_HOME}/.var_babitas/R_primer5.txt" ]; then
tr --delete '\r' < R_primer5.txt | tr --delete '\n' > R_prim5.txt
r5=$(cat R_prim5.txt)
fi
if [ -e "${USER_HOME}/.var_babitas/R_primer6.txt" ]; then
tr --delete '\r' < R_primer6.txt | tr --delete '\n' > R_prim6.txt
r6=$(cat R_prim6.txt)
fi
if [ -e "${USER_HOME}/.var_babitas/R_primer7.txt" ]; then
tr --delete '\r' < R_primer7.txt | tr --delete '\n' > R_prim7.txt
r7=$(cat R_prim7.txt)
fi
if [ -e "${USER_HOME}/.var_babitas/R_primer8.txt" ]; then
tr --delete '\r' < R_primer8.txt | tr --delete '\n' > R_prim8.txt
r8=$(cat R_prim8.txt)
fi
if [ -e "${USER_HOME}/.var_babitas/R_primer9.txt" ]; then
tr --delete '\r' < R_primer9.txt | tr --delete '\n' > R_prim9.txt
r9=$(cat R_prim9.txt)
fi
if [ -e "${USER_HOME}/.var_babitas/R_primer10.txt" ]; then
tr --delete '\r' < R_primer10.txt | tr --delete '\n' > R_prim10.txt
r10=$(cat R_prim10.txt)
fi


#Set working directory
WorkingDirectory=$(awk 'BEGIN {FS="/"} {$NF=""; print $0}' < ${USER_HOME}/.var_babitas/assembled_fastq_location.txt | tr " " "/")

cd $WorkingDirectory


#Create oligo file into the directory "created_oligo_files"
mkdir -p created_oligo_files

cd created_oligo_files



#Create oligos files
#Single barcode. Tag attached to reverse primer. Fasta 3'-5'
if grep -q 'single_reverse' ${USER_HOME}/.var_babitas/oligos_format.txt; then
	awk 'NF' < ${USER_HOME}/.var_babitas/oligos_create1.txt > ${USER_HOME}/.var_babitas/oligos_create1_1.txt
	awk 'NF' < ${USER_HOME}/.var_babitas/oligos_create2.txt > ${USER_HOME}/.var_babitas/oligos_create2_1.txt
	pr -tm -J ${USER_HOME}/.var_babitas/oligos_create1_1.txt ${USER_HOME}/.var_babitas/oligos_create2_1.txt | awk 'BEGIN{FS="Ã"}{print $1"\t"$2}' | sed -e 's/^/barcode\t/g' > oligos.txt
	cp oligos.txt oligos_single.txt

	if grep -q 'YES' ${USER_HOME}/.var_babitas/include_Fprimers.txt || grep -q 'YES' ${USER_HOME}/.var_babitas/include_Rprimers.txt; then

	#in 3'-5' mode, forward primer is considered as reverse primer and reverse as forward!
	echo $f1 $f2 $f3 $f4 $f5 $f6 $f7 $f8 $f9 $f10 | sed -e 's/ /\n/g' | sed -e 's/^/reverse\t/g' > forward_primers.txt
	echo $r1 $r2 $r3 $r4 $r5 $r6 $r7 $r8 $r9 $r10 | sed -e 's/ /\n/g' | sed -e 's/^/forward\t/g' > reverse_primers.txt


		if grep -q 'YES' ${USER_HOME}/.var_babitas/include_Fprimers.txt && grep -q 'YES' ${USER_HOME}/.var_babitas/include_Rprimers.txt; then
			
			cat reverse_primers.txt forward_primers.txt oligos.txt > oligos_single.txt


				else if grep -q 'YES' ${USER_HOME}/.var_babitas/include_Fprimers.txt && grep -q 'NO' ${USER_HOME}/.var_babitas/include_Rprimers.txt; then
				cat forward_primers.txt oligos.txt > oligos_single.txt


				else if grep -q 'NO' ${USER_HOME}/.var_babitas/include_Fprimers.txt && grep -q 'YES' ${USER_HOME}/.var_babitas/include_Rprimers.txt; then
				cat reverse_primers.txt oligos.txt > oligos_single.txt

								
				fi
				fi
		fi
	fi
fi








#Single barcode. Tag attached to forward primer. Fasta 5'-3'
if grep -q 'single_forward' ${USER_HOME}/.var_babitas/oligos_format.txt; then
	awk 'NF' < ${USER_HOME}/.var_babitas/oligos_create1.txt > ${USER_HOME}/.var_babitas/oligos_create1_1.txt
	awk 'NF' < ${USER_HOME}/.var_babitas/oligos_create2.txt > ${USER_HOME}/.var_babitas/oligos_create2_1.txt
	pr -tm -J ${USER_HOME}/.var_babitas/oligos_create1_1.txt ${USER_HOME}/.var_babitas/oligos_create2_1.txt | awk 'BEGIN{FS="Ã"}{print $1"\t"$2}' | sed -e 's/^/barcode\t/g' > oligos.txt
	cp oligos.txt oligos_single.txt

	if grep -q 'YES' ${USER_HOME}/.var_babitas/include_Fprimers.txt || grep -q 'YES' ${USER_HOME}/.var_babitas/include_Rprimers.txt; then

	echo $f1 $f2 $f3 $f4 $f5 $f6 $f7 $f8 $f9 $f10 | sed -e 's/ /\n/g' | sed -e 's/^/forward\t/g' > forward_primers.txt
	echo $r1 $r2 $r3 $r4 $r5 $r6 $r7 $r8 $r9 $r10 | sed -e 's/ /\n/g' | sed -e 's/^/reverse\t/g' > reverse_primers.txt


		if grep -q 'YES' ${USER_HOME}/.var_babitas/include_Fprimers.txt && grep -q 'YES' ${USER_HOME}/.var_babitas/include_Rprimers.txt; then
			
			cat forward_primers.txt reverse_primers.txt oligos.txt > oligos_single.txt


				else if grep -q 'YES' ${USER_HOME}/.var_babitas/include_Fprimers.txt && grep -q 'NO' ${USER_HOME}/.var_babitas/include_Rprimers.txt; then
				cat forward_primers.txt oligos.txt > oligos_single.txt


				else if grep -q 'NO' ${USER_HOME}/.var_babitas/include_Fprimers.txt && grep -q 'YES' ${USER_HOME}/.var_babitas/include_Rprimers.txt; then
				cat reverse_primers.txt oligos.txt > oligos_single.txt

				
				fi
				fi
		fi
	fi
fi





#Paired barcodes.
if grep -q 'paired' ${USER_HOME}/.var_babitas/oligos_format.txt; then
	awk 'NF' < ${USER_HOME}/.var_babitas/oligos_create1.txt > ${USER_HOME}/.var_babitas/oligos_create1_1.txt
	awk 'NF' < ${USER_HOME}/.var_babitas/oligos_create2.txt > ${USER_HOME}/.var_babitas/oligos_create2_1.txt
	awk 'NF' < ${USER_HOME}/.var_babitas/oligos_create3.txt > ${USER_HOME}/.var_babitas/oligos_create3_1.txt

	pr -tm -J ${USER_HOME}/.var_babitas/oligos_create1_1.txt ${USER_HOME}/.var_babitas/oligos_create2_1.txt ${USER_HOME}/.var_babitas/oligos_create3_1.txt | awk 'BEGIN{FS="Ã"}{print $1"\t"$2"\t"$3}' | sed -e 's/^/barcode\t/g' > oligos_paired.txt



	if grep -q 'YES' ${USER_HOME}/.var_babitas/include_Fprimers.txt || grep -q 'YES' ${USER_HOME}/.var_babitas/include_Rprimers.txt; then

	echo $f1"_"$r1 $f2"_"$r2 $f3"_"$r3 $f4"_"$r4 $f5"_"$r5 $f6"_"$r6 $f7"_"$r7 $f8"_"$r8  $f9"_"$r9 $f10"_"$r10 | \
	sed -e 's/ /\n/g' | \
	sed -e 's/_/\t/g' | \
	awk 'NF > 0' | \
	sed -e 's/^/primer\t/g' | \
	awk -F'\t' -vOFS='\t' '{if ($3 == "") gsub("", "NONE", $3); print $0}' | \
	awk -F'\t' -vOFS='\t' '{if ($2 == "") gsub("", "NONE", $2); print $0}' > primers_set.txt

pr -tm -J ${USER_HOME}/.var_babitas/oligos_create1_1.txt ${USER_HOME}/.var_babitas/oligos_create2_1.txt ${USER_HOME}/.var_babitas/oligos_create3_1.txt | awk 'BEGIN{FS="Ã"}{print $1"\t"$2"\t"$3}' | sed -e 's/^/barcode\t/g' > oligos1.txt

		
		if grep -q 'YES' ${USER_HOME}/.var_babitas/include_Fprimers.txt && grep -q 'YES' ${USER_HOME}/.var_babitas/include_Rprimers.txt; then

cat primers_set.txt oligos1.txt > oligos_paired.txt

			
			else if grep -q 'YES' ${USER_HOME}/.var_babitas/include_Fprimers.txt && grep -q 'NO' ${USER_HOME}/.var_babitas/include_Rprimers.txt; then
			awk '{print $1"\t"$2"\t""NONE"}' < primers_set.txt | sed -r '/primer\tNONE\tNONE/d' > primers_F.txt
			cat primers_F.txt oligos1.txt > oligos_paired.txt


			else if grep -q 'NO' ${USER_HOME}/.var_babitas/include_Fprimers.txt && grep -q 'YES' ${USER_HOME}/.var_babitas/include_Rprimers.txt; then
			awk '{print $1"\t""NONE""\t"$3}' < primers_set.txt | sed -r '/primer\tNONE\tNONE/d' > primers_R.txt
			cat primers_R.txt oligos1.txt > oligos_paired.txt

			
			fi
			fi
		fi
	fi
fi







#Oligos location
if [ -e "${USER_HOME}/.var_babitas/oligos_create3.txt" ]; then
pwd | sed 's,$,/oligos_paired.txt,' > ${USER_HOME}/.var_babitas/created_oligo_location.txt

	else
	pwd | sed 's,$,/oligos_single.txt,' > ${USER_HOME}/.var_babitas/created_oligo_location.txt
fi



#Remove unnecessary text files
if [ -e "${USER_HOME}/.var_babitas/oligos_create1.txt" ]; then
rm ${USER_HOME}/.var_babitas/oligos_create1.txt
fi
if [ -e "${USER_HOME}/.var_babitas/oligos_create1_1.txt" ]; then
rm ${USER_HOME}/.var_babitas/oligos_create1_1.txt
fi
if [ -e "${USER_HOME}/.var_babitas/oligos_create2.txt" ]; then
rm ${USER_HOME}/.var_babitas/oligos_create2.txt
fi
if [ -e "${USER_HOME}/.var_babitas/oligos_create2_1.txt" ]; then
rm ${USER_HOME}/.var_babitas/oligos_create2_1.txt
fi
if [ -e "${USER_HOME}/.var_babitas/oligos_create3.txt" ]; then
rm ${USER_HOME}/.var_babitas/oligos_create3.txt
fi
if [ -e "${USER_HOME}/.var_babitas/oligos_create3_1.txt" ]; then
rm ${USER_HOME}/.var_babitas/oligos_create3_1.txt
fi
if [ -e "${USER_HOME}/.var_babitas/primersIUPAC.txt" ]; then
rm ${USER_HOME}/.var_babitas/primersIUPAC.txt
fi
if [ -e "${USER_HOME}/.var_babitas/include_Rprimers.txt" ]; then
rm ${USER_HOME}/.var_babitas/include_Rprimers.txt
fi
if [ -e "${USER_HOME}/.var_babitas/include_Fprimers.txt" ]; then
rm ${USER_HOME}/.var_babitas/include_Fprimers.txt
fi
if [ -e "${USER_HOME}/.var_babitas/F_primer1.txt" ]; then
rm ${USER_HOME}/.var_babitas/F_prim*
fi
if [ -e "${USER_HOME}/.var_babitas/R_primer1.txt" ]; then
rm ${USER_HOME}/.var_babitas/R_prim*
fi

if [ -e "paired_barcodes_primers.txt" ]; then
rm paired_barcodes_primers.txt
fi
if [ -e "first_line.txt" ]; then
rm first_line.txt
fi
if [ -e "oligos1.txt" ]; then
rm oligos1.txt
fi
if [ -e "forward_primers.txt" ]; then
rm forward_primers.txt
fi
if [ -e "reverse_primers.txt" ]; then
rm reverse_primers.txt
fi
if [ -e "primers_set.txt" ]; then
rm primers_set.txt
fi
if [ -e "primers_F.txt" ]; then
rm primers_F.txt
fi
if [ -e "primers_R.txt" ]; then
rm primers_R.txt
fi
if [ -e "oligos.txt" ]; then
rm oligos.txt
fi

echo "oligos file created"



