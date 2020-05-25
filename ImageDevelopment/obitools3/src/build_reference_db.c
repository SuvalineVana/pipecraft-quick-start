/***********************************************************************************
 * Functions to build reference databases for the taxonomic assignment of sequences *
 ***********************************************************************************/

/**
 * @file build_reference_db.c
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 * @date November 15th 2018
 * @brief Functions to build referece databases for the taxonomic assignment of sequences.
 */

//#define OMP_SUPPORT // TODO
#ifdef OMP_SUPPORT
#include <omp.h>
#endif

#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <search.h>
#include <sys/time.h>

#include "build_reference_db.h"
#include "obidms.h"
#include "obidebug.h"
#include "obierrno.h"
#include "obisig.h"
#include "obitypes.h"
#include "obiview.h"
#include "obi_lcs.h"
#include "obidms_taxonomy.h"
#include "obidmscolumn_array.h"
#include "libjson/json_utils.h"


#define DEBUG_LEVEL 0	// TODO has to be defined somewhere else (cython compil flag?)


/**************************************************************************
 *
 * D E C L A R A T I O N   O F   T H E   P R I V A T E   F U N C T I O N S
 *
 **************************************************************************/

/**
 * Internal function computing the last common ancestor (LCA) of a list of merged taxids (generated by obi uniq).
 * Also works on just simple taxid (returns the associated taxon).
 *
 * @param view A pointer on the view containing the taxid information (merged or not).
 * @param taxid_column A pointer on the column where taxids are kept (merged or not, aka int array or int columns).
 * @param idx The index of the sequence to compute the LCA of in the view.
 * @param merged Whether the taxid information is made of arrays of taxids or a single taxid.
 * @param tax A pointer on a taxonomy structure.
 * @param taxid_count The maximum number of taxids associated with one sequence (aka the number of elements in taxid_column).
 * @param taxid_str_indices A pointer on the list of indices in taxid_strings referring to the taxids stored as strings (see next param).
 * @param taxid_strings A pointer on the list of taxids stored as strings in the taxid column header (they correspond to the element names).
 *
 * @returns A pointer on the LCA taxon.
 * @retval NULL if an error occurred.
 *
 * @since August 2019
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static inline ecotx_t* get_lca_from_merged_taxids(Obiview_p view, OBIDMS_column_p taxid_column, index_t idx, bool merged,
										   OBIDMS_taxonomy_p tax, index_t taxid_count, int64_t* taxid_str_indices, char* taxid_strings);


/************************************************************************
 *
 * D E F I N I T I O N   O F   T H E   P R I V A T E   F U N C T I O N S
 *
 ************************************************************************/


static inline ecotx_t* get_lca_from_merged_taxids(Obiview_p view, OBIDMS_column_p taxid_column, index_t idx, bool merged,
										   OBIDMS_taxonomy_p tax, index_t taxid_count, int64_t* taxid_str_indices, char* taxid_strings)
{
	ecotx_t* taxon = NULL;
	ecotx_t* lca = NULL;
	int32_t taxid;
	index_t taxid_idx;
	int64_t taxid_str_idx;
	char* taxid_str;
	obiint_t n;

	for (taxid_idx=0; taxid_idx<taxid_count; taxid_idx++) // get lca of all taxids associated with the sequence
	{
		n = obi_get_int_with_elt_idx_and_col_p_in_view(view, taxid_column, idx, taxid_idx);
		if (n != OBIInt_NA) // The taxid of this column is associated with this sequence
		{
			if (merged)
			{
				taxid_str_idx = taxid_str_indices[taxid_idx];
				taxid_str = taxid_strings+taxid_str_idx;
				taxid = atoi(taxid_str);
			}
			else
				taxid = n;

			taxon = obi_taxo_get_taxon_with_taxid(tax, taxid);
			if (taxon == NULL)
			{
				obidebug(1, "\nError getting a taxon with taxid %d when building a reference database, seq %lld in refs view", taxid, idx);
				return NULL;
			}
			if (lca == NULL)
				lca = taxon;
			else
			{
				// Compute LCA
				lca = obi_taxo_get_lca(taxon, lca);
				if (lca == NULL)
				{
					obidebug(1, "\nError getting the last common ancestor of two taxa when building a reference database");
					return NULL;
				}
			}
		}
	}
	return lca;
}


