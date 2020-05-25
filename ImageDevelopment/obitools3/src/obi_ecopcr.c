/****************************************************************************
 * In silico PCR														    *
 ****************************************************************************/

/**
 * @file obi_ecopcr.c
 * @author Celine Mercier (celine.mercier@metabarcoding.org) from Eric Coissac's original code (eric.coissac@metabarcoding.org)
 * @date June 5th 2018
 * @brief ecoPCR works as an in silico PCR that preserves the taxonomic information of the selected sequences, and allows various specified conditions for the in silico amplification.
 */

#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <getopt.h>
#include <math.h>

#include "libecoPCR/ecoPCR.h"
#include "libecoPCR/libthermo/nnparams.h"

#include "obi_ecopcr.h"
#include "obidms.h"
#include "obidms_taxonomy.h"
#include "obiview.h"
#include "obidebug.h"
#include "obierrno.h"
#include "obisig.h"
#include "obitypes.h"
#include "obiview.h"


#define DEBUG_LEVEL 0	// TODO has to be defined somewhere else (cython compil flag?)


/**************************************************************************
 *
 * D E C L A R A T I O N   O F   T H E   P R I V A T E   F U N C T I O N S
 *
 **************************************************************************/

/**
 * Internal function creating the output columns for the ecopcr algorithm.
 *
 * @param o_view A pointer on the output view.
 * @param kingdom_mode Whether the kingdom or the superkingdom informations should be printed to the output.
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since July 2018
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static int create_output_columns(Obiview_p o_view, bool kingdom_mode);


/**
 * Internal function printing a found amplicon with all its associated informations.
 *
 * @param i_view A pointer on the input view.
 * @param o_view A pointer on the output view.
 * @param i_idx The line index of the sequence in the input view.
 * @param o_idx The line index where the amplicon should be written in the output view.
 * @param taxonomy A pointer on a taxonomy structure.
 * @param sequence The original full length sequence.
 * @param taxid The taxid associated with the amplicon.
 * @param seq_len The length of the original full length sequence.
 * @param amplicon_len The length of the amplicon.
 * @param primer1 The first primer.
 * @param primer2 The second primer.
 * @param tparm The structure with the PCR temperature informations.
 * @param o1 The structure with the first primer's data.
 * @param o2 The structure with the second primer's data.
 * @param pos1 The start position of the amplicon.
 * @param pos2 The end position of the amplicon.
 * @param err1 The number of errors in the first primer.
 * @param err2 The number of errors in the second primer.
 * @param strand The DNA strand direction of the amplicon (R(everse) or D(irect)).
 * @param kingdom_mode Whether the kingdom or the superkingdom informations should be printed to the output.
 * @param keep_nucleotides Number of nucleotides kept on each side of the amplicon (not including the primers if they are kept).
 * @param keep_primers Whether to keep the primers.
 * @param i_id_column A pointer on the input sequence identifier column.
 * @param o_id_column A pointer on the output sequence identifier column.
 * @param o_ori_seq_len_column A pointer on the original sequence length column.
 * @param o_amplicon_column A pointer on the output sequence column.
 * @param o_amplicon_length_column A pointer on the output amplicon length column.
 * @param o_taxid_column A pointer on the output taxid column.
 * @param o_rank_column A pointer on the output taxonomic rank column.
 * @param o_name_column A pointer on the output scientific name column.
 * @param o_species_taxid_column A pointer on the output species taxid column.
 * @param o_species_name_column A pointer on the output species name column.
 * @param o_genus_taxid_column A pointer on the output genus taxid column.
 * @param o_genus_name_column A pointer on the output genus name column.
 * @param o_family_taxid_column A pointer on the output family taxid column.
 * @param o_family_name_column A pointer on the output family name column.
 * @param o_kingdom_taxid_column A pointer on the output kingdom taxid column.
 * @param o_kingdom_name_column A pointer on the output kingdom name column.
 * @param o_superkingdom_taxid_column A pointer on the output superkingdom taxid column.
 * @param o_superkingdom_name_column A pointer on the output superkingdom name column.
 * @param o_strand_column A pointer on the output strand direction column.
 * @param o_primer1_column A pointer on the output first primer column.
 * @param o_primer2_column A pointer on the output second primer column.
 * @param o_error1_column A pointer on the output column for the error count in the first primer.
 * @param o_error2_column A pointer on the output column for the error count in the second primer.
 * @param o_temp1_column A pointer on the output column for the temperature for the first primer.
 * @param o_temp2_column A pointer on the output column for the temperature for the second primer.
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since July 2018
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static int print_seq(Obiview_p i_view, Obiview_p o_view,
					 index_t i_idx, index_t o_idx,
					 OBIDMS_taxonomy_p taxonomy,
					 char* sequence,
					 obiint_t taxid,
					 int seq_len,
					 int32_t amplicon_len,
					 const char* primer1, const char* primer2,
					 PNNParams tparm,
					 PatternPtr o1, PatternPtr o2,
					 int32_t pos1, int32_t pos2,
					 int32_t err1, int32_t err2,
					 char strand, bool kingdom_mode,
					 int keep_nucleotides,
					 bool keep_primers,
					 OBIDMS_column_p i_id_column, OBIDMS_column_p o_id_column, OBIDMS_column_p o_ori_seq_len_column,
					 OBIDMS_column_p o_amplicon_column, OBIDMS_column_p o_amplicon_length_column,
					 OBIDMS_column_p o_taxid_column, OBIDMS_column_p o_rank_column, OBIDMS_column_p o_name_column,
					 OBIDMS_column_p o_species_taxid_column, OBIDMS_column_p o_species_name_column,
					 OBIDMS_column_p o_genus_taxid_column, OBIDMS_column_p o_genus_name_column,
					 OBIDMS_column_p o_family_taxid_column, OBIDMS_column_p o_family_name_column,
					 OBIDMS_column_p o_kingdom_taxid_column, OBIDMS_column_p o_kingdom_name_column,
					 OBIDMS_column_p o_superkingdom_taxid_column, OBIDMS_column_p o_superkingdom_name_column,
					 OBIDMS_column_p o_strand_column,
					 OBIDMS_column_p o_primer1_column, OBIDMS_column_p o_primer2_column,
					 OBIDMS_column_p o_error1_column, OBIDMS_column_p o_error2_column,
					 OBIDMS_column_p o_temp1_column, OBIDMS_column_p o_temp2_column);


/************************************************************************
 *
 * D E F I N I T I O N   O F   T H E   P R I V A T E   F U N C T I O N S
 *
 ************************************************************************/

