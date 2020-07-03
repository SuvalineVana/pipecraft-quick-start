#include <string.h>
#include "ecoPCR.h"

/*
 * @doc: DNA alphabet (IUPAC)
 */
#define LX_BIO_DNA_ALPHA   "ABCDEFGHIJKLMNOPQRSTUVWXYZ#![]"

/*
 * @doc: complementary DNA alphabet (IUPAC)
 */
#define LX_BIO_CDNA_ALPHA  "TVGHEFCDIJMLKNOPQYSAABWXRZ#!]["


static char sNuc[]     = LX_BIO_DNA_ALPHA;
static char sAnuc[]    = LX_BIO_CDNA_ALPHA;

static char LXBioBaseComplement(char nucAc);
static char *LXBioSeqComplement(char *nucAcSeq);
static char *reverseSequence(char *str,char isPattern);

 
/* ---------------------------- */

char LXBioBaseComplement(char nucAc)
{
    char *c;

    if ((c = strchr(sNuc, nucAc)))
        return sAnuc[(c - sNuc)];
    else
        return nucAc;
}

/* ---------------------------- */

char *LXBioSeqComplement(char *nucAcSeq)
{
    char *s;

    for (s = nucAcSeq ; *s ; s++)
        *s = LXBioBaseComplement(*s);

    return nucAcSeq;
}


char *reverseSequence(char *str,char isPattern)
{
        char *sb, *se, c;

        if (! str)
            return str;
            
        sb = str;
        se = str + strlen(str) - 1;

        while(sb <= se) {
           c    = *sb;
          *sb++ = *se;
          *se-- = c;
        }

		sb = str;
		se = str + strlen(str) - 1;
		
		if (isPattern)
			for (;sb < se; sb++)
			{
				if (*sb=='#')
				{
					if (((se - sb) > 2) && (*(sb+2)=='!'))
					{
						*sb='!';
						sb+=2;
						*sb='#';
					}
					else
					{
						*sb=*(sb+1);
						sb++;
						*sb='#';
					}
				}
				else if (*sb=='!')
					{
						*sb=*(sb-1);
						*(sb-1)='!';
					}
			}

        return str;
}

char *ecoComplementPattern(char *nucAcSeq)
{
    return reverseSequence(LXBioSeqComplement(nucAcSeq),1);
}

char *ecoComplementSequence(char *nucAcSeq)
{
    return reverseSequence(LXBioSeqComplement(nucAcSeq),0);
}


char *getSubSequence(char* nucAcSeq,int32_t begin,int32_t end)
/*
   extract subsequence from nucAcSeq [begin,end[
*/
{
	static char *buffer  = NULL;
	static int32_t buffSize= 0;
	int32_t length;
	
	if (begin < end)
	{
		length = end - begin;
		
		if (length >= buffSize)
		{
			buffSize = length+1;
			if (buffer)
				buffer=ECOREALLOC(buffer,buffSize,
						   	      "Error in reallocating sub sequence buffer");
			else
				buffer=ECOMALLOC(buffSize,
				          		 "Error in allocating sub sequence buffer");
				
		}
		
		strncpy(buffer,nucAcSeq + begin,length);
		buffer[length]=0;
	}
	else
	{
		length = end + strlen(nucAcSeq) - begin;
		
		if (length >= buffSize)
		{
			buffSize = length+1;
			if (buffer)
				buffer=ECOREALLOC(buffer,buffSize,
						   	      "Error in reallocating sub sequence buffer");
			else
				buffer=ECOMALLOC(buffSize,
				          		 "Error in allocating sub sequence buffer");
				
		}
		strncpy(buffer,nucAcSeq+begin,length - end);
		strncpy(buffer+(length-end),nucAcSeq ,end);
		buffer[length]=0;
	}
	
	return buffer;
}

