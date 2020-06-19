/****************************************************************************
 * Taxonomic assignment of sequences              						    *
 ****************************************************************************/

/**
 * @file obi_ecotag.c
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 * @date November 15th 2018
 * @brief Functions for the taxonomic assignment of sequences.
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

#include "obi_ecotag.h"
#include "obidms_taxonomy.h"
#include "obidms.h"
#include "obidebug.h"
#include "obierrno.h"
#include "obisig.h"
#include "obitypes.h"
#include "obiview.h"
#include "obidmscolumn.h"
#include "sse_banded_LCS_alignment.h"
#include "upperband.h"
#include "obiblob.h"
#include "build_reference_db.h"
#include "libjson/json_utils.h"


#define DEBUG_LEVEL 0	// TODO has to be defined somewhere else (cython compil flag?)


/**************************************************************************
 *
 * D E C L A R A T I O N   O F   T H E   P R I V A T E   F U N C T I O N S
 *
 **************************************************************************/


/**
 * Internal function creating the output columns for the ecotag algorithm.
 *
 * @param o_view A pointer on the output view.
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since December 2018
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static int create_output_columns(Obiview_p o_view);


/**
 * @brief Internal function printing the result of one assignment to the output view.
 *
 * @param output_view A pointer on the writable view where the result should be written.
 * @param line The line in the output view where the result should be written.
 * @param assigned_taxid_column A pointer on the column where the assigned taxid should be written.
 * @param taxid The assigned taxid.
 * @param assigned_name_column A pointer on the column where the assigned scientific name should be written.
 * @param name The assigned scientific name.
 * @param assigned_status_column A pointer on the column where the assigned status should be written.
 * @param assigned The assigned status (whether the sequence was assigned to a taxon or not).
 * @param best_match_column A pointer on the column where the list of ids of the best matches should be written.
 * @param best_match_ids The list of ids of the best matches as an array of the concatenated ids separated by '\0'.
 * @param best_match_ids_length The total length of the array of ids of best matches.
 * @param score_column A pointer on the column where the score should be written.
 * @param score The similarity score of the sequence with its best match(es).
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since December 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int print_assignment_result(Obiview_p output_view, index_t line,
							OBIDMS_column_p assigned_taxid_column, int32_t taxid,
							OBIDMS_column_p assigned_name_column, const char* name,
							OBIDMS_column_p assigned_status_column, bool assigned,
							OBIDMS_column_p best_match_column, const char* best_match_ids, int best_match_ids_length,
							OBIDMS_column_p score_column, double score);


/************************************************************************
 *
 * D E F I N I T I O N   O F   T H E   P R I V A T E   F U N C T I O N S
 *
 ************************************************************************/

static int create_output_columns(Obiview_p o_view)
{
	// Score column
	if (obi_view_add_column(o_view, ECOTAG_SCORE_COLUMN_NAME, -1, NULL, OBI_FLOAT, 0, 1, NULL, false, false, false, NULL, NULL, -1, "{}", true) < 0)
	{
		obidebug(1, "\nError creating the column for the score in ecotag");
		return -1;
	}

	// Assigned taxid column
	if (obi_view_add_column(o_view, ECOTAG_TAXID_COLUMN_NAME, -1, NULL, OBI_INT, 0, 1, NULL, false, false, false, NULL, NULL, -1, "{}", true) < 0)
	{
		obidebug(1, "\nError creating the column for the assigned taxid in ecotag");
		return -1;
	}

	// Assigned scientific name column
	if (obi_view_add_column(o_view, ECOTAG_NAME_COLUMN_NAME, -1, NULL, OBI_STR, 0, 1, NULL, false, false, false, NULL, NULL, -1, "{}", true) < 0)
	{
		obidebug(1, "\nError creating the column for the assigned scientific name in ecotag");
		return -1;
	}

	// Assignement status column
	if (obi_view_add_column(o_view, ECOTAG_STATUS_COLUMN_NAME, -1, NULL, OBI_BOOL, 0, 1, NULL, false, false, false, NULL, NULL, -1, "{}", true) < 0)
	{
		obidebug(1, "\nError creating the column for the assignment status in ecotag");
		return -1;
	}

	// Column for array of best match ids
	if (obi_view_add_column(o_view, ECOTAG_BEST_MATCH_IDS_COLUMN_NAME, -1, NULL, OBI_STR, 0, 1, NULL, false, true, false, NULL, NULL, -1, "{}", true) < 0)
	{
		obidebug(1, "\nError creating the column for the array of ids of the best match in ecotag");
		return -1;
	}

	return 0;
}


