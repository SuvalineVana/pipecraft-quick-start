/****************************************************************************
 * LCS sequence alignment functions				                            *
 ****************************************************************************/

/**
 * @file obi_lcs.c
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 * @date May 4th 2016
 * @brief Functions handling LCS sequence alignments.
 */

//#define OMP_SUPPORT // TODO
#ifdef OMP_SUPPORT
#include <omp.h>
#endif

#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>

#include "obi_lcs.h"
#include "obidebug.h"
#include "obierrno.h"
#include "obisig.h"
#include "obitypes.h"
#include "obiview.h"
#include "sse_banded_LCS_alignment.h"
#include "upperband.h"
#include "obiblob.h"


#define DEBUG_LEVEL 0	// TODO has to be defined somewhere else (cython compil flag?)


/**************************************************************************
 *
 * D E C L A R A T I O N   O F   T H E   P R I V A T E   F U N C T I O N S
 *
 **************************************************************************/


/**
 * @brief Internal function creating the columns where the alignment results are written.
 *
 * @param output_view A pointer on the writable view where the columns should be created.
 * @param id1_indexer_name The name of the indexer where the id of the 1st sequence aligned is indexed.
 * @param id2_indexer_name The name of the indexer where the id of the 2nd sequence aligned is indexed.
 * @param seq1_indexer_name The name of the indexer where the 1st sequence aligned is indexed (needed only if print_seq is True).
 * @param seq2_indexer_name The name of the indexer where the 2nd sequence aligned is indexed (needed only if print_seq is True).
 * @param print_seq A boolean indicating whether the aligned sequences should be copied in the output view.
 * @param print_count A boolean indicating whether the aligned sequence counts should be copied in the output view.
 * @param normalize Whether the score should be normalized with the reference sequence length.
 * @param reference The reference length. 0: The alignement length; 1: The longest sequence's length; 2: The shortest sequence's length.
 * @param similarity_mode Whether the score should be expressed in similarity (true) or distance (false).
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since December 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static int create_alignment_output_columns(Obiview_p output_view,
										   const char* id1_indexer_name,
										   const char* id2_indexer_name,
										   const char* seq1_indexer_name,
										   const char* seq2_indexer_name,
		                                   bool print_seq, bool print_count,
										   bool normalize, int reference, bool similarity_mode);


/**
 * @brief Internal function printing the result of one alignment to the output view.
 *
 * @param output_view A pointer on the writable view where the result should be written.
 * @param line The line in the output view where the result should be written.
 * @param idx1_column A pointer on the column where the index referring to the line of the first sequence aligned in the input view should be written.
 * @param idx2_column A pointer on the column where the index referring to the line of the second sequence aligned in the input view should be written.
 * @param idx1 The index referring to the line of the first sequence aligned in the input view.
 * @param idx2 The index referring to the line of the second sequence aligned in the input view.
 * @param id1_column A pointer on the column where the identifier of the first sequence aligned should be written.
 * @param id2_column A pointer on the column where the identifier of the second sequence aligned should be written.
 * @param id1_idx The index of the identifier of the first sequence aligned.
 * @param id2_idx The index of the identifier of the second sequence aligned.
 * @param print_seq A boolean indicating whether the aligned sequences should be copied in the output view.
 * @param seq1_column A pointer on the column where the first sequence aligned should be written.
 * @param seq2_column A pointer on the column where the second sequence aligned should be written.
 * @param seq1_idx The index of the sequence of the first sequence aligned.
 * @param seq2_idx The index of the sequence of the second sequence aligned.
 * @param print_count A boolean indicating whether the aligned sequence counts should be copied in the output view.
 * @param count1_column A pointer on the column where the count of the first sequence aligned should be written.
 * @param count2_column A pointer on the column where the count of the second sequence aligned should be written.
 * @param count1 The count of the first sequence aligned.
 * @param count2 The count of the second sequence aligned.
 * @param ali_length_column A pointer on the column where the alignment length should be written.
 * @param ali_length The alignment length.
 * @param lcs_length_column A pointer on the column where the LCS length should be written.
 * @param lcs_length The LCS length.
 * @param score_column A pointer on the column where the score should be written.
 * @param score The alignment score.
 * @param reference The reference length. 0: The alignment length; 1: The longest sequence's length; 2: The shortest sequence's length.
 * @param normalize Whether the score should be normalized with the reference sequence length.
 * @param similarity_mode Whether the score should be expressed in similarity (true) or distance (false).
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since December 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static int print_alignment_result(Obiview_p output_view,
								   index_t line,
								   OBIDMS_column_p idx1_column,
								   OBIDMS_column_p idx2_column,
								   index_t idx1,
								   index_t idx2,
								   OBIDMS_column_p id1_column,
								   OBIDMS_column_p id2_column,
								   index_t id1_idx,
								   index_t id2_idx,
								   bool print_seq,
								   OBIDMS_column_p seq1_column,
								   OBIDMS_column_p seq2_column,
								   index_t seq1_idx,
								   index_t seq2_idx,
								   bool print_count,
								   OBIDMS_column_p count1_column,
								   OBIDMS_column_p count2_column,
								   int count1,
								   int count2,
								   OBIDMS_column_p ali_length_column,
								   int ali_length,
								   OBIDMS_column_p lcs_length_column,
								   int lcs_length,
								   OBIDMS_column_p score_column,
								   double score,
								   int reference,
								   bool normalize,
								   bool similarity_mode);



/************************************************************************
 *
 * D E F I N I T I O N   O F   T H E   P R I V A T E   F U N C T I O N S
 *
 ************************************************************************/


