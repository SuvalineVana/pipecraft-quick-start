/* ---------------------------------------------------------------- */
/* Copyright (c) Atelier de BioInformatique                         */
/* @file: Gmach.h                                                   */
/* @desc: machine dependant setup                                   */
/* @+     *should* be included in all ABI softs                     */
/*                                                                  */
/* @history:                                                        */
/* @+       <Gloup> : Jul 95 : MWC first draft                      */
/* @+       <Gloup> : Jan 96 : adapted to Pwg                       */
/* @+       <Gloup> : Nov 00 : adapted to Mac_OS_X                  */
/* ---------------------------------------------------------------- */

#ifndef _H_Gmach

                        /* OS names             */

#define _H_Gmach

                        /* Macintosh Classic    */
                        /* Think C environment  */
#ifdef THINK_C 
#define MACINTOSH
#define MAC_OS_C
#endif


                        /* Macintosh Classic    */
                        /* Code-Warrior         */
#ifdef __MWERKS__ 
#define MACINTOSH
#define MAC_OS_C
#endif

                        /* Macintosh OS-X       */
#ifdef MAC_OS_X
#define MACINTOSH
#define UNIX
#define UNIX_BSD
#endif

						/* LINUX				*/
#ifdef LINUX
#define UNIX
#define UNIX_BSD
#endif

                        /* other Unix Boxes     */
                        /* SunOS /  Solaris     */      
#ifdef SUN
#define UNIX
#ifdef SOLARIS
#define UNIX_S7
#else
#define UNIX_BSD
#endif
#endif

                        /* SGI Irix             */      
#ifdef SGI
#define UNIX
#define UNIX_S7
#endif

/* ansi setup                           */
/* for unix machines see makefile       */

#ifndef PROTO
#define PROTO 1
#endif

#ifndef ANSI_PROTO
#define ANSI_PROTO PROTO
#endif

#ifndef ANSI_STR
#define ANSI_STR 1
#endif

/* unistd.h header file */

#ifdef UNIX
#define HAS_UNISTD_H <unistd.h>
#endif

/* getopt.h header file */

#ifdef MAC_OS_C
#define HAS_GETOPT_H "getopt.h"
#endif

#ifdef SGI
#define HAS_GETOPT_H <getopt.h>
#endif



#endif
