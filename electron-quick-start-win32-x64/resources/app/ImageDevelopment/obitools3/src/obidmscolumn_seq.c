/****************************************************************************
 * OBIDMS_column_seq functions                                              *
 ****************************************************************************/

/**
 * @file obidsmcolumn_seq.c
 * @author Celine Mercier
 * @date November 18th 2015
 * @brief Functions handling OBIColumns containing data in the form of indices referring to DNA sequences.
 */


#include <stdlib.h>
#include <stdio.h>

#include "obidmscolumn.h"
#include "obitypes.h"
#include "dna_seq_indexer.h"


/**********************************************************************
 *
 * D E F I N I T I O N   O F   T H E   P U B L I C   F U N C T I O N S
 *
 **********************************************************************/

int obi_column_set_obiseq_with_elt_idx(OBIDMS_column_p column, index_t line_nb, index_t element_idx, const char* value)
{
	index_t idx;

	if (obi_column_prepare_to_set_value(column, line_nb, element_idx) < 0)
		return -1;

	if (value == OBISeq_NA)
	{
		idx = OBIIdx_NA;
	}
	else
	{
		// Add the value in the indexer
		idx = obi_index_dna_seq(column->indexer, value);
		if (idx == -1)	// An error occurred
		{
			if (obi_errno == OBI_READ_ONLY_INDEXER_ERROR)
			{
				// If the error is that the indexer is read-only, clone it
				if (obi_clone_column_indexer(column) < 0)
					return -1;
				obi_set_errno(0);

				// Add the value in the new indexer
				idx = obi_index_dna_seq(column->indexer, value);
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


char* obi_column_get_obiseq_with_elt_idx(OBIDMS_column_p column, index_t line_nb, index_t element_idx)
{
	index_t idx;

	if (obi_column_prepare_to_get_value(column, line_nb) < 0)
		return OBISeq_NA;

	idx = *(((index_t*) (column->data)) + (line_nb * ((column->header)->nb_elements_per_line)) + element_idx);

	// Check NA
	if (idx == OBIIdx_NA)
		return OBISeq_NA;

	return obi_retrieve_dna_seq(column->indexer, idx);
}


int obi_column_set_obiseq_with_elt_name(OBIDMS_column_p column, index_t line_nb, const char* element_name, const char* value)
{
	index_t element_idx = obi_column_get_element_index_from_name(column, element_name);
	if (element_idx == OBIIdx_NA)
		return -1;

	return obi_column_set_obiseq_with_elt_idx(column, line_nb, element_idx, value);
}


char* obi_column_get_obiseq_with_elt_name(OBIDMS_column_p column, index_t line_nb, const char* element_name)
{
	index_t element_idx = obi_column_get_element_index_from_name(column, element_name);
	if (element_idx == OBIIdx_NA)
		return OBISeq_NA;

	return obi_column_get_obiseq_with_elt_idx(column, line_nb, element_idx);
}

