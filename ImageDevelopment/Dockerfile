FROM ubuntu:18.04
RUN apt-get update
RUN apt-get dist-upgrade -y
RUN DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install software-properties-common
RUN DEBIAN_FRONTEND=noninteractive apt-add-repository ppa:neufeldlab/ppa
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y pandaseq