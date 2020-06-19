/****************************************************************************
 * Kmer similarity computation functions                                      *
 ****************************************************************************/

/**
 * @file kmer_similarity.c
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 * @date January 7th 2019
 * @brief Kmer similarity computation functions.
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <inttypes.h>

#include "utils.h"
#include "obidebug.h"
#include "obierrno.h"
#include "obitypes.h"

#include "kmer_similarity.h"
#include "obidmscolumn.h"
#include "obiview.h"
#include "encode.h"
#include "dna_seq_indexer.h"


#define DEBUG_LEVEL 0	// TODO has to be defined somewhere else (cython compil flag?)



/**************************************************************************
 *
 * D E C L A R A T I O N   O F   T H E   P R I V A T E   F U N C T I O N S
 *
 **************************************************************************/




/************************************************************************
 *
 * D E F I N I T I O N   O F   T H E   P R I V A T E   F U N C T I O N S
 *
 ************************************************************************/




/**********************************************************************
 *
 * D E F I N I T I O N   O F   T H E   P U B L I C   F U N C T I O N S
 *
 **********************************************************************/


void obi_free_shifted_ali(Obi_ali_p ali)
{
	free(ali->consensus_seq);
	free(ali->consensus_qual);
	free(ali);
}


Obi_ali_p kmer_similarity(Obiview_p view1, OBIDMS_column_p column1, index_t idx1, index_t elt_idx1,
						  Obiview_p view2, OBIDMS_column_p column2, index_t idx2, index_t elt_idx2,
						  OBIDMS_column_p qual_col1, OBIDMS_column_p qual_col2, OBIDMS_column_p reversed_column,
						  uint8_t kmer_size,
						  int32_t** kmer_pos_array_p, int32_t* kmer_pos_array_height_p,
						  int32_t** shift_array_p, int32_t* shift_array_height_p,
						  int32_t** shift_count_array_p, int32_t* shift_count_array_length_p,
						  bool build_consensus)
{
	int32_t*        kmer_pos_array;
	int32_t*        shift_array;
	int32_t*        shift_count_array;
	Obi_ali_p       ali = NULL;
	int 			i, j;
	bool 			switched_seqs;
	bool			reversed;
	int 			score = 0;
	Obi_blob_p      blob1 = NULL;
	Obi_blob_p   	blob2 = NULL;
	Obi_blob_p   	temp_blob = NULL;
	char*			seq1 = NULL;
	char*			seq2 = NULL;
	int32_t         len1;
	int32_t         len2;
	int32_t			temp_len;
	int32_t         pos;
	int32_t         shift1;
	int32_t         shift2;
	const uint8_t*  qual1;
	const uint8_t*  qual2;
	int             qual1_len;
	int				qual2_len;
	char*           consensus_seq;
	uint8_t*        consensus_qual;
	int32_t  		empty_part;
	int32_t	        nuc_idx;
	int32_t    		kmer_idx;
	int32_t	        kmer_count;
	int32_t         best_shift_idx;
	int32_t         best_shift;
	int32_t         abs_shift;
	int32_t         max_common_kmers;
	int32_t         overlap_len;
	int32_t         consensus_len;
	int32_t  		cons_shift;
	int32_t  		copy_start;
	int32_t  		copy_len;
	uint8_t   		kmer;
	byte_t          nuc;
	uint8_t         encoding;
	int             total_len;
	int             shift;
	int32_t  		shift_idx;
	int32_t         kmer_pos_array_height    = *kmer_pos_array_height_p;
	int32_t         shift_array_height       = *shift_array_height_p;
	int32_t         shift_count_array_length = *shift_count_array_length_p;
	bool			free_blob1 = false;
	bool			keep_seq1_start;
	bool			keep_seq2_start;
	bool			keep_seq1_end;
	bool			keep_seq2_end;

	// Check kmer size
	if ((kmer_size < 1) || (kmer_size > 4))
	{
		obi_set_errno(OBI_ALIGN_ERROR);
		obidebug(1, "\nError when computing the kmer similarity between two sequences: the kmer size must be >= 1 or <= 4");
		return NULL;
	}

	// Get sequence blobs
	blob1 = obi_get_blob_with_elt_idx_and_col_p_in_view(view1, column1, idx1, elt_idx1);
	if (blob1 == NULL)
	{
	 	obidebug(1, "\nError getting the blob of the 1st sequence when computing the kmer similarity between two sequences");
	 	return NULL;
	}
	blob2 = obi_get_blob_with_elt_idx_and_col_p_in_view(view2, column2, idx2, elt_idx2);
	if (blob2 == NULL)
	{
	 	obidebug(1, "\nError getting the blob of the 2nd sequence when computing the kmer similarity between two sequences");
	 	return NULL;
	}

	// Choose the shortest sequence to save kmer positions in array
	switched_seqs = false;
	len1 = blob1->length_decoded_value;
	len2 = blob2->length_decoded_value;
	if (len2 < len1)
	{
		switched_seqs = true;
		temp_len = len1;
		len1 = len2;
		len2 = temp_len;
		temp_blob = blob1;
		blob1 = blob2;
		blob2 = temp_blob;
	}

	// Force encoding on 2 bits by replacing ambiguous nucleotides by 'a's
	if (blob1->element_size == 4)
	{
		seq1 = obi_blob_to_seq(blob1);
		for (i=0; i<len1; i++)
		{
			if (seq1[i] != 'a' && seq1[i] != 't' && seq1[i] != 'g' && seq1[i] != 'c')
				seq1[i] = 'a';
		}
		blob1 = obi_seq_to_blob(seq1);
		free_blob1 = true;
	}
	if (blob2->element_size == 4)
	{
		seq2 = obi_blob_to_seq(blob2);
		for (i=0; i<len2; i++)
		{
			if (seq2[i] != 'a' && seq2[i] != 't' && seq2[i] != 'g' && seq2[i] != 'c')
				seq2[i] = 'a';
		}
	}

	// Reverse complement the other sequence    // TODO blob to seq to blob for now, could be more efficient
	if (seq2 == NULL)
		seq2 = obi_blob_to_seq(blob2);
	seq2 = reverse_complement_sequence(seq2);
	blob2 = obi_seq_to_blob(seq2);

	// Check if the sequences have been reverse-complemented by the ngsfilter tool
	if (reversed_column != NULL)
		reversed = obi_get_bool_with_elt_idx_and_col_p_in_view(view1, reversed_column, idx1, 0); // assuming that reversed_column is in view1 is dirty but faster
	else
		reversed = false;
	if (reversed)
		switched_seqs = !switched_seqs;

	// Save total length for the shift counts array
	total_len = len1 + len2 + 1;   // +1 for shift 0

	// Allocate or reallocate memory for the array of shift counts if necessary
	if (*shift_count_array_p == NULL)
	{
		shift_count_array_length = total_len;
		*shift_count_array_p = (int32_t*) malloc(shift_count_array_length * sizeof(int32_t));
		if (*shift_count_array_p == NULL)
		{
		 	obi_set_errno(OBI_MALLOC_ERROR);
		 	obidebug(1, "\nError computing the kmer similarity between two sequences: error allocating memory");
		 	return NULL;
		}
	}
	else if (total_len >= shift_count_array_length)
	{
		shift_count_array_length = total_len;
		*shift_count_array_p = (int32_t*) realloc(*shift_count_array_p, shift_count_array_length * sizeof(int32_t));
		if (*shift_count_array_p == NULL)
		{
		 	obi_set_errno(OBI_MALLOC_ERROR);
		 	obidebug(1, "\nError computing the kmer similarity between two sequences: error allocating memory");
		 	return NULL;
		}
	}

	// Allocate or reallocate memory for the array of shifts if necessary
	if (*shift_array_p == NULL)
	{
		shift_array_height = total_len;
		*shift_array_p = (int32_t*) malloc(ARRAY_LENGTH * shift_array_height * sizeof(int32_t));
		if (*shift_array_p == NULL)
		{
		 	obi_set_errno(OBI_MALLOC_ERROR);
		 	obidebug(1, "\nError computing the kmer similarity between two sequences: error allocating memory");
		 	return NULL;
		}
	}
	else if (len1 >= shift_array_height)
	{
		shift_array_height = total_len;
		*shift_array_p = (int32_t*) realloc(*shift_array_p, ARRAY_LENGTH * shift_array_height * sizeof(int32_t));
		if (*shift_array_p == NULL)
		{
		 	obi_set_errno(OBI_MALLOC_ERROR);
		 	obidebug(1, "\nError computing the kmer similarity between two sequences: error allocating memory");
		 	return NULL;
		}
	}

	// Allocate or reallocate memory for the array of positions if necessary
	if (*kmer_pos_array_p == NULL)
	{
		kmer_pos_array_height = len1;
		*kmer_pos_array_p = (int32_t*) malloc(ARRAY_LENGTH * kmer_pos_array_height * sizeof(int32_t));
		if (*kmer_pos_array_p == NULL)
		{
		 	obi_set_errno(OBI_MALLOC_ERROR);
		 	obidebug(1, "\nError computing the kmer similarity between two sequences: error allocating memory");
		 	return NULL;
		}
	}
	else if (len1 >= kmer_pos_array_height)
	{
		kmer_pos_array_height = len1;
		*kmer_pos_array_p = (int32_t*) realloc(*kmer_pos_array_p, ARRAY_LENGTH * kmer_pos_array_height * sizeof(int32_t));
		if (*kmer_pos_array_p == NULL)
		{
		 	obi_set_errno(OBI_MALLOC_ERROR);
		 	obidebug(1, "\nError computing the kmer similarity between two sequences: error allocating memory");
		 	return NULL;
		}
	}

	shift_count_array = *shift_count_array_p;
	shift_array = *shift_array_p;
	kmer_pos_array = *kmer_pos_array_p;

	// Initialize all positions to -1
	for (i=0; i<(ARRAY_LENGTH * kmer_pos_array_height); i++)
		kmer_pos_array[i] = -1;
	// Initialize all shifts to the maximum value of an int32_t
	for (i=0; i<(ARRAY_LENGTH * shift_array_height); i++)
		shift_array[i] = INT32_MAX;
	//memset(shift_array, 1, ARRAY_LENGTH * shift_array_height * sizeof(int32_t)); // why doesn't this work?
	// Initialize all shift counts to 0
	memset(shift_count_array, 0, shift_count_array_length * sizeof(int32_t));

	*kmer_pos_array_height_p = kmer_pos_array_height;
	*shift_array_height_p = shift_array_height;
	*shift_count_array_length_p = shift_count_array_length;

	// Fill array with positions of kmers in the shortest sequence
	encoding = blob1->element_size;
	kmer_count = len1 - kmer_size + 1;
	for (kmer_idx=0; kmer_idx < kmer_count; kmer_idx++)
	{
		kmer = 0;
		for (nuc_idx=kmer_idx; nuc_idx<(kmer_idx+kmer_size); nuc_idx++)
		{
			nuc = get_nucleotide_from_encoded_seq(blob1->value, nuc_idx, encoding);
			kmer <<= encoding;
			kmer |= nuc;
		}

		i = 0;
		while (kmer_pos_array[(kmer*kmer_pos_array_height)+i] != -1)
			i++;
		kmer_pos_array[(kmer*kmer_pos_array_height)+i] = kmer_idx;
	}

	// Compare positions of kmers between both sequences and store shifts
	kmer_count = blob2->length_decoded_value - kmer_size + 1;
	for (kmer_idx=0; kmer_idx < kmer_count; kmer_idx++)
	{
		kmer = 0;
		for (nuc_idx=kmer_idx; nuc_idx<(kmer_idx+kmer_size); nuc_idx++)
		{
			nuc = get_nucleotide_from_encoded_seq(blob2->value, nuc_idx, encoding);
			kmer <<= encoding;
			kmer |= nuc;
		}

		// Get the index at which the new shifts should be stored for that kmer
		j = 0;
		while ((shift_array[(kmer*shift_array_height)+j] != INT32_MAX) && (j<shift_array_height))
			j++;
		// Store the shift between the kmer in the 1st and the 2nd sequence
		i = 0;
		while ((kmer_pos_array[(kmer*kmer_pos_array_height)+i] != -1) && (i<kmer_pos_array_height))
		{
			shift_array[(kmer*shift_array_height)+j] = kmer_idx - kmer_pos_array[(kmer*kmer_pos_array_height)+i];
			i++;
			j++;
		}
	}

	// Count how many times each shift is represented
	for (kmer=0;;kmer++)
	{
		for (i=0;;i++)
		{
			shift = shift_array[(kmer*shift_array_height)+i];
			if ((shift == INT32_MAX) || (i==shift_array_height))
				break;
			shift_idx = shift + len1;
			shift_count_array[shift_idx]++;
		}
		if (kmer == (ARRAY_LENGTH-1))  // stop condition can't be in for line because kmer can't be >= 255
			break;
	}

	// Find the most represented shift
	best_shift_idx = 0;
	max_common_kmers = 0;
	//empty_part = (shift_count_array_length-1)/2 - len1; //TODO wrong in some cases (len1 shorter than overlap or something like that)
	empty_part = 0;
	for (i=empty_part; i < (shift_count_array_length - empty_part); i++)  // skipping empty parts of the array
	{
		if (shift_count_array[i] > max_common_kmers)
		{
			best_shift_idx = i;
			max_common_kmers = shift_count_array[i];
		}
	}
	best_shift = best_shift_idx - len1;

	keep_seq1_start = false;
	keep_seq1_end = false;
	keep_seq2_start = false;
	keep_seq2_end = false;

	// The 873863 cases of hell
	if (best_shift > 0)
	{
		overlap_len = len2 - best_shift;
		if (len1 <= overlap_len)
		{
			overlap_len = len1;
			if (! switched_seqs)
				keep_seq2_end = true;
			else
				keep_seq2_start = true;
		}
		else if (switched_seqs)
		{
			keep_seq2_start = true;
			keep_seq1_end = true;
		}
	}
	else if (best_shift < 0)
	{
	    overlap_len = len1 + best_shift;
	    if (!switched_seqs)
	    {
	    	keep_seq1_start = true;
	    	keep_seq2_end = true;
	    }
	}
	else
	{
		overlap_len = len1;
		if ((!switched_seqs) && (len2 > len1))
			keep_seq2_end = true;
	}

	ali = (Obi_ali_p) malloc(sizeof(Obi_ali_t));
	if (ali == NULL)
	{
	 	obi_set_errno(OBI_MALLOC_ERROR);
	 	obidebug(1, "\nError computing the kmer similarity between two sequences: error allocating memory for the result structure");
	 	return NULL;
	}

	score = max_common_kmers + kmer_size - 1;  // aka the number of nucleotides in the longest stretch of kmers perfectly matching
	abs_shift = abs(best_shift);

	// Save result in Obi_ali structure
	ali->score = score;
	ali->consensus_length = 0;
	ali->overlap_length = overlap_len;
	ali->shift = abs_shift;
	ali->consensus_seq = NULL;
	ali->consensus_qual = NULL;
	if (((best_shift <= 0) && (!switched_seqs)) || ((best_shift > 0) && switched_seqs))
		strcpy(ali->direction, "left");
	else
		strcpy(ali->direction, "right");

	// Build the consensus sequence if asked
	if (build_consensus)
	{
		// Get the quality arrays
		qual1 = obi_get_qual_int_with_elt_idx_and_col_p_in_view(view1, qual_col1, idx1, 0, &qual1_len);
		if (qual1 == NULL)
		{
			obidebug(1, "\nError getting the quality of the 1st sequence when computing the kmer similarity between two sequences");
			return NULL;
		}
		qual2 = obi_get_qual_int_with_elt_idx_and_col_p_in_view(view2, qual_col2, idx2, 0, &qual2_len);
		if (qual2 == NULL)
		{
			obidebug(1, "\nError getting the quality of the 2nd sequence when computing the kmer similarity between two sequences");
			return NULL;
		}

		// Decode the first sequence if not already done
		if (seq1 == NULL)
			seq1 = obi_blob_to_seq(blob1);

		if (! switched_seqs)
		    consensus_len = len2 - best_shift;
		else
		    consensus_len = len1 + best_shift;

		// Allocate memory for consensus sequence
		consensus_seq = (char*) malloc(consensus_len + 1 * sizeof(char)); // TODO keep malloced too maybe
		if (consensus_seq == NULL)
		{
		 	obi_set_errno(OBI_MALLOC_ERROR);
		 	obidebug(1, "\nError computing the kmer similarity between two sequences: error allocating memory for the consensus sequence");
		 	return NULL;
		}

		// Allocate memory for consensus quality
		consensus_qual = (uint8_t*) malloc(consensus_len * sizeof(uint8_t));
		if (consensus_qual == NULL)
		{
		 	obi_set_errno(OBI_MALLOC_ERROR);
		 	obidebug(1, "\nError computing the kmer similarity between two sequences: error allocating memory for the consensus quality");
		 	return NULL;
		}

		ali->consensus_length = consensus_len;
		ali->consensus_seq = consensus_seq;
		ali->consensus_qual = consensus_qual;

		// Compute consensus-relative shift for each sequence
		if (best_shift > 0)
		{
			shift1 = 0;
			shift2 = best_shift;
		}
		else
		{
			shift1 = -(best_shift);
			shift2 = 0;
		}

		// Copy first part of first or second sequence depending on cases
		if (keep_seq1_start)
		{
			strncpy(consensus_seq, seq1, abs_shift);
			memcpy(consensus_qual, qual1, abs_shift*sizeof(uint8_t));
			cons_shift = abs_shift;
		}
		else if (keep_seq2_start)
		{
			strncpy(consensus_seq, seq2, abs_shift);
			memcpy(consensus_qual, qual2, abs_shift*sizeof(uint8_t));
			cons_shift = abs_shift;
		}
		else
			cons_shift = 0;

		// Build consensus part
		for (pos=0; pos<overlap_len; pos++)
		{
			if (qual1[pos+shift1] >= qual2[pos+shift2])
				consensus_seq[pos+cons_shift] = seq1[pos+shift1];
			else
				consensus_seq[pos+cons_shift] = seq2[pos+shift2];
 			consensus_qual[pos+cons_shift] = round((qual1[pos+shift1] + qual2[pos+shift2])/2);    // TODO maybe use the (p1*(1-p2/3)) formula (but parenthesis bug???)
		}

		// Copy last part of first or second sequence depending on cases
		if (keep_seq1_end)
		{
			strncpy(consensus_seq+cons_shift+overlap_len, seq1+overlap_len, len1 - overlap_len);
			memcpy(consensus_qual+cons_shift+overlap_len, qual1+overlap_len, (len1 - overlap_len)*sizeof(uint8_t));
		}
		if (keep_seq2_end)
		{
			if (best_shift <= 0)
			{
				copy_start = overlap_len;
				copy_len = len2 - overlap_len;
			}
			if (best_shift > 0)
			{
				copy_start = overlap_len + best_shift;
				copy_len = len2 - overlap_len - best_shift;
			}
			strncpy(consensus_seq+cons_shift+overlap_len, seq2+copy_start, copy_len);
			memcpy(consensus_qual+cons_shift+overlap_len, qual2+copy_start, copy_len*sizeof(uint8_t));
		}

		consensus_seq[consensus_len] = '\0';
	}

	if (seq1 != NULL)
		free(seq1);
	if (free_blob1)
		free(blob1);
	free(seq2);
	free(blob2);

	return ali;
}

