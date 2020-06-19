/****************************************************************************
 * Encoding header file	                                                    *
 ****************************************************************************/

/**
 * @file encode.h
 * @author Celine Mercier
 * @date November 18th 2015
 * @brief Header file for encoding DNA sequences.
 */


#ifndef ENCODE_H_
#define ENCODE_H_


#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>

#include "obitypes.h"


#define NUC_MASK_2B 0x3   	/**< Binary: 11 to use when decoding 2 bits sequences
 	 	 	 	 	 	 	 */
#define NUC_MASK_4B 0xF  	/**< Binary: 1111 to use when decoding 4 bits sequences
 	 	 	 	 	 	 	 */


/**
 * @brief enum for the 2-bits codes for each of the 4 nucleotides.
 */
enum
{
    NUC_A_2b = 0x0,   /* binary: 00 */
    NUC_C_2b = 0x1,   /* binary: 01 */
    NUC_G_2b = 0x2,   /* binary: 10 */
    NUC_T_2b = 0x3,   /* binary: 11 */
};


/**
 * @brief enum for the 4-bits codes for each of the 15 IUPAC nucleotides.
 */
enum
{
    NUC_A_4b = 0x1,   /* binary: 0001 */
    NUC_C_4b = 0x2,   /* binary: 0010 */
    NUC_G_4b = 0x3,   /* binary: 0011 */
    NUC_T_4b = 0x4,   /* binary: 0100 */
	NUC_R_4b = 0x5,   /* binary: 0101 */
	NUC_Y_4b = 0x6,   /* binary: 0110 */
	NUC_S_4b = 0x7,   /* binary: 0111 */
	NUC_W_4b = 0x8,   /* binary: 1000 */
	NUC_K_4b = 0x9,   /* binary: 1001 */
	NUC_M_4b = 0xA,   /* binary: 1010 */
	NUC_B_4b = 0xB,   /* binary: 1011 */
	NUC_D_4b = 0xC,   /* binary: 1100 */
	NUC_H_4b = 0xD,   /* binary: 1101 */
	NUC_V_4b = 0xE,   /* binary: 1110 */
	NUC_N_4b = 0xF,   /* binary: 1111 */
};


/**
 * @brief Checks if there are only 'atgcATGC' characters in a
 *        character string.
 *
 * @param seq The sequence to check.
 *
 * @returns A boolean value indicating if there are only
 *          'atgcATGC' characters in a character string.
 *
 * @since November 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
bool only_ATGC(const char* seq);


/**
 * @brief Checks if there are only IUPAC DNA characters in a
 *        character string.
 *
 * @param seq The sequence to check.
 *
 * @returns A boolean value indicating if there are only
 *          IUPAC DNA characters in a character string.
 *
 * @since May 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
bool only_IUPAC_DNA(const char* seq);


/**
 * @brief Checks if a character string can be read as a DNA sequence encoded
 *        with ACGT or IUPAC characters (in capital letters or not).
 *
 * @param seq The sequence to check.
 *
 * @returns A boolean value indicating if the character string
 *          can be read as a DNA sequence.
 *
 * @since May 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
bool is_a_DNA_seq(const char* seq);


/**
 * @brief Returns a nucleotide from a DNA sequence encoded
 *        with each nucleotide on 2 or 4 bits.
 *
 * @param seq The encoded sequence.
 * @param idx The index (in the decoded sequence) of the nucleotide to get.
 * @param encoding An integer indicating whether the sequence is encoded with each nucleotide on 2 or 4 bits.
 *
 * @returns The (still encoded) nucleotide at the given index.
 * @retval 255 if an error occurred.
 *
 * @see decode_seq_on_2_bits() and decode_seq_on_4_bits()
 * @since January 2019
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
byte_t get_nucleotide_from_encoded_seq(byte_t* seq, int32_t idx, uint8_t encoding);


/**
 * @brief Encodes a DNA sequence with each nucleotide coded on 2 bits.
 *
 *    A or a : 00
 *    C or c : 01
 *    T or t : 10
 *    G or g : 11
 *
 * @warning The DNA sequence must contain only 'atgcATGC' characters.
 *
 * @param seq The sequence to encode.
 * @param length The length of the sequence to encode.
 *
 * @returns The encoded sequence.
 *
 * @since November 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
byte_t* encode_seq_on_2_bits(const char* seq, int32_t length);


/**
 * @brief Decodes a DNA sequence that is coded with each nucleotide on 2 bits.
 *
 *    00 -> a
 *    01 -> c
 *    10 -> t
 *    11 -> g
 *
 * @param seq_b The sequence to decode.
 * @param length_seq The initial length of the sequence before it was encoded.
 *
 * @returns The decoded sequence ended with '\0'.
 *
 * @since November 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
char* decode_seq_on_2_bits(byte_t* seq_b, int32_t length_seq);


/**
 * @brief Encodes a DNA sequence with each nucleotide coded on 4 bits.
 *
 *		A or a : 0001
 *      C or c : 0010
 *      G or g : 0011
 *      T or t : 0100
 *      R or r : 0101
 *      Y or y : 0110
 *      S or s : 0111
 *      W or w : 1000
 *      K or k : 1001
 *      M or m : 1010
 *      B or b : 1011
 *      D or d : 1100
 *      H or h : 1101
 *      V or v : 1110
 *      N or n : 1111
 *
 * @warning The DNA sequence must contain only IUPAC characters.
 *
 * @param seq The sequence to encode.
 * @param length The length of the sequence to encode.
 *
 * @returns The encoded sequence.
 *
 * @since November 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
byte_t* encode_seq_on_4_bits(const char* seq, int32_t length);


/**
 * @brief Decodes a DNA sequence that is coded with each nucleotide on 4 bits.
 *
 *		A or a : 0001
 *      C or c : 0010
 *      G or g : 0011
 *      T or t : 0100
 *      R or r : 0101
 *      Y or y : 0110
 *      S or s : 0111
 *      W or w : 1000
 *      K or k : 1001
 *      M or m : 1010
 *      B or b : 1011
 *      D or d : 1100
 *      H or h : 1101
 *      V or v : 1110
 *      N or n : 1111
 *
 * @param seq_b The sequence to decode.
 * @param length_seq The initial length of the sequence before it was encoded.
 *
 * @returns The decoded sequence ended with '\0'.
 *
 * @since November 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
char* decode_seq_on_4_bits(byte_t* seq_b, int32_t length_seq);


////////// FOR DEBUGGING ///////////

// little endian
void print_bits(void* ptr, int32_t length);


#endif /* ENCODE_H_ */

