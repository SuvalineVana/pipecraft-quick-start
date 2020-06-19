def __addInputOption(optionManager):
    
    optionManager.add_argument(
                    dest='obi:inputURI',  
                    metavar='INPUT', 
                    help='Data source URI')
    

    group = optionManager.add_argument_group("Restriction to a sub-part options",
                    "Allows to limit analysis to a sub-part of the input")

    group.add_argument('--skip',
                     action="store", dest="obi:skip",
                     metavar='<N>',
                     default=None,
                     type=int,
                     help="skip the N first sequences")

    group.add_argument('--only',
                     action="store", dest="obi:only",
                     metavar='<N>',
                     default=None,
                     type=int,
                     help="treat only N sequences")
    

def __addImportInputOption(optionManager):
    group = optionManager.add_argument_group("Input format options for imported files")

    group.add_argument('--fasta-input',
                     action="store_const", dest="obi:inputformat",
                     default=None,
                     const=b'fasta',
                     help="Input file is in sanger fasta format")

    group.add_argument('--fastq-input',
                     action="store_const", dest="obi:inputformat",
                     default=None,
                     const=b'fastq',
                     help="Input file is in fastq format")

    group.add_argument('--embl-input',
                     action="store_const", dest="obi:inputformat",
                     default=None,
                     const=b'embl',
                     help="Input file is in embl nucleic format")

    group.add_argument('--genbank-input',
                     action="store_const", dest="obi:inputformat",
                     default=None,
                     const=b'genbank',
                     help="Input file is in genbank nucleic format")

    group.add_argument('--ngsfilter-input',
                     action="store_const", dest="obi:inputformat",
                     default=None,
                     const=b'ngsfilter',
                     help="Input file is an ngsfilter file. If not using tags, use ':' or 'None:None' or '-:-' or any combination")

    group.add_argument('--ecopcr-result-input',
                     action="store_const", dest="obi:inputformat",
                     default=None,
                     const=b'ecopcr',
                     help="Input file is the result of an ecoPCR (version 2)")

    group.add_argument('--ecoprimers-result-input',
                     action="store_const", dest="obi:inputformat",
                     default=None,
                     const=b'ecoprimers',
                     help="Input file is the result of an ecoprimers")

    group.add_argument('--tabular-input',
                     action="store_const", dest="obi:inputformat",
                     default=None,
                     const=b'tabular',
                     help="Input file is a tabular file")

    group.add_argument('--no-skip-on-error',
                     action="store_false", dest="obi:skiperror",
                     default=True,
                     help="Don't skip sequence entries with parsing errors (default: they are skipped)")

    group.add_argument('--no-quality',
                     action="store_true", dest="obi:noquality",
                     default=False,
                     help="Do not import fastQ quality")

    group.add_argument('--quality-sanger',
                     action="store_const", dest="obi:qualityformat",
                     default=None,
                     const=b'sanger',
                     help="Fastq quality is encoded following sanger format (standard fastq)")

    group.add_argument('--quality-solexa',
                     action="store_const", dest="obi:qualityformat",
                     default=None,
                     const=b'solexa',
                     help="Fastq quality is encoded following solexa sequencer format")

    group.add_argument('--nuc',
                     action="store_const", dest="obi:moltype",
                     default=None,
                     const=b'nuc',
                     help="Input file contains nucleic sequences")
    
    group.add_argument('--prot',
                     action="store_const", dest="obi:moltype",
                     default=None,
                     const=b'pep',
                     help="Input file contains protein sequences")

    group.add_argument('--input-na-string',
                     action="store", dest="obi:inputnastring",
                     default="NA",
                     type=str,
                     help="String associated with Non Available (NA) values in the input")


def __addTabularOption(optionManager):
    group = optionManager.add_argument_group("Input and output format options for tabular files")

    group.add_argument('--header',
                     action="store_true", dest="obi:header",
                     default=False,
                     help="First line of tabular file contains column names")

    group.add_argument('--sep',
                     action="store", dest="obi:sep",
                     default="\t",
                     type=str,
                     help="Column separator")


def __addTabularInputOption(optionManager):
    group = optionManager.add_argument_group("Input format options for tabular files")
    
    __addTabularOption(optionManager)
    
    group.add_argument('--dec',
                     action="store", dest="obi:dec",
                     default=".",
                     type=str,
                     help="Decimal separator")
    
    group.add_argument('--strip-white',
                     action="store_false", dest="obi:stripwhite",
                     default=True,
                     help="Remove white chars at the beginning and the end of values")

    group.add_argument('--blank-line-skip',
                     action="store_false", dest="obi:blanklineskip",
                     default=True,
                     help="Skip empty lines")

    group.add_argument('--comment-char',
                     action="store", dest="obi:commentchar",
                     default="#",
                     type=str,
                     help="Lines starting by this char are considered as comment")


