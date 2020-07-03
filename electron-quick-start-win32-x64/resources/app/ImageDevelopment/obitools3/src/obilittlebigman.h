/****************************************************************************
 * Header file for endianness checking                                      *
 ****************************************************************************/

/**
 * @file obilittlebigman.h
 * @author Eric Coissac (eric.coissac@metabarcoding.org)
 * @date 23 May 2015
 * @brief Header file for endianness checking.
 */


#ifndef OBILITTLEBIGMAN_H_
#define OBILITTLEBIGMAN_H_


#include <stdbool.h>


/**
 * Test if the architecture of the processor is little endian.
 *
 * ##Two classes of CPU architecture can be defined:
 * 		- little endian
 * 		- big endian
 *
 * 	They describe the way the processor stores multi-byte values
 * 	in memory. If we consider a 32 bits integer value encoded in
 * 	hexadecimal `0x11223344`, this value needs four bytes to be
 * 	stored. These four bytes will have consecutive addresses in memory.
 * 	Let's say that these addresses will be : 01, 02, 03, and 04
 *
 * 	###A big endian architecture will store our integer with the following schema:
 *
 *	     Address |   01 |   02 |   03 |   04
 *	    ---------|------|------|------|------
 *       value   | Ox11 | Ox22 | 0x33 | 0x44
 *
 *  In this architecture, the last address (the end of the representation) is
 *  used to store the byte of higher weight (BIG ENDian)
 *
 * 	###A little endian architecture will store our integer with the following schema:
 *
 *	     Address |   01 |   02 |   03 |   04
 *	    ---------|------|------|------|------
 *       value   | Ox44 | Ox33 | 0x22 | 0x11
 *
 *  In this architecture, the last address is
 *  used to store the byte of lighter weight (LITTLE ENDian)
 *
 * @returns a `bool` value:
 * 		- `true`  if the architecture is little endian
 * 		- `false` if the architecture is big endian
 *
 * @since May 2015
 * @author Eric Coissac (eric.coissac@metabarcoding.org)
 */
bool obi_is_little_endian(void);


#endif /* OBILITTLEBIGMAN_H_ */
