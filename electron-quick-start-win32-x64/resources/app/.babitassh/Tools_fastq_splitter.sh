#!/bin/bash

echo "### Splitting FASTQ file ###"
echo ""
echo "fastq-splitter v0.1.2"
echo "http://kirill-kryukov.com/study/tools/fastq-splitter"
echo "Distributed under the zlib/libpng license"
echo "________________________________________________"

USER_HOME=$(eval echo ~${SUDO_USER})

#Set working directory
WorkingDirectory=$(awk 'BEGIN{FS=OFS="/"} NF{NF--};1' < ${USER_HOME}/.var_babitas/fastq4.txt)
		if [ "$?" = "0" ]; then
 		echo "Working directory = $WorkingDirectory"
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


#Set input variable
fastq4=$(cat ${USER_HOME}/.var_babitas/fastq4.txt)
		if [ "$?" = "0" ]; then
 		echo ""
		else
		touch ${USER_HOME}/.var_babitas/tools_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi

#Set part-size variable
size=$(cat ${USER_HOME}/.var_babitas/split_size.txt)
		if [ "$?" = "0" ]; then
 		echo ""
		else
		touch ${USER_HOME}/.var_babitas/tools_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi



####################
# Split fastq file #
####################
echo "perl fastq-splitter.pl --part-size $size --measure count $fastq4"
echo ""

perl ${USER_HOME}/.babitassh/fastq-splitter.pl --part-size $size --measure count $fastq4
		if [ "$?" = "0" ]; then
		echo ""
		echo "##########################"
		echo "DONE"
		echo "################################"
		echo "You may close this window now!"
		touch ${USER_HOME}/.var_babitas/tools_finished.txt
		else
		touch ${USER_HOME}/.var_babitas/tools_error.txt && echo "ERROR occured" 1>&2 && echo "Close this window" && exit 1
		fi



