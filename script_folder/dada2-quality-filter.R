a = Sys.getenv('ENV_FILE_TEST')
library("dada2")

if (dir.exists("/input/dada2-quality-filter-output")) {
    unlink("/input/dada2-quality-filter-output", recursive=TRUE)
}

dir.create('/input/dada2-quality-filter-output')

maxEE = Sys.getenv('maxEE')
maxN = Sys.getenv('maxN')
truncQ = Sys.getenv('truncQ')
truncLen = Sys.getenv('truncLen')
minLen = Sys.getenv('minLen')
maxLen = Sys.getenv('maxLen')
minQ = Sys.getenv('minQ')

x = iconv(maxEE, from = '', to = 'UTF-8')
x
Encoding(x)

library(stringr)
parameters = paste(maxEE, maxN, truncQ, truncLen, minLen, maxLen, minQ, sep=',')
parameters = str_replace_all(parameters, ',,', ',')
Encoding(parameters)



# input = list.files(pattern = "fastq")
# output = paste('/input/dada2-quality-filter-output/',input, sep="")
# out <- filterAndTrim(input, output, rev = NULL, filt.rev = NULL, maxEE, compress=FALSE)
# head(out)


# readRenviron("C:/Users/m_4_r/Desktop/materializeDEMO/pipecraft-quick-start/env_files/dada2-quality-filter.env")