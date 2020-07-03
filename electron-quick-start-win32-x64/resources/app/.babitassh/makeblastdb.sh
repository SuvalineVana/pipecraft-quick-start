#!/bin/bash 



echo "### Make BLAST database ###"
echo ""
echo ""


USER_HOME=$(eval echo ~${SUDO_USER})

#Set input file variable
	makedb=$(cat ${USER_HOME}/.var_babitas/makedb.txt)

	

#Set working directory
WorkingDirectory=$(awk 'BEGIN{FS=OFS="/"} NF{NF--};1' < ${USER_HOME}/.var_babitas/makedb.txt)
		if [ "$?" = "0" ]; then
 		echo ""
		else
		touch ${USER_HOME}/.var_babitas/MakeDB_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi


cd $WorkingDirectory
		if [ "$?" = "0" ]; then
 		echo "Working directory="$WorkingDirectory
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/MakeDB_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi



#Make BLAST database

makeblastdb -in $makedb -dbtype nucl -out $makedb.DB
		if [ "$?" = "0" ]; then
 		touch ${USER_HOME}/.var_babitas/MakeDB_finished.txt
		echo ""
		echo "##########################"
		echo "DONE"
		echo "############################"
		echo "makeblastdb finished"
		echo "##############################"
		echo "output = $makedb.DB"
		echo "Select it as your BLAST database"
		echo "################################"
		echo "You may close this window now!"
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/MakeDB_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi







#Delete unnecessary files
if [ -e "${USER_HOME}/.var_babitas/makedb.txt" ]; then
rm ${USER_HOME}/.var_babitas/makedb.txt
fi


