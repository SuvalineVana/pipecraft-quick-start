/****************************************************************************
 * Blob indexer header file	                                                    *
 ****************************************************************************/

/**
 * @file obiblob_indexer.h
 * @author Celine Mercier
 * @date April 12th 2016
 * @brief Header file for the functions handling the indexing of values.
 */


#ifndef OBIBLOB_INDEXER_H_
#define OBIBLOB_INDEXER_H_


#include <stdlib.h>
#include <stdio.h>

#include "obidms.h"
#include "obiavl.h"
#include "obitypes.h"
#include "obiblob.h"


#define INDEXER_MAX_NAME AVL_MAX_NAME 			/**< Macro to refer to the maximum size of the name of an indexer structure.
 	 	 	 	 	 	 	 	 	 	 	 	 */


typedef struct OBIDMS_avl_group Obi_indexer;	/**< Typedef to refer to the used indexer structure.
 	 	 	 	 	 	 	 	 	 	 	 	 */
typedef OBIDMS_avl_group_p Obi_indexer_p; 		/**< Typedef to refer to the pointer of the used indexer structure.
 	 	 	 	 	 	 	 	 	 	 	 	 */


/**
 * @brief Checks if an indexer already exists or not.
 *
 * @param dms The OBIDMS to which the indexer belongs.
 * @param name The name of the indexer.
 *
 * @returns A value indicating whether the indexer exists or not.
 * @retval 1 if the indexer exists.
 * @retval 0 if the indexer does not exist.
 * @retval -1 if an error occurred.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static inline int obi_indexer_exists(OBIDMS_p dms, const char* name)
{
	return obi_avl_exists(dms, name);
}


/**
 * @brief Opens an indexer and creates it if it does not already exist.
 *
 * @param dms The OBIDMS to which the indexer belongs.
 * @param name The name of the indexer.
 *
 * @returns A pointer to the indexer structure.
 * @retval NULL if an error occurred.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static inline Obi_indexer_p obi_indexer(OBIDMS_p dms, const char* name)
{
	return obi_avl_group(dms, name);
}


/**
 * @brief Creates an indexer.
 *
 * @param dms The OBIDMS to which the indexer belongs.
 * @param name The name of the indexer.
 *
 * @returns A pointer to the AVL tree group structure.
 * @retval NULL if an error occurred.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static inline Obi_indexer_p obi_create_indexer(OBIDMS_p dms, const char* name)
{
	return obi_create_avl_group(dms, name);
}


/**
 * @brief Opens an indexer.
 *
 * @param dms The OBIDMS to which the indexer belongs.
 * @param name The name of the indexer.
 *
 * @returns A pointer to the indexer structure.
 * @retval NULL if an error occurred.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static inline Obi_indexer_p obi_open_indexer(OBIDMS_p dms, const char* name)
{
	return obi_open_avl_group(dms, name);
}


/**
 * @brief Clones an indexer.
 *
 * @param indexer The indexer to clone.
 * @param name The name of the new indexer.
 *
 * @returns A pointer on the new indexer structure.
 * @retval NULL if an error occurred.
 *
 * @since May 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static inline Obi_indexer_p obi_clone_indexer(Obi_indexer_p indexer, const char* name)
{
	return obi_clone_avl_group(indexer, name);
}


/**
 * @brief Closes an indexer.
 *
 * @param indexer A pointer to the indexer structure to close and free.
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static inline int obi_close_indexer(Obi_indexer_p indexer)
{
	return obi_close_avl_group(indexer);
}


/**
 * @brief Indexes a blob in an indexer and returns the index referring to the blob.
 *
 * @param indexer A pointer to the indexer.
 * @param value The blob to index.
 *
 * @returns The index of the blob newly added in the indexer.
 * @retval -1 if an error occurred.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static inline index_t obi_indexer_add(Obi_indexer_p indexer, Obi_blob_p value)
{
	return obi_avl_group_add(indexer, value);
}


/**
 * @brief Recovers a blob from an indexer.
 *
 * @param indexer A pointer to the indexer.
 * @param index The index of the blob in the indexer.
 *
 * @returns A pointer to the blob recovered.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static inline Obi_blob_p obi_indexer_get(Obi_indexer_p indexer, index_t idx)
{
	return obi_avl_group_get(indexer, idx);
}


/**
 * @brief Recovers the name of an indexer.
 *
 * @param indexer A pointer on the indexer.
 *
 * @returns A pointer on the name of the indexer.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static inline const char* obi_indexer_get_name(Obi_indexer_p indexer)
{
	return obi_avl_group_get_name(indexer);
}


/**
 * @brief Builds an indexer name in the form columnname_columnversion_indexer.
 *
 * @warning The returned pointer has to be freed by the caller.
 *
 * @param column_name The name of the column associated with the indexer.
 * @param column_version The version of the column associated with the indexer.
 *
 * @returns A pointer on the indexer name built.
 * @retval NULL if an error occurred.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
char* obi_build_indexer_name(const char* column_name, obiversion_t column_version);


#endif /* OBIBLOB_INDEXER_H_ */

