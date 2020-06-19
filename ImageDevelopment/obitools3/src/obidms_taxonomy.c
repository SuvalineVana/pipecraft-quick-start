/********************************************************************
 * OBIDMS taxonomy functions                                        *
 ********************************************************************/

/**
 * @file obidms_taxonomy.c
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 * @date March 2nd 2016
 * @brief Functions for handling the reading and writing of taxonomy files.
 */


#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <unistd.h>

#include "obidms_taxonomy.h"
#include "obidms.h"
#include "obidebug.h"
#include "obierrno.h"
#include "utils.h"


#define DEBUG_LEVEL 0	// TODO has to be defined somewhere else (cython compil flag?)


/**************************************************************************
 *
 * D E C L A R A T I O N   O F   T H E   P R I V A T E   F U N C T I O N S
 *
 **************************************************************************/


/**
 * @brief Internal function comparing two rank names.
 *
 * @param label1 A char* pointer on the first rank name.
 * @param label2 A char** pointer on a second pointer, that second char* pointer being on the second rank name.
 * 				 (making the function usable with an ecorankidx_t structure and functions like bsearch)
 *
 * @returns A value < 0 if label1 < label2,
 * 			a value > 0 if label1 > label2,
 * 			and 0 if label1 == label2.
 */
static int cmp_rank_labels(const void* label1, const void* label2);


/**
 * @brief Internal function comparing two taxids, one of them stored in an ecotx_t structure.
 *
 * @param ptaxid The first taxid.
 * @param ptaxon A pointer on an ecotx_t structure where the second taxid is stored.
 *
 * @returns A value < 0 if taxid1 < taxid2,
 * 			a value > 0 if taxid1 > taxid2,
 * 			and 0 if taxid1 == taxid2.
 */
static int cmp_taxids_in_ecotx_t(const void* ptaxid, const void* ptaxon);


/**
 * @brief Internal function comparing two taxids, one of them stored in an ecomerged_t structure.
 *
 * @param ptaxid The first taxid.
 * @param ptaxon A pointer on an ecomerged_t structure where the second taxid is stored.
 *
 * @returns A value < 0 if taxid1 < taxid2,
 * 			a value > 0 if taxid1 > taxid2,
 * 			and 0 if taxid1 == taxid2.
 *
 * @since January 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static int cmp_taxids_in_ecomerged_t(const void* ptaxid, const void* ptaxon);


/**
 * @brief Internal function comparing two character strings pointed to by char** pointers.
 *
 * @param s1 A char** pointer on a second pointer, that second char* pointer being on the first character string.
 * @param s2 A char** pointer on a second pointer, that second char* pointer being on the second character string.
 *
 * @returns A value < 0 if s1 < s2,
 * 			a value > 0 if s1 > s2,
 * 			and 0 if s1 == s2.
 */
static int cmp_str(const void* s1, const void* s2);


/**
 * @brief Internal function comparing two taxon names stored in econame_t structures.
 *
 * @param n1 A pointer on the first econame_t structure.
 * @param n2 A pointer on the second econame_t structure.
 *
 * @returns A value < 0 if n1 < n2,
 * 			a value > 0 if n1 > n2,
 * 			and 0 if n1 == n2.
 *
 * @since 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static int cmp_names(const void* n1, const void* n2);


/**
 * @brief Internal function comparing returning the ecotx_t structure associated with a taxid.
 *
 * This function only looks for the taxid in the modern taxonomy, it does not consider deprecated
 * and old taxids, unlike obi_taxo_get_taxon_with_taxid().
 *
 * @param taxonomy A pointer on the taxonomy structure.
 * @param taxid The taxid of the taxon wanted.
 *
 * @returns A pointer on the ecotx_t structure associated with a taxid.
 *
 * @see obi_taxo_get_taxon_with_taxid()
 */
static ecotx_t* get_taxon_with_current_taxid(OBIDMS_taxonomy_p taxonomy, int32_t taxid);


/**
 * @brief Internal function returning the complete path to a taxonomy directory in a DMS.
 *
 * @param dms A pointer on the DMS.
 * @param tax_name The name of the taxonomy.
 *
 * @returns The complete path to the taxonomy directory.
 * @retval NULL if an error occurred.
 *
 * @since 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static char* get_taxonomy_path(OBIDMS_p dms, const char* tax_name);


/**
 * @brief Internal function returning the index of a rank in an ecorankidx_t structure.
 *
 * @param label The name of the rank.
 * @param ranks A pointer on an ecorankidx_t structure.
 *
 * @returns The index of a rank in the ecorankidx_t structure.
 * @retval -1 if the rank was not found.
 */
static int32_t rank_label_to_index(const char* label, ecorankidx_t* ranks);


/**
 * @brief Internal function opening a binary taxonomy file (.tdx, .rdx, .ndx, .adx, .pdx, .ldx).
 *
 * @param file_name The file path.
 * @param count A pointer on an integer that the function will set to the number of records in the file.
 * @param abort_on_open_error A boolean indicating whether the function should trigger an error if the file can't be open.
 *
 * @returns The FILE object.
 * @retval NULL if an error occurred or if the file was not found.
 */
static FILE* open_ecorecorddb(const char* file_name, int32_t* count, int32_t abort_on_open_error);


/**
 * @brief Internal function returning the next record in a binary taxonomy file (.tdx, .rdx, .ndx, .adx, .pdx, .ldx).
 *
 * @param f The file object with the offset at the start of a record.
 * @param record_size A pointer on an integer that the function will set to the size of the record.
 *
 * @returns A pointer on the read record.
 * @retval NULL if an error occurred.
 */
static void* read_ecorecord(FILE* f, int32_t* record_size);


/**
 * @brief Internal function reading the next taxon record in a .tdx binary taxonomy file.
 *
 * @param f The file object with the offset at the start of a record.
 * @param taxon A pointer on an empty, allocated ecotx_t structure that the function will fill.
 *
 * @returns A pointer on the read record.
 * @retval NULL if an error occurred.
 */
static ecotx_t* readnext_ecotaxon(FILE* f, ecotx_t* taxon);


/**
 * @brief Internal function reading the next taxon name record in a .ndx binary taxonomy file.
 *
 * @param f The file object with the offset at the start of a record.
 * @param name A pointer on an empty, allocated econame_t structure that the function will fill.
 * @param taxonomy A pointer on the taxonomy structure.
 *
 * @returns A pointer on the read record.
 * @retval NULL if an error occurred.
 */
static econame_t* readnext_econame(FILE* f, econame_t* name, OBIDMS_taxonomy_p taxonomy);


/**
 * @brief Internal function reading the next taxon preferred name record in a .pdx binary taxonomy file.
 *
 * @param f The file object with the offset at the start of a record.
 * @param name A pointer on an empty, allocated econame_t structure that the function will fill.
 * @param taxonomy A pointer on the taxonomy structure.
 *
 * @returns A pointer on the read record.
 * @retval NULL if an error occurred.
 *
 * @since January 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static econame_t* readnext_ecopreferredname(FILE* f, econame_t* name, OBIDMS_taxonomy_p taxonomy);


/**
 * @brief Internal function reading a taxonomic ranks (.rdx) binary taxonomy file.
 *
 * @param ranks_file_name The name of the .rdx file to read.
 *
 * @returns A pointer on an ecorankidx_t structure.
 * @retval NULL if an error occurred.
 */
static ecorankidx_t* read_ranks_idx(const char* ranks_file_name);


/**
 * @brief Internal function reading the taxa (.tdx, .ldx) binary taxonomy file.
 *
 * @param taxa_file_name The name of the .tdx file to read.
 * @param local_taxa_file_name The name of the .ldx file containing the local taxa to read if there is one.
 *
 * @returns A pointer on an ecotxidx_t structure.
 * @retval NULL if an error occurred.
 */
static ecotxidx_t* read_taxonomy_idx(const char* taxa_file_name, const char* local_taxa_file_name);


/**
 * @brief Internal function reading a names (.ndx) binary taxonomy file.
 *
 * @param file_name The name of the .ndx file to read.
 * @param taxonomy A pointer on the taxonomy structure.
 *
 * @returns A pointer on an econameidx_t structure.
 * @retval NULL if an error occurred.
 */
static econameidx_t* read_names_idx(const char* file_name, OBIDMS_taxonomy_p taxonomy);


/**
 * @brief Internal function reading a preferred names (.pdx) binary taxonomy file.
 *
 * @param file_name The name of the .pdx file to read.
 * @param taxonomy A pointer on the taxonomy structure.
 *
 * @returns A pointer on an econameidx_t structure.
 * @retval NULL if an error occurred.
 *
 * @since January 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static econameidx_t* read_preferred_names_idx(const char* file_name, OBIDMS_taxonomy_p taxonomy);


/**
 * @brief Internal function reading a merged index (.adx) binary taxonomy file.
 *
 * @param file_name The name of the .adx file to read.
 * @param taxonomy A pointer on the taxonomy structure.
 *
 * @returns A pointer on an ecomergedidx_t structure.
 * @retval NULL if an error occurred.
 *
 * @since January 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static ecomergedidx_t* read_merged_idx(const char* file_name, OBIDMS_taxonomy_p taxonomy);


/**
 * @brief Internal function writing a rank index (.rdx) binary taxonomy file.
 *
 * @param dms A pointer on the DMS.
 * @param tax A pointer on the taxonomy structure.
 * @param taxonomy_name The name of the taxonomy.
 *
 * @returns An integer value indicating the success of the operation.
 * @retval 0 on success.
 * @retval -1 if an error occurred.
 */
static int write_ranks_idx(OBIDMS_p dms, OBIDMS_taxonomy_p tax, const char* taxonomy_name);


/**
 * @brief Internal function writing a taxonomy index (.tdx) binary taxonomy file.
 *
 * @param dms A pointer on the DMS.
 * @param tax A pointer on the taxonomy structure.
 * @param taxonomy_name The name of the taxonomy.
 *
 * @returns An integer value indicating the success of the operation.
 * @retval 0 on success.
 * @retval -1 if an error occurred.
 */
static int write_taxonomy_idx(OBIDMS_p dms, OBIDMS_taxonomy_p tax, const char* taxonomy_name);


/**
 * @brief Internal function writing a local taxonomy index (.ldx) binary taxonomy file.
 *
 * @param dms A pointer on the DMS.
 * @param tax A pointer on the taxonomy structure.
 * @param taxonomy_name The name of the taxonomy.
 *
 * @returns An integer value indicating the success of the operation.
 * @retval 0 on success.
 * @retval -1 if an error occurred.
 *
 * @since 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static int write_local_taxonomy_idx(OBIDMS_p dms, OBIDMS_taxonomy_p tax, const char* taxonomy_name);


/**
 * @brief Internal function writing a names index (.ndx) binary taxonomy file.
 *
 * @param dms A pointer on the DMS.
 * @param tax A pointer on the taxonomy structure.
 * @param taxonomy_name The name of the taxonomy.
 *
 * @returns An integer value indicating the success of the operation.
 * @retval 0 on success.
 * @retval -1 if an error occurred.
 */
static int write_names_idx(OBIDMS_p dms, OBIDMS_taxonomy_p tax, const char* taxonomy_name);


/**
 * @brief Internal function writing a preferred names index (.pdx) binary taxonomy file.
 *
 * @param dms A pointer on the DMS.
 * @param tax A pointer on the taxonomy structure.
 * @param taxonomy_name The name of the taxonomy.
 *
 * @returns An integer value indicating the success of the operation.
 * @retval 0 on success.
 * @retval -1 if an error occurred.
 *
 * @since January 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static int write_preferred_names_idx(OBIDMS_p dms, OBIDMS_taxonomy_p tax, const char* taxonomy_name);


/**
 * @brief Internal function writing a merged index (.adx) binary taxonomy file.
 *
 * @param dms A pointer on the DMS.
 * @param tax A pointer on the taxonomy structure.
 * @param taxonomy_name The name of the taxonomy.
 *
 * @returns An integer value indicating the success of the operation.
 * @retval 0 on success.
 * @retval -1 if an error occurred.
 *
 * @since January 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static int write_merged_idx(OBIDMS_p dms, OBIDMS_taxonomy_p tax, const char* taxonomy_name);


/**
 * @brief Internal function reading the 'nodes.dmp' file from an NCBI taxdump.
 *
 * @param taxdump The path to the taxdump.
 * @param tax A pointer on the taxonomy structure.
 * @param rank_names_p A char*** pointer on a non allocated char* array where the function will store rank names.
 * @param parent_taxids_p An int** pointer on a non allocated int array where the function will store parent taxids.
 *
 * @returns An integer value indicating the success of the operation.
 * @retval 0 on success.
 * @retval -1 if an error occurred.
 *
 * @since January 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static int read_nodes_dmp(const char* taxdump, OBIDMS_taxonomy_p tax, char*** rank_names_p, int** parent_taxids_p);


/**
 * @brief Internal function reading the 'delnodes.dmp' file from an NCBI taxdump.
 *
 * @param taxdump The path to the taxdump.
 * @param tax A pointer on the taxonomy structure.
 * @param delnodes_p An int** pointer on a non allocated int array where the function will store deleted taxids.
 * @param delnodes_count An int* pointer where the function will store the number of deleted taxids.
 *
 * @returns An integer value indicating the success of the operation.
 * @retval 0 on success.
 * @retval -1 if an error occurred.
 *
 * @since January 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static int read_delnodes_dmp(const char* taxdump, OBIDMS_taxonomy_p tax, int32_t** delnodes_p, int32_t* delnodes_count);


/**
 * @brief Internal function reading the 'merged.dmp' file from an NCBI taxdump.
 *
 * @warning Should be used AFTER read_nodes_dmp() and read_delnodes_dmp().
 *
 * The function merges the information about current nodes previously read in read_nodes_dmp(),
 * the information about deleted nodes previously read in read_delnodes_dmp(), and the information read
 * in the 'merged.dmp' file, to build the final merged taxon index in the taxonomy structure.
 *
 * @param taxdump The path to the taxdump.
 * @param tax A pointer on the taxonomy structure.
 * @param delnodes An int* pointer containing the deleted taxids.
 * @param delnodes_count The number of deleted taxids.
 *
 * @returns An integer value indicating the success of the operation.
 * @retval 0 on success.
 * @retval -1 if an error occurred.
 *
 * @since January 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static int read_merged_dmp(const char* taxdump, OBIDMS_taxonomy_p tax, int32_t* delnodes, int32_t delnodes_count);


/**
 * @brief Internal function reading the 'names.dmp' file from an NCBI taxdump.
 *
 * @param taxdump The path to the taxdump.
 * @param tax A pointer on the taxonomy structure.
 *
 * @returns An integer value indicating the success of the operation.
 * @retval 0 on success.
 * @retval -1 if an error occurred.
 *
 * @since January 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static int read_names_dmp(const char* taxdump, OBIDMS_taxonomy_p tax);


/************************************************************************
 *
 * D E F I N I T I O N   O F   T H E   P R I V A T E   F U N C T I O N S
 *
 ************************************************************************/


