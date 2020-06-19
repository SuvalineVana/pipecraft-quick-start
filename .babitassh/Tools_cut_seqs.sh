#!/bin/bash 


echo "### Cutting sequences with mothur ###"
echo ""
echo "mothur - Schloss, P.D., et al., 2009. Introducing mothur: Open-Source, Platform-Independent, Community-Supported Software for Describing and Comparing Microbial Communities. Applied and Environmental Microbiology 75, 7537-7541."
echo "Distributed under the GNU General Public License version 2 by the Free Software Foundation"
echo "www.mothur.org"
echo "____________________________________________________"



#Set working directory
USER_HOME=$(eval echo ~${SUDO_USER})

if [ -e ${USER_HOME}/.var_babitas/fasta_cut.txt ]; then

	WorkingDirectory=$(awk 'BEGIN{FS=OFS="/"} NF{NF--};1' < ${USER_HOME}/.var_babitas/fasta_cut.txt)

	input=$(cat ${USER_HOME}/.var_babitas/fasta_cut.txt)


	cd $WorkingDirectory
			if [ "$?" = "0" ]; then
 			echo ""
			else
			touch ${USER_HOME}/.var_babitas/tools_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi

	else 
	echo "Error: no input" && exit 1

fi




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

#KeepFirst, RemoveLast, MinLen, MaxLen, RC
if [ -e ${USER_HOME}/.var_babitas/KeepFirst.txt ] && [ -e ${USER_HOME}/.var_babitas/RemoveLast.txt ] && [ -e ${USER_HOME}/.var_babitas/MinLen.txt ] && [ -e ${USER_HOME}/.var_babitas/MaxLen.txt ] && [ -e ${USER_HOME}/.var_babitas/rc.txt ]; then

	mothur "#trim.seqs(fasta=$input, flip=T, keepfirst=$KeepFirst, removelast=$RemoveLast, minlength=$MinLen, maxlength=$MaxLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/tools_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/tools_finished.txt
			fi


#KeepFirst, RemoveLast, MinLen, MaxLen
else if [ -e ${USER_HOME}/.var_babitas/KeepFirst.txt ] && [ -e ${USER_HOME}/.var_babitas/RemoveLast.txt ] && [ -e ${USER_HOME}/.var_babitas/MinLen.txt ] && [ -e ${USER_HOME}/.var_babitas/MaxLen.txt ]; then

	mothur "#trim.seqs(fasta=$input, keepfirst=$KeepFirst, removelast=$RemoveLast, minlength=$MinLen, maxlength=$MaxLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/tools_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/tools_finished.txt
			fi


#KeepFirst, RemoveLast, MinLen, RC
else if [ -e ${USER_HOME}/.var_babitas/KeepFirst.txt ] && [ -e ${USER_HOME}/.var_babitas/RemoveLast.txt ] && [ -e ${USER_HOME}/.var_babitas/MinLen.txt ] && [ -e ${USER_HOME}/.var_babitas/MaxLen.txt ] && [ -e ${USER_HOME}/.var_babitas/rc.txt ]; then

	mothur "#trim.seqs(fasta=$input, flip=T, keepfirst=$KeepFirst, removelast=$RemoveLast, minlength=$MinLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/tools_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/tools_finished.txt
			fi


#KeepFirst, RemoveLast, MinLen
else if [ -e ${USER_HOME}/.var_babitas/KeepFirst.txt ] && [ -e ${USER_HOME}/.var_babitas/RemoveLast.txt ] && [ -e ${USER_HOME}/.var_babitas/MinLen.txt ]; then

	mothur "#trim.seqs(fasta=$input, keepfirst=$KeepFirst, removelast=$RemoveLast, minlength=$MinLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/tools_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/tools_finished.txt
			fi


#KeepFirst, RemoveLast, MaxLen, RC
else if [ -e ${USER_HOME}/.var_babitas/KeepFirst.txt ] && [ -e ${USER_HOME}/.var_babitas/RemoveLast.txt ] && [ -e ${USER_HOME}/.var_babitas/MaxLen.txt ] && [ -e ${USER_HOME}/.var_babitas/rc.txt ]; then

	mothur "#trim.seqs(fasta=$input, flip=T, keepfirst=$KeepFirst, removelast=$RemoveLast, maxlength=$MaxLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/tools_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/tools_finished.txt
			fi


#KeepFirst, RemoveLast, MaxLen
else if [ -e ${USER_HOME}/.var_babitas/KeepFirst.txt ] && [ -e ${USER_HOME}/.var_babitas/RemoveLast.txt ] && [ -e ${USER_HOME}/.var_babitas/MaxLen.txt ]; then

	mothur "#trim.seqs(fasta=$input, keepfirst=$KeepFirst, removelast=$RemoveLast, maxlength=$MaxLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/tools_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/tools_finished.txt
			fi