static int create_alignment_output_columns(Obiview_p output_view,
										   const char* id1_indexer_name,
										   const char* id2_indexer_name,
										   const char* seq1_indexer_name,
										   const char* seq2_indexer_name,
		                                   bool print_seq, bool print_count,
										   bool normalize, int reference, bool similarity_mode)
{
	// Create the column for the ids of the 1st sequence aligned
	if (obi_view_add_column(output_view, ID1_COLUMN_NAME, -1, NULL, OBI_STR, 0, 1, NULL, false, false, false, id1_indexer_name, NULL, -1, ID1_COLUMN_COMMENTS, true) < 0)
	{
		obidebug(1, "\nError creating the first column for the sequence ids when aligning");
		return -1;
	}

	// Create the column for the ids of the 2nd sequence aligned
	if (obi_view_add_column(output_view, ID2_COLUMN_NAME, -1, NULL, OBI_STR, 0, 1, NULL, false, false, false, id2_indexer_name, NULL, -1, ID2_COLUMN_COMMENTS, true) < 0)
	{
		obidebug(1, "\nError creating the second column for the sequence ids when aligning");
		return -1;
	}

	// Create the column for the index (in the input view) of the first sequences aligned
	if (obi_view_add_column(output_view, IDX1_COLUMN_NAME, -1, NULL, OBI_INT, 0, 1, NULL, false, false, false, NULL, NULL, -1, IDX1_COLUMN_COMMENTS, true) < 0)
	{
		obidebug(1, "\nError creating the first column for the sequence indices when aligning");
		return -1;
	}

	// Create the column for the index (in the input view) of the second sequences aligned
	if (obi_view_add_column(output_view, IDX2_COLUMN_NAME, -1, NULL, OBI_INT, 0, 1, NULL, false, false, false, NULL, NULL, -1, IDX2_COLUMN_COMMENTS, true) < 0)
	{
		obidebug(1, "\nError creating the second column for the sequence indices when aligning");
		return -1;
	}

	// Create the column for the LCS length
	if (obi_view_add_column(output_view, LCS_LENGTH_COLUMN_NAME, -1, NULL, OBI_INT, 0, 1, NULL, false, false, false, NULL, NULL, -1, LCS_LENGTH_COLUMN_COMMENTS, true) < 0)
	{
		obidebug(1, "\nError creating the column for the LCS length when aligning");
		return -1;
	}

	// Create the column for the alignment length if it is computed
	if ((reference == ALILEN) && (normalize || !similarity_mode))
	{
		if (obi_view_add_column(output_view, ALI_LENGTH_COLUMN_NAME, -1, NULL, OBI_INT, 0, 1, NULL, false, false, false, NULL, NULL, -1, ALI_LENGTH_COLUMN_COMMENTS, true) < 0)
		{
			obidebug(1, "\nError creating the column for the alignment length when aligning");
			return -1;
		}
	}
	// Create the column for the alignment score
	if (normalize)
	{
		if (obi_view_add_column(output_view, SCORE_COLUMN_NAME, -1, NULL, OBI_FLOAT, 0, 1, NULL, false, false, false, NULL, NULL, -1, SCORE_COLUMN_NAME, true) < 0)
		{
			obidebug(1, "\nError creating the column for the score when aligning");
			return -1;
		}
	}
	else
	{
		if (obi_view_add_column(output_view, SCORE_COLUMN_NAME, -1, NULL, OBI_INT, 0, 1, NULL, false, false, false, NULL, NULL, -1, SCORE_COLUMN_NAME, true) < 0)
		{
			obidebug(1, "\nError creating the column for the score when aligning");
			return -1;
		}
	}

	if (print_seq)
	{
		// Create the column for the first sequences aligned
		if (obi_view_add_column(output_view, SEQ1_COLUMN_NAME, -1, NULL, OBI_SEQ, 0, 1, NULL, false, false, false, seq1_indexer_name, NULL, -1, SEQ1_COLUMN_COMMENTS, true) < 0)
		{
			obidebug(1, "\nError creating the first column for the sequences when aligning");
			return -1;
		}

		// Create the column for the second sequences aligned
		if (obi_view_add_column(output_view, SEQ2_COLUMN_NAME, -1, NULL, OBI_SEQ, 0, 1, NULL, false, false, false, seq2_indexer_name, NULL, -1, SEQ2_COLUMN_COMMENTS, true) < 0)
		{
			obidebug(1, "\nError creating the second column for the sequences when aligning");
			return -1;
		}
	}
	if (print_count)
	{
		// Create the column for the count of the first sequences aligned
		if (obi_view_add_column(output_view, COUNT1_COLUMN_NAME, -1, NULL, OBI_INT, 0, 1, NULL, false, false, false, NULL, NULL, -1, COUNT1_COLUMN_COMMENTS, true) < 0)
		{
			obidebug(1, "\nError creating the first column for the sequence counts when aligning");
			return -1;
		}

		// Create the column for the count of the second sequences aligned
		if (obi_view_add_column(output_view, COUNT2_COLUMN_NAME, -1, NULL, OBI_INT, 0, 1, NULL, false, false, false, NULL, NULL, -1, COUNT2_COLUMN_COMMENTS, true) < 0)
		{
			obidebug(1, "\nError creating the second column for the sequence counts when aligning");
			return -1;
		}
	}

	return 0;
}


