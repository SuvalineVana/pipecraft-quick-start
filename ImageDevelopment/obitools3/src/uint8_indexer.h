/****************************************************************************
 * uint8 indexer header file	                                            *
 ****************************************************************************/

/**
 * @file uint8_indexer.h
 * @author Celine Mercier
 * @date May 4th 2016
 * @brief Header file for the functions handling the indexing of uint8 arrays.
 */


#ifndef UINT8_INDEXER_H_
#define UINT8_INDEXER_H_


#include <stdlib.h>
#include <stdio.h>

#include "obidms.h"
#include "obitypes.h"
#include "obiblob.h"
#include "obiblob_indexer.h"


/**
 * @brief Converts an uint8 array to a blob.
 *
 * @warning The blob must be freed by the caller.
 *
 * @param value The uint8 array to convert.
 * @param value_length The length of the uint8 array to convert.
 *
 * @returns A pointer on the blob created.
 * @retval NULL if an error occurred.
 *
 * @since May 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
Obi_blob_p obi_uint8_to_blob(const uint8_t* value, int value_length);


/**
 * @brief Converts a blob to an uint8 array.
 *
 * @warning The array returned is mapped.
 *
 * @param value_b The blob to convert.
 *
 * @returns A pointer on the uint8 array contained in the blob.
 * @retval NULL if an error occurred.
 *
 * @since May 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
const uint8_t* obi_blob_to_uint8(Obi_blob_p value_b);


/**
 * @brief Stores an uint8 array in an indexer and returns the index.
 *
 * @param indexer The indexer structure.
 * @param value The uint8 array to index.
 * @param value_length The length of the uint8 array to index.
 *
 * @returns The index referring to the stored uint8 array in the indexer.
 *
 * @since May 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
index_t obi_index_uint8(Obi_indexer_p indexer, const uint8_t* value, int value_length);


/**
 * @brief Retrieves an uint8 array from an indexer.
 *
 * @warning The array returned is mapped.
 *
 * @param indexer The indexer structure.
 * @param idx The index referring to the uint8 array to retrieve in the indexer.
 * @param value_length A pointer on an integer to store the length of the array retrieved.
 *
 * @returns A pointer on the uint8 array.
 *
 * @since May 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
const uint8_t* obi_retrieve_uint8(Obi_indexer_p indexer, index_t idx, int* value_length);


#endif /* UINT8_INDEXER_H_ */

