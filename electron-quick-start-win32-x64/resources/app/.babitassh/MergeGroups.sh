#!/bin/bash 

#Set working directory
USER_HOME=$(eval echo ~${SUDO_USER})

WorkingDirectory=$(cat ${USER_HOME}/.var_babitas/groupFile.txt | head -n1 | awk 'BEGIN {FS="/"} {$NF=""; print $0}' | tr " " "/")


cd $WorkingDirectory


#Merge group files
merge=$(cat ${USER_HOME}/.var_babitas/groupFile.txt | tr "\n" " ") && cat $merge > MERGEDgroups.groups
		if [ "$?" = "0" ]; then
 		touch ${USER_HOME}/.var_babitas/groups_merge_ok.txt && exit 1
		else
		touch ${USER_HOME}/.var_babitas/groups_merge_error.txt && exit 1
		fi