static int create_output_columns(Obiview_p o_view, bool kingdom_mode)
{
	// Original length column
	if (obi_view_add_column(o_view, ECOPCR_SEQLEN_COLUMN_NAME, -1, NULL, OBI_INT, 0, 1, NULL, false, false, false, NULL, NULL, -1, ECOPCR_SEQLEN_COLUMN_COMMENTS, true) < 0)
	{
		obidebug(1, "\nError creating the %s column", ECOPCR_SEQLEN_COLUMN_NAME);
		return -1;
	}

	// Amplicon length column
	if (obi_view_add_column(o_view, ECOPCR_AMPLICONLEN_COLUMN_NAME, -1, NULL, OBI_INT, 0, 1, NULL, false, false, false, NULL, NULL, -1, ECOPCR_AMPLICONLEN_COLUMN_COMMENTS, true) < 0)
	{
		obidebug(1, "\nError creating the %s column", ECOPCR_AMPLICONLEN_COLUMN_NAME);
		return -1;
	}

	// Taxid column
	if (obi_view_add_column(o_view, TAXID_COLUMN, -1, NULL, OBI_INT, 0, 1, NULL, false, false, false, NULL, NULL, -1, TAXID_COLUMN_COMMENTS, true) < 0)
	{
		obidebug(1, "\nError creating the %s column", TAXID_COLUMN);
		return -1;
	}

	// Taxonomic rank column
	if (obi_view_add_column(o_view, ECOPCR_RANK_COLUMN_NAME, -1, NULL, OBI_STR, 0, 1, NULL, false, false, false, NULL, NULL, -1, ECOPCR_RANK_COLUMN_COMMENTS, true) < 0)
	{
		obidebug(1, "\nError creating the %s column", ECOPCR_RANK_COLUMN_NAME);
		return -1;
	}

	// Species taxid column
	if (obi_view_add_column(o_view, ECOPCR_SPECIES_TAXID_COLUMN_NAME, -1, NULL, OBI_INT, 0, 1, NULL, false, false, false, NULL, NULL, -1, ECOPCR_SPECIES_TAXID_COLUMN_COMMENTS, true) < 0)
	{
		obidebug(1, "\nError creating the %s column", ECOPCR_SPECIES_TAXID_COLUMN_NAME);
		return -1;
	}

	// Genus taxid column
	if (obi_view_add_column(o_view, ECOPCR_GENUS_TAXID_COLUMN_NAME, -1, NULL, OBI_INT, 0, 1, NULL, false, false, false, NULL, NULL, -1, ECOPCR_GENUS_TAXID_COLUMN_COMMENTS, true) < 0)
	{
		obidebug(1, "\nError creating the %s column", ECOPCR_GENUS_TAXID_COLUMN_NAME);
		return -1;
	}

	// Family taxid column
	if (obi_view_add_column(o_view, ECOPCR_FAMILY_TAXID_COLUMN_NAME, -1, NULL, OBI_INT, 0, 1, NULL, false, false, false, NULL, NULL, -1, ECOPCR_FAMILY_TAXID_COLUMN_COMMENTS, true) < 0)
	{
		obidebug(1, "\nError creating the %s column", ECOPCR_FAMILY_TAXID_COLUMN_NAME);
		return -1;
	}

	if (kingdom_mode)
	{
		// Kingdom taxid column
		if (obi_view_add_column(o_view, ECOPCR_KINGDOM_TAXID_COLUMN_NAME, -1, NULL, OBI_INT, 0, 1, NULL, false, false, false, NULL, NULL, -1, ECOPCR_KINGDOM_TAXID_COLUMN_COMMENTS, true) < 0)
		{
			obidebug(1, "\nError creating the %s column", ECOPCR_KINGDOM_TAXID_COLUMN_NAME);
			return -1;
		}
	}
	else
	{
		// Superkingdom taxid column
		if (obi_view_add_column(o_view, ECOPCR_SUPERKINGDOM_TAXID_COLUMN_NAME, -1, NULL, OBI_INT, 0, 1, NULL, false, false, false, NULL, NULL, -1, ECOPCR_SUPERKINGDOM_TAXID_COLUMN_COMMENTS, true) < 0)
		{
			obidebug(1, "\nError creating the %s column", ECOPCR_SUPERKINGDOM_TAXID_COLUMN_NAME);
			return -1;
		}
	}

	// Scientific name column
	if (obi_view_add_column(o_view, ECOPCR_SCIENTIFIC_NAME_COLUMN_NAME, -1, NULL, OBI_STR, 0, 1, NULL, false, false, false, NULL, NULL, -1, ECOPCR_SCIENTIFIC_NAME_COLUMN_COMMENTS, true) < 0)
	{
		obidebug(1, "\nError creating the %s column", ECOPCR_SCIENTIFIC_NAME_COLUMN_NAME);
		return -1;
	}

	// Species name column
	if (obi_view_add_column(o_view, ECOPCR_SPECIES_NAME_COLUMN_NAME, -1, NULL, OBI_STR, 0, 1, NULL, false, false, false, NULL, NULL, -1, ECOPCR_SPECIES_NAME_COLUMN_COMMENTS, true) < 0)
	{
		obidebug(1, "\nError creating the %s column", ECOPCR_SPECIES_NAME_COLUMN_NAME);
		return -1;
	}

	// Genus name column
	if (obi_view_add_column(o_view, ECOPCR_GENUS_NAME_COLUMN_NAME, -1, NULL, OBI_STR, 0, 1, NULL, false, false, false, NULL, NULL, -1, ECOPCR_GENUS_NAME_COLUMN_COMMENTS, true) < 0)
	{
		obidebug(1, "\nError creating the %s column", ECOPCR_GENUS_NAME_COLUMN_NAME);
		return -1;
	}

	// Family name column
	if (obi_view_add_column(o_view, ECOPCR_FAMILY_NAME_COLUMN_NAME, -1, NULL, OBI_STR, 0, 1, NULL, false, false, false, NULL, NULL, -1, ECOPCR_FAMILY_NAME_COLUMN_COMMENTS, true) < 0)
	{
		obidebug(1, "\nError creating the %s column", ECOPCR_FAMILY_NAME_COLUMN_NAME);
		return -1;
	}

	if (kingdom_mode)
	{
		// Kingdom name column
		if (obi_view_add_column(o_view, ECOPCR_KINGDOM_NAME_COLUMN_NAME, -1, NULL, OBI_STR, 0, 1, NULL, false, false, false, NULL, NULL, -1, ECOPCR_KINGDOM_NAME_COLUMN_COMMENTS, true) < 0)
		{
			obidebug(1, "\nError creating the %s column", ECOPCR_KINGDOM_NAME_COLUMN_NAME);
			return -1;
		}
	}
	else
	{
		// Superkingdom name column
		if (obi_view_add_column(o_view, ECOPCR_SUPERKINGDOM_NAME_COLUMN_NAME, -1, NULL, OBI_STR, 0, 1, NULL, false, false, false, NULL, NULL, -1, ECOPCR_SUPERKINGDOM_NAME_COLUMN_COMMENTS, true) < 0)
		{
			obidebug(1, "\nError creating the %s column", ECOPCR_SUPERKINGDOM_NAME_COLUMN_NAME);
			return -1;
		}
	}

	// Strand column
	if (obi_view_add_column(o_view, ECOPCR_STRAND_COLUMN_NAME, -1, NULL, OBI_CHAR, 0, 1, NULL, false, false, false, NULL, NULL, -1, ECOPCR_STRAND_COLUMN_COMMENTS, true) < 0)
	{
		obidebug(1, "\nError creating the %s column", ECOPCR_STRAND_COLUMN_NAME);
		return -1;
	}

	// Primer 1 column
	if (obi_view_add_column(o_view, ECOPCR_PRIMER1_COLUMN_NAME, -1, NULL, OBI_SEQ, 0, 1, NULL, false, false, false, NULL, NULL, -1, ECOPCR_PRIMER1_COLUMN_COMMENTS, true) < 0)
	{
		obidebug(1, "\nError creating the %s column", ECOPCR_PRIMER1_COLUMN_NAME);
		return -1;
	}

	// Primer 2 column
	if (obi_view_add_column(o_view, ECOPCR_PRIMER2_COLUMN_NAME, -1, NULL, OBI_SEQ, 0, 1, NULL, false, false, false, NULL, NULL, -1, ECOPCR_PRIMER2_COLUMN_COMMENTS, true) < 0)
	{
		obidebug(1, "\nError creating the %s column", ECOPCR_PRIMER2_COLUMN_NAME);
		return -1;
	}

	// Error 1 column
	if (obi_view_add_column(o_view, ECOPCR_ERROR1_COLUMN_NAME, -1, NULL, OBI_INT, 0, 1, NULL, false, false, false, NULL, NULL, -1, ECOPCR_ERROR1_COLUMN_COMMENTS, true) < 0)
	{
		obidebug(1, "\nError creating the %s column", ECOPCR_ERROR1_COLUMN_NAME);
		return -1;
	}

	// Error 2 column
	if (obi_view_add_column(o_view, ECOPCR_ERROR2_COLUMN_NAME, -1, NULL, OBI_INT, 0, 1, NULL, false, false, false, NULL, NULL, -1, ECOPCR_ERROR2_COLUMN_COMMENTS, true) < 0)
	{
		obidebug(1, "\nError creating the %s column", ECOPCR_ERROR2_COLUMN_NAME);
		return -1;
	}

	// Temperature 1 column
	if (obi_view_add_column(o_view, ECOPCR_TEMP1_COLUMN_NAME, -1, NULL, OBI_FLOAT, 0, 1, NULL, false, false, false, NULL, NULL, -1, ECOPCR_TEMP1_COLUMN_COMMENTS, true) < 0)
	{
		obidebug(1, "\nError creating the %s column", ECOPCR_TEMP1_COLUMN_NAME);
		return -1;
	}

	// Temperature 2 column
	if (obi_view_add_column(o_view, ECOPCR_TEMP2_COLUMN_NAME, -1, NULL, OBI_FLOAT, 0, 1, NULL, false, false, false, NULL, NULL, -1, ECOPCR_TEMP2_COLUMN_COMMENTS, true) < 0)
	{
		obidebug(1, "\nError creating the %s column", ECOPCR_TEMP2_COLUMN_NAME);
		return -1;
	}

	return 0;
}


