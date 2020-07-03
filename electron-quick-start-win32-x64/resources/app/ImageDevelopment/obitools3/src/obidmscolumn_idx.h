/****************************************************************************
 * OBIDMS_column_idx header file                                            *
 ****************************************************************************/

/**
 * @file obidsmcolumn_idx.h
 * @author Celine Mercier
 * @date February 14th 2016
 * @brief Header file for the functions handling OBIColumns containing indices (stored data type: OBI_IDX).
 *
 * Note: Columns containing indices refer to data stored elsewhere, for example lines in other columns,
 *	     or data stored in indexers.
 */


#ifndef OBIDMSCOLUMN_IDX_H_
#define OBIDMSCOLUMN_IDX_H_


#include <stdlib.h>
#include <stdio.h>

#include "obidmscolumn.h"
#include "obitypes.h"


/**
 * @brief Sets a value in an OBIDMS column containing indices (stored data type: OBI_IDX),
 *        using the index of the element in the line.
 *
 *	Note: Columns containing indices refer to data stored elsewhere, for example lines in other columns,
 *	      or data stored in indexers.
 *
 * In the case of columns referring to values stored in indexers, this allows to directly set already-known
 * indices without going through the time-consuming step of indexing the value.
 *
 * @warning Pointers returned by obi_open_column() don't allow writing.
 *
 * @param column A pointer as returned by obi_create_column() or obi_clone_column().
 * @param line_nb The number of the line where the value should be set.
 * @param element_idx The index of the element that should be set in the line.
 * @param value The index that should be set.
 *
 * @returns An integer value indicating the success of the operation.
 * @retval 0 on success.
 * @retval -1 if an error occurred.
 *
 * @since November 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_column_set_index_with_elt_idx(OBIDMS_column_p column, index_t line_nb, index_t element_idx, index_t value);


/**
 * @brief Recovers a value in an OBIDMS column containing indices (stored data type: OBI_IDX),
 *        using the index of the element in the line.
 *
 *	Note: Columns containing indices refer to data stored elsewhere, for example lines in other columns,
 *	      or data stored in indexers.
 *
 * The value recovered is the index itself and not the data it is referring to.
 *
 * @param column A pointer as returned by obi_create_column().
 * @param line_nb The number of the line where the value should be recovered.
 * @param element_idx The index of the element that should be recovered in the line.
 *
 * @returns The recovered value.
 * @retval OBIIdx_NA the NA value of the type if an error occurred and obi_errno is set.
 *
 * @since November 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
index_t obi_column_get_index_with_elt_idx(OBIDMS_column_p column, index_t line_nb, index_t element_idx);


/**
 * @brief Sets a value in an OBIDMS column containing indices (stored data type: OBI_IDX),
 *        using the index of the element in the line.
 *
 *	Note: Columns containing indices refer to data stored elsewhere, for example lines in other columns,
 *	      or data stored in indexers.
 *
 * In the case of columns referring to values stored in indexers, this allows to directly set already-known
 * indices without going through the time-consuming step of indexing the value.
 *
 * @warning Pointers returned by obi_open_column() don't allow writing.
 *
 * @param column A pointer as returned by obi_create_column() or obi_clone_column().
 * @param line_nb The number of the line where the value should be set.
 * @param element_name The name of the element that should be set in the line.
 * @param value The index that should be set.
 *
 * @returns An integer value indicating the success of the operation.
 * @retval 0 on success.
 * @retval -1 if an error occurred.
 *
 * @since November 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_column_set_index_with_elt_name(OBIDMS_column_p column, index_t line_nb, index_t element_idx, index_t value);


/**
 * @brief Recovers a value in an OBIDMS column containing indices (stored data type: OBI_IDX),
 *        using the name of the element in the line.
 *
 *	Note: Columns containing indices refer to data stored elsewhere, for example lines in other columns,
 *	      or data stored in indexers.
 *
 * The value recovered is the index itself and not the data it is referring to.
 *
 * @param column A pointer as returned by obi_create_column() or obi_clone_column().
 * @param line_nb The number of the line where the value should be recovered.
 * @param element_name The name of the element that should be recovered in the line.
 *
 * @returns The recovered value.
 * @retval OBIIdx_NA the NA value of the type if an error occurred and obi_errno is set.
 *
 * @since November 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
index_t obi_column_get_index_with_elt_name(OBIDMS_column_p column, index_t line_nb, const char* element_name);


#endif /* OBIDMSCOLUMN_IDX_H_ */

