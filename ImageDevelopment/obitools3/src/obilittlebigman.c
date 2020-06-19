/****************************************************************************
 * Code for endianness checking                                             *
 ****************************************************************************/

/**
 * @file obilittlebigman.c
 * @author Eric Coissac (eric.coissac@metabarcoding.org)
 * @date 23 May 2015
 * @brief Code endianness checking.
 */

#include "obilittlebigman.h"


// TODO this function does not seem to work properly
bool obi_is_little_endian() {
    union { int entier;
            char caractere[4] ;
    } test;

    test.entier=0x01020304;

    return (test.caractere[3] == 1);
}