static int print_seq(Obiview_p i_view, Obiview_p o_view,
					 index_t i_idx, index_t o_idx,
					 OBIDMS_taxonomy_p taxonomy,
					 char* sequence,
					 obiint_t taxid,
					 int seq_len,
					 int32_t amplicon_len,
					 const char* primer1, const char* primer2,
					 PNNParams tparm,
					 PatternPtr o1, PatternPtr o2,
					 int32_t pos1, int32_t pos2,
					 int32_t err1, int32_t err2,
					 char strand, bool kingdom_mode,
					 int keep_nucleotides,
					 bool keep_primers,
					 OBIDMS_column_p i_id_column, OBIDMS_column_p o_id_column, OBIDMS_column_p o_ori_seq_len_column,
					 OBIDMS_column_p o_amplicon_column, OBIDMS_column_p o_amplicon_length_column,
					 OBIDMS_column_p o_taxid_column, OBIDMS_column_p o_rank_column, OBIDMS_column_p o_name_column,
					 OBIDMS_column_p o_species_taxid_column, OBIDMS_column_p o_species_name_column,
					 OBIDMS_column_p o_genus_taxid_column, OBIDMS_column_p o_genus_name_column,
					 OBIDMS_column_p o_family_taxid_column, OBIDMS_column_p o_family_name_column,
					 OBIDMS_column_p o_kingdom_taxid_column, OBIDMS_column_p o_kingdom_name_column,
					 OBIDMS_column_p o_superkingdom_taxid_column, OBIDMS_column_p o_superkingdom_name_column,
					 OBIDMS_column_p o_strand_column,
					 OBIDMS_column_p o_primer1_column, OBIDMS_column_p o_primer2_column,
					 OBIDMS_column_p o_error1_column, OBIDMS_column_p o_error2_column,
					 OBIDMS_column_p o_temp1_column, OBIDMS_column_p o_temp2_column)
{
	const char* seq_id;
	ecotx_t*    main_taxon;
	ecotx_t*    taxon;
	int32_t     rank_idx;
	const char* rank_label;

	char     oligo1[MAX_PAT_LEN+1] = {0};
	char     oligo2[MAX_PAT_LEN+1] = {0};

	int32_t  error1;
	int32_t  error2;
	int32_t  ldelta, rdelta;
	int32_t  len_with_primers;

	char*    amplicon = NULL;
	double   tm1,tm2;
	//double   tm=0;

	int32_t i;

	// TODO add check for primer longer than MAX_PAT_LEN (32)

	ldelta = (pos1 <= keep_nucleotides)?pos1:keep_nucleotides;
	rdelta = ((pos2+keep_nucleotides)>=seq_len)?seq_len-pos2:keep_nucleotides;

	amplicon = getSubSequence(sequence, pos1-ldelta, pos2+rdelta);
	len_with_primers = amplicon_len + o1->patlen + o2->patlen;

	if (strand == 'R')
	{
	    ecoComplementSequence(amplicon);

		strncpy(oligo1, amplicon + rdelta, o2->patlen);

		oligo1[o2->patlen] = 0;
		error1 = err2;

		strncpy(oligo2, amplicon + rdelta + len_with_primers - o1->patlen, o1->patlen);
		oligo2[o1->patlen] = 0;
		error2 = err1;

		if (!keep_primers)
			amplicon+=o2->patlen;
		else
		{
			keep_nucleotides = ldelta;
			ldelta = rdelta+o2->patlen;
			rdelta = keep_nucleotides+o1->patlen;
		}
	}
	else /* strand == 'D' */
	{
		strncpy(oligo1, amplicon+ldelta, o1->patlen);
		oligo1[o1->patlen] = 0;
		error1 = err1;

		strncpy(oligo2, amplicon + ldelta + len_with_primers - o2->patlen, o2->patlen);
		oligo2[o2->patlen] = 0;
		error2 = err2;

		if (!keep_primers)
			amplicon+=o1->patlen;
		else
		{
			ldelta+=o1->patlen;
			rdelta+=o2->patlen;
		}
	}

	ecoComplementSequence(oligo2);
	if (!keep_primers)
		amplicon[amplicon_len]=0;
	else
	{
		amplicon_len = ldelta+rdelta+amplicon_len;
		amplicon[amplicon_len] = 0;
	}

	tm1=nparam_CalcTwoTM(tparm, oligo1, primer1, o1->patlen) - 273.15;
	tm2=nparam_CalcTwoTM(tparm, oligo2, primer2, o2->patlen) - 273.15;
	//tm = (tm1 < tm2) ? tm1:tm2;

	if (isnan(tm1))
		tm1 = OBIFloat_NA;
	if (isnan(tm2))
		tm2 = OBIFloat_NA;

	// Get the taxon structure
	main_taxon = obi_taxo_get_taxon_with_taxid(taxonomy, taxid);
	if (main_taxon == NULL)
	{
		obidebug(1, "\nError reading the taxonomic information of a sequence");
		return -1;
	}

	// Write sequence id
	seq_id = obi_get_str_with_elt_idx_and_col_p_in_view(i_view, i_id_column, i_idx, 0);
	if (obi_set_str_with_elt_idx_and_col_p_in_view(o_view, o_id_column, o_idx, 0, seq_id) < 0)
	{
		obidebug(1, "\nError writing the sequence id");
		return -1;
	}

	// Write original sequence length
	if (obi_set_int_with_elt_idx_and_col_p_in_view(o_view, o_ori_seq_len_column, o_idx, 0, seq_len) < 0)
	{
		obidebug(1, "\nError writing the original sequence length");
		return -1;
	}

	// Write the amplicon itself
	if (obi_set_seq_with_elt_idx_and_col_p_in_view(o_view, o_amplicon_column, o_idx, 0, amplicon) < 0)
	{
		obidebug(1, "\nError writing the amplicon");
		return -1;
	}

	// Write the amplicon length
	if (obi_set_int_with_elt_idx_and_col_p_in_view(o_view, o_amplicon_length_column, o_idx, 0, amplicon_len) < 0)
	{
		obidebug(1, "\nError writing the amplicon length");
		return -1;
	}

	// Write taxonomic rank
	rank_idx = main_taxon->rank;
	rank_label = obi_taxo_rank_index_to_label(rank_idx, taxonomy->ranks);
	if (rank_label == NULL)
	{
		obidebug(1, "\nError reading the taxonomic rank");
		return -1;
	}
	if (obi_set_str_with_elt_idx_and_col_p_in_view(o_view, o_rank_column, o_idx, 0, rank_label) < 0)
	{
		obidebug(1, "\nError writing the taxonomic rank");
		return -1;
	}

	// Write taxid
	if (obi_set_int_with_elt_idx_and_col_p_in_view(o_view, o_taxid_column, o_idx, 0, taxid) < 0)
	{
		obidebug(1, "\nError writing the taxid");
		return -1;
	}

	// Write scientific name
	if (obi_set_str_with_elt_idx_and_col_p_in_view(o_view, o_name_column, o_idx, 0, main_taxon->name) < 0)
	{
		obidebug(1, "\nError writing the scientific name");
		return -1;
	}

	// Write species informations if available
	taxon = obi_taxo_get_species(main_taxon, taxonomy);
	if (taxon)
	{
		if (obi_set_int_with_elt_idx_and_col_p_in_view(o_view, o_species_taxid_column, o_idx, 0, taxon->taxid) < 0)
		{
			obidebug(1, "\nError writing the species taxid");
			return -1;
		}
		if (obi_set_str_with_elt_idx_and_col_p_in_view(o_view, o_species_name_column, o_idx, 0, taxon->name) < 0)
		{
			obidebug(1, "\nError writing the species name");
			return -1;
		}
	}

	// Write genus informations if available
	taxon = obi_taxo_get_genus(main_taxon, taxonomy);
	if (taxon)
	{
		if (obi_set_int_with_elt_idx_and_col_p_in_view(o_view, o_genus_taxid_column, o_idx, 0, taxon->taxid) < 0)
		{
			obidebug(1, "\nError writing the genus taxid");
			return -1;
		}
		if (obi_set_str_with_elt_idx_and_col_p_in_view(o_view, o_genus_name_column, o_idx, 0, taxon->name) < 0)
		{
			obidebug(1, "\nError writing the genus name");
			return -1;
		}
	}

	// Write family informations if available
	taxon = obi_taxo_get_family(main_taxon, taxonomy);
	if (taxon)
	{
		if (obi_set_int_with_elt_idx_and_col_p_in_view(o_view, o_family_taxid_column, o_idx, 0, taxon->taxid) < 0)
		{
			obidebug(1, "\nError writing the family taxid");
			return -1;
		}
		if (obi_set_str_with_elt_idx_and_col_p_in_view(o_view, o_family_name_column, o_idx, 0, taxon->name) < 0)
		{
			obidebug(1, "\nError writing the family name");
			return -1;
		}
	}

	// Write kingdom or superkingdom informations if available
	if (kingdom_mode)
	{
		taxon = obi_taxo_get_kingdom(main_taxon, taxonomy);
		if (taxon)
		{
			if (obi_set_int_with_elt_idx_and_col_p_in_view(o_view, o_kingdom_taxid_column, o_idx, 0, taxon->taxid) < 0)
			{
				obidebug(1, "\nError writing the kingdom taxid");
				return -1;
			}
			if (obi_set_str_with_elt_idx_and_col_p_in_view(o_view, o_kingdom_name_column, o_idx, 0, taxon->name) < 0)
			{
				obidebug(1, "\nError writing the kingdom name");
				return -1;
			}
		}
	}
	else
	{
		taxon = obi_taxo_get_superkingdom(main_taxon, taxonomy);
		if (taxon)
		{
			if (obi_set_int_with_elt_idx_and_col_p_in_view(o_view, o_superkingdom_taxid_column, o_idx, 0, taxon->taxid) < 0)
			{
				obidebug(1, "\nError writing the superkingdom taxid");
				return -1;
			}
			if (obi_set_str_with_elt_idx_and_col_p_in_view(o_view, o_superkingdom_name_column, o_idx, 0, taxon->name) < 0)
			{
				obidebug(1, "\nError writing the superkingdom name");
				return -1;
			}
		}
	}

	// Write strand
	if (obi_set_char_with_elt_idx_and_col_p_in_view(o_view, o_strand_column, o_idx, 0, strand) < 0)
	{
		obidebug(1, "\nError writing the strand");
		return -1;
	}

	// Write primer1
	if (obi_set_seq_with_elt_idx_and_col_p_in_view(o_view, o_primer1_column, o_idx, 0, oligo1) < 0)
	{
		obidebug(1, "\nError writing the first primer: >%s<", oligo1);
		return -1;
	}

	// Write primer2
	if (obi_set_seq_with_elt_idx_and_col_p_in_view(o_view, o_primer2_column, o_idx, 0, oligo2) < 0)
	{
		obidebug(1, "\nError writing the second primer");
		return -1;
	}

	// Write error1
	if (obi_set_int_with_elt_idx_and_col_p_in_view(o_view, o_error1_column, o_idx, 0, error1) < 0)
	{
		obidebug(1, "\nError writing the first error count");
		return -1;
	}

	// Write error2
	if (obi_set_int_with_elt_idx_and_col_p_in_view(o_view, o_error2_column, o_idx, 0, error2) < 0)
	{
		obidebug(1, "\nError writing the second error count");
		return -1;
	}

	// Write temp1
	if (obi_set_float_with_elt_idx_and_col_p_in_view(o_view, o_temp1_column, o_idx, 0, tm1) < 0)
	{
		obidebug(1, "\nError writing the first temperature");
		return -1;
	}

	// Write temp2
	if (obi_set_float_with_elt_idx_and_col_p_in_view(o_view, o_temp2_column, o_idx, 0, tm2) < 0)
	{
		obidebug(1, "\nError writing the second temperature");
		return -1;
	}

	return 0;
}


