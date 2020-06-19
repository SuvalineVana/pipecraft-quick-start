#!/bin/bash 


#Set working directory
USER_HOME=$(eval echo ~${SUDO_USER})

WorkingDirectory=$(awk 'BEGIN{FS=OFS="/"} NF{NF--};1' < ${USER_HOME}/.var_babitas/list_file.txt)


cd $WorkingDirectory
		if [ "$?" = "0" ]; then
 		echo "..."
		else
		touch ${USER_HOME}/.var_babitas/OTU_table_errorr.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi


list=$(cat ${USER_HOME}/.var_babitas/list_file.txt)

awk 'BEGIN{FS=OFS="\t"}{$1="";$2=""; print}' $list | sed -e 's/\t/\n/g;s/,/\t/g' | sed '/^\s*$/d' > Cluster_file.cluster
		if [ "$?" = "0" ]; then
 		echo "done"
		else
		touch ${USER_HOME}/.var_babitas/OTU_table_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi
