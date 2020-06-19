#!/bin/bash -e

USER_HOME=$(eval echo ~${SUDO_USER})

#Set working directory
if [ -e ${USER_HOME}/.var_babitas/fastq_input.txt ]; then
WorkingDirectory=$(awk 'BEGIN{FS=OFS="/"} NF{NF--};1' < ${USER_HOME}/.var_babitas/fastq_input.txt)
else 
echo "#ERROR: no input file"
fi


cd $WorkingDirectory
		if [ "$?" = "0" ]; then
 		echo "Working directory = "$WorkingDirectory
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Trimming_error.txt && echo "ERROR occured: Unable to open working directory" 1>&2 && echo "Close this window" && exit 1
		fi

script -c "${USER_HOME}/.babitassh/Trimming.sh 2>&1" log_QualityFiltering.log


sed --in-place 's/\^C/\n#PROCESS_STOPPED_by_user#/' log_QualityFiltering.log

sed --in-place '/%/d;/Type/d;/Distributed under the GNU General Public License/d;/mothur > quit()/d;/Department of Microbiology & Immunology/d;/University of Michigan/d;/When using, please cite:/d;/Schloss, P.D., et al., Introducing mothur:/d;/mothur v.1.36.1/d;/Last updated/d;/Patrick/d;/pschloss/d;/http/d;/Licensed to/d;/^by/d;/\[2J/d' log_QualityFiltering.log

#delete duplicate, consecutive lines from a file (emulates "uniq") 
sed --in-place '$!N; /^\(.*\)\n\1$/!P; D' log_QualityFiltering.log


	if grep -q 'error' log_QualityFiltering.log; then
 	echo "### ERROR ###"
	touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
			
	else if grep -q 'No such file or directory' log_QualityFiltering.log; then
	echo "ERROR occurred - No such file or directory"
	echo "Examine log_QualityFiltering.log for details"
	touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
			
	else if grep -q '#PROCESS_STOPPED_by_user#' log_QualityFiltering.log; then
	echo "### Stopped ###"
	touch ${USER_HOME}/.var_babitas/Trimming_error.txt && exit
	echo ""
	fi
	fi
	fi
