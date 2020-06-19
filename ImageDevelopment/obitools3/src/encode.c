/****************************************************************************
 * Encoding functions                                                       *
 ****************************************************************************/

/**
 * @file encode.c
 * @author Celine Mercier
 * @date November 18th 2015
 * @brief Functions encoding DNA sequences.
 */


#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <math.h>

#include "encode.h"
#include "obierrno.h"
#include "obitypes.h"	// For byte_t type
#include "obidebug.h"


#define DEBUG_LEVEL 0	// TODO has to be defined somewhere else (cython compil flag?)


// TODO: endianness problem?



bool only_ATGC(const char* seq)
{
	const char* c = seq;

	while (*c)
	{
		if (!((*c == 'A') || \
			  (*c == 'T') || \
			  (*c == 'G') || \
			  (*c == 'C') || \
			  (*c == 'a') || \
			  (*c == 't') || \
			  (*c == 'g') || \
			  (*c == 'c')))
		{
			return 0;
		}
		else
		{
			c++;
		}
	}
	return 1;
}


bool only_IUPAC_DNA(const char* seq)
{
	const char* c = seq;

	while (*c)
	{
		if (!((*c == 'A') || \
			  (*c == 'T') || \
			  (*c == 'G') || \
			  (*c == 'C') || \
			  (*c == 'U') || \
			  (*c == 'R') || \
			  (*c == 'Y') || \
			  (*c == 'S') || \
			  (*c == 'W') || \
			  (*c == 'K') || \
			  (*c == 'M') || \
			  (*c == 'B') || \
			  (*c == 'D') || \
			  (*c == 'H') || \
			  (*c == 'V') || \
			  (*c == 'N') || \
			  (*c == 'a') || \
			  (*c == 't') || \
			  (*c == 'g') || \
			  (*c == 'c') || \
			  (*c == 'u') || \
			  (*c == 'r') || \
			  (*c == 'y') || \
			  (*c == 's') || \
			  (*c == 'w') || \
			  (*c == 'k') || \
			  (*c == 'm') || \
			  (*c == 'b') || \
			  (*c == 'd') || \
			  (*c == 'h') || \
			  (*c == 'v') || \
			  (*c == 'n') || \
			  (*c == '.') || \
			  (*c == '-')))
		{
			return 0;
		}
		else
		{
			c++;
		}
	}
	return 1;
}


bool is_a_DNA_seq(const char* seq)
{
	if (only_ATGC(seq))
		return true;
	return only_IUPAC_DNA(seq);
}


byte_t get_nucleotide_from_encoded_seq(byte_t* seq, int32_t idx, uint8_t encoding)
{
	uint8_t shift;
	uint8_t mask;
	byte_t  nuc;

	if (encoding == 2)
	{
		shift = 6 - 2*(idx % 4);
		mask = NUC_MASK_2B << shift;
		nuc = (seq[idx/4] & mask) >> shift;
	}
	else if (encoding == 4)
	{
		shift = 4 - 4*(idx % 2);
		mask = NUC_MASK_4B << shift;
		nuc = (seq[idx/2] & mask) >> shift;
	}
	else
	{
		obi_set_errno(OBI_DECODE_ERROR);
		obidebug(1, "\nInvalid encoding base: must be on 2 bits or 4 bits");
		return -1;
	}

	return nuc;
}


byte_t* encode_seq_on_2_bits(const char* seq, int32_t length)
{
	byte_t*  seq_b;
	uint8_t  modulo;
	int32_t  length_b;
	int32_t  i;

	length_b = ceil((double) length / (double) 4.0);

	seq_b = (byte_t*) calloc(length_b, sizeof(byte_t));
	if (seq_b == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating memory for an encoded DNA sequence");
		return NULL;
	}

	for (i=0; i<length; i++)
	{
		// Shift of 2 to make place for new nucleotide
		seq_b[i/4] <<= 2;

		// Add new nucleotide
		switch (seq[i])
		{
		case 'a':
		case 'A':
			seq_b[i/4] |= NUC_A_2b;
			break;
		case 'c':
		case 'C':
			seq_b[i/4] |= NUC_C_2b;
			break;
		case 'g':
		case 'G':
			seq_b[i/4] |= NUC_G_2b;
			break;
		case 't':
		case 'T':
			seq_b[i/4] |= NUC_T_2b;
			break;
		default:
			obi_set_errno(OBI_ENCODE_ERROR);
			obidebug(1, "\nInvalid nucleotide base when encoding (not [atgcATGC])");
			return NULL;
		}
	}

	// Final shift for the last byte if needed
	modulo = (length % 4);
	if (modulo)
		seq_b[(i-1)/4] <<= (2*(4 - modulo));

	return seq_b;
}


char* decode_seq_on_2_bits(byte_t* seq_b, int32_t length_seq)
{
	char*   seq;
	int32_t i;
	uint8_t shift;
	uint8_t mask;
	uint8_t nuc;

	seq = (char*) malloc((length_seq+1) * sizeof(char));
	if (seq == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating memory for a decoded DNA sequence");
		return NULL;
	}

	for (i=0; i<length_seq; i++)
	{
		shift = 6 - 2*(i % 4);
		mask = NUC_MASK_2B << shift;
		nuc = (seq_b[i/4] & mask) >> shift;

		switch (nuc)
		{
		case NUC_A_2b:
			seq[i] = 'a';
			break;
		case NUC_C_2b:
			seq[i] = 'c';
			break;
		case NUC_G_2b:
			seq[i] = 'g';
			break;
		case NUC_T_2b:
			seq[i] = 't';
			break;
		default:
			obi_set_errno(OBI_DECODE_ERROR);
			obidebug(1, "\nInvalid nucleotide base when decoding");
			return NULL;
		}
	}

	seq[length_seq] = '\0';

	return seq;
}


