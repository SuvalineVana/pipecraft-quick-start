#ifndef ECOPCR_H_
#define ECOPCR_H_

#include <stdio.h>
#include <inttypes.h>

#include "../obidmscolumn.h"
#include "../obiview.h"
#include "../obitypes.h"

#ifndef H_apat
#include "./libapat/apat.h"
#endif

/*****************************************************
 * 
 *  Data type declarations
 * 
 *****************************************************/

/*
 * 
 *  Sequence types
 * 
 */

typedef struct {
	
	int32_t  taxid;
	char     AC[20];
	int32_t  DE_length;
	int32_t  SQ_length;
	int32_t  CSQ_length;
	
	char     data[1];
	
} ecoseqformat_t;

typedef struct {
	int32_t taxid;
	int32_t SQ_length;
	char    *AC;
	char    *DE;
	char    *SQ;
} ecoseq_t;

 
/*****************************************************
 * 
 *  Function declarations
 * 
 *****************************************************/

/*
 * 
 * Low level system functions
 * 
 */

int32_t is_big_endian(void);
int32_t swap_int32_t(int32_t);

void   *eco_malloc(int32_t chunksize,
                   const char *error_message,
                   const char *filename,
                   int32_t    line);
                   
                   
void   *eco_realloc(void *chunk,
                    int32_t chunksize,
                    const char *error_message,
                    const char *filename,
                    int32_t    line);
                    
void    eco_free(void *chunk,
                 const char *error_message,
                 const char *filename,
                 int32_t    line);
                 
void    eco_trace_memory_allocation(void);
void    eco_untrace_memory_allocation(void);

#define ECOMALLOC(size,error_message) \
	    eco_malloc((size),(error_message),__FILE__,__LINE__)
	   
#define ECOREALLOC(chunk,size,error_message) \
        eco_realloc((chunk),(size),(error_message),__FILE__,__LINE__)
        
#define ECOFREE(chunk,error_message) \
        eco_free((chunk),(error_message),__FILE__,__LINE__)
        

/*
 * 
 * Error management
 * 
 */
 
  
void ecoError(int32_t,const char*,const char *,int);

#define ECOERROR(code,message) ecoError((code),(message),__FILE__,__LINE__)

#define ECO_IO_ERROR       (1)
#define ECO_MEM_ERROR      (2)
#define ECO_ASSERT_ERROR   (3)
#define ECO_NOTFOUND_ERROR (4)


/*
 * 
 * Low level Disk access functions
 * 
 */


int32_t    delete_apatseq(SeqPtr pseq);
PatternPtr buildPattern(const char *pat, int32_t error_max);
PatternPtr complementPattern(PatternPtr pat);

SeqPtr ecoseq2apatseq(char* sequence, SeqPtr out, int32_t circular);

char *ecoComplementPattern(char *nucAcSeq);
char *ecoComplementSequence(char *nucAcSeq);
char *getSubSequence(char* nucAcSeq,int32_t begin,int32_t end);


#endif /*ECOPCR_H_*/