static int cmp_rank_labels(const void* label1, const void* label2)
{
	return strcmp((const char*)label1,*(const char**)label2);
}


static int cmp_taxids_in_ecotx_t(const void* ptaxid, const void* ptaxon)
{
  ecotx_t* current_taxon = (ecotx_t*) ptaxon;
  int32_t  taxid = (int32_t) ((size_t) ptaxid);
  return taxid - current_taxon->taxid;
}


static int cmp_taxids_in_ecomerged_t(const void* ptaxid, const void* ptaxon)
{
  ecomerged_t* current_taxon = (ecomerged_t*) ptaxon;
  int32_t  taxid = (int32_t) ((size_t) ptaxid);
  return taxid - current_taxon->taxid;
}


static int cmp_str(const void* s1, const void* s2)
{
    return strcmp(*((char**)s1), *((char**)s2));
}


static int cmp_names(const void* n1, const void* n2)
{
	econame_t name1 = *((econame_t*)n1);
	econame_t name2 = *((econame_t*)n2);

    return strcmp(name1.name, name2.name);
}


static ecotx_t* get_taxon_with_current_taxid(OBIDMS_taxonomy_p taxonomy, int32_t taxid)
{
	ecotx_t *current_taxon;
	int32_t  count;

	count = (taxonomy->taxa)->count;

	current_taxon = (ecotx_t*) bsearch((const void *) ((size_t) taxid),
                                       (const void *) taxonomy->taxa->taxon,
                                       count,
                                       sizeof(ecotx_t),
									   cmp_taxids_in_ecotx_t);
	return current_taxon;
}


static char* get_taxonomy_path(OBIDMS_p dms, const char* tax_name)
{
	char*   all_tax_dir_path;
	char*   tax_path;

	all_tax_dir_path = obi_dms_get_full_path(dms, TAXONOMY_DIR_NAME);
	if (all_tax_dir_path == NULL)
		return NULL;

	tax_path = (char*) malloc((strlen(all_tax_dir_path) + strlen(tax_name) + 2)*sizeof(char));
	if (tax_path == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating memory for taxonomy path");
		free(all_tax_dir_path);
		return NULL;
	}

	if (sprintf(tax_path, "%s/%s", all_tax_dir_path, tax_name) < 0)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError building taxonomy path");
		free(all_tax_dir_path);
		return NULL;
	}

	free(all_tax_dir_path);

	return tax_path;
}


static int32_t rank_label_to_index(const char* label, ecorankidx_t* ranks)
{
	char **rep;

	rep = bsearch(label, ranks->label, ranks->count, sizeof(char*), cmp_rank_labels);

	if (rep)
		return rep-ranks->label;

	return -1;
}


static FILE* open_ecorecorddb(const char* file_name,
                       int32_t*    count,
                       int32_t     abort_on_open_error)
{
    FILE*		f;
	int32_t     read;

	f = fopen(file_name, "rb");

	if (!f)
	{
		if (abort_on_open_error)
		{
	 		obi_set_errno(OBI_TAXONOMY_ERROR);
	 		obidebug(1, "\nCouldn't open a taxonomy file");
	 		return NULL;
		}
	 	else
	 	{
	 		*count = 0;
	 		return NULL;
	 	}
	}

	read = fread(count,
	      		 sizeof(int32_t),
				 1,
	      		 f);

	if (read != 1)
	{
 		obi_set_errno(OBI_TAXONOMY_ERROR);
 		obidebug(1, "\nError reading taxonomy record size");
 		fclose(f);
 		return NULL;
	}

	return f;
}


static void* read_ecorecord(FILE* f, int32_t* record_size)
{
	static void* buffer = NULL;
	int32_t      buffer_size = 0;
	int32_t      read;

	if (!record_size)
	{
 		obi_set_errno(OBI_TAXONOMY_ERROR);
 		obidebug(1, "\nError reading a taxonomy file: record_size can not be NULL");
 		return NULL;
	}

	read = fread(record_size,
	      		 sizeof(int32_t),
				 1,
	             f);

	if (feof(f))
	{
 		obi_set_errno(OBI_TAXONOMY_ERROR);
 		obidebug(1, "\nError reading a taxonomy file: reached end of file");
 		return NULL;
	}

	if (read != 1)
	{
 		obi_set_errno(OBI_TAXONOMY_ERROR);
 		obidebug(1, "\nError reading a taxonomy file: error reading record size");
 		return NULL;
	}

	if (buffer_size < *record_size)
	{
		if (buffer)
			buffer = realloc(buffer, *record_size);
		else
			buffer = malloc(*record_size);
		if (buffer == NULL)
		{
	 		obi_set_errno(OBI_MALLOC_ERROR);
	 		obidebug(1, "\nError reading a taxonomy file: error allocating memory");
	 		return NULL;
		}
	}

	read = fread(buffer,
				 *record_size,
				 1,
				 f);

	if (read != 1)
	{
 		obi_set_errno(OBI_TAXONOMY_ERROR);
 		obidebug(1, "\nError reading a taxonomy file: error reading a record %d, %d", read, *record_size);
 		free(buffer);
 		return NULL;
	}

	return buffer;
};


static ecotx_t* readnext_ecotaxon(FILE* f, ecotx_t* taxon)
{
	ecotxformat_t* raw;
	int32_t        record_length;

	raw = read_ecorecord(f, &record_length);
	if (!raw)
		return NULL;

	taxon->parent = (ecotx_t*) ((size_t) raw->parent);
	taxon->taxid  = raw->taxid;
	taxon->rank   = raw->rank;
	taxon->farest = -1;

	taxon->name   = malloc((raw->name_length+1) * sizeof(char));
	if (taxon->name == NULL)
	{
 		obi_set_errno(OBI_MALLOC_ERROR);
 		obidebug(1, "\nError reading a taxonomy file: error allocating memory");
 		return NULL;
	}

	strncpy(taxon->name, raw->name, raw->name_length);
	taxon->name[raw->name_length] = 0;					// TODO note: this line is probably missing in ROBITaxonomy and source of a bug

	return taxon;
}


static econame_t* readnext_econame(FILE* f, econame_t* name, OBIDMS_taxonomy_p taxonomy)
{
	econameformat_t* raw;
	int32_t          record_length;

	raw = read_ecorecord(f, &record_length);
	if (raw == NULL)
 		return NULL;

	name->is_scientific_name = raw->is_scientific_name;

	name->name = malloc((raw->name_length + 1) * sizeof(char));
	if (name->name == NULL)
	{
 		obi_set_errno(OBI_MALLOC_ERROR);
 		obidebug(1, "\nError allocating memory for a taxon name");
 		free(raw);
 		return NULL;
	}
	strncpy(name->name, raw->names, raw->name_length);
	name->name[raw->name_length] = 0;

	name->class_name = malloc((raw->class_length+1) * sizeof(char));
	if (name->class_name == NULL)
	{
 		obi_set_errno(OBI_MALLOC_ERROR);
 		obidebug(1, "\nError allocating memory for a taxon class name");
 		free(name->name);
 		free(raw);
 		return NULL;
	}
	strncpy(name->class_name,(raw->names + raw->name_length), raw->class_length);
	name->class_name[raw->class_length] = 0;

	name->taxon = taxonomy->taxa->taxon + raw->taxid;

	return name;
}


static econame_t* readnext_ecopreferredname(FILE* f, econame_t* name, OBIDMS_taxonomy_p taxonomy)
{
	econameformat_t* raw;
	int32_t          record_length;

	raw = read_ecorecord(f, &record_length);
	if (raw == NULL)
 		return NULL;

	name->is_scientific_name = raw->is_scientific_name;

	name->name = malloc((raw->name_length + 1) * sizeof(char));
	if (name->name == NULL)
	{
 		obi_set_errno(OBI_MALLOC_ERROR);
 		obidebug(1, "\nError allocating memory for a taxon preferred name");
 		free(raw);
 		return NULL;
	}
	strncpy(name->name, raw->names, raw->name_length);
	name->name[raw->name_length] = 0;

	name->class_name = malloc((raw->class_length+1) * sizeof(char));
	if (name->class_name == NULL)
	{
 		obi_set_errno(OBI_MALLOC_ERROR);
 		obidebug(1, "\nError allocating memory for a taxon class name");
 		free(name->name);
 		free(raw);
 		return NULL;
	}
	strncpy(name->class_name,(raw->names + raw->name_length), raw->class_length);
	name->class_name[raw->class_length] = 0;

	name->taxon = taxonomy->taxa->taxon + raw->taxid;

	// Add the preferred name in the taxon structure 	// TODO discuss: couldn't they all use the same pointer?
	(taxonomy->taxa->taxon + raw->taxid)->preferred_name = malloc((raw->name_length + 1) * sizeof(char));
	if ((taxonomy->taxa->taxon + raw->taxid)->preferred_name == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating memory for a taxon preferred name");
		free(name->name);
		free(name->class_name);
		free(raw);
		return NULL;
	}
	strcpy((taxonomy->taxa->taxon + raw->taxid)->preferred_name, name->name);

	return name;
}


static ecorankidx_t* read_ranks_idx(const char* ranks_file_name)
{
	int32_t      			count;
	FILE*        			ranks_file;
	ecorankidx_t*           ranks_index;
	int32_t      			i;
	int32_t      			rank_length;
	char*					buffer;

	ranks_file = open_ecorecorddb(ranks_file_name, &count, 0);
	if (ranks_file==NULL)
		return NULL;

	ranks_index = (ecorankidx_t*) malloc(sizeof(ecorankidx_t) + sizeof(char*) * count);
	if (ranks_index == NULL)
	{
 		obi_set_errno(OBI_MALLOC_ERROR);
 		obidebug(1, "\nError allocating memory for taxonomy rank structure");
 		fclose(ranks_file);
 		return NULL;
	}

	ranks_index->count = count;

	for (i=0; i < count; i++)
	{
		buffer = read_ecorecord(ranks_file, &rank_length);
		if (buffer == NULL)
		{
	 		obi_set_errno(OBI_TAXONOMY_ERROR);
	 		obidebug(1, "\nError reading a value in a taxonomy file");
	 		fclose(ranks_file);
	 		free(ranks_index);
	 		return NULL;
		}
		ranks_index->label[i] = (char*) malloc(rank_length+1);
		if (ranks_index->label[i] == NULL)
		{
	 		obi_set_errno(OBI_MALLOC_ERROR);
	 		obidebug(1, "\nError allocating memory for taxonomy rank label");
	 		fclose(ranks_file);
	 		free(ranks_index);
	 		free(buffer);
	 		return NULL;
		}
		strncpy(ranks_index->label[i], buffer, rank_length);
		(ranks_index->label[i])[rank_length] = 0;
	}

	fclose(ranks_file);

	return ranks_index;
}


static ecotxidx_t* read_taxonomy_idx(const char* taxa_file_name, const char* local_taxa_file_name)
{
	int32_t      	  count_taxa;
	int32_t      	  count_local_taxa;
	FILE*			  f_taxa;
	FILE* 			  f_local_taxa;
	ecotxidx_t*		  taxa_index;
	struct ecotxnode* t;
	int32_t      	  i;
	int32_t      	  j;

	f_taxa = open_ecorecorddb(taxa_file_name, &count_taxa, 1);
	if (f_taxa == NULL)
	{
 		obidebug(1, "\nError reading taxonomy taxa file");
 		return NULL;
	}

	f_local_taxa = open_ecorecorddb(local_taxa_file_name, &count_local_taxa, 0);

	taxa_index = (ecotxidx_t*) malloc(sizeof(ecotxidx_t) + sizeof(ecotx_t) * (count_taxa + count_local_taxa));
	if (taxa_index == NULL)
	{
 		obi_set_errno(OBI_MALLOC_ERROR);
 		obidebug(1, "\nError allocating memory for taxonomy structure");
 		fclose(f_taxa);
 		fclose(f_local_taxa);
 		return NULL;
	}

	taxa_index->count = count_taxa + count_local_taxa;
	taxa_index->ncbi_count = count_taxa;
	taxa_index->local_count = count_local_taxa;
	taxa_index->buffer_size = taxa_index->count;

	taxa_index->max_taxid = 0;
	printf("Reading %d taxa...\n", count_taxa);
	for (i=0; i<count_taxa; i++)
	{
		readnext_ecotaxon(f_taxa, &(taxa_index->taxon[i]));
		taxa_index->taxon[i].idx = i;
		taxa_index->taxon[i].parent = taxa_index->taxon + (size_t) taxa_index->taxon[i].parent;
		taxa_index->taxon[i].parent->farest = 0;
		if (taxa_index->taxon[i].taxid > taxa_index->max_taxid)
			taxa_index->max_taxid = taxa_index->taxon[i].taxid;
		taxa_index->taxon[i].preferred_name = NULL;
	}

	if (count_local_taxa > 0)
		printf("Reading %d local taxa...\n", count_local_taxa);
	else
		printf("No local taxa\n");

	count_taxa = taxa_index->count;

	for (; i < count_taxa; i++){
		readnext_ecotaxon(f_local_taxa, &(taxa_index->taxon[i]));
		taxa_index->taxon[i].idx = i;
		taxa_index->taxon[i].parent = taxa_index->taxon + (size_t) taxa_index->taxon[i].parent;
		taxa_index->taxon[i].parent->farest=0;
		if (taxa_index->taxon[i].taxid > taxa_index->max_taxid)
			taxa_index->max_taxid = taxa_index->taxon[i].taxid;
		taxa_index->taxon[i].preferred_name = NULL;
	}

	for (i=0; i < count_taxa; i++)
	{
		t = taxa_index->taxon+i;
		if (t->farest == -1)
		{
			t->farest=0;
            while (t->parent != t)
            {
            	j = t->farest + 1;
            	if (j > t->parent->farest)
            	{
            		t->parent->farest = j;
            		t=t->parent;
            	}
            	else
            		t = taxa_index->taxon;
            }
		}
	}

	fclose(f_taxa);
	if (f_local_taxa != NULL)
		fclose(f_local_taxa);

	return taxa_index;
}


