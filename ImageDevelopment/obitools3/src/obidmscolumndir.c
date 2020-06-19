/****************************************************************************
 * OBIDMS column directories functions                                      *
 ****************************************************************************/

/**
 * @file obidmscolumndir.c
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 * @date 18 June 2015
 * @brief Functions for OBIDMS column directories.
 */


#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <dirent.h>
#include <fcntl.h>
#include <unistd.h>

#include "obidmscolumndir.h"
#include "obidms.h"
#include "utils.h"
#include "obierrno.h"
#include "obidebug.h"


#define DEBUG_LEVEL 0	// TODO has to be defined somewhere else (cython compil flag?)



/**********************************************************************
 *
 * D E F I N I T I O N   O F   T H E   P U B L I C   F U N C T I O N S
 *
 **********************************************************************/


char* obi_build_column_directory_name(const char* column_name)
{
	char* column_directory_name;

	// Build the database directory name
	column_directory_name = (char*) malloc((strlen(column_name) + 8)*sizeof(char));
	if (sprintf(column_directory_name, "%s.obicol", column_name) < 0)
	{
		obi_set_errno(OBICOLDIR_MEMORY_ERROR);
		obidebug(1, "\nError building a column directory name");
		return NULL;
	}

	// Test if the database name is not too long
	if (strlen(column_directory_name) >= OBIDMS_COLUMN_MAX_NAME)
	{
		obi_set_errno(OBICOLDIR_LONG_NAME_ERROR);
		obidebug(1, "\nError due to column name too long");
		free(column_directory_name);
		return NULL;
	}

	return column_directory_name;
}


int obi_column_directory_exists(OBIDMS_p dms, const char* column_name)
{
    struct 	stat buffer;
	char* 	column_directory_name;
	char* 	full_path;
    int 	check_dir;

	// Build and check the directory name
    column_directory_name = obi_build_column_directory_name(column_name);
	if (column_directory_name == NULL)
		return -1;

	// Get the full path for the column directory
	full_path = obi_dms_get_full_path(dms, column_directory_name);
	if (full_path == NULL)
	{
		obi_set_errno(OBICOLDIR_UNKNOWN_ERROR);
		obidebug(1, "\nError getting path for an OBIDMS directory");
		free(column_directory_name);
		return -1;
	}

	check_dir = stat(full_path, &buffer);

	free(column_directory_name);
	free(full_path);

    if(check_dir == 0)
        return 1;
    else
        return 0;
}


OBIDMS_column_directory_p obi_create_column_directory(OBIDMS_p dms, const char* column_name)
{
	char* 	column_directory_name;

	// Build and check the directory name
	column_directory_name = obi_build_column_directory_name(column_name);
	if (column_directory_name == NULL)
	{
		obi_set_errno(OBICOLDIR_UNKNOWN_ERROR);
		return NULL;
	}

	// Try to create the directory
	if (mkdirat(dms->dir_fd, column_directory_name, 00777) < 0)
	{
		if (errno == EEXIST)
			obi_set_errno(OBICOLDIR_EXIST_ERROR);
		else
			obi_set_errno(OBICOLDIR_UNKNOWN_ERROR);
		obidebug(1, "\nError creating a column directory");
		free(column_directory_name);
		return NULL;
	}

	free(column_directory_name);

	return obi_open_column_directory(dms, column_name);
}


OBIDMS_column_directory_p obi_open_column_directory(OBIDMS_p dms, const char* column_name)
{
	OBIDMS_column_directory_p	column_directory;
	char*	 					column_directory_name;
	DIR*						directory;

	column_directory = NULL;

	// Build and check the directory name
	column_directory_name = obi_build_column_directory_name(column_name);
	if (column_directory_name == NULL)
		return NULL;

	// Try to open the column directory
	directory = opendir_in_dms(dms, column_directory_name);
	if (directory == NULL) {
		switch (errno)
		{
			case ENOENT:
				obi_set_errno(OBICOLDIR_NOT_EXIST_ERROR);
				break;

			case EACCES:
				obi_set_errno(OBICOLDIR_ACCESS_ERROR);
				break;

			case ENOMEM:
				obi_set_errno(OBICOLDIR_MEMORY_ERROR);
				break;

			default:
				obi_set_errno(OBICOLDIR_UNKNOWN_ERROR);
		}
		obidebug(1, "\nError opening a column directory");
		free(column_directory_name);
		return NULL;
	}

	// Allocate the column dir structure
	column_directory = (OBIDMS_column_directory_p) malloc(sizeof(OBIDMS_column_directory_t));
	if (column_directory == NULL)
	{
		obi_set_errno(OBICOLDIR_MEMORY_ERROR);
		obidebug(1, "\nError allocating the memory for an OBIDMS column directory structure");
		free(column_directory_name);
		return NULL;
	}

	// Initialize the data structure
	column_directory->dms = dms;
	strcpy(column_directory->directory_name, column_directory_name);
	strcpy(column_directory->column_name, column_name);

	if (closedir(directory) < 0)
	{
		obi_set_errno(OBICOLDIR_MEMORY_ERROR);
		obidebug(1, "\nError closing a DIR after opening a column directory");
		free(column_directory_name);
		return NULL;
	}

	free(column_directory_name);

	return column_directory;
}


OBIDMS_column_directory_p obi_column_directory(OBIDMS_p dms, const char* column_name)
{
	int exists;
	exists = obi_column_directory_exists(dms, column_name);

	switch (exists)
	{
		case 0:
			return obi_create_column_directory(dms, column_name);
		case 1:
			return obi_open_column_directory(dms, column_name);
	};

	obidebug(1, "\nError checking if a column directory exists");
	return NULL;
}


int obi_close_column_directory(OBIDMS_column_directory_p column_directory)
{
	if (column_directory != NULL)
		free(column_directory);

	return 0;
}