#RemoveLast, MinLen, MaxLen, RC
else if [ -e ${USER_HOME}/.var_babitas/RemoveLast.txt ] && [ -e ${USER_HOME}/.var_babitas/MinLen.txt ] && [ -e ${USER_HOME}/.var_babitas/MaxLen.txt ] && [ -e ${USER_HOME}/.var_babitas/rc.txt ]; then

	mothur "#trim.seqs(fasta=$input, flip=T, removelast=$RemoveLast, minlength=$MinLen, maxlength=$MaxLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/tools_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/tools_finished.txt
			fi


#RemoveLast, MinLen, MaxLen
else if [ -e ${USER_HOME}/.var_babitas/RemoveLast.txt ] && [ -e ${USER_HOME}/.var_babitas/MinLen.txt ] && [ -e ${USER_HOME}/.var_babitas/MaxLen.txt ]; then

	mothur "#trim.seqs(fasta=$input, removelast=$RemoveLast, minlength=$MinLen, maxlength=$MaxLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/tools_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/tools_finished.txt
			fi


#KeepFirst, MinLen, MaxLen, RC
else if [ -e ${USER_HOME}/.var_babitas/KeepFirst.txt ] && [ -e ${USER_HOME}/.var_babitas/MinLen.txt ] && [ -e ${USER_HOME}/.var_babitas/MaxLen.txt ] && [ -e ${USER_HOME}/.var_babitas/rc.txt ]; then

	mothur "#trim.seqs(fasta=$input, flip=T, keepfirst=$KeepFirst, minlength=$MinLen, maxlength=$MaxLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/tools_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/tools_finished.txt
			fi


#KeepFirst, MinLen, MaxLen
else if [ -e ${USER_HOME}/.var_babitas/KeepFirst.txt ] && [ -e ${USER_HOME}/.var_babitas/MinLen.txt ] && [ -e ${USER_HOME}/.var_babitas/MaxLen.txt ]; then

	mothur "#trim.seqs(fasta=$input, keepfirst=$KeepFirst, minlength=$MinLen, maxlength=$MaxLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/tools_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/tools_finished.txt
			fi


#KeepFirst, RemoveLast, RC
else if [ -e ${USER_HOME}/.var_babitas/KeepFirst.txt ] && [ -e ${USER_HOME}/.var_babitas/RemoveLast.txt ] && [ -e ${USER_HOME}/.var_babitas/rc.txt ]; then

	mothur "#trim.seqs(fasta=$input, flip=T, keepfirst=$KeepFirst, removelast=$RemoveLast)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/tools_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/tools_finished.txt
			fi


#KeepFirst, RemoveLast
else if [ -e ${USER_HOME}/.var_babitas/KeepFirst.txt ] && [ -e ${USER_HOME}/.var_babitas/RemoveLast.txt ]; then

	mothur "#trim.seqs(fasta=$input, keepfirst=$KeepFirst, removelast=$RemoveLast)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/tools_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/tools_finished.txt
			fi


#KeepFirst, MinLen, RC
else if [ -e ${USER_HOME}/.var_babitas/KeepFirst.txt ] && [ -e ${USER_HOME}/.var_babitas/MinLen.txt ] && [ -e ${USER_HOME}/.var_babitas/rc.txt ]; then

	mothur "#trim.seqs(fasta=$input, flip=T, keepfirst=$KeepFirst, minlength=$MinLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/tools_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/tools_finished.txt
			fi


#KeepFirst, MinLen
else if [ -e ${USER_HOME}/.var_babitas/KeepFirst.txt ] && [ -e ${USER_HOME}/.var_babitas/MinLen.txt ]; then

	mothur "#trim.seqs(fasta=$input, keepfirst=$KeepFirst, minlength=$MinLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/tools_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/tools_finished.txt
			fi


#KeepFirst, MaxLen, RC
else if [ -e ${USER_HOME}/.var_babitas/KeepFirst.txt ] && [ -e ${USER_HOME}/.var_babitas/MaxLen.txt ] && [ -e ${USER_HOME}/.var_babitas/rc.txt ]; then

	mothur "#trim.seqs(fasta=$input, flip=T, keepfirst=$KeepFirst, maxlength=$MaxLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/tools_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/tools_finished.txt
			fi


#KeepFirst, MaxLen
else if [ -e ${USER_HOME}/.var_babitas/KeepFirst.txt ] && [ -e ${USER_HOME}/.var_babitas/MaxLen.txt ] && [ -e ${USER_HOME}/.var_babitas/rc.txt ]; then

	mothur "#trim.seqs(fasta=$input, keepfirst=$KeepFirst, maxlength=$MaxLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/tools_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/tools_finished.txt
			fi