static int print_alignment_result(Obiview_p output_view,
								   index_t line,
								   OBIDMS_column_p idx1_column,
								   OBIDMS_column_p idx2_column,
								   index_t idx1,
								   index_t idx2,
								   OBIDMS_column_p id1_column,
								   OBIDMS_column_p id2_column,
								   index_t id1_idx,
								   index_t id2_idx,
								   bool print_seq,
								   OBIDMS_column_p seq1_column,
								   OBIDMS_column_p seq2_column,
								   index_t seq1_idx,
								   index_t seq2_idx,
								   bool print_count,
								   OBIDMS_column_p count1_column,
								   OBIDMS_column_p count2_column,
								   int count1,
								   int count2,
								   OBIDMS_column_p ali_length_column,
								   int ali_length,
								   OBIDMS_column_p lcs_length_column,
								   int lcs_length,
								   OBIDMS_column_p score_column,
								   double score,
								   int reference,
								   bool normalize,
								   bool similarity_mode)
{
	// Write line indices of the input view in the output view (to easily refer to the input sequences from the output view)
	if (obi_set_int_with_elt_idx_and_col_p_in_view(output_view, idx1_column, line, 0, idx1) < 0)
	{
		obidebug(1, "\nError writing idx1 in a column");
		return -1;
	}
	if (obi_set_int_with_elt_idx_and_col_p_in_view(output_view, idx2_column, line, 0, idx2) < 0)
	{
		obidebug(1, "\nError writing idx2 in a column");
		return -1;
	}

	// Write ids in output view
	if (obi_set_index_with_elt_idx_and_col_p_in_view(output_view, id1_column, line, 0, id1_idx) < 0)
	{
		obidebug(1, "\nError writing id1 in a column");
		return -1;
	}
	if (obi_set_index_with_elt_idx_and_col_p_in_view(output_view, id2_column, line, 0, id2_idx) < 0)
	{
		obidebug(1, "\nError writing id2 in a column");
		return -1;
	}

	// Write the sequences if needed
	if (print_seq)
	{
		if (obi_set_index_with_elt_idx_and_col_p_in_view(output_view, seq1_column, line, 0, seq1_idx) < 0)
		{
			obidebug(1, "\nError writing seq1 in a column");
			return -1;
		}

		if (obi_set_index_with_elt_idx_and_col_p_in_view(output_view, seq2_column, line, 0, seq2_idx) < 0)
		{
			obidebug(1, "\nError writing seq2 in a column");
			return -1;
		}
	}

	// Write the counts if needed
	if (print_count)
	{
		if (obi_set_int_with_elt_idx_and_col_p_in_view(output_view, count1_column, line, 0, count1) < 0)
		{
			obidebug(1, "\nError writing count1 in a column");
			return -1;
		}

		if (obi_set_int_with_elt_idx_and_col_p_in_view(output_view, count2_column, line, 0, count2) < 0)
		{
			obidebug(1, "\nError writing count2 in a column");
			return -1;
		}
	}

	// Write the alignment length if it was computed
	if ((reference == ALILEN) && (normalize || !similarity_mode))
	{
		if (obi_set_int_with_elt_idx_and_col_p_in_view(output_view, ali_length_column, line, 0, ali_length) < 0)
		{
			obidebug(1, "\nError writing alignment length in a column");
			return -1;
		}
	}

	// Write the LCS length
	if (obi_set_int_with_elt_idx_and_col_p_in_view(output_view, lcs_length_column, line, 0, lcs_length) < 0)
	{
		obidebug(1, "\nError writing LCS length in a column");
		return -1;
	}

	// Write score
	if (normalize)
	{
		if (obi_set_float_with_elt_idx_and_col_p_in_view(output_view, score_column, line, 0, (obifloat_t) score) < 0)
		{
			obidebug(1, "\nError writing alignment score in a column");
			return -1;
		}
	}
	else
	{
		if (obi_set_int_with_elt_idx_and_col_p_in_view(output_view, score_column, line, 0, (obiint_t) score) < 0)
		{
			obidebug(1, "\nError writing alignment score in a column");
			return -1;
		}
	}

	return 0;
}



/**********************************************************************
 *
 * D E F I N I T I O N   O F   T H E   P U B L I C   F U N C T I O N S
 *
 **********************************************************************/


