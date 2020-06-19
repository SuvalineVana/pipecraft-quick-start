/****************************************************************************
 * Uint8 indexing functions                               *
 ****************************************************************************/

/**
 * @file uint8_indexer.c
 * @author Celine Mercier
 * @date May 4th 2016
 * @brief Functions handling the indexing and retrieval of uint8 arrays.
 */


#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <math.h>

#include "uint8_indexer.h"
#include "obiblob.h"
#include "obiblob_indexer.h"
#include "obidebug.h"
#include "obitypes.h"


#define DEBUG_LEVEL 0	// TODO has to be defined somewhere else (cython compil flag?)


Obi_blob_p obi_uint8_to_blob(const uint8_t* value, int value_length)
{
	return obi_blob((byte_t*)value, ELEMENT_SIZE_UINT8, value_length, value_length);
}


const uint8_t* obi_blob_to_uint8(Obi_blob_p value_b)
{
	return ((uint8_t*) (value_b->value));
}


index_t obi_index_uint8(Obi_indexer_p indexer, const uint8_t* value, int value_length)
{
	Obi_blob_p  value_b;
	index_t 	idx;

	// Encode value
	value_b = obi_uint8_to_blob(value, value_length);
	if (value_b == NULL)
		return -1;

	// Add in the indexer
	idx = obi_indexer_add(indexer, value_b);

	free(value_b);

	return idx;
}


const uint8_t* obi_retrieve_uint8(Obi_indexer_p indexer, index_t idx, int* value_length)
{
	Obi_blob_p  value_b;

	// Get encoded value
	value_b = obi_indexer_get(indexer, idx);

	// Return decoded sequence
	*value_length = value_b->length_decoded_value;
	return obi_blob_to_uint8(value_b);
}

