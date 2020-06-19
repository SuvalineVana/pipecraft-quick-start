#!/bin/bash 


echo "### Converting OTU table to biom format ###"
echo ""
echo "Using:"
echo "biom-format"
echo "McDonald, D., Clemente, J.C., Kuczynski, J., Rideout, J.R., Stombaugh, J., Wendel, D., Wilke, A., Huse, S., Hufnagle, J. & Meyer, F., 2012. The Biological Observation Matrix (BIOM) format or: how I learned to stop worrying and love the ome-ome. GigaScience, 1, 1."
echo "Copyright (c) 2011-2013, The BIOM Format Development Team <gregcaporaso@gmail.com>"
echo "github.com/biocore/biom-format"
echo ""
echo "____________________________________________"



#Set working directory
USER_HOME=$(eval echo ~${SUDO_USER})

if [ -e ${USER_HOME}/.var_babitas/convert_table.txt ]; then

	WorkingDirectory=$(awk 'BEGIN{FS=OFS="/"} NF{NF--};1' < ${USER_HOME}/.var_babitas/convert_table.txt)

	input=$(cat ${USER_HOME}/.var_babitas/convert_table.txt)


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



#Convert a tab-delimited table to a HDF5 or JSON biom format.

if grep -q 'JSON' ${USER_HOME}/.var_babitas/table_format.txt; then
echo 'biom convert -i $input -o table.from_txt_json.biom --table-type="OTU table" --to-json'

biom convert -i $input -o table.from_txt_json.biom --table-type="OTU table" --to-json
			if [ "$?" = "0" ]; then
			touch ${USER_HOME}/.var_babitas/tools_finished.txt
 			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "OTU table converted"
			echo "output = table.from_txt_json.biom"
			echo "################################"
			echo "You may close this window now!"
			else
			touch ${USER_HOME}/.var_babitas/tools_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi


	else if grep -q 'HDF5' ${USER_HOME}/.var_babitas/table_format.txt; then
	echo 'biom convert -i $input -o table.from_txt_hdf5.biom --table-type="OTU table" --to-hdf5'	

	biom convert -i $input -o table.from_txt_hdf5.biom --table-type="OTU table" --to-hdf5
			if [ "$?" = "0" ]; then
			touch ${USER_HOME}/.var_babitas/tools_finished.txt
 			echo ""
	 		echo "##########################"
			echo "DONE"
			echo "############################"
			echo "OTU table converted"
			echo "output = table.from_txt_hdf5.biom"
			echo "################################"
			echo "You may close this window now!"
			else
			touch ${USER_HOME}/.var_babitas/tools_error.txt 
			echo "An unexpected error has occurred!  Aborting." 1>&2
			exit 1
			fi

	fi
fi