/**********************************************************************
 *
 * D E F I N I T I O N   O F   T H E   P U B L I C   F U N C T I O N S
 *
 **********************************************************************/


int obi_ecopcr(const char* i_dms_name,
		       const char* i_view_name,
			   const char* taxonomy_name,     // TODO discuss that input dms assumed
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
			   double salt,
			   int saltmethod,
			   int keep_nucleotides,
			   bool keep_primers,
			   bool kingdom_mode)
{

	index_t       i_idx;
	index_t       o_idx;
	int           r,g;
	float 		  p;

	CNNParams     tparm;

	PatternPtr    o1;
	PatternPtr    o2;
	PatternPtr    o1c;
	PatternPtr 	  o2c;

	OBIDMS_p          i_dms = NULL;
	OBIDMS_p          o_dms = NULL;
	OBIDMS_taxonomy_p taxonomy = NULL;
	Obiview_p         i_view = NULL;
	Obiview_p         o_view = NULL;
	OBIDMS_column_p   i_seq_column = NULL, i_taxid_column = NULL, \
						i_id_column = NULL, o_id_column = NULL, \
						o_ori_seq_len_column = NULL, o_amplicon_column = NULL, o_amplicon_length_column = NULL, \
						o_taxid_column = NULL, o_rank_column = NULL, o_name_column = NULL, \
						o_species_taxid_column = NULL, o_species_name_column = NULL, \
						o_genus_taxid_column = NULL, o_genus_name_column = NULL, \
						o_family_taxid_column = NULL, o_family_name_column = NULL, \
						o_kingdom_taxid_column = NULL, o_kingdom_name_column = NULL, \
						o_superkingdom_taxid_column = NULL, o_superkingdom_name_column = NULL, \
						o_strand_column = NULL, \
						o_primer1_column = NULL, o_primer2_column = NULL, \
						o_error1_column = NULL, o_error2_column = NULL, \
						o_temp1_column = NULL, o_temp2_column = NULL;

	index_t       seq_count;

	index_t       checkedSequence  = 0;

	obiint_t      taxid;
	char*         sequence;

	SeqPtr        apatseq=NULL;
	int32_t       o1Hits;
	int32_t       o2Hits;
	int32_t       o1cHits;
	int32_t       o2cHits;
	int32_t       length;
	int32_t		  begin;
	StackiPtr     stktmp;
	int32_t       i;
	int32_t       j;
	int32_t       posi;
	int32_t		  posj;
	int32_t       erri;
	int32_t		  errj;

	signal(SIGINT, sig_handler);

	if (keep_nucleotides > 0)
		keep_primers = true;

	if (circular)
	{
		circular = strlen(primer1);
		if (strlen(primer2)>(size_t)circular)
			circular = strlen(primer2);
	}

	nparam_InitParams(&tparm,
			          DEF_CONC_PRIMERS,
				 	  DEF_CONC_PRIMERS,
					  salt,
					  saltmethod);

    if (!primer1 || !primer2)
	{
		obi_set_errno(OBI_ECOPCR_ERROR);
		obidebug(1, "\nError: first and/or second primer(s) not specified (%s, %s)", primer1, primer2);
		return -1;
	}

	o1 = buildPattern(primer1, error_max);
	o2 = buildPattern(primer2, error_max);

	o1c = complementPattern(o1);
	o2c = complementPattern(o2);

	// Open input DMS
	i_dms = obi_open_dms(i_dms_name, false);
	if (i_dms == NULL)
	{
		obidebug(1, "\nError opening the input DMS");
		return -1;
	}

	// Open input sequence view
	i_view = obi_open_view(i_dms, i_view_name);
	if (i_view == NULL)
	{
		obidebug(1, "\nError opening the input view");
		return -1;
	}

	// Open output DMS
	o_dms = obi_open_dms(o_dms_name, false);
	if (o_dms == NULL)
	{
		obidebug(1, "\nError opening the output DMS");
		return -1;
	}

	// Create output view
	o_view = obi_new_view_nuc_seqs(o_dms, o_view_name, NULL, NULL, o_view_comments, false, true);
	if (o_view == NULL)
	{
		obidebug(1, "\nError creating the output view");
		return -1;
	}

	// Create output columns
	if (create_output_columns(o_view, kingdom_mode) < 0)
	{
		obidebug(1, "\nError creating the output columns");
		return -1;
	}

	// Open all the input and output columns needed and keep pointers for efficiency
	if (strcmp((i_view->infos)->view_type, VIEW_TYPE_NUC_SEQS) == 0)
		i_seq_column = obi_view_get_column(i_view, NUC_SEQUENCE_COLUMN);
	else
	{
		obi_set_errno(OBI_ECOPCR_ERROR);
		obidebug(1, "\nError: no sequence column");
		return -1;
	}
	if (i_seq_column == NULL)
	{
		obidebug(1, "\nError getting the sequence column");
		return -1;
	}
	i_id_column = obi_view_get_column(i_view, ID_COLUMN);
	if (i_id_column == NULL)
	{
		obidebug(1, "\nError getting the input id column");
		return -1;
	}
	i_taxid_column = obi_view_get_column(i_view, TAXID_COLUMN);
	if (i_taxid_column == NULL)
	{
		obidebug(1, "\nError getting the taxid column");
		return -1;
	}
	o_id_column = obi_view_get_column(o_view, ID_COLUMN);
	if (o_id_column == NULL)
	{
		obidebug(1, "\nError getting the output id column");
		return -1;
	}
	o_ori_seq_len_column = obi_view_get_column(o_view, ECOPCR_SEQLEN_COLUMN_NAME);
	if (o_ori_seq_len_column == NULL)
	{
		obidebug(1, "\nError getting the output original sequence length column");
		return -1;
	}
	o_amplicon_column = obi_view_get_column(o_view, NUC_SEQUENCE_COLUMN);
	if (o_amplicon_column == NULL)
	{
		obidebug(1, "\nError getting the output sequence column");
		return -1;
	}
	o_amplicon_length_column = obi_view_get_column(o_view, ECOPCR_AMPLICONLEN_COLUMN_NAME);
	if (o_amplicon_length_column == NULL)
	{
		obidebug(1, "\nError getting the output amplicon length column");
		return -1;
	}
	o_taxid_column = obi_view_get_column(o_view, TAXID_COLUMN);
	if (o_taxid_column == NULL)
	{
		obidebug(1, "\nError getting the output taxid column");
		return -1;
	}
	o_rank_column = obi_view_get_column(o_view, ECOPCR_RANK_COLUMN_NAME);
	if (o_rank_column == NULL)
	{
		obidebug(1, "\nError getting the output rank column");
		return -1;
	}
	o_name_column = obi_view_get_column(o_view, ECOPCR_SCIENTIFIC_NAME_COLUMN_NAME);
	if (o_name_column == NULL)
	{
		obidebug(1, "\nError getting the output scientific name column");
		return -1;
	}
	o_species_taxid_column = obi_view_get_column(o_view, ECOPCR_SPECIES_TAXID_COLUMN_NAME);
	if (o_species_taxid_column == NULL)
	{
		obidebug(1, "\nError getting the output species taxid column");
		return -1;
	}
	o_species_name_column = obi_view_get_column(o_view, ECOPCR_SPECIES_NAME_COLUMN_NAME);
	if (o_species_name_column == NULL)
	{
		obidebug(1, "\nError getting the output species name column");
		return -1;
	}
	o_genus_taxid_column = obi_view_get_column(o_view, ECOPCR_GENUS_TAXID_COLUMN_NAME);
	if (o_genus_taxid_column == NULL)
	{
		obidebug(1, "\nError getting the output genus taxid column");
		return -1;
	}
	o_genus_name_column = obi_view_get_column(o_view, ECOPCR_GENUS_NAME_COLUMN_NAME);
	if (o_genus_name_column == NULL)
	{
		obidebug(1, "\nError getting the output genus name column");
		return -1;
	}
	o_family_taxid_column = obi_view_get_column(o_view, ECOPCR_FAMILY_TAXID_COLUMN_NAME);
	if (o_family_taxid_column == NULL)
	{
		obidebug(1, "\nError getting the output family taxid column");
		return -1;
	}
	o_family_name_column = obi_view_get_column(o_view, ECOPCR_FAMILY_NAME_COLUMN_NAME);
	if (o_family_name_column == NULL)
	{
		obidebug(1, "\nError getting the output family name column");
		return -1;
	}
	if (kingdom_mode)
	{
		o_kingdom_taxid_column = obi_view_get_column(o_view, ECOPCR_KINGDOM_TAXID_COLUMN_NAME);
		if (o_kingdom_taxid_column == NULL)
		{
			obidebug(1, "\nError getting the output kingdom taxid column");
			return -1;
		}
		o_kingdom_name_column = obi_view_get_column(o_view, ECOPCR_KINGDOM_NAME_COLUMN_NAME);
		if (o_kingdom_name_column == NULL)
		{
			obidebug(1, "\nError getting the output kingdom name column");
			return -1;
		}
	}
	else
	{
		o_superkingdom_taxid_column = obi_view_get_column(o_view, ECOPCR_SUPERKINGDOM_TAXID_COLUMN_NAME);
		if (o_superkingdom_taxid_column == NULL)
		{
			obidebug(1, "\nError getting the output superkingdom taxid column");
			return -1;
		}
		o_superkingdom_name_column = obi_view_get_column(o_view, ECOPCR_SUPERKINGDOM_NAME_COLUMN_NAME);
		if (o_superkingdom_name_column == NULL)
		{
			obidebug(1, "\nError getting the output superkingdom name column");
			return -1;
		}
	}
	o_strand_column = obi_view_get_column(o_view, ECOPCR_STRAND_COLUMN_NAME);
	if (o_strand_column == NULL)
	{
		obidebug(1, "\nError getting the output strand column");
		return -1;
	}
	o_primer1_column = obi_view_get_column(o_view, ECOPCR_PRIMER1_COLUMN_NAME);
	if (o_primer1_column == NULL)
	{
		obidebug(1, "\nError getting the output primer1 column");
		return -1;
	}
	o_primer2_column = obi_view_get_column(o_view, ECOPCR_PRIMER2_COLUMN_NAME);
	if (o_primer2_column == NULL)
	{
		obidebug(1, "\nError getting the output primer2 column");
		return -1;
	}
	o_error1_column = obi_view_get_column(o_view, ECOPCR_ERROR1_COLUMN_NAME);
	if (o_error1_column == NULL)
	{
		obidebug(1, "\nError getting the output error1 column");
		return -1;
	}
	o_error2_column = obi_view_get_column(o_view, ECOPCR_ERROR2_COLUMN_NAME);
	if (o_error2_column == NULL)
	{
		obidebug(1, "\nError getting the output error2 column");
		return -1;
	}
	o_temp1_column = obi_view_get_column(o_view, ECOPCR_TEMP1_COLUMN_NAME);
	if (o_temp1_column == NULL)
	{
		obidebug(1, "\nError getting the output temp1 column");
		return -1;
	}
	o_temp2_column = obi_view_get_column(o_view, ECOPCR_TEMP2_COLUMN_NAME);
	if (o_temp2_column == NULL)
	{
		obidebug(1, "\nError getting the output temp2 column");
		return -1;
	}

	// Open the taxonomy
	taxonomy = obi_read_taxonomy(i_dms, taxonomy_name, false);
	if (taxonomy == NULL)
	{
		obidebug(1, "\nError opening the taxonomy");
		return -1;
	}

	checkedSequence = 0;

	seq_count = (i_view->infos)->line_count;

	// Count number of restricted taxids
	i=0;
	while (restrict_to_taxids[i] != -1)
		i++;
	r=i;

	// Count number of ignored taxids
	i=0;
	while (ignore_taxids[i] != -1)
		i++;
	g=i;

	o_idx = 0;
	for (i_idx=0; i_idx<seq_count; i_idx++)
	{
		if (i_idx%1000 == 0)
		{
			p = (i_idx/(float)(seq_count))*100;
		    fprintf(stderr,"\rDone : %f %%          ", p);
		}

		if (! keep_running)
			return -1;

		checkedSequence++;

		// Get the taxid
		taxid = obi_get_int_with_elt_idx_and_col_p_in_view(i_view, i_taxid_column, i_idx, 0);

		// Get the sequence
		sequence = obi_get_seq_with_elt_idx_and_col_p_in_view(i_view, i_seq_column, i_idx, 0);

		if ((taxid != OBIInt_NA) && (sequence != OBISeq_NA))
		{
			/**
			* Check if current sequence should be included
			**/
			if ((r == 0) || (obi_taxo_is_taxid_included(taxonomy, restrict_to_taxids, r, taxid)))   // TODO taxid mystery to check  // TODO test
			{
				if ((g == 0) || !(obi_taxo_is_taxid_included(taxonomy, ignore_taxids, g, taxid)))  // TODO taxid mystery to check  // TODO test
				{
					apatseq = ecoseq2apatseq(sequence, apatseq, circular);

					o1Hits = ManberAll(apatseq, o1, 0, 0, apatseq->seqlen+apatseq->circular);
					o2cHits= 0;

					if (o1Hits)
					{
						stktmp = apatseq->hitpos[0];
						begin = stktmp->val[0] + o1->patlen;

						if (max_len)
							length = stktmp->val[stktmp->top-1] + o1->patlen - begin + max_len + o2->patlen;
						else
							length = apatseq->seqlen - begin;

						if (circular)
						{
							begin = 0;
							length = apatseq->seqlen+circular;
						}

						o2cHits = ManberAll(apatseq, o2c, 1, begin, length);

						if (o2cHits)
						{
							for (i=0; i < o1Hits; i++)
							{
								posi = apatseq->hitpos[0]->val[i];

								if (posi < apatseq->seqlen)
								{
									erri = apatseq->hiterr[0]->val[i];
									for (j=0; j < o2cHits; j++)
									{
										posj = apatseq->hitpos[1]->val[j];

										if (posj < apatseq->seqlen)
										{
											posj+=o2c->patlen;
											errj = apatseq->hiterr[1]->val[j];
											length = 0;
											if (posj > posi)
												length = posj - posi - o1->patlen - o2->patlen;
											if (posj < posi)
												length = posj + apatseq->seqlen - posi - o1->patlen - o2->patlen;
											if ((length>0) &&	// For when primers touch or overlap
												(!min_len || (length >= min_len)) &&
												(!max_len || (length <= max_len)))
											{
												// Print the found amplicon
												if (print_seq(i_view, o_view,
														  	  i_idx, o_idx,
															  taxonomy,
															  sequence,
															  taxid,
															  apatseq->seqlen,
															  length,
															  primer1, primer2,
															  &tparm,
														  	  o1, o2c,
															  posi, posj,
														  	  erri, errj,
															  'D', kingdom_mode,
															  keep_nucleotides,
															  keep_primers,
															  i_id_column, o_id_column, o_ori_seq_len_column,
															  o_amplicon_column, o_amplicon_length_column,
															  o_taxid_column, o_rank_column, o_name_column,
															  o_species_taxid_column, o_species_name_column,
															  o_genus_taxid_column, o_genus_name_column,
															  o_family_taxid_column, o_family_name_column,
														  	  o_kingdom_taxid_column, o_kingdom_name_column,
															  o_superkingdom_taxid_column, o_superkingdom_name_column,
															  o_strand_column,
															  o_primer1_column, o_primer2_column,
															  o_error1_column, o_error2_column,
															  o_temp1_column,  o_temp2_column) < 0)
												{
													obidebug(1, "\nError writing the ecopcr result");
													return -1;
												}
												o_idx++;
											}
										}
									}
								}
							}
						}
					}

					o2Hits = ManberAll(apatseq, o2, 2, 0, apatseq->seqlen);
					o1cHits= 0;

					if (o2Hits)
					{
						stktmp = apatseq->hitpos[2];
						begin = stktmp->val[0] + o2->patlen;

						if (max_len)
							length = stktmp->val[stktmp->top-1] + o2->patlen - begin + max_len + o1->patlen;
						else
							length = apatseq->seqlen - begin;

						if (circular)
						{
							begin = 0;
							length = apatseq->seqlen+circular;
						}

						o1cHits = ManberAll(apatseq, o1c, 3, begin, length);

						if (o1cHits)
						{
							for (i=0; i < o2Hits; i++)
							{
								posi = apatseq->hitpos[2]->val[i];

								if (posi < apatseq->seqlen)
								{
									erri = apatseq->hiterr[2]->val[i];
									for (j=0; j < o1cHits; j++)
									{
										posj = apatseq->hitpos[3]->val[j];
										if (posj < apatseq->seqlen)
										{
											posj+=o1c->patlen;
											errj=apatseq->hiterr[3]->val[j];

											length = 0;
											if (posj > posi)
												length = posj - posi + 1  - o2->patlen - o1->patlen; /* - o1->patlen : deleted by <EC> (prior to the OBITools3) */
											if (posj < posi)
												length = posj + apatseq->seqlen - posi - o1->patlen - o2->patlen;
											if ((length>0) &&	// For when primers touch or overlap
												(!min_len || (length >= min_len)) &&
												(!max_len || (length <= max_len)))
											{
												// Print the found amplicon
												if (print_seq(i_view, o_view,
														  	  i_idx, o_idx,
															  taxonomy,
															  sequence,
															  taxid,
															  apatseq->seqlen,
															  length,
															  primer1, primer2,
															  &tparm,
														  	  o2, o1c,
															  posi, posj,
														  	  erri, errj,
															  'R', kingdom_mode,
															  keep_nucleotides,
															  keep_primers,
															  i_id_column, o_id_column, o_ori_seq_len_column,
															  o_amplicon_column, o_amplicon_length_column,
															  o_taxid_column, o_rank_column, o_name_column,
															  o_species_taxid_column, o_species_name_column,
															  o_genus_taxid_column, o_genus_name_column,
															  o_family_taxid_column, o_family_name_column,
														  	  o_kingdom_taxid_column, o_kingdom_name_column,
															  o_superkingdom_taxid_column, o_superkingdom_name_column,
															  o_strand_column,
															  o_primer1_column, o_primer2_column,
															  o_error1_column, o_error2_column,
															  o_temp1_column,  o_temp2_column) < 0)
												{
													obidebug(1, "\nError writing the ecopcr result");
													return -1;
												}
												o_idx++;
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}

		free(sequence);
	}

	if (delete_apatseq((apatseq)) < 0)
	{
		obidebug(1, "\nError freeing a sequence structure");
		return -1;
	}

	// Close views
	if (obi_save_and_close_view(i_view) < 0)
	{
		obidebug(1, "\nError closing the input view");
		return -1;
	}

	if (obi_save_and_close_view(o_view) < 0)
	{
		obidebug(1, "\nError closing the output view");
		return -1;
	}

	// Close the taxonomy
	if (obi_close_taxonomy(taxonomy) < 0)
	{
		obidebug(1, "\nError closing the taxonomy");
		return -1;
	}

	fprintf(stderr,"\rDone : 100 %%           ");
	return 0;

	return 0;
}



