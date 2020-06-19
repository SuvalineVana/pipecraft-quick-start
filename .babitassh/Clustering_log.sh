#!/bin/bash -e

USER_HOME=$(eval echo ~${SUDO_USER})

#Set working directory
if [ -e ${USER_HOME}/.var_babitas/input_for_clustering.txt ]; then

WorkingDirectory=$(awk 'BEGIN{FS=OFS="/"} NF{NF--};1' < ${USER_HOME}/.var_babitas/input_for_clustering.txt)
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Clustering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi

	else if [ -e ${USER_HOME}/.var_babitas/fastaFile.txt ]; then

		sed -i 's/<p><\/p>//g' ${USER_HOME}/.var_babitas/fastaFile.txt
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Clustering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

	WorkingDirectory=$(cat ${USER_HOME}/.var_babitas/fastaFile.txt | sed '/^\s*$/d' | head -n1 | awk 'BEGIN{FS=OFS="/"} NF{NF--};1')
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/Clustering_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi

		else 
		touch ${USER_HOME}/.var_babitas/Clustering_error.txt && echo "ERROR occured (no input?)" 1>&2 && echo "Close this window" && exit 1

	fi
fi



cd $WorkingDirectory
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/Clustering_error.txt && echo "ERROR occured: Unable to open working directory" 1>&2 && echo "Close this window" && exit 1
		fi




script -c "${USER_HOME}/.babitassh/Clustering.sh 2>&1" log_Clustering.log



sed --in-place 's/\^C/\n#PROCESS_STOPPED_by_user#/' log_Clustering.log

sed --in-place '/%/d;/Type/d;/Distributed under the GNU General Public License/d;/mothur > quit()/d;/Department of Microbiology & Immunology/d;/University of Michigan/d;/When using, please cite:/d;/Schloss, P.D., et al., Introducing mothur:/d;/mothur v.1.36.1/d;/Last updated/d;/Patrick/d;/pschloss/d;/http/d;/Licensed to/d;/^by/d;/\[2J/d' log_Clustering.log

#delete duplicate, consecutive lines from a file (emulates "uniq") 
sed --in-place '$!N; /^\(.*\)\n\1$/!P; D' log_Clustering.log



	if grep -q 'error' log_Clustering.log || grep -q 'ERROR' log_Clustering.log; then
 	echo "### ERROR ###"
	touch ${USER_HOME}/.var_babitas/Clustering_error.txt && exit
			
	else if grep -q 'No such file or directory' log_Clustering.log; then
	echo ""
	echo "ERROR occurred - Some file or directory does not exist"
	echo "Examine log_Clustering.log for details"
	touch ${USER_HOME}/.var_babitas/Clustering_error.txt && exit

	else if grep -q '#PROCESS_STOPPED_by_user#' log_Clustering.log; then
	echo "### Stopped ###"
	touch ${USER_HOME}/.var_babitas/Clustering_error.txt && exit
	echo ""
	fi
	fi
	fi
