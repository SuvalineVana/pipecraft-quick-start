/****************************************************************************
 * OBIDMS_column_qual header file                                           *
 ****************************************************************************/

/**
 * @file obidsmcolumn_qual.h
 * @author Celine Mercier
 * @date May 4th 2016
 * @brief Header file for the functions handling OBIColumns containing data in the form of indices referring to sequence qualities.
 */


#ifndef OBIDMSCOLUMN_QUAL_H_
#define OBIDMSCOLUMN_QUAL_H_


#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>

#include "obidmscolumn.h"
#include "obitypes.h"


#define QUALITY_ASCII_BASE (33)   		/**< The default ASCII base of sequence quality.
										 *   Used to convert sequence qualities from characters to integers
										 *   and the other way around.
                                	 	 */


/**
 * @brief Sets a value in an OBIDMS column containing data in the form of indices referring
 * to sequence qualities handled by an indexer, and using the index of the element in the column's line.
 *
 * This function is for qualities in the character string format.
 *
 * @warning Pointers returned by obi_open_column() don't allow writing.
 *
 * @param column A pointer as returned by obi_create_column() or obi_clone_column().
 * @param line_nb The number of the line where the value should be set.
 * @param element_idx The index of the element that should be set in the line.
 * @param value The value that should be set, in the character string format.
 * @param offset The ASCII base of sequence quality, used to convert sequence qualities from characters to integers
 *				 and the other way around. If -1, the default base is used.
 *
 * @returns An integer value indicating the success of the operation.
 * @retval 0 on success.
 * @retval -1 if an error occurred.
 *
 * @since May 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_column_set_obiqual_char_with_elt_idx(OBIDMS_column_p column, index_t line_nb, index_t element_idx, const char* value, int offset);


/**
 * @brief Sets a value in an OBIDMS column containing data in the form of indices referring
 * to sequence qualities handled by an indexer, and using the index of the element in the column's line.
 *
 * This function is for qualities in the integer format.
 *
 * @warning Pointers returned by obi_open_column() don't allow writing.
 *
 * @param column A pointer as returned by obi_create_column() or obi_clone_column().
 * @param line_nb The number of the line where the value should be set.
 * @param element_idx The index of the element that should be set in the line.
 * @param value The value that should be set, in the integer array format.
 * @param value_length The length of the integer array.
 *
 * @returns An integer value indicating the success of the operation.
 * @retval 0 on success.
 * @retval -1 if an error occurred.
 *
 * @since May 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_column_set_obiqual_int_with_elt_idx(OBIDMS_column_p column, index_t line_nb, index_t element_idx, const uint8_t* value, int value_length);


/**
 * @brief Recovers a value in an OBIDMS column containing data in the form of indices referring
 * to sequence qualities handled by an indexer, and using the index of the element in the column's line.
 *
 * This function returns quality scores in the character string format.
 *
 * @param column A pointer as returned by obi_create_column().
 * @param line_nb The number of the line where the value should be recovered.
 * @param element_idx The index of the element that should be recovered in the line.
 * @param offset The ASCII base of sequence quality, used to convert sequence qualities from characters to integers
 *				 and the other way around. If -1, the default base is used.
 *
 * @returns The recovered value, in the character string format.
 * @retval OBIQual_char_NA the NA value of the type if an error occurred and obi_errno is set.
 *
 * @since May 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
char* obi_column_get_obiqual_char_with_elt_idx(OBIDMS_column_p column, index_t line_nb, index_t element_idx, int offset);


/**
 * @brief Recovers a value in an OBIDMS column containing data in the form of indices referring
 * to sequence qualities handled by an indexer, and using the index of the element in the column's line.
 *
 * This function returns quality scores in the integer format.
 *
 * @param column A pointer as returned by obi_create_column().
 * @param line_nb The number of the line where the value should be recovered.
 * @param element_idx The index of the element that should be recovered in the line.
 * @param value_length A pointer on an integer to store the length of the integer array recovered.
 *
 * @returns The recovered value, in the integer array format.
 * @retval OBIQual_int_NA the NA value of the type if an error occurred and obi_errno is set.
 *
 * @since May 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
const uint8_t* obi_column_get_obiqual_int_with_elt_idx(OBIDMS_column_p column, index_t line_nb, index_t element_idx, int* value_length);


/**
 * @brief Sets a value in an OBIDMS column containing data in the form of indices referring
 * to sequence qualities handled by an indexer, and using the index of the element in the column's line.
 *
 * This function is for quality scores in the character string format.
 *
 * @warning Pointers returned by obi_open_column() don't allow writing.
 *
 * @param column A pointer as returned by obi_create_column() or obi_clone_column().
 * @param line_nb The number of the line where the value should be set.
 * @param element_name The name of the element that should be set in the line.
 * @param value The value that should be set, in the character string format.
 * @param offset The ASCII base of sequence quality, used to convert sequence qualities from characters to integers
 *				 and the other way around. If -1, the default base is used.
 *
 * @returns An integer value indicating the success of the operation.
 * @retval 0 on success.
 * @retval -1 if an error occurred.
 *
 * @since May 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_column_set_obiqual_char_with_elt_name(OBIDMS_column_p column, index_t line_nb, const char* element_name, const char* value, int offset);


/**
 * @brief Sets a value in an OBIDMS column containing data in the form of indices referring
 * to sequence qualities handled by an indexer, and using the index of the element in the column's line.
 *
 * This function is for quality scores in the integer array format.
 *
 * @warning Pointers returned by obi_open_column() don't allow writing.
 *
 * @param column A pointer as returned by obi_create_column() or obi_clone_column().
 * @param line_nb The number of the line where the value should be set.
 * @param element_name The name of the element that should be set in the line.
 * @param value The value that should be set, in the integer format.
 * @param value_length The length of the integer array.
 *
 * @returns An integer value indicating the success of the operation.
 * @retval 0 on success.
 * @retval -1 if an error occurred.
 *
 * @since May 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_column_set_obiqual_int_with_elt_name(OBIDMS_column_p column, index_t line_nb, const char* element_name, const uint8_t* value, int value_length);


/**
 * @brief Recovers a value in an OBIDMS column containing data in the form of indices referring
 * to sequence qualities handled by an indexer, and using the index of the element in the column's line.
 *
 * This function returns quality scores in the character string format.
 *
 * @param column A pointer as returned by obi_create_column() or obi_clone_column().
 * @param line_nb The number of the line where the value should be recovered.
 * @param element_name The name of the element that should be recovered in the line.
 * @param offset The ASCII base of sequence quality, used to convert sequence qualities from characters to integers
 *				 and the other way around. If -1, the default base is used.
 *
 * @returns The recovered value, in the character string format.
 * @retval OBIQual_char_NA the NA value of the type if an error occurred and obi_errno is set.
 *
 * @since May 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
char* obi_column_get_obiqual_char_with_elt_name(OBIDMS_column_p column, index_t line_nb, const char* element_name, int offset);


/**
 * @brief Recovers a value in an OBIDMS column containing data in the form of indices referring
 * to sequence qualities handled by an indexer, and using the index of the element in the column's line.
 *
 * This function returns quality scores in the integer array format.
 *
 * @param column A pointer as returned by obi_create_column() or obi_clone_column().
 * @param line_nb The number of the line where the value should be recovered.
 * @param element_name The name of the element that should be recovered in the line.
 * @param value_length A pointer on an integer to store the length of the integer array recovered.
 *
 * @returns The recovered value, in the integer format.
 * @retval OBIQual_int_NA the NA value of the type if an error occurred and obi_errno is set.
 *
 * @since May 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
const uint8_t* obi_column_get_obiqual_int_with_elt_name(OBIDMS_column_p column, index_t line_nb, const char* element_name, int* value_length);


#endif /* OBIDMSCOLUMN_QUAL_H_ */

