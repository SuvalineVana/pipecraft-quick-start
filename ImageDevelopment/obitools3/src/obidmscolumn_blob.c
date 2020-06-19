/****************************************************************************
 * OBIDMS_column_blob functions                                             *
 ****************************************************************************/

/**
 * @file obidsmcolumn_blob.c
 * @author Celine Mercier
 * @date November 9th 2015
 * @brief Functions handling OBIColumns containing data in the form of indices referring to Obiblobs, to get blobs directly without decoding.
 */


#include <stdlib.h>
#include <stdio.h>

#include "obidmscolumn.h"
#include "obitypes.h"
#include "obiblob.h"


/**********************************************************************
 *
 * D E F I N I T I O N   O F   T H E   P U B L I C   F U N C T I O N S
 *
 **********************************************************************/


Obi_blob_p obi_column_get_blob_with_elt_idx(OBIDMS_column_p column, index_t line_nb, index_t element_idx)
{
	index_t idx;

	if (obi_column_prepare_to_get_value(column, line_nb) < 0)
		return OBIBlob_NA;

	idx = *(((index_t*) (column->data)) + (line_nb * ((column->header)->nb_elements_per_line)) + element_idx);

	// Check NA
	if (idx == OBIIdx_NA)
		return OBIBlob_NA;

	return obi_indexer_get(column->indexer, idx);
}


Obi_blob_p obi_column_get_blob_with_elt_name(OBIDMS_column_p column, index_t line_nb, const char* element_name)
{
	index_t element_idx = obi_column_get_element_index_from_name(column, element_name);
	if (element_idx == OBIIdx_NA)
		return OBIBlob_NA;

	return obi_column_get_blob_with_elt_idx(column, line_nb, element_idx);
}

