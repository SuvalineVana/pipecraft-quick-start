/* ==================================================== */
/*      Copyright (c) Atelier de BioInformatique        */
/*      Mar. 92                                         */
/*      File: libstki.c                                 */
/*      Purpose: A library to deal with 'stacks' of     */
/*               integers                               */
/*      Note: 'stacks' are dynamic (i.e. size is        */
/*            automatically readjusted when needed)     */
/*      History:                                        */
/*      00/03/92 : <Gloup> first draft                  */
/*      15/08/93 : <Gloup> revised version              */
/*      14/05/99 : <Gloup> last revision                */
/* ==================================================== */

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>

#include "Gtypes.h"
#include "libstki.h"


/* ============================ */
/* Constantes et Macros locales */
/* ============================ */

#define ExpandStack(stkh) ResizeStacki((stkh), (*stkh)->size << 1)

#define ShrinkStack(stkh) ResizeStacki((stkh), (*stkh)->size >> 1)


static Int16 sStkiLastError = kStkiNoErr;

/* -------------------------------------------- */
/* gestion des erreurs                          */
/* get/reset erreur flag                        */
/*                                              */
/* @function: StkiError                         */
/* -------------------------------------------- */

Int16 StkiError(bool reset)
{
        Int16 err;
        
        err = sStkiLastError;
        
        if (reset)
           sStkiLastError = kStkiNoErr;
           
        return err;
        
} /* end of StkiError */

/* -------------------------------------------- */
/* creation d'un stack                          */
/*                                              */
/* @function: NewStacki                         */
/* -------------------------------------------- */

StackiPtr NewStacki(Int32 size)
{
        StackiPtr stki;
        
        if (! (stki = NEW(Stacki)))
                return NULL;

        stki->size    = size;
        stki->top     = 0;
        stki->cursor  = 0;
        
        if ( ! (stki->val = NEWN(Int32, size))) {
            sStkiLastError = kStkiMemErr;
            return FreeStacki(stki);
        }

        return stki;    
                        
} /* end of NewStacki */


/* -------------------------------------------- */
/* liberation d'un stack                        */
/*                                              */
/* @function: FreeStacki                        */
/* -------------------------------------------- */

StackiPtr FreeStacki(StackiPtr stki)
{
        if (stki) {
            if (stki->val)
                FREE(stki->val);
            FREE(stki);
        }
        
        return NULL;
        
} /* end of FreeStacki */

/* -------------------------------------------- */
/* creation d'un vecteur de stacks              */
/*                                              */
/* @function: NewStackiVector                   */
/* -------------------------------------------- */

StackiHdle NewStackiVector(Int32 vectSize, Int32 stackSize)
{
        Int32           i;
        StackiHdle      stkh;
        
        if (! (stkh = NEWN(StackiPtr, vectSize))) {
            sStkiLastError = kStkiMemErr;
            return NULL;
        }
        
        for (i = 0 ; i < vectSize ; i++)
            if (! (stkh[i] = NewStacki(stackSize)))
                return FreeStackiVector(stkh, i);
            
        return stkh;
        
} /* end of NewStackiVector */


/* -------------------------------------------- */
/* liberation d'un vecteur de stacks            */
/*                                              */
/* @function: FreeStackiVector                  */
/* -------------------------------------------- */

StackiHdle FreeStackiVector(StackiHdle stkh, Int32 vectSize)
{
        Int32   i;
        
        if (stkh) {
            for (i = 0 ; i < vectSize ; i++)
                (void) FreeStacki(stkh[i]);
            FREE(stkh);
        }

        return NULL;
                
} /* end of FreeStackiVector */

/* -------------------------------------------- */
/* resize d'un stack                            */
/*                                              */
/* @function: ResizeStacki                      */
/* -------------------------------------------- */

Int32 ResizeStacki(StackiHdle stkh, Int32 size)
{
        Int32 resize = 0;               /* assume error         */
        Int32 *val;
        
        if ((val = REALLOC(Int32, (*stkh)->val, size))) {
            (*stkh)->size = resize = size;
            (*stkh)->val = val;
        }

        if (! resize)
            sStkiLastError = kStkiMemErr;

        return resize;
        
} /* end of ResizeStacki */

/* -------------------------------------------- */
/* empilage(/lement)                            */
/*                                              */
/* @function: PushiIn                           */
/* -------------------------------------------- */

bool PushiIn(StackiHdle stkh, Int32 val)
{
        if (((*stkh)->top >= (*stkh)->size) && (! ExpandStack(stkh)))
            return Faux;

        (*stkh)->val[((*stkh)->top)++] = val;

        return Vrai;
        
} /* end of PushiIn */

