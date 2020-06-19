/********************************************************************
 * OBIDMS functions                                                 *
 ********************************************************************/

/**
 * @file obidms.c
 * @author Eric Coissac (eric.coissac@metabarcoding.org)
 * @date 23 May 2015
 * @brief OBIDMS functions.
 */


#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/types.h>
#include <dirent.h>
#include <unistd.h>
#include <libgen.h>   /* <EC> : Added July 28th 2017 to include basename */
#include <sys/mman.h>
#include <math.h>

#include "obidms.h"
#include "obierrno.h"
#include "obidebug.h"
#include "obidmscolumn.h"
#include "obiview.h"
#include "obiblob_indexer.h"
#include "utils.h"
#include "obilittlebigman.h"
#include "libjson/json_utils.h"
#include "obisig.h"


#define DEBUG_LEVEL 0	// TODO has to be defined somewhere else (cython compil flag?)


// Initialize global list of opened DMS and their associated counters
OBIDMS_p global_opened_dms_list[MAX_NB_OPENED_DMS+1] = { 0 };
int global_opened_dms_counter_list[MAX_NB_OPENED_DMS+1] = { 0 };



/**************************************************************************
 *
 * D E C L A R A T I O N   O F   T H E   P R I V A T E   F U N C T I O N S
 *
 **************************************************************************/


/**
 * Internal function building the OBIDMS directory name from an OBIDMS name.
 *
 * The function builds the directory name corresponding to an OBIDMS.
 * It also checks that the name is not too long.
 *
 * @warning The returned pointer has to be freed by the caller.
 *
 * @param dms_name The name of the OBIDMS.
 *
 * @returns A pointer to the directory name.
 * @retval NULL if an error occurred.
 *
 * @since May 2015
 * @author Eric Coissac (eric.coissac@metabarcoding.org)
 */
static char* build_directory_name(const char* dms_name);


/**
 * Internal function building the informations file name from an OBIDMS name.
 *
 * The function builds the file name for the informations file of an OBIDMS.
 *
 * @warning The returned pointer has to be freed by the caller.
 *
 * @param dms_name The name of the OBIDMS.
 *
 * @returns A pointer on the file name.
 * @retval NULL if an error occurred.
 *
 * @since November 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static char* build_infos_file_name(const char* dms_name);


/**
 * Internal function calculating the initial size of the file where the informations about a DMS are stored.
 *
 * @returns The initial size of the file in bytes, rounded to a multiple of page size.
 *
 * @since September 2018
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static size_t get_platform_infos_file_size(void);


/**
 * @brief Internal function enlarging a DMS information file.
 *
 * @param dms A pointer on the DMS.
 * @param new_size The new size needed, in bytes (not necessarily rounded to a page size multiple).
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since September 2018
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static int enlarge_infos_file(OBIDMS_p dms, size_t new_size);


/**
 * @brief Internal function mapping a DMS information file and returning the mapped structure stored in it.
 *
 * The function checks that endianness of the platform and of the DMS match.
 *
 * @param dms_file_descriptor The file descriptor of the DMS directory.
 * @param dms_name The base name of the DMS.
 *
 * @returns A pointer on the mapped DMS infos structure.
 * @retval NULL if an error occurred.
 *
 * @since September 2018
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static OBIDMS_infos_p map_infos_file(int dms_file_descriptor, const char* dms_name);


/**
 * @brief Unmaps a DMS information file.
 *
 * @param dms A pointer on the OBIDMS.
 *
 * @returns A value indicating the success of the operation.
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since October 2018
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static int unmap_infos_file(OBIDMS_p dms);


/**
 * Internal function creating the file containing basic informations on the OBIDMS.
 *
 * This file contains an OBIDMS_infos structure.
 *
 * @warning The returned pointer has to be freed by the caller.
 *
 * @param dms_file_descriptor The file descriptor of the DMS directory.
 * @param dms_name The base name of the DMS.
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since November 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static int create_dms_infos_file(int dms_file_descriptor, const char* dms_name);


/**
 * Internal function adding a DMS in the global list of DMS opened by a program.
 *
 * @param dms A pointer on the DMS to add.
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since October 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static int list_dms(OBIDMS_p dms);


/**
 * Internal function removing a DMS from the global list of DMS opened by a program.
 *
 * @param dms A pointer on the DMS to remove.
 * @param force Whether the DMS should be unlisted even if it is opened more than once.
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if the DMS was not found.
 *
 * @since October 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static int unlist_dms(OBIDMS_p dms, bool force);


/**
 * Internal function checking if a DMS is already in the global list of DMS opened by the program.
 *
 * @param full_dms_path The absolute path to the DMS directory.
 *
 * @returns A pointer on the DMS if it is already opened, or NULL if it was not opened.
 *
 * @since November 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static OBIDMS_p check_if_dms_in_list(const char* full_dms_path);


/**
 * Internal function returning the count for an opened DMS (how many times the DMS is opened) in the global list of DMS opened by the program.
 *
 * @param dms A pointer on the DMS.
 *
 * @returns The count indicating how many times the DMS has been opened by the program.
 *
 * @retval -1 if the DMS was not found.
 *
 * @since November 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static int dms_count_in_list(OBIDMS_p dms);



/************************************************************************
 *
 * D E F I N I T I O N   O F   T H E   P R I V A T E   F U N C T I O N S
 *
 ************************************************************************/

static char* build_directory_name(const char* dms_name)
{
	char* directory_name;

	// Build the database directory name
	directory_name = (char*) malloc((strlen(dms_name) + 8)*sizeof(char));
	if (sprintf(directory_name, "%s.obidms", dms_name) < 0)
	{
		obi_set_errno(OBIDMS_MEMORY_ERROR);
		obidebug(1, "\nProblem building an OBIDMS directory name");
		return NULL;
	}

	// Test if the database name is not too long
	if (strlen(directory_name) >= OBIDMS_MAX_NAME)
	{
		obi_set_errno(OBIDMS_LONG_NAME_ERROR);
		obidebug(1, "\nProblem building an OBIDMS directory name");
		free(directory_name);
		return NULL;
	}

	return directory_name;
}


static char* build_infos_file_name(const char* dms_name)
{
	char* file_name;

	// Build file name
	file_name = (char*) malloc((strlen(dms_name) + 7)*sizeof(char));
	if (sprintf(file_name, "%s_infos", dms_name) < 0)
	{
		obi_set_errno(OBIDMS_MEMORY_ERROR);
		obidebug(1, "\nProblem building an informations file name");
		return NULL;
	}

	return file_name;
}


static size_t get_platform_infos_file_size()
{
	size_t infos_size;
	size_t rounded_infos_size;
	double multiple;

	infos_size = sizeof(OBIDMS_infos_t);

	multiple = 	ceil((double) (infos_size) / (double) getpagesize());

	rounded_infos_size = multiple * getpagesize();

	return rounded_infos_size;
}


static int enlarge_infos_file(OBIDMS_p dms, size_t new_size)
{
	int    infos_file_descriptor;
	double multiple;
	size_t rounded_new_size;
	char*  file_name;

	// Create file name
	file_name = build_infos_file_name(dms->dms_name);
	if (file_name == NULL)
		return -1;

    // Open infos file
	infos_file_descriptor = openat(dms->dir_fd, file_name, O_RDWR, 0777);
	if (infos_file_descriptor < 0)
	{
		obi_set_errno(OBIDMS_UNKNOWN_ERROR);
		obidebug(1, "\nError opening a DMS information file");
		free(file_name);
		return -1;
	}

	free(file_name);

	// Round new size to a multiple of page size	// TODO make function in utils
	multiple = 	ceil((double) new_size / (double) getpagesize());
	rounded_new_size = multiple * getpagesize();

	// Enlarge the file
	if (ftruncate(infos_file_descriptor, rounded_new_size) < 0)
	{
		obi_set_errno(OBIDMS_UNKNOWN_ERROR);
		obidebug(1, "\nError enlarging a DMS information file");
		close(infos_file_descriptor);
		return -1;
	}

	// Unmap and remap the file
	if (munmap(dms->infos, (dms->infos)->file_size) < 0)
	{
		obi_set_errno(OBIDMS_UNKNOWN_ERROR);
		obidebug(1, "\nError munmapping a DMS information file when enlarging");
		close(infos_file_descriptor);
		return -1;
	}

	dms->infos = mmap(NULL,
					  rounded_new_size,
					  PROT_READ | PROT_WRITE,
					  MAP_SHARED,
					  infos_file_descriptor,
					  0
					  );
	if (dms->infos == MAP_FAILED)
	{
		obi_set_errno(OBIDMS_UNKNOWN_ERROR);
		obidebug(1, "\nError re-mmapping a DMS information file after enlarging the file");
		close(infos_file_descriptor);
		return -1;
	}

	// Set new size
	(dms->infos)->file_size = rounded_new_size;

	if (close(infos_file_descriptor) < 0)
	{
		obi_set_errno(OBIDMS_UNKNOWN_ERROR);
		obidebug(1, "\nError closing a DMS information file");
		return -1;
	}

	return 0;
}


static OBIDMS_infos_p map_infos_file(int dms_file_descriptor, const char* dms_name)
{
	char*				file_name;
	OBIDMS_infos_p		dms_infos;
	int 				file_descriptor;
	size_t  			min_size;
	size_t  			full_size;
	bool                little_endian_platform;

	// Build file name
	file_name = build_infos_file_name(dms_name);
	if (file_name == NULL)
		return NULL;

    // Open file
	file_descriptor = openat(dms_file_descriptor,
							 file_name,
							 O_RDWR, 0777);
	if (file_descriptor < 0)
	{
		obi_set_errno(OBIDMS_UNKNOWN_ERROR);
		obidebug(1, "\nError opening a DMS information file (DMS %s)", dms_name);
		free(file_name);
		return NULL;
	}

	free(file_name);

	// Map minimum size to read endianness and file size
	// (fread() fails to read properly from the structure in the file because of padding)
	min_size = get_platform_infos_file_size();

	dms_infos = mmap(NULL,
					 min_size,
					 PROT_READ | PROT_WRITE,
					 MAP_SHARED,
					 file_descriptor,
					 0
	   	   	 	 	);
	if (dms_infos == NULL)
	{
		obi_set_errno(OBIDMS_UNKNOWN_ERROR);
		obidebug(1, "\nError mapping a DMS information file");
		return NULL;
	}

	// Check endianness of the platform and DMS
	little_endian_platform = obi_is_little_endian();
	if (little_endian_platform != dms_infos->little_endian)
	{
		obi_set_errno(OBIDMS_BAD_ENDIAN_ERROR);
		obidebug(1, "\nError: The DMS and the platform have different endianness");
		close(file_descriptor);
		return NULL;
	}

	// Read actual file size
	full_size = dms_infos->file_size;

	// Unmap the minimum size and remap the file with the full size
	if (munmap(dms_infos, min_size) < 0)
	{
		obi_set_errno(OBIDMS_UNKNOWN_ERROR);
		obidebug(1, "\nError munmapping a DMS information file");
		close(file_descriptor);
		return NULL;
	}

	dms_infos = mmap(NULL,
				 	 full_size,
					 PROT_READ | PROT_WRITE,
					 MAP_SHARED,
					 file_descriptor,
					 0
	   	   	 	 	);
	if (dms_infos == NULL)
	{
		obi_set_errno(OBIDMS_UNKNOWN_ERROR);
		obidebug(1, "\nError mapping a DMS information file");
		return NULL;
	}

	if (close(file_descriptor) < 0)
	{
		obi_set_errno(OBIDMS_UNKNOWN_ERROR);
		obidebug(1, "\nError closing a DMS information file");
		return NULL;
	}

	return dms_infos;
}


static int unmap_infos_file(OBIDMS_p dms)
{
	OBIDMS_infos_p dms_infos;
	char* 	       file_name;
	int 	       file_descriptor;
	size_t         file_size;

	dms_infos = dms->infos;

	// Build file name
	file_name = build_infos_file_name(dms->dms_name);
	if (file_name == NULL)
		return -1;

    // Open file
	file_descriptor = openat(dms->dir_fd,
							 file_name,
							 O_RDWR, 0777);
	if (file_descriptor < 0)
	{
		obi_set_errno(OBIDMS_UNKNOWN_ERROR);
		obidebug(1, "\nError opening a DMS information file (DMS %s) to unmap it", dms->dms_name);
		free(file_name);
		return -1;
	}

	free(file_name);

	// Unmap the DMS infos structure
	file_size = dms_infos->file_size;
	if (munmap(dms_infos, file_size) < 0)
	{
		obi_set_errno(OBIDMS_UNKNOWN_ERROR);
		obidebug(1, "\nError unmapping a DMS information file");
		close(file_descriptor);
		return -1;
	}

	if (close(file_descriptor) < 0)
	{
		obi_set_errno(OBIDMS_UNKNOWN_ERROR);
		obidebug(1, "\nError closing a DMS information file");
		return -1;
	}

	return 0;
}


