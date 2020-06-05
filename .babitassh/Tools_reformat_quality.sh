#!/bin/bash

echo "### Reformat quality scores ###"
echo ""
echo "BBMap - sourceforge.net/projects/bbmap/?source=navbar"
echo "BBTools Copyright (c) 2014, The Regents of the University of California, through Lawrence Berkeley National Laboratory (subject to receipt of any required approvals from the U.S. Dept. of Energy)."
echo "________________________________________________"

USER_HOME=$(eval echo ~${SUDO_USER})

#Set working directory
WorkingDirectory=$(awk 'BEGIN{FS=OFS="/"} NF{NF--};1' < ${USER_HOME}/.var_babitas/fastq6.txt)
		if [ "$?" = "0" ]; then
 		echo "Working directory = $WorkingDirectory"
		else
		touch ${USER_HOME}/.var_babitas/tools_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi


#Enter working directory
cd $WorkingDirectory
		if [ "$?" = "0" ]; then
 		echo ""
		else
		touch ${USER_HOME}/.var_babitas/tools_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi


#Set input variable
fastq6=$(cat ${USER_HOME}/.var_babitas/fastq6.txt)
		if [ "$?" = "0" ]; then
 		echo ""
		else
		touch ${USER_HOME}/.var_babitas/tools_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi




${USER_HOME}/.babitassh/bbmap/reformat.sh in=$fastq6 out=$fastq6.reformat.fastq qin=33 maxcalledquality=41 overwrite=true
			if [ "$?" = "0" ]; then
			echo "#############################"
			echo "DONE"
			echo "#############################"
			echo "output = $fastq6.reformat.fastq"
			echo "#############################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/tools_finished.txt
			else
			touch ${USER_HOME}/.var_babitas/tools_error.txt && echo "# ERROR #" 1>&2 && echo "Close this window" && exit 1
			fi