int print_assignment_result(Obiview_p output_view, index_t line,
							OBIDMS_column_p assigned_taxid_column, int32_t taxid,
							OBIDMS_column_p assigned_name_column, const char* name,
							OBIDMS_column_p assigned_status_column, bool assigned,
							OBIDMS_column_p best_match_column, const char* best_match_ids, int best_match_ids_length,
							OBIDMS_column_p score_column, double score)
{
	// Write the assigned taxid
	if (obi_set_int_with_elt_idx_and_col_p_in_view(output_view, assigned_taxid_column, line, 0, taxid) < 0)
	{
		obidebug(1, "\nError writing a taxid in a column when writing ecotag results");
		return -1;
	}

	// Write the assigned scientific name
	if (obi_set_str_with_elt_idx_and_col_p_in_view(output_view, assigned_name_column, line, 0, name) < 0)
	{
		obidebug(1, "\nError writing a scientific name in a column when writing ecotag results");
		return -1;
	}

	// Write the assigned status
	if (obi_set_bool_with_elt_idx_and_col_p_in_view(output_view, assigned_status_column, line, 0, assigned) < 0)
	{
		obidebug(1, "\nError writing a assignment status in a column when writing ecotag results");
		return -1;
	}

	// Write the best match ids
	if (obi_set_array_with_col_p_in_view(output_view, best_match_column, line, best_match_ids, (uint8_t)(sizeof(char)*8), best_match_ids_length) < 0)
	{
		obidebug(1, "\nError writing a assignment status in a column when writing ecotag results");
		return -1;
	}

	// Write the similarity score with the best match
	if (obi_set_float_with_elt_idx_and_col_p_in_view(output_view, score_column, line, 0, score) < 0)
	{
		obidebug(1, "\nError writing a score in a column when writing ecotag results");
		return -1;
	}

	return 0;
}


/**********************************************************************
 *
 * D E F I N I T I O N   O F   T H E   P U B L I C   F U N C T I O N S
 *
 **********************************************************************/


