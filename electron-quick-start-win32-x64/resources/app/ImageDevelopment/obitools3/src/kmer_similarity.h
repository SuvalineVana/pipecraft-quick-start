/****************************************************************************
 * Header file for Kmer similarity computation functions                    *
 ****************************************************************************/

/**
 * @file kmer_similarity.h
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 * @date January 7th 2019
 * @brief Header file for Kmer similarity computation functions.
 */


#ifndef KMER_SIMILARITY_H_
#define KMER_SIMILARITY_H_

#include <stdio.h>

#include "obitypes.h"
#include "obidmscolumn.h"
#include "obiview.h"


#define ARRAY_LENGTH (256)


/**
 * @brief Alignment structure, with informations about the similarity and to rebuild the alignment.
 */
typedef struct Obi_ali {
	int      score;	    		/**< Alignment score, corresponding to the number of nucleotides in the longest stretch of kmers perfectly matching.
	 	 	 	 	 	 	 	 */
	int      consensus_length; 	/**< Length of the final consensus sequence.
	 	 	 	 	 	 	 	 */
	int      overlap_length;	/**< Length of the overlap between the aligned sequences.
	 	 	 	 	 	 	 	 */
	char*    consensus_seq; 	/**< Consensus sequence built as to reconstruct a pairedend read.
	 	 	 	 	 	 	 	 */
	uint8_t* consensus_qual;	/**< Consensus quality built as to reconstruct a pairedend read.
	 	 	 	        	 	 */
	int		 shift;   		    /**< Shift chosen to align the sequences.
	 	 	 	 	 	 	 	 */
	char     direction[6]; 	    /**< Alignment direction (positive/right or negative/left shift).
								 */
} Obi_ali_t, *Obi_ali_p;


/**
 * @brief Frees an Obi_ali_p structure and all its elements.
 *
 * @warning The pointer sent becomes unusable.
 *
 * @param ali The pointer on the Obi_ali_p structure to free.
 *
 * @since January 2019
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
void obi_free_shifted_ali(Obi_ali_p ali);


/**
 * Function computing the kmer similarity of two sequences stored in views.
 *
 * The similarity is computing this way: the positions of identical kmers in both sequences are
 * compared, and the most represented shift is chosen. The similarity is then calculated as:
 * kmer_similarity = number_of_common_kmers_with_the_chosen_shift + kmer_size - 1
 *
 * @warning Several pointers and structures passed to or returned by the function have to be freed by the caller:
 * 			  - kmer_pos_array
 * 			  - shift_array
 * 			  - shift_count_array
 * 			  - the Obi_ali_p structure returned
 *
 * @param view1 A pointer on the view containing the first sequence.
 * @param column1 A pointer on the column containing the first sequence.
 * @param idx1 The index of the first sequence in view1.
 * @param elt_idx1 The element index of the first sequence in column1.
 * @param view2 A pointer on the view containing the second sequence.
 * @param column2 A pointer on the column containing the second sequence.
 * @param idx2 The index of the second sequence in view2.
 * @param elt_idx2 The element index of the second sequence in column2.
 * @param qual_col1 A pointer on the column containing the quality associated with the first sequence (in view1).
 * @param qual_col2 A pointer on the column containing the quality associated with the second sequence (in view2).
 * @param reversed_column A pointer on the column containing a boolean indicating whether the sequences correspond
 * 						  to paired-end reads that might have been reversed before aligning them
 * 						  (e.g. when the ngsfilter tool is used before alignpairedend).
 * @param kmer_size The kmer length to use. Must be >= 1 <= 4.
 * @param kmer_pos_array The array used to store kmer positions. If NULL, allocated by the function.
 *        If needed, reallocated to a bigger size.
 * @param kmer_pos_array_height_p A pointer on an integer corresponding to the size (number of elements)
 *        allocated for kmer_pos_array. Updated by the function as needed.
 * @param shift_array The array used to store kmer shifts. If NULL, allocated by the function.
 *        If needed, reallocated to a bigger size.
 * @param shift_array_height_p A pointer on an integer corresponding to the size (number of elements)
 *        allocated for shift_array. Updated by the function as needed.
 * @param shift_count_array The array used to store shift counts. If NULL, allocated by the function.
 *        If needed, reallocated to a bigger size.
 * @param shift_count_array_height_p A pointer on an integer corresponding to the size (number of elements)
 *        allocated for shift_count_array. Updated by the function as needed.
 * @param build_consensus A boolean indicating whether the function should build the consensus sequence and quality as to reconstruct a pairedend read. // TODO option to build consensus without quality?
 *
 * @returns A pointer on an Obi_ali_p structure containing the results.
 * @retval NULL if an error occurred.
 *
 * @since January 2019
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
Obi_ali_p kmer_similarity(Obiview_p view1,
						  OBIDMS_column_p column1,
						  index_t idx1,
						  index_t elt_idx1,
						  Obiview_p view2,
						  OBIDMS_column_p column2,
						  index_t idx2,
						  index_t elt_idx2,
						  OBIDMS_column_p qual_col1,
						  OBIDMS_column_p qual_col2,
						  OBIDMS_column_p reversed_column,
						  uint8_t kmer_size,
						  int32_t** kmer_pos_array_p,
						  int32_t* kmer_pos_array_height_p,
						  int32_t** shift_array_p,
						  int32_t* shift_array_height_p,
						  int32_t** shift_count_array_p,
						  int32_t* shift_count_array_height_p,
						  bool build_consensus);


#endif /* KMER_SIMILARITY_H_ */