static econameidx_t* read_names_idx(const char *file_name, OBIDMS_taxonomy_p taxonomy)
{
	int32_t      		count;
	FILE*				f;
	econameidx_t*		index_names;
	int32_t      		i;

	f = open_ecorecorddb(file_name, &count, 0);
	if (f == NULL)
		return NULL;

	index_names = (econameidx_t*) malloc(sizeof(econameidx_t) + sizeof(econame_t) * count);
	if (index_names == NULL)
	{
 		obi_set_errno(OBI_MALLOC_ERROR);
 		obidebug(1, "\nError reading taxonomy name file");
 		return NULL;
	}

	index_names->count = count;

	for (i=0; i < count; i++)
	{
		readnext_econame(f, (index_names->names)+i, taxonomy);
		if ((index_names->names)+i == NULL)
		{
	 		obi_set_errno(OBI_TAXONOMY_ERROR);
	 		obidebug(1, "\nError reading taxonomy name file");
	 		free(index_names);
	 		return NULL;
		}
	}

	fclose(f);

	return index_names;
}


static econameidx_t* read_preferred_names_idx(const char *file_name, OBIDMS_taxonomy_p taxonomy)
{
	int32_t      		count;
	FILE*				f;
	econameidx_t*		index_names;
	int32_t      		i;

	f = open_ecorecorddb(file_name, &count, 0);
	if (f == NULL)
		return NULL;

	index_names = (econameidx_t*) malloc(sizeof(econameidx_t) + sizeof(econame_t) * count);
	if (index_names == NULL)
	{
 		obi_set_errno(OBI_MALLOC_ERROR);
 		obidebug(1, "\nError reading taxonomy name file");
 		return NULL;
	}

	index_names->count = count;

	for (i=0; i < count; i++)
	{
		readnext_ecopreferredname(f, (index_names->names)+i, taxonomy);
		if ((index_names->names)+i == NULL)
		{
	 		obi_set_errno(OBI_TAXONOMY_ERROR);
	 		obidebug(1, "\nError reading taxonomy name file");
	 		free(index_names);
	 		return NULL;
		}
	}

	fclose(f);

	return index_names;
}


static ecomergedidx_t* read_merged_idx(const char *file_name, OBIDMS_taxonomy_p taxonomy)
{
	int32_t      		count;
	FILE*				f;
	ecomergedidx_t*		index_merged_idx;
	ecomerged_t*		merged_idx;
	int32_t      		i;
	int32_t             record_length;

	f = open_ecorecorddb(file_name, &count, 0);
	if (f == NULL)
	{
 		obidebug(1, "\nError reading taxonomy name file");
 		return NULL;
	}

	index_merged_idx = (ecomergedidx_t*) malloc(sizeof(ecomergedidx_t) + (sizeof(ecomerged_t) * count));
	if (index_merged_idx == NULL)
	{
 		obi_set_errno(OBI_MALLOC_ERROR);
 		obidebug(1, "\nError reading taxonomy name file");
 		return NULL;
	}

	index_merged_idx->count = count;

	for (i=0; i < count; i++)
	{
		merged_idx = read_ecorecord(f, &record_length);
		memcpy((index_merged_idx->merged)+i, merged_idx, record_length);
		if ((index_merged_idx->merged)+i == NULL)
		{
	 		obi_set_errno(OBI_TAXONOMY_ERROR);
	 		obidebug(1, "\nError reading taxonomy name file");
	 		free(index_merged_idx);
	 		return NULL;
		}
	}

	fclose(f);

	return index_merged_idx;
}


static int write_ranks_idx(OBIDMS_p dms, OBIDMS_taxonomy_p tax, const char* taxonomy_name)		// TODO prefix in taxonomy struct?
{
	int     i;
	char* 	file_name;
	int 	file_descriptor;
	off_t 	file_size;
	char*   taxonomy_path;
	int32_t	length;

	// Compute file size
	file_size = sizeof(int32_t);
	for (i=0; i < (tax->ranks)->count; i++)
	{
		file_size = file_size + sizeof(int32_t);	// To store label size
		file_size = file_size + strlen(((tax->ranks)->label)[i]);	// To store label
	}

	// Build the taxonomy directory path
	taxonomy_path = get_taxonomy_path(dms, taxonomy_name);

	file_name =	(char*) malloc((strlen(taxonomy_path) + strlen(taxonomy_name) + 6)*sizeof(char));
	if (file_name == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating the memory for a binary taxonomy file name");
		return -1;
	}

	// Build the file path
	if (sprintf(file_name, "%s/%s.rdx", taxonomy_path, taxonomy_name) < 0)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError building a binary taxonomy file name");
		return -1;
	}

	free(taxonomy_path);

	// Create file
	file_descriptor = open(file_name, O_RDWR | O_CREAT | O_EXCL, 0777);
	if (file_descriptor < 0)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError creating a binary taxonomy file %s", file_name);
		free(file_name);
		return -1;
	}

	free(file_name);

	// Truncate the file to the right size
	if (ftruncate(file_descriptor, file_size) < 0)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError truncating a binary taxonomy file");
		close(file_descriptor);
		return -1;
	}

	// Write rank count
	if (write(file_descriptor, &((tax->ranks)->count), sizeof(int32_t)) < ((ssize_t) sizeof(int32_t)))
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError writing in a binary taxonomy file");
		close(file_descriptor);
		return -1;
	}

	// Write ranks
	for (i=0; i < (tax->ranks)->count; i++)
	{
		length = strlen(((tax->ranks)->label)[i]);

		// Write rank size
		if (write(file_descriptor, &length, sizeof(int32_t)) < ((ssize_t) sizeof(int32_t)))
		{
			obi_set_errno(OBI_TAXONOMY_ERROR);
			obidebug(1, "\nError writing in a binary taxonomy file");
			close(file_descriptor);
			return -1;
		}
		// Write rank label
		if (write(file_descriptor, ((tax->ranks)->label)[i], length) < ((ssize_t) length))
		{
			obi_set_errno(OBI_TAXONOMY_ERROR);
			obidebug(1, "\nError writing in a binary taxonomy file");
			close(file_descriptor);
			return -1;
		}
	}

	// Close file
	if (close(file_descriptor) < 0)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError closing an rdx taxonomy file");
		return -1;
	}

	return 0;
}


static int write_taxonomy_idx(OBIDMS_p dms, OBIDMS_taxonomy_p tax, const char* taxonomy_name)		// TODO prefix in taxonomy struct? keep argument but if NULL, use the one in struct?
{
	int     i;
	char* 	file_name;
	int 	file_descriptor;
	off_t 	file_size;
	char*   taxonomy_path;
	int32_t	name_length;
	int32_t record_size;

	// Compute file size
	file_size = sizeof(int32_t);	// To store record count
	for (i=0; i < (tax->taxa)->ncbi_count; i++)
	{
		file_size = file_size + sizeof(int32_t) * 5;				// To store record size, taxid, rank index, parent index, and name length
		file_size = file_size + strlen(tax->taxa->taxon[i].name);	// To store name
	}

	// Build the taxonomy directory path
	taxonomy_path = get_taxonomy_path(dms, taxonomy_name);

	file_name =	(char*) malloc((strlen(taxonomy_path) + strlen(taxonomy_name) + 6)*sizeof(char));
	if (file_name == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating the memory for a binary taxonomy file name");
		return -1;
	}

	// Build the file path
	if (sprintf(file_name, "%s/%s.tdx", taxonomy_path, taxonomy_name) < 0)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError building a binary taxonomy file name");
		return -1;
	}

	free(taxonomy_path);

	// Create file
	file_descriptor = open(file_name, O_RDWR | O_CREAT | O_EXCL, 0777);
	if (file_descriptor < 0)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError creating a binary taxonomy file");
		free(file_name);
		return -1;
	}

	free(file_name);

	// Truncate the file to the right size
	if (ftruncate(file_descriptor, file_size) < 0)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError truncating a binary taxonomy file");
		close(file_descriptor);
		return -1;
	}

	// Write record count
	if (write(file_descriptor, &(tax->taxa->ncbi_count), sizeof(int32_t)) < ((ssize_t) sizeof(int32_t)))
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError writing in a binary taxonomy file");
		close(file_descriptor);
		return -1;
	}

	// Write records
	for (i=0; i < (tax->taxa)->ncbi_count; i++)
	{
		name_length = strlen(tax->taxa->taxon[i].name);
		record_size = 4*sizeof(int32_t) + name_length;

		// Write record size
		if (write(file_descriptor, &record_size, sizeof(int32_t)) < ((ssize_t) sizeof(int32_t)))
		{
			obi_set_errno(OBI_TAXONOMY_ERROR);
			obidebug(1, "\nError writing in a binary taxonomy file");
			close(file_descriptor);
			return -1;
		}
		// Write taxid
		if (write(file_descriptor, &(tax->taxa->taxon[i].taxid), sizeof(int32_t)) < ((ssize_t) sizeof(int32_t)))
		{
			obi_set_errno(OBI_TAXONOMY_ERROR);
			obidebug(1, "\nError writing in a binary taxonomy file");
			close(file_descriptor);
			return -1;
		}
		// Write rank index
		if (write(file_descriptor, &(tax->taxa->taxon[i].rank), sizeof(int32_t)) < ((ssize_t) sizeof(int32_t)))
		{
			obi_set_errno(OBI_TAXONOMY_ERROR);
			obidebug(1, "\nError writing in a binary taxonomy file");
			close(file_descriptor);
			return -1;
		}
		// Write parent index
		if (write(file_descriptor, &((tax->taxa->taxon[i].parent)->idx), sizeof(int32_t)) < ((ssize_t) sizeof(int32_t)))
		{
			obi_set_errno(OBI_TAXONOMY_ERROR);
			obidebug(1, "\nError writing in a binary taxonomy file");
			close(file_descriptor);
			return -1;
		}
		// Write name length
		if (write(file_descriptor, &name_length, sizeof(int32_t)) < ((ssize_t) sizeof(int32_t)))
		{
			obi_set_errno(OBI_TAXONOMY_ERROR);
			obidebug(1, "\nError writing in a binary taxonomy file");
			close(file_descriptor);
			return -1;
		}
		// Write name
		if (write(file_descriptor, tax->taxa->taxon[i].name, name_length) < ((ssize_t) name_length))
		{
			obi_set_errno(OBI_TAXONOMY_ERROR);
			obidebug(1, "\nError writing in a binary taxonomy file");
			close(file_descriptor);
			return -1;
		}
	}

	// Close file
	if (close(file_descriptor) < 0)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError closing a tdx taxonomy file");
		return -1;
	}

	return 0;
}


static int write_local_taxonomy_idx(OBIDMS_p dms, OBIDMS_taxonomy_p tax, const char* taxonomy_name)		// TODO prefix in taxonomy struct? keep argument but if NULL, use the one in struct?
{
	int     i;
	char* 	file_name;
	int 	file_descriptor;
	off_t 	file_size;
	char*   taxonomy_path;
	int32_t	name_length;
	int32_t record_size;

	// Compute file size
	file_size = sizeof(int32_t);	// To store record count
	for (i=(tax->taxa)->ncbi_count; i < (tax->taxa)->count; i++)
	{
		file_size = file_size + sizeof(int32_t) * 5;				// To store record size, taxid, rank index, parent index, and name length
		file_size = file_size + strlen(tax->taxa->taxon[i].name);	// To store name
	}

	// Build the taxonomy directory path
	taxonomy_path = get_taxonomy_path(dms, taxonomy_name);

	file_name =	(char*) malloc((strlen(taxonomy_path) + strlen(taxonomy_name) + 6)*sizeof(char));
	if (file_name == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating the memory for a binary taxonomy file name");
		return -1;
	}

	// Build the file path
	if (sprintf(file_name, "%s/%s.ldx", taxonomy_path, taxonomy_name) < 0)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError building a binary taxonomy file name");
		return -1;
	}

	free(taxonomy_path);

	// Create file
	file_descriptor = open(file_name, O_RDWR | O_CREAT, 0777);
	if (file_descriptor < 0)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError creating a binary taxonomy file");
		free(file_name);
		return -1;
	}

	free(file_name);

	// Truncate the file to the right size
	if (ftruncate(file_descriptor, file_size) < 0)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError truncating a binary taxonomy file");
		close(file_descriptor);
		return -1;
	}

	// Write record count
	if (write(file_descriptor, &((tax->taxa)->local_count), sizeof(int32_t)) < ((ssize_t) sizeof(int32_t)))
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError writing in a binary taxonomy file");
		close(file_descriptor);
		return -1;
	}

	// Write records
	for (i=(tax->taxa)->ncbi_count; i < (tax->taxa)->count; i++)
	{
		name_length = strlen(tax->taxa->taxon[i].name);
		record_size = 4*sizeof(int32_t) + name_length;

		// Write record size
		if (write(file_descriptor, &record_size, sizeof(int32_t)) < ((ssize_t) sizeof(int32_t)))
		{
			obi_set_errno(OBI_TAXONOMY_ERROR);
			obidebug(1, "\nError writing in a binary taxonomy file");
			close(file_descriptor);
			return -1;
		}
		// Write taxid
		if (write(file_descriptor, &(tax->taxa->taxon[i].taxid), sizeof(int32_t)) < ((ssize_t) sizeof(int32_t)))
		{
			obi_set_errno(OBI_TAXONOMY_ERROR);
			obidebug(1, "\nError writing in a binary taxonomy file");
			close(file_descriptor);
			return -1;
		}
		// Write rank index
		if (write(file_descriptor, &(tax->taxa->taxon[i].rank), sizeof(int32_t)) < ((ssize_t) sizeof(int32_t)))
		{
			obi_set_errno(OBI_TAXONOMY_ERROR);
			obidebug(1, "\nError writing in a binary taxonomy file");
			close(file_descriptor);
			return -1;
		}
		// Write parent index
		if (write(file_descriptor, &((tax->taxa->taxon[i].parent)->idx), sizeof(int32_t)) < ((ssize_t) sizeof(int32_t)))
		{
			obi_set_errno(OBI_TAXONOMY_ERROR);
			obidebug(1, "\nError writing in a binary taxonomy file");
			close(file_descriptor);
			return -1;
		}
		// Write name length
		if (write(file_descriptor, &name_length, sizeof(int32_t)) < ((ssize_t) sizeof(int32_t)))
		{
			obi_set_errno(OBI_TAXONOMY_ERROR);
			obidebug(1, "\nError writing in a binary taxonomy file");
			close(file_descriptor);
			return -1;
		}
		// Write name
		if (write(file_descriptor, tax->taxa->taxon[i].name, name_length) < ((ssize_t) name_length))
		{
			obi_set_errno(OBI_TAXONOMY_ERROR);
			obidebug(1, "\nError writing in a binary taxonomy file");
			close(file_descriptor);
			return -1;
		}
	}

	// Close file
	if (close(file_descriptor) < 0)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError closing a ldx taxonomy file");
		return -1;
	}

	return 0;
}