int obi_lcs_align_one_column(const char* dms_name,
							 const char* seq_view_name,
							 const char* seq_column_name,
							 const char* seq_elt_name,
							 const char* id_column_name,
					         const char* output_view_name,
							 const char* output_view_comments,
							 bool print_seq, bool print_count,
						     double threshold, bool normalize, int reference, bool similarity_mode,
							 int thread_count)
{
	index_t         i, j, k;
	index_t         seq_count;
	index_t         id1_idx, id2_idx;
	index_t         seq1_idx, seq2_idx;
	int             count1 = 0;
	int				count2 = 0;
	double          score;
	int             lcs_length;
	int             ali_length;
	Kmer_table_p    ktable;
	Obi_blob_p      blob1;
	Obi_blob_p   	blob2;
	int				lcs_min;
	index_t         seq_elt_idx;

	OBIDMS_p        dms = NULL;
	Obiview_p       seq_view = NULL;
	Obiview_p       output_view = NULL;
	OBIDMS_column_p iseq_column = NULL;
	OBIDMS_column_p i_count_column = NULL;
	OBIDMS_column_p id_column = NULL;
	OBIDMS_column_p id1_column = NULL;
	OBIDMS_column_p id2_column = NULL;
	OBIDMS_column_p seq1_column = NULL;
	OBIDMS_column_p seq2_column = NULL;
	OBIDMS_column_p count1_column = NULL;
	OBIDMS_column_p count2_column = NULL;
	OBIDMS_column_p idx1_column = NULL;
	OBIDMS_column_p idx2_column = NULL;
	OBIDMS_column_p lcs_length_column = NULL;
	OBIDMS_column_p ali_length_column = NULL;
	OBIDMS_column_p score_column = NULL;

	signal(SIGINT, sig_handler);

	k = 0;

	// Open DMS
	dms = obi_open_dms(dms_name, false);
	if (dms == NULL)
	{
		obidebug(1, "\nError opening the DMS");
		return -1;
	}

	// Open input view
	seq_view = obi_open_view(dms, seq_view_name);
	if (seq_view == NULL)
	{
		obidebug(1, "\nError opening the input view to align");
		return -1;
	}

	// Open the sequence column to align
	// If a column name wasn't given, open default sequence column
	if (strcmp(seq_column_name, "") == 0)  // TODO check for NULL
	{
		if (strcmp((seq_view->infos)->view_type, VIEW_TYPE_NUC_SEQS) == 0)
			iseq_column = obi_view_get_column(seq_view, NUC_SEQUENCE_COLUMN);
		else
		{
			obi_set_errno(OBI_ALIGN_ERROR);
			obidebug(1, "\nError: no column given to align");
			return -1;
		}
	}
	else
		iseq_column = obi_view_get_column(seq_view, seq_column_name);
	if (iseq_column == NULL)
	{
		obidebug(1, "\nError getting the column to align");
		return -1;
	}

	// Check column type
	if ((iseq_column->header)->returned_data_type != OBI_SEQ)
	{
		obi_set_errno(OBI_ALIGN_ERROR);
		obidebug(1, "\nError: column given to align is not an OBI_SEQ column");
		return -1;
	}

	// Get element index of the sequence to align in each line to compute it only once
	if ((strcmp(seq_elt_name, "") != 0) && (seq_elt_name != NULL))
	{
		seq_elt_idx = obi_column_get_element_index_from_name(iseq_column, seq_elt_name);
		if (seq_elt_idx == OBIIdx_NA)
		{
			obidebug(1, "\nError getting the sequence index in a column line when aligning");
			return -1;
		}
	}
	else
		seq_elt_idx = 0;

	// Open the ID column, containing the identifiers of the sequences to align
	// If a column name wasn't given, open default ID column
	if (strcmp(id_column_name, "") == 0)
	{
		if (strcmp((seq_view->infos)->view_type, VIEW_TYPE_NUC_SEQS) == 0)
			id_column = obi_view_get_column(seq_view, ID_COLUMN);
		else
		{
			obi_set_errno(OBI_ALIGN_ERROR);
			obidebug(1, "\nError: no ID column given");
			return -1;
		}
	}
	else
		id_column = obi_view_get_column(seq_view, id_column_name);
	if (id_column == NULL)
	{
		obidebug(1, "\nError getting the ID column");
		return -1;
	}

	// Open the input count column
	if (print_count)
	{
		i_count_column = obi_view_get_column(seq_view, COUNT_COLUMN);
		if (i_count_column == NULL)
		{
			obidebug(1, "\nError getting the input COUNT column");
			return -1;
		}
	}

	// Create the output view
	output_view = obi_new_view(dms, output_view_name, NULL, NULL, output_view_comments);
	if (output_view == NULL)
	{
		obidebug(1, "\nError creating the output view when aligning");
		return -1;
	}

	// Create the output columns
	if (create_alignment_output_columns(output_view,
			(id_column->header)->indexer_name, (id_column->header)->indexer_name,
			(iseq_column->header)->indexer_name, (iseq_column->header)->indexer_name,
			print_seq, print_count, normalize, reference, similarity_mode) < 0)
		return -1;
	id1_column = obi_view_get_column(output_view, ID1_COLUMN_NAME);
	id2_column = obi_view_get_column(output_view, ID2_COLUMN_NAME);
	idx1_column = obi_view_get_column(output_view, IDX1_COLUMN_NAME);
	idx2_column = obi_view_get_column(output_view, IDX2_COLUMN_NAME);
    lcs_length_column = obi_view_get_column(output_view, LCS_LENGTH_COLUMN_NAME);
	if ((reference == ALILEN) && (normalize || !similarity_mode))
		ali_length_column = obi_view_get_column(output_view, ALI_LENGTH_COLUMN_NAME);
	score_column = obi_view_get_column(output_view, SCORE_COLUMN_NAME);
	if (print_seq)
	{
		seq1_column = obi_view_get_column(output_view, SEQ1_COLUMN_NAME);
		seq2_column = obi_view_get_column(output_view, SEQ2_COLUMN_NAME);
	}
	if (print_count)
	{
		count1_column = obi_view_get_column(output_view, COUNT1_COLUMN_NAME);
		count2_column = obi_view_get_column(output_view, COUNT2_COLUMN_NAME);
	}

	// Build kmer tables
	ktable = hash_seq_column(seq_view, iseq_column, seq_elt_idx);
	if (ktable == NULL)
	{
		obi_set_errno(OBI_ALIGN_ERROR);
		obidebug(1, "\nError building kmer tables before aligning");
		return -1;
	}

	seq_count = (seq_view->infos)->line_count;

	#ifdef OMP_SUPPORT
	omp_set_num_threads(thread_count);
	#pragma omp parallel for
	#endif

	for (i=0; i < (seq_count - 1); i++)
	{
		if (i%100 == 0)
			fprintf(stderr,"\rDone : %f %%       ", (i / (float) seq_count)*100);

		if (! keep_running)
			return -1;

		// Get first id idx
		id1_idx = obi_get_index_with_elt_idx_and_col_p_in_view(seq_view, id_column, i, 0);	// TODO Could there be multiple IDs per line?
		// Get first sequence and its index
		seq1_idx = obi_get_index_with_elt_idx_and_col_p_in_view(seq_view, iseq_column, i, seq_elt_idx);
		blob1 = obi_get_blob_with_elt_idx_and_col_p_in_view(seq_view, iseq_column, i, seq_elt_idx);
		if (blob1 == NULL)
		{
			obidebug(1, "\nError retrieving sequences to align");
			return -1;
		}

		for (j=i+1; j < seq_count; j++)
		{
			// Get second sequence and its index
			seq2_idx = obi_get_index_with_elt_idx_and_col_p_in_view(seq_view, iseq_column, j, seq_elt_idx);
			blob2 = obi_get_blob_with_elt_idx_and_col_p_in_view(seq_view, iseq_column, j, seq_elt_idx);
			if (blob2 == NULL)
			{
				obidebug(1, "\nError retrieving sequences to align");
				return -1;
			}

			// Check if the sequences are identical in a quick way (same index in the same indexer)
			if (obi_get_index_with_elt_idx_and_col_p_in_view(seq_view, iseq_column, i, seq_elt_idx) == obi_get_index_with_elt_idx_and_col_p_in_view(seq_view, iseq_column, j, seq_elt_idx))
			{
				if (similarity_mode && normalize)
					score = 1.0;
				else if (!similarity_mode)
					score = 0.0;
				else
					score = blob1->length_decoded_value;
			}

			else // the sequences aren't identical
			{
				// kmer filter
				align_filters(ktable, blob1, blob2, i, j, threshold, normalize, reference, similarity_mode, &score, &lcs_min, false);

				// Compute alignment score
				if ((threshold == 0) || (score == -1.0))	// no threshold, or filter passed: align
					score = obiblob_sse_banded_lcs_align(blob1, blob2, threshold, normalize, reference, similarity_mode, &lcs_length, &ali_length);
			}

			if ((score >= 0) && (((normalize || similarity_mode) && (score >= threshold)) || ((!similarity_mode && !normalize) && (score <= threshold))))
			{	// Print result

				// Get second id idx
				id2_idx = obi_get_index_with_elt_idx_and_col_p_in_view(seq_view, id_column, j, 0);

				// Get counts  // TODO use array for efficiency?
				if (print_count)
				{
					count1 = obi_get_int_with_elt_idx_and_col_p_in_view(seq_view, i_count_column, i, 0);
					count2 = obi_get_int_with_elt_idx_and_col_p_in_view(seq_view, i_count_column, j, 0);
				}

				if (print_alignment_result(output_view, k,
										   idx1_column, idx2_column, i, j,
										   id1_column, id2_column, id1_idx, id2_idx,
						                   print_seq, seq1_column, seq2_column, seq1_idx, seq2_idx,
										   print_count, count1_column, count2_column, count1, count2,
										   ali_length_column, ali_length,
										   lcs_length_column, lcs_length,
										   score_column, score,
										   reference, normalize, similarity_mode) < 0)
					return -1;

				k++;
			}
		}
	}

	fprintf(stderr,"\rDone : 100 %%         \n");

	// Close views
	if (obi_save_and_close_view(seq_view) < 0)
	{
		obidebug(1, "\nError closing the input view after aligning");
		return -1;
	}
	if (obi_save_and_close_view(output_view) < 0)
	{
		obidebug(1, "\nError closing the output view after aligning");
		return -1;
	}

	if (obi_close_dms(dms, false) < 0)
	{
		obidebug(1, "\nError closing the DMS after aligning");
		return -1;
	}

	free_kmer_tables(ktable, seq_count);

	return 0;
}


