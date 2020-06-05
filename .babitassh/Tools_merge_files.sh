#!/bin/bash 

echo "### Merging files ###"
echo ""


USER_HOME=$(eval echo ~${SUDO_USER})


#Rename fasta file
if [ -e ${USER_HOME}/.var_babitas/inputs.txt ]; then

#remove <p></p> characters from file
sed -i 's/<p><\/p>//g' ${USER_HOME}/.var_babitas/inputs.txt

#Set working directory
WorkingDirectory=$(cat ${USER_HOME}/.var_babitas/inputs.txt | sed '/^\s*$/d' | head -n1 | awk 'BEGIN{FS=OFS="/"} NF{NF--};1')


cd $WorkingDirectory
			if [ "$?" = "0" ]; then
 			echo ""
			else
			touch ${USER_HOME}/.var_babitas/tools_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi

#Merge files
	echo ""

	inputs=$(cat ${USER_HOME}/.var_babitas/inputs.txt | sed '/^\s*$/d' | tr "\n" " " | tr "\r" " ")


	#Enter NEW LINE to the end of each file (so that the cat would work correctly)
	sed -i -e '$a\' $inputs

	#Detect the files formatting
	echo $inputs | awk 'BEGIN{FS="."}{print $NF}' > format.temp
	format=$(cat format.temp)
	rm format.temp

	echo "cat "$inputs
	cat $inputs > MERGEDfile.$format

			if [ "$?" = "0" ]; then
			echo "#############################"
			echo "DONE"
			echo "#############################"
			echo "output = MERGEDfile."$format
			echo "#############################"
			echo "You may close this window now!"
			touch ${USER_HOME}/.var_babitas/tools_finished.txt
			else
			touch ${USER_HOME}/.var_babitas/tools_error.txt && echo "# ERROR #" 1>&2 && echo "Close this window" && exit 1
			fi

fi



	








