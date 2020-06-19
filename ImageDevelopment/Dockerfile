FROM alpine:3.10
RUN apk add wget
RUN wget https://www.drive5.com/downloads/usearch11.0.667_i86linux32.gz
RUN gunzip usearch11.0.667_i86linux32.gz
RUN chmod 777 usearch11.0.667_i86linux32
RUN mv usearch11.0.667_i86linux32 /bin/usearch