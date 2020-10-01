FROM alpine:3.10
RUN apk add wget
RUN apk add perl 
RUN apk add build-base
RUN wget http://eddylab.org/software/hmmer/hmmer.tar.gz 
RUN tar zxf hmmer.tar.gz
RUN apk add python3
RUN cd hmmer-3.3.1 \
    && ./configure \
    && make \
    && make check \
    && make install
RUN wget https://github.com/carden24/V-Xtractor/blob/master/vxtractor.pl