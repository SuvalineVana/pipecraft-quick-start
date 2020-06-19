/****************************************************************************
 * Array columns header file                                                *
 ****************************************************************************/

/**
 * @file obidsmcolumn_array.h
 * @author Celine Mercier
 * @date October 30th 2017
 * @brief Header file for the functions handling OBIColumns containing data in the form of indices referring to data arrays.
 */


#ifndef OBIDMSCOLUMN_ARRAY_H_
#define OBIDMSCOLUMN_ARRAY_H_


#include <stdlib.h>
#include <stdio.h>

#include "obidmscolumn.h"
#include "obitypes.h"


/**
 * @brief Sets a value in an OBIDMS column containing data in the form of indices referring
 * to arrays handled by an indexer.
 *
 * @warning Pointers returned by obi_open_column() don't allow writing.
 *
 * @param column A pointer as returned by obi_create_column() or obi_clone_column().
 * @param line_nb The number of the line where the value should be set.
 * @param value A pointer on the array.
 * @param elt_size The size in bits of one element.
 * @param value_length The length (number of elements) of the array to index.
 *
 * @returns An integer value indicating the success of the operation.
 * @retval 0 on success.
 * @retval -1 if an error occurred.
 *
 * @since October 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_column_set_array(OBIDMS_column_p column, index_t line_nb, const void* value, uint8_t elt_size, int32_t value_length);


/**
 * @brief Recovers a value in an OBIDMS column containing data in the form of indices referring
 * to arrays handled by an indexer.
 *
 * @param column A pointer as returned by obi_create_column().
 * @param line_nb The number of the line where the value should be recovered.
 * @param value_length A pointer on an integer to store the length of the array retrieved.
 *
 * @returns The recovered value.
 * @retval OBITuple_NA the NA value of the type if an error occurred and obi_errno is set.
 *
 * @since October 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
const void* obi_column_get_array(OBIDMS_column_p column, index_t line_nb, int32_t* value_length_p);


#endif /* OBIDMSCOLUMN_ARRAY_H_ */

