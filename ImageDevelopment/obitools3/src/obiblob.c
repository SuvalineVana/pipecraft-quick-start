/****************************************************************************
 * Obiblob functions                                                       *
 ****************************************************************************/

/**
 * @file obiblob.c
 * @author Celine Mercier
 * @date April 11th 2016
 * @brief Functions handling Obiblob structures.
 */


#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <math.h>

#include "obiblob.h"
#include "obierrno.h"
#include "obitypes.h"	// For byte_t type
#include "obidebug.h"


#define DEBUG_LEVEL 0	// TODO has to be defined somewhere else (cython compil flag?)


// TODO: endianness problem?


Obi_blob_p obi_blob(byte_t* encoded_value, uint8_t element_size, int32_t length_encoded_value, int32_t length_decoded_value)
{
	Obi_blob_p blob;

	// Allocate the memory for the blob structure
	blob = (Obi_blob_p) calloc(sizeof(Obi_blob_t) + length_encoded_value, sizeof(byte_t));
	if (blob == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating memory for a blob");
		return NULL;
	}

	// Store the number of bits on which each element is encoded
	blob->element_size = element_size;

	// Store the length (in bytes) of the encoded value
	blob->length_encoded_value = length_encoded_value;

	// Store the initial length (in bytes) of the decoded value
	blob->length_decoded_value = length_decoded_value;

	// Store the encoded value
	memcpy(blob->value, encoded_value, length_encoded_value);

	return blob;
}


int obi_blob_compare(Obi_blob_p value_1, Obi_blob_p value_2)
{
	int 	comp;
	int32_t b;

	if (value_1->element_size != value_2->element_size)
		return (value_1->element_size - value_2->element_size);

	if (value_1->length_encoded_value != value_2->length_encoded_value)
		return (value_1->length_encoded_value - value_2->length_encoded_value);

	if (value_1->element_size != ELEMENT_SIZE_STR) // because if so, length_decoded_value == length_encoded_value
	{
		if (value_1->length_decoded_value != value_2->length_decoded_value)
			return (value_1->length_decoded_value - value_2->length_decoded_value);
	}

	b = 0;
	comp = 0;
	while (!comp && (b < value_1->length_encoded_value))
	{
		comp = *((value_1->value)+b) - *((value_2->value)+b);
		b++;
	}
	return comp;
}


int obi_blob_sizeof(Obi_blob_p value)
{
	return (sizeof(Obi_blob_t) + (value->length_encoded_value));
}