static int write_names_idx(OBIDMS_p dms, OBIDMS_taxonomy_p tax, const char* taxonomy_name)		// TODO prefix in taxonomy struct? keep argument but if NULL, use the one in struct?
{
	int     i;
	char* 	file_name;
	int 	file_descriptor;
	off_t 	file_size;
	char*   taxonomy_path;
	int32_t	name_length;
	int32_t	class_length;
	int32_t record_size;

	// Compute file size
	file_size = sizeof(int32_t);	// To store record count
	for (i=0; i < (tax->names)->count; i++)
	{
		file_size = file_size + sizeof(int32_t) * 5;						// To store record size, taxid, rank index, parent index, and name length
		file_size = file_size + strlen(tax->names->names[i].name);			// To store name
		file_size = file_size + strlen(tax->names->names[i].class_name);	// To store name
	}

	// Build the taxonomy directory path
	taxonomy_path = get_taxonomy_path(dms, taxonomy_name);

	file_name =	(char*) malloc((strlen(taxonomy_path) + strlen(taxonomy_name) + 6)*sizeof(char));
	if (file_name == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating the memory for a binary taxonomy file name");
		return -1;
	}

	// Build the file path
	if (sprintf(file_name, "%s/%s.ndx", taxonomy_path, taxonomy_name) < 0)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError building a binary taxonomy file name");
		return -1;
	}

	free(taxonomy_path);

	// Create file
	file_descriptor = open(file_name, O_RDWR | O_CREAT | O_EXCL, 0777);
	if (file_descriptor < 0)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError creating a binary taxonomy file");
		free(file_name);
		return -1;
	}

	free(file_name);

	// Truncate the file to the right size
	if (ftruncate(file_descriptor, file_size) < 0)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError truncating a binary taxonomy file");
		close(file_descriptor);
		return -1;
	}

	// Write record count
	if (write(file_descriptor, &(tax->names->count), sizeof(int32_t)) < ((ssize_t) sizeof(int32_t)))
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError writing in a binary taxonomy file");
		close(file_descriptor);
		return -1;
	}

	// Write records
	for (i=0; i < tax->names->count; i++)
	{
		name_length = strlen(tax->names->names[i].name);
		class_length = strlen(tax->names->names[i].class_name);
		record_size = 4*sizeof(int32_t) + name_length + class_length;

		// Write record size
		if (write(file_descriptor, &record_size, sizeof(int32_t)) < ((ssize_t) sizeof(int32_t)))
		{
			obi_set_errno(OBI_TAXONOMY_ERROR);
			obidebug(1, "\nError writing in a binary taxonomy file");
			close(file_descriptor);
			return -1;
		}
		// Write if the name is a scientific name
		if (write(file_descriptor, &(tax->names->names[i].is_scientific_name), sizeof(int32_t)) < ((ssize_t) sizeof(int32_t)))
		{
			obi_set_errno(OBI_TAXONOMY_ERROR);
			obidebug(1, "\nError writing in a binary taxonomy file");
			close(file_descriptor);
			return -1;
		}
		// Write name length
		if (write(file_descriptor, &name_length, sizeof(int32_t)) < ((ssize_t) sizeof(int32_t)))
		{
			obi_set_errno(OBI_TAXONOMY_ERROR);
			obidebug(1, "\nError writing in a binary taxonomy file");
			close(file_descriptor);
			return -1;
		}
		// Write class length
		if (write(file_descriptor, &class_length, sizeof(int32_t)) < ((ssize_t) sizeof(int32_t)))
		{
			obi_set_errno(OBI_TAXONOMY_ERROR);
			obidebug(1, "\nError writing in a binary taxonomy file");
			close(file_descriptor);
			return -1;
		}
		// Write taxid index
		if (write(file_descriptor, &(tax->names->names[i].taxon->idx), sizeof(int32_t)) < ((ssize_t) sizeof(int32_t)))
		{
			obi_set_errno(OBI_TAXONOMY_ERROR);
			obidebug(1, "\nError writing in a binary taxonomy file");
			close(file_descriptor);
			return -1;
		}
		// Write name
		if (write(file_descriptor, tax->names->names[i].name, name_length) < ((ssize_t) name_length))
		{
			obi_set_errno(OBI_TAXONOMY_ERROR);
			obidebug(1, "\nError writing in a binary taxonomy file");
			close(file_descriptor);
			return -1;
		}
		// Write class
		if (write(file_descriptor, tax->names->names[i].class_name, class_length) < ((ssize_t) class_length))
		{
			obi_set_errno(OBI_TAXONOMY_ERROR);
			obidebug(1, "\nError writing in a binary taxonomy file");
			close(file_descriptor);
			return -1;
		}
	}

	// Close file
	if (close(file_descriptor) < 0)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError closing a ndx taxonomy file");
		return -1;
	}

	return 0;
}


static int write_preferred_names_idx(OBIDMS_p dms, OBIDMS_taxonomy_p tax, const char* taxonomy_name)		// TODO prefix in taxonomy struct? keep argument but if NULL, use the one in struct?
{
	int     i;
	char* 	file_name;
	int 	file_descriptor;
	off_t 	file_size;
	char*   taxonomy_path;
	int32_t	name_length;
	int32_t	class_length;
	int32_t record_size;

	// Compute file size
	file_size = sizeof(int32_t);	// To store record count
	for (i=0; i < (tax->preferred_names)->count; i++)
	{
		file_size = file_size + sizeof(int32_t) * 5;						// To store record size, taxid, rank index, parent index, and name length
		file_size = file_size + strlen(tax->preferred_names->names[i].name);			// To store name
		file_size = file_size + strlen(tax->preferred_names->names[i].class_name);	// To store name
	}

	// Build the taxonomy directory path
	taxonomy_path = get_taxonomy_path(dms, taxonomy_name);

	file_name =	(char*) malloc((strlen(taxonomy_path) + strlen(taxonomy_name) + 6)*sizeof(char));
	if (file_name == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating the memory for a binary taxonomy file name");
		return -1;
	}

	// Build the file path
	if (sprintf(file_name, "%s/%s.pdx", taxonomy_path, taxonomy_name) < 0)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError building a binary taxonomy file name");
		return -1;
	}

	free(taxonomy_path);

	// Create file
	file_descriptor = open(file_name, O_RDWR | O_CREAT, 0777);
	if (file_descriptor < 0)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError creating a binary taxonomy file");
		free(file_name);
		return -1;
	}

	free(file_name);

	// Truncate the file to the right size
	if (ftruncate(file_descriptor, file_size) < 0)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError truncating a binary taxonomy file");
		close(file_descriptor);
		return -1;
	}

	// Write record count
	if (write(file_descriptor, &(tax->preferred_names->count), sizeof(int32_t)) < ((ssize_t) sizeof(int32_t)))
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError writing in a binary taxonomy file");
		close(file_descriptor);
		return -1;
	}

	// Write records
	for (i=0; i < tax->preferred_names->count; i++)
	{
		name_length = strlen(tax->preferred_names->names[i].name);
		class_length = strlen(tax->preferred_names->names[i].class_name);
		record_size = 4*sizeof(int32_t) + name_length + class_length;

		// Write record size
		if (write(file_descriptor, &record_size, sizeof(int32_t)) < ((ssize_t) sizeof(int32_t)))
		{
			obi_set_errno(OBI_TAXONOMY_ERROR);
			obidebug(1, "\nError writing in a binary taxonomy file");
			close(file_descriptor);
			return -1;
		}
		// Write if the name is a scientific name
		if (write(file_descriptor, &(tax->preferred_names->names[i].is_scientific_name), sizeof(int32_t)) < ((ssize_t) sizeof(int32_t)))
		{
			obi_set_errno(OBI_TAXONOMY_ERROR);
			obidebug(1, "\nError writing in a binary taxonomy file");
			close(file_descriptor);
			return -1;
		}
		// Write name length
		if (write(file_descriptor, &name_length, sizeof(int32_t)) < ((ssize_t) sizeof(int32_t)))
		{
			obi_set_errno(OBI_TAXONOMY_ERROR);
			obidebug(1, "\nError writing in a binary taxonomy file");
			close(file_descriptor);
			return -1;
		}
		// Write class length
		if (write(file_descriptor, &class_length, sizeof(int32_t)) < ((ssize_t) sizeof(int32_t)))
		{
			obi_set_errno(OBI_TAXONOMY_ERROR);
			obidebug(1, "\nError writing in a binary taxonomy file");
			close(file_descriptor);
			return -1;
		}
		// Write taxid index
		if (write(file_descriptor, &(tax->preferred_names->names[i].taxon->idx), sizeof(int32_t)) < ((ssize_t) sizeof(int32_t)))
		{
			obi_set_errno(OBI_TAXONOMY_ERROR);
			obidebug(1, "\nError writing in a binary taxonomy file");
			close(file_descriptor);
			return -1;
		}
		// Write name
		if (write(file_descriptor, tax->preferred_names->names[i].name, name_length) < ((ssize_t) name_length))
		{
			obi_set_errno(OBI_TAXONOMY_ERROR);
			obidebug(1, "\nError writing in a binary taxonomy file");
			close(file_descriptor);
			return -1;
		}
		// Write class
		if (write(file_descriptor, tax->preferred_names->names[i].class_name, class_length) < ((ssize_t) class_length))
		{
			obi_set_errno(OBI_TAXONOMY_ERROR);
			obidebug(1, "\nError writing in a binary taxonomy file");
			close(file_descriptor);
			return -1;
		}
	}

	// Close file
	if (close(file_descriptor) < 0)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError closing a pdx taxonomy file");
		return -1;
	}

	return 0;
}


static int write_merged_idx(OBIDMS_p dms, OBIDMS_taxonomy_p tax, const char* taxonomy_name)		// TODO prefix in taxonomy struct?
{
	int     i;
	char* 	file_name;
	int 	file_descriptor;
	off_t 	file_size;
	char*   taxonomy_path;
	int32_t record_size;

	// Compute file size
	file_size = sizeof(int32_t) + (sizeof(int32_t) * 3 * (tax->merged_idx)->count);

	// Build the taxonomy directory path
	taxonomy_path = get_taxonomy_path(dms, taxonomy_name);

	file_name =	(char*) malloc((strlen(taxonomy_path) + strlen(taxonomy_name) + 6)*sizeof(char));
	if (file_name == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating the memory for a binary taxonomy file name");
		return -1;
	}

	// Build the file path
	if (sprintf(file_name, "%s/%s.adx", taxonomy_path, taxonomy_name) < 0)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError building a binary taxonomy file name");
		return -1;
	}

	free(taxonomy_path);

	// Create file
	file_descriptor = open(file_name, O_RDWR | O_CREAT | O_EXCL, 0777);
	if (file_descriptor < 0)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError creating a binary taxonomy file %s", file_name);
		free(file_name);
		return -1;
	}

	free(file_name);

	// Truncate the file to the right size
	if (ftruncate(file_descriptor, file_size) < 0)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError truncating a binary taxonomy file");
		close(file_descriptor);
		return -1;
	}

	// Write merged indices count
	if (write(file_descriptor, &((tax->merged_idx)->count), sizeof(int32_t)) < ((ssize_t) sizeof(int32_t)))
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError writing in a binary taxonomy file");
		close(file_descriptor);
		return -1;
	}

	record_size = 2 * sizeof(int32_t);

	// Write merged indices
	for (i=0; i < (tax->merged_idx)->count; i++)
	{
		// Write record size
		if (write(file_descriptor, &(record_size), sizeof(int32_t)) < ((ssize_t) sizeof(int32_t)))
		{
			obi_set_errno(OBI_TAXONOMY_ERROR);
			obidebug(1, "\nError writing in a binary taxonomy file");
			close(file_descriptor);
			return -1;
		}

		// Write taxid
		if (write(file_descriptor, &(((tax->merged_idx)->merged)[i].taxid), sizeof(int32_t)) < ((ssize_t) sizeof(int32_t)))
		{
			obi_set_errno(OBI_TAXONOMY_ERROR);
			obidebug(1, "\nError writing in a binary taxonomy file");
			close(file_descriptor);
			return -1;
		}

		// Write index corresponding to the taxid in the ecotxidx_t structure
		if (write(file_descriptor, &(((tax->merged_idx)->merged)[i].idx), sizeof(int32_t)) < ((ssize_t) sizeof(int32_t)))
		{
			obi_set_errno(OBI_TAXONOMY_ERROR);
			obidebug(1, "\nError writing in a binary taxonomy file");
			close(file_descriptor);
			return -1;
		}
	}

	// Close file
	if (close(file_descriptor) < 0)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError closing an adx taxonomy file");
		return -1;
	}

	return 0;
}