static int create_dms_infos_file(int dms_file_descriptor, const char* dms_name)
{
	char*				file_name;
	int 				infos_file_descriptor;
	size_t  			file_size;

	// Build file name
	file_name = build_infos_file_name(dms_name);
	if (file_name == NULL)
		return -1;

    // Create file
	infos_file_descriptor = openat(dms_file_descriptor,
								   file_name,
								   O_RDWR | O_CREAT | O_EXCL,
								   0777);
	if (infos_file_descriptor < 0)
	{
		obi_set_errno(OBIDMS_UNKNOWN_ERROR);
		obidebug(1, "\nError creating a DMS information file (DMS %s)", dms_name);
		free(file_name);
		return -1;
	}

	free(file_name);

	// Truncate file to the initial size
	file_size = get_platform_infos_file_size();

	if (ftruncate(infos_file_descriptor, file_size) < 0)
	{
		obi_set_errno(OBIDMS_UNKNOWN_ERROR);
		obidebug(1, "\nError truncating a DMS information file to the right size");
		close(infos_file_descriptor);
		return -1;
	}

	// Map the DMS infos structure
	OBIDMS_infos_p infos = mmap(NULL,
				 	 file_size,
					 PROT_READ | PROT_WRITE,
					 MAP_SHARED,
					 infos_file_descriptor,
					 0
	   	   	 	 	);

	// Initialize values
	infos->little_endian = obi_is_little_endian();
	infos->file_size = file_size;
	infos->used_size = 0;
	infos->working = false;
	infos->comments[0] = '\0';

	// Unmap the infos file
	if (munmap(infos, file_size) < 0)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError munmapping a DMS information file");
		return -1;
	}

	if (close(infos_file_descriptor) < 0)
	{
		obi_set_errno(OBIDMS_UNKNOWN_ERROR);
		obidebug(1, "\nError closing a view file");
		return -1;
	}

	return 0;
}


static int list_dms(OBIDMS_p dms)
{
	int i = 0;
	while ((global_opened_dms_list[i] != NULL) && (global_opened_dms_list[i] != dms))
		i++;
	if (i == (MAX_NB_OPENED_DMS-1))
	{
		obi_set_errno(OBIDMS_UNKNOWN_ERROR);
		obidebug(1, "\nError opening a DMS: maximum number of DMS opened by a program reached");
		return -1;
	}
	if (global_opened_dms_list[i] == NULL)
	{    // new dms
		global_opened_dms_list[i] = dms;
		global_opened_dms_counter_list[i] = 1;
	}
	else
	{    // already opened dms
		(global_opened_dms_counter_list[i])++;
	}

	return 0;
}


static int unlist_dms(OBIDMS_p dms, bool force)
{
	int i = 0;
	while ((global_opened_dms_list[i] != dms) && (i <= MAX_NB_OPENED_DMS))
		i++;
	if (i == MAX_NB_OPENED_DMS)
		return -1; // DMS not found
	// If opened more than once, and the unlisting is not forced, decrement counter
	if ((global_opened_dms_counter_list[i] > 1) && (! force))
		(global_opened_dms_counter_list[i])--;
	else
	{	// If opened once or forced unlisting, delete and unlist by shifting the list
		while (global_opened_dms_list[i] != NULL)
		{
			global_opened_dms_list[i] = global_opened_dms_list[i+1];
			i++;
		}
	}
	return 0;
}


static OBIDMS_p check_if_dms_in_list(const char* full_dms_path)
{
	int i = 0;
	while ((i <= MAX_NB_OPENED_DMS) && (global_opened_dms_list[i] != NULL) && (strcmp(global_opened_dms_list[i]->directory_path, full_dms_path) != 0))
		i++;
	if (i == MAX_NB_OPENED_DMS)
		return NULL; // DMS not found
	if (global_opened_dms_list[i] != NULL)
		return global_opened_dms_list[i];
	return NULL;
}


static int dms_count_in_list(OBIDMS_p dms)
{
	int i = 0;
	while ((i <= MAX_NB_OPENED_DMS) && (global_opened_dms_list[i] != dms))
		i++;
	if (i == MAX_NB_OPENED_DMS)
		return -1; // DMS not found
	return global_opened_dms_counter_list[i];
}


/**********************************************************************
 *
 * D E F I N I T I O N   O F   T H E   P U B L I C   F U N C T I O N S
 *
 **********************************************************************/

int obi_dms_is_clean(OBIDMS_p dms)
{
	int ret_val1;
	int ret_val2;

	ret_val1 = obi_dms_has_unfinished_views(dms);
	if (ret_val1 < 0)
		return -1;
	ret_val2 = obi_dms_has_unfinished_columns(dms);
	if (ret_val2 < 0)
		return -1;

	return !(ret_val1 || ret_val2);
}


int obi_clean_dms(const char* dms_path)
{
	OBIDMS_p dms;

	dms = obi_open_dms(dms_path, true);
	if (dms == NULL)
	{
		obidebug(1, "\nError opening a DMS before cleaning unfinished views and columns");
		return -1;
	}

	// Currently done in obi_open_dms
//	// Clean unfinished views
//	if (obi_clean_unfinished_views(dms) < 0)
//	{
//		obidebug(1, "\nError cleaning unfinished views");
//		return -1;
//	}
//
//	// Clean unfinished columns
//	if (obi_clean_unfinished_columns(dms) < 0)
//	{
//		obidebug(1, "\nError cleaning unfinished columns");
//		return -1;
//	}

	if (obi_close_dms(dms, true) < 0)
	{
		obidebug(1, "\nError closing a DMS after cleaning");
		return -1;
	}

	return 0;
}


int obi_dms_exists(const char* dms_path)
{
    struct stat buffer;
	char*       directory_name;
    int 		check_dir;

	// Build and check the directory name
    directory_name = build_directory_name(dms_path);
	if (directory_name == NULL)
		return -1;

	check_dir = stat(directory_name, &buffer);

	free(directory_name);

    if (check_dir == 0)
        return 1;
    else
    	return 0;
}