int obi_ecotag(const char* dms_name,
		       const char* query_view_name,
			   const char* ref_dms_name,
			   const char* ref_view_name,
			   const char* taxo_dms_name,
			   const char* taxonomy_name,
			   const char* output_view_name,
			   const char* output_view_comments,
			   double ecotag_threshold)    // TODO different threshold for the similarity sphere around ref seqs
{

	// For each sequence

		// Align with DB

		// Keep the indices of all max scores

		// For each kept index, get the LCA at threshold, then the LCA of those LCAs

		// Write result (max score, threshold, LCA assigned, list of the ids of the best matches)


	index_t         i, j, k;
	ecotx_t*        lca;
	ecotx_t*        lca_in_array;
	ecotx_t*        best_match;
	index_t         query_seq_idx, ref_seq_idx;
	double          score, best_score;
	double			threshold;
	int             lcs_length;
	int             ali_length;
	Kmer_table_p    ktable;
	Obi_blob_p      blob1;
	Obi_blob_p   	blob2;
	int				lcs_min;
	index_t         query_count;
	index_t         ref_count;
	bool 			same_indexer;
	const double*   score_array;
	const int*      lca_array;
	index_t*        best_match_array;
	char*     		best_match_ids;
	char*			best_match_ids_to_store;
	int32_t         best_match_ids_length;
	int				best_match_count;
	int             buffer_size;
	int 			best_match_ids_buffer_size;
	index_t         best_match_idx;
	int32_t         lca_array_length;
	int32_t         lca_taxid;
	int32_t         taxid_best_match;
	bool   			assigned;
	const char*		lca_name;
	const char*		id;
	int				id_len;

	OBIDMS_p          dms = NULL;
	OBIDMS_p		  ref_dms = NULL;
	OBIDMS_p		  taxo_dms = NULL;

	OBIDMS_taxonomy_p taxonomy = NULL;

	Obiview_p       query_view = NULL;
	Obiview_p       ref_view = NULL;
	Obiview_p       output_view = NULL;
	OBIDMS_column_p query_seq_column = NULL;
	OBIDMS_column_p ref_seq_column = NULL;
	OBIDMS_column_p ref_id_column = NULL;
	OBIDMS_column_p score_column = NULL;
	OBIDMS_column_p assigned_taxid_column = NULL;
	OBIDMS_column_p assigned_name_column = NULL;
	OBIDMS_column_p assigned_status_column = NULL;
	OBIDMS_column_p best_match_column = NULL;
	OBIDMS_column_p lca_taxid_a_column = NULL;
	OBIDMS_column_p score_a_column = NULL;
	OBIDMS_column_p ref_taxid_column = NULL;

	char* db_threshold_str = NULL;
	double db_threshold;

	buffer_size = 1024;
	best_match_ids_buffer_size = 1024;

	signal(SIGINT, sig_handler);

	// Open main DMS containing the query sequences and where the output will be written
	dms = obi_open_dms(dms_name, false);
	if (dms == NULL)
	{
		obidebug(1, "\nError opening the DMS containing the query sequences for ecotag");
		return -1;
	}

	// Open the DMS containing the reference database (can be the same or not)
	ref_dms = obi_open_dms(ref_dms_name, false);
	if (ref_dms == NULL)
	{
		obidebug(1, "\nError opening the DMS containing the reference database for ecotag");
		return -1;
	}

	// Open the DMS containing the taxonomy (can be the same or not)
	taxo_dms = obi_open_dms(taxo_dms_name, false);
	if (taxo_dms == NULL)
	{
		obidebug(1, "\nError opening the DMS containing the taxonomy for ecotag");
		return -1;
	}

	// Open the taxonomy
	taxonomy = obi_read_taxonomy(taxo_dms, taxonomy_name, 0);
	if (taxonomy == NULL)
	{
		obidebug(1, "\nError opening the taxonomy for the assignment of sequences");
		return -1;
	}

	// Open the query view
	query_view = obi_open_view(dms, query_view_name);
	if (query_view == NULL)
	{
		obidebug(1, "\nError opening the view of query sequences to assign");
		return -1;
	}

	// Open the reference view.
	ref_view = obi_open_view(ref_dms, ref_view_name);
	if (ref_view == NULL)
	{
		obidebug(1, "\nError opening the view of reference sequences to assign");
		return -1;
	}

	// Open the column of query sequences to assign
	if (strcmp((query_view->infos)->view_type, VIEW_TYPE_NUC_SEQS) == 0)
		query_seq_column = obi_view_get_column(query_view, NUC_SEQUENCE_COLUMN);
	else
	{
		obi_set_errno(OBI_ECOTAG_ERROR);
		obidebug(1, "\nError: query view must have the type NUC_SEQS view");
		return -1;
	}
	if (query_seq_column == NULL)
	{
		obidebug(1, "\nError getting the query column to assign");
		return -1;
	}

	// Open the column of reference sequences to compare the query sequences to
	if (strcmp((ref_view->infos)->view_type, VIEW_TYPE_NUC_SEQS) == 0)
		ref_seq_column = obi_view_get_column(ref_view, NUC_SEQUENCE_COLUMN);
	else
	{
		obi_set_errno(OBI_ECOTAG_ERROR);
		obidebug(1, "\nError: reference view must have the type NUC_SEQS view");
		return -1;
	}
	if (ref_seq_column == NULL)
	{
		obidebug(1, "\nError getting the reference column to assign");
		return -1;
	}

	// Check if the demanded threshold is lower than the threshold used to build the reference database
	db_threshold_str = obi_read_comment((ref_view->infos)->comments, DB_THRESHOLD_KEY_IN_COMMENTS);
	if (db_threshold_str == NULL)
	{
		obidebug(1, "\nError reading the threshold used to build the reference database.");
		return -1;
	}
	if (sscanf(db_threshold_str+1, "%lf", &db_threshold) <= 0)
	{
		obidebug(1, "\nError reading the threshold used to build the reference database.");
		return -1;
	}
	free(db_threshold_str);
	if (ecotag_threshold < db_threshold)
	{
		fprintf(stderr, "\nError: The threshold demanded (%f) is lower than the threshold used to build the reference database (%f).\n\n",
				ecotag_threshold, db_threshold);
		return -1;
	}

	// Open the ID column of reference sequences
	ref_id_column = obi_view_get_column(ref_view, ID_COLUMN);
	if (ref_id_column == NULL)
	{
		obidebug(1, "\nError getting the ID column of the reference view");
		return -1;
	}

	// Create the output view
	output_view = obi_clone_view(dms, query_view, output_view_name, NULL, output_view_comments);
	if (output_view == NULL)
	{
		obidebug(1, "\nError creating the output view when assigning");
		return -1;
	}

	// Create the output columns
	if (create_output_columns(output_view) < 0)
		return -1;
	assigned_taxid_column = obi_view_get_column(output_view, ECOTAG_TAXID_COLUMN_NAME);
	assigned_name_column = obi_view_get_column(output_view, ECOTAG_NAME_COLUMN_NAME);
	assigned_status_column = obi_view_get_column(output_view, ECOTAG_STATUS_COLUMN_NAME);
	best_match_column = obi_view_get_column(output_view, ECOTAG_BEST_MATCH_IDS_COLUMN_NAME);
	score_column = obi_view_get_column(output_view, ECOTAG_SCORE_COLUMN_NAME);

	// Open the used reference columns
	lca_taxid_a_column = obi_view_get_column(ref_view, LCA_TAXID_ARRAY_COLUMN_NAME);
	if (lca_taxid_a_column == NULL)
	{
		obidebug(1, "\nError opening the reference LCA taxid array column when doing the taxonomic assignment of sequences");
		return -1;
	}
	score_a_column = obi_view_get_column(ref_view, LCA_SCORE_ARRAY_COLUMN_NAME);
	if (score_a_column == NULL)
	{
		obidebug(1, "\nError opening the score array column when doing the taxonomic assignment of sequences");
		return -1;
	}
	ref_taxid_column = obi_view_get_column(ref_view, TAXID_COLUMN);
	if (ref_taxid_column == NULL)
	{
		obidebug(1, "\nError opening the taxid column when doing the taxonomic assignment of sequences");
		return -1;
	}

	// Check if the sequence columns share the same indexer (allows for quick checking of sequence equality)
	if ((strcmp((query_seq_column->header)->indexer_name, (ref_seq_column->header)->indexer_name) == 0) && (dms == ref_dms))
		same_indexer = true;
	else
		same_indexer = false;

	// Build kmer tables
	ktable = hash_two_seq_columns(query_view, query_seq_column, 0, ref_view, ref_seq_column, 0);
	if (ktable == NULL)
	{
		obi_set_errno(OBI_ECOTAG_ERROR);
		obidebug(1, "\nError building kmer tables before assigning");
		return -1;
	}

	query_count = (query_view->infos)->line_count;
	ref_count = (ref_view->infos)->line_count;

	best_match_array = (index_t*) malloc(buffer_size * sizeof(index_t));
	if (best_match_array == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating memory for the best match index array in ecotag");
		return -1;
	}

	best_match_ids = (char*) malloc(best_match_ids_buffer_size* sizeof(char));
	if (best_match_ids == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating memory for the best match id array in ecotag");
		return -1;
	}

	for (i=0; i < query_count; i++)
	{
		if (i%100 == 0)
			fprintf(stderr,"\rDone : %f %%       ", (i / (float) query_count)*100);

		best_match_count = 0;
		best_match_ids_length = 0;
		threshold = ecotag_threshold;
		best_score = 0.0;

		// Get first sequence and its index
		query_seq_idx = obi_get_index_with_elt_idx_and_col_p_in_view(query_view, query_seq_column, i, 0);
		blob1 = obi_get_blob_with_elt_idx_and_col_p_in_view(query_view, query_seq_column, i, 0);
		if (blob1 == NULL)
		{
			obidebug(1, "\nError retrieving sequences to align when assigning");
			return -1;
		}

		for (j=0; j < ref_count; j++)
		{
			if (! keep_running)
				return -1;

			// Get reference sequence and its index
			ref_seq_idx = obi_get_index_with_elt_idx_and_col_p_in_view(ref_view, ref_seq_column, j, 0);
			blob2 = obi_get_blob_with_elt_idx_and_col_p_in_view(ref_view, ref_seq_column, j, 0);
			if (blob2 == NULL)
			{
				obidebug(1, "\nError retrieving sequences to align when assigning");
				return -1;
			}

			// Check if the sequences are identical in a quick way (same index in the same indexer)
			if (same_indexer && (query_seq_idx == ref_seq_idx))
				score = 1.0;

			else // the sequences aren't identical or we don't know
			{
				// kmer filter (offset for the index of the kmer table of the 2nd sequence because the kmer tables of both the query and ref columns are concatenated in one)
				align_filters(ktable, blob1, blob2, i, query_count+j, threshold, true, ALILEN, true, &score, &lcs_min, !same_indexer);
				// Compute alignment score
				if ((score < 0) && ((threshold == 0) || (score == -1.0)))	// (sequences are not identical), and (no threshold, or filter passed): align
					score = obiblob_sse_banded_lcs_align(blob1, blob2, threshold, true, ALILEN, true, &lcs_length, &ali_length);
			}

			if ((score >= threshold) && (score >= best_score))
			{
				// Replace everything if score is better
				if (score > best_score)
				{
					// Up the alignment threshold because we only want scores equal or greater than the best found
					threshold = score;
					best_score = score;
					// Reset the array with that match
					best_match_ids_length = 0;
					best_match_count = 0;
				}

				// Store in best match array

				// Grow match array if needed
				if (best_match_count == buffer_size)
				{
					buffer_size = buffer_size*2;
					best_match_array = (index_t*) realloc(best_match_array, buffer_size*sizeof(index_t));
					if (best_match_array == NULL)
					{
						obi_set_errno(OBI_MALLOC_ERROR);
						obidebug(1, "\nError reallocating match array when assigning");
						return -1;
					}
				}

				id = obi_get_str_with_elt_idx_and_col_p_in_view(ref_view, ref_id_column, j, 0);
				id_len = strlen(id);

				// Grow ids array if needed
				while ((best_match_ids_length+id_len+1) >= best_match_ids_buffer_size)
				{
					best_match_ids_buffer_size = best_match_ids_buffer_size*2;
					best_match_ids = (char*) realloc(best_match_ids, best_match_ids_buffer_size*sizeof(char));
					if (best_match_ids == NULL)
					{
						obi_set_errno(OBI_MALLOC_ERROR);
						obidebug(1, "\nError reallocating match ids array when assigning");
						return -1;
					}
				}

				// Save match
				best_match_array[best_match_count] = j;
				best_match_count++;
				strcpy(best_match_ids+best_match_ids_length, id);
				best_match_ids_length = best_match_ids_length + id_len + 1;
			}
		}

		// Get LCA of the LCAs of the best matches
		lca = NULL;
		lca_taxid = -1;
		for (j=0; j<best_match_count; j++)
		{
			best_match_idx = best_match_array[j];

			// Find the LCA for the chosen threshold
			score_array = obi_get_array_with_col_p_in_view(ref_view, score_a_column, best_match_idx, &lca_array_length);

			k = 0;
			while ((k < lca_array_length) && (score_array[k] >= ecotag_threshold))
				k++;

			if (k>0)
			{
				lca_array = obi_get_array_with_col_p_in_view(ref_view, lca_taxid_a_column, best_match_idx, &lca_array_length);
				if (j>0)
				{
					lca = obi_taxo_get_taxon_with_taxid(taxonomy, lca_taxid);
					if (lca == NULL)
					{
						obidebug(1, "\nError getting a taxon from a taxid when doing taxonomic assignment");
						return -1;
					}
					lca_in_array = obi_taxo_get_taxon_with_taxid(taxonomy, lca_array[k-1]);
					if (lca_in_array == NULL)
					{
						obidebug(1, "\nError getting a taxon from a taxid when doing taxonomic assignment");
						return -1;
					}
					lca = obi_taxo_get_lca(lca, lca_in_array);
					if (lca == NULL)
					{
						obidebug(1, "\nError getting the LCA of two taxa when doing taxonomic assignment");
						return -1;
					}
					lca_taxid = lca->taxid;
				}
				else
				{
					lca_taxid = lca_array[k-1];
					lca = obi_taxo_get_taxon_with_taxid(taxonomy, lca_taxid);
				}
			}
			else
			{
				taxid_best_match = obi_get_int_with_elt_idx_and_col_p_in_view(ref_view, ref_taxid_column, best_match_idx, 0);
				best_match = obi_taxo_get_taxon_with_taxid(taxonomy, taxid_best_match);
				if (best_match == NULL)
				{
					obidebug(1, "\nError getting a taxon from a taxid (%d) when doing taxonomic assignment", taxid_best_match);
					return -1;
				}
				if (j>0)
				{
					lca = obi_taxo_get_lca(lca, best_match);
					lca_taxid = lca->taxid;
				}
				else
				{
					lca_taxid = taxid_best_match;
					lca = obi_taxo_get_taxon_with_taxid(taxonomy, lca_taxid);
				}
			}
		}

		lca_name = NULL;
		if (best_match_count > 0)
		{
			assigned = true;

			// Get LCA name
			if (lca->preferred_name != NULL)
				lca_name = lca->preferred_name;
			else
				lca_name = lca->name;
			best_match_ids_to_store = best_match_ids;
		}
		else
		{
			assigned = false;
			lca_name = OBIStr_NA;
			lca_taxid = OBIInt_NA;
			best_match_ids_to_store = OBITuple_NA;
			score = OBIFloat_NA;
		}

		// Print result in output view
		if (print_assignment_result(output_view, i,
								    assigned_taxid_column, lca_taxid,
									assigned_name_column, lca_name,
									assigned_status_column, assigned,
									best_match_column, best_match_ids_to_store, best_match_ids_length,
									score_column, best_score
									) < 0)
							return -1;
	}

	free(best_match_array);
	free(best_match_ids);

	obi_close_taxonomy(taxonomy);
	obi_save_and_close_view(query_view);
	obi_save_and_close_view(ref_view);
	obi_save_and_close_view(output_view);

	obi_close_dms(dms, false);
	obi_close_dms(ref_dms, false);
	obi_close_dms(taxo_dms, false);

	fprintf(stderr,"\rDone : 100 %%           \n");
	return 0;
}



