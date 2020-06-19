/****************************************************************************
 * DNA sequence indexer header file	                                        *
 ****************************************************************************/

/**
 * @file dna_seq_indexer.h
 * @author Celine Mercier
 * @date April 12th 2016
 * @brief Header file for the functions handling the indexing of DNA sequences.
 */


#ifndef DNA_SEQ_INDEXER_H_
#define DNA_SEQ_INDEXER_H_


#include <stdlib.h>
#include <stdio.h>

#include "obidms.h"
#include "obitypes.h"
#include "obiblob.h"
#include "obiblob_indexer.h"


/**
 * @brief Converts a DNA sequence to a blob.
 *
 * @warning The blob must be freed by the caller.
 *
 * @param value The DNA sequence to convert.
 *
 * @returns A pointer to the blob created.
 * @retval NULL if an error occurred.
 *
 * @since November 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
Obi_blob_p obi_seq_to_blob(const char* seq);


/**
 * @brief Converts a blob to a DNA sequence.
 *
 * @param value_b The blob to convert.
 *
 * @returns A pointer to the DNA sequence contained in the blob.
 * @retval NULL if an error occurred.
 *
 * @since November 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
char* obi_blob_to_seq(Obi_blob_p value_b);


/**
 * @brief Stores a DNA sequence in an indexer and returns the index.
 *
 * @param indexer The indexer structure.
 * @param value The DNA sequence to index.
 *
 * @returns The index referring to the stored DNA sequence in the indexer.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
index_t obi_index_dna_seq(Obi_indexer_p indexer, const char* value);


/**
 * @brief Retrieves a DNA sequence from an indexer.
 *
 * @warning The DNA sequence returned must be freed by the caller.
 *
 * @param indexer The indexer structure.
 * @param idx The index referring to the DNA sequence to retrieve in the indexer.
 *
 * @returns A pointer on the DNA sequence.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
char* obi_retrieve_dna_seq(Obi_indexer_p indexer, index_t idx);


#endif /* DNA_SEQ_INDEXER_H_ */

