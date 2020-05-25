/****************************************************************************
 * LCS alignment of two sequences header file                               *
 ****************************************************************************/

/**
 * @file sse_banded_LCS_alignment.h
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 * @date November 7th 2012
 * @brief header file for the functions handling the alignment of two sequences to compute their Longest Common Sequence.
 */


#ifndef SSE_BANDED_LCS_ALIGNMENT_H_
#define SSE_BANDED_LCS_ALIGNMENT_H_


#include <stdint.h>
#include <stdbool.h>

#include "obiblob.h"


/**
 * @brief Macros for reference lengths to use when aligning.
 *
 * @since 2012
 * @author Eric Coissac (eric.coissac@metabarcoding.org)
 */
#define ALILEN (0)
#define MAXLEN (1)
#define MINLEN (2)


/**
 * @brief Function calculating the minimum length of the Longest Common Subsequence between two sequences to be above a chosen score threshold.
 *
 * @warning The first argument (lmax) must correspond to length of the longest sequence.
 *
 * @param lmax The length of the longest sequence to align.
 * @param lmin The length of the shortest sequence to align.
 * @param threshold Score threshold. If the score is normalized and expressed in similarity, it is an identity, e.g. 0.95
 * 					for an identity of 95%. If the score is normalized and expressed in distance, it is (1.0 - identity),
 * 					e.g. 0.05 for an identity of 95%. If the score is not normalized and expressed in similarity, it is
 * 					the length of the Longest Common Subsequence. If the score is not normalized and expressed in distance,
 *                  it is (reference length - LCS length). Only sequence pairs with a similarity above the threshold are printed.
 * @param normalize Whether the score should be normalized with the reference sequence length.
 * @param reference The reference length. 0: The alignment length; 1: The longest sequence's length; 2: The shortest sequence's length.	// TODO
 * @param similarity_mode Whether the score should be expressed in similarity (true) or distance (false).
 *
 * @returns The minimum length of the Longest Common Subsequence between two sequences to be above the chosen score threshold.
 *
 * @since 2012
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int calculateLCSmin(int lmax, int lmin, double threshold, bool normalize, int reference, bool similarity_mode);


/**
 * @brief Function aligning two sequences.
 *
 * The alignment algorithm is a banded global alignment algorithm, a modified version of the classical Needleman and Wunsch algorithm,
 * and uses indices based on the length of the Longest Common Subsequence between the two sequences.
 *
 * Note: the sequences do not need to be ordered (e.g. with the longest sequence as first argument).
 *
 * @param seq1 A pointer on the character string corresponding to the first sequence.
 * @param seq2 A pointer on the character string corresponding to the second sequence.
 * @param threshold Score threshold. If the score is normalized and expressed in similarity, it is an identity, e.g. 0.95
 * 					for an identity of 95%. If the score is normalized and expressed in distance, it is (1.0 - identity),
 * 					e.g. 0.05 for an identity of 95%. If the score is not normalized and expressed in similarity, it is
 * 					the length of the Longest Common Subsequence. If the score is not normalized and expressed in distance,
 *                  it is (reference length - LCS length). Only sequence pairs with a similarity above the threshold are printed.
 * @param normalize Whether the score should be normalized with the reference sequence length.
 * @param reference The reference length. 0: The alignment length; 1: The longest sequence's length; 2: The shortest sequence's length.	// TODO
 * @param similarity_mode Whether the score should be expressed in similarity (true) or distance (false).
 * @param lcs_length A pointer on the int where the LCS length will be stored.
 * @param ali_length A pointer on the int where the alignment length will be stored.
 *
 * @returns The alignment score (normalized according to the parameters).
 *
 * @since 2012
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
double generic_sse_banded_lcs_align(char* seq1, char* seq2, double threshold, bool normalize, int reference, bool similarity_mode, int* lcs_length, int* ali_length);


/**
 * @brief Function aligning two sequences encoded in obiblobs.
 *
 * The alignment algorithm is a banded global alignment algorithm, a modified version of the classical Needleman and Wunsch algorithm,
 * and uses indices based on the length of the Longest Common Subsequence between the two sequences.
 *
 * Note: the obiblobs do not need to be ordered (e.g. with the obiblob containing the longest sequence as first argument).
 *
 * @param seq1 A pointer on the blob containing the first sequence.
 * @param seq2 A pointer on the blob containing the second sequence.
 * @param threshold Score threshold. If the score is normalized and expressed in similarity, it is an identity, e.g. 0.95
 * 					for an identity of 95%. If the score is normalized and expressed in distance, it is (1.0 - identity),
 * 					e.g. 0.05 for an identity of 95%. If the score is not normalized and expressed in similarity, it is
 * 					the length of the Longest Common Subsequence. If the score is not normalized and expressed in distance,
 *                  it is (reference length - LCS length). Only sequence pairs with a similarity above the threshold are printed.
 * @param normalize Whether the score should be normalized with the reference sequence length.
 * @param reference The reference length. 0: The alignment length; 1: The longest sequence's length; 2: The shortest sequence's length.	// TODO
 * @param similarity_mode Whether the score should be expressed in similarity (true) or distance (false).
 * @param lcs_length A pointer on the int where the LCS length will be stored.
 * @param ali_length A pointer on the int where the alignment length will be stored.
 *
 * @returns The alignment score (normalized according to the parameters).
 *
 * @since December 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
double obiblob_sse_banded_lcs_align(Obi_blob_p seq1, Obi_blob_p seq2, double threshold, bool normalize, int reference, bool similarity_mode, int* lcs_length, int* ali_length);


#endif
