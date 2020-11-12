FROM ubuntu:18.04
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get upgrade \
    && apt-get update -y --fix-missing \
    && apt-get install -y pigz \
    && apt-get install wget -y \
    && apt-get install libreadline7 -y \
    && apt-get install unzip -y \
    && wget https://github.com/mothur/mothur/releases/download/v.1.43.0/Mothur.Ubuntu_18.zip \
    && unzip Mothur.Ubuntu_18.zip \
    && rm Mothur.Ubuntu_18.zip \
    && rm -r /var/lib/apt/lists/* \
    && wget https://github.com/shenwei356/seqkit/releases/download/v0.14.0/seqkit_linux_amd64.tar.gz \
    && tar -zxvf seqkit_linux_amd64.tar.gz \
    && cp seqkit /usr/local/bin/ \
    && apt-get update -y --fix-missing \
    && apt-get install -y python3 \
    && apt-get install -y python3-pip \
    && pip3 install biopython \
    && apt-get install gawk -y \
    && apt-get install rename -y \
    && apt-get remove wget -y && apt-get remove unzip -y

ENV PATH "$PATH:/mothur"
