/*************************************************************************************************
 * Header file for in silico PCR																 *
 *************************************************************************************************/

/**
 * @file obi_ecopcr.h
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 * @date June 5th 2018
 * @brief Header file for the functions performing an in silico PCR.
 */


#ifndef OBI_ECOPCR_H_
#define OBI_ECOPCR_H_


#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>

#include "obidms.h"
#include "obiview.h"
#include "obidmscolumn.h"
#include "obitypes.h"

// TODO discuss names
#define ECOPCR_SEQLEN_COLUMN_NAME                   "seq_length_ori"
#define ECOPCR_SEQLEN_COLUMN_COMMENTS				""
#define ECOPCR_AMPLICONLEN_COLUMN_NAME				"seq_length"
#define ECOPCR_AMPLICONLEN_COLUMN_COMMENTS			""
#define TAXID_COLUMN_COMMENTS						""
#define ECOPCR_RANK_COLUMN_NAME						"rank"
#define ECOPCR_RANK_COLUMN_COMMENTS					""
#define ECOPCR_SCIENTIFIC_NAME_COLUMN_NAME          "scientific_name"
#define ECOPCR_SCIENTIFIC_NAME_COLUMN_COMMENTS      ""
#define ECOPCR_SPECIES_TAXID_COLUMN_NAME			"species"
#define ECOPCR_SPECIES_TAXID_COLUMN_COMMENTS		""
#define ECOPCR_GENUS_TAXID_COLUMN_NAME				"genus"
#define ECOPCR_GENUS_TAXID_COLUMN_COMMENTS			""
#define ECOPCR_FAMILY_TAXID_COLUMN_NAME				"family"
#define ECOPCR_FAMILY_TAXID_COLUMN_COMMENTS			""
#define ECOPCR_KINGDOM_TAXID_COLUMN_NAME		    "kingdom"
#define ECOPCR_KINGDOM_TAXID_COLUMN_COMMENTS	    ""
#define ECOPCR_SUPERKINGDOM_TAXID_COLUMN_NAME	    "superkingdom"
#define ECOPCR_SUPERKINGDOM_TAXID_COLUMN_COMMENTS	""
#define ECOPCR_SPECIES_NAME_COLUMN_NAME				"species_name"
#define ECOPCR_SPECIES_NAME_COLUMN_COMMENTS			""
#define ECOPCR_GENUS_NAME_COLUMN_NAME				"genus_name"
#define ECOPCR_GENUS_NAME_COLUMN_COMMENTS			""
#define ECOPCR_FAMILY_NAME_COLUMN_NAME				"family_name"
#define ECOPCR_FAMILY_NAME_COLUMN_COMMENTS			""
#define ECOPCR_KINGDOM_NAME_COLUMN_NAME		        "kindgom_name"
#define ECOPCR_KINGDOM_NAME_COLUMN_COMMENTS	        ""
#define ECOPCR_SUPERKINGDOM_NAME_COLUMN_NAME		"superkingdom_name"
#define ECOPCR_SUPERKINGDOM_NAME_COLUMN_COMMENTS	""
#define ECOPCR_STRAND_COLUMN_NAME					"strand"
#define ECOPCR_STRAND_COLUMN_COMMENTS				""
#define ECOPCR_PRIMER1_COLUMN_NAME					"forward_match"
#define ECOPCR_PRIMER1_COLUMN_COMMENTS				""
#define ECOPCR_PRIMER2_COLUMN_NAME					"reverse_match"
#define ECOPCR_PRIMER2_COLUMN_COMMENTS				""
#define ECOPCR_ERROR1_COLUMN_NAME					"forward_error"
#define ECOPCR_ERROR1_COLUMN_COMMENTS				""
#define ECOPCR_ERROR2_COLUMN_NAME					"reverse_error"
#define ECOPCR_ERROR2_COLUMN_COMMENTS				""
#define ECOPCR_TEMP1_COLUMN_NAME					"forward_tm"
#define ECOPCR_TEMP1_COLUMN_COMMENTS				""
#define ECOPCR_TEMP2_COLUMN_NAME					"reverse_tm"
#define ECOPCR_TEMP2_COLUMN_COMMENTS				""



/**
 * @brief ecoPCR works as an in silico PCR that preserves the taxonomic information of the selected sequences, and allows various specified conditions for the in silico amplification.
 *
 * Note: The columns where the results are written are automatically named and created.
 *
 * @param i_dms_name The path to the input DMS.
 * @param i_view_name The name of the input view.
 * @param taxonomy_name The name of the taxonomy in the input DMS.
 * @param o_dms_name The path to the output DMS.
 * @param o_view_name The name of the output view.
 * @param o_view_comments The comments to associate with the output view.
 * @param primer1 The first primer.
 * @param primer2 The second primer.
 * @param error_max The maximum number of errors allowed per primer for amplification.
 * @param min_len The minimum length of an amplicon.
 * @param max_len The maximum length of an amplicon.
 * @param restrict_to_taxids A pointer on an array of taxids. A sequence must belong to at least one of the groups formed by the taxids to be kept
 *                           (example: be a genus under a family in the list).
 * @param ignore_taxids A pointer on an array of taxids. A sequence must NOT belong to any of the groups formed by the taxids to be kept.
 * @param circular Whether the input sequences are circular (e.g. mitochondrial or chloroplastic DNA).
 * @param salt_concentration The salt concentration used for estimating the Tm.
 * @param salt_correction_method The method used for estimating the Tm (melting temperature) between the primers and their corresponding
 *                              target sequences. SANTALUCIA: 1, or OWCZARZY: 2.
 * @param keep_nucleotides The number of nucleotides to keep on each side of the in silico amplified sequences, not including primers (primers automatically entirely kept if > 0).
 * @param keep_primers Whether primers are kept attached to the output sequences.
 * @param kingdom_mode Whether the kingdom or the superkingdom informations should be printed to the output.
 *
 * @returns A value indicating the success of the operation.
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since June 2018
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_ecopcr(const char* i_dms_name,
		       const char* i_view_name,
			   const char* taxonomy_name,
			   const char* o_dms_name,
			   const char* o_view_name,
			   const char* o_view_comments,
			   const char* primer1,
			   const char* primer2,
			   int error_max,
			   int min_len,
			   int max_len,
			   int32_t* restrict_to_taxids,
			   int32_t* ignore_taxids,
			   bool circular,
			   double salt_concentration,
			   int salt_correction_method,
			   int keep_nucleotides,
			   bool keep_primers,
			   bool kingdom_mode);

#endif /* OBI_ECOPCR_H_ */

