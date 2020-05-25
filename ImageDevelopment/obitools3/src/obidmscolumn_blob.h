/****************************************************************************
 * OBIDMS_column_blob header file                                            *
 ****************************************************************************/

/**
 * @file obidsmcolumn_blob.h
 * @author Celine Mercier
 * @date November 9th 2016
 * @brief Header file for the functions handling OBIColumns containing data in the form of indices referring to Obiblobs.
 */


#ifndef OBIDMSCOLUMN_BLOB_H_
#define OBIDMSCOLUMN_BLOB_H_


#include <stdlib.h>
#include <stdio.h>

#include "obidmscolumn.h"
#include "obiblob.h"
#include "obitypes.h"


/**
 * @brief Recovers a value in an OBIDMS column containing data in the form of indices referring
 * to Obiblobs handled by an indexer, and using the index of the element in the column's line.
 *
 * @param column A pointer as returned by obi_create_column().
 * @param line_nb The number of the line where the value should be recovered.
 * @param element_idx The index of the element that should be recovered in the line.
 *
 * @returns The recovered value.
 * @retval OBIBlob_NA the NA value of the type if an error occurred and obi_errno is set.
 *
 * @since November 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
Obi_blob_p obi_column_get_blob_with_elt_idx(OBIDMS_column_p column, index_t line_nb, index_t element_idx);


/**
 * @brief Recovers a value in an OBIDMS column containing data in the form of indices referring
 * to Obiblobs handled by an indexer, using the name of the element in the line.
 *
 * @param column A pointer as returned by obi_create_column() or obi_clone_column().
 * @param line_nb The number of the line where the value should be recovered.
 * @param element_name The name of the element that should be recovered in the line.
 *
 * @returns The recovered value.
 * @retval OBIBlob_NA the NA value of the type if an error occurred and obi_errno is set.
 *
 * @since November 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
Obi_blob_p obi_column_get_blob_with_elt_name(OBIDMS_column_p column, index_t line_nb, const char* element_name);


#endif /* OBIDMSCOLUMN_BLOB_H_ */

