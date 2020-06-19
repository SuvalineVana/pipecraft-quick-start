/********************************************************************
 * Json utils header file                                           *
 ********************************************************************/

/**
 * @file json_utils.h
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 * @date 27 August 2018
 * @brief Header file for the JSON utils functions.
 */


#ifndef JSON_UTILS_H_
#define JSON_UTILS_H_


#include <stdlib.h>
#include <stdint.h>


/**
 * @brief Add a comment (in the key/value form) to a (JSON formatted) comments character string.
 *
 * Note: The usual way to use this function is to call obi_add_comment() with a view or a column's comments,
 *       then obi_view_write_comments() with the result, then free said result.
 *
 * @warning If the key is already in the structure, its associated value is turned
 *          into an array if needed and the new value is added to that array.
 *             // TODO discuss replace boolean
 *
 * @warning The returned pointer has to be freed by the caller.
 *
 * @param comments The initial comments, in the form of a JSON formatted character string.
 * @param key The key of the key/value pair to add.
 * @param value The value of the key/value pair to add.
 *
 * @returns A pointer on the comments with the added key/value element.
 * @retval NULL if an error occurred.
 *
 * @since August 2018
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
char* obi_add_comment(char* comments, const char* key, const char* value);


/**
 * @brief Read a comment (returns its value) from a (JSON formatted) comments character string.
 *
 * @warning The returned character string is framed with "". // TODO which sucks
 *
 * @warning The returned pointer has to be freed by the caller.
 *
 * @param comments The initial comments, in the form of a JSON formatted character string.
 * @param key The key referring to the wanted value.
 *
 * @returns A pointer on the character string containing the formatted value, framed with "".
 * @retval NULL if an error occurred.
 *
 * @since August 2019
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
char* obi_read_comment(char* comments, const char* key);


#endif /* JSON_UTILS_H_ */
