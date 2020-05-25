/****************************************************************************
 * LCS sequence alignment functions header file	                            *
 ****************************************************************************/

/**
 * @file obi_lcs.h
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 * @date May 11th 2016
 * @brief Header file for the functions handling the LCS alignment of DNA sequences.
 */


#ifndef OBI_LCS_H_
#define OBI_LCS_H_


#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>

#include "obidms.h"
#include "obiview.h"
#include "obidmscolumn.h"
#include "obitypes.h"


/**
 * @brief Names and comments of columns automatically created in the output view when aligning.
 *
 * @since December 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
#define ID1_COLUMN_NAME "ID1"
#define ID1_COLUMN_COMMENTS "{}"
#define ID2_COLUMN_NAME "ID2"
#define ID2_COLUMN_COMMENTS "{}"
#define SEQ1_COLUMN_NAME "SEQ1"
#define SEQ1_COLUMN_COMMENTS "{}"
#define SEQ2_COLUMN_NAME "SEQ2"
#define SEQ2_COLUMN_COMMENTS "{}"
#define COUNT1_COLUMN_NAME "COUNT1"
#define COUNT1_COLUMN_COMMENTS "{}"
#define COUNT2_COLUMN_NAME "COUNT2"
#define COUNT2_COLUMN_COMMENTS "{}"
#define IDX1_COLUMN_NAME "IDX1"
#define IDX1_COLUMN_COMMENTS "{}"
#define IDX2_COLUMN_NAME "IDX2"
#define IDX2_COLUMN_COMMENTS "{}"
#define LCS_LENGTH_COLUMN_NAME "LCS_LENGTH"
#define LCS_LENGTH_COLUMN_COMMENTS "{}"
#define ALI_LENGTH_COLUMN_NAME "LCS_ALI_LENGTH"
#define ALI_LENGTH_COLUMN_COMMENTS "{}"
#define SCORE_COLUMN_NAME "LCS_SCORE"
#define SCORE_COLUMN_COMMENTS "{}"


/**
 * @brief Aligns an OBI_SEQ column with itself.
 *
 * Note: The columns where the results are written are automatically named and created.
 *
 * @param dms_name The path of the DMS.
 * @param seq_view_name The name of the view where the column to align is.
 * @param seq_column_name The name of the OBI_SEQ column in the input view to align.
 *                        If "" (empty string), and the input view is of type NUC_SEQS_VIEW, the associated "NUC_SEQ" column is aligned.
 * @param seq_elt_name The name of the element in the column corresponding to the sequence to align, if the column has multiple
 *                     elements per line.
 * @param id_column_name The name of the column in the input view containing the identifiers of the sequences to align.
 *                       If "" (empty string), and the input view is of type NUC_SEQS_VIEW, the associated "ID" column is aligned.
 * @param output_view_name The name of the output view where the results should be written (should not already exist).
 * @param output_view_comments The comments that should be associated with the output view.
 * @param print_seq A boolean indicating whether the aligned sequences should be copied in the output view.
 * @param print_count A boolean indicating whether the aligned sequence counts should be copied in the output view.
 * @param threshold Score threshold. If the score is normalized and expressed in similarity, it is an identity, e.g. 0.95
 * 					for an identity of 95%. If the score is normalized and expressed in distance, it is (1.0 - identity),
 * 					e.g. 0.05 for an identity of 95%. If the score is not normalized and expressed in similarity, it is
 * 					the length of the Longest Common Subsequence. If the score is not normalized and expressed in distance,
 *                  it is (reference length - LCS length). Only sequence pairs with a similarity above the threshold are printed.
 * @param normalize Whether the score should be normalized with the reference sequence length.
 * @param reference The reference length. 0: The alignment length; 1: The longest sequence's length; 2: The shortest sequence's length.
 * @param similarity_mode Whether the score should be expressed in similarity (true) or distance (false).
 *
 * @returns A value indicating the success of the operation.
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since May 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_lcs_align_one_column(const char* dms_name,
							 const char* seq_view_name,
							 const char* seq_column_name,
							 const char* seq_elt_name,
							 const char* id_column_name,
					         const char* output_view_name,
							 const char* output_view_comments,
							 bool print_seq, bool print_count,
						     double threshold, bool normalize, int reference, bool similarity_mode,
							 int thread_count);


/**
 * @brief Aligns two OBI_SEQ columns.
 *
 * The columns must belong to the same OBIDMS, but can belong to different views.
 *
 * Note: The columns where the results are written are automatically named and created.
 *
 * @param dms_name The path of the DMS.
 * @param seq1_view_name The name of the view where the first column to align is.
 * @param seq2_view_name The name of the view where the second column to align is ("" if it is the same view as the first one).
 * @param seq1_column_name The name of the first OBI_SEQ column in the input view to align.
 *                         If "" (empty string), and the input view is of type NUC_SEQS_VIEW, the associated "NUC_SEQ" column is aligned.
 * @param seq2_column_name The name of the second OBI_SEQ column in the input view to align.
 *                         If "" (empty string), and the input view is of type NUC_SEQS_VIEW, the associated "NUC_SEQ" column is aligned.
 * @param seq1_elt_name The name of the element in the first column corresponding to the sequence to align, if the column has multiple
 *                      elements per line.
 * @param seq2_elt_name The name of the element in the second column corresponding to the sequence to align, if the column has multiple
 *                      elements per line.
 * @param id1_column_name The name of the column in the first input view containing the identifiers of the first sequence to align.
 *                        If "" (empty string), and the input view is of type NUC_SEQS_VIEW, the associated "ID" column is aligned.
 * @param id2_column_name The name of the column in the second input view containing the identifiers of the second sequence to align.
 *                        If "" (empty string), and the input view is of type NUC_SEQS_VIEW, the associated "ID" column is aligned.
 * @param output_view_name The name of the output view where the results should be written (should not already exist).
 * @param output_view_comments The comments that should be associated with the output view.
 * @param print_seq A boolean indicating whether the aligned sequences should be copied in the output view.
 * @param print_count A boolean indicating whether the aligned sequence counts should be copied in the output view.
 * @param threshold Score threshold. If the score is normalized and expressed in similarity, it is an identity, e.g. 0.95
 * 					for an identity of 95%. If the score is normalized and expressed in distance, it is (1.0 - identity),
 * 					e.g. 0.05 for an identity of 95%. If the score is not normalized and expressed in similarity, it is
 * 					the length of the Longest Common Subsequence. If the score is not normalized and expressed in distance,
 *                  it is (reference length - LCS length). Only sequence pairs with a similarity above the threshold are printed.
 * @param normalize Whether the score should be normalized with the reference sequence length.
 * @param reference The reference length. 0: The alignement length; 1: The longest sequence's length; 2: The shortest sequence's length.
 * @param similarity_mode Whether the score should be expressed in similarity (true) or distance (false).
 *
 * @returns A value indicating the success of the operation.
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since December 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
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
						      double threshold, bool normalize, int reference, bool similarity_mode);


#endif /* OBI_LCS_H_ */