/**********************************************************************
 *
 * D E F I N I T I O N   O F   T H E   P U B L I C   F U N C T I O N S
 *
 **********************************************************************/


int build_reference_db(const char* dms_name,
					   const char* refs_view_name,
					   const char* taxonomy_name,
					   const char* o_view_name,
					   const char* o_view_comments,
					   double threshold)
{
	OBIDMS_p dms                      		 = NULL;
	OBIDMS_taxonomy_p tax             		 = NULL;
	char* matrix_view_name            		 = NULL;   // TODO discuss that it must be unique
	char* matrix_with_lca_view_name   		 = NULL;   // TODO discuss that it must be unique
	Obiview_p matrix_with_lca_view    		 = NULL;
	Obiview_p refs_view               		 = NULL;
	Obiview_p o_view				  		 = NULL;
	OBIDMS_column_p matrix_idx1_column       = NULL;
	OBIDMS_column_p matrix_idx2_column       = NULL;
	OBIDMS_column_p refs_taxid_column     	 = NULL;
	OBIDMS_column_p matrix_lca_taxid_column  = NULL;
	OBIDMS_column_p matrix_score_column      = NULL;
	OBIDMS_column_p final_lca_taxid_a_column = NULL;
	OBIDMS_column_p final_score_a_column     = NULL;
	char* taxid_strings;
	int64_t* taxid_str_indices;
	index_t taxid_count;
	obiint_t taxid_lca;
	ecotx_t* lca_1 = NULL;
	ecotx_t* lca_2 = NULL;
	ecotx_t* lca = NULL;
	index_t idx1, idx2;
	index_t i, j, k;
	int32_t taxid_array_length;
	int32_t score_array_length;
	int32_t taxid_array_writable_length;
	int32_t score_array_writable_length;
	obifloat_t score;
	obiint_t* lca_taxid_array;
	obifloat_t* score_array;
	obiint_t lca_taxid_array_writable[1000];
	obifloat_t score_array_writable[1000];
	bool modified;
	bool merged;
	char threshold_str[5];
	char* new_comments;

	signal(SIGINT, sig_handler);

	// Discuss keeping the matrix view or not
	matrix_view_name = calloc((strlen(o_view_name)+strlen("_matrix")+1), sizeof(char));
	if (matrix_view_name == NULL)
	{
		obidebug(1, "\nError allocating memory for the name of the matrix view when building a reference database");
		return -1;
	}
	// TODO check and create view name that doesn't already exist
	matrix_view_name = strcpy(matrix_view_name, o_view_name);
	strcat(matrix_view_name, "_matrix");

	if (obi_lcs_align_one_column(dms_name,
								 refs_view_name,
								 "",
								 "",
								 "",
								 matrix_view_name,
								 "{}",
								 false, false,
							     threshold, true, 0, true,
								 1) < 0)
	{
		obidebug(1, "\nError aligning the sequences when building a reference database");
	}

	// Add a column to the matrix view for LCAs

	// Clone the view with a new name

	// Build the view name
	matrix_with_lca_view_name = calloc((strlen(o_view_name)+strlen("_matrix_with_lca")+1), sizeof(char));
	if (matrix_with_lca_view_name == NULL)
	{
		obidebug(1, "\nError allocating memory for the name of the matrix view with LCA when building a reference database");
		return -1;
	}
	matrix_with_lca_view_name = strcpy(matrix_with_lca_view_name, o_view_name);
	strcat(matrix_with_lca_view_name, "_matrix_with_lca");

	// Clone the matrix view
	// Open the DMS
	dms = obi_open_dms(dms_name, false);
	if (dms == NULL)
	{
		obidebug(1, "\nError opening the DMS when building a reference database");
		return -1;
	}

	// Clone the view
	matrix_with_lca_view = obi_clone_view_from_name(dms, matrix_view_name, matrix_with_lca_view_name, NULL, "{}");
	if (matrix_with_lca_view == NULL)
	{
		obidebug(1, "\nError creating the matrix with LCA view when building a reference database");
		return -1;
	}

	// Add the LCA taxid column
	if (obi_view_add_column(matrix_with_lca_view,
							LCA_TAXID_COLUMN_NAME,
							-1,
							LCA_TAXID_COLUMN_NAME,
							OBI_INT,
							-1,
							1,
							"",
							false,
							false,
							false,
							"",
							"",
							-1,
							"{}",
							true)
			< 0)
	{
		obidebug(1, "\nError adding the LCA column to the matrix with LCA view when building a reference database");
		return -1;
	}

	// Open the taxonomy
	tax = obi_read_taxonomy(dms, taxonomy_name, true);
	if (tax == NULL)
	{
		obidebug(1, "\nError reading the taxonomy when building a reference database");
		return -1;
	}

	// Open the reference sequences view
	refs_view = obi_open_view(dms, refs_view_name);
	if (refs_view == NULL)
	{
		obidebug(1, "\nError opening the reference sequences view when building a reference database");
		return -1;
	}

	// Save column pointers
	matrix_idx1_column = obi_view_get_column(matrix_with_lca_view, IDX1_COLUMN_NAME);
	if (matrix_idx1_column == NULL)
	{
		obidebug(1, "\nError opening the first index column when building a reference database");
		return -1;
	}
	matrix_idx2_column = obi_view_get_column(matrix_with_lca_view, IDX2_COLUMN_NAME);
	if (matrix_idx2_column == NULL)
	{
		obidebug(1, "\nError opening the second index column when building a reference database");
		return -1;
	}
	if (obi_view_column_exists(refs_view, MERGED_TAXID_COLUMN))
	{
		refs_taxid_column = obi_view_get_column(refs_view, MERGED_TAXID_COLUMN);
		merged = true;
	}
	else
	{
		refs_taxid_column = obi_view_get_column(refs_view, TAXID_COLUMN);
		merged = false;
	}
	if (refs_taxid_column == NULL)
	{
		obidebug(1, "\nError opening the taxid column when building a reference database");
		return -1;
	}
	// Check that the refs taxid column doesn't contain character strings to parse
	// (happens with obi uniq when there is a lot of elements per line, see options to set the limit,
	// parsing of those strings in C not implemented yet)
	if ((refs_taxid_column->header)->to_eval)
	{
		obidebug(1, "\nError opening the column containing the taxids of the reference sequences when building a reference database: "
					"run previous obi uniq with a higher threshold for the --max-elts option while waiting for the implementation of this feature");
		return -1;
	}

	// Get the (maximum) number of taxids associated with a sequence
	taxid_count = (refs_taxid_column->header)->nb_elements_per_line;
	// Get pointers on element names (aka taxids) and their start indices for faster access
	taxid_strings = (refs_taxid_column->header)->elements_names;
	taxid_str_indices = (refs_taxid_column->header)->elements_names_idx;

	matrix_lca_taxid_column = obi_view_get_column(matrix_with_lca_view, LCA_TAXID_COLUMN_NAME);
	if (matrix_lca_taxid_column == NULL)
	{
		obidebug(1, "\nError opening the LCA column when building a reference database");
		return -1;
	}

	// Compute all the LCAs
		// For each pair
	for (i=0; i<(matrix_with_lca_view->infos)->line_count; i++)
	{
		if (! keep_running)
			return -1;

		// Read all taxids associated with the first sequence and compute their LCA
		// Read line index
		idx1 = obi_get_int_with_elt_idx_and_col_p_in_view(matrix_with_lca_view, matrix_idx1_column, i, 0);
		lca_1 = get_lca_from_merged_taxids(refs_view, refs_taxid_column, idx1, merged,
											tax, taxid_count, taxid_str_indices, taxid_strings);
		if (lca_1 == NULL)
		{
			obidebug(1, "\nError getting the last common ancestor of merged taxids when building a reference database");
			return -1;
		}

		// Read all taxids associated with the second sequence and compute their LCA
			// Read line index
		idx2 = obi_get_int_with_elt_idx_and_col_p_in_view(matrix_with_lca_view, matrix_idx2_column, i, 0);
		lca_2 = get_lca_from_merged_taxids(refs_view, refs_taxid_column, idx2, merged,
											tax, taxid_count, taxid_str_indices, taxid_strings);
		if (lca_2 == NULL)
		{
			obidebug(1, "\nError getting the last common ancestor of merged taxids when building a reference database");
			return -1;
		}

		// Compute and write their LCA
		lca = obi_taxo_get_lca(lca_1, lca_2);
		if (lca == NULL)
		{
			obidebug(1, "\nError getting the last common ancestor of two taxa when building a reference database");
			return -1;
		}
		taxid_lca = lca->taxid;
		if (obi_set_int_with_elt_idx_and_col_p_in_view(matrix_with_lca_view, matrix_lca_taxid_column, i, 0, taxid_lca) < 0)
		{
			obidebug(1, "\nError writing the last common ancestor of two taxa when building a reference database");
			return -1;
		}
	}

	// Clone refs view, add 2 arrays columns for lca and score, compute and write them

	// Clone refs view
	o_view = obi_clone_view(dms, refs_view, o_view_name, NULL, o_view_comments);
	if (o_view == NULL)
	{
		obidebug(1, "\nError cloning the view of references when building a reference database");
		return -1;
	}

	// Add the LCA taxid array column
	if (obi_view_add_column(o_view,
							LCA_TAXID_ARRAY_COLUMN_NAME,
							-1,
							LCA_TAXID_ARRAY_COLUMN_NAME,
							OBI_INT,
							-1,
							1,
							"",
							false,
							true,
							false,
							"",
							"",
							-1,
							"{}",
							true)
			< 0)
	{
		obidebug(1, "\nError adding the LCA taxid column to the final view when building a reference database");
		return -1;
	}

	// Add the score array column
	if (obi_view_add_column(o_view,
							LCA_SCORE_ARRAY_COLUMN_NAME,
							-1,
							LCA_SCORE_ARRAY_COLUMN_NAME,
							OBI_FLOAT,
							-1,
							1,
							"",
							false,
							true,
							false,
							"",
							"",
							-1,
							"{}",
							true)
			< 0)
	{
		obidebug(1, "\nError adding the score column to the final view when building a reference database");
		return -1;
	}

	// Open the newly added columns
	final_lca_taxid_a_column = obi_view_get_column(o_view, LCA_TAXID_ARRAY_COLUMN_NAME);
	if (final_lca_taxid_a_column == NULL)
	{
		obidebug(1, "\nError opening the LCA taxid array column when building a reference database");
		return -1;
	}
	final_score_a_column = obi_view_get_column(o_view, LCA_SCORE_ARRAY_COLUMN_NAME);
	if (final_score_a_column == NULL)
	{
		obidebug(1, "\nError opening the score array column when building a reference database");
		return -1;
	}

	// Open alignment score column
	matrix_score_column = obi_view_get_column(matrix_with_lca_view, SCORE_COLUMN_NAME);
	if (matrix_score_column == NULL)
	{
		obidebug(1, "\nError opening the alignment score column when building a reference database");
		return -1;
	}

	// For each sequence, look for all its alignments in the matrix, and for each different LCA taxid/score, order them and write them
	// Going through matrix once, filling refs arrays on the go for efficiency
	for (i=0; i<(matrix_with_lca_view->infos)->line_count; i++)
	{
		if (! keep_running)
			return -1;

		// Read ref line indexes
		idx1 = obi_get_int_with_elt_idx_and_col_p_in_view(matrix_with_lca_view, matrix_idx1_column, i, 0);
		idx2 = obi_get_int_with_elt_idx_and_col_p_in_view(matrix_with_lca_view, matrix_idx2_column, i, 0);
		// Read LCA taxid
		taxid_lca = obi_get_int_with_elt_idx_and_col_p_in_view(matrix_with_lca_view, matrix_lca_taxid_column, i, 0);
		// Get LCA taxon
		lca = obi_taxo_get_taxon_with_taxid(tax, taxid_lca);
		if (lca == NULL)
		{
			obidebug(1, "\nError getting a LCA from taxid when building a reference database, taxid %d", taxid_lca);
			return -1;
		}
		// Read alignment score
		score = obi_get_float_with_elt_idx_and_col_p_in_view(matrix_with_lca_view, matrix_score_column, i, 0);

		///////////////// Compute for first sequence \\\\\\\\\\\\\\\\\\\\\\\     (TODO function)

		// Read arrays
		lca_taxid_array = (obiint_t*) obi_get_array_with_col_p_in_view(o_view, final_lca_taxid_a_column, idx1, &taxid_array_length);
		score_array = (obifloat_t*) obi_get_array_with_col_p_in_view(o_view, final_score_a_column, idx1, &score_array_length);

		taxid_array_writable_length = taxid_array_length;
		score_array_writable_length = score_array_length;

		// Check that lengths are equal (TODO eventually remove?)
//		if (taxid_array_length != score_array_length)
//		{
//			obidebug(1, "\nError building a reference database: LCA taxid and score arrays' lengths are not equal (%d and %d)", taxid_array_length, score_array_length);
//			return -1;
//		}

		// If empty, add values
		if (taxid_array_length == 0)
		{
			if (obi_set_array_with_col_p_in_view(o_view, final_lca_taxid_a_column, idx1, &taxid_lca, (uint8_t) (obi_sizeof(OBI_INT) * 8), 1) < 0)
			{
				obidebug(1, "\nError setting a LCA taxid array in a column when building a reference database");
				return -1;
			}
			if (obi_set_array_with_col_p_in_view(o_view, final_score_a_column, idx1, &score, (uint8_t) (obi_sizeof(OBI_FLOAT) * 8), 1) < 0)
			{
				obidebug(1, "\nError setting a score array in a column when building a reference database");
				return -1;
			}
		}
		else
		{
			j = 0;
			modified = false;
			while (j < taxid_array_length)
			{
				if (taxid_lca == lca_taxid_array[j])  // Same LCA taxid: replace if the similarity score is greater
				{
					if (score > score_array[j])
					{
						// Copy in array to make writable
						memcpy(lca_taxid_array_writable, lca_taxid_array, taxid_array_length*sizeof(obiint_t));
						memcpy(score_array_writable, score_array, score_array_length*sizeof(obifloat_t));
						modified = true;

						// Better score for the same LCA, replace this LCA/score pair
						lca_taxid_array_writable[j] = taxid_lca;
						score_array_writable[j] = score;

						// Remove the previous (children) LCAs from the array if their score is equal or lower
						while ((j>0) && (score_array_writable[j-1] <= score))
						{
							for (k=j-1; k<taxid_array_writable_length-1; k++)
							{
								lca_taxid_array_writable[k] = lca_taxid_array_writable[k+1];
								score_array_writable[k] = score_array_writable[k+1];
							}
							if (k>(j-1))
							{
								taxid_array_writable_length--;
								score_array_writable_length--;
							}
							j--;
						}
					}
					break;
				}
				else if (obi_taxo_is_taxon_under_taxid(lca, lca_taxid_array[j])) // Array LCA is a parent LCA
				{
					if (score > score_array[j])
					{
						memcpy(lca_taxid_array_writable, lca_taxid_array, taxid_array_length*sizeof(obiint_t));
						memcpy(score_array_writable, score_array, score_array_length*sizeof(obifloat_t));
						modified = true;

						// Insert new LCA/score pair
						for (k=taxid_array_writable_length; k>=j+1; k--)
						{
							lca_taxid_array_writable[k] = lca_taxid_array_writable[k-1];
							score_array_writable[k] = score_array_writable[k-1];
						}

						taxid_array_writable_length++;
						score_array_writable_length++;

						lca_taxid_array_writable[j] = taxid_lca;
						score_array_writable[j] = score;

						// Remove the previous (children) LCAs from the array if their score is equal or lower
						while ((j>0) && (score_array_writable[j-1] <= score))
						{
							for (k=j-1; k<taxid_array_writable_length-1; k++)
							{
								lca_taxid_array_writable[k] = lca_taxid_array_writable[k+1];
								score_array_writable[k] = score_array_writable[k+1];
							}
							if (k>(j-1))
							{
								taxid_array_writable_length--;
								score_array_writable_length--;
							}
							j--;
						}
					}
					break;
				}
				j++;
			}

			if (j == taxid_array_length) // same or parent LCA not found, need to be appended at the end
			{
				memcpy(lca_taxid_array_writable, lca_taxid_array, taxid_array_length*sizeof(obiint_t));
				memcpy(score_array_writable, score_array, score_array_length*sizeof(obifloat_t));
				modified = true;

				// Append LCA
				lca_taxid_array_writable[taxid_array_writable_length] = taxid_lca;
				score_array_writable[score_array_writable_length] = score;

				// Remove the previous (children) LCAs from the array if their score is equal or lower
				while ((j>0) && (score_array_writable[j-1] <= score))
				{
					for (k=j-1; k<taxid_array_writable_length-1; k++)
					{
						lca_taxid_array_writable[k] = lca_taxid_array_writable[k+1];
						score_array_writable[k] = score_array_writable[k+1];
					}
					if (k>(j-1))
					{
						taxid_array_writable_length--;
						score_array_writable_length--;
					}
					j--;
				}
			}

			// Write new arrays
			if (modified)
			{
				if (obi_set_array_with_col_p_in_view(o_view, final_lca_taxid_a_column, idx1, lca_taxid_array_writable, (uint8_t) (obi_sizeof(OBI_INT) * 8), taxid_array_writable_length) < 0)
				{
					obidebug(1, "\nError setting a LCA taxid array in a column when building a reference database");
					return -1;
				}
				if (obi_set_array_with_col_p_in_view(o_view, final_score_a_column, idx1, score_array_writable, (uint8_t) (obi_sizeof(OBI_FLOAT) * 8), score_array_writable_length) < 0)
				{
					obidebug(1, "\nError setting a score array in a column when building a reference database");
					return -1;
				}
			}
		}

		///////////////// Compute for second sequence \\\\\\\\\\\\\\\\\\\\\\\ (TODO function)

		// Read arrays
		lca_taxid_array = (obiint_t*) obi_get_array_with_col_p_in_view(o_view, final_lca_taxid_a_column, idx2, &taxid_array_length);
		score_array = (obifloat_t*) obi_get_array_with_col_p_in_view(o_view, final_score_a_column, idx2, &score_array_length);

		taxid_array_writable_length = taxid_array_length;
		score_array_writable_length = score_array_length;

		// Check that lengths are equal (TODO eventually remove?)
//		if (taxid_array_length != score_array_length)
//		{
//			obidebug(1, "\nError building a reference database: LCA taxid and score arrays' lengths are not equal (%d and %d)", taxid_array_length, score_array_length);
//			return -1;
//		}

		// If empty, add values
		if (taxid_array_length == 0)
		{
			if (obi_set_array_with_col_p_in_view(o_view, final_lca_taxid_a_column, idx2, &taxid_lca, (uint8_t) (obi_sizeof(OBI_INT) * 8), 1) < 0)
			{
				obidebug(1, "\nError setting a LCA taxid array in a column when building a reference database");
				return -1;
			}
			if (obi_set_array_with_col_p_in_view(o_view, final_score_a_column, idx2, &score, (uint8_t) (obi_sizeof(OBI_FLOAT) * 8), 1) < 0)
			{
				obidebug(1, "\nError setting a score array in a column when building a reference database");
				return -1;
			}
		}
		else
		{
			j = 0;
			modified = false;
			while (j < taxid_array_length)
			{
				if (taxid_lca == lca_taxid_array[j])  // Same LCA taxid: replace if the similarity score is greater
				{
					if (score > score_array[j])
					{
						// Copy in array to make writable
						memcpy(lca_taxid_array_writable, lca_taxid_array, taxid_array_length*sizeof(obiint_t));
						memcpy(score_array_writable, score_array, score_array_length*sizeof(obifloat_t));
						modified = true;

						// Better score for the same LCA, replace this LCA/score pair
						lca_taxid_array_writable[j] = taxid_lca;
						score_array_writable[j] = score;

						// Remove the previous (children) LCAs from the array if their score is equal or lower
						while ((j>0) && (score_array_writable[j-1] <= score))
						{
							for (k=j-1; k<taxid_array_writable_length-1; k++)
							{
								lca_taxid_array_writable[k] = lca_taxid_array_writable[k+1];
								score_array_writable[k] = score_array_writable[k+1];
							}
							if (k>(j-1))
							{
								taxid_array_writable_length--;
								score_array_writable_length--;
							}
							j--;
						}
					}
					break;
				}
				else if (obi_taxo_is_taxon_under_taxid(lca, lca_taxid_array[j])) // Array LCA is a parent LCA
				{
					if (score > score_array[j])
					{
						memcpy(lca_taxid_array_writable, lca_taxid_array, taxid_array_length*sizeof(obiint_t));
						memcpy(score_array_writable, score_array, score_array_length*sizeof(obifloat_t));
						modified = true;

						// Insert new LCA/score pair
						for (k=taxid_array_writable_length; k>=j+1; k--)
						{
							lca_taxid_array_writable[k] = lca_taxid_array_writable[k-1];
							score_array_writable[k] = score_array_writable[k-1];
						}

						taxid_array_writable_length++;
						score_array_writable_length++;

						lca_taxid_array_writable[j] = taxid_lca;
						score_array_writable[j] = score;

						// Remove the previous (children) LCAs from the array if their score is equal or lower
						while ((j>0) && (score_array_writable[j-1] <= score))
						{
							for (k=j-1; k<taxid_array_writable_length-1; k++)
							{
								lca_taxid_array_writable[k] = lca_taxid_array_writable[k+1];
								score_array_writable[k] = score_array_writable[k+1];
							}
							if (k>(j-1))
							{
								taxid_array_writable_length--;
								score_array_writable_length--;
							}
							j--;
						}
					}
					break;
				}
				j++;
			}

			if (j == taxid_array_length) // same or parent LCA not found, need to be appended at the end
			{
				memcpy(lca_taxid_array_writable, lca_taxid_array, taxid_array_length*sizeof(obiint_t));
				memcpy(score_array_writable, score_array, score_array_length*sizeof(obifloat_t));
				modified = true;

				// Append LCA
				lca_taxid_array_writable[taxid_array_writable_length] = taxid_lca;
				score_array_writable[score_array_writable_length] = score;

				// Remove the previous (children) LCAs from the array if their score is equal or lower
				while ((j>0) && (score_array_writable[j-1] <= score))
				{
					for (k=j-1; k<taxid_array_writable_length-1; k++)
					{
						lca_taxid_array_writable[k] = lca_taxid_array_writable[k+1];
						score_array_writable[k] = score_array_writable[k+1];
					}
					if (k>(j-1))
					{
						taxid_array_writable_length--;
						score_array_writable_length--;
					}
					j--;
				}
			}

			// Write new arrays
			// Copy arrays for modification (can't edit in place, as it is stored in indexer data file)
			if (modified)
			{
				if (obi_set_array_with_col_p_in_view(o_view, final_lca_taxid_a_column, idx2, lca_taxid_array_writable, (uint8_t) (obi_sizeof(OBI_INT) * 8), taxid_array_writable_length) < 0)
				{
					obidebug(1, "\nError setting a LCA taxid array in a column when building a reference database");
					return -1;
				}
				if (obi_set_array_with_col_p_in_view(o_view, final_score_a_column, idx2, score_array_writable, (uint8_t) (obi_sizeof(OBI_FLOAT) * 8), score_array_writable_length) < 0)
				{
					obidebug(1, "\nError setting a score array in a column when building a reference database");
					return -1;
				}
			}
		}
	}

	// Fill empty LCA informations (because filling from potentially sparse alignment matrix) with the sequence taxid
	score=1.0;  // technically getting LCA of identical sequences
	for (i=0; i<(o_view->infos)->line_count; i++)
	{
		obi_get_array_with_col_p_in_view(o_view, final_lca_taxid_a_column, i, &taxid_array_length);
		if (taxid_array_length == 0)  // no LCA set
		{
			lca = get_lca_from_merged_taxids(refs_view, refs_taxid_column, i, merged,
												tax, taxid_count, taxid_str_indices, taxid_strings);
			if (lca == NULL)
			{
				obidebug(1, "\nError getting the last common ancestor of merged taxids when building a reference database");
				return -1;
			}

			taxid_lca = lca->taxid;
			// Set them in output view
			if (obi_set_array_with_col_p_in_view(o_view, final_lca_taxid_a_column, i, &taxid_lca, (uint8_t) (obi_sizeof(OBI_INT) * 8), 1) < 0)
			{
				obidebug(1, "\nError setting a LCA taxid array in a column when building a reference database");
				return -1;
			}
			if (obi_set_array_with_col_p_in_view(o_view, final_score_a_column, i, &score, (uint8_t) (obi_sizeof(OBI_FLOAT) * 8), 1) < 0)
			{
				obidebug(1, "\nError setting a score array in a column when building a reference database");
				return -1;
			}
		}
	}

	// Add information about the threshold used to build the DB
	snprintf(threshold_str, 5, "%f", threshold);

	new_comments = obi_add_comment((o_view->infos)->comments, DB_THRESHOLD_KEY_IN_COMMENTS, threshold_str);
	if (new_comments == NULL)
	{
		obidebug(1, "\nError adding a comment (db threshold) to a view, key: %s, value: %s", DB_THRESHOLD_KEY_IN_COMMENTS, threshold_str);
		return -1;
	}

	if (obi_view_write_comments(o_view, new_comments) < 0)
	{
		obidebug(1, "\nError adding a comment (db threshold) to a view, key: %s, value: %s", DB_THRESHOLD_KEY_IN_COMMENTS, threshold_str);
		return -1;
	}

	free(new_comments);

	// Close views and DMS
	if (obi_save_and_close_view(refs_view) < 0)
	{
		obidebug(1, "\nError closing the reference view after building a reference database");
		return -1;
	}
	if (obi_save_and_close_view(matrix_with_lca_view) < 0)
	{
		obidebug(1, "\nError closing the matrix with LCA view after building a reference database");
		return -1;
	}
	if (obi_save_and_close_view(o_view) < 0)
	{
		obidebug(1, "\nError closing the final view after building a reference database");
		return -1;
	}

	// Delete temporary views
	if (obi_delete_view(dms, matrix_view_name) < 0)
	{
		obidebug(1, "\nError deleting temporary view %s after building a reference database", matrix_view_name);
		return -1;
	}
	if (obi_delete_view(dms, matrix_with_lca_view_name) < 0)
	{
		obidebug(1, "\nError deleting temporary view %s after building a reference database", matrix_view_name);
		return -1;
	}

	// Close DMS
	if (obi_close_dms(dms, false) < 0)
	{
		obidebug(1, "\nError closing the DMS after building a reference database");
		return -1;
	}

	// Free everything
	free(matrix_view_name);
	free(matrix_with_lca_view_name);

	fprintf(stderr,"\rDone : 100 %%           \n");
	return 0;
}

