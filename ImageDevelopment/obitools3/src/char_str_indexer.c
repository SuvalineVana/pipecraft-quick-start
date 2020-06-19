/****************************************************************************
 * Character string indexing functions                                      *
 ****************************************************************************/

/**
 * @file char_str_indexer.c
 * @author Celine Mercier
 * @date April 12th 2016
 * @brief Functions handling the indexing and retrieval of character strings.
 */


#include <stdlib.h>
#include <stdio.h>
#include <math.h>

#include "char_str_indexer.h"
#include "obiblob.h"
#include "obiblob_indexer.h"
#include "obidebug.h"
#include "obitypes.h"


#define DEBUG_LEVEL 0	// TODO has to be defined somewhere else (cython compil flag?)


Obi_blob_p obi_str_to_blob(const char* value)
{
	int32_t length;

	// Compute the number of bytes on which the value will be encoded
	length = strlen(value) + 1;		// +1 to store \0 at the end (makes retrieving faster)

	return obi_blob((byte_t*)value, ELEMENT_SIZE_STR, length, length);
}


const char* obi_blob_to_str(Obi_blob_p value_b)
{
	return value_b->value;
}


index_t obi_index_char_str(Obi_indexer_p indexer, const char* value)
{
	Obi_blob_p  value_b;
	index_t 	idx;

	// Encode value
	value_b = obi_str_to_blob(value);
	if (value_b == NULL)
		return -1;

	// Add in the indexer
	idx = obi_indexer_add(indexer, value_b);

	free(value_b);

	return idx;
}


const char* obi_retrieve_char_str(Obi_indexer_p indexer, index_t idx)
{
	Obi_blob_p  value_b;

	// Get encoded value
	value_b = obi_indexer_get(indexer, idx);

	// Return decoded character string
	return obi_blob_to_str(value_b);
}

