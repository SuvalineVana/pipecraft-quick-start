/* ==================================================== */
/*      Copyright (c) Atelier de BioInformatique        */
/*      Mar. 92                                         */
/*      File: apat_parse.c                              */
/*      Purpose: Codage du pattern                      */
/*      History:                                        */
/*      00/07/94 : <Gloup> first version (stanford)     */
/*      00/11/94 : <Gloup> revised for DNA/PROTEIN      */
/*      30/12/94 : <Gloup> modified EncodePattern       */
/*                         for manber search            */
/*      14/05/99 : <Gloup> indels added                 */
/* ==================================================== */

#include <ctype.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "Gtypes.h"
#include "apat.h"
                                /* -------------------- */
                                /* default char         */
                                /* encodings            */
                                /* -------------------- */

static Int32 sDftCode[]  =  {

#include "CODES/dft_code.h"

};
                                /* -------------------- */
                                /* char encodings       */
                                /* IUPAC                */
                                /* -------------------- */

                                /* IUPAC Proteins       */
static Int32 sProtCode[]  =  {

#include "CODES/prot_code.h"

};
                                /* IUPAC Dna/Rna        */
static Int32 sDnaCode[]  =  {

#include "CODES/dna_code.h"

};


/* -------------------------------------------- */
/* internal replacement of gets                 */
/* -------------------------------------------- */
static char *sGets(char *buffer, int size) {
        
        char *ebuf;

        if (! fgets(buffer, size-1, stdin))
           return NULL;

        /* remove trailing line feed */

        ebuf = buffer + strlen(buffer); 

        while (--ebuf >= buffer) {
           if ((*ebuf == '\n') || (*ebuf == '\r'))
                *ebuf = '\000';
           else
                break;
        }

        return buffer;
}

/* -------------------------------------------- */
/* returns actual code associated to type       */
/* -------------------------------------------- */

Int32 *GetCode(CodType ctype)
{
        Int32 *code = sDftCode;

        switch (ctype) {
           case dna     : code = sDnaCode  ; break;
           case protein : code = sProtCode ; break;
           default      : code = sDftCode  ; break;
        }

        return code;
}

/* -------------------------------------------- */

#define BAD_IF(tst)   if (tst)  return 0

int CheckPattern(Pattern *ppat)
{
        int lev;
        char *pat;

        pat = ppat->cpat;
        
        BAD_IF (*pat == '#');

        for (lev = 0; *pat ; pat++)

            switch (*pat) {

                case '[' :
                   BAD_IF (lev);
                   BAD_IF (*(pat+1) == ']');
                   lev++;
                   break;

                case ']' :
                   lev--;
                   BAD_IF (lev);
                   break;

                case '!' :
                   BAD_IF (lev);
                   BAD_IF (! *(pat+1));
                   BAD_IF (*(pat+1) == ']');
                   break;

                case '#' :
                   BAD_IF (lev);
                   BAD_IF (*(pat-1) == '[');
                   break;

                default :
                   if (! isupper(*pat))
                        return 0;
                   break;
            }

        return (lev ? 0 : 1);
}
 
#undef BAD_IF
           

/* -------------------------------------------- */
static char *skipOblig(char *pat)
{
        return (*(pat+1) == '#' ? pat+1 : pat);
}

/* -------------------------------------------- */
static char *splitPattern(char *pat)
{
        switch (*pat) {
                   
                case '[' :
                   for (; *pat; pat++)
                        if (*pat == ']')
                          return skipOblig(pat);
                   return NULL;
                   break;

                case '!' :
                   return splitPattern(pat+1);
                   break;

        }
        
        return skipOblig(pat);                  
}

/* -------------------------------------------- */
static Int32 valPattern(char *pat, Int32 *code)
{
        Int32 val;
        
        switch (*pat) {
                   
                case '[' :
                   return valPattern(pat+1, code);
                   break;

                case '!' :
                   val = valPattern(pat+1, code);
                   return (~val & PATMASK);
                   break;

                default :
                   val = 0x0;
                   while (isupper(*pat)) {
                       val |= code[*pat - 'A'];
                       pat++;
                   }
                   return val;
        }

        return 0x0;                     
}

