/****************************************************************************
 * Obiblob header file	                                                    *
 ****************************************************************************/

/**
 * @file obiblob.h
 * @author Celine Mercier
 * @date November 18th 2015
 * @brief Header file for handling Obi_blob structures.
 */


#ifndef OBIBLOB_H_
#define OBIBLOB_H_


#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>

#include "obitypes.h"


#define ELEMENT_SIZE_STR (8)		/**< The size of an element from a value of type character string.
                              	  	 */
#define ELEMENT_SIZE_UINT8 (8)		/**< The size of an element from a value of type uint8_t.
                              	  	 */
#define ELEMENT_SIZE_SEQ_2 (2)		/**< The size of an element from a value of type DNA sequence encoded on 2 bits.
                              	  	 */
#define ELEMENT_SIZE_SEQ_4 (4)		/**< The size of an element from a value of type DNA sequence encoded on 4 bits.
                              	  	 */


/**
 * @brief Blob structure, for handling encoded values.
 */
typedef struct Obi_blob {
	uint8_t  element_size;		 	/**< Size in bits of one element from the encoded value.
	 	 	 	 	 	 	 	 	 */
	int32_t  length_encoded_value;	/**< Length in bytes of the encoded value.
	 	 	 	 	 	 	 	 	 */
	int32_t  length_decoded_value;	/**< Length in bytes of the decoded value.
	 	 	 	 	 	 	 	 	 */
	byte_t   value[];				/**< Encoded value.
	 	 	 	 	 	 	 	 	 */
} Obi_blob_t, *Obi_blob_p;



/**
 * @brief Function building a blob structure.
 *
 * @param encoded_value A pointer to the encoded value that will be stored in the blob.
 * @param element_size The size in bits of one element from the encoded value.
 * @param length_encoded_value The length in bytes of the encoded value.
 * @param length_decoded_value The length in bytes of the decoded value.
 *
 * @returns A pointer to the created blob structure.
 * @retval NULL if an error occurred.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
Obi_blob_p obi_blob(byte_t* encoded_value, uint8_t element_size, int32_t length_encoded_value, int32_t length_decoded_value);


/**
 * @brief Function comparing two blobs.
 *
 * The encoding is compared first, then the length of the
 * values, then the values themselves.
 *
 * @param value_1 A pointer to the first blob structure.
 * @param value_2 A pointer to the second blob structure.
 *
 * @returns A value < 0 if value_1 < value_2,
 * 			a value > 0 if value_1 > value_2,
 * 			and 0 if value_1 == value_2.
 *
 * @since October 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_blob_compare(Obi_blob_p value_1, Obi_blob_p value_2);


/**
 * @brief Function calculating the size in bytes of a blob.
 *
 * @param value A pointer to the blob structure.
 *
 * @returns The size of the blob in bytes.
 *
 * @since October 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_blob_sizeof(Obi_blob_p value);


#endif /* OBIBLOB_H_ */

