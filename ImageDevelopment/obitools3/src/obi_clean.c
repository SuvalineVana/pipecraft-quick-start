/****************************************************************************
 * Tags a set of sequences for PCR/sequencing errors identification		    *
 ****************************************************************************/

/**
 * @file obi_clean.c
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 * @date April 9th 2018
 * @brief Functions tagging a set of sequences for PCR/sequencing errors identification.
 */

#ifdef _OPENMP
#include <omp.h>
#endif

#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <search.h>
#include <sys/time.h>
#include <math.h>

#include "obi_clean.h"
#include "obidms.h"
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
 * Internal function creating the output columns for the obiclean algorithm.
 *
 * @param o_view A pointer on the output view.
 * @param sample_column A pointer on the column where sample counts are kept.
 * @param sample_count The number of different samples.
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since April 2018
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static int create_output_columns(Obiview_p o_view,
								 OBIDMS_column_p sample_column,
								 int sample_count);


/**
 * @brief Internal function comparing two indexes (int64_t).
 *
 * @param idx1 A pointer on the first index.
 * @param idx2 A pointer on the second index.
 *
 * @returns -1 if idx1 < idx2,
 * 			1 if idx1 > idx2,
 * 			and 0 if idx1 == idx2.
 *
 * @since April 2018
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static inline int idxcmp(const void* idx1, const void* idx2);


/************************************************************************
 *
 * D E F I N I T I O N   O F   T H E   P R I V A T E   F U N C T I O N S
 *
 ************************************************************************/

static int create_output_columns(Obiview_p o_view,
								 OBIDMS_column_p sample_column,
								 int sample_count)
{
	// Status column
	if (obi_view_add_column(o_view, CLEAN_STATUS_COLUMN_NAME, -1, NULL, OBI_CHAR, 0, sample_count, (sample_column->header)->elements_names, true, false, false, NULL, NULL, -1, CLEAN_STATUS_COLUMN_COMMENTS, true) < 0)
	{
		obidebug(1, "\nError creating the %s column", CLEAN_STATUS_COLUMN_NAME);
		return -1;
	}

	// Head column
	if (obi_view_add_column(o_view, CLEAN_HEAD_COLUMN_NAME, -1, NULL, OBI_BOOL, 0, 1, NULL, false, false, false, NULL, NULL, -1, CLEAN_HEAD_COLUMN_COMMENTS, true) < 0)
	{
		obidebug(1, "\nError creating the %s column", CLEAN_HEAD_COLUMN_NAME);
		return -1;
	}

	// Sample count column
	if (obi_view_add_column(o_view, CLEAN_SAMPLECOUNT_COLUMN_NAME, -1, NULL, OBI_INT, 0, 1, NULL, false, false, false, NULL, NULL, -1, CLEAN_SAMPLECOUNT_COLUMN_COMMENTS, true) < 0)
	{
		obidebug(1, "\nError creating the %s column", CLEAN_SAMPLECOUNT_COLUMN_NAME);
		return -1;
	}

	// Head count column
	if (obi_view_add_column(o_view, CLEAN_HEADCOUNT_COLUMN_NAME, -1, NULL, OBI_INT, 0, 1, NULL, false, false, false, NULL, NULL, -1, CLEAN_HEADCOUNT_COLUMN_COMMENTS, true) < 0)
	{
		obidebug(1, "\nError creating the %s column", CLEAN_HEADCOUNT_COLUMN_NAME);
		return -1;
	}

	// Internal count column
	if (obi_view_add_column(o_view, CLEAN_INTERNALCOUNT_COLUMN_NAME, -1, NULL, OBI_INT, 0, 1, NULL, false, false, false, NULL, NULL, -1, CLEAN_INTERNALCOUNT_COLUMN_COMMENTS, true) < 0)
	{
		obidebug(1, "\nError creating the %s column", CLEAN_INTERNALCOUNT_COLUMN_NAME);
		return -1;
	}

	// Singleton count column
	if (obi_view_add_column(o_view, CLEAN_SINGLETONCOUNT_COLUMN_NAME, -1, NULL, OBI_INT, 0, 1, NULL, false, false, false, NULL, NULL, -1, CLEAN_SINGLETONCOUNT_COLUMN_COMMENTS, true) < 0)
	{
		obidebug(1, "\nError creating the %s column", CLEAN_SINGLETONCOUNT_COLUMN_NAME);
		return -1;
	}

	return 0;
}