int read_nodes_dmp(const char* taxdump, OBIDMS_taxonomy_p tax, 	char***	rank_names_p, int** parent_taxids_p)
{
	struct dirent* 	dp;
	DIR*           	tax_dir;
	FILE*          	file;
	char*			file_name;
	bool           	file_found=false;
	char 			line[2048];			// TODO large enough?
	char*			elt;
	int				buffer_size;
	int			    i, n;

	buffer_size = 10000;

	// Initialize rank names and parent taxids arrays
	*parent_taxids_p = malloc(buffer_size * sizeof(int));
	if (*parent_taxids_p == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating the memory for the parent taxids array");
		return -1;
	}

	*rank_names_p = malloc(buffer_size * sizeof(char*));
	if (*rank_names_p == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating the memory for the rank names array");
		free(*parent_taxids_p);
		return -1;
	}

	// Open the taxdum directory
	tax_dir = opendir(taxdump);
	if (tax_dir == NULL)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nProblem opening a taxdump directory");
		free(*parent_taxids_p);
		free(*rank_names_p);
		return -1;
	}

	// Look for the 'nodes.dmp' file
	while ((dp = readdir(tax_dir)) != NULL)
	{
		if (strcmp(dp->d_name, "nodes.dmp") == 0)
		{
			file_found = true;

			// Initializing the taxa structure
			tax->taxa = (ecotxidx_t*) malloc(sizeof(ecotxidx_t) + sizeof(ecotx_t) * buffer_size);
			if (tax->taxa == NULL)
			{
				obi_set_errno(OBI_MALLOC_ERROR);
				obidebug(1, "\nError allocating the memory for a taxonomy structure");
				free(*parent_taxids_p);
				free(*rank_names_p);
				closedir(tax_dir);
				return -1;
			}

			// Allocating the memory for the file name
			file_name =	(char*) malloc((strlen(taxdump) + 11)*sizeof(char));
			if (file_name == NULL)
			{
				obi_set_errno(OBI_MALLOC_ERROR);
				obidebug(1, "\nError allocating the memory for a file name");
				free(*parent_taxids_p);
				free(*rank_names_p);
				closedir(tax_dir);
				return -1;
			}

			// Build the file path
			if (sprintf(file_name, "%s/nodes.dmp", taxdump) < 0)
			{
				obi_set_errno(OBI_TAXONOMY_ERROR);
				obidebug(1, "\nError building a taxonomy file name for 'nodes.dmp'");
				free(*parent_taxids_p);
				free(*rank_names_p);
				closedir(tax_dir);
				free(file_name);
				return -1;
			}

			file = fopen(file_name, "r");
			if (file == NULL)
			{
				obi_set_errno(OBI_TAXONOMY_ERROR);
				obidebug(1, "\nProblem opening a taxonomy file");
				free(*parent_taxids_p);
				free(*rank_names_p);
				closedir(tax_dir);
				free(file_name);
				return -1;
			}

			free(file_name);

			(tax->taxa)->max_taxid = 0;
			n = 0;
			while (fgets(line, sizeof(line), file))
			{
				// Enlarge structures if needed
				if (n == buffer_size)
				{
					buffer_size = buffer_size * 2;

					tax->taxa = (ecotxidx_t*) realloc(tax->taxa, sizeof(ecotxidx_t) + sizeof(ecotx_t) * buffer_size);
					if (tax->taxa == NULL)
					{
						obi_set_errno(OBI_MALLOC_ERROR);
						obidebug(1, "\nError reallocating memory for a taxonomy structure");
						free(*parent_taxids_p);
						free(*rank_names_p);
						fclose(file);
						closedir(tax_dir);
						return -1;
					}

					*parent_taxids_p = (int*) realloc(*parent_taxids_p, sizeof(int) * buffer_size);
					if (*parent_taxids_p == NULL)
					{
						obi_set_errno(OBI_MALLOC_ERROR);
						obidebug(1, "\nError reallocating memory for the parent taxids array");
						free(*parent_taxids_p);
						free(*rank_names_p);
						fclose(file);
						closedir(tax_dir);
						return -1;
					}

					*rank_names_p = (char**) realloc(*rank_names_p, sizeof(char*) * buffer_size);
					if (*rank_names_p == NULL)
					{
						obi_set_errno(OBI_MALLOC_ERROR);
						obidebug(1, "\nError reallocating memory for the rank names array");
						free(*parent_taxids_p);
						free(*rank_names_p);
						fclose(file);
						closedir(tax_dir);
						return -1;
					}
				}

				// Check for terminal '\n' character (line complete)
				if (line[strlen(line) - 1] != '\n')
				{
					obi_set_errno(OBI_TAXONOMY_ERROR);
					obidebug(1, "\nError: line buffer size not large enough for line in taxonomy file");
					free(*parent_taxids_p);
					free(*rank_names_p);
					fclose(file);
					closedir(tax_dir);
					return -1;
				}

				(tax->taxa)->taxon[n].idx = n;

				// Parse 3 first elements separated by '|'

				elt = strtok(line, "|");

				// Remove the last character (tab character)
				elt[strlen(elt)-1] = '\0';

				// First element: taxid
				(tax->taxa)->taxon[n].taxid = atoi(elt);

				// Update max taxid
				if ((tax->taxa)->taxon[n].taxid > (tax->taxa)->max_taxid)
					(tax->taxa)->max_taxid = (tax->taxa)->taxon[n].taxid;

				// Initialize farest taxid value
				(tax->taxa)->taxon[n].farest = -1;

				i = 1;
				while (i < 3)
				{
					elt = strtok(NULL, "|");

					// Remove the first and the last characters (tab characters)
					elt = elt+1;
					elt[strlen(elt)-1] = '\0';

					if (i == 1)
						(*parent_taxids_p)[n] = atoi(elt);
					else if (i == 2)
					{
						(*rank_names_p)[n] = (char*) malloc((strlen(elt)+1) * sizeof(char));
						if ((*rank_names_p)[n] == NULL)
						{
							obi_set_errno(OBI_MALLOC_ERROR);
							obidebug(1, "\nError allocating memory for taxon rank name");
							free(*parent_taxids_p);
							free(*rank_names_p);
							fclose(file);
							closedir(tax_dir);
							return -1;
						}
						strcpy((*rank_names_p)[n], elt);
					}
					i++;
				}
				n++;
			}

			// Check that fgets stopped because it reached EOF
			if (!feof(file))
			{
				obi_set_errno(OBI_TAXONOMY_ERROR);
				obidebug(1, "\nError: file reading was stopped before end of file");
				free(*parent_taxids_p);
				free(*rank_names_p);
				fclose(file);
				closedir(tax_dir);
				return -1;
			}

			// Store count
			(tax->taxa)->count = n;
			(tax->taxa)->ncbi_count = n;
			(tax->taxa)->local_count = 0;

			// Truncate the structure memory to the right size
			tax->taxa = (ecotxidx_t*) realloc(tax->taxa, sizeof(ecotxidx_t) + sizeof(ecotx_t) * (tax->taxa)->count);
			if (tax->taxa == NULL)
			{
				obi_set_errno(OBI_MALLOC_ERROR);
				obidebug(1, "\nError reallocating memory for taxonomy structure");
				free(*parent_taxids_p);
				free(*rank_names_p);
				fclose(file);
				closedir(tax_dir);
				return -1;
			}

			if (fclose(file) < 0)
			{
				obi_set_errno(OBI_TAXONOMY_ERROR);
				obidebug(1, "\nError closing a taxdump file");
				free(*parent_taxids_p);
				free(*rank_names_p);
				closedir(tax_dir);
				return -1;
			}
		}
	}
	if (closedir(tax_dir) < 0)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError closing a taxdump directory");
		free(*parent_taxids_p);
		free(*rank_names_p);
		closedir(tax_dir);
		return -1;
	}

	if ( ! file_found)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError: could not find 'nodes.dmp' file in taxdump directory");
		free(*parent_taxids_p);
		free(*rank_names_p);
		return -1;
	}

	return 0;
}


int read_delnodes_dmp(const char* taxdump, OBIDMS_taxonomy_p tax, int32_t** delnodes_p, int32_t* delnodes_count)
{
	struct dirent* 	dp;
	DIR*           	tax_dir;
	FILE*          	file;
	char*			file_name;
	bool           	file_found=false;
	char 			line[2048];			// TODO large enough?
	char*			elt;
	int				buffer_size;
	int			    n;
	int 		    old_taxid;

	buffer_size = 10000;

	// Initializing the list of deleted nodes
	*delnodes_p = (int32_t*) malloc(sizeof(int32_t) * buffer_size);
	if (*delnodes_p == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating the memory for the deleted taxids array");
		return -1;
	}

	tax_dir = opendir(taxdump);
	if (tax_dir == NULL)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nProblem opening a taxdump directory");
		closedir(tax_dir);
		free(*delnodes_p);
		return -1;
	}

	// Go through taxonomy files
	while ((dp = readdir(tax_dir)) != NULL)
	{
		if (strcmp(dp->d_name, "delnodes.dmp") == 0)
		{
			file_found = true;

			// Allocating the memory for the file name
			file_name =	(char*) malloc((strlen(taxdump) + 14)*sizeof(char));
			if (file_name == NULL)
			{
				obi_set_errno(OBI_MALLOC_ERROR);
				obidebug(1, "\nError allocating the memory for a file name");
				closedir(tax_dir);
				free(*delnodes_p);
				return -1;
			}

			// Build the file path
			if (sprintf(file_name, "%s/delnodes.dmp", taxdump) < 0)
			{
				obi_set_errno(OBI_TAXONOMY_ERROR);
				obidebug(1, "\nError building a taxonomy file name");
				closedir(tax_dir);
				free(*delnodes_p);
				free(file_name);
				return -1;
			}

			file = fopen(file_name, "r");
			if (file == NULL)
			{
				obi_set_errno(OBI_TAXONOMY_ERROR);
				obidebug(1, "\nProblem opening a taxonomy file");
				closedir(tax_dir);
				free(file_name);
				free(*delnodes_p);
				return -1;
			}

			free(file_name);

			n = 0;
			while (fgets(line, sizeof(line), file))
			{
				// Check for terminal '\n' character (line complete)
				if (line[strlen(line) - 1] != '\n')
				{
					obi_set_errno(OBI_TAXONOMY_ERROR);
					obidebug(1, "\nError: line buffer size not large enough for line in taxonomy file");
					fclose(file);
					closedir(tax_dir);
					free(*delnodes_p);
					return -1;
				}

				// Get first and only element of the line (the deprecated taxid)
				elt = strtok(line, "|");
				// Remove the last character (tab character)
				elt[strlen(elt)-1] = '\0';
				// First element: old deprecated taxid
				old_taxid = atoi(elt);

				// Store the old taxid in the list of deleted taxids
					// Enlarge array if needed
				if (n == buffer_size)
				{
					buffer_size = buffer_size * 2;
					(*delnodes_p) = (int32_t*) realloc(*delnodes_p, sizeof(int32_t) * buffer_size);
					if ((*delnodes_p) == NULL)
					{
						obi_set_errno(OBI_MALLOC_ERROR);
						obidebug(1, "\nError reallocating memory for a taxonomy structure");
						fclose(file);
						closedir(tax_dir);
						return -1;
					}
				}

				(*delnodes_p)[n] = old_taxid;
				n++;
			}

			// Check that fgets stopped because it reached EOF
			if (!feof(file))
			{
				obi_set_errno(OBI_TAXONOMY_ERROR);
				obidebug(1, "\nError: file reading was stopped before end of file");
				fclose(file);
				closedir(tax_dir);
				free(*delnodes_p);
				return -1;
			}

			// Store count
			*delnodes_count = n;

			if (fclose(file) < 0)
			{
				obi_set_errno(OBI_TAXONOMY_ERROR);
				obidebug(1, "\nError closing a taxdump file");
				free(*delnodes_p);
				closedir(tax_dir);
				return -1;
			}
		}
	}
	if (closedir(tax_dir) < 0)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError closing a taxdump directory");
		free(*delnodes_p);
		return -1;
	}

	if ( ! file_found)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError: could not find 'delnodes.dmp' file in taxdump directory");
		free(*delnodes_p);
		return -1;
	}

	return 0;
}


int read_merged_dmp(const char* taxdump, OBIDMS_taxonomy_p tax, int32_t* delnodes, int32_t delnodes_count)
{
	int				n, nD, nT;
	int				taxid, old_taxid;
	ecotx_t* 		t;
	struct dirent* 	dp;
	DIR*           	tax_dir;
	FILE*          	file;
	char*			file_name;
	bool            file_found=false;
	char 			line[2048];			// TODO large enough?
	char*			elt;
	int				buffer_size;

	buffer_size = 10000;

	tax_dir = opendir(taxdump);
	if (tax_dir == NULL)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nProblem opening a taxdump directory");
		return -1;
	}

	// Go through taxonomy files
	while ((dp = readdir(tax_dir)) != NULL)
	{
		if (strcmp(dp->d_name, "merged.dmp") == 0)
		{
			file_found = true;

			// Initializing the merged structure
			tax->merged_idx = (ecomergedidx_t*) malloc(sizeof(ecomergedidx_t) + sizeof(ecomerged_t) * buffer_size);
			if (tax->merged_idx == NULL)
			{
				obi_set_errno(OBI_MALLOC_ERROR);
				obidebug(1, "\nError allocating the memory for a taxonomy structure");
				closedir(tax_dir);
				return -1;
			}

			// Allocating the memory for the file name
			file_name =	(char*) malloc((strlen(taxdump) + 12)*sizeof(char));
			if (file_name == NULL)
			{
				obi_set_errno(OBI_MALLOC_ERROR);
				obidebug(1, "\nError allocating the memory for a file name");
				closedir(tax_dir);
				return -1;
			}

			// Build the file path
			if (sprintf(file_name, "%s/merged.dmp", taxdump) < 0)
			{
				obi_set_errno(OBI_TAXONOMY_ERROR);
				obidebug(1, "\nError building a taxonomy file name");
				closedir(tax_dir);
				free(file_name);
				return -1;
			}

			file = fopen(file_name, "r");
			if (file == NULL)
			{
				obi_set_errno(OBI_TAXONOMY_ERROR);
				obidebug(1, "\nProblem opening a taxonomy file");
				closedir(tax_dir);
				free(file_name);
				return -1;
			}

			free(file_name);

			nT = 0;					// to point in current taxa list while merging
			nD = delnodes_count-1;	// to point in deleted taxids list while merging (going from count-1 to 0 because taxids are sorted in descending order)
			n = 0;					// to point in final merged list while merging
			while (fgets(line, sizeof(line), file))
			{
				// Check for terminal '\n' character (line complete)
				if (line[strlen(line) - 1] != '\n')
				{
					obi_set_errno(OBI_TAXONOMY_ERROR);
					obidebug(1, "\nError: line buffer size not large enough for line in taxonomy file");
					closedir(tax_dir);
					fclose(file);
					return -1;
				}

				// Parse the 2 elements separated by '|'

				// Get first element
				elt = strtok(line, "|");
				// Remove the last character (tab character)
				elt[strlen(elt)-1] = '\0';
				// First element: old deprecated taxid
				old_taxid = atoi(elt);

				// Get 2nd element: new taxid
				elt = strtok(NULL, "|");
				// Remove the first and the last characters (tab characters)
				elt = elt+1;
				elt[strlen(elt)-1] = '\0';
				taxid = atoi(elt);

				// Store the old taxid in the merged_idx ordered taxid list
				// The merged list is an ordered list of the current taxids, the deprecated taxids that have current references,
				// and the deleted taxids with no current reference. An element of the list is composed of the taxid, and the index
				// of the taxon in the taxa structure, or -1 for deleted taxids.
				// Creating the merged list requires to merge the 3 ordered lists into one.
				while (((nT < (tax->taxa)->count) && ((tax->taxa)->taxon[nT].taxid < old_taxid)) || ((nD >= 0) && (delnodes[nD] < old_taxid)))
				{
					if ((tax->taxa)->taxon[nT].taxid < delnodes[nD])
					{ // Add element from taxa list
						// Enlarge structure if needed
						if (n == buffer_size)
						{
							buffer_size = buffer_size * 2;
							tax->merged_idx = (ecomergedidx_t*) realloc(tax->merged_idx, sizeof(ecomergedidx_t) + sizeof(ecomerged_t) * buffer_size);
							if (tax->merged_idx == NULL)
							{
								obi_set_errno(OBI_MALLOC_ERROR);
								obidebug(1, "\nError reallocating memory for a taxonomy structure");
								closedir(tax_dir);
								fclose(file);
								return -1;
							}
						}

						(tax->merged_idx)->merged[n].taxid = (tax->taxa)->taxon[nT].taxid;
						(tax->merged_idx)->merged[n].idx = nT;

						nT++;
						n++;
					}
					else if (delnodes[nD] < (tax->taxa)->taxon[nT].taxid)
					{ // Add element from deleted taxids list
						// Enlarge structure if needed
						if (n == buffer_size)
						{
							buffer_size = buffer_size * 2;
							tax->merged_idx = (ecomergedidx_t*) realloc(tax->merged_idx, sizeof(ecomergedidx_t) + sizeof(ecomerged_t) * buffer_size);
							if (tax->merged_idx == NULL)
							{
								obi_set_errno(OBI_MALLOC_ERROR);
								obidebug(1, "\nError reallocating memory for a taxonomy structure");
								closedir(tax_dir);
								fclose(file);
								return -1;
							}
						}

						(tax->merged_idx)->merged[n].taxid = delnodes[nD];
						(tax->merged_idx)->merged[n].idx = -1;	// The index to tag deleted taxids is -1

						nD--;
						n++;
					}
				}

				// Add the deprecated taxid
				// Enlarge structure if needed
				if (n == buffer_size)
				{
					buffer_size = buffer_size * 2;
					tax->merged_idx = (ecomergedidx_t*) realloc(tax->merged_idx, sizeof(ecomergedidx_t) + sizeof(ecomerged_t) * buffer_size);
					if (tax->merged_idx == NULL)
					{
						obi_set_errno(OBI_MALLOC_ERROR);
						obidebug(1, "\nError reallocating memory for a taxonomy structure");
						closedir(tax_dir);
						fclose(file);
						return -1;
					}
				}

					// Store the deprecated taxid with the index that refers to the new taxid
						// Find the index of the new taxid
				t = get_taxon_with_current_taxid(tax, taxid);
						// Store the old taxid with the index
				(tax->merged_idx)->merged[n].taxid = old_taxid;
				(tax->merged_idx)->merged[n].idx = t->idx;

				n++;
			}

			// Check that fgets stopped because it reached EOF
			if (!feof(file))
			{
				obi_set_errno(OBI_TAXONOMY_ERROR);
				obidebug(1, "\nError: file reading was stopped before end of file");
				closedir(tax_dir);
				fclose(file);
				return -1;
			}

			// Store count
			(tax->merged_idx)->count = n;

			// Truncate the structure memory to the right size
			tax->merged_idx = (ecomergedidx_t*) realloc(tax->merged_idx, sizeof(ecomergedidx_t) + sizeof(ecomerged_t) * (tax->merged_idx)->count);
			if (tax->merged_idx == NULL)
			{
				obi_set_errno(OBI_MALLOC_ERROR);
				obidebug(1, "\nError reallocating memory for a a taxonomy structure");
				closedir(tax_dir);
				fclose(file);
				return -1;
			}

			if (fclose(file) < 0)
			{
				obi_set_errno(OBI_TAXONOMY_ERROR);
				obidebug(1, "\nError closing a taxdump file");
				closedir(tax_dir);
				return -1;
			}
		}
	}
	if (closedir(tax_dir) < 0)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError closing a taxdump directory");
		closedir(tax_dir);
		return -1;
	}

	if ( ! file_found)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError: could not find 'merged.dmp' file in taxdump directory");
		return -1;
	}

	// Free delnodes array, not needed anymore
	free(delnodes);

	return 0;
}