#RemoveLast, MinLen, RC
else if [ -e ${USER_HOME}/.var_babitas/RemoveLast.txt ] && [ -e ${USER_HOME}/.var_babitas/MinLen.txt ] && [ -e ${USER_HOME}/.var_babitas/rc.txt ]; then

	mothur "#trim.seqs(fasta=$input, flip=T, removelast=$RemoveLast, minlength=$MinLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/tools_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/tools_finished.txt
			fi


#RemoveLast, MinLen
else if [ -e ${USER_HOME}/.var_babitas/RemoveLast.txt ] && [ -e ${USER_HOME}/.var_babitas/MinLen.txt ]; then

	mothur "#trim.seqs(fasta=$input, removelast=$RemoveLast, minlength=$MinLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/tools_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/tools_finished.txt
			fi


#RemoveLast, MaxLen, RC
else if [ -e ${USER_HOME}/.var_babitas/RemoveLast.txt ] && [ -e ${USER_HOME}/.var_babitas/MaxLen.txt ] && [ -e ${USER_HOME}/.var_babitas/rc.txt ]; then

	mothur "#trim.seqs(fasta=$input, flip=T, removelast=$RemoveLast, maxlength=$MaxLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/tools_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/tools_finished.txt
			fi


#RemoveLast, MaxLen
else if [ -e ${USER_HOME}/.var_babitas/RemoveLast.txt ] && [ -e ${USER_HOME}/.var_babitas/MaxLen.txt ]; then

	mothur "#trim.seqs(fasta=$input, removelast=$RemoveLast, maxlength=$MaxLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/tools_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/tools_finished.txt
			fi


#MinLen, MaxLen, RC
else if [ -e ${USER_HOME}/.var_babitas/MinLen.txt ] && [ -e ${USER_HOME}/.var_babitas/MaxLen.txt ] && [ -e ${USER_HOME}/.var_babitas/rc.txt ]; then

	mothur "#trim.seqs(fasta=$input, flip=T, minlength=$MinLen, maxlength=$MaxLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/tools_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/tools_finished.txt
			fi


#MinLen, MaxLen
else if [ -e ${USER_HOME}/.var_babitas/MinLen.txt ] && [ -e ${USER_HOME}/.var_babitas/MaxLen.txt ]; then

	mothur "#trim.seqs(fasta=$input, minlength=$MinLen, maxlength=$MaxLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/tools_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/tools_finished.txt
			fi




#KeepFirst, RC
else if [ -e ${USER_HOME}/.var_babitas/KeepFirst.txt ] && [ -e ${USER_HOME}/.var_babitas/rc.txt ]; then

	mothur "#trim.seqs(fasta=$input, flip=T, keepfirst=$KeepFirst)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/tools_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/tools_finished.txt
			fi


#KeepFirst
else if [ -e ${USER_HOME}/.var_babitas/KeepFirst.txt ]; then

	mothur "#trim.seqs(fasta=$input, keepfirst=$KeepFirst)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/tools_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/tools_finished.txt
			fi

#RemoveLast, RC
else if [ -e ${USER_HOME}/.var_babitas/RemoveLast.txt ] && [ -e ${USER_HOME}/.var_babitas/rc.txt ]; then

	mothur "#trim.seqs(fasta=$input, flip=T, removelast=$RemoveLast)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/tools_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/tools_finished.txt
			fi


#RemoveLast
else if [ -e ${USER_HOME}/.var_babitas/RemoveLast.txt ]; then

	mothur "#trim.seqs(fasta=$input, removelast=$RemoveLast)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/tools_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/tools_finished.txt
			fi


#MinLen, RC
else if [ -e ${USER_HOME}/.var_babitas/MinLen.txt ] && [ -e ${USER_HOME}/.var_babitas/rc.txt ]; then

	mothur "#trim.seqs(fasta=$input, flip=T, minlength=$MinLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/tools_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/tools_finished.txt
			fi


#MinLen
else if [ -e ${USER_HOME}/.var_babitas/MinLen.txt ]; then

	mothur "#trim.seqs(fasta=$input, minlength=$MinLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/tools_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/tools_finished.txt
			fi


#MaxLen, RC
else if  [ -e ${USER_HOME}/.var_babitas/MaxLen.txt ] && [ -e ${USER_HOME}/.var_babitas/rc.txt ]; then

	mothur "#trim.seqs(fasta=$input, flip=T, maxlength=$MaxLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/tools_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/tools_finished.txt
			fi


#MaxLen
else if  [ -e ${USER_HOME}/.var_babitas/MaxLen.txt ]; then

	mothur "#trim.seqs(fasta=$input, maxlength=$MaxLen)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/tools_error.txt && exit
			else
			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "Cutting sequences finished"
			echo "################################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/tools_finished.txt
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


