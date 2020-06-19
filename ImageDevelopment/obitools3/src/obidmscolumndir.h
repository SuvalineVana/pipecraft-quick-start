/****************************************************************************
 * OBIDMS column directories header file                                    *
 ****************************************************************************/

/**
 * @file obidmscolumndir.h
 * @author Celine Mercier
 * @date 18 June 2015
 * @brief Header file for the OBIDMS column directories structures and functions.
 */


#ifndef OBIDMSCOLUMNGROUP_H_
#define OBIDMSCOLUMNGROUP_H_


#include <stdlib.h>
#include <stdio.h>
#include <dirent.h>

#include "obidms.h"


#define OBIDMS_COLUMN_MAX_NAME (1024) /**< The maximum length of an OBIDMS column name.
                                       */


/**
 * @brief A structure describing an OBIDMS column directory instance.
 *
 * A pointer to this structure is returned on creation
 * and opening of an OBIDMS column directory.
 */
typedef struct OBIDMS_column_directory {
	OBIDMS_p	dms;	 										 /**< A pointer to a DMS instance.
     	 	 	 	 	 	 	 	 	 	 	 	 		 	  */
	char 		column_name[OBIDMS_COLUMN_MAX_NAME+1];		     /**< The name of the column
																  *    contained in the directory.
																  */
	char		directory_name[OBIDMS_COLUMN_MAX_NAME+1];	     /**< The name of the directory
	                                     	 	 	 	 	 	  *    containing the column.
	                                     	 	 	 	 	 	  */
} OBIDMS_column_directory_t, *OBIDMS_column_directory_p;


/**
 * Function building the column directory name from an OBIDMS column name.
 *
 * The function builds the directory name corresponding to an OBIDMS column directory.
 * It checks also that the name is not too long.
 *
 * @warning The returned pointer has to be freed by the caller.
 *
 * @param column_name The name of the OBIDMS column.
 *
 * @returns A pointer to the OBIDMS column directory name.
 * @retval NULL if an error occurred.
 *
 * @since June 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
char* obi_build_column_directory_name(const char* column_name);


/**
 * @brief Checks if an OBIDMS column directory exists.
 *
 * @param dms A pointer to an OBIDMS as returned by obi_create_dms() or obi_open_dms().
 * @param column_name A pointer to a C string containing the name of the column.
 *
 * @returns An integer value indicating the status of the column directory.
 * @retval 1 if the directory exists.
 * @retval 0 if the directory does not exist.
 * @retval -1 if an error occurred.
 *
 * @see obi_close_column_directory()
 * @since June 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_column_directory_exists(OBIDMS_p dms, const char* column_name);


/**
 * @brief Creates a new OBIDMS column directory instance.
 *
 * A new OBIDMS column directory is created. This function checks
 * if a directory with this name does not already exist
 * before creating the new column directory.
 *
 * @param dms A pointer to an OBIDMS as returned by obi_create_dms() or obi_open_dms().
 * @param column_name A pointer to a C string containing the name of the column.
 *                    The actual directory name used to store the column will be
 *                    `<column_name>.obicol`.
 *
 * @returns A pointer to an OBIDMS column directory structure describing the newly created
 * 		    directory.
 * @retval NULL if an error occurred.
 *
 * @see obi_close_column_directory()
 * @since June 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
OBIDMS_column_directory_p obi_create_column_directory(OBIDMS_p dms, const char* column_name);


/**
 * @brief Opens an existing OBIDMS column directory instance.
 *
 * @param dms A pointer to an OBIDMS as returned by obi_create_dms() or obi_open_dms().
 * @param column_name A pointer to a C string containing the name of the column.
 *                    The actual directory name used to store the column is
 *                    `<column_name>.obicol`.
 *
 * @returns A pointer to the OBIDMS column directory structure describing the directory.
 * @retval NULL if an error occurred.
 *
 * @see obi_close_column_directory()
 * @since June 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
OBIDMS_column_directory_p obi_open_column_directory(OBIDMS_p dms, const char* column_name);


/**
 * @brief Opens or creates a new OBIDMS column directory instance.
 *
 * If the directory already exists, this function opens it, otherwise it
 * creates a new column directory.
 *
 * @param dms A pointer to an OBIDMS as returned by obi_create_dms() or obi_open_dms().
 * @param column_name A pointer to a C string containing the name of the column.
 *                    The actual directory name used to store the column is
 *                    `<column_name>.obicol`.
 *
 * @returns A pointer to the OBIDMS column directory structure describing the directory.
 * @retval NULL if an error occurred.
 *
 * @since June 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
OBIDMS_column_directory_p obi_column_directory(OBIDMS_p dms, const char* column_name);


/**
 * @brief Closes an opened OBIDMS column directory instance.
 *
 * @param column_directory A pointer to an OBIDMS column directory as returned by
 *                         obi_create_column_directory() or obi_open_column_directory().
 *
 * @returns An integer value indicating the success of the operation. Even on
 * 		    error, the `OBIDMS_column_directory` structure is freed.
 * @retval 0 on success.
 * @retval -1 if an error occurred.
 *
 * @see obi_create_column_directory()
 * @see obi_open_column_directory()
 * @since June 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_close_column_directory(OBIDMS_column_directory_p column_directory);


#endif /* OBIDMSCOLUMNDIR_H_ */
