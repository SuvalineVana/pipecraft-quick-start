#!/bin/bash -e


USER_HOME=$(eval echo ~${SUDO_USER})

#Set working directory
WorkingDirectory=$(awk 'BEGIN{FS=OFS="/"} NF{NF--};1' < ${USER_HOME}/.var_babitas/fastq4.txt)
		if [ "$?" = "0" ]; then
 		echo ""
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



script -c "${USER_HOME}/.babitassh/Tools_fastq_splitter.sh 2>&1" log_fastq_splitter.log


sed --in-place 's/\^C/\n#PROCESS_STOPPED_by_user#/' log_fastq_splitter.log

sed --in-place '/%/d;/Type/d;/Distributed under the GNU General Public License/d;/mothur > quit()/d;/Department of Microbiology & Immunology/d;/University of Michigan/d;/When using, please cite:/d;/Schloss, P.D., et al., Introducing mothur:/d;/mothur v.1.36.1/d;/Last updated/d;/Patrick/d;/pschloss/d;/http/d;/Licensed to/d;/^by/d;/\[2J/d' log_fastq_splitter.log

#delete duplicate, consecutive lines from a file (emulates "uniq") 
sed --in-place '$!N; /^\(.*\)\n\1$/!P; D' log_fastq_splitter.log


	if grep -q 'error' log_fastq_splitter.log; then
 	echo "### ERROR ###"
	touch ${USER_HOME}/.var_babitas/tools_error.txt && exit
			
	else if grep -q 'No such file or directory' log_fastq_splitter.log; then
	echo "ERROR occurred - No such file or directory"
	echo "Examine log_fastq_splitter.log for details"
	touch ${USER_HOME}/.var_babitas/tools_error.txt && exit
			
	else if grep -q '#PROCESS_STOPPED_by_user#' log_fastq_splitter.log; then
	echo "### Stopped ###"
	touch ${USER_HOME}/.var_babitas/tools_error.txt && exit
	echo ""
	fi
	fi
	fi
