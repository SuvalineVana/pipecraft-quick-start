#!/bin/bash
#demuxbyname in=<infile> out=<outfile>

function usage(){
echo "
Written by Brian Bushnell
Last modified April 14, 2015

Description:  Demultiplexes reads based on their name (suffix or prefix) into multiple files.

Usage:  demuxbyname.sh in=<file> in2=<file2> out=<outfile> out2=<outfile2> names=<string,string,string...>

in2 and out2 are for paired reads and are optional.
If input is paired and there is only one output file, it will be written interleaved.
Output filenames MUST contain a '%' symbol.

Parameters and their defaults:

in=<file>           Input file.
out=<file>          Output files for reads with matched names.
outu=<file>         Output file for reads with unmatched names.
prefixmode=t        (pm) Match prefix of read name.  If false, match suffix of read name.
names=              List of strings (or files containing strings) to parse from read names.
length=0            If positive, use a suffix or prefix of this length from read name instead of or in addition to the list of names.
ow=f                (overwrite) Overwrites files that already exist.
app=f               (append) Append to files that already exist.
zl=4                (ziplevel) Set compression level, 1 (low) to 9 (max).
int=f               (interleaved) Determines whether INPUT file is considered interleaved.
fastawrap=80        Length of lines in fasta output.
fastareadlen=0      Set to a non-zero number to break fasta files into reads of at most this length.
minscaf=1           Ignore fasta reads shorter than this.
tuc=f               (touppercase) Change lowercase letters in reads to uppercase.
qin=auto            ASCII offset for input quality.  May be 33 (Sanger), 64 (Illumina), or auto.
qout=auto           ASCII offset for output quality.  May be 33 (Sanger), 64 (Illumina), or auto (same as input).
qfake=30            Quality value used for fasta to fastq demuxbynameting.
tossbrokenreads=f   (tbr) Discard reads that have different numbers of bases and qualities.  By default this will be detected and cause a crash.
ignorebadquality=f  (ibq) Fix out-of-range quality values instead of crashing with a warning.

Java Parameters:
-Xmx                This will be passed to Java to set memory usage, overriding the program's automatic memory detection.
                    -Xmx20g will specify 20 gigs of RAM, and -Xmx200m will specify 200 megs.  The max is typically 85% of physical memory.

Supported input formats are fastq, fasta, fast+qual, scarf, and bread (BBMap's native format)
Supported output formats are fastq, fasta, fast+qual, bread, sam, and bam (bam only if samtools is installed)
Supported compression formats are gz, zip, and bz2
To read from stdin, set 'in=stdin'.  The format should be specified with an extension, like 'in=stdin.fq.gz'
To write to stdout, set 'out=stdout'.  The format should be specified with an extension, like 'out=stdout.fasta'

Please contact Brian Bushnell at bbushnell@lbl.gov if you encounter any problems.
"
}

pushd . > /dev/null
DIR="${BASH_SOURCE[0]}"
while [ -h "$DIR" ]; do
  cd "$(dirname "$DIR")"
  DIR="$(readlink "$(basename "$DIR")")"
done
cd "$(dirname "$DIR")"
DIR="$(pwd)/"
popd > /dev/null

#DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/"
CP="$DIR""current/"

z="-Xmx400m"
EA="-ea"
set=0

if [ -z "$1" ] || [[ $1 == -h ]] || [[ $1 == --help ]]; then
	usage
	exit
fi

calcXmx () {
	source "$DIR""/calcmem.sh"
	parseXmx "$@"
}
calcXmx "$@"

function demuxbyname() {
	if [[ $NERSC_HOST == genepool ]]; then
		module unload oracle-jdk
		module unload samtools
		module load oracle-jdk/1.7_64bit
		module load pigz
		module load samtools
	fi
	local CMD="java $EA $z -cp $CP jgi.DemuxByName $@"
	echo $CMD >&2
	eval $CMD
}

demuxbyname "$@"
