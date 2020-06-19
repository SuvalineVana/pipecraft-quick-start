/****************************************************************************
 * Array indexer header file	                                                *
 ****************************************************************************/

/**
 * @file array_indexer.h
 * @author Celine Mercier
 * @date October 5th 2017
 * @brief Header file for the functions handling the indexing of arrays of any type.
 */


#ifndef ARRAY_INDEXER_H_
#define ARRAY_INDEXER_H_


#include <stdlib.h>
#include <stdio.h>

#include "obidms.h"
#include "obitypes.h"
#include "obiblob.h"
#include "obiblob_indexer.h"


/**
 * @brief Stores an array of elements of any type in an indexer and returns the index.
 *
 * @param indexer The indexer structure.
 * @param value The array to index.
 * @param elt_size The size in bits of one element.
 * @param value_length The length (number of elements) of the array to index.
 *
 * @returns The index referring to the stored array in the indexer.
 *
 * @since October 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
index_t obi_index_array(Obi_indexer_p indexer, const void* value, uint8_t elt_size, int32_t value_length);


/**
 * @brief Retrieves an array from an indexer.
 *
 * @warning The array returned is mapped.
 *
 * @param indexer The indexer structure.
 * @param idx The index referring to the array to retrieve in the indexer.
 * @param value_length A pointer on an integer to store the length of the array retrieved.
 *
 * @returns A pointer on the array.
 *
 * @since October 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
const void* obi_retrieve_array(Obi_indexer_p indexer, index_t idx, int32_t* value_length_p);


#endif /* ARRAY_INDEXER_H_ */