OBIDMS_p obi_create_dms(const char* dms_path)
{
	char*  			directory_name;
	DIR*  			dms_dir;
	int    			dms_file_descriptor;
	OBIDMS_p        dms;

	// Build and check the directory name
	directory_name = build_directory_name(dms_path);
	if (directory_name == NULL)
		return NULL;

	// Try to create the directory
	if (mkdir(directory_name, 00777) < 0)
	{
		if (errno == EEXIST)
		{
			obi_set_errno(OBIDMS_EXIST_ERROR);
			obidebug(1, "\nAn OBIDMS directory with the same name already exists in this directory.");
		}
		else
			obi_set_errno(OBIDMS_UNKNOWN_ERROR);
		obidebug(1, "\nProblem creating an OBIDMS directory");
		free(directory_name);
		return NULL;
	}

	// Get file descriptor of DMS directory to create other directories
	dms_dir = opendir(directory_name);
	if (dms_dir == NULL)
	{
		obi_set_errno(OBIDMS_UNKNOWN_ERROR);
		obidebug(1, "\nProblem opening a newly created OBIDMS directory");
		free(directory_name);
		return NULL;
	}

	free(directory_name);

	dms_file_descriptor = dirfd(dms_dir);
	if (dms_file_descriptor < 0)
	{
		obi_set_errno(OBIDMS_UNKNOWN_ERROR);
		obidebug(1, "\nProblem getting the file descriptor of a newly created OBIDMS directory");
		return NULL;
	}

	// Create the indexer directory
	if (mkdirat(dms_file_descriptor, INDEXER_DIR_NAME, 00777) < 0)
	{
		obi_set_errno(OBI_INDEXER_ERROR);
		obidebug(1, "\nProblem creating the indexer directory");
		return NULL;
	}

	// Create the view directory
	if (mkdirat(dms_file_descriptor, VIEW_DIR_NAME, 00777) < 0)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nProblem creating the view directory");
		return NULL;
	}

	// Create the taxonomy directory
	if (mkdirat(dms_file_descriptor, TAXONOMY_DIR_NAME, 00777) < 0)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nProblem creating the taxonomy directory");
		return NULL;
	}

	// Create the information file
	if (create_dms_infos_file(dms_file_descriptor, basename((char*)dms_path)) < 0)
		return NULL;

	// Open DMS
	dms = obi_open_dms(dms_path, false);
	if (dms == NULL)
	{
		obidebug(1, "\nProblem opening a DMS");
		return NULL;
	}

	// Write empty json string in comments (Python json lib doesn't like empty "")
	if (obi_dms_write_comments(dms, "{}") < 0)
	{
		obidebug(1, "\nProblem initializing empty json string in new DMS comments");
		return NULL;
	}

	if (closedir(dms_dir) < 0)
	{
		obi_set_errno(OBIDMS_UNKNOWN_ERROR);
		obidebug(1, "\nError closing a directory");
		return NULL;
	}

	return dms;
}


