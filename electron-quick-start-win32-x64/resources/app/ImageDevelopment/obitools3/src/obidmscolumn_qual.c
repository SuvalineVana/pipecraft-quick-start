/****************************************************************************
 * OBIDMS_column_qual functions                                             *
 ****************************************************************************/

/**
 * @file obidsmcolumn_qual.c
 * @author Celine Mercier
 * @date May 4th 2016
 * @brief Functions handling OBIColumns containing data in the form of indices referring to sequence qualities.
 */


#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>

#include "obidmscolumn_qual.h"
#include "obidmscolumn.h"
#include "obitypes.h"
#include "uint8_indexer.h"


/**********************************************************************
 *
 * D E F I N I T I O N   O F   T H E   P U B L I C   F U N C T I O N S
 *
 **********************************************************************/

int obi_column_set_obiqual_char_with_elt_idx(OBIDMS_column_p column, index_t line_nb, index_t element_idx, const char* value, int offset)
{
	uint8_t* int_value;
	int      int_value_length;
	int 	 i;
	int		 ret_value;

	if (offset == -1)
		offset = QUALITY_ASCII_BASE;

	// Check NA value
	if (value == OBIQual_char_NA)
	{
		ret_value = obi_column_set_obiqual_int_with_elt_idx(column, line_nb, element_idx, OBIQual_int_NA, 0);
	}
	else
	{
		int_value_length = strlen(value);
		int_value = (uint8_t*) malloc(int_value_length * sizeof(uint8_t));

		// Convert in uint8_t array to index in that format
		for (i=0; i<int_value_length; i++)
			int_value[i] = ((uint8_t)(value[i])) - offset;
		ret_value = obi_column_set_obiqual_int_with_elt_idx(column, line_nb, element_idx, int_value, int_value_length);
		free(int_value);
	}

	return ret_value;
}


int obi_column_set_obiqual_int_with_elt_idx(OBIDMS_column_p column, index_t line_nb, index_t element_idx, const uint8_t* value, int value_length)
{
	index_t idx;
	char*   new_indexer_name;

	if (obi_column_prepare_to_set_value(column, line_nb, element_idx) < 0)
		return -1;

	if (value == OBIQual_int_NA)
	{
		idx = OBIIdx_NA;
	}
	else
	{
		// Add the value in the indexer
		idx = obi_index_uint8(column->indexer, value, value_length);
		if (idx == -1)	// An error occurred
		{
			if (obi_errno == OBI_READ_ONLY_INDEXER_ERROR)
			{
				// TODO PUT IN A COLUMN FUNCTION
				// If the error is that the indexer is read-only, clone it
				new_indexer_name = obi_build_indexer_name((column->header)->name, (column->header)->version);
				if (new_indexer_name == NULL)
					return -1;
				column->indexer = obi_clone_indexer(column->indexer, new_indexer_name);	// TODO Need to lock this somehow?
				strcpy((column->header)->indexer_name, new_indexer_name);
				free(new_indexer_name);
				obi_set_errno(0);

				// Add the value in the new indexer
				idx = obi_index_uint8(column->indexer, value, value_length);
				if (idx == -1)
					return -1;
			}
			else
				return -1;
		}
	}

	// Add the value's index in the column
	*(((index_t*) (column->data)) + (line_nb * ((column->header)->nb_elements_per_line)) + element_idx) = idx;

	return 0;
}


char* obi_column_get_obiqual_char_with_elt_idx(OBIDMS_column_p column, index_t line_nb, index_t element_idx, int offset)
{
	char* 		   value;
	const uint8_t* int_value;
	int			   int_value_length;
	int			   i;

	if (offset == -1)
		offset = QUALITY_ASCII_BASE;

	int_value = obi_column_get_obiqual_int_with_elt_idx(column, line_nb, element_idx, &int_value_length);

	// Check NA
	if (int_value == OBIQual_int_NA)
		return OBIQual_char_NA;

	value = (char*) malloc((int_value_length + 1) * sizeof(char));

	// Encode int quality to char quality
	for (i=0; i<int_value_length; i++)
		value[i] = (char)(int_value[i] + offset);

	value[i] = '\0';

	return value;
}


const uint8_t* obi_column_get_obiqual_int_with_elt_idx(OBIDMS_column_p column, index_t line_nb, index_t element_idx, int* value_length)
{
	index_t idx;

	if (obi_column_prepare_to_get_value(column, line_nb) < 0)
		return OBIQual_int_NA;

	idx = *(((index_t*) (column->data)) + (line_nb * ((column->header)->nb_elements_per_line)) + element_idx);

	// Check NA
	if (idx == OBIIdx_NA)
		return OBIQual_int_NA;

	return obi_retrieve_uint8(column->indexer, idx, value_length);
}


int obi_column_set_obiqual_char_with_elt_name(OBIDMS_column_p column, index_t line_nb, const char* element_name, const char* value, int offset)
{
	index_t element_idx = obi_column_get_element_index_from_name(column, element_name);
	if (element_idx == OBIIdx_NA)
		return -1;

	return obi_column_set_obiqual_char_with_elt_idx(column, line_nb, element_idx, value, offset);
}


int obi_column_set_obiqual_int_with_elt_name(OBIDMS_column_p column, index_t line_nb, const char* element_name, const uint8_t* value, int value_length)
{
	index_t element_idx = obi_column_get_element_index_from_name(column, element_name);
	if (element_idx == OBIIdx_NA)
		return -1;

	return obi_column_set_obiqual_int_with_elt_idx(column, line_nb, element_idx, value, value_length);
}


char* obi_column_get_obiqual_char_with_elt_name(OBIDMS_column_p column, index_t line_nb, const char* element_name, int offset)
{
	index_t element_idx = obi_column_get_element_index_from_name(column, element_name);
	if (element_idx == OBIIdx_NA)
		return OBIQual_char_NA;

	return obi_column_get_obiqual_char_with_elt_idx(column, line_nb, element_idx, offset);
}


const uint8_t* obi_column_get_obiqual_int_with_elt_name(OBIDMS_column_p column, index_t line_nb, const char* element_name, int* value_length)
{
	index_t element_idx = obi_column_get_element_index_from_name(column, element_name);
	if (element_idx == OBIIdx_NA)
		return OBIQual_int_NA;

	return obi_column_get_obiqual_int_with_elt_idx(column, line_nb, element_idx, value_length);
}

