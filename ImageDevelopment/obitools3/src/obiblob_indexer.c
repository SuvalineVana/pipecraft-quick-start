/****************************************************************************
 * Obiblob functions                                                       *
 ****************************************************************************/

/**
 * @file obiblob_indexer.c
 * @author Celine Mercier
 * @date April 12th 2016
 * @brief Functions handling the indexing and retrieval of blob structures.
 */


#include <stdlib.h>
#include <stdio.h>

#include "obiblob_indexer.h"
#include "obidms.h"
#include "obierrno.h"
#include "obidebug.h"


#define DEBUG_LEVEL 0	// TODO has to be defined somewhere else (cython compil flag?)


static inline int obi_indexer_exists(OBIDMS_p dms, const char* name);

static inline Obi_indexer_p obi_indexer(OBIDMS_p dms, const char* name);

static inline Obi_indexer_p obi_create_indexer(OBIDMS_p dms, const char* name);

static inline Obi_indexer_p obi_open_indexer(OBIDMS_p dms, const char* name);

static inline Obi_indexer_p obi_clone_indexer(Obi_indexer_p indexer, const char* name);

static inline int obi_close_indexer(Obi_indexer_p indexer);

static inline index_t obi_indexer_add(Obi_indexer_p indexer, Obi_blob_p value);

static inline Obi_blob_p obi_indexer_get(Obi_indexer_p indexer, index_t idx);

static inline const char* obi_indexer_get_name(Obi_indexer_p indexer);


char* obi_build_indexer_name(const char* column_name, obiversion_t column_version)
{
	char* indexer_name;

	indexer_name = (char*) malloc(INDEXER_MAX_NAME * sizeof(char));
	if (indexer_name == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating the memory for an indexer name");
		return NULL;
	}

	strcpy(indexer_name, column_name);
	sprintf(indexer_name+strlen(column_name), "_%d_indexer", column_version);

	return indexer_name;
}