static inline int idxcmp(const void* idx1, const void* idx2)
{
    if (*(index_t*) idx1 < *(index_t*) idx2)
        return -1;
    if (*(index_t*) idx1 > *(index_t*) idx2)
        return 1;
    return 0;
}


/**********************************************************************
 *
 * D E F I N I T I O N   O F   T H E   P U B L I C   F U N C T I O N S
 *
 **********************************************************************/


int obi_clean(const char* dms_name,
		      const char* i_view_name,
			  const char* sample_column_name,
			  const char* o_view_name,
			  const char* o_view_comments,
			  double threshold,
			  double max_ratio,
			  bool heads_only,
			  int thread_count)
{
	char* 			o_view_name_temp = NULL;
	float 			p;
	index_t    		i;
	index_t         l;
	index_t  	    k;
	index_t         seq_count;
	index_t*  		line_selection = NULL;
	Kmer_table_p    ktable;
	int				sample_count;
	bool            head;
	int             head_count;
	int       	    internal_count;
	int 			singleton_count;
	int 			ind_sample_count;
	char  			status;
	int 	   		samp;
	Obi_blob_p 		blob1;

	byte_t*         alignment_result_array = NULL;

	int* 			complete_sample_count_array = NULL;
	Obi_blob_p* 	blob_array = NULL;

	OBIDMS_p        dms = NULL;
	Obiview_p       i_view = NULL;
	Obiview_p       o_view = NULL;
	OBIDMS_column_p iseq_column = NULL;
	OBIDMS_column_p sample_column = NULL;
	OBIDMS_column_p status_column = NULL;
	OBIDMS_column_p head_column = NULL;
	OBIDMS_column_p internalcount_column = NULL;
	OBIDMS_column_p headcount_column = NULL;
	OBIDMS_column_p singletoncount_column = NULL;
	OBIDMS_column_p samplecount_column = NULL;

	bool normalize = false;
	int  reference = 0;
	bool similarity_mode = false;

	bool stop = false;

	int max_threads = 1;

	signal(SIGINT, sig_handler);

	#ifdef _OPENMP
	max_threads = omp_get_max_threads();
	if ((thread_count == -1) || (thread_count > max_threads))
		thread_count = max_threads;
	omp_set_num_threads(thread_count);
	fprintf(stderr, "Running on %d thread(s)\n", thread_count);
	#endif

	// Open DMS
	dms = obi_dms(dms_name);
	if (dms == NULL)
	{
		obidebug(1, "\nError opening the DMS");
		return -1;
	}

	// Open input view
	i_view = obi_open_view(dms, i_view_name);
	if (i_view == NULL)
	{
		obidebug(1, "\nError opening the input view to clean");
		return -1;
	}

	// Open the sequence column
	if (strcmp((i_view->infos)->view_type, VIEW_TYPE_NUC_SEQS) == 0)
		iseq_column = obi_view_get_column(i_view, NUC_SEQUENCE_COLUMN);
	else
	{
		obi_set_errno(OBI_CLEAN_ERROR);
		obidebug(1, "\nError: no sequence column");
		return -1;
	}
	if (iseq_column == NULL)
	{
		obidebug(1, "\nError getting the sequence column");
		return -1;
	}

	// Open the sample column if there is one
	if ((strcmp(sample_column_name, "") == 0) || (sample_column_name == NULL))
		sample_column = NULL;
	else
	{
		sample_column = obi_view_get_column(i_view, sample_column_name);
		if (sample_column == NULL)
		{
			obidebug(1, "\nError getting the sample column");
			return -1;
		}
	}

	// Create the output view, or a temporary one if heads only
	if (heads_only)
	{
		o_view_name_temp = calloc((strlen(o_view_name)+strlen("_temp")+1), sizeof(char));
		if (o_view_name_temp == NULL)
		{
			obidebug(1, "\nError allocating memory for the name of a temporary output view in obiclean");
			return -1;
		}
		o_view_name_temp = strcpy(o_view_name_temp, o_view_name);
		strcat(o_view_name_temp, "_temp");
		o_view = obi_clone_view(dms, i_view, o_view_name_temp, NULL, o_view_comments);
	}
	else
		o_view = obi_clone_view(dms, i_view, o_view_name, NULL, o_view_comments);

	if (o_view == NULL)
	{
		obidebug(1, "\nError creating the output view in obiclean");
		return -1;
	}

	sample_count = (sample_column->header)->nb_elements_per_line;

	// Create the output columns
	if (create_output_columns(o_view, sample_column, sample_count) < 0)
	{
		obidebug(1, "\nError creating the output columns");
		return -1;
	}

	// Get the created output columns
	status_column = obi_view_get_column(o_view, CLEAN_STATUS_COLUMN_NAME);
	if (status_column == NULL)
	{
		obidebug(1, "\nError getting the obiclean status column");
		return -1;
	}
	head_column = obi_view_get_column(o_view, CLEAN_HEAD_COLUMN_NAME);
	if (status_column == NULL)
	{
		obidebug(1, "\nError getting the obiclean head column");
		return -1;
	}
	internalcount_column = obi_view_get_column(o_view, CLEAN_INTERNALCOUNT_COLUMN_NAME);
	if (status_column == NULL)
	{
		obidebug(1, "\nError getting the obiclean internal count column");
		return -1;
	}
	headcount_column = obi_view_get_column(o_view, CLEAN_HEADCOUNT_COLUMN_NAME);
	if (status_column == NULL)
	{
		obidebug(1, "\nError getting the obiclean head count column");
		return -1;
	}
	singletoncount_column = obi_view_get_column(o_view, CLEAN_SINGLETONCOUNT_COLUMN_NAME);
	if (status_column == NULL)
	{
		obidebug(1, "\nError getting the obiclean singleton count column");
		return -1;
	}
	samplecount_column = obi_view_get_column(o_view, CLEAN_SAMPLECOUNT_COLUMN_NAME);
	if (status_column == NULL)
	{
		obidebug(1, "\nError getting the obiclean sample count column");
		return -1;
	}

	// Build kmer tables
	ktable = hash_seq_column(i_view, iseq_column, 0);
	if (ktable == NULL)
	{
		obi_set_errno(OBI_CLEAN_ERROR);
		obidebug(1, "\nError building kmer tables before aligning");
		return -1;
	}

	seq_count = (i_view->infos)->line_count;

	// Allocate arrays for sample counts otherwise reading in mapped files takes longer
	complete_sample_count_array = (int*) malloc(seq_count * sample_count * sizeof(int));
	if (complete_sample_count_array == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating memory for the array of sample counts, size: %lld", seq_count * sample_count * sizeof(int));
		return -1;
	}
	for (samp=0; samp < sample_count; samp++)
	{
		for (k=0; k<seq_count; k++)
			complete_sample_count_array[k+(samp*seq_count)] = obi_get_int_with_elt_idx_and_col_p_in_view(i_view, sample_column, k, samp);
	}

	// Allocate arrays for blobs otherwise reading in mapped files takes longer
	blob_array = (Obi_blob_p*) malloc(seq_count * sizeof(Obi_blob_p));
	if (blob_array == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating memory for the array of blobs");
		return -1;
	}
	for (k=0; k<seq_count; k++)
	{
		blob_array[k] = obi_get_blob_with_elt_idx_and_col_p_in_view(i_view, iseq_column, k, 0);
	}

	// Allocate alignment result array (byte at 0 if not aligned yet,
	//											1 if sequence at index has a similarity above the threshold with the current sequence,
	//											2 if sequence at index has a similarity below the threshold with the current sequence)
	alignment_result_array = (byte_t*) calloc(seq_count, sizeof(byte_t));
	if (alignment_result_array == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating memory for alignment result array");
		return -1;
	}

	// Initialize all sequences to singletons or NA if no sequences in that sample
	for (k=0; k<seq_count; k++)
	{
		for (samp=0; samp < sample_count; samp++)
		{
			if (obi_get_int_with_elt_idx_and_col_p_in_view(i_view, sample_column, k, samp) != OBIInt_NA)  // Only initialize samples where there are some sequences
			{
				if (obi_set_char_with_elt_idx_and_col_p_in_view(o_view, status_column, k, samp, 's') < 0)
				{
					obidebug(1, "\nError initializing all sequences to singletons");
					return -1;
				}
			}
		}
	}

	for (i=0; i< (seq_count-1); i++)
	{

		if (i%1000 == 0)
		{
			p = (i/(float)seq_count)*100;
			fprintf(stderr,"\rDone : %f %%          ",p);
		}

		// Get first sequence
		blob1 = blob_array[i];
//			blob1 = obi_get_blob_with_elt_idx_and_col_p_in_view(i_view, iseq_column, i, 0);  // slower
		if (blob1 == NULL)
		{
			obidebug(1, "\nError retrieving sequences to align");
			stop = true;
		}

		#pragma omp parallel shared(thread_count, seq_count, blob_array, complete_sample_count_array, alignment_result_array, \
					 	 			 stop, blob1, i, obi_errno, keep_running, stderr, max_ratio, iseq_column, i_view, \
									 similarity_mode, reference, normalize, threshold, ktable, status_column, o_view, sample_count)
		{
			index_t    j;
			Obi_blob_p blob2;
			int        s1_count;
			int        s2_count;
			int* 	   sample_count_array;
			int 	   sample;
			byte_t     no;
			byte_t     yes;
			double     score;
			int		   lcs_min;
			bool       above_threshold;
			int        lcs_length;
			int        ali_length;
			byte_t 	   ali_result;

			// Parallelize the loop on samples to avoid interdependency issues inside one sample
			#pragma omp for schedule(dynamic, sample_count/thread_count + (sample_count % thread_count != 0))  // Avoid 0 which blocks the program
			for (sample=0; sample < sample_count; sample++)
			{
				if (! keep_running)
					stop = true;

				sample_count_array = complete_sample_count_array+(sample*seq_count);

				// Get count for this sample
				s1_count = sample_count_array[i];
				//s1_count = obi_get_int_with_elt_idx_and_col_p_in_view(i_view, sample_column, i, sample);   // slower

				for (j=i+1; j < seq_count; j++)
				{
					// Get second sequence
					blob2 = blob_array[j];
	//				blob2 = obi_get_blob_with_elt_idx_and_col_p_in_view(i_view, iseq_column, j, 0);   // slower
					if (blob2 == NULL)
					{
						obidebug(1, "\nError retrieving sequences to align");
						stop = true;
					}

					// Get count for this sample
					s2_count = sample_count_array[j];
					//s2_count = obi_get_int_with_elt_idx_and_col_p_in_view(i_view, sample_column, j, sample);    // slower

					// Check all ratios
					if (((s1_count!=OBIInt_NA && s2_count!=OBIInt_NA) && (s1_count>0 && s2_count>0)) &&
							((((s1_count >= s2_count) && (((double) s2_count / (double) s1_count) <= max_ratio))) ||
							(((s2_count >= s1_count) && (((double) s1_count / (double) s2_count) <= max_ratio)))))
					{

						yes = 0;
						no = 0;
						above_threshold = false;
						ali_result = alignment_result_array[j];
						if (ali_result > 0) // already aligned
						{
							if (ali_result == 2)
								no = 1;
							else if (ali_result == 1)
								yes = 1;
						}
						else  // never compared before
						{
							// Check if the sequences are identical in a quick way (same index in the same indexer)
							if (obi_get_index_with_elt_idx_and_col_p_in_view(i_view, iseq_column, i, 0) == obi_get_index_with_elt_idx_and_col_p_in_view(i_view, iseq_column, j, 0))
								above_threshold = true;
							else // the sequences aren't identical
							{
								// kmer filter
								align_filters(ktable, blob1, blob2, i, j, threshold, normalize, reference, similarity_mode, &score, &lcs_min, false);

								// Compute alignment score if filter passed
								if (score == -1.0)
									score = obiblob_sse_banded_lcs_align(blob1, blob2, threshold, normalize, reference, similarity_mode, &lcs_length, &ali_length);

								above_threshold = ((score >= 0) && (score <= threshold));
							}
						}

						if (yes || above_threshold)
						{
							if (yes == 0)
							// Set ali result as above the threshold (value 1)
							alignment_result_array[j] = 1;

							// Might be worth having arrays to read values too for some datasets but unlikely
							// label as head or internal

							if (s1_count >= s2_count)
							{
								if (obi_get_char_with_elt_idx_and_col_p_in_view(o_view, status_column, i, sample) == 's')	// seq can become head ONLY if it's a singleton
								{
									if (obi_set_char_with_elt_idx_and_col_p_in_view(o_view, status_column, i, sample, 'h') < 0)
										stop = true;
								}
								// Otherwise it's an internal (do nothing)
								// Label other sequence as internal no matter what
								if (obi_set_char_with_elt_idx_and_col_p_in_view(o_view, status_column, j, sample, 'i') < 0)
									stop = true;
							}
							else // Same thing but with sequences switched
							{
								if (obi_get_char_with_elt_idx_and_col_p_in_view(o_view, status_column, j, sample) == 's')	// seq can become head ONLY if it's a singleton
									{
										if (obi_set_char_with_elt_idx_and_col_p_in_view(o_view, status_column, j, sample, 'h') < 0)
											stop = true;
									}
								if (obi_set_char_with_elt_idx_and_col_p_in_view(o_view, status_column, i, sample, 'i') < 0)
									stop = true;
							}

						}

						else if (no == 0)
						// Set ali result as above the threshold (value 2)
							alignment_result_array[j] = 2;
					}
				}
			}

			// Reset ali result array to 0
			memset(alignment_result_array, 0, seq_count);
		}
	}

	free_kmer_tables(ktable, seq_count);
	free(complete_sample_count_array);
	free(blob_array);
	free(alignment_result_array);

	fprintf(stderr, "\n");

	if (stop)
		return -1;

	if (heads_only)
	{
		line_selection = malloc((o_view->infos)->line_count * sizeof(index_t));
		if (line_selection == NULL)
		{
			obi_set_errno(OBI_MALLOC_ERROR);
			obidebug(1, "\nError allocating memory for line selection");
			return -1;
		}
		l=0;
	}

	for (k=0; k<seq_count; k++)
	{
		if (k%1000 == 0)
		{
			p = (k/(float)(seq_count))*100;
		    fprintf(stderr, "\rAnnotating : %f %%          ",p);
		}

		head = false;
		head_count = 0;
		internal_count = 0;
		singleton_count = 0;
		ind_sample_count = 0;

		for (samp=0; samp < sample_count; samp++)
		{
			// Check if head or singleton in at least one sample
			status = obi_get_char_with_elt_idx_and_col_p_in_view(o_view, status_column, k, samp);
			if ((!head) && ((status == 'h') || (status == 's')))
			{
				head = true;
				if (heads_only)
				{
					line_selection[l] = k;
					l++;
				}
			}

			if (status == 's')
			{
				singleton_count++;
				ind_sample_count++;
			}
			else if (status == 'i')
			{
				internal_count++;
				ind_sample_count++;
			}
			else if (status == 'h')
			{
				head_count++;
				ind_sample_count++;
			}

		}

		if (!heads_only  || (heads_only && head))  // Label only if sequence is going to be kept in final view
		{
			if (obi_set_bool_with_elt_idx_and_col_p_in_view(o_view, head_column, k, 0, head) < 0)
				return -1;
			if (obi_set_int_with_elt_idx_and_col_p_in_view(o_view, singletoncount_column, k, 0, singleton_count) < 0)
				return -1;
			if (obi_set_int_with_elt_idx_and_col_p_in_view(o_view, internalcount_column, k, 0, internal_count) < 0)
				return -1;
			if (obi_set_int_with_elt_idx_and_col_p_in_view(o_view, headcount_column, k, 0, head_count) < 0)
				return -1;
			if (obi_set_int_with_elt_idx_and_col_p_in_view(o_view, samplecount_column, k, 0, ind_sample_count) < 0)
				return -1;
		}
	}

	// Flag the end of the line selection
	if (heads_only)
		line_selection[l] = -1;

	// Create new view with line selection if heads only
	if (heads_only)
	{
		if (obi_save_and_close_view(o_view) < 0)
		{
			obidebug(1, "\nError closing the temporary output view");
			return -1;
		}
		o_view = obi_clone_view_from_name(dms, o_view_name_temp, o_view_name, line_selection, o_view_comments);
		if (o_view == NULL)
		{
			obidebug(1, "\nError cloning the temporary output view to make the final output view");
			return -1;
		}

		// Delete the temporary view
		if (obi_delete_view(dms, o_view_name_temp) < 0)
		{
			obidebug(1, "\nError deleting the temporary output view");
			return -1;
		}

		free(o_view_name_temp);
		free(line_selection);
	}

	// Close views
	if (obi_save_and_close_view(i_view) < 0)
	{
		obidebug(1, "\nError closing the input view after aligning");
		return -1;
	}

	if (obi_save_and_close_view(o_view) < 0)
	{
		obidebug(1, "\nError closing the output view after aligning");
		return -1;
	}

	fprintf(stderr, "\rDone : 100 %%               \n");
	return 0;
}



