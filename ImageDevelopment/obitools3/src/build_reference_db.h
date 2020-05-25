/****************************************************************************************************
 * Header file for functions to build reference databases for the taxonomic assignment of sequences *
 ****************************************************************************************************/

/**
 * @file build_reference_db.h
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 * @date November 15th 2018
 * @brief Header file for the functions for the taxonomic assignment of sequences.
 */


#ifndef BUILD_REFERENCE_DB_H_
#define BUILD_REFERENCE_DB_H_


#include <stdlib.h>
#include <stdio.h>


#define LCA_TAXID_COLUMN_NAME "LCA_TAXID"
#define LCA_TAXID_ARRAY_COLUMN_NAME "LCA_TAXID"
#define LCA_SCORE_ARRAY_COLUMN_NAME "LCA_SCORE"
#define DB_THRESHOLD_KEY_IN_COMMENTS "ref_db_threshold"


/**
 * @brief Building of reference databases for the taxonomic assignment of sequences.
 *
 * Note: The columns where the results are written are automatically named and created.
 *
 * Note: The threshold used to build the db is saved in the view's comments with the key
 *       defined by the DB_THRESHOLD_KEY_IN_COMMENTS macro.
 *
 * @param dms_name The name of the DMS.
 * @param refs_view_name The name of the view containing the reference sequences annotated with their taxids.
 * @param taxonomy_name The name of the taxonomy stored in the DMS.
 * @param o_view_name The name of the final reference database to create.
 * @param o_view_comments The comments to associate with the final reference database to create.
 * @param threshold The threshold (similarity score in identity percentage) at which the database should be created.
 *                  The output database contains the Lowest Common Ancestor and associated highest similarity score for each
 *                  sequence with the sequences with a similarity equal or greater than this threshold.
 *
 * @returns A value indicating the success of the operation.
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since November 2018
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int build_reference_db(const char* dms_name,
					   const char* refs_view_name,
					   const char* taxonomy_name,
					   const char* o_view_name,
					   const char* o_view_comments,
					   double threshold);


#endif /* BUILD_REFERENCE_DB_H_ */

