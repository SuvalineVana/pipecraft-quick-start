/*************************************************************************************************
 * Header file for functions for the taxonomic assignment of sequences 							 *
 *************************************************************************************************/

/**
 * @file obi_ecotag.h
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 * @date November 15th 2018
 * @brief Header file for the functions for the taxonomic assignment of sequences.
 */


#ifndef OBI_ECOTAG_H_
#define OBI_ECOTAG_H_


#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>



#define ECOTAG_TAXID_COLUMN_NAME "TAXID"
#define ECOTAG_NAME_COLUMN_NAME "SCIENTIFIC_NAME"
#define ECOTAG_STATUS_COLUMN_NAME "ID_STATUS"
#define ECOTAG_BEST_MATCH_IDS_COLUMN_NAME "BEST_MATCH"
#define ECOTAG_SCORE_COLUMN_NAME "BEST_IDENTITY"


/**
 * @brief Taxonomic assignment of sequences.
 *
 * Note: The columns where the results are written are automatically named and created.
 *
 * @param dms_name The path to the DMS where the views are.
 * @param query_view_name The name of the view containing the query sequences.
 * @param ref_dms_name The name of the DMS containing the reference database.
 * @param ref_view_name The name of the view corresponding to the reference database as built by build_reference_db().
 * @param taxo_dms_name The name of the DMS containing the taxonomy associated with the reference database.
 * @param taxonomy_name The name of the taxonomy associated with the reference database.
 * @param output_view_name The name to give to the output view.
 * @param output_view_comments The comments to associate to the output view.
 * @param ecotag_threshold The threshold at which to assign.
 *
 * 	The algorithm works like this:
 * 		For each query sequence:
 *			Align with reference database
 *			Keep the indices of all the best matches
 *			For each kept index, get the LCA at that threshold as stored in the reference database, then the LCA of those LCAs
 *			Write result (max score, threshold, taxid and scientific name of the LCA assigned, list of the ids of the best matches)
 *
 * @returns A value indicating the success of the operation.
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since November 2018
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_ecotag(const char* dms_name,
		       const char* query_view_name,
			   const char* ref_dms_name,
			   const char* ref_view_name,
			   const char* taxo_dms_name,
			   const char* taxonomy_name,
			   const char* output_view_name,
			   const char* output_view_comments,
			   double ecotag_threshold);


#endif /* OBI_ECOTAG_H_ */