int read_names_dmp(const char* taxdump, OBIDMS_taxonomy_p tax)
{
	int				i, j, n;
	int				taxid;
	struct dirent* 	dp;
	DIR*           	tax_dir;
	FILE*          	file;
	char*			file_name;
	bool            file_found=false;
	char 			line[2048];			// TODO large enough?
	char*			elt;
	int				buffer_size;

	buffer_size = 10000;

	tax_dir = opendir(taxdump);
	if (tax_dir == NULL)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nProblem opening a taxdump directory");
		return -1;
	}

	// Go through taxonomy files
	while ((dp = readdir(tax_dir)) != NULL)
	{
		if (strcmp(dp->d_name, "names.dmp") == 0)
		{
			file_found = true;

			// Initializing the names structure
			tax->names = (econameidx_t*) malloc(sizeof(econameidx_t) + sizeof(econame_t) * buffer_size);
			if (tax->names == NULL)
			{
				obi_set_errno(OBI_MALLOC_ERROR);
				obidebug(1, "\nError allocating the memory for a taxonomy structure");
				closedir(tax_dir);
				return -1;
			}

			// Allocating the memory for the file name
			file_name =	(char*) malloc((strlen(taxdump) + 11)*sizeof(char));
			if (file_name == NULL)
			{
				obi_set_errno(OBI_MALLOC_ERROR);
				obidebug(1, "\nError allocating the memory for a file name");
				closedir(tax_dir);
				return -1;
			}

			// Build the file path
			if (sprintf(file_name, "%s/names.dmp", taxdump) < 0)
			{
				obi_set_errno(OBI_TAXONOMY_ERROR);
				obidebug(1, "\nError building a taxonomy file name");
				free(file_name);
				closedir(tax_dir);
				return -1;
			}

			file = fopen(file_name, "r");
			if (file == NULL)
			{
				obi_set_errno(OBI_TAXONOMY_ERROR);
				obidebug(1, "\nProblem opening a taxonomy file");
				free(file_name);
				closedir(tax_dir);
				return -1;
			}

			free(file_name);

			n = 0;
			j = 0;
			while (fgets(line, sizeof(line), file))
			{
				// Enlarge structures if needed
				if (n == buffer_size)
				{
					buffer_size = buffer_size * 2;
					tax->names = (econameidx_t*) realloc(tax->names, sizeof(econameidx_t) + sizeof(econame_t) * buffer_size);
					if (tax->names == NULL)
					{
						obi_set_errno(OBI_MALLOC_ERROR);
						obidebug(1, "\nError reallocating memory for a taxonomy structure");
						fclose(file);
						closedir(tax_dir);
						return -1;
					}
				}

				// Check for terminal '\n' character (line complete)
				if (line[strlen(line) - 1] != '\n')
				{
					obi_set_errno(OBI_TAXONOMY_ERROR);
					obidebug(1, "\nError: line buffer size not large enough for line in taxonomy file");
					fclose(file);
					closedir(tax_dir);
					return -1;
				}

				// Parse 4 first elements separated by '|'

				elt = strtok(line, "|");

				// Remove the last character (tab character)
				elt[strlen(elt)-1] = '\0';

				// First element: taxid
				taxid = atoi(elt);
				// Find taxid in taxa structure and store pointer in names structure
				i = j;
				while ((i < (tax->taxa)->count) && ((tax->taxa)->taxon[i].taxid != taxid))
					i++;
				if (i == (tax->taxa)->count)
				{
					obi_set_errno(OBI_TAXONOMY_ERROR);
					obidebug(1, "\nError: could not find taxon associated to name when reading taxdump");
					fclose(file);
					closedir(tax_dir);
					return -1;
				}
				j = i;	// Because there are several names by taxon but they are in the same order
				(tax->names)->names[n].taxon = ((tax->taxa)->taxon)+i;

				i = 1;
				while (i < 4)
				{
					elt = strtok(NULL, "|");

					// Remove the first and the last characters (tab characters)
					elt = elt+1;
					elt[strlen(elt)-1] = '\0';

					if (i == 1)		// Name
					{
						(tax->names)->names[n].name = (char*) malloc((strlen(elt) + 1) * sizeof(char));
						if ((tax->names)->names[n].name == NULL)
						{
							obi_set_errno(OBI_MALLOC_ERROR);
							obidebug(1, "\nError allocating memory for a taxon name");
							obi_close_taxonomy(tax);
							fclose(file);
							closedir(tax_dir);
							return -1;
						}
						strcpy((tax->names)->names[n].name, elt);
					}
					else if (i == 3)	// Class name
					{
						(tax->names)->names[n].class_name = (char*) malloc((strlen(elt) + 1) * sizeof(char));
						if ((tax->names)->names[n].class_name == NULL)
						{
							obi_set_errno(OBI_MALLOC_ERROR);
							obidebug(1, "\nError allocating memory for a taxon class name");
							fclose(file);
							closedir(tax_dir);
							return -1;
						}
						strcpy((tax->names)->names[n].class_name, elt);
						if (strcmp(elt, "scientific name") == 0)
						{
							(tax->names)->names[n].is_scientific_name = 1;
						}
						else
							(tax->names)->names[n].is_scientific_name = 0;
					}
					i++;
				}
				n++;
			}

			// Check that fgets stopped because it reached EOF
			if (!feof(file))
			{
				obi_set_errno(OBI_TAXONOMY_ERROR);
				obidebug(1, "\nError: file reading was stopped before end of file");
				fclose(file);
				closedir(tax_dir);
				return -1;
			}

			// Store count
			(tax->names)->count = n;

			// Truncate the structure memory to the right size
			tax->names = (econameidx_t*) realloc(tax->names, sizeof(econameidx_t) + sizeof(econame_t) * (tax->names)->count);
			if (tax->names == NULL)
			{
				obi_set_errno(OBI_MALLOC_ERROR);
				obidebug(1, "\nError reallocating memory for a a taxonomy structure");
				fclose(file);
				closedir(tax_dir);
				return -1;
			}

			if (fclose(file) < 0)
			{
				obi_set_errno(OBI_TAXONOMY_ERROR);
				obidebug(1, "\nError closing a taxdump file");
				closedir(tax_dir);
				return -1;
			}
		}
	}
	if (closedir(tax_dir) < 0)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError closing a taxdump directory");
		closedir(tax_dir);
		return -1;
	}

	if ( ! file_found)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError: could not find 'merged.dmp' file in taxdump directory");
		return -1;
	}

	return 0;
}


/**********************************************************************
 *
 * D E F I N I T I O N   O F   T H E   P U B L I C   F U N C T I O N S
 *
 **********************************************************************/


int obi_taxonomy_exists(OBIDMS_p dms, const char* taxonomy_name)
{
	char* taxonomy_path;
	DIR* dir;

	taxonomy_path = get_taxonomy_path(dms, taxonomy_name);
	if (taxonomy_path == NULL)
		return -1;

	dir = opendir(taxonomy_path);
	if (dir)
	{
	    /* Directory exists. */
	    closedir(dir);
	    return 1;
	}
	else if (ENOENT == errno)
	{
	    /* Directory does not exist. */
		return 0;
	}
	else
	{
	    /* opendir() failed for some other reason. */
		return -1;
	}
}