/* -------------------------------------------- */
/* depilage(/lement)                            */
/*                                              */
/* @function: PopiOut                           */
/* -------------------------------------------- */

bool PopiOut(StackiHdle stkh, Int32 *val)
{
        if ((*stkh)->top <= 0)
            return Faux;
        
        *val = (*stkh)->val[--((*stkh)->top)];

        if (    ((*stkh)->top < ((*stkh)->size >> 1)) 
             && ((*stkh)->top > kMinStackiSize))

            (void) ShrinkStack(stkh);

        return Vrai;
        
} /* end of PopiOut */
                
/* -------------------------------------------- */
/* lecture descendante                          */
/*                                              */
/* @function: ReadiDown                         */
/* -------------------------------------------- */

bool ReadiDown(StackiPtr stki, Int32 *val)
{
        if (stki->cursor <= 0)
            return Faux;
                
        *val = stki->val[--(stki->cursor)];
        
        return Vrai;
        
} /* end of ReadiDown */

/* -------------------------------------------- */
/* lecture ascendante                           */
/*                                              */
/* @function: ReadiUp                           */
/* -------------------------------------------- */

bool ReadiUp(StackiPtr stki, Int32 *val)
{
        if (stki->cursor >= stki->top)
            return Faux;
                
        *val = stki->val[(stki->cursor)++];
        
        return Vrai;
        
} /* end of ReadiUp */

/* -------------------------------------------- */
/* remontee/descente du curseur                 */
/*                                              */
/* @function: CursiToTop                        */
/* @function: CursiToBottom                     */
/* -------------------------------------------- */

void CursiToTop(StackiPtr stki)
{
        stki->cursor = stki->top;

} /* end of CursiToTop */

void CursiToBottom(stki)
        StackiPtr stki;
{
        stki->cursor = 0;

} /* end of CursiToBottom */

/* -------------------------------------------- */
/* echange des valeurs cursor <-> (top - 1)     */
/*                                              */
/* @function: CursiSwap                         */
/* -------------------------------------------- */

void CursiSwap(StackiPtr stki)
{
        Int32   tmp;
        
        if ((stki->top <= 0) || (stki->cursor < 0))
            return;
        
        tmp = stki->val[stki->cursor];
        stki->val[stki->cursor] = stki->val[stki->top - 1];
        stki->val[stki->top - 1] = tmp;
        
} /* end of CursiSwap */

/* -------------------------------------------- */
/* Recherche d'une valeur en stack a partir du  */
/* curseur courant en descendant.               */
/* on laisse le curseur a l'endroit trouve      */
/*                                              */
/* @function: SearchDownStacki                  */
/* -------------------------------------------- */

bool SearchDownStacki(StackiPtr stki, Int32 sval)
{
        Int32   val;
        bool    more;
        
        while ((more = ReadiDown(stki, &val)))
            if (val == sval) 
                break;
        
        return more;
        
} /* end of SearchDownStacki */

/* -------------------------------------------- */
/* Recherche dichotomique d'une valeur en stack */
/* le stack est suppose trie par valeurs        */
/* croissantes.                                 */
/* on place le curseur a l'endroit trouve       */
/*                                              */
/* @function: BinSearchStacki                   */
/* -------------------------------------------- */

bool BinSearchStacki(StackiPtr stki, Int32 sval)
{
        Int32   midd, low, high, span;

        low  = 0;
        high = stki->top - 1;
        
        while (high >= low) {   

            midd = (high + low) / 2;

            span = stki->val[midd] - sval;

            if (span == 0) {
                stki->cursor = midd;
                return Vrai;
            }
        
            if (span > 0)
                high = midd - 1;
            else
                low  = midd + 1;
        }

        return Faux;
        
} /* end of BinSearchStacki */

/* -------------------------------------------- */
/* teste l'egalite *physique* de deux stacks    */
/*                                              */
/* @function: SameStacki                        */
/* -------------------------------------------- */

bool SameStacki(StackiPtr stki1, StackiPtr stki2)
{
        if (stki1->top != stki2->top) 
            return Faux;
        
        return ((memcmp(stki1->val, stki2->val, 
                        stki1->top * sizeof(Int32)) == 0) ? Vrai : Faux);
                        
} /* end of SameStacki */


/* -------------------------------------------- */
/* inverse l'ordre des elements dans un stack   */
/*                                              */
/* @function: ReverseStacki                     */
/* -------------------------------------------- */

bool ReverseStacki(StackiPtr stki)
{
        Int32   *t, *b, swp;

        if (stki->top <= 0) 
            return Faux;
        
        b = stki->val;
        t = b + stki->top - 1;

        while (t > b) {
             swp  = *t;
             *t-- = *b;
             *b++ = swp;
        }

        return Vrai;
        
} /* end of ReverseStacki */