int obi_lcs_align_two_columns(const char* dms_name,
							  const char* seq1_view_name,
							  const char* seq2_view_name,
							  const char* seq1_column_name,
							  const char* seq2_column_name,
							  const char* seq1_elt_name,
							  const char* seq2_elt_name,
							  const char* id1_column_name,
							  const char* id2_column_name,
					          const char* output_view_name,
							  const char* output_view_comments,
							  bool print_seq, bool print_count,
						      double threshold, bool normalize, int reference, bool similarity_mode)
{
	index_t         i, j, k;
	index_t         seq1_count;
	index_t         seq2_count;
	index_t         id1_idx, id2_idx;
	index_t         seq1_idx, seq2_idx;
	int             count1 = 0;
	int			    count2 = 0;
	double          score;
	int             lcs_length;
	int             ali_length;
	Kmer_table_p    ktable;
	Obi_blob_p      blob1;
	Obi_blob_p   	blob2;
	int				lcs_min;
	index_t         seq1_elt_idx;
	index_t         seq2_elt_idx;
	bool 			same_indexer;

	OBIDMS_p        dms = NULL;
	Obiview_p       seq1_view = NULL;
	Obiview_p       seq2_view = NULL;
	Obiview_p       output_view = NULL;
	OBIDMS_column_p i_seq1_column = NULL;
	OBIDMS_column_p i_seq2_column = NULL;
	OBIDMS_column_p i_id1_column = NULL;
	OBIDMS_column_p i_id2_column = NULL;
	OBIDMS_column_p i_count1_column = NULL;
	OBIDMS_column_p i_count2_column = NULL;
	OBIDMS_column_p id1_column = NULL;
	OBIDMS_column_p id2_column = NULL;
	OBIDMS_column_p seq1_column = NULL;
	OBIDMS_column_p seq2_column = NULL;
	OBIDMS_column_p count1_column = NULL;
	OBIDMS_column_p count2_column = NULL;
	OBIDMS_column_p idx1_column = NULL;
	OBIDMS_column_p idx2_column = NULL;
	OBIDMS_column_p lcs_length_column = NULL;
	OBIDMS_column_p ali_length_column = NULL;
	OBIDMS_column_p score_column = NULL;

	signal(SIGINT, sig_handler);

	k = 0;

	// Open DMS
	dms = obi_open_dms(dms_name, false);
	if (dms == NULL)
	{
		obidebug(1, "\nError opening the DMS to align");
		return -1;
	}

	// Open the first input view
	seq1_view = obi_open_view(dms, seq1_view_name);
	if (seq1_view == NULL)
	{
		obidebug(1, "\nError opening the first input view to align");
		return -1;
	}

	// Open the second input view. Same as 1st if ""
	if (strcmp(seq2_view_name, "") == 0)
		seq2_view = seq1_view;
	else
	{
		seq2_view = obi_open_view(dms, seq2_view_name);
		if (seq2_view == NULL)
		{
			obidebug(1, "\nError opening the second input view to align");
			return -1;
		}
	}

	// Open the first sequence column to align
	// If a column name wasn't given, open default sequence column
	if (strcmp(seq1_column_name, "") == 0)
	{
		if (strcmp((seq1_view->infos)->view_type, VIEW_TYPE_NUC_SEQS) == 0)
			i_seq1_column = obi_view_get_column(seq1_view, NUC_SEQUENCE_COLUMN);
		else
		{
			obi_set_errno(OBI_ALIGN_ERROR);
			obidebug(1, "\nError: no first column given to align");
			return -1;
		}
	}
	else
		i_seq1_column = obi_view_get_column(seq1_view, seq1_column_name);
	if (i_seq1_column == NULL)
	{
		obidebug(1, "\nError getting the first column to align");
		return -1;
	}

	// Check column type
	if ((i_seq1_column->header)->returned_data_type != OBI_SEQ)
	{
		obi_set_errno(OBI_ALIGN_ERROR);
		obidebug(1, "\nError: first column given to align is not an OBI_SEQ column");
		return -1;
	}

	// Open the second sequence column to align
	// If a column name wasn't given, open default sequence column
	if (strcmp(seq2_column_name, "") == 0)
	{
		if (strcmp((seq2_view->infos)->view_type, VIEW_TYPE_NUC_SEQS) == 0)
			i_seq2_column = obi_view_get_column(seq2_view, NUC_SEQUENCE_COLUMN);
		else
		{
			obi_set_errno(OBI_ALIGN_ERROR);
			obidebug(1, "\nError: no second column given to align");
			return -1;
		}
	}
	else
		i_seq2_column = obi_view_get_column(seq2_view, seq2_column_name);
	if (i_seq2_column == NULL)
	{
		obidebug(1, "\nError getting the second column to align");
		return -1;
	}
	// Check that the sequence columns are not both the default NUC_SEQ column of the same view
	if (i_seq1_column == i_seq2_column)
	{
		obidebug(1, "\nError: trying to align a column with itself (default NUC_SEQ column of the same view)");
		return -1;
	}

	// Check column type
	if ((i_seq2_column->header)->returned_data_type != OBI_SEQ)
	{
		obi_set_errno(OBI_ALIGN_ERROR);
		obidebug(1, "\nError: second column given to align is not an OBI_SEQ column");
		return -1;
	}

	// Get element index of the sequence to align in each line of the first column to compute it only once
	if ((strcmp(seq1_elt_name, "") != 0) && (seq1_elt_name != NULL))
	{
		seq1_elt_idx = obi_column_get_element_index_from_name(i_seq1_column, seq1_elt_name);
		if (seq1_elt_idx == OBIIdx_NA)
		{
			obidebug(1, "\nError getting the sequence index in a column line when aligning");
			return -1;
		}
	}
	else
		seq1_elt_idx = 0;

	// Get element index of the sequence to align in each line of the second column to compute it only once
	if ((strcmp(seq2_elt_name, "") != 0) && (seq2_elt_name != NULL))
	{
		seq2_elt_idx = obi_column_get_element_index_from_name(i_seq2_column, seq2_elt_name);
		if (seq2_elt_idx == OBIIdx_NA)
		{
			obidebug(1, "\nError getting the sequence index in a column line when aligning");
			return -1;
		}
	}
	else
		seq2_elt_idx = 0;


	// Open the first ID column, containing the identifiers of the first sequence to align
	// If a column name wasn't given, open default ID column
	if (strcmp(id1_column_name, "") == 0)
	{
		if (strcmp((seq1_view->infos)->view_type, VIEW_TYPE_NUC_SEQS) == 0)
			i_id1_column = obi_view_get_column(seq1_view, ID_COLUMN);
		else
		{
			obi_set_errno(OBI_ALIGN_ERROR);
			obidebug(1, "\nError: no first ID column given");
			return -1;
		}
	}
	else
		i_id1_column = obi_view_get_column(seq1_view, id1_column_name);
	if (i_id1_column == NULL)
	{
		obidebug(1, "\nError getting the first ID column");
		return -1;
	}

	// Open the second ID column, containing the identifiers of the second sequence to align
	// If a column name wasn't given, open default ID column
	if (strcmp(id2_column_name, "") == 0)
	{
		if (strcmp((seq2_view->infos)->view_type, VIEW_TYPE_NUC_SEQS) == 0)
			i_id2_column = obi_view_get_column(seq2_view, ID_COLUMN);
		else
		{
			obi_set_errno(OBI_ALIGN_ERROR);
			obidebug(1, "\nError: no second ID column given");
			return -1;
		}
	}
	else
		i_id2_column = obi_view_get_column(seq2_view, id2_column_name);
	if (i_id2_column == NULL)
	{
		obidebug(1, "\nError getting the second ID column");
		return -1;
	}

	// Open the input count columns
	if (print_count)
	{
		i_count1_column = obi_view_get_column(seq1_view, COUNT_COLUMN);
		if (i_count1_column == NULL)
		{
			obidebug(1, "\nError getting the first input COUNT column");
			return -1;
		}
		i_count2_column = obi_view_get_column(seq2_view, COUNT_COLUMN);
		if (i_count2_column == NULL)
		{
			obidebug(1, "\nError getting the second input COUNT column");
			return -1;
		}
	}

	// Create the output view
	output_view = obi_new_view(dms, output_view_name, NULL, NULL, output_view_comments);
	if (output_view == NULL)
	{
		obidebug(1, "\nError creating the output view when aligning");
		return -1;
	}

	// Create the output columns
	if (create_alignment_output_columns(output_view,
			(i_id1_column->header)->indexer_name, (i_id2_column->header)->indexer_name,
			(i_seq1_column->header)->indexer_name, (i_seq2_column->header)->indexer_name,
			print_seq, print_count, normalize, reference, similarity_mode) < 0)
		return -1;
	id1_column = obi_view_get_column(output_view, ID1_COLUMN_NAME);
	id2_column = obi_view_get_column(output_view, ID2_COLUMN_NAME);
	idx1_column = obi_view_get_column(output_view, IDX1_COLUMN_NAME);
	idx2_column = obi_view_get_column(output_view, IDX2_COLUMN_NAME);
    lcs_length_column = obi_view_get_column(output_view, LCS_LENGTH_COLUMN_NAME);
	if ((reference == ALILEN) && (normalize || !similarity_mode))
		ali_length_column = obi_view_get_column(output_view, ALI_LENGTH_COLUMN_NAME);
	score_column = obi_view_get_column(output_view, SCORE_COLUMN_NAME);
	if (print_seq)
	{
		seq1_column = obi_view_get_column(output_view, SEQ1_COLUMN_NAME);
		seq2_column = obi_view_get_column(output_view, SEQ2_COLUMN_NAME);
	}
	if (print_count)
	{
		count1_column = obi_view_get_column(output_view, COUNT1_COLUMN_NAME);
		count2_column = obi_view_get_column(output_view, COUNT2_COLUMN_NAME);
	}

	// Check if the sequence columns share the same indexer (allows for quick checking of sequence equality)
	if (strcmp((i_seq1_column->header)->indexer_name, (i_seq2_column->header)->indexer_name) == 0)
		same_indexer = true;
	else
		same_indexer = false;

	// Build kmer tables
	ktable = hash_two_seq_columns(seq1_view, i_seq1_column, seq1_elt_idx, seq2_view, i_seq2_column, seq2_elt_idx);
	if (ktable == NULL)
	{
		obi_set_errno(OBI_ALIGN_ERROR);
		obidebug(1, "\nError building kmer tables before aligning");
		return -1;
	}

	// TODO check this
	if (!similarity_mode && normalize && (threshold > 0))
		threshold = 1.0 - threshold;

	seq1_count = (seq1_view->infos)->line_count;
	seq2_count = (seq2_view->infos)->line_count;

	for (i=0; i < seq1_count; i++)
	{
		if (i%100 == 0)
			fprintf(stderr,"\rDone : %f %%       ", (i / (float) seq1_count)*100);

		// Get id index of first sequence
		id1_idx = obi_get_index_with_elt_idx_and_col_p_in_view(seq1_view, i_id1_column, i, 0); // TODO Could there be multiple IDs per line?
		// Get first sequence and its index
		seq1_idx = obi_get_index_with_elt_idx_and_col_p_in_view(seq1_view, i_seq1_column, i, seq1_elt_idx);
		blob1 = obi_get_blob_with_elt_idx_and_col_p_in_view(seq1_view, i_seq1_column, i, seq1_elt_idx);
		if (blob1 == NULL)
		{
			obidebug(1, "\nError retrieving sequences to align");
			return -1;
		}

		for (j=0; j < seq2_count; j++)
		{
			if (! keep_running)
				return -1;

			// Get second sequence and its index
			seq2_idx = obi_get_index_with_elt_idx_and_col_p_in_view(seq2_view, i_seq2_column, j, seq2_elt_idx);
			blob2 = obi_get_blob_with_elt_idx_and_col_p_in_view(seq2_view, i_seq2_column, j, seq2_elt_idx);
			if (blob2 == NULL)
			{
				obidebug(1, "\nError retrieving sequences to align");
				return -1;
			}

			// Check if the sequences are identical in a quick way (same index in the same indexer)
			if (same_indexer && (seq1_idx == seq2_idx))
			{
				if (similarity_mode && normalize)
					score = 1.0;
				else if (!similarity_mode)
					score = 0.0;
				else
					score = blob1->length_decoded_value;
			}

			else // the sequences aren't identical or we don't know
			{
				// kmer filter (offset for the index of the kmer table of the 2nd sequence because the kmer tables of the 2 sequence columns are concatenated in one)
				align_filters(ktable, blob1, blob2, i, seq1_count+j, threshold, normalize, reference, similarity_mode, &score, &lcs_min, !same_indexer);

				// Compute alignment score
				if ((score < 0) && ((threshold == 0) || (score == -1.0)))	// (sequences are not identical), and (no threshold, or filter passed): align
					score = obiblob_sse_banded_lcs_align(blob1, blob2, threshold, normalize, reference, similarity_mode, &lcs_length, &ali_length);

				// TODO check this
//				if (print && !lcsmode && normalize)
//					score = 1.0 - score;

			}

			if ((score >= 0) && (((normalize || similarity_mode) && (score >= threshold)) || ((!similarity_mode && !normalize) && (score <= threshold))))
			{	// Print result

				// Get second id idx
				id2_idx = obi_get_index_with_elt_idx_and_col_p_in_view(seq2_view, i_id2_column, j, 0);

				// Get counts  // TODO use array for efficiency?
				if (print_count)
				{
					count1 = obi_get_int_with_elt_idx_and_col_p_in_view(seq1_view, i_count1_column, i, 0);
					count2 = obi_get_int_with_elt_idx_and_col_p_in_view(seq2_view, i_count2_column, j, 0);
				}

				if (print_alignment_result(output_view, k,
										   idx1_column, idx2_column, i, j,
										   id1_column, id2_column, id1_idx, id2_idx,
						                   print_seq, seq1_column, seq2_column, seq1_idx, seq2_idx,
										   print_count, count1_column, count2_column, count1, count2,
										   ali_length_column, ali_length,
										   lcs_length_column, lcs_length,
										   score_column, score,
										   reference, normalize, similarity_mode) < 0)
					return -1;

				k++;
			}
		}
	}

	// Close views
	if (seq2_view != seq1_view)
	{
		if (obi_save_and_close_view(seq2_view) < 0)
		{
			obidebug(1, "\nError closing the second input view after aligning");
			return -1;
		}
	}
	if (obi_save_and_close_view(seq1_view) < 0)
	{
		obidebug(1, "\nError closing the first input view after aligning");
		return -1;
	}

	if (obi_save_and_close_view(output_view) < 0)
	{
		obidebug(1, "\nError closing the output view after aligning");
		return -1;
	}

	if (obi_close_dms(dms, false) < 0)
	{
		obidebug(1, "\nError closing the DMS after aligning");
		return -1;
	}

	free_kmer_tables(ktable, seq1_count + seq2_count);

	return 0;
}

