#!/bin/bash 


#Set working directory
USER_HOME=$(eval echo ~${SUDO_USER})

if [ -e ${USER_HOME}/.var_babitas/cluster_to_convert.txt ]; then

	WorkingDirectory=$(awk 'BEGIN{FS=OFS="/"} NF{NF--};1' < ${USER_HOME}/.var_babitas/cluster_to_convert.txt)

	cluster_to_convert=$(cat ${USER_HOME}/.var_babitas/cluster_to_convert.txt)


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


#############################################
### UC file ###### UC file ###### UC file ###
#############################################
if grep -q 'uc' ${USER_HOME}/.var_babitas/cluster_format.txt; then

echo "### Converting UC file to regular CULSTER format ###"
echo " # using custom python script"
echo ""

echo $WorkingDirectory > ${USER_HOME}/.var_babitas/WD.txt

cp $cluster_to_convert Clusters_to_convert.uc

python ${USER_HOME}/.babitassh/uc_converter_tools.py
		if [ "$?" = "0" ]; then
		rm Clusters_to_convert.uc
 		echo ""
		echo "###############################"
		echo "DONE"
		echo "###############################"
		echo "output = Converted_uc.cluster"
		echo "###############################"
		echo "You may close this window now!"
		touch ${USER_HOME}/.var_babitas/tools_finished.txt
		else
		touch ${USER_HOME}/.var_babitas/tools_error.txt
		echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi




#############################################
### UP file ###### UP file ###### UP file ###
#############################################
else if grep -q 'up' ${USER_HOME}/.var_babitas/cluster_format.txt; then

echo "### Converting UP file to regular CULSTER format ###"
echo " # using custom python script"
echo ""

python ${USER_HOME}/.babitassh/up_converter.py $cluster_to_convert Converted_UP.cluster
		if [ "$?" = "0" ]; then
 		echo ""
		echo "###############################"
		echo "DONE"
		echo "###############################"
		echo "output = Converted_UP.cluster"
		echo "###############################"
		echo "You may close this window now!"
		touch ${USER_HOME}/.var_babitas/tools_finished.txt
		else
		touch ${USER_HOME}/.var_babitas/tools_error.txt
		echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi



######################################################
### CLSTR file ###### CLSTR file ###### CLSTR file ###
######################################################
else if grep -q 'clstr' ${USER_HOME}/.var_babitas/cluster_format.txt; then

echo "### Converting CLSTR file to regular CULSTER format ###"
echo " # using custom python script"
echo ""
echo ""

echo $WorkingDirectory > ${USER_HOME}/.var_babitas/WD.txt

cp $cluster_to_convert Clusters_to_convert.clstr

python ${USER_HOME}/.babitassh/cdhit_clstr_convert_tools.py
		if [ "$?" = "0" ]; then
 		echo ""
		else
		touch ${USER_HOME}/.var_babitas/tools_error.txt
		echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi

#Delete '...' , created by CDHIT
sed -e 's/...\t/\t/g' < Converted_clusters.temp > Converted_CLSTR.cluster
		if [ "$?" = "0" ]; then
		rm Converted_clusters.temp
		rm Clusters_to_convert.clstr
 		echo ""
		echo "###############################"
		echo "DONE"
		echo "###############################"
		echo "output = Converted_CLSTR.cluster"
		echo "###############################"
		echo "You may close this window now!"
		touch ${USER_HOME}/.var_babitas/tools_finished.txt
		else
		touch ${USER_HOME}/.var_babitas/tools_error.txt
		echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi




###################################################
### LIST file ###### LIST file ###### LIST file ###
###################################################
else if grep -q 'list' ${USER_HOME}/.var_babitas/cluster_format.txt; then

echo "### Converting LIST file to regular CULSTER format ###"
echo " # using custom awk script"
echo ""
echo ""

awk 'BEGIN{FS=OFS="\t"}{$1="";$2=""; print}' $cluster_to_convert | sed -e 's/\t/\n/g;s/,/\t/g' | sed '/^\s*$/d' > Converted_LIST.cluster
		if [ "$?" = "0" ]; then
 		echo "###############################"
		echo "DONE"
		echo "###############################"
		echo "output = Converted_LIST.cluster"
		echo "###############################"
		echo "You may close this window now!"
		touch ${USER_HOME}/.var_babitas/tools_finished.txt
			else
		touch ${USER_HOME}/.var_babitas/tools_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi

fi
fi
fi
fi
























