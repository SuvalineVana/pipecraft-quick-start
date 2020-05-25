/****************************************************************************
 * OBIDMS_column_str header file                                            *
 ****************************************************************************/

/**
 * @file obidsmcolumn_str.h
 * @author Celine Mercier
 * @date October 28th 2015
 * @brief Header file for the functions handling OBIColumns containing data in the form of indices referring to character strings.
 */


#ifndef OBIDMSCOLUMN_STR_H_
#define OBIDMSCOLUMN_STR_H_


#include <stdlib.h>
#include <stdio.h>

#include "obidmscolumn.h"
#include "obitypes.h"


/**
 * @brief Sets a value in an OBIDMS column containing data in the form of indices referring
 * to character strings handled by an indexer, using the index of the element in the line.
 *
 * @warning Pointers returned by obi_open_column() don't allow writing.
 *
 * @param column A pointer as returned by obi_create_column() or obi_clone_column().
 * @param line_nb The number of the line where the value should be set.
 * @param element_idx The index of the element that should be set in the line.
 * @param value The value that should be set.
 *
 * @returns An integer value indicating the success of the operation.
 * @retval 0 on success.
 * @retval -1 if an error occurred.
 *
 * @since October 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_column_set_obistr_with_elt_idx(OBIDMS_column_p column, index_t line_nb, index_t element_idx, const char* value);


/**
 * @brief Recovers a value in an OBIDMS column containing data in the form of indices referring
 * to character strings handled by an indexer, using the index of the element in the line.
 *
 * @param column A pointer as returned by obi_create_column().
 * @param line_nb The number of the line where the value should be recovered.
 * @param element_idx The index of the element that should be recovered in the line.
 *
 * @returns The recovered value.
 * @retval OBIStr_NA the NA value of the type if an error occurred and obi_errno is set.
 *
 * @since October 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
const char* obi_column_get_obistr_with_elt_idx(OBIDMS_column_p column, index_t line_nb, index_t element_idx);


/**
 * @brief Sets a value in an OBIDMS column containing data in the form of indices referring
 * to character strings handled by an indexer, using the name of the element in the line.
 *
 * @warning Pointers returned by obi_open_column() don't allow writing.
 *
 * @param column A pointer as returned by obi_create_column() or obi_clone_column().
 * @param line_nb The number of the line where the value should be set.
 * @param element_name The name of the element that should be set in the line.
 * @param value The value that should be set.
 *
 * @returns An integer value indicating the success of the operation.
 * @retval 0 on success.
 * @retval -1 if an error occurred.
 *
 * @since October 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_column_set_obistr_with_elt_name(OBIDMS_column_p column, index_t line_nb, const char* element_name, const char* value);


/**
 * @brief Recovers a value in an OBIDMS column containing data in the form of indices referring
 * to character strings handled by an indexer, using the name of the element in the line.
 *
 * @param column A pointer as returned by obi_create_column() or obi_clone_column().
 * @param line_nb The number of the line where the value should be recovered.
 * @param element_name The name of the element that should be recovered in the line.
 *
 * @returns The recovered value.
 * @retval OBIStr_NA the NA value of the type if an error occurred and obi_errno is set.
 *
 * @since October 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
const char* obi_column_get_obistr_with_elt_name(OBIDMS_column_p column, index_t line_nb, const char* element_name);


#endif /* OBIDMSCOLUMN_STR_H_ */

