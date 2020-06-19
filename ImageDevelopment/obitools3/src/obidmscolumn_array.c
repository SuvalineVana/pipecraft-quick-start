/****************************************************************************
 * OBIDMS_column_array functions                                              *
 ****************************************************************************/

/**
 * @file obidsmcolumn_array.c
 * @author Celine Mercier
 * @date October 27th 2017
 * @brief Functions handling OBIColumns containing data arrays of any type.
 */


#include <stdlib.h>
#include <stdio.h>

#include "obidmscolumn.h"
#include "obitypes.h"
#include "array_indexer.h"


/**********************************************************************
 *
 * D E F I N I T I O N   O F   T H E   P U B L I C   F U N C T I O N S
 *
 **********************************************************************/


int obi_column_set_array(OBIDMS_column_p column, index_t line_nb, const void* value, uint8_t elt_size, int32_t value_length)
{
	index_t idx;

	if (obi_column_prepare_to_set_value(column, line_nb, 0) < 0)
		return -1;

	if (value == OBITuple_NA)
	{
		idx = OBIIdx_NA;
	}
	else
	{
		// Add the value in the indexer
		idx = obi_index_array(column->indexer, value, elt_size, value_length);
		if (idx == -1)	// An error occurred
		{
			if (obi_errno == OBI_READ_ONLY_INDEXER_ERROR)
			{
				// If the error is that the indexer is read-only, clone it
				if (obi_clone_column_indexer(column) < 0)
					return -1;
				obi_set_errno(0);

				// Add the value in the new indexer
				idx = obi_index_array(column->indexer, value, elt_size, value_length);
				if (idx == -1)
					return -1;
			}
			else
				return -1;
		}
	}

	// Add the value's index in the column
	*(((index_t*) (column->data)) + line_nb) = idx;

	return 0;
}


const void* obi_column_get_array(OBIDMS_column_p column, index_t line_nb, int32_t* value_length_p)
{
	index_t idx;

	if (obi_column_prepare_to_get_value(column, line_nb) < 0)
	{
		*value_length_p = -1;
		return OBITuple_NA;
	}

	idx = *(((index_t*) (column->data)) + line_nb);

	// Check NA
	if (idx == OBIIdx_NA)
	{
		*value_length_p = 0;
		return OBITuple_NA;
	}

	return obi_retrieve_array(column->indexer, idx, value_length_p);
}


