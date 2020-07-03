/****************************************************************************
 * JSON utils functions                                                     *
 ****************************************************************************/

/**
 * @file json_utils.c
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 * @date August 23th 2018
 * @brief Functions formatting and handling json-formatted comments for DMS', views and columns.
 */


#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <string.h>

#include "../obierrno.h"
#include "../obidebug.h"
#include "./json_utils.h"
#include "./cJSON.h"


#define DEBUG_LEVEL 0	// TODO has to be defined somewhere else (cython compil flag?)


/**************************************************************************
 *
 * D E C L A R A T I O N   O F   T H E   P R I V A T E   F U N C T I O N S
 *
 **************************************************************************/

/**
 * Internal function reading a character string as a cJSON structure.
 *
 * @warning The returned pointer has to be freed by the caller.
 *
 * @param comments The character string to read.
 *
 * @returns A pointer on a cJSON structure.
 * @retval NULL if an error occurred.
 *
 * @since August 2018
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
cJSON* read_comments(const char* comments);


/**
 * Internal function adding a key/value pair to a cJSON structure.
 *
 * @warning If the key is already in the structure, its associated value is turned
 *          into an array if needed and the new value is added to that array.
 *             // TODO discuss replace boolean
 *
 * @param comments_struct The cJSON structure to which the pair should be added.
 * @param key The key of the key/value pair to add.
 * @param value The value of the key/value pair to add.
 *
 * @returns A pointer on the cJSON structure with the added element.
 * @retval NULL if an error occurred.
 *
 * @since August 2018
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
cJSON* add_comment_to_struct(cJSON* comments_struct, const char* key, const char* value);


/************************************************************************
 *
 * D E F I N I T I O N   O F   T H E   P R I V A T E   F U N C T I O N S
 *
 ************************************************************************/

cJSON* read_comments(const char* comments)
{
    cJSON* comments_struct = cJSON_Parse(comments);

    if (comments_struct == NULL)
    {
        const char* error_ptr = cJSON_GetErrorPtr();
        if (error_ptr != NULL)
            fprintf(stderr, "JSON error before: %s\n", error_ptr);
    	obi_set_errno(OBI_JSON_ERROR);
    	obidebug(1, "\nError reading comments as a cJSON structure");
        return NULL;
    }

    return comments_struct;
}


cJSON* add_comment_to_struct(cJSON* comments_struct, const char* key, const char* value)
{
	cJSON* array = NULL;
	cJSON* element = NULL;
	cJSON* array_element = NULL;
	cJSON* value_struct = NULL;
	cJSON* old_string = NULL;
	char*  elt_value=NULL;

	cJSON_ArrayForEach(element, comments_struct)
	{
		if (strcmp(key, element->string) == 0)
		{
			// Check if value is already in
			// If string, compare value
			if (cJSON_IsString(element))
			{
				elt_value = cJSON_Print(element);
				if (strcmp(value, elt_value) == 0)
				{// If same value, done
					free(elt_value);
					return comments_struct;
				}
				free(elt_value);
			}
			else
			{
				if (cJSON_IsArray(element))
				// Go through values to check if new value is already in
				{
					cJSON_ArrayForEach(array_element, element)
					{
						// Compare value
						elt_value = cJSON_Print(array_element);
						if (strcmp(value, elt_value) == 0)
						{// If same value, done
							free(elt_value);
							return comments_struct;
						}
						free(elt_value);
					}
				}
			}
			// If value was not found, turn the element into an array (if not array already) and append
			if (cJSON_IsString(element))
			{ // Turn the string item into an array
				array = cJSON_CreateArray();
				if (array == NULL)
				{
			    	obi_set_errno(OBI_JSON_ERROR);
					obidebug(1, "\nError creating an array in a cJSON structure");
					return NULL;
				}
				cJSON_AddItemToObject(comments_struct, key, array);
				// Detach the existing string and insert it in the array
				old_string = cJSON_DetachItemFromObjectCaseSensitive(comments_struct, key);
				cJSON_AddItemToArray(array, old_string);
			}
			else if (cJSON_IsArray(element))
			{
				// Add value in array
				array = element;
			}
			else
			{
		    	obi_set_errno(OBI_JSON_ERROR);
				obidebug(1, "\nError adding a key/value pair to a cJSON structure: a new value can be added to an existing key"
						"only if the existing value is either a character string or an array");
				return NULL;
			}

			// Convert value to cJSON structure
			value_struct = cJSON_CreateString(value);
			if (value_struct == NULL)
			{
		    	obi_set_errno(OBI_JSON_ERROR);
				obidebug(1, "\nError creating a cJSON character string to add a new value to a cJSON structure");
				return NULL;
			}

			// Add new value item to the array
			cJSON_AddItemToArray(array, value_struct);

			// Done
			return comments_struct;
		}
	}

	// If key not already in, add with value
	value_struct = cJSON_CreateString(value);
	if (value_struct == NULL)
	{
    	obi_set_errno(OBI_JSON_ERROR);
		obidebug(1, "\nError creating a cJSON character string to add a new value to a cJSON structure");
		return NULL;
	}
	cJSON_AddItemToObject(comments_struct, key, value_struct);

	return comments_struct;
}


