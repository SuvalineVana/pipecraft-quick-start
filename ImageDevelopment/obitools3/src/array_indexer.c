/****************************************************************************
 * Array indexing functions                                                  *
 ****************************************************************************/

/**
 * @file array_indexer.c
 * @author Celine Mercier
 * @date October 5th 2017
 * @brief Functions handling the indexing and retrieval of arrays of any type.
 */


#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <math.h>

#include "obiblob.h"
#include "obiblob_indexer.h"
#include "obidebug.h"
#include "obitypes.h"


#define DEBUG_LEVEL 0	// TODO has to be defined somewhere else (cython compil flag?)


index_t obi_index_array(Obi_indexer_p indexer, const void* value, uint8_t elt_size, int value_length)
{
	Obi_blob_p  value_b;
	index_t 	idx;
	int32_t     length_bytes;

	//fprintf(stderr, "\nelt size in C: %u, value len = %d\n", elt_size, value_length);
	//for (int i=0; i<value_length; i++)
	//	fprintf(stderr, "%d - ", ((obiint_t*)value)[i]);

	length_bytes = value_length * elt_size / 8;

	//fprintf(stderr, "\nlength_bytes: %d", length_bytes);

	// Encode value
	value_b = obi_blob((byte_t*)value, elt_size, length_bytes, length_bytes);
	if (value_b == NULL)
		return -1;

	//for (int i=0; i<value_length; i++)
	//	fprintf(stderr, "\nin blob: value %d\n", ((obiint_t*)(value_b->value))[i]);

	// Add in the indexer
	idx = obi_indexer_add(indexer, value_b);

	free(value_b);

	return idx;
}


const void* obi_retrieve_array(Obi_indexer_p indexer, index_t idx, int32_t* value_length_p)
{
	Obi_blob_p  value_b;

	// Get encoded value
	value_b = obi_indexer_get(indexer, idx);

	//fprintf(stderr, "\nlen in blob: %d, elt size %u", value_b->length_decoded_value, value_b->element_size);

	// Store array length
	*value_length_p = (value_b->length_decoded_value) * 8 / (value_b->element_size);

	//fprintf(stderr, "\ngetting length: %d\n", *value_length_p);
	//for (int i=0; i<*value_length_p; i++)
	//	fprintf(stderr, "\nin blob getting: value %d\n", ((obiint_t*)(value_b->value))[i]);

	// Return pointer on mapped array
	return ((void*) (value_b->value));
}