/* -------------------------------------------- */
static Int32 obliBitPattern(char *pat)
{
        return (*(pat + strlen(pat) - 1) == '#' ? OBLIBIT : 0x0);
}       
                

/* -------------------------------------------- */
static int lenPattern(char *pat)
{
        int  lpat;

        lpat = 0;
        
        while (*pat) {
        
            if (! (pat = splitPattern(pat)))
                return 0;

            pat++;

            lpat++;
        }

        return lpat;
}

/* -------------------------------------------- */
/* Interface                                    */
/* -------------------------------------------- */

/* -------------------------------------------- */
/* encode un pattern                            */
/* -------------------------------------------- */
int EncodePattern(Pattern *ppat, CodType ctype)
{
        int   pos, lpat;
        Int32 *code;
        char  *pp, *pa, c;

        ppat->ok = Faux;

        code = GetCode(ctype);

        ppat->patlen = lpat = lenPattern(ppat->cpat);
        
        if (lpat <= 0)
            return 0;
        
        if (! (ppat->patcode = NEWN(Int32, lpat)))
            return 0;

        pa = pp = ppat->cpat;

        pos = 0;
        
        while (*pa) {
        
            pp = splitPattern(pa);

            c = *++pp;
            
            *pp = '\000';
                    
            ppat->patcode[pos++] = valPattern(pa, code) | obliBitPattern(pa);
            
            *pp = c;
            
            pa = pp;
        }

        ppat->ok = Vrai;

        return lpat;
}

/* -------------------------------------------- */
/* remove blanks                                */
/* -------------------------------------------- */
static char *RemBlanks(char *s)
{
        char *sb, *sc;

        for (sb = sc = s ; *sb ; sb++)
           if (! isspace(*sb))
                *sc++ = *sb;

        return s;
}

/* -------------------------------------------- */
/* count non blanks                             */
/* -------------------------------------------- */
static Int32 CountAlpha(char *s)
{
        Int32 n;

        for (n = 0 ; *s ; s++)
           if (! isspace(*s))
                n++;

        return n;
}
           
        
/* -------------------------------------------- */
/* lit un pattern                               */
/* <pattern> #mis                               */
/* ligne starting with '/' are comments         */
/* -------------------------------------------- */
int ReadPattern(Pattern *ppat)
{
        int  val;
        char *spac;
        char buffer[BUFSIZ];

        ppat->ok = Vrai;

        if (! sGets(buffer, sizeof(buffer)))
            return 0;

        if (*buffer == '/')
            return ReadPattern(ppat);

        if (! CountAlpha(buffer))
            return ReadPattern(ppat);

        for (spac = buffer ; *spac ; spac++)
            if ((*spac == ' ') || (*spac == '\t'))
                break;

        ppat->ok = Faux;

        if (! *spac)
            return 0;
        
        if (sscanf(spac, "%d", &val) != 1)
            return 0;

        ppat->hasIndel = (val < 0);
        
        ppat->maxerr = ((val >= 0) ? val : -val);

        *spac = '\000';

        (void) RemBlanks(buffer);

        if ((ppat->cpat = NEWN(char, strlen(buffer)+1)))
            strcpy(ppat->cpat, buffer);
        
        ppat->ok = (ppat->cpat != NULL);

        return (ppat->ok ? 1 : 0);
}

/* -------------------------------------------- */
/* ecrit un pattern - Debug -                   */
/* -------------------------------------------- */
void PrintDebugPattern(Pattern *ppat)
{
        int i;

        printf("Pattern  : %s\n", ppat->cpat);
        printf("Encoding : \n\t");

        for (i = 0 ; i < ppat->patlen ; i++) {
            printf("0x%8.8x ", ppat->patcode[i]);
            if (i%4 == 3)
                printf("\n\t");
        }
        printf("\n");
}