/**********************************************************************
 *
 * D E F I N I T I O N   O F   T H E   P U B L I C   F U N C T I O N S
 *
 **********************************************************************/

char* obi_add_comment(char* comments, const char* key, const char* value)
{
	cJSON* comments_struct=NULL;
	char* new_comments=NULL;

	// If NULL or empty comments, error
	if ((comments == NULL) || (strcmp(comments, "") == 0))
	{
    	obi_set_errno(OBI_JSON_ERROR);
		obidebug(1, "\nError adding a key/value pair to a comments character string: comments is NULL");
		return NULL;
	}

	comments_struct = cJSON_Parse(comments);
	if (comments_struct == NULL)
	{
		obi_set_errno(OBI_JSON_ERROR);
		obidebug(1, "\nError parsing the comments when adding a comment to a view, key: %s, value: %s", key, value);
		return NULL;
	}

	comments_struct = add_comment_to_struct(comments_struct, key, value);
	if (comments_struct == NULL)
	{
		obi_set_errno(OBI_JSON_ERROR);
		obidebug(1, "\nError adding a comment to a view, key: %s, value: %s", key, value);
		return NULL;
	}

	// Print to char*
	new_comments = cJSON_Print(comments_struct);
	if (new_comments == NULL)
	{
		obi_set_errno(OBI_JSON_ERROR);
		obidebug(1, "\nError building the new comments string when adding a comment to a view, key: %s, value: %s", key, value);
		return NULL;
	}

	// Free structure
	cJSON_Delete(comments_struct);

	return new_comments;
}


char* obi_read_comment(char* comments, const char* key)
{
	cJSON* comments_struct = NULL;
	cJSON* value_json      = NULL;
	char*  value           = NULL;

	comments_struct = cJSON_Parse(comments);
	if (comments_struct == NULL)
	{
		obi_set_errno(OBI_JSON_ERROR);
		obidebug(1, "\nError parsing the comments when reading comments, key: %s", key);
		return NULL;
	}

	value_json = cJSON_GetObjectItem(comments_struct, key);
	if (value_json == NULL)
	{
		obi_set_errno(OBI_JSON_ERROR);
		obidebug(1, "\nError getting a value when reading a comment, key: %s", key);
		return NULL;
	}

	value = cJSON_Print(value_json);
	if (value == NULL)
	{
		obi_set_errno(OBI_JSON_ERROR);
		obidebug(1, "\nError formatting a value when reading a comment, key: %s", key);
		return NULL;
	}

	// Free structure
	cJSON_Delete(comments_struct);

	return value;
}


