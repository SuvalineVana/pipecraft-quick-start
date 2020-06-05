#!/bin/bash -e

USER_HOME=$(eval echo ~${SUDO_USER})

#Set working directory
WorkingDirectory=$(awk 'BEGIN{FS=OFS="/"} NF{NF--};1' < ${USER_HOME}/.var_babitas/dem_input_location.txt)



cd $WorkingDirectory
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt && echo "ERROR occured: Unable to open working directory" 1>&2 && echo "Close this window" && exit 1
		fi


script -c "${USER_HOME}/.babitassh/demultiplex.sh 2>&1" log_demultiplexing.log



sed --in-place 's/\^C/\n#PROCESS_STOPPED_by_user#/' log_demultiplexing.log
sed --in-place 's/KeyboardInterrupt/\n#PROCESS_STOPPED_by_user#/' log_demultiplexing.log




sed --in-place '/%/d;/Type/d;/Distributed under the GNU General Public License/d;/mothur > quit()/d;/Department of Microbiology & Immunology/d;/University of Michigan/d;/When using, please cite:/d;/Schloss, P.D., et al., Introducing mothur:/d;/mothur v.1.36.1/d;/Last updated/d;/Patrick/d;/pschloss/d;/http/d;/Licensed to/d;/^by/d;/\[2J/d' log_demultiplexing.log

#delete duplicate, consecutive lines from a file (emulates "uniq") 
sed --in-place '$!N; /^\(.*\)\n\1$/!P; D' log_demultiplexing.log

	if grep -q 'error' log_demultiplexing.log; then
 	echo "### ERROR ###"
	touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt && exit
			
		else if grep -q 'No such file or directory' log_demultiplexing.log; then
		echo ""
		echo ""
		echo ""
		echo "ERROR occurred - No such file or directory"
		echo "Examine log_demultiplexing.log for details"
		touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt && exit
			
		else if grep -q '#PROCESS_STOPPED_by_user#' log_demultiplexing.log; then
		echo ""
		echo ""
		echo ""
		echo "### Stopped ###"
		touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt && exit
		echo ""

		else if grep -q 'AttributeError' log_demultiplexing.log; then
		echo ""
		echo ""
		echo ""
		echo "### AttributeError by OBITools ###"
		echo "# Check the sequences - may contain many ambiguous (N) base pairs -> DISCARD THOSE SEQS"
		touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt && exit
		echo ""

		else if grep -q 'Premature End-Of-File' log_demultiplexing.log; then
		echo ""
		echo ""
		echo ""
		echo "ERROR"
		echo ""
		echo "### Premature End-Of-File by Fastx Toolkit ###"
		echo "# Check the primers. Check if the sequences are mixed or 5'-3' oriented"
		touch ${USER_HOME}/.var_babitas/demultiplexing_error.txt && exit
		echo ""

		fi
		fi
		fi
		fi
	fi
