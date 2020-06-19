/* ---------------------------------------------------------------- */
/* Copyright (c) Atelier de BioInformatique                         */
/* @file: Gtypes.h                                                  */
/* @desc: general & machine dependant types                         */
/* @+     *should* be included in all ABI softs                     */
/*                                                                  */
/* @history:                                                        */
/* @+       <Gloup> : Jan 91 : MWC first draft                      */
/* @+       <Gloup> : Jul 95 : Gmach addition                       */
/* ---------------------------------------------------------------- */

#define _H_Gtypes

#ifndef _H_Gmach
#include "Gmach.h"
#endif

#ifndef NULL
#include <stdio.h>                      /* is the official NULL here ?  */
#endif

/* ==================================================== */
/* constantes                                           */
/* ==================================================== */

#ifndef PROTO
#define PROTO   1                       /* prototypes flag              */
#endif


#define Vrai    0x1                     /* bool values  = TRUE          */
#define Faux    0x0                     /*              = FALSE         */

#define Nil     NULL                    /* nil pointer                  */

#define kBigInt16       0x7fff          /* plus grand 16 bits signe     */
#define kBigInt32       0x7fffffff      /* plus grand 32 bits signe     */
#define kBigUInt16      0xffff          /* plus grand 16 bits ~signe    */
#define kBigUInt32      0xffffffff      /* plus grand 32 bits ~signe    */


/* ==================================================== */
/*  Types (for Sun & Iris - 32 bits machines)           */
/* ==================================================== */

                                        /* --- specific sizes --------- */
typedef int             Int32;          /* Int32  = 32 bits signe       */
typedef unsigned int    UInt32;         /* UInt32 = 32 bits ~signe      */
typedef short           Int16;          /* Int16  = 16 bits signe       */
typedef unsigned short  UInt16;         /* UInt32 = 16 bits ~signe      */
typedef char            Int8;           /* Int8   = 8 bits signe        */
typedef unsigned char   UInt8;          /* UInt8  = 8 bits ~signe       */

                                        /* --- default types ---------- */

typedef int             Int;            /* 'natural' int (>= 32 bits)   */

typedef void            *Ptr;           /* pointeur                     */



/* ==================================================== */
/*  special macro for prototypes                        */
/* ==================================================== */

#if PROTO
#define         P(s)    s 
#else
#define         P(s)    ()
#endif