OBIDMS_taxonomy_p obi_read_taxdump(const char* taxdump)
{
	OBIDMS_taxonomy_p tax;
	char**		      rank_names=NULL;
	int*		      parent_taxids=NULL;
	int32_t*          delnodes=NULL;
	int32_t           delnodes_count;
	bool			  already_in;
	ecotx_t* 		  t;
	int				  buffer_size;
	int			      i, j;

	// Initialize taxonomy structure
	tax = (OBIDMS_taxonomy_p) malloc(sizeof(OBIDMS_taxonomy_t));
	if (tax == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating the memory for a taxonomy structure");
		return NULL;
	}
	tax->ranks      	 = NULL;
	tax->taxa       	 = NULL;
	tax->names      	 = NULL;
	tax->preferred_names = NULL;
	tax->merged_idx 	 = NULL;

	tax->dms = NULL;
	(tax->tax_name)[0] = '\0';

	// TODO check if taxdump path is for a gz file to unzip or a directory

	// READ NODES.DMP
	if (read_nodes_dmp(taxdump, tax, &rank_names, &parent_taxids) < 0)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nProblem reading 'nodes.dmp'");
		obi_close_taxonomy(tax);
		return NULL;
	}

	// READ DELNODES.DMP
	if (read_delnodes_dmp(taxdump, tax, &delnodes, &delnodes_count) < 0)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nProblem reading 'delnodes.dmp'");
		obi_close_taxonomy(tax);
		free(rank_names);
		free(parent_taxids);
		return NULL;
	}

	// READ MERGED.DMP
	if (read_merged_dmp(taxdump, tax, delnodes, delnodes_count) < 0)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nProblem reading 'merged.dmp'");
		obi_close_taxonomy(tax);
		free(delnodes);
		free(rank_names);
		free(parent_taxids);
		return NULL;
	}

	// READ NAMES.DMP
	if (read_names_dmp(taxdump, tax) < 0)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nProblem reading 'names.dmp'");
		obi_close_taxonomy(tax);
		free(rank_names);
		free(parent_taxids);
		return NULL;
	}

	// Go through data to fill the taxonomy structure

	// Build rank list

	// Initialize rank structure
	buffer_size = 10;
	tax->ranks = (ecorankidx_t*) malloc(sizeof(ecorankidx_t) + sizeof(char*) * buffer_size);
	if (tax->ranks == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating memory for taxon rank array");
		obi_close_taxonomy(tax);
		free(parent_taxids);
		free(rank_names);
		return NULL;
	}
	(tax->ranks)->count = 0;
	for (i=0; i < (tax->taxa)->count; i++)
	{
		already_in = false;
		for (j=0; j < (tax->ranks)->count; j++)
		{
			if (strcmp(rank_names[i], ((tax->ranks)->label)[j]) == 0)
			{
				already_in = true;
				break;
			}
		}
		if (!already_in)
		{
			// Realloc rank structure if needed
			if ((tax->ranks)->count == buffer_size)
			{
				buffer_size = buffer_size + 10;
				tax->ranks = (ecorankidx_t*) realloc(tax->ranks, sizeof(ecorankidx_t) + sizeof(char*) * buffer_size);
				if (tax->ranks == NULL)
				{
					obi_set_errno(OBI_MALLOC_ERROR);
					obidebug(1, "\nError reallocating memory for taxon ranks");
					obi_close_taxonomy(tax);
					free(parent_taxids);
					free(rank_names);
					return NULL;
				}
			}

			// Store new rank
			((tax->ranks)->label)[(tax->ranks)->count] = (char*) malloc((strlen(rank_names[i]) + 1) * sizeof(char));
			if (((tax->ranks)->label)[(tax->ranks)->count] == NULL)
			{
				obi_set_errno(OBI_MALLOC_ERROR);
				obidebug(1, "\nError allocating memory for taxon rank names");
				obi_close_taxonomy(tax);
				free(parent_taxids);
				free(rank_names);
				return NULL;
			}
			strcpy(((tax->ranks)->label)[(tax->ranks)->count], rank_names[i]);
			((tax->ranks)->count)++;
		}
	}

	// Truncate to the number of ranks recorded
	tax->ranks = (ecorankidx_t*) realloc(tax->ranks, sizeof(ecorankidx_t) + sizeof(char*) * (tax->ranks)->count);
	if (tax->ranks == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError reallocating memory for taxon ranks");
		obi_close_taxonomy(tax);
		free(parent_taxids);
		free(rank_names);
		return NULL;
	}

	// Sort in alphabetical order
	qsort((tax->ranks)->label, (tax->ranks)->count, sizeof(char*), cmp_str);

	// Associate the taxa with their rank indices
	for (i=0; i < (tax->taxa)->count; i++)
	{
		for (j=0; j < (tax->ranks)->count; j++)
		{
			if (strcmp(rank_names[i], ((tax->ranks)->label)[j]) == 0)
			{
				((tax->taxa)->taxon)[i].rank = j;
				break;
			}
		}
	}

	// Associate the taxa with their scientific name
	for (i=0; i < (tax->names)->count; i++)
	{
		if ((tax->names)->names[i].is_scientific_name)
		{
			((tax->names)->names[i].taxon)->name = (char*) malloc((strlen((((tax->names)->names)[i]).name) + 1) * sizeof(char));
			if (((tax->names)->names[i].taxon)->name == NULL)
			{
				obi_set_errno(OBI_MALLOC_ERROR);
				obidebug(1, "\nError reallocating memory for taxon ranks");
				obi_close_taxonomy(tax);
				free(parent_taxids);
				free(rank_names);
				return NULL;
			}
			strcpy(((tax->names)->names[i].taxon)->name, (((tax->names)->names)[i]).name);
		}
	}

	// Sort names in alphabetical order
	qsort((tax->names)->names, (tax->names)->count, sizeof(econame_t), cmp_names);

	// Associate the taxa with their parent
	for (i=0; i < (tax->taxa)->count; i++)
	{
		((tax->taxa)->taxon)[i].parent = get_taxon_with_current_taxid(tax, parent_taxids[i]);
		if (((tax->taxa)->taxon)[i].parent == NULL)
		{
			obi_set_errno(OBI_TAXONOMY_ERROR);
			obidebug(1, "\nError: taxon parent not found");
			obi_close_taxonomy(tax);
			free(parent_taxids);
			free(rank_names);
			return NULL;
		}
		(((tax->taxa)->taxon)[i].parent)->farest = 0;
	}

	// Initialize preferred names to NULL
	for (i=0; i < (tax->taxa)->count; i++)
		((tax->taxa)->taxon)[i].preferred_name = NULL;

	(tax->taxa)->buffer_size = (tax->taxa)->count;

	// Compute longest branches (used to compute distances between taxa faster)
	for (i=0; i < (tax->taxa)->count; i++)
	{
		t = (((tax->taxa))->taxon)+i;
		if (t->farest == -1)
		{
			t->farest=0;
            while (t->parent != t)
            {
            	j = t->farest + 1;
            	if (j > t->parent->farest)
            	{
            		t->parent->farest = j;
            		t=t->parent;
            	}
            	else
            		t = (tax->taxa)->taxon;
            }
		}
	}

	// Freeing
	free(parent_taxids);
	for (i=0; i < (tax->taxa)->count; i++)
		free(rank_names[i]);
	free(rank_names);

	return tax;
}


OBIDMS_taxonomy_p obi_read_taxonomy(OBIDMS_p dms, const char* taxonomy_name, bool read_alternative_names)
{
	OBIDMS_taxonomy_p  tax;
	char*			   taxonomy_path;
	char*  			   ranks_file_name;
	char*              taxa_file_name;
	char*              merged_idx_file_name;
	char*			   local_taxa_file_name;
	char*			   alter_names_file_name;
	char*			   pref_names_file_name;
	int                buffer_size;

	tax = (OBIDMS_taxonomy_p) malloc(sizeof(OBIDMS_taxonomy_t));
	if (tax == NULL)
	{
 		obi_set_errno(OBI_MALLOC_ERROR);
 		obidebug(1, "\nError allocating memory for a taxonomy structure");
 		return NULL;
	}

	tax->ranks           = NULL;
	tax->taxa            = NULL;
	tax->names           = NULL;
	tax->preferred_names = NULL;
	tax->merged_idx      = NULL;

	tax->dms = dms;

	strcpy(tax->tax_name, taxonomy_name);

	buffer_size = 2048;

	taxonomy_path = get_taxonomy_path(dms, taxonomy_name);
	if (taxonomy_path == NULL)
		return NULL;

	// Read ranks
	ranks_file_name = (char*) malloc(buffer_size*sizeof(char));
	if (ranks_file_name == NULL)
	{
 		obi_set_errno(OBI_MALLOC_ERROR);
 		obidebug(1, "\nError allocating memory for ranks file name");
		free(taxonomy_path);
		free(tax);
		return NULL;
	}
	if (snprintf(ranks_file_name, buffer_size, "%s/%s.rdx", taxonomy_path, taxonomy_name) < 0)
	{
 		obi_set_errno(OBI_TAXONOMY_ERROR);
 		obidebug(1, "\nError building ranks file name");
		free(taxonomy_path);
		free(ranks_file_name);
		free(tax);
		return NULL;
	}
	tax->ranks = read_ranks_idx(ranks_file_name);
	if (tax->ranks == NULL)
	{
 		obi_set_errno(OBI_TAXONOMY_ERROR);
 		obidebug(1, "\nError reading taxonomy ranks file (check taxonomy name spelling)");
		free(taxonomy_path);
		free(ranks_file_name);
		free(tax);
		return NULL;
	}
	free(ranks_file_name);

	// Read taxa
	taxa_file_name = (char*) malloc(buffer_size*sizeof(char));
	if (taxa_file_name == NULL)
	{
 		obi_set_errno(OBI_MALLOC_ERROR);
 		obidebug(1, "\nError allocating memory for taxa file name");
		free(taxonomy_path);
		obi_close_taxonomy(tax);
		return NULL;
	}
	if (snprintf(taxa_file_name, buffer_size, "%s/%s.tdx", taxonomy_path, taxonomy_name) < 0)
	{
 		obi_set_errno(OBI_TAXONOMY_ERROR);
 		obidebug(1, "\nError building taxa file name");
		free(taxonomy_path);
		free(taxa_file_name);
		obi_close_taxonomy(tax);
		return NULL;
	}
	local_taxa_file_name = (char*) malloc(buffer_size*sizeof(char));
	if (local_taxa_file_name == NULL)
	{
 		obi_set_errno(OBI_MALLOC_ERROR);
 		obidebug(1, "\nError allocating memory for taxa file name");
		free(taxonomy_path);
		free(taxa_file_name);
		obi_close_taxonomy(tax);
		return NULL;
	}
	if (snprintf(local_taxa_file_name, buffer_size, "%s/%s.ldx", taxonomy_path, taxonomy_name) < 0)
	{
 		obi_set_errno(OBI_TAXONOMY_ERROR);
 		obidebug(1, "\nError building local taxa file name");
		free(taxonomy_path);
		free(taxa_file_name);
		free(local_taxa_file_name);
		obi_close_taxonomy(tax);
		return NULL;
	}
	tax->taxa = read_taxonomy_idx(taxa_file_name, local_taxa_file_name);
	if (tax->taxa == NULL)
	{
		free(taxonomy_path);
		free(taxa_file_name);
		free(local_taxa_file_name);
		obi_close_taxonomy(tax);
		return NULL;
	}
	free(taxa_file_name);
	free(local_taxa_file_name);

	// Read merged index (old and current taxids referring to indices in the taxa structure)
	merged_idx_file_name = (char*) malloc(buffer_size*sizeof(char));
	if (merged_idx_file_name == NULL)
	{
 		obi_set_errno(OBI_MALLOC_ERROR);
 		obidebug(1, "\nError allocating memory for merged index file name");
		free(taxonomy_path);
		obi_close_taxonomy(tax);
		return NULL;
	}
	if (snprintf(merged_idx_file_name, buffer_size, "%s/%s.adx", taxonomy_path, taxonomy_name) < 0)
	{
 		obi_set_errno(OBI_TAXONOMY_ERROR);
 		obidebug(1, "\nError building merged index file name");
		free(taxonomy_path);
		free(merged_idx_file_name);
		obi_close_taxonomy(tax);
		return NULL;
	}
    tax->merged_idx = read_merged_idx(merged_idx_file_name, tax);
	if (tax->merged_idx == NULL)
	{
		free(taxonomy_path);
		free(merged_idx_file_name);
		obi_close_taxonomy(tax);
		return NULL;
	}
    free(merged_idx_file_name);

	// Read preferred names
	pref_names_file_name = (char*) malloc(buffer_size*sizeof(char));
	if (pref_names_file_name == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating memory for alternative names file name");
		free(taxonomy_path);
		obi_close_taxonomy(tax);
		return NULL;
	}
	if (snprintf(pref_names_file_name, buffer_size, "%s/%s.pdx", taxonomy_path, taxonomy_name) < 0)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError building alternative names file name");
		free(taxonomy_path);
		free(pref_names_file_name);
		obi_close_taxonomy(tax);
		return NULL;
	}
	tax->preferred_names = read_preferred_names_idx(pref_names_file_name, tax);
	if (obi_errno)
	{
		free(taxonomy_path);
		free(pref_names_file_name);
		obi_close_taxonomy(tax);
		return NULL;
	}
	free(pref_names_file_name);

	if (tax->preferred_names != NULL)
		fprintf(stderr, "\nPreferred names read");

	// Read alternative names
	if (read_alternative_names)
	{
		alter_names_file_name = (char*) malloc(buffer_size*sizeof(char));
		if (alter_names_file_name == NULL)
		{
	 		obi_set_errno(OBI_MALLOC_ERROR);
	 		obidebug(1, "\nError allocating memory for alternative names file name");
			free(taxonomy_path);
			obi_close_taxonomy(tax);
			return NULL;
		}
		if (snprintf(alter_names_file_name, buffer_size, "%s/%s.ndx", taxonomy_path, taxonomy_name) < 0)
		{
	 		obi_set_errno(OBI_TAXONOMY_ERROR);
	 		obidebug(1, "\nError building alternative names file name");
			free(taxonomy_path);
			free(alter_names_file_name);
			obi_close_taxonomy(tax);
			return NULL;
		}
        tax->names = read_names_idx(alter_names_file_name, tax);
    	if (tax->names == NULL)
    	{
			free(taxonomy_path);
			free(alter_names_file_name);
			obi_close_taxonomy(tax);
			return NULL;
    	}
        free(alter_names_file_name);
	}

	free(taxonomy_path);

	return tax;
}


int obi_write_taxonomy(OBIDMS_p dms, OBIDMS_taxonomy_p tax, const char* tax_name)
{
	char* taxonomy_path;

	// Build the taxonomy directory path
	taxonomy_path = get_taxonomy_path(dms, tax_name);
	if (taxonomy_path == NULL)
		return -1;

	// Try to create the directory
	if (mkdir(taxonomy_path, 00777) < 0)
	{
		if (errno == EEXIST)
			obidebug(1, "\nA taxonomy already exists with this name.");
		obidebug(1, "\nProblem creating a new taxonomy directory");
		free(taxonomy_path);
		return -1;
	}

	free(taxonomy_path);

    if (write_ranks_idx(dms, tax, tax_name) < 0)
        return -1;
    if (write_taxonomy_idx(dms, tax, tax_name) < 0)
        return -1;
    if (write_names_idx(dms, tax, tax_name) < 0)
    	return -1;
    if (write_merged_idx(dms, tax, tax_name) < 0)
    	return -1;
    // Check if there are local taxa (if so last taxon is local)
    if ((tax->taxa)->local_count > 0)
    {
    	if (write_local_taxonomy_idx(dms, tax, tax_name) < 0)
    		return -1;
    }
    // Write preferred names if there are some
    if (tax->preferred_names != NULL)
    {
    	if (write_preferred_names_idx(dms, tax, tax_name) < 0)
    		return -1;
    }
	return 0;
}


int obi_close_taxonomy(OBIDMS_taxonomy_p taxonomy)
{
	int i;

	if (taxonomy)
	{
		// Update local informations (local taxa and preferred names) if there are any
		if ((taxonomy->taxa)->local_count > 0)
		{
			if (taxonomy->dms == NULL)
			{
				obi_set_errno(OBI_TAXONOMY_ERROR);
				obidebug(1, "\nError closing a taxonomy with local files but no DMS associated (probably read directly from taxdump)");		// TODO discuss
			}
			if (write_local_taxonomy_idx(taxonomy->dms, taxonomy, taxonomy->tax_name) < 0)
				return -1;
		}

		// Write preferred names if there are some
		if (taxonomy->preferred_names)
		{
			if (write_preferred_names_idx(taxonomy->dms, taxonomy, taxonomy->tax_name) < 0)
				return -1;

			// Free preferred names
			for (i=0; i < (taxonomy->preferred_names)->count; i++)
			{
				if (((taxonomy->preferred_names)->names[i]).name)
					free(((taxonomy->preferred_names)->names[i]).name);
				if (((taxonomy->preferred_names)->names[i]).class_name)
					free(((taxonomy->preferred_names)->names[i]).class_name);
			}
			free(taxonomy->preferred_names);
		}

		if (taxonomy->ranks)
		{
			for (i=0; i < (taxonomy->ranks)->count; i++)
			{
				if ((taxonomy->ranks)->label[i])
					free((taxonomy->ranks)->label[i]);
			}
			free(taxonomy->ranks);
		}

		if (taxonomy->names)
		{
			for (i=0; i < (taxonomy->names)->count; i++)
			{
				if (((taxonomy->names)->names[i]).name)
					free(((taxonomy->names)->names[i]).name);
				if (((taxonomy->names)->names[i]).class_name)
					free(((taxonomy->names)->names[i]).class_name);
			}
			free(taxonomy->names);
		}

		if (taxonomy->taxa)
		{
			for (i=0; i < (taxonomy->taxa)->count; i++)
			{
				if (((taxonomy->taxa)->taxon[i]).name)
					free(((taxonomy->taxa)->taxon[i]).name);
			}
			free(taxonomy->taxa);
		}

		if (taxonomy->merged_idx)
		{
			free(taxonomy->merged_idx);
		}

		free(taxonomy);
	}

	return 0;
}