OBIDMS_p obi_open_dms(const char* dms_path, bool cleaning)
{
	OBIDMS_p	dms;
	char*	 	relative_dms_path;
	char*	 	absolute_dms_path;
	//int			clean_dms;

	dms = NULL;

	// Build and check the directory name including the relative path
	relative_dms_path = build_directory_name(dms_path);
	if (relative_dms_path == NULL)
		return NULL;

	// Get and store the absolute path to the DMS directory
	absolute_dms_path = realpath(relative_dms_path, NULL);
	if (absolute_dms_path == NULL)
	{
		obi_set_errno(OBIDMS_UNKNOWN_ERROR);
		obidebug(1, "\nError getting the absolute path to the DMS directory (DMS does not exist)");
		free(relative_dms_path);
		return NULL;
	}

	free(relative_dms_path);

	// Check if the DMS is already opened
	dms = check_if_dms_in_list(absolute_dms_path);
	if (dms != NULL)
	{
		list_dms(dms);
		free(absolute_dms_path);
		return dms;
	}

	// Allocate the data structure
	dms = (OBIDMS_p) malloc(sizeof(OBIDMS_t));
	if (dms == NULL)
	{
		obi_set_errno(OBIDMS_MEMORY_ERROR);
		obidebug(1, "\nError allocating the memory for the OBIDMS structure");
		return NULL;
	}

	strcpy(dms->dms_name, basename((char*)dms_path));
	strcpy(dms->directory_path, absolute_dms_path);

	// Try to open the directory
	dms->directory = opendir(dms->directory_path);
	if (dms->directory == NULL)
	{
		switch (errno)
		{
			case ENOENT:
				obi_set_errno(OBIDMS_NOT_EXIST_ERROR);
				break;

			case EACCES:
				obi_set_errno(OBIDMS_ACCESS_ERROR);
				break;

			case ENOMEM:
				obi_set_errno(OBIDMS_MEMORY_ERROR);
				break;

			default:
				obi_set_errno(OBIDMS_UNKNOWN_ERROR);
		}
		obidebug(1, "\nCan't open OBIDMS directory");
		free(dms);
		return NULL;
	}

	// Get and store file descriptor of DMS directory
	dms->dir_fd = dirfd(dms->directory);
	if (dms->dir_fd < 0)
	{
		obi_set_errno(OBIDMS_UNKNOWN_ERROR);
		obidebug(1, "\nError getting the file descriptor for a newly created OBIDMS directory");
		closedir(dms->directory);
		free(dms);
		return NULL;
	}

	// Open the information file
	dms->infos = map_infos_file(dms->dir_fd, dms->dms_name);
	if (dms->infos == NULL)
	{
		obidebug(1, "\nError opening a DMS information file");
		closedir(dms->directory);
		free(dms);
		return NULL;
	}

	// Reset the working variable to false if cleaning the DMS
	if (cleaning)
		(dms->infos)->working = false;

	// Check that the DMS is not already working (being used by a process)
	if ((dms->infos)->working)
	{
		obidebug(1, "\n\nERROR:\nThe DMS '%s' contains unfinished views or columns. Either another command is currently running, "
                    "in which case you have to wait for it to finish, or a previous command was interrupted, "
                    "in which case you can run 'obi clean_dms [your_dms]' to clean the DMS.\n", dms->dms_name);
		obi_set_errno(OBIDMS_WORKING);
		unmap_infos_file(dms);
		closedir(dms->directory);
		free(dms);
		return NULL;
	}

	// Set the working variable to true
	(dms->infos)->working = true;

	// Open the indexer directory
	dms->indexer_directory = opendir_in_dms(dms, INDEXER_DIR_NAME);
	if (dms->indexer_directory == NULL)
	{
		obi_set_errno(OBIDMS_UNKNOWN_ERROR);
		obidebug(1, "\nError opening the indexer directory");
		unmap_infos_file(dms);
		closedir(dms->directory);
		free(dms);
		return NULL;
	}

	// Store the indexer directory's file descriptor
	dms->indexer_dir_fd = dirfd(dms->indexer_directory);
	if (dms->indexer_dir_fd < 0)
	{
		obi_set_errno(OBIDMS_UNKNOWN_ERROR);
		obidebug(1, "\nError getting the file descriptor of the indexer directory");
		unmap_infos_file(dms);
		closedir(dms->indexer_directory);
		closedir(dms->directory);
		free(dms);
		return NULL;
	}

	// Open the view directory
	dms->view_directory = opendir_in_dms(dms, VIEW_DIR_NAME);
	if (dms->view_directory == NULL)
	{
		obi_set_errno(OBIDMS_UNKNOWN_ERROR);
		obidebug(1, "\nError opening the view directory");
		unmap_infos_file(dms);
		closedir(dms->indexer_directory);
		closedir(dms->directory);
		free(dms);
		return NULL;
	}

	// Store the view directory's file descriptor
	dms->view_dir_fd = dirfd(dms->view_directory);
	if (dms->view_dir_fd < 0)
	{
		obi_set_errno(OBIDMS_UNKNOWN_ERROR);
		obidebug(1, "\nError getting the file descriptor of the view directory");
		unmap_infos_file(dms);
		closedir(dms->view_directory);
		closedir(dms->directory);
		free(dms);
		return NULL;
	}

	// Open the taxonomy directory
	dms->tax_directory = opendir_in_dms(dms, TAXONOMY_DIR_NAME);
	if (dms->tax_directory == NULL)
	{
		obi_set_errno(OBIDMS_UNKNOWN_ERROR);
		obidebug(1, "\nError opening the taxonomy directory");
		unmap_infos_file(dms);
		closedir(dms->indexer_directory);
		closedir(dms->view_directory);
		closedir(dms->directory);
		free(dms);
		return NULL;
	}

	// Store the taxonomy directory's file descriptor
	dms->tax_dir_fd = dirfd(dms->tax_directory);
	if (dms->tax_dir_fd < 0)
	{
		obi_set_errno(OBIDMS_UNKNOWN_ERROR);
		obidebug(1, "\nError getting the file descriptor of the taxonomy directory");
		unmap_infos_file(dms);
		closedir(dms->indexer_directory);
		closedir(dms->tax_directory);
		closedir(dms->view_directory);
		closedir(dms->directory);
		free(dms);
		return NULL;
	}

	//	// Check for unfinished views and columns
	//	clean_dms = obi_dms_is_clean(dms);
	//	if (clean_dms < 0)
	//	{
	//		obi_set_errno(OBIDMS_UNKNOWN_ERROR);
	//		obidebug(1, "\nError checking if a DMS has unfinished views or columns when opening it");
	//		unmap_infos_file(dms);
	//		closedir(dms->indexer_directory);
	//		closedir(dms->tax_directory);
	//		closedir(dms->view_directory);
	//		closedir(dms->directory);
	//		free(dms);
	//		return NULL;
	//	}
	//	if (! clean_dms)
	//		obi_set_errno(OBIDMS_NOT_CLEAN);

	// Clean unfinished views
	if (obi_clean_unfinished_views(dms) < 0)
	{
		obidebug(1, "\nError cleaning unfinished views when opening an OBIDMS");
		unmap_infos_file(dms);
		closedir(dms->indexer_directory);
		closedir(dms->tax_directory);
		closedir(dms->view_directory);
		closedir(dms->directory);
		free(dms);
		return NULL;
	}

	// Clean unfinished columns
	if (obi_clean_unfinished_columns(dms) < 0)
	{
		obidebug(1, "\nError cleaning unfinished columns when opening an OBIDMS");
		unmap_infos_file(dms);
		closedir(dms->indexer_directory);
		closedir(dms->tax_directory);
		closedir(dms->view_directory);
		closedir(dms->directory);
		free(dms);
		return NULL;
	}

	// Initialize the list of opened columns
	dms->opened_columns = (Opened_columns_list_p) malloc(sizeof(Opened_columns_list_t));
	(dms->opened_columns)->nb_opened_columns = 0;

	// Initialize the list of opened indexers
	dms->opened_indexers = (Opened_indexers_list_p) malloc(sizeof(Opened_indexers_list_t));
	(dms->opened_indexers)->nb_opened_indexers = 0;

	// Add in the global list of opened DMS
	if (list_dms(dms) < 0)
	{
		obidebug(1, "\nError cleaning unfinished columns when opening an OBIDMS");
		unmap_infos_file(dms);
		closedir(dms->indexer_directory);
		closedir(dms->tax_directory);
		closedir(dms->view_directory);
		closedir(dms->directory);
		free(dms->opened_columns);
		free(dms->opened_indexers);
		free(dms);
		return NULL;
	}

	return dms;
}


OBIDMS_p obi_test_open_dms(const char* dms_name)
{
	int exists;

	exists = obi_dms_exists(dms_name);

	switch (exists)
	{
		case 0:
			return NULL;
		case 1:
			return obi_open_dms(dms_name, false);
	};

	obidebug(1, "\nError checking if an OBIDMS directory exists");
	return NULL;
}


OBIDMS_p obi_dms(const char* dms_name)
{
	int exists;

	exists = obi_dms_exists(dms_name);

	switch (exists)
	{
		case 0:
			return obi_create_dms(dms_name);
		case 1:
			return obi_open_dms(dms_name, false);
	};

	obidebug(1, "\nError checking if an OBIDMS directory exists");
	return NULL;
}