def __addTaxdumpInputOption(optionManager):  # TODO maybe not the best way to do it
    group = optionManager.add_argument_group("Input format options for taxdump")

    group.add_argument('--taxdump',
                     action="store_true", dest="obi:taxdump",
                     default=False,
                     help="Whether the input is a taxdump")


def __addTaxonomyOption(optionManager):
    group = optionManager.add_argument_group("Input format options for taxonomy")

    group.add_argument('--taxonomy',
                     action="store", dest="obi:taxoURI",
                     default=None,
                     help="Taxonomy URI")
    
    #TODO option bool to download taxo if URI doesn't exist


def addMinimalInputOption(optionManager):
    __addInputOption(optionManager)

    
def addImportInputOption(optionManager):
    __addInputOption(optionManager)
    __addImportInputOption(optionManager)


def addTabularInputOption(optionManager):
    __addTabularInputOption(optionManager)


def addTaxonomyOption(optionManager):
    __addTaxonomyOption(optionManager)


def addTaxdumpInputOption(optionManager):
    __addTaxdumpInputOption(optionManager)


def addAllInputOption(optionManager):
    __addInputOption(optionManager)
    __addImportInputOption(optionManager)
    __addTabularInputOption(optionManager)
    __addTaxonomyOption(optionManager)
    __addTaxdumpInputOption(optionManager)    


def __addOutputOption(optionManager):
    
    optionManager.add_argument(
                    dest='obi:outputURI',
                    metavar='OUTPUT', 
                    help='Data destination URI')


def __addDMSOutputOption(optionManager):
    group = optionManager.add_argument_group("Output options for DMS data")

    group.add_argument('--no-create-dms',
                 action="store_true", dest="obi:nocreatedms",
                 default=False,
                 help="Don't create an output DMS if it does not already exist")


def __addEltLimitOption(optionManager):
    group = optionManager.add_argument_group("Option to limit the number of elements per line in columns")
    group.add_argument('--max-elts',
                 action="store", dest="obi:maxelts",
                 metavar='<N>',
                 default=1000000,
                 type=int,
                 help="Maximum number of elements per line in a column "
                      "(e.g. the number of different keys in a dictionary-type "
                      "key from sequence headers). If the number of different keys "
                      "is greater than N, the values are stored as character strings")


def __addExportOutputOption(optionManager):
    group = optionManager.add_argument_group("Output format options for exported files")

    group.add_argument('-o',
                    dest='obi:outputURI',
                    metavar='OUTPUT', 
                    help='Data destination URI')

    group.add_argument('--fasta-output',
                     action="store_const", dest="obi:outputformat",
                     default=None,
                     const=b'fasta',
                     help="Output file is in sanger fasta format")

    group.add_argument('--fastq-output',
                     action="store_const", dest="obi:outputformat",
                     default=None,
                     const=b'fastq',
                     help="Output file is in fastq format")

    group.add_argument('--tab-output',
                     action="store_const", dest="obi:outputformat",
                     default=None,
                     const=b'tabular',
                     help="Output file is in tabular format")

    group.add_argument('--print-na',
                     action="store_true", dest="obi:printna",
                     default=False,
                     help="Print Non Available (NA) values in the output")

    group.add_argument('--output-na-string',
                     action="store", dest="obi:outputnastring",
                     default="NA",
                     type=str,
                     help="String associated with Non Available (NA) values in the output")


def __addNoProgressBarOption(optionManager):
    group = optionManager.add_argument_group("Option to deactivate the display of the progress bar")

    group.add_argument('--no-progress-bar',
                     action="store_true", dest="obi:noprogressbar",
                     default=False,
                     help="Do not display progress bar")


def addMinimalOutputOption(optionManager):
    __addOutputOption(optionManager)
    __addDMSOutputOption(optionManager)


def addTabularOutputOption(optionManager):
    __addTabularOption(optionManager)


def addExportOutputOption(optionManager):
    __addExportOutputOption(optionManager)
    __addTabularOption(optionManager)


def addAllOutputOption(optionManager):
    __addOutputOption(optionManager)
    __addDMSOutputOption(optionManager)
    __addExportOutputOption(optionManager)
    __addTabularOption(optionManager)


def addNoProgressBarOption(optionManager):
    __addNoProgressBarOption(optionManager)
    
def addEltLimitOption(optionManager):
    __addEltLimitOption(optionManager)
    
    