byte_t* encode_seq_on_4_bits(const char* seq, int32_t length)
{
	byte_t*  seq_b;
	uint8_t  modulo;
	int32_t  length_b;
	int32_t  i;

	length_b = ceil((double) length / (double) 2.0);

	seq_b = (byte_t*) calloc(length_b, sizeof(byte_t));
	if (seq_b == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating memory for an encoded DNA sequence");
		return NULL;
	}

	for (i=0; i<length; i++)
	{
		// Shift of 4 to make place for new nucleotide
		seq_b[i/2] <<= 4;

		// Add new nucleotide
		switch (seq[i])
		{
		case 'a':
		case 'A':
			seq_b[i/2] |= NUC_A_4b;
			break;
		case 'c':
		case 'C':
			seq_b[i/2] |= NUC_C_4b;
			break;
		case 'g':
		case 'G':
			seq_b[i/2] |= NUC_G_4b;
			break;
		case 't':
		case 'T':
			seq_b[i/2] |= NUC_T_4b;
			break;
		case 'r':
		case 'R':
			seq_b[i/2] |= NUC_R_4b;
			break;
		case 'y':
		case 'Y':
			seq_b[i/2] |= NUC_Y_4b;
			break;
		case 's':
		case 'S':
			seq_b[i/2] |= NUC_S_4b;
			break;
		case 'w':
		case 'W':
			seq_b[i/2] |= NUC_W_4b;
			break;
		case 'k':
		case 'K':
			seq_b[i/2] |= NUC_K_4b;
			break;
		case 'm':
		case 'M':
			seq_b[i/2] |= NUC_M_4b;
			break;
		case 'b':
		case 'B':
			seq_b[i/2] |= NUC_B_4b;
			break;
		case 'd':
		case 'D':
			seq_b[i/2] |= NUC_D_4b;
			break;
		case 'h':
		case 'H':
			seq_b[i/2] |= NUC_H_4b;
			break;
		case 'v':
		case 'V':
			seq_b[i/2] |= NUC_V_4b;
			break;
		case 'n':
		case 'N':
			seq_b[i/2] |= NUC_N_4b;
			break;
		default:
			obi_set_errno(OBI_ENCODE_ERROR);
			obidebug(1, "\nInvalid nucleotide base when encoding (not IUPAC), sequence: %s", seq);
			return NULL;
		}
	}

	// Final shift for the last byte if needed
	modulo = (length % 2);
	if (modulo)
		seq_b[(i-1)/2] <<= (4*modulo);

	return seq_b;
}


char* decode_seq_on_4_bits(byte_t* seq_b, int32_t length_seq)
{
	char*   seq;
	int32_t i;
	uint8_t shift;
	uint8_t mask;
	uint8_t nuc;

	seq = (char*) malloc((length_seq+1) * sizeof(char));
	if (seq == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating memory for a decoded DNA sequence");
		return NULL;
	}

	for (i=0; i<length_seq; i++)
	{
		shift = 4 - 4*(i % 2);
		mask = NUC_MASK_4B << shift;
		nuc = (seq_b[i/2] & mask) >> shift;

		switch (nuc)
		{
		case NUC_A_4b:
			seq[i] = 'a';
			break;
		case NUC_C_4b:
			seq[i] = 'c';
			break;
		case NUC_G_4b:
			seq[i] = 'g';
			break;
		case NUC_T_4b:
			seq[i] = 't';
			break;
		case NUC_R_4b:
			seq[i] = 'r';
			break;
		case NUC_Y_4b:
			seq[i] = 'y';
			break;
		case NUC_S_4b:
			seq[i] = 's';
			break;
		case NUC_W_4b:
			seq[i] = 'w';
			break;
		case NUC_K_4b:
			seq[i] = 'k';
			break;
		case NUC_M_4b:
			seq[i] = 'm';
			break;
		case NUC_B_4b:
			seq[i] = 'b';
			break;
		case NUC_D_4b:
			seq[i] = 'd';
			break;
		case NUC_H_4b:
			seq[i] = 'h';
			break;
		case NUC_V_4b:
			seq[i] = 'v';
			break;
		case NUC_N_4b:
			seq[i] = 'n';
			break;
		default:
			obi_set_errno(OBI_DECODE_ERROR);
			obidebug(1, "\nInvalid nucleotide base when decoding");
			return NULL;
		}
	}

	seq[length_seq] = '\0';

	return seq;
}


///////////////////// FOR DEBUGGING ///////////////////////////
//NOTE: The first byte is printed the first (at the left-most).
// TODO Move to utils

void print_bits(void* ptr, int32_t size)
{
	uint8_t* b = (uint8_t*) ptr;
	uint8_t byte;
    int32_t i, j;

    fprintf(stderr, "\n");
    for (i=0;i<size;i++)
    {
        for (j=7;j>=0;j--)
        {
            byte = b[i] & (1<<j);
            byte >>= j;
            fprintf(stderr, "%u", byte);
        }
        fprintf(stderr, " ");
    }
    fprintf(stderr, "\n");
}
