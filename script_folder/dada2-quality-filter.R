a = Sys.getenv('ENV_FILE_TEST')
library("dada2")
getwd()

if (dir.exists("/input/dada2-quality-filter-output")) {
    unlink("/input/dada2-quality-filter-output", recursive=TRUE)
}

dir.create('/input/dada2-quality-filter-output')

truncLen = Sys.getenv('truncLen')
truncQ = Sys.getenv('truncQ')
maxLen = Sys.getenv('maxLen')
minLen = Sys.getenv('minLen')
maxEE = Sys.getenv('maxEE')
maxN = Sys.getenv('maxN')
minQ = Sys.getenv('minQ')

input = list.files(pattern = "fastq")

for (fastq in input)
{
    output = paste('/input/dada2-quality-filter-output/',fastq, sep="")
    out <- filterAndTrim(fastq, output, rev = NULL, filt.rev = NULL, truncLen, maxN, maxEE, truncQ, minLen, minQ, maxLen)
    print(fastq)
    head(out)
}