int obi_close_dms(OBIDMS_p dms, bool force)
{
	int dms_counter;

	if (!force)
	{
		dms_counter = dms_count_in_list(dms);
		if (dms_counter < 0)
			obidebug(1, "\nError checking the counter of an OBIDMS in the global list of opened OBIDMS");

		if (dms_counter > 1)	// Don't close if the DMS is opened more than once
		{
			if (unlist_dms(dms, force) < 0)
			{
				obidebug(1, "\nError decrementing the counter of an OBIDMS in the global list of opened OBIDMS");
				return -1;
			}
			return 0;
		}
	}

	if (dms != NULL)
	{
		// Close all columns
		while ((dms->opened_columns)->nb_opened_columns > 0)
			obi_close_column(*((dms->opened_columns)->columns));

		// Close dms, and view, indexer and taxonomy directories
		if (closedir(dms->indexer_directory) < 0)
		{
			obi_set_errno(OBI_INDEXER_ERROR);
			obidebug(1, "\nError closing an indexer directory");
			free(dms);
			return -1;
		}
		if (closedir(dms->view_directory) < 0)
		{
			obi_set_errno(OBIVIEW_ERROR);
			obidebug(1, "\nError closing a view directory");
			free(dms);
			return -1;
		}
		if (closedir(dms->tax_directory) < 0)
		{
			obi_set_errno(OBIVIEW_ERROR);
			obidebug(1, "\nError closing a taxonomy directory");
			free(dms);
			return -1;
		}

		// Set the working variable as false
		(dms->infos)->working = false;

		// Unmap information file
		if (unmap_infos_file(dms) < 0)
		{
			obidebug(1, "\nError unmaping a DMS information file while closing a DMS");
			free(dms);
			return -1;
		}

		if (closedir(dms->directory) < 0)
		{
			obi_set_errno(OBIDMS_MEMORY_ERROR);
			obidebug(1, "\nError closing an OBIDMS directory");
			free(dms);
			return -1;
		}

		// Remove DMS from global list of opened DMS
		if (unlist_dms(dms, force) < 0)
		{
			obidebug(1, "\nError removing an OBIDMS from the global list of opened OBIDMS when closing it");
			free(dms);
			return -1;
		}

		free(dms);
	}

	return 0;
}


int obi_dms_write_comments(OBIDMS_p dms, const char* comments)
{
	size_t new_size;

	if (comments == NULL)
		return 0;	// TODO or error? discuss

	new_size = sizeof(OBIDMS_infos_t) + strlen(comments) + 1;

	// Check if the file has to be enlarged
	if (new_size >= (dms->infos)->file_size)
	{
		if (enlarge_infos_file(dms, new_size) < 0)
			return -1;
	}

	strcpy((dms->infos)->comments, comments);

	(dms->infos)->used_size = new_size;

	return 0;
}


int obi_dms_add_comment(OBIDMS_p dms, const char* key, const char* value)
{
	char* new_comments = NULL;

	new_comments = obi_add_comment((dms->infos)->comments, key, value);
	if (new_comments == NULL)
	{
		obidebug(1, "\nError adding a comment to a dms, key: %s, value: %s", key, value);
		return -1;
	}

	if (obi_dms_write_comments(dms, new_comments) < 0)
	{
		obidebug(1, "\nError adding a comment to a dms, key: %s, value: %s", key, value);
		return -1;
	}

	free(new_comments);

	return 0;
}


OBIDMS_column_p obi_dms_get_column_from_list(OBIDMS_p dms, const char* column_name, obiversion_t version)
{
	int i;

	for (i=0; i < ((dms->opened_columns)->nb_opened_columns); i++)
	{
		if (!strcmp(((*(((dms->opened_columns)->columns)+i))->header)->name, column_name)
				&& (((*(((dms->opened_columns)->columns)+i))->header)->version == version))
		{	// Found the column already opened, return it
			return *(((dms->opened_columns)->columns)+i);
		}
	}
	// Didn't find the column
	return NULL;
}


void obi_dms_list_column(OBIDMS_p dms, OBIDMS_column_p column)	// TODO add check if column already in list?
{
	*(((dms->opened_columns)->columns)+((dms->opened_columns)->nb_opened_columns)) = column;
	((dms->opened_columns)->nb_opened_columns)++;
}


int obi_dms_unlist_column(OBIDMS_p dms, OBIDMS_column_p column)
{
	int i;
	Opened_columns_list_p columns_list;

	columns_list = dms->opened_columns;

	for (i=0; i < columns_list->nb_opened_columns; i++)
	{
		if (!strcmp(((*((columns_list->columns)+i))->header)->name, (column->header)->name)
				&& (((*((columns_list->columns)+i))->header)->version == (column->header)->version))
		{	// Found the column. Rearrange list
			(columns_list->nb_opened_columns)--;
			(columns_list->columns)[i] = (columns_list->columns)[columns_list->nb_opened_columns];
			return 0;
		}
	}

	obidebug(1, "\nCould not find the column to delete from list of open columns");
	return -1;
}


Obi_indexer_p obi_dms_get_indexer_from_list(OBIDMS_p dms, const char* indexer_name)
{
	int i;
	Opened_indexers_list_p indexers_list;

	indexers_list = dms->opened_indexers;

	for (i=0; i < (indexers_list->nb_opened_indexers); i++)
	{
		if (!strcmp(obi_indexer_get_name((indexers_list->indexers)[i]), indexer_name))
		{	// Found the indexer already opened, return it
			return (indexers_list->indexers)[i];
		}
	}
	// Didn't find the indexer
	return NULL;
}


void obi_dms_list_indexer(OBIDMS_p dms, Obi_indexer_p indexer)  	// TODO add check if indexer already in list?
{
	*(((dms->opened_indexers)->indexers)+((dms->opened_indexers)->nb_opened_indexers)) = indexer;
	((dms->opened_indexers)->nb_opened_indexers)++;
}


int obi_dms_unlist_indexer(OBIDMS_p dms, Obi_indexer_p indexer)
{
	int i;
	Opened_indexers_list_p indexers_list;

	indexers_list = dms->opened_indexers;

	for (i=0; i < indexers_list->nb_opened_indexers; i++)
	{
		if (!strcmp(obi_indexer_get_name((indexers_list->indexers)[i]), indexer->name))
		{	// Found the indexer. Rearrange list
			(indexers_list->nb_opened_indexers)--;
			(indexers_list->indexers)[i] = (indexers_list->indexers)[indexers_list->nb_opened_indexers];
			return 0;
		}
	}

	obidebug(1, "\nCould not find the indexer to delete from list of open indexers");
	return -1;
}


char* obi_dms_get_dms_path(OBIDMS_p dms)
{
	char* full_path;

	full_path = (char*) malloc((MAX_PATH_LEN)*sizeof(char));
	if (full_path == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating memory for the char* path to a file or directory");
		return NULL;
	}

	strcpy(full_path, dms->directory_path);

	return full_path;
}


char* obi_dms_get_full_path(OBIDMS_p dms, const char* path_name)
{
	char* full_path;

	full_path = obi_dms_get_dms_path(dms);
	strcat(full_path, "/");
	strcat(full_path, path_name);

	return full_path;
}


DIR* opendir_in_dms(OBIDMS_p dms, const char* path_name)
{
	char* full_path;
	DIR* directory;

	full_path = obi_dms_get_full_path(dms, path_name);
	if (full_path == NULL)
		return NULL;

	directory = opendir(full_path);
	if (directory == NULL)
	{
		obi_set_errno(OBI_UTILS_ERROR);
		obidebug(1, "\nError opening a directory");
	}

	free(full_path);

	return directory;
}


// TODO move somewhere else maybe
// TODO discuss arguments
obiversion_t obi_import_column(const char* dms_path_1, const char* dms_path_2, const char* column_name, obiversion_t version_number)
{
	OBIDMS_p				dms_1;
	OBIDMS_p 				dms_2;
	OBIDMS_column_p 		column_1;
	OBIDMS_column_p 	   	column_2;
	OBIDMS_column_header_p 	header_1;
	OBIDMS_column_header_p 	header_2;
	int 					avl_exists;
	const char* 			avl_name;
	char* 					new_avl_name;
	obiversion_t 			new_version;
	int 					i;
	int 					avl_count;
	char*		 			avl_name_1;
	char* 					avl_name_2;
	char* 					avl_file_path_1;
	char* 					avl_file_path_2;
	char* 					avl_data_file_path_1;
	char* 					avl_data_file_path_2;
	char* 					complete_avl_name;
	Obi_indexer_p 			avl_group;

	dms_1 = obi_open_dms(dms_path_1, false);
	if (dms_1 == NULL)
	{
		obidebug(1, "\nError opening a DMS to import a column from it");
		return -1;
	}

	dms_2 = obi_dms(dms_path_2);
	if (dms_2 == NULL)
	{
		obidebug(1, "\nError opening or creating a DMS to import a column into it");
		return -1;
	}

	column_1 = obi_open_column(dms_1, column_name, version_number);
	if (column_1 == NULL)
	{
		obidebug(1, "\nError opening a column to import in another DMS");
		return -1;
	}

	header_1 = column_1->header;

	// Check if associated indexer exists BEFORE creating the new column as that will automatically create it if it doesn't already exist
	avl_name = header_1->indexer_name;
	avl_exists = obi_indexer_exists(dms_2, avl_name);
	if (avl_exists == -1)
	{
		obidebug(1, "\nError checking if an indexer exists while importing a column");
		return -1;
	}
	if (avl_exists)
		// Use automatic name
		new_avl_name = NULL;
	else
		// Name can stay the same
		new_avl_name = header_1->indexer_name;

	// Create new column
	column_2 = obi_create_column(dms_2, column_name, header_1->returned_data_type, header_1->line_count,
								 header_1->nb_elements_per_line, header_1->elements_names, true, header_1->tuples,
								 header_1->to_eval, new_avl_name, (header_1->associated_column).column_name,
								 (header_1->associated_column).version, header_1->comments);

	if (column_2 == NULL)
	{
		obidebug(1, "\nError creating the new column while importing a column");
		return -1;
	}

	header_2 = column_2->header;

	// Get the new version to return
	new_version = header_2->version;

	// Copy lines_used informations
	header_2->lines_used = header_1->lines_used;

	// Copy data TODO check how much time and memory that costs, eventually use write() instead
	memcpy(column_2->data, column_1->data, header_1->data_size);

	// Copy the AVL files if there are some (overwriting the automatically created files)
	if ((header_1->returned_data_type == OBI_STR) || (header_1->returned_data_type == OBI_SEQ) || (header_1->returned_data_type == OBI_QUAL))
	{
		avl_name_1 = (char*) malloc((strlen(header_1->indexer_name) + 1)  * sizeof(char));
		if (avl_name_1 == NULL)
		{
			obi_set_errno(OBI_MALLOC_ERROR);
			obidebug(1, "\nError allocating memory for an AVL name when importing a column");
			return -1;
		}
		strcpy(avl_name_1, header_1->indexer_name);

		avl_name_2 = (char*) malloc((strlen(header_2->indexer_name) + 1)  * sizeof(char));
		if (avl_name_2 == NULL)
		{
			obi_set_errno(OBI_MALLOC_ERROR);
			obidebug(1, "\nError allocating memory for an AVL name when importing a column");
			return -1;
		}
		strcpy(avl_name_2, header_2->indexer_name);

		avl_count = (column_1->indexer->last_avl_idx) + 1;

		// Close column to manipulate AVL files safely (but not multithreading safe) (TODO not sure how important this is, can't find informations about conflicts when using write() on mmapped files)
		if (obi_close_column(column_1) < 0)
		{
			obidebug(1, "\nError closing an imported column");
			return -1;
		}

		(column_2->header)->finished = true;  // note: this is normally handled by the view that created the column
		if (obi_close_column(column_2) < 0)
		{
			obidebug(1, "\nError closing an imported column");
			return -1;
		}

		for (i=0; i < avl_count; i++)
		{
			avl_file_path_1 = obi_get_full_path_of_avl_file_name(dms_1, avl_name_1, i);
			if (avl_file_path_1 == NULL)
			{
				obidebug(1, "\nError getting an AVL file path while importing a column");
				return -1;
			}

			avl_data_file_path_1 = obi_get_full_path_of_avl_data_file_name(dms_1, avl_name_1, i);
			if (avl_data_file_path_1 == NULL)
			{
				obidebug(1, "\nError getting an AVL file path while importing a column");
				return -1;
			}
			avl_file_path_2 = obi_get_full_path_of_avl_file_name(dms_2, avl_name_2, i);
			if (avl_file_path_2 == NULL)
			{
				obidebug(1, "\nError getting an AVL file path while importing a column");
				return -1;
			}
			avl_data_file_path_2 = obi_get_full_path_of_avl_data_file_name(dms_2, avl_name_2, i);
			if (avl_data_file_path_2 == NULL)
			{
				obidebug(1, "\nError getting an AVL file path while importing a column");
				return -1;
			}

			// Copy AVL file
			if (copy_file(avl_file_path_1, avl_file_path_2) < 0)
			{
				obidebug(1, "\nError copying an AVL file while importing a column");
				return -1;
			}

			// Copy AVL data file
			if (copy_file(avl_data_file_path_1, avl_data_file_path_2) < 0)
			{
				obidebug(1, "\nError copying a data AVL file while importing a column");
				return -1;
			}

			free(avl_file_path_1);
			free(avl_file_path_2);
			free(avl_data_file_path_1);
			free(avl_data_file_path_2);
		}

		// Update AVL names in headers
		avl_group = obi_open_indexer(dms_2, avl_name_2);
		for (i=0; i < avl_count; i++)
		{
			complete_avl_name = obi_build_avl_name_with_idx(avl_name_2, i);
			strcpy((((avl_group->sub_avls)[i])->header)->avl_name, complete_avl_name);
			strcpy(((((avl_group->sub_avls)[i])->data)->header)->avl_name, complete_avl_name);
			free(complete_avl_name);
		}

		free(avl_name_1);
		free(avl_name_2);
	}
	else
	{
		if (obi_close_column(column_1) < 0)
		{
			obidebug(1, "\nError closing an imported column");
			return -1;
		}

		(column_2->header)->finished = true;  // note: this is normally handled by the view that created the column
		if (obi_close_column(column_2) < 0)
		{
			obidebug(1, "\nError closing an imported column");
			return -1;
		}
	}

	// Copy associated column (update version)
	//new_associated_col_version = import_column(dms_path_1, dms_path_2, header_1->associated_column_name, header_1->associated_column_version);
	// TODO no? because if iterating over all columns in a view etc.... iterate and change associated columns version refs afterwards?

	// Close the DMS
	obi_close_dms(dms_1, false);
	obi_close_dms(dms_2, false);

	return new_version;
}


// TODO move somewhere else maybe
// TODO discuss arguments
int obi_import_view(const char* dms_path_1, const char* dms_path_2, const char* view_name_1, const char* view_name_2)
{
	OBIDMS_p 		dms_1;
	OBIDMS_p	 	dms_2;
	Obiview_p 		view_1;
	Obiview_p 		view_2;
	obiversion_t 	new_version;
	int 			i, j;
	OBIDMS_column_header_p header = NULL;
	OBIDMS_column_header_p header_2 = NULL;

	signal(SIGINT, sig_handler);

	dms_1 = obi_open_dms(dms_path_1, false);
	if (dms_1 == NULL)
	{
		obidebug(1, "\nError opening a DMS to import a view from it");
		return -1;
	}

	dms_2 = obi_dms(dms_path_2);
	if (dms_2 == NULL)
	{
		obidebug(1, "\nError opening or creating a DMS to import a view into it");
		return -1;
	}

	// Open view to import
	view_1 = obi_open_view(dms_1, view_name_1);

	// Create new view
	if (strcmp((view_1->infos)->view_type, VIEW_TYPE_NUC_SEQS) == 0)
		view_2 = obi_new_view_nuc_seqs(dms_2, view_name_2, NULL, NULL, (view_1->infos)->comments, false, false);
	else	// Non-typed view
		view_2 = obi_new_view(dms_2, view_name_2, NULL, NULL, (view_1->infos)->comments);

	// Import line count
	view_2->infos->line_count = view_1->infos->line_count;

	// Import the line selection column if there is one
	if (! view_1->infos->all_lines)
	{
		view_2->infos->all_lines = false;
		new_version = obi_import_column(dms_path_1, dms_path_2, ((view_1->infos)->line_selection).column_name, ((view_1->infos)->line_selection).version);
		if (new_version == -1)
		{
			obidebug(1, "\nError importing a line selection column while importing a view");
			return -1;
		}
		strcpy(((view_2->infos)->line_selection).column_name, ((view_1->infos)->line_selection).column_name);
		((view_2->infos)->line_selection).version = new_version;
		view_2->line_selection = obi_open_column(dms_2, ((view_2->infos)->line_selection).column_name, ((view_2->infos)->line_selection).version);
		if (view_2->line_selection == NULL)
		{
			obidebug(1, "\nError opening a line selection column while importing a view");
			return -1;
		}
	}

	// Import each column and update with the new version number
	for (i=0; i < (view_1->infos->column_count); i++)
	{
		if (! keep_running)
			return -1;

		new_version = obi_import_column(dms_path_1, dms_path_2, ((((view_1->infos)->column_references)[i]).column_refs).column_name, ((((view_1->infos)->column_references)[i]).column_refs).version);
		if (new_version == -1)
		{
			obidebug(1, "\nError importing a column while importing a view");
			return -1;
		}

		if (obi_view_add_column(view_2,
							    ((((view_1->infos)->column_references)[i]).column_refs).column_name,
							    new_version,
							    (((view_1->infos)->column_references)[i]).alias,
							    0,
								0,
								0,
								NULL,
								false,
								false,
								false,
								NULL,
								NULL,
								-1,
								NULL,
								false) < 0)
		{
			obidebug(1, "\nError adding a column to a view while importing it");
			return -1;
		}
	}

	// Go through columns again to update associated columns
	for (i=0; i < (view_1->infos->column_count); i++)
	{
		if (! keep_running)
			return -1;

		header = obi_column_get_header_from_name(dms_1, ((((view_1->infos)->column_references)[i]).column_refs).column_name, ((((view_1->infos)->column_references)[i]).column_refs).version);
		if (header == NULL)
		{
			obidebug(1, "\nError opening a column header while importing a view");
			return -1;
		}

		if (header->returned_data_type == OBI_QUAL)   // TODO maybe there should be a bool in column headers
		{
			// Look for the index of the associated column in the list
			for (j=0; j < (view_1->infos->column_count); j++)
			{
				if ((strcmp((header->associated_column).column_name, ((((view_1->infos)->column_references)[j]).column_refs).column_name) == 0) &&
						((header->associated_column).version == ((((view_1->infos)->column_references)[j]).column_refs).version))
					break;
			}

			header_2 = obi_column_get_header_from_name(dms_2, ((((view_2->infos)->column_references)[i]).column_refs).column_name, ((((view_2->infos)->column_references)[i]).column_refs).version);
			if (header_2 == NULL)
			{
				obidebug(1, "\nError opening a column header while importing a view");
				return -1;
			}

			// Update version of associated column
			(header_2->associated_column).version = ((((view_2->infos)->column_references)[j]).column_refs).version;
			if (obi_close_header(header_2) < 0)
			{
				obidebug(1, "\nError closing a column header while importing a view");
				return -1;
			}
		}
		if (obi_close_header(header) < 0)
		{
			obidebug(1, "\nError closing a column header while importing a view");
			return -1;
		}
	}

	if (! keep_running)
		return -1;

	// Close the views
	if (obi_save_and_close_view(view_1) < 0)
	{
		obidebug(1, "\nError closing a view after importing from it");
		return -1;
	}
	if (obi_save_and_close_view(view_2) < 0)
	{
		obidebug(1, "\nError closing a view after importing it");
		return -1;
	}

	// Close the DMS
	obi_close_dms(dms_1, false);
	obi_close_dms(dms_2, false);

	return 0;
}


void obi_close_atexit()
{
	int i=0;

	while (global_opened_dms_list[i] != NULL)
	{
        obi_close_dms(global_opened_dms_list[i], true);
		i++;
	}
}