int obi_taxo_add_local_taxon(OBIDMS_taxonomy_p tax, const char* name, const char* rank_name, int32_t parent_taxid, int32_t min_taxid)
{
	int32_t    taxid;
	ecotx_t*   taxon;
	int        i;
//	econame_t* name_struct;

	// Enlarge the structure memory for a new taxon
	tax->taxa = (ecotxidx_t*) realloc(tax->taxa, sizeof(ecotxidx_t) + sizeof(ecotx_t) * (((tax->taxa)->count) + 1));
	if (tax->taxa == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError reallocating memory for a taxonomy structure to add a new taxon");
		return -1;
	}

	// Compute new taxid that must be equal or greater than 1E7 and greater than the maximum taxid existing in the taxonomy
	if (min_taxid < MIN_LOCAL_TAXID)
		min_taxid = MIN_LOCAL_TAXID;
	if (min_taxid > (tax->taxa)->max_taxid)
		taxid = min_taxid;
	else
		taxid = ((tax->taxa)->max_taxid) + 1;

	// Fill the ecotx_t node structure
	taxon = ((tax->taxa)->taxon)+((tax->taxa)->count);
	taxon->taxid = taxid;
	taxon->idx = (tax->taxa)->count;
	taxon->local = true;
	taxon->name = (char*) malloc((strlen(name) + 1) * sizeof(char));
	if (taxon->name == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating memory for a taxon name to add a new taxon");
		return -1;
	}
	strcpy(taxon->name, name);
	taxon->rank = -1;
	for (i=0; i < (tax->ranks)->count; i++)
	{
		if (strcmp(rank_name, ((tax->ranks)->label)[i]) == 0)
		{
			taxon->rank = i;
			break;
		}
	}
	if (taxon->rank == -1)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError: taxon rank not found when adding a new taxon");
		return -1;
	}
	taxon->parent = obi_taxo_get_taxon_with_taxid(tax, parent_taxid);
	if (taxon->parent == NULL)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError: taxon parent not found when adding a new taxon");
		return -1;
	}
	taxon->farest = 0;

	// Update taxonomy counts etc
	(tax->taxa)->max_taxid = taxid;
	((tax->taxa)->count)++;
	((tax->taxa)->local_count)++;
	(tax->taxa)->buffer_size = (tax->taxa)->count;

//	// Add new name in names structure     // Commented because the new name was not added in the .ndx file in the OBITools1
//	// Allocate memory for new name
//	tax->names = (econameidx_t*) realloc(tax->names, sizeof(econameidx_t) + sizeof(econame_t) * ((tax->names)->count + 1));
//	if (tax->names == NULL)
//	{
//		obi_set_errno(OBI_MALLOC_ERROR);
//		obidebug(1, "\nError reallocating memory for a taxonomy structure to add a new taxon");
//		return -1;
//	}
//
//	// Add new name
//	name_struct = (tax->names)->names + ((tax->names)->count);
//	name_struct->name = (char*) malloc((strlen(name) + 1) * sizeof(char));
//	if (name_struct->name == NULL)
//	{
//		obi_set_errno(OBI_MALLOC_ERROR);
//		obidebug(1, "\nError allocating memory for a taxon name to add a new taxon");
//		return -1;
//	}
//	strcpy(name_struct->name, name);
//	name_struct->class_name = (char*) malloc((strlen("scientific name") + 1) * sizeof(char));
//	if (name_struct->class_name == NULL)
//	{
//		obi_set_errno(OBI_MALLOC_ERROR);
//		obidebug(1, "\nError allocating memory for a taxon class name to add a new taxon");
//		return -1;
//	}
//	strcpy(name_struct->class_name, "scientific name");
//	name_struct->is_scientific_name = true;
//	name_struct->taxon = ((tax->taxa)->taxon) + ((tax->taxa)->count) - 1;
//
//	// Sort names in alphabetical order
//	qsort((tax->names)->names, (tax->names)->count, sizeof(econame_t), cmp_names);
//
//	// Update name count
//	((tax->names)->count)++;

	return taxid;
}


int obi_taxo_add_preferred_name_with_taxid(OBIDMS_taxonomy_p tax, int32_t taxid, const char* preferred_name)
{
	ecotx_t* taxon;

	taxon = obi_taxo_get_taxon_with_taxid(tax, taxid);

	return obi_taxo_add_preferred_name_with_taxon(tax, taxon, preferred_name);
}


int obi_taxo_add_preferred_name_with_taxon(OBIDMS_taxonomy_p tax, ecotx_t* taxon, const char* preferred_name)
{
	econame_t* name_struct;

	// Free previous preferred name if there is one
	if (taxon->preferred_name != NULL)
		free(taxon->preferred_name);

	taxon->preferred_name = (char*) malloc((strlen(preferred_name) + 1) * sizeof(char));
	if (taxon->preferred_name == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating memory for a new preferred name for a taxon");
		return -1;
	}
	strcpy(taxon->preferred_name, preferred_name);

	// Add new name in preferred names structure
	// Allocate or reallocate memory for new name
	if (tax->preferred_names == NULL)
	{
		tax->preferred_names = (econameidx_t*) malloc(sizeof(econameidx_t) + sizeof(econame_t));
		(tax->preferred_names)->count = 0;
	}
	else
		tax->preferred_names = (econameidx_t*) realloc(tax->preferred_names, sizeof(econameidx_t) + sizeof(econame_t) * ((tax->preferred_names)->count + 1));
	if (tax->preferred_names == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError reallocating memory for a taxonomy structure to add a new preferred name");
		return -1;
	}

	// Add new preferred name
	name_struct = (tax->preferred_names)->names + ((tax->preferred_names)->count);
	name_struct->name = (char*) malloc((strlen(preferred_name) + 1) * sizeof(char));
	if (name_struct->name == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating memory for a new taxon preferred name");
		return -1;
	}
	strcpy(name_struct->name, preferred_name);

	name_struct->class_name = (char*) malloc((strlen("preferred name") + 1) * sizeof(char));
	if (name_struct->class_name == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating memory for a taxon class name to add a new preferred name");
		return -1;
	}
	strcpy(name_struct->class_name, "preferred name");
	name_struct->is_scientific_name = false;
	name_struct->taxon = taxon;

	// Sort preferred names in alphabetical order
	qsort((tax->preferred_names)->names, (tax->preferred_names)->count, sizeof(econame_t), cmp_names);

	// Update preferred name count
	((tax->preferred_names)->count)++;

	return 0;
}


ecotx_t* obi_taxo_get_lca(ecotx_t* taxon1, ecotx_t* taxon2)  // TODO could be more efficient maybe
{
	ecotx_t* current_taxon;
	ecotx_t* next_taxon;
	ecotx_t* lca;
	ecotx_t* path1[1000];
	ecotx_t* path2[1000];
	int      i,j;

	if ((taxon1 == NULL) || (taxon2 == NULL))
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError getting the LCA of two taxons: at least one of the taxon pointers is NULL");
		return NULL;
	}

	// Get path of first taxon   // TODO function to get path?
	current_taxon = taxon1;
	next_taxon    = current_taxon->parent;
	path1[0]      = current_taxon;
	i=0;
	while (current_taxon->taxid != 1)  // root node
	{
		current_taxon = next_taxon;
		next_taxon    = current_taxon->parent;
		i++;
		path1[i] = current_taxon;
	}
	i--;

	// Get path of second taxon   // TODO function to get path?
	current_taxon = taxon2;
	next_taxon    = current_taxon->parent;
	path2[0]      = current_taxon;
	j=0;
	while (current_taxon->taxid != 1)  // root node
	{
		current_taxon = next_taxon;
		next_taxon    = current_taxon->parent;
		j++;
		path2[j] = current_taxon;
	}
	j--;

	while ((i>=0) && (j>=0) && (path1[i] == path2[j]))
	{
		i--;
		j--;
	}
	i++;

	lca = path1[i];

	return lca;
}


ecotx_t* obi_taxo_get_parent_at_rank(ecotx_t* taxon, int32_t rankidx)
{
	ecotx_t* current_taxon;
	ecotx_t* next_taxon;

	if (taxon == NULL)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError getting the parent of a taxon at a given rank: taxon pointer is NULL");
		return NULL;
	}

	current_taxon = taxon;
	next_taxon    = current_taxon->parent;

	while ((current_taxon != next_taxon) &&  // root node
		   (current_taxon->rank != rankidx))
	{
		current_taxon = next_taxon;
		next_taxon    = current_taxon->parent;
	}

	if (current_taxon->rank == rankidx)
		return current_taxon;
	else
		return NULL;
}


ecotx_t* obi_taxo_get_taxon_with_taxid(OBIDMS_taxonomy_p taxonomy, int32_t taxid)
{
	ecotx_t     *current_taxon;
	ecomerged_t *indexed_taxon;
	int32_t      count;

	if (taxonomy == NULL)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError trying to get a taxon with its taxid: taxonomy pointer is NULL");
		return NULL;
	}

	count = (taxonomy->merged_idx)->count;

	indexed_taxon = (ecomerged_t*) bsearch((const void *) ((size_t) taxid),
                                       	   (const void *) taxonomy->merged_idx->merged,
										   count,
										   sizeof(ecomerged_t),
										   cmp_taxids_in_ecomerged_t);

	if (indexed_taxon == NULL)
		current_taxon = NULL;
	else if (indexed_taxon->idx == -1)
		current_taxon = NULL;	// TODO discuss what to do when old deleted taxon
	else
		current_taxon = (taxonomy->taxa->taxon)+(indexed_taxon->idx);

	return current_taxon;
}


int obi_taxo_is_taxon_under_taxid(ecotx_t* taxon, int32_t other_taxid)		// TODO discuss that this doesn't work with deprecated taxids
{
	ecotx_t* next_parent;

	next_parent = taxon->parent;

	if (taxon == NULL)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError checking if a taxon is under another: taxon pointer is NULL");
		return -1;
	}

	while ((other_taxid != next_parent->taxid) && (strcmp(next_parent->name, "root")))
		next_parent = next_parent->parent;

	if (other_taxid == next_parent->taxid)
		return 1;
	else
		return 0;
}


ecotx_t* obi_taxo_get_species(ecotx_t* taxon, OBIDMS_taxonomy_p taxonomy)
{
	static int32_t		     rankindex = -1;

	if (taxonomy == NULL)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError trying to get the species associated with a taxon: taxonomy pointer is NULL");
		return NULL;
	}

	if (taxon == NULL)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError trying to get the species associated with a taxon: taxon pointer is NULL");
		return NULL;
	}

	rankindex = rank_label_to_index("species", taxonomy->ranks);
	if (rankindex < 0)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError trying to get the species associated with a taxon: error getting rank index");
		return NULL;
	}

	return obi_taxo_get_parent_at_rank(taxon, rankindex);
}


ecotx_t* obi_taxo_get_genus(ecotx_t* taxon, OBIDMS_taxonomy_p taxonomy)
{
	static int32_t		     rankindex = -1;

	if (taxonomy == NULL)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError trying to get the genus associated with a taxon: taxonomy pointer is NULL");
		return NULL;
	}

	if (taxon == NULL)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError trying to get the genus associated with a taxon: taxon pointer is NULL");
		return NULL;
	}

	rankindex = rank_label_to_index("genus", taxonomy->ranks);
	if (rankindex < 0)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError trying to get the genus associated with a taxon: error getting rank index");
		return NULL;
	}

	return obi_taxo_get_parent_at_rank(taxon, rankindex);
}


ecotx_t* obi_taxo_get_family(ecotx_t* taxon, OBIDMS_taxonomy_p taxonomy)
{
	static int32_t		     rankindex = -1;

	if (taxonomy == NULL)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError trying to get the family associated with a taxon: taxonomy pointer is NULL");
		return NULL;
	}

	if (taxon == NULL)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError trying to get the family associated with a taxon: taxon pointer is NULL");
		return NULL;
	}

	rankindex = rank_label_to_index("family", taxonomy->ranks);
	if (rankindex < 0)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError trying to get the family associated with a taxon: error getting rank index");
		return NULL;
	}

	return obi_taxo_get_parent_at_rank(taxon, rankindex);
}


ecotx_t* obi_taxo_get_kingdom(ecotx_t* taxon, OBIDMS_taxonomy_p taxonomy)
{
	static int32_t		     rankindex = -1;

	if (taxonomy == NULL)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError trying to get the kingdom associated with a taxon: taxonomy pointer is NULL");
		return NULL;
	}

	if (taxon == NULL)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError trying to get the kingdom associated with a taxon: taxon pointer is NULL");
		return NULL;
	}

	rankindex = rank_label_to_index("kingdom", taxonomy->ranks);
	if (rankindex < 0)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError trying to get the kingdom associated with a taxon: error getting rank index");
		return NULL;
	}

	return obi_taxo_get_parent_at_rank(taxon, rankindex);
}


ecotx_t* obi_taxo_get_superkingdom(ecotx_t* taxon, OBIDMS_taxonomy_p taxonomy)
{
	static int32_t rankindex = -1;

	if (taxonomy == NULL)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError trying to get the superkingdom associated with a taxon: taxonomy pointer is NULL");
		return NULL;
	}

	if (taxon == NULL)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError trying to get the superkingdom associated with a taxon: taxon pointer is NULL");
		return NULL;
	}

	rankindex = rank_label_to_index("superkingdom", taxonomy->ranks);
	if (rankindex < 0)
	{
		obi_set_errno(OBI_TAXONOMY_ERROR);
		obidebug(1, "\nError trying to get the superkingdom associated with a taxon: error getting rank index");
		return NULL;
	}

	return obi_taxo_get_parent_at_rank(taxon, rankindex);
}


const char* obi_taxo_rank_index_to_label(int32_t rank_idx, ecorankidx_t* ranks)
{
	return (ranks->label)[rank_idx];
}


int obi_taxo_is_taxid_included(OBIDMS_taxonomy_p taxonomy,
			     			   int32_t* restrict_to_taxids,
				    		   int32_t count,
					    	   int32_t taxid)
{
	int i;
	ecotx_t* taxon;

	taxon = obi_taxo_get_taxon_with_taxid(taxonomy, taxid);

	if (taxon)
		for (i=0; i < count; i++)
			if ((taxon->taxid == restrict_to_taxids[i]) ||
				 (obi_taxo_is_taxon_under_taxid(taxon, restrict_to_taxids[i])))
				return 1;

	return 0;
}

