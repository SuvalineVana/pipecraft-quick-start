#load dada2
library("dada2")

#check for lingering output dir and delete if needed
if (dir.exists("/input/dada2-quality-filter-output")) {
    unlink("/input/dada2-quality-filter-output", recursive=TRUE)
}

#create new output dir
dir.create('/input/dada2-quality-filter-output')

#load environment variables
maxEE = Sys.getenv('maxEE')
maxN = Sys.getenv('maxN')
truncQ = Sys.getenv('truncQ')
truncLen = Sys.getenv('truncLen')
minLen = Sys.getenv('minLen')
maxLen = Sys.getenv('maxLen')
minQ = Sys.getenv('minQ')

#define input and output file paths
input = list.files(pattern = "fastq")
output = paste('/input/dada2-quality-filter-output/',input, sep="")

#save parameters to comma separated string
library(stringr)
parameters = paste(maxEE, maxN, truncQ, truncLen, minLen, maxLen, minQ, sep=', ')
parameters = str_replace_all(parameters, ', ,', ',')

#construct the full command for execution
command = paste('out <-','filterAndTrim(','input','output','rev=NULL','filt.rev=NULL',parameters,'compress=FALSE','verbose=TRUE)', sep=", ")
command = str_replace(command, ', ', ' ')
command = str_replace(command, ', ', '')

#turns string into an expression, and evaluates the expression.
eval(parse(text = command))

#show stats
command
head(out)
