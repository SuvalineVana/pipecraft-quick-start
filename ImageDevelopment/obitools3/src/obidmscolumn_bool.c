/****************************************************************************
 * OBIDMS_column_bool functions                                             *
 ****************************************************************************/

/**
 * @file obidsmcolumn_bool.c
 * @author Celine Mercier
 * @date August 10th 2015
 * @brief Functions handling OBIColumns containing data with the OBIType OBI_BOOL.
 */


#include <stdlib.h>
#include <stdio.h>

#include "obidmscolumn.h"
#include "obitypes.h"


/**********************************************************************
 *
 * D E F I N I T I O N   O F   T H E   P U B L I C   F U N C T I O N S
 *
 **********************************************************************/


int obi_column_set_obibool_with_elt_idx(OBIDMS_column_p column, index_t line_nb, index_t element_idx, obibool_t value)
{
	if (obi_column_prepare_to_set_value(column, line_nb, element_idx) < 0)
		return -1;

	// Set the value
	*(((obibool_t*) (column->data)) + (line_nb * ((column->header)->nb_elements_per_line)) + element_idx) = value;

	return 0;
}


obibool_t obi_column_get_obibool_with_elt_idx(OBIDMS_column_p column, index_t line_nb, index_t element_idx)
{
	if (obi_column_prepare_to_get_value(column, line_nb) < 0)
		return OBIBool_NA;

	return *(((obibool_t*) (column->data)) + (line_nb * ((column->header)->nb_elements_per_line)) + element_idx);
}


int obi_column_set_obibool_with_elt_name(OBIDMS_column_p column, index_t line_nb, const char* element_name, obibool_t value)
{
	index_t element_idx = obi_column_get_element_index_from_name(column, element_name);
	if (element_idx == OBIIdx_NA)
		return -1;

	return obi_column_set_obibool_with_elt_idx(column, line_nb, element_idx, value);
}


obibool_t obi_column_get_obibool_with_elt_name(OBIDMS_column_p column, index_t line_nb, const char* element_name)
{
	index_t element_idx = obi_column_get_element_index_from_name(column, element_name);
	if (element_idx == OBIIdx_NA)
		return OBIBool_NA;

	return obi_column_get_obibool_with_elt_idx(column, line_nb, element_idx);
}

