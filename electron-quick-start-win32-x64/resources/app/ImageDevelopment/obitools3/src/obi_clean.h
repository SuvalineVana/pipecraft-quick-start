/*************************************************************************************************
 * Header file for functions tagging a set of sequences for PCR/sequencing errors identification *
 *************************************************************************************************/

/**
 * @file obi_clean.h
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 * @date April 9th 2018
 * @brief Header file for the functions tagging a set of sequences for PCR/sequencing errors identification.
 */


#ifndef OBI_CLEAN_H_
#define OBI_CLEAN_H_


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
 * @since April 2018
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
#define CLEAN_STATUS_COLUMN_NAME "obiclean_status"
#define CLEAN_HEAD_COLUMN_NAME "obiclean_head"
#define CLEAN_SAMPLECOUNT_COLUMN_NAME "obiclean_samplecount"
#define CLEAN_HEADCOUNT_COLUMN_NAME "obiclean_headcount"
#define CLEAN_INTERNALCOUNT_COLUMN_NAME "obiclean_internalcount"
#define CLEAN_SINGLETONCOUNT_COLUMN_NAME "obiclean_singletoncount"

#define CLEAN_STATUS_COLUMN_COMMENTS ""
#define CLEAN_HEAD_COLUMN_COMMENTS ""
#define CLEAN_SAMPLECOUNT_COLUMN_COMMENTS ""
#define CLEAN_HEADCOUNT_COLUMN_COMMENTS ""
#define CLEAN_INTERNALCOUNT_COLUMN_COMMENTS ""
#define CLEAN_SINGLETONCOUNT_COLUMN_COMMENTS ""


/**
 * @brief Tags a set of sequences for PCR/sequencing errors identification
 *
 * Note: The columns where the results are written are automatically named and created.
 *
 * @param dms A pointer on an OBIDMS.
 * @param i_view_name The name of the input view.
 * @param sample_column_name The name of the OBI_STR column in the input view where the sample information is kept.
 *                           NULL or "" (empty string) if there is no sample information.
 * @param o_view_name The name of the output view where the results should be written (should not already exist).
 * @param o_view_comments The comments that should be associated with the output view.
 * @param threshold Similarity threshold expressed as a number of differences.
 *                  Only sequence pairs with a similarity above the threshold are clustered.
 * @param max_ratio Maximum ratio between the counts of two sequences so that the less abundant one can be considered
 *          	    as a variant of the more abundant one.
 * @param heads_only If true, only cluster heads are printed to the output view.
 * @param thread_count Number of threads to use. If the number given is -1 or is greater than the maximum number of
 * 					   threads available, the maximum number of threads is detected and used.
 *
 * @returns A value indicating the success of the operation.
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since April 2018
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_clean(const char* dms_name,
		      const char* i_view_name,
			  const char* sample_column_name,
			  const char* o_view_name,
			  const char* o_view_comments,
			  double threshold,
			  double max_ratio,
			  bool heads_only,
			  int thread_count);


#endif /* OBI_CLEAN_H_ */

