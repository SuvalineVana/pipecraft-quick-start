#include "./libapat/libstki.h"
#include "./libapat/apat.h"

#include "ecoPCR.h"

#include <string.h>

#include "../obidmscolumn.h"
#include "../obiview.h"
#include "../obitypes.h"


static void EncodeSequence(SeqPtr seq);
static void UpperSequence(char *seq);

/* -------------------------------------------- */
/* uppercase sequence                           */
/* -------------------------------------------- */

#define IS_LOWER(c) (((c) >= 'a') && ((c) <= 'z'))
#define TO_UPPER(c) ((c) - 'a' + 'A')

void UpperSequence(char *seq)
{
        char *cseq;

        for (cseq = seq ; *cseq ; cseq++) 
            if (IS_LOWER(*cseq))
                *cseq = TO_UPPER(*cseq);
}
 
#undef IS_LOWER
#undef TO_UPPER



/* -------------------------------------------- */
/* encode sequence                              */
/* IS_UPPER is slightly faster than isupper     */
/* -------------------------------------------- */

#define IS_UPPER(c) (((c) >= 'A') && ((c) <= 'Z'))



void EncodeSequence(SeqPtr seq)
{
        int   i;
        UInt8 *data;
        char  *cseq;

        data = seq->data;
        cseq = seq->cseq;

        while (*cseq) {
            *data = (IS_UPPER(*cseq) ? *cseq - 'A' : 0x0);
            data++;
            cseq++;
        }
        
        for (i=0,cseq=seq->cseq;i < seq->circular; i++,cseq++,data++)
            *data = (IS_UPPER(*cseq) ? *cseq - 'A' : 0x0);

        for (i = 0 ; i < MAX_PATTERN ; i++)
            seq->hitpos[i]->top = seq->hiterr[i]->top = 0;
}

#undef IS_UPPER


SeqPtr ecoseq2apatseq(char* sequence, SeqPtr out, int32_t circular)
{
        int     i;
        int32_t seq_len;

		if (!out)
		{
			out = ECOMALLOC(sizeof(Seq),
			                "Error in Allocation of a new Seq structure");

	        for (i  = 0 ; i < MAX_PATTERN ; i++)
	        {

	           if (! (out->hitpos[i] = NewStacki(kMinStackiSize)))
	             	ECOERROR(ECO_MEM_ERROR,"Error in hit stack Allocation");

	           if (! (out->hiterr[i] = NewStacki(kMinStackiSize)))
	            	ECOERROR(ECO_MEM_ERROR,"Error in error stack Allocation");
	        }
		}

		seq_len = strlen(sequence);

		out->seqsiz = out->seqlen = seq_len;
		out->circular = circular;
		
		if (!out->data)
		{
			out->data = ECOMALLOC((out->seqlen+circular) *sizeof(UInt8),
		    	     			  "Error in Allocation of a new Seq data member");    
		   	out->datsiz=  out->seqlen+circular;
		}
		else if ((out->seqlen +circular) >= out->datsiz)
		{
			out->data = ECOREALLOC(out->data,(out->seqlen+circular),
			                      "Error during Seq data buffer realloc");
		   	out->datsiz=  out->seqlen+circular;			                      
		}

		UpperSequence(sequence);    // ecoPCR only works on uppercase
		out->cseq = sequence;
		
		EncodeSequence(out);

        return out;
}


int32_t delete_apatseq(SeqPtr pseq)
{
         int i;

        if (pseq) {

            if (pseq->data) 
            	ECOFREE(pseq->data,"Freeing sequence data buffer");

            for (i = 0 ; i < MAX_PATTERN ; i++) {
                if (pseq->hitpos[i]) FreeStacki(pseq->hitpos[i]);
                if (pseq->hiterr[i]) FreeStacki(pseq->hiterr[i]);
            }

            ECOFREE(pseq,"Freeing apat sequence structure");
            
            return 0;
        }
        
        return 1;
}

PatternPtr buildPattern(const char *pat, int32_t error_max)
{
	PatternPtr pattern;
	int32_t    patlen;
	
	pattern = ECOMALLOC(sizeof(Pattern),
						"Error in pattern allocation");
						
	pattern->ok      = Vrai;
	pattern->hasIndel= Faux;
	pattern->maxerr  = error_max;
	patlen  = strlen(pat);
	
	pattern->cpat    = ECOMALLOC(sizeof(char)*patlen+1,
	                             "Error in sequence pattern allocation");
	                             
	strncpy(pattern->cpat,pat,patlen);
	pattern->cpat[patlen]=0;
	UpperSequence(pattern->cpat);
	
	if (!CheckPattern(pattern))
		ECOERROR(ECO_ASSERT_ERROR,"Error in pattern checking");
		
	if (! EncodePattern(pattern, dna))
		ECOERROR(ECO_ASSERT_ERROR,"Error in pattern encoding");

   	if (! CreateS(pattern, ALPHA_LEN))
		ECOERROR(ECO_ASSERT_ERROR,"Error in pattern compiling");
	
	return pattern;
		
}

PatternPtr complementPattern(PatternPtr pat)
{
	PatternPtr pattern;
	
	pattern = ECOMALLOC(sizeof(Pattern),
						"Error in pattern allocation");

	pattern->ok      = Vrai;
	pattern->hasIndel= pat->hasIndel;
	pattern->maxerr  = pat->maxerr;
	pattern->patlen  = pat->patlen;
	
	pattern->cpat    = ECOMALLOC(sizeof(char)*(strlen(pat->cpat)+1),
	                             "Error in sequence pattern allocation");


	strcpy(pattern->cpat,pat->cpat);

	ecoComplementPattern(pattern->cpat);
	
	if (!CheckPattern(pattern))
		ECOERROR(ECO_ASSERT_ERROR,"Error in pattern checking");
		
	if (! EncodePattern(pattern, dna))
		ECOERROR(ECO_ASSERT_ERROR,"Error in pattern encoding");

   	if (! CreateS(pattern, ALPHA_LEN))
		ECOERROR(ECO_ASSERT_ERROR,"Error in pattern compiling");
	
	return pattern;
		
}
