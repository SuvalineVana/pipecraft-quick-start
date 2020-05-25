/****************************************************************************
 * DNA sequence indexing functions                                          *
 ****************************************************************************/

/**
 * @file dna_seq_indexer.c
 * @author Celine Mercier
 * @date April 12th 2016
 * @brief Functions handling the indexing and retrieval of DNA sequences.
 */


#include <stdlib.h>
#include <stdio.h>
#include <math.h>

#include "dna_seq_indexer.h"
#include "obiblob.h"
#include "obiblob_indexer.h"
#include "obidebug.h"
#include "obitypes.h"


#define DEBUG_LEVEL 0	// TODO has to be defined somewhere else (cython compil flag?)


Obi_blob_p obi_seq_to_blob(const char* seq)
{
	Obi_blob_p 		 value_b;
	int32_t          length_encoded_seq;	// length of the encoded sequence in bytes
	int32_t          seq_length;
	byte_t*          encoded_seq;

	seq_length = strlen(seq);

	// Check if just ATGC and encode accordingly
	if (only_ATGC(seq))
	{
		// Compute the length (in bytes) of the encoded sequence
		length_encoded_seq = ceil((double) seq_length / (double) 4.0);
		// Encode
		encoded_seq = encode_seq_on_2_bits(seq, seq_length);
		if (encoded_seq == NULL)
			return NULL;
		value_b = obi_blob(encoded_seq, ELEMENT_SIZE_SEQ_2, length_encoded_seq, seq_length);
	}
	else
	{
		// Compute the length (in bytes) of the encoded sequence
		length_encoded_seq = ceil((double) seq_length / (double) 2.0);
		// Encode
		encoded_seq = encode_seq_on_4_bits(seq, seq_length);
		if (encoded_seq == NULL)
			return NULL;
		value_b = obi_blob(encoded_seq, ELEMENT_SIZE_SEQ_4, length_encoded_seq, seq_length);
	}

	free(encoded_seq);

	return value_b;
}


char* obi_blob_to_seq(Obi_blob_p value_b)
{
	// Decode
	if (value_b->element_size == 2)
		return decode_seq_on_2_bits(value_b->value, value_b->length_decoded_value);
	else //if (value_b->element_size == 4) commented for efficiency reasons
		return decode_seq_on_4_bits(value_b->value, value_b->length_decoded_value);
//	else
//	{
//		fprintf(stderr, "\n BUG \n");
//		return NULL;
//	}
}


index_t obi_index_dna_seq(Obi_indexer_p indexer, const char* value)
{
	Obi_blob_p  value_b;
	index_t 	idx;

	// Encode value
	value_b = obi_seq_to_blob(value);
	if (value_b == NULL)
		return -1;

	// Add in the indexer
	idx = obi_indexer_add(indexer, value_b);

	free(value_b);

	return idx;
}


char* obi_retrieve_dna_seq(Obi_indexer_p indexer, index_t idx)
{
	Obi_blob_p  value_b;

	// Get encoded value
	value_b = obi_indexer_get(indexer, idx);

	// Return decoded sequence
	return obi_blob_to_seq(value_b);
}

