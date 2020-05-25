/****************************************************************************
 * DNA sequence indexer header file	                                        *
 ****************************************************************************/

/**
 * @file dna_seq_indexer.h
 * @author Celine Mercier
 * @date April 12th 2016
 * @brief Header file for the functions handling the indexing of DNA sequences.
 */


#ifndef CHAR_STR_INDEXER_H_
#define CHAR_STR_INDEXER_H_


#include <stdlib.h>
#include <stdio.h>

#include "obitypes.h"
#include "obiblob.h"
#include "obiblob_indexer.h"


/**
 * @brief Converts a character string to a blob.
 *
 * @warning The blob must be freed by the caller.
 *
 * @param value The character string to convert.
 *
 * @returns A pointer to the blob created.
 * @retval NULL if an error occurred.
 *
 * @since October 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
Obi_blob_p obi_str_to_blob(const char* value);


/**
 * @brief Converts a blob to a character string.
 *
 * @warning The character string returned is mapped.
 *
 * @param value_b The blob to convert.
 *
 * @returns A pointer on the character string contained in the blob.
 *
 * @since October 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
const char* obi_blob_to_str(Obi_blob_p value_b);


/**
 * @brief Stores a character string in an indexer and returns the index.
 *
 * @param indexer The indexer structure.
 * @param value The character string to index.
 *
 * @returns The index referring to the stored character string in the indexer.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
index_t obi_index_char_str(Obi_indexer_p indexer, const char* value);


/**
 * @brief Retrieves a character string from an indexer.
 *
 * @warning The character string returned is mapped.
 *
 * @param indexer The indexer structure.
 * @param idx The index referring to the character string to retrieve in the indexer.
 *
 * @returns A pointer on the character string.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
const char* obi_retrieve_char_str(Obi_indexer_p indexer, index_t idx);


#endif /* CHAR_STR_INDEXER_H_ */

