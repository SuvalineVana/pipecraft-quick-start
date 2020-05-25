/* ==================================================== */
/*      Copyright (c) Atelier de BioInformatique        */
/*      Dec. 94                                         */
/*      File: apat.h                                    */
/*      Purpose: pattern scan                           */
/*      History:                                        */
/*      28/12/94 : <Gloup> ascan first version          */
/*      14/05/99 : <Gloup> last revision                */
/* ==================================================== */


#include <stdbool.h>

#ifndef _H_Gtypes
#include "Gtypes.h"
#endif

#ifndef _H_libstki
#include "libstki.h" 
#endif

#define H_apat

/* ----------------------------------------------- */
/* constantes                                      */
/* ----------------------------------------------- */

#ifndef BUFSIZ
#define BUFSIZ          1024    /* io buffer size               */
#endif

#define MAX_NAME_LEN    BUFSIZ  /* max length of sequence name  */

#define ALPHA_LEN        26     /* alphabet length              */
                                /* *DO NOT* modify              */

#define MAX_PATTERN       4     /* max # of patterns            */
                                /* *DO NOT* modify              */

#define MAX_PAT_LEN      32     /* max pattern length           */
                                /* *DO NOT* modify              */

#define MAX_PAT_ERR      32     /* max # of errors              */
                                /* *DO NOT* modify              */

#define PATMASK 0x3ffffff       /* mask for 26 symbols          */
                                /* *DO NOT* modify              */

#define OBLIBIT 0x4000000       /* bit 27 to 1 -> oblig. pos    */
                                /* *DO NOT* modify              */

                                /* mask for position            */
#define ONEMASK 0x80000000      /* mask for highest position    */

                                /* masks for Levenhstein edit   */
#define OPER_IDT  0x00000000    /* identity                     */
#define OPER_INS  0x40000000    /* insertion                    */
#define OPER_DEL  0x80000000    /* deletion                     */
#define OPER_SUB  0xc0000000    /* substitution                 */

#define OPER_SHFT 30            /* <unused> shift               */

                                /* Levenhstein Opcodes          */
#define SOPER_IDT 0x0           /* identity                     */
#define SOPER_INS 0x1           /* insertion                    */
#define SOPER_DEL 0x2           /* deletion                     */
#define SOPER_SUB 0x3           /* substitution                 */

                                /* Levenhstein Opcodes masks    */
#define OPERMASK  0xc0000000    /* mask for Opcodes             */
#define NOPERMASK 0x3fffffff    /* negate of previous           */

                                /* special chars in pattern     */
#define PATCHARS  "[]!#"

                                /* 26 letter alphabet           */
                                /* in alphabetical order        */

//#define ORD_ALPHA "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

                                /* protein alphabet             */

//#define PROT_ALPHA "ACDEFGHIKLMNPQRSTVWY"

                                /* dna/rna alphabet             */

//#define DNA_ALPHA "ABCDGHKMNRSTUVWXY"


/* ----------------------------------------------- */
/* data structures                                 */
/* ----------------------------------------------- */

                                        /* -------------------- */
typedef enum {                          /* data encoding        */
                                        /* -------------------- */
        alpha = 0,                      /* [A-Z]                */
        dna,                            /* IUPAC DNA            */
        protein                         /* IUPAC proteins       */
} CodType;

                                        /* -------------------- */
typedef struct {                        /* sequence             */
                                        /* -------------------- */
    char      *name;                    /* sequence name        */
    Int32     seqlen;                   /* sequence length      */
    Int32     seqsiz;                   /* sequence buffer size */
    Int32     datsiz;                   /* data buffer size     */
    Int32     circular;
    UInt8     *data;                    /* data buffer          */
    char      *cseq;                    /* sequence buffer      */
    StackiPtr hitpos[MAX_PATTERN];      /* stack of hit pos.    */
    StackiPtr hiterr[MAX_PATTERN];      /* stack of errors      */
} Seq, *SeqPtr;

                                        /* -------------------- */
typedef struct {                        /* pattern              */
                                        /* -------------------- */
    int    patlen;                      /* pattern length       */
    int    maxerr;                      /* max # of errors      */
    char   *cpat;                       /* pattern string       */
    Int32  *patcode;                    /* encoded pattern      */
    UInt32 *smat;                       /* S matrix             */
    UInt32 omask;                       /* oblig. bits mask     */
    bool   hasIndel;                    /* are indels allowed   */
    bool   ok;                          /* is pattern ok        */
} Pattern, *PatternPtr;

/* ----------------------------------------------- */
/* macros                                          */
/* ----------------------------------------------- */

#ifndef NEW
#define NEW(typ)                (typ*)malloc(sizeof(typ)) 
#define NEWN(typ, dim)          (typ*)malloc((unsigned long)(dim) * sizeof(typ))
#define REALLOC(typ, ptr, dim)  (typ*)realloc((void *) (ptr), (unsigned long)(dim) * sizeof(typ))
#define FREE(ptr)               free((void *) ptr)
#endif

/* ----------------------------------------------- */
/* prototypes                                      */
/* ----------------------------------------------- */

                                     /* apat_seq.c */

SeqPtr  FreeSequence     (SeqPtr pseq);
SeqPtr  NewSequence      (void);
int     ReadNextSequence (SeqPtr pseq);
int     WriteSequence    (FILE *filou , SeqPtr pseq);

                                   /* apat_parse.c      */

Int32   *GetCode          (CodType ctype);
int     CheckPattern      (Pattern *ppat);
int     EncodePattern     (Pattern *ppat, CodType ctype);
int     ReadPattern       (Pattern *ppat);
void    PrintDebugPattern (Pattern *ppat);

                                /* apat_search.c        */

int     CreateS           (Pattern *ppat, Int32 lalpha);
Int32   ManberNoErr       (Seq *pseq , Pattern *ppat, int patnum,int begin,int length);
Int32   ManberSub         (Seq *pseq , Pattern *ppat, int patnum,int begin,int length);
Int32   ManberIndel       (Seq *pseq , Pattern *ppat, int patnum,int begin,int length);
Int32   ManberAll         (Seq *pseq , Pattern *ppat, int patnum,int begin,int length);
Int32   NwsPatAlign       (Seq *pseq , Pattern *ppat, Int32 nerr , 
                              Int32 *reslen , Int32 *reserr);

                                   /* apat_sys.c   */

float   UserCpuTime     (int reset);
float   SysCpuTime      (int reset);
char    *StrCpuTime     (int reset);
void    Erreur          (char *msg , int stat);
int     AccessFile      (char *path, char *mode);

