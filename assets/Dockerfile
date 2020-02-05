FROM ubuntu:18.04
ARG DEBIAN_FRONTEND=noninteractive

# Build mothur from scratch
RUN apt-get update -y
RUN apt-get install apt-utils -y
RUN apt install git-all -y 
RUN apt install zlib1g-dev -y
RUN apt install zlib1g -y
RUN apt-get install bzip2 -y
RUN apt-get install wget -y
RUN apt-get install unzip -y
RUN apt-get install libgsl-dev -y
RUN apt-get install libboost-all-dev -y
RUN apt-get install libreadline-dev -y
RUN apt-get install libhdf5-dev -y
RUN wget https://github.com/mothur/mothur/releases/download/v.1.43.0/Mothur.Ubuntu_18.zip
RUN unzip Mothur.Ubuntu_18.zip
RUN apt-get install nano -y
#cutadapt
RUN apt-get install python3.6-dev -y
RUN apt-get install build-essential -y
RUN apt install python3-venv python3-pip -y
RUN python3 -m pip install cutadapt
#trimmomatic
RUN apt-get update -y
RUN apt-get install trimmomatic -y
#R and Dada2
RUN apt-get install software-properties-common -y
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
RUN add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran35/'
RUN apt-get update -y
RUN apt install r-base r-base-dev -y
RUN apt-get -y install libcurl4-openssl-dev libssl-dev libxml2-dev -y
ADD dadaInstall.R /
RUN chmod 777 dadaInstall.R
RUN Rscript dadaInstall.R

#RUN apt install vim -y
#RUN git clone https://github.com/SuvalineVana/mothur
#RUN export CPATH=/usr/include/hdf5/serial/
#RUN cd mothur && make clean && make
#PATH=~/path_to_mothur_binary_folder:${PATH}



# RUN wget https://github.com/mothur/mothur/releases/download/v.1.43.0/Mothur.Ubuntu_18.zip
# RUN unzip Mothur.Ubuntu_18.zip
# RUN apt install libboost-all-dev -y
# RUN wget https://dl.bintray.com/boostorg/release/1.71.0/source/boost_1_71_0.tar.gz
# RUN tar -xzvf boost_1_71_0.tar.gz
# RUN cd boost_1_71_0 && ./bootstrap.sh && ./b2
# bzip2-devel
# RUN git clone https://github.com/mothur/mothur
# RUN git clone https://github.com/boostorg/boost





#CMD  ./RunAnalysis.sh