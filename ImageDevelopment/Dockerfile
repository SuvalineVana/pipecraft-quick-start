FROM alpine:3.10
RUN apk add git
RUN apk add autoconf
RUN apk add automake
RUN apk add build-base
RUN git clone https://github.com/torognes/swarm.git
RUN cd swarm && make