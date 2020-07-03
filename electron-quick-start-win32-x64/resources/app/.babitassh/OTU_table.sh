#!/bin/bash

echo "### Making OTU table ###"
echo ""
echo "When using the incorporated tools, please cite as follows:"
echo ""
echo "mothur - Schloss, P.D., et al., 2009. Introducing mothur: Open-Source, Platform-Independent, Community-Supported Software for Describing and Comparing Microbial Communities. Applied and Environmental Microbiology 75, 7537-7541."
echo "Distributed under the GNU General Public License version 2 by the Free Software Foundation"
echo "www.mothur.org"
echo "________________________________________________"



USER_HOME=$(eval echo ~${SUDO_USER})

#Set working directory
if [ -e ${USER_HOME}/.var_babitas/cluster_file.txt ]; then

WorkingDirectory=$(awk 'BEGIN{FS=OFS="/"} NF{NF--};1' < ${USER_HOME}/.var_babitas/cluster_file.txt)
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/OTU_table_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi


		else 
		touch ${USER_HOME}/.var_babitas/OTU_table_error.txt && echo "ERROR occured (no input?)" 1>&2 && echo "Close this window" && exit 1


fi

echo $WorkingDirectory > ${USER_HOME}/.var_babitas/WD.txt

cd $WorkingDirectory
		if [ "$?" = "0" ]; then
		echo ""
		else
		touch ${USER_HOME}/.var_babitas/OTU_table_error.txt && echo "ERROR occured" 1>&2 && echo "Can't enter to the directory" && exit 1
		fi



#Input variables
cluster_file=$(cat ${USER_HOME}/.var_babitas/cluster_file.txt)


merge_groups=$(cat ${USER_HOME}/.var_babitas/groupFile2.txt | sed '/^\s*$/d' | tr "\n" " " | tr "\r" " ")
	echo "group(s) = "$merge_groups
	cat $merge_groups > groups.groups
			if [ "$?" = "0" ]; then
	 		echo ""
			else
			touch ${USER_HOME}/.var_babitas/OTU_table_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi


#Making mothur list from cluster file
tr "\t" "," < $cluster_file | tr "\n" "\t" | sed -e 's/,\t/\t/g'  > mothur.list.temp

	gawk '{print substr($0,length,1)}' mothur.list.temp | if grep -q ","; then
	a=$(cat mothur.list.temp)
	echo "${a::-1}" > mothur.list
	rm mothur.list.temp

	else
	cp mothur.list.temp mothur.list
	fi

grep -c "" < $cluster_file | sed 's/^/0.03\t/' > OTUnr.temp 
cat OTUnr.temp mothur.list > mothur_with_count.temp && rm OTUnr.temp
tr "\n" "\t" < mothur_with_count.temp > mothur_with_count.list && rm mothur_with_count.temp
			if [ "$?" = "0" ]; then
			echo ""
			else
			touch ${USER_HOME}/.var_babitas/OTU_table_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi



#Make OTU table
echo "Making OTU table"
python ${USER_HOME}/.babitassh/Finding_groups.py > groups.temp
			if [ "$?" = "0" ]; then
			rm groups.temp
			else
			touch ${USER_HOME}/.var_babitas/OTU_table_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi


mothur "#make.shared(list=mothur_with_count.list, group=Final.groups)" | tee lastlog.txt
			if grep -q 'ERROR' lastlog.txt; then
 			echo "ERROR occurred, examine lastlog.txt" && echo "Close this window" && touch ${USER_HOME}/.var_babitas/OTU_table_error.txt  && exit
			else
			echo ""
			fi


#Transpose OTU table
	#delete label column and numOTUs column
gawk 'FS=OFS="\t" {$1="";$3="";print}' mothur_with_count.shared | \
	#Transpoe
gawk '
{ 
    for (i=1; i<=NF; i++)  {
        a[NR,i] = $i
    }
}
NF>p { p = NF }
END {    
    for(j=1; j<=p; j++) {
        str=a[1,j]
        for(i=2; i<=NR; i++){
            str=str" "a[i,j];
        }
        print str
    }
}' | sed -e 's/ /\t/g' > OTU_TABLE.txt
			if [ "$?" = "0" ]; then
			echo "# Created OTU_TABLE.txt"
			else
			touch ${USER_HOME}/.var_babitas/OTU_table_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi


echo ""




			if [ "$?" = "0" ]; then
			touch ${USER_HOME}/.var_babitas/OTU_table_finished.txt
			rm mothur.list.temp
			echo ""
			echo "##########################"
			echo "DONE"
			echo "#############################"
			echo "OTU table output = OTU_TABLE.txt"
			echo "###################################"
			echo "You may close this window now!"
			else
			touch ${USER_HOME}/.var_babitas/OTU_table_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
			fi




#Delete mothur_logfiles
if ls mothur.*.logfile 1> /dev/null 2>&1; then
	rm *.logfile
fi



