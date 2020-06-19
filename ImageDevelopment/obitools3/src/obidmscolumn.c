/****************************************************************************
 * OBIDMS columns functions                                                 *
 ****************************************************************************/

/**
 * @file obidmscolumn.c
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 * @date 22 May 2015
 * @brief Functions shared by all the OBIDMS columns.
 */


#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <dirent.h>
#include <unistd.h>
#include <time.h>
#include <fcntl.h>
#include <stdbool.h>
#include <math.h>
#include <sys/mman.h>

#include "obidmscolumn.h"
#include "obidmscolumn_idx.h"
#include "obidmscolumndir.h"
#include "obidms.h"
#include "obitypes.h"
#include "obierrno.h"
#include "obidebug.h"
#include "obilittlebigman.h"
#include "obiblob_indexer.h"
#include "utils.h"
#include "libjson/json_utils.h"


#define DEBUG_LEVEL 0	// TODO has to be defined somewhere else (cython compil flag?)


/**************************************************************************
 *
 * D E C L A R A T I O N   O F   T H E   P R I V A T E   F U N C T I O N S
 *
 **************************************************************************/


/**
 * @brief Internal function building the file name for a column.
 *
 * The function builds the file name corresponding to a column of an OBIDMS.
 *
 * @warning The returned pointer has to be freed by the caller.
 *
 * @param column_name The name of the OBIDMS column file.
 * @param version_number The version number of the OBIDMS column file.
 *
 * @returns A pointer to the column file name.
 * @retval NULL if an error occurred.
 *
 * @since May 2015
 * @author Eric Coissac (eric.coissac@metabarcoding.org)
 */
static char* build_column_file_name(const char* column_name, obiversion_t version_number);


/**
 * @brief Internal function building the file name for a column version file.
 *
 * The column version file indicates the latest version number for a column.
 * This function returns the name of the file storing this information.
 *
 * @warning The returned pointer has to be freed by the caller.
 *
 * @param column_name The name of the OBIDMS column.
 *
 * @returns A pointer to the version file name.
 * @retval NULL if an error occurred.
 *
 * @since May 2015
 * @author Eric Coissac (eric.coissac@metabarcoding.org)
 */
static char* build_version_file_name(const char* column_name);


/**
 * @brief Internal function returning a new column version number
 *        in the OBIDMS database.
 *
 * @param column_directory A pointer as returned by obi_create_column_directory() or obi_open_column_directory().
 * @param block Whether the call is blocking or not:
 *              	- `true` the call is blocking
 *                  - `false` the call is not blocking.
 *
 * @returns The next version number for this column.
 * @retval -1 if an error occurred.
 *
 * @since May 2015
 * @author Eric Coissac (eric.coissac@metabarcoding.org)
 */
static obiversion_t obi_get_new_version_number(OBIDMS_column_directory_p column_directory, bool block);


/**
 * @brief Internal function creating a new column version file
 *        in the OBIDMS database.
 *
 * The new file is initialized with the minimum version number `0`.
 *
 * @param column_directory A pointer as returned by obi_create_column_directory() or obi_open_column_directory().
 *
 * @returns The next usable version number for this column : `0`.
 * @retval -1 if an error occurred.
 *
 * @since May 2015
 * @author Eric Coissac (eric.coissac@metabarcoding.org)
 */
static obiversion_t create_version_file(OBIDMS_column_directory_p column_directory);


/**
 * @brief Internal function building the default elements names of the lines of a
 *        column, with ';' as separator (i.e. "0;1;2;...;n\0").
 *
 * @warning The returned pointer has to be freed by the caller.
 *
 * @param nb_elements_per_line The number of elements per line in the column.
 *
 * @returns A pointer on the elements names.
 * @retval NULL if an error occurred.
 *
 * @since December 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static char* build_default_elements_names(index_t nb_elements_per_line);


/**
 * @brief Internal function formatting the elements names of the lines of a
 *        column with '\0' as separator (e.g. "0\01\02\0...\0n\0").
 *
 * @param elements_names The character string formatted with ';' as separator (e.g. "0;1;2;...;n\0").
 *
 * @since January 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static void format_elements_names(char* elements_names);


/**
 * @brief Internal function comparing two element names using their sorted index, using data stored in the column header.
 *
 * @param n1_sort_idx A pointer on the sorted index of the first name.
 * @param n2_sort_idx A pointer on the sorted index of the second name.
 * @param h A pointer on the column header.
 *
 * @returns A value < 0 if name1 < name2,
 * 			a value > 0 if name1 > name2,
 * 			and 0 if name1 == name2.
 *
 * @since January 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static int cmp_elements_names_with_idx(const void* n1_sort_idx, const void* n2_sort_idx, const void* h);


/**
 * @brief Internal function comparing two element names using a pointer on the first name and the sorted index of the second name,
 * 		  using data stored in the column header.
 *
 * @param name1 A pointer on the first name.
 * @param n2_sort_idx A pointer on the sorted index of the second name.
 * @param h A pointer on the column header.
 *
 * @returns A value < 0 if name1 < name2,
 * 			a value > 0 if name1 > name2,
 * 			and 0 if name1 == name2.
 *
 * @since January 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static int cmp_elements_names_with_name_and_idx(const void* name1, const void* n2_sort_idx, const void* h);


/**
 * @brief Internal function setting the elements names of the lines of a
 *        column in the header of the OBIDMS column structure.
 *
 * @param column A pointer as returned by obi_create_column().
 * @param elements_names The names of the elements as formatted by format_elements_names().
 * @param elts_names_length The length of elements_names including the two terminal '\0's.
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since July 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static int set_elements_names(OBIDMS_column_p column, char* elements_names, int64_t elts_names_length, index_t nb_elements_per_line);


/**
 * @brief Internal function reading the informations related to the elements names
 *        of the lines of a column in the header of the OBIDMS column structure.
 *
 * @param header A pointer on the header of the column.
 *
 * @since December 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static void read_elt_names_informations(OBIDMS_column_header_p header);


/**
 * @brief Internal function counting the number of elements names in a character array.
 *
 * @param elements_names A pointer on the character string corresponding to the elements names,
 *                       formatted with ';' or with '\0' as separator.
 * @param elt_names_formatted Whether the separator is ';' (false), or '\0' (true, as formatted by format_elements_names()).
 *
 * @returns The number of elements names in the character array.
 *
 * @since January 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static index_t check_elt_names_count(const char* elements_names, bool elt_names_formatted);


/**
 * @brief Internal function computing the length of a character array containing elements names as formatted by format_elements_names().
 *
 * @param elements_names A pointer on the character string corresponding to the elements names as formatted by format_elements_names().
 *
 * @returns The length of a character array.
 *
 * @since January 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static int get_formatted_elt_names_length(const char* elements_names, index_t nb_elements);


/**
 * @brief Internal function computing how many lines of an OBIDMS column
 *        fit in a memory page.
 *
 * @param data_type The data OBIType.
 * @param nb_elements_per_line The number of elements per line.
 *
 * @returns The line count for one memory page.
 *
 * @since September 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static index_t get_line_count_per_page(OBIType_t data_type, index_t nb_elements_per_line);


/************************************************************************
 *
 * D E F I N I T I O N   O F   T H E   P R I V A T E   F U N C T I O N S
 *
 ************************************************************************/


static char* build_column_file_name(const char* column_name, obiversion_t version_number)
{
	char* file_name;
	int version_number_length;

	// Build the file name
	version_number_length = (version_number == 0 ? 1 : (int)(log10(version_number)+1));
	file_name =	(char*) malloc((strlen(column_name) + version_number_length + 6)*sizeof(char));
	if (file_name == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating the memory for a column file name");
		return NULL;
	}

	if (sprintf(file_name,"%s@%d.odc", column_name, version_number) < 0)
	{
		obi_set_errno(OBICOL_MEMORY_ERROR);
		obidebug(1, "\nError building a column file name");
		return NULL;
	}

	return file_name;
}


static char* build_version_file_name(const char* column_name)
{
	char* file_name;

	// Build the file name
	file_name =	(char*) malloc((strlen(column_name) + 5)*sizeof(char));
	if (file_name == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating the memory for a version file name");
		return NULL;
	}

	if (sprintf(file_name,"%s.odv", column_name) < 0)
	{
		obi_set_errno(OBICOL_MEMORY_ERROR);
		obidebug(1, "\nError building a version file name");
		return NULL;
	}

	return file_name;
}


static obiversion_t obi_get_new_version_number(OBIDMS_column_directory_p column_directory, bool block)
{
	off_t 			loc_size;
	obiversion_t 	new_version_number;
	char* 			version_file_name;
	int    			version_file_descriptor;
	int 			lock_mode;
	char* 			column_directory_name;
	DIR* 			col_directory;
	int 			col_dir_fd;

	new_version_number = 0;
	loc_size = sizeof(obiversion_t);

	// Select the correct lockf operation according to the blocking mode
	if (block)
		lock_mode=F_LOCK;
	else
		lock_mode=F_TLOCK;

	// Build the version file name
	version_file_name = build_version_file_name(column_directory->column_name);
	if (version_file_name == NULL)
		return -1;

	// Open the version file
	column_directory_name = obi_build_column_directory_name(column_directory->column_name);
	if (column_directory_name == NULL)
	{
		obi_set_errno(OBICOLDIR_UNKNOWN_ERROR);
		obidebug(1, "\nError opening a version file");
		free(version_file_name);
		return -1;
	}
	col_directory = opendir_in_dms(column_directory->dms, column_directory_name);
	if (col_directory == NULL)
	{
		obi_set_errno(OBICOLDIR_UNKNOWN_ERROR);
		obidebug(1, "\nError opening a version file");
		free(version_file_name);
		free(column_directory_name);
		return -1;
	}
	col_dir_fd = dirfd(col_directory);
	if (col_dir_fd < 0)
	{
		obi_set_errno(OBICOLDIR_UNKNOWN_ERROR);
		obidebug(1, "\nError opening a version file");
		free(version_file_name);
		free(column_directory_name);
		closedir(col_directory);
		return -1;
	}
	version_file_descriptor = openat(col_dir_fd, version_file_name, O_RDWR);
	if (version_file_descriptor < 0)
	{
		if (errno == ENOENT)
		{
			free(version_file_name);
			free(column_directory_name);
			closedir(col_directory);
			return create_version_file(column_directory);
		}
		else
		{
			obi_set_errno(OBICOL_UNKNOWN_ERROR);
			obidebug(1, "\nError opening a version file");
			free(column_directory_name);
			closedir(col_directory);
			free(version_file_name);
			return -1;
		}
	}

	free(version_file_name);
	free(column_directory_name);
	if (closedir(col_directory) < 0)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError opening a version file");
		close(version_file_descriptor);
		return -1;
	}

	// Test if the version file size is ok
	if (lseek(version_file_descriptor, 0, SEEK_END) < loc_size)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError testing if a version file size is ok");
		close(version_file_descriptor);
		return -1;
	}

	// Reset offset to 0
	if (lseek(version_file_descriptor, 0, SEEK_SET) != 0)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError positioning offset in version file");
		close(version_file_descriptor);
		return -1;
	}

	// Lock the file
	if (lockf(version_file_descriptor, lock_mode, loc_size) < 0)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError locking a version file");
		close(version_file_descriptor);
		return -1;
	}

    // Read the current version number
    if (read(version_file_descriptor, &new_version_number, sizeof(obiversion_t)) < ((ssize_t) sizeof(obiversion_t)))
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError reading a version file");
		close(version_file_descriptor);
		return -1;
	}

    new_version_number++;

    // Reset offset to 0 to write the new version number
	if (lseek(version_file_descriptor, 0, SEEK_SET) != 0)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError positioning offset in version file");
		close(version_file_descriptor);
		return -1;
	}

    // Write the new version number
	if (write(version_file_descriptor, &new_version_number, sizeof(obiversion_t)) < ((ssize_t) sizeof(obiversion_t)))
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError writing a new version number in a version file");
		close(version_file_descriptor);
		return -1;
	}

	// Reset offset to 0 (TODO: why?)
	if (lseek(version_file_descriptor, 0, SEEK_SET) != 0)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError positioning offset in version file");
		close(version_file_descriptor);
		return -1;
	}

	// Unlock the file
	if (lockf(version_file_descriptor, F_ULOCK, loc_size) < 0)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError unlocking a version file");
		close(version_file_descriptor);
		return -1;
	}

	if (close(version_file_descriptor) < 0)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError closing a version file");
		return -1;
	}

	return new_version_number;
}


static obiversion_t create_version_file(OBIDMS_column_directory_p column_directory)
{
	off_t 			loc_size;
	obiversion_t 	version_number;
	char* 			version_file_name;
	int    			version_file_descriptor;
	char* 			column_directory_name;
	DIR* 			col_directory;
	int 			col_dir_fd;

	loc_size = sizeof(obiversion_t);
	version_number = 0;

	version_file_name = build_version_file_name(column_directory->column_name);
	if (version_file_name == NULL)
		return -1;

	// Get the file descriptor associated to the version file
	column_directory_name = obi_build_column_directory_name(column_directory->column_name);
	if (column_directory_name == NULL)
	{
		obi_set_errno(OBICOLDIR_UNKNOWN_ERROR);
		obidebug(1, "\nError opening a version file");
		free(version_file_name);
		return -1;
	}
	col_directory = opendir_in_dms(column_directory->dms, column_directory_name);
	if (col_directory == NULL)
	{
		obi_set_errno(OBICOLDIR_UNKNOWN_ERROR);
		obidebug(1, "\nError opening a version file");
		free(version_file_name);
		free(column_directory_name);
		return -1;
	}
	col_dir_fd = dirfd(col_directory);
	if (col_dir_fd < 0)
	{
		obi_set_errno(OBICOLDIR_UNKNOWN_ERROR);
		obidebug(1, "\nError opening a version file");
		free(version_file_name);
		free(column_directory_name);
		closedir(col_directory);
		return -1;
	}
	version_file_descriptor = openat(col_dir_fd, version_file_name, O_RDWR | O_CREAT | O_EXCL, 0777);
	if (version_file_descriptor < 0)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError opening a version file");
		free(version_file_name);
		return -1;
	}

	free(version_file_name);
	free(column_directory_name);
	closedir(col_directory);

	// Lock the file
	if (lockf(version_file_descriptor, F_LOCK, loc_size) < 0)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError locking a version file");
		close(version_file_descriptor);
		return -1;
	}

	// Truncate the version file to the right size
	if (ftruncate(version_file_descriptor, loc_size) < 0)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError truncating a version file");
		close(version_file_descriptor);
		return -1;
	}

	// Position offset to 0 to prepare for writing		// TODO Unnecessary?
	if (lseek(version_file_descriptor, 0, SEEK_SET) != 0)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError changing offset of a version file");
		close(version_file_descriptor);
		return -1;
	}

	// Write version number
	if (write(version_file_descriptor, &version_number, sizeof(obiversion_t)) < ((ssize_t) sizeof(obiversion_t)))
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError writing version number in a version file");
		close(version_file_descriptor);
		return -1;
	}

	// Prepare for unlocking
	if (lseek(version_file_descriptor, 0, SEEK_SET) != 0)		// TODO Unnecessary?
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError preparing a version file for unlocking");
		close(version_file_descriptor);
		return -1;
	}

	// Unlock the file
	if (lockf(version_file_descriptor, F_ULOCK, loc_size) < 0)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError unlocking a version file");
		close(version_file_descriptor);
		return -1;
	}

	if (close(version_file_descriptor) < 0)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError closing a version file");
		return -1;
	}

	return version_number;
}



static char* build_default_elements_names(index_t nb_elements_per_line)
{
	char* elements_names;
	int   i;
	int   len;

//	if (nb_elements_per_line > NB_ELTS_MAX_IF_DEFAULT_NAME)
//	{
//		obi_set_errno(OBICOL_UNKNOWN_ERROR);
//		obidebug(1, "\nError: too many elements per line to use the default names (max = %d elements)", NB_ELTS_MAX_IF_DEFAULT_NAME);
//		return NULL;
//	}

	// TODO
	elements_names = (char*) malloc(nb_elements_per_line * 10 * sizeof(char));
	if (elements_names == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating memory for elements names");
		return NULL;
	}

	len = 0;
	for (i = 0; i < nb_elements_per_line; i++)
		len += sprintf(elements_names+len, "%d;", i);

	// Terminal character
	elements_names[len-1] = '\0';	// -1 to delete last ';'
	len--;

	return elements_names;
}



static void format_elements_names(char* elements_names)
{
	int     i;
	int64_t elts_names_length;

	elts_names_length = strlen(elements_names);

	// Replace the ';' with '\0'
	for (i=0; i < elts_names_length; i++)
	{
		if (elements_names[i] == ';')
			elements_names[i] = '\0';
	}
}



static int cmp_elements_names_with_idx(const void* n1_sort_idx, const void* n2_sort_idx, const void* h)
{
	char* name1=NULL;
	char* name2=NULL;

	index_t name1_idx;
	index_t name2_idx;

	index_t name1_sort_idx = *((index_t*)n1_sort_idx);
	index_t name2_sort_idx = *((index_t*)n2_sort_idx);
	OBIDMS_column_header_p header = (OBIDMS_column_header_p) h;

	name1_idx = (header->elements_names_idx)[name1_sort_idx];
	name1 = (header->elements_names)+name1_idx;

	name2_idx = (header->elements_names_idx)[name2_sort_idx];
	name2 = (header->elements_names)+name2_idx;

	return strcmp(name1, name2);
}



static int cmp_elements_names_with_name_and_idx(const void* name1, const void* n2_sort_idx, const void* h)
{
	char*   name2=NULL;
	index_t name2_idx;

	index_t name2_sort_idx = *((index_t*)n2_sort_idx);
	OBIDMS_column_header_p header = (OBIDMS_column_header_p) h;

	name2_idx = (header->elements_names_idx)[name2_sort_idx];
	name2 = (header->elements_names)+name2_idx;

	return strcmp(name1, name2);
}


static int set_elements_names(OBIDMS_column_p column, char* elements_names, int64_t elts_names_length, index_t nb_elements)
{
	OBIDMS_column_header_p header;
	index_t                i, j;

	header = column->header;

	// Store the length of the character array containing the elements names
	header->elements_names_length = elts_names_length;
	// Store the pointers pointing to the different elements stored in the memory arena
	header->elements_names = (char*)&(header->mem_arena)[0];
	header->elements_names_idx = (index_t*)&((char*)(header->mem_arena) + elts_names_length)[0];
	header->sorted_elements_idx = (header->elements_names_idx) + nb_elements;

	// Copy the elements names in the header
	memcpy(header->elements_names, elements_names, (elts_names_length-2)*sizeof(char));

	// Terminal characters
	header->elements_names[elts_names_length - 2] = '\0';
	header->elements_names[elts_names_length - 1] = '\0';

	// Build the elements names index
	i = 0;
	j = 0;
	// Index the first element name
	(header->elements_names_idx)[j] = i;
	(header->sorted_elements_idx)[j] = j;
	i++;
	j++;

	while (i < elts_names_length-2)
	{
		if (elements_names[i] == '\0')
		{	// Index new element name
			(header->elements_names_idx)[j] = i+1;
			(header->sorted_elements_idx)[j] = j;
			j++;
		}
		i++;
	}

	// Build the sorted index
	qsort_user_data(header->sorted_elements_idx, j, sizeof(index_t), column->header, cmp_elements_names_with_idx);

	return 0;
}



static void read_elt_names_informations(OBIDMS_column_header_p header)
{
	int64_t elts_names_length;

	elts_names_length = header->elements_names_length;
	header->elements_names = (char*)&(header->mem_arena)[0];
	header->elements_names_idx = (index_t*)&((char*)(header->mem_arena) + elts_names_length)[0];
	header->sorted_elements_idx = (index_t*)&((header->elements_names_idx) + (header->nb_elements_per_line))[0];
}



static index_t check_elt_names_count(const char* elements_names, bool elt_names_formatted)
{
	char    sep;
	int     i = 0;
	bool    stop = false;
	index_t count = 0;

	if (elt_names_formatted)
		sep = FORMATTED_ELT_NAMES_SEPARATOR;
	else
		sep = NOT_FORMATTED_ELT_NAMES_SEPARATOR;

	while (! stop)
	{
		if ((elt_names_formatted && (elements_names[i] == '\0') && (elements_names[i+1] == '\0')) ||
				((! elt_names_formatted) && (elements_names[i] == '\0')))
			stop = true;
		if ((elements_names[i] == sep) || (elements_names[i] == '\0'))
			count++;
		i++;
	}

	return count;
}



static int get_formatted_elt_names_length(const char* elements_names, index_t nb_elements)
{
	int     i = 0;
	index_t n = 0;

	while (n < nb_elements)
	{
		if (elements_names[i] == '\0')
			n++;
		i++;
	}

	return i+1;
}



static index_t get_line_count_per_page(OBIType_t data_type, index_t nb_elements_per_line)
{
	return getpagesize() / obi_sizeof(data_type) / nb_elements_per_line;
}


/**********************************************************************
 *
 * D E F I N I T I O N   O F   T H E   P U B L I C   F U N C T I O N S
 *
 **********************************************************************/


char* obi_version_file_full_path(OBIDMS_p dms, const char* column_name)
{
	char* version_file_name;
	char* column_dir_name;
	char* relative_path;
	char* full_path;

	version_file_name = build_version_file_name(column_name);
	if (version_file_name == NULL)
		return NULL;

	column_dir_name = obi_build_column_directory_name(column_name);
	if (column_dir_name == NULL)
		return NULL;

	relative_path = (char*) malloc(strlen(version_file_name) + strlen(column_dir_name) + 2);

	strcpy(relative_path, column_dir_name);
	strcat(relative_path, "/");
	strcat(relative_path, version_file_name);

	// Build path relative to DMS
	full_path = obi_dms_get_full_path(dms, relative_path);

	free(version_file_name);
	free(column_dir_name);
	free(relative_path);

	return full_path;
}


char* obi_column_full_path(OBIDMS_p dms, const char* column_name, obiversion_t version_number)
{
	char* column_file_name;
	char* column_dir_name;
	char* relative_path;
	char* full_path;


	column_file_name = build_column_file_name(column_name, version_number);
	if (column_file_name == NULL)
		return NULL;

	column_dir_name = obi_build_column_directory_name(column_name);
	if (column_dir_name == NULL)
		return NULL;

	relative_path = (char*) malloc(strlen(column_file_name) + strlen(column_dir_name) + 2);

	strcpy(relative_path, column_dir_name);
	strcat(relative_path, "/");
	strcat(relative_path, column_file_name);

	// Build path relative to DMS
	full_path = obi_dms_get_full_path(dms, relative_path);

	free(column_file_name);
	free(column_dir_name);
	free(relative_path);

	return full_path;
}


obiversion_t obi_get_latest_version_number(OBIDMS_column_directory_p column_directory)
{
	off_t 			loc_size;
	obiversion_t 	latest_version_number;
	char * 			version_file_name;
	int    			version_file_descriptor;
	char*			column_directory_name;
	DIR*			col_directory;
	int				col_dir_fd;

	loc_size = sizeof(obiversion_t);
	latest_version_number = 0;

	version_file_name = build_version_file_name(column_directory->column_name);
	if (version_file_name==NULL)
		return -1;

	// Get the file descriptor associated to the version file
	column_directory_name = obi_build_column_directory_name(column_directory->column_name);
	if (column_directory_name == NULL)
	{
		obi_set_errno(OBICOLDIR_UNKNOWN_ERROR);
		obidebug(1, "\nError opening a version file");
		free(version_file_name);
		return -1;
	}
	col_directory = opendir_in_dms(column_directory->dms, column_directory_name);
	if (col_directory == NULL)
	{
		obi_set_errno(OBICOLDIR_UNKNOWN_ERROR);
		obidebug(1, "\nError opening a version file");
		free(version_file_name);
		free(column_directory_name);
		return -1;
	}
	col_dir_fd = dirfd(col_directory);
	if (col_dir_fd < 0)
	{
		obi_set_errno(OBICOLDIR_UNKNOWN_ERROR);
		obidebug(1, "\nError opening a version file");
		free(version_file_name);
		free(column_directory_name);
		closedir(col_directory);
		return -1;
	}
	version_file_descriptor = openat(col_dir_fd, version_file_name, O_RDONLY);
	if (version_file_descriptor < 0)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError opening a version file");
		free(version_file_name);
		return -1;
	}

	free(version_file_name);
	free(column_directory_name);
	closedir(col_directory);

	// Check that the version file size is ok
	if (lseek(version_file_descriptor, 0, SEEK_END) < loc_size)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError testing if a version file size is ok");
		close(version_file_descriptor);
		return -1;
	}

	// Set the offset to 0 in the version file
	if (lseek(version_file_descriptor, 0, SEEK_SET) != 0)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError setting the offset of a version file to 0");
		close(version_file_descriptor);
		return -1;
	}

    // Read the latest version number
    if (read(version_file_descriptor, &latest_version_number, sizeof(obiversion_t)) < ((ssize_t) sizeof(obiversion_t)))
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError reading the latest version number in a version file");
		close(version_file_descriptor);
		return -1;
	}

	if (close(version_file_descriptor) < 0)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError closing a version file");
		return -1;
	}

	return latest_version_number;
}



obiversion_t obi_column_get_latest_version_from_name(OBIDMS_p dms, const char* column_name)
{
	OBIDMS_column_directory_p	column_directory;
	obiversion_t	   			latest_version;

	// Get the column directory structure associated to the column
	column_directory = obi_open_column_directory(dms, column_name);
	if (column_directory == NULL)
	{
		obidebug(1, "\nProblem opening a column directory structure");
		return -1;
	}

	// Get the latest version number
	latest_version = obi_get_latest_version_number(column_directory);
	if (latest_version < 0)
	{
		obidebug(1, "\nProblem getting the latest version number in a column directory");
		return -1;
	}

	return latest_version;
}


// TODO make private
size_t obi_calculate_header_size(index_t nb_elements_per_line, int64_t elts_names_length)
{
	size_t header_size;
	size_t rounded_header_size;
	double multiple;

	header_size = sizeof(OBIDMS_column_header_t);
	header_size = header_size + (nb_elements_per_line*2)*sizeof(int64_t) + elts_names_length*sizeof(char);

	multiple = 	ceil((double) header_size / (double) getpagesize());

	rounded_header_size = multiple * getpagesize();

	return rounded_header_size;
}


OBIDMS_column_p obi_create_column(OBIDMS_p     dms,
		                          const char*  column_name,
								  OBIType_t    data_type,
								  index_t      nb_lines,
								  index_t      nb_elements_per_line,
								  char*        elements_names,
								  bool		   elt_names_formatted,
								  bool		   tuples,
								  bool         to_eval,
								  const char*  indexer_name,
								  const char*  associated_column_name,
								  obiversion_t associated_column_version,
								  const char*  comments
								 )
{
	OBIDMS_column_p 			new_column;
	OBIDMS_column_directory_p	column_directory;
	OBIDMS_column_header_p 		header;
	size_t 						file_size;
	obiversion_t 				version_number;
	char* 						column_file_name;
	int 						column_file_descriptor;
	size_t 						header_size;
	size_t 						data_size;
	int 						comments_ok;
	index_t						minimum_line_count;
	OBIType_t  					returned_data_type;
	OBIType_t  					stored_data_type;
	char*			    		final_indexer_name = NULL;
	char*						built_elements_names = NULL;
	int64_t						elts_names_length;
	char*                       column_directory_name;
	DIR*						col_dir;
	int							col_dir_fd;

	new_column = NULL;

	// Check that the informations given are not NULL/invalid/greater than the allowed sizes
	if (dms == NULL)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nCan't create column because of invalid DMS");
		return NULL;
	}
	if (column_name == NULL)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nCan't create column because of empty column name");
		return NULL;
	}
	if (nb_elements_per_line < 1)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nCan't create column: the number of elements per line can't be less than 1");
		return NULL;
	}
	if ((data_type < 1) || (data_type > 8))		// TODO check in more robust way ?
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nCan't create column because of invalid data type");
		return NULL;
	}

	// Get the column directory structure associated to the column
	column_directory = obi_column_directory(dms, column_name);
	if (column_directory == NULL)
	{
		obi_set_errno(OBICOLDIR_UNKNOWN_ERROR);
		obidebug(1, "\nError opening a column directory structure");
		return NULL;
	}

	// Get the latest version number
	version_number = obi_get_new_version_number(column_directory, true);
	if (version_number < 0)
	{
		return NULL;
	}

	// Build the indexer name if needed
	if ((data_type == OBI_STR) || (data_type == OBI_SEQ) || (data_type == OBI_QUAL) || tuples)
	{
		if ((indexer_name == NULL) || (*indexer_name == 0))
		{
			final_indexer_name = obi_build_indexer_name(column_name, version_number);
			if (final_indexer_name == NULL)
				return NULL;
		}
		else
		{
			final_indexer_name = (char*) malloc((strlen(indexer_name)+1)*sizeof(char));
			strcpy(final_indexer_name, indexer_name);
		}
	}

	returned_data_type = data_type;
	if ((data_type == OBI_STR) || (data_type == OBI_SEQ) || (data_type == OBI_QUAL) || tuples)
	// stored data is indices referring to data stored elsewhere
		stored_data_type = OBI_IDX;
	else
		stored_data_type = returned_data_type;

	// The initial line count should be between the minimum (corresponding to the page size) and the maximum allowed
	minimum_line_count = get_line_count_per_page(stored_data_type, nb_elements_per_line);
	if (minimum_line_count == 0)	// Happens if high number of elements per line
		minimum_line_count = 1;
	if (nb_lines > MAXIMUM_LINE_COUNT)
	{
		obidebug(1, "\nCan't create column because of line count greater than the maximum allowed (%d)", MAXIMUM_LINE_COUNT);
		return NULL;
	}
	else if (nb_lines < minimum_line_count)
		nb_lines = minimum_line_count;

	// Check, format, and build if needed the element names
	if ((elements_names == NULL) || (*elements_names == '\0'))	// Build the default element names
	{
		built_elements_names = build_default_elements_names(nb_elements_per_line);
		if (built_elements_names == NULL)
			return NULL;
		elements_names = built_elements_names;
	}
	else
	{ // The number of elements names should be equal to the number of elements per line
		if (check_elt_names_count(elements_names, elt_names_formatted) != nb_elements_per_line)
		{
			obidebug(1, "\nCan't create column because the number of elements names given is not equal to the number of elements per line:"
					"\n%lld elements per line\nelements names:%s\n", nb_elements_per_line, elements_names);
			return NULL;
		}
	}

	// Format the elements names string
	if (! elt_names_formatted)
		format_elements_names(elements_names);
	elts_names_length = get_formatted_elt_names_length(elements_names, nb_elements_per_line);

	// Calculate the size needed
	header_size = obi_calculate_header_size(nb_elements_per_line, elts_names_length);
	data_size = obi_array_sizeof(stored_data_type, nb_lines, nb_elements_per_line);
	file_size = header_size + data_size;

	// Get the column file name
	column_file_name = build_column_file_name(column_name, version_number);
	if (column_file_name == NULL)
		return NULL;

	// Open the column file
	column_directory_name = obi_build_column_directory_name(column_directory->column_name);
	if (column_directory_name == NULL)
	{
		obi_set_errno(OBICOLDIR_UNKNOWN_ERROR);
		obidebug(1, "\nError opening a column file");
		free(column_file_name);
		return NULL;
	}
	col_dir = opendir_in_dms(dms, column_directory_name);
	if (col_dir == NULL)
	{
		obi_set_errno(OBICOLDIR_UNKNOWN_ERROR);
		obidebug(1, "\nError opening a version file");
		free(column_file_name);
		free(column_directory_name);
		return NULL;
	}
	col_dir_fd = dirfd(col_dir);
	if (col_dir_fd < 0)
	{
		obi_set_errno(OBICOLDIR_UNKNOWN_ERROR);
		obidebug(1, "\nError opening a version file");
		free(column_file_name);
		free(column_directory_name);
		closedir(col_dir);
		return NULL;
	}

	column_file_descriptor = openat(col_dir_fd, column_file_name, O_RDWR | O_CREAT | O_EXCL, 0777);
	if (column_file_descriptor < 0)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError opening a column file %s", column_file_name);
		free(column_file_name);
		free(column_directory_name);
		closedir(col_dir);
		return NULL;
	}

	free(column_file_name);
	free(column_directory_name);
	if (closedir(col_dir) < 0)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError closing a column directory");
		close(column_file_descriptor);
		return NULL;
	}

	// Truncate the column file to the right size
	if (ftruncate(column_file_descriptor, file_size) < 0)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError truncating a column file to the right size");
		close(column_file_descriptor);
		return NULL;
	}

	// Allocate the memory for the column structure
	new_column = (OBIDMS_column_p) malloc(sizeof(OBIDMS_column_t));
	if (new_column == NULL)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError allocating the memory for the column structure");
		close(column_file_descriptor);
		return NULL;
	}

	// Fill the column structure
	new_column->dms    			 = dms;
	new_column->column_directory = column_directory;
	new_column->header 			 = mmap(NULL,
			                  	  	    header_size,
			                  	  	    PROT_READ | PROT_WRITE,
			                  	  	    MAP_SHARED,
			                  	  	    column_file_descriptor,
			                  	  	    0
			                 	 	   );

	if (new_column->header == MAP_FAILED)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError mmapping the header of a column");
		close(column_file_descriptor);
		free(new_column);
		return NULL;
	}

	new_column->data   			 = mmap(NULL,
			                 	 	 	data_size,
			                 	 	 	PROT_READ | PROT_WRITE,
			                 	 	 	MAP_SHARED,
			                 	 	 	column_file_descriptor,
			                 	 	 	header_size
			                			);

	if (new_column->data == MAP_FAILED)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError mmapping the data of a column.\nArguments: data_size=%lu, column_file_descriptor=%d, header_size=%lu",
				data_size, column_file_descriptor, header_size);
		munmap(new_column->header, header_size);
		close(column_file_descriptor);
		free(new_column);
		return NULL;
	}

	new_column->writable = true;

	header 				  		 		  = new_column->header;
	header->header_size   		   		  = header_size;
	header->data_size			 		  = data_size;
	header->line_count   	 	 		  = nb_lines;
	header->lines_used    		          = 0;
	header->nb_elements_per_line          = nb_elements_per_line;
	header->stored_data_type     		  = stored_data_type;
	header->returned_data_type   		  = returned_data_type;
	header->tuples     					  = tuples;
	header->to_eval                       = to_eval;
	header->creation_date 		 		  = time(NULL);
	header->version       		          = version_number;
	header->cloned_from    		          = -1;
	header->finished 					  = false;

	set_elements_names(new_column, elements_names, elts_names_length, nb_elements_per_line);
	read_elt_names_informations(header);

	// Free the element names if they were built
	if (built_elements_names != NULL)
		free(built_elements_names);

	strncpy(header->name, column_name, OBIDMS_COLUMN_MAX_NAME);

	// Comments must be a json string, even empty
	if ((comments == NULL) || (strcmp(comments, "") == 0))
		comments_ok = obi_column_write_comments(new_column, "{}");
	else
		comments_ok = obi_column_write_comments(new_column, comments);
	if (comments_ok < 0)
	{
		obidebug(1, "\nError writing comments in new column");
		munmap(new_column->header, header_size);
		close(column_file_descriptor);
		free(new_column);
		return NULL;
	}

	// Store the associated column reference if needed // TODO discuss cases
	if (data_type == OBI_QUAL)
	{
		if ((associated_column_name == NULL) || (*associated_column_name == '\0'))
		{
			obidebug(1, "\nError: The name of the associated column when creating a new column is NULL");
			munmap(new_column->header, header_size);
			close(column_file_descriptor);
			free(new_column);
			return NULL;
		}
		strcpy((header->associated_column).column_name, associated_column_name);

		if (associated_column_version == -1)
		{
			obidebug(1, "\nError: The version of the associated column when creating a new column is not defined");
			munmap(new_column->header, header_size);
			close(column_file_descriptor);
			free(new_column);
			return NULL;
		}
		(header->associated_column).version = associated_column_version;
	}

	// If the data type is OBI_STR, OBI_SEQ or OBI_QUAL, the associated obi_indexer is opened or created
	if ((returned_data_type == OBI_STR) || (returned_data_type == OBI_SEQ) || (returned_data_type == OBI_QUAL) || tuples)
	{
		new_column->indexer = obi_indexer(dms, final_indexer_name);
		if (new_column->indexer == NULL)
		{
			obidebug(1, "\nError opening or creating the indexer associated with a column");
			munmap(new_column->header, header_size);
			close(column_file_descriptor);
			free(new_column);
			return NULL;
		}
		strncpy(header->indexer_name, final_indexer_name, INDEXER_MAX_NAME);
	}

	// Fill the data with NA values
	obi_ini_to_NA_values(new_column, 0, nb_lines);

	if (close(column_file_descriptor) < 0)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError closing a column file");
		return NULL;
	}

	// Add in the list of opened columns
	obi_dms_list_column(dms, new_column);

	// Set counter to 1 // TODO Discuss counters
	new_column->counter = 1;

	return new_column;
}



OBIDMS_column_p obi_open_column(OBIDMS_p     dms,
								const char*  column_name,
								obiversion_t version_number)
{
	OBIDMS_column_p 		    column;
	OBIDMS_column_directory_p	column_directory;
	char* 						column_file_name;
	int 						column_file_descriptor;
	size_t 						header_size;
	char*						column_directory_name;
	DIR*						col_dir;
	int							col_dir_fd;

	column = NULL;

	// Get the column directory structure associated to the column
	column_directory = obi_open_column_directory(dms, column_name);
	if (column_directory == NULL)
	{
		obidebug(1, "\nError opening a column directory structure");
		return NULL;
	}

	// Get the latest version number if it has the value -1 (not given by user)
	if (version_number == -1)
	{
		version_number = obi_get_latest_version_number(column_directory);
		if (version_number < 0)
		{
			obidebug(1, "\nError getting the latest version number in a column directory");
			return NULL;
		}
	}

	// Check if the column is already in the list of opened columns
	column = obi_dms_get_column_from_list(dms, column_name, version_number);
	// If it's found, increment its counter and return it
	if (column != NULL)
	{
		(column->counter)++;
		if (obi_close_column_directory(column_directory) < 0)
		{
			obi_set_errno(OBICOL_UNKNOWN_ERROR);
			obidebug(1, "\nError closing a column directory");
			return NULL;
		}
		return column;
	}

	// Get the column file name
	column_file_name = build_column_file_name(column_name, version_number);
	if (column_file_name == NULL)
	{
		return NULL;
	}

	// Open the column file, ALWAYS READ-ONLY
	column_directory_name = obi_build_column_directory_name(column_directory->column_name);
	if (column_directory_name == NULL)
	{
		obi_set_errno(OBICOLDIR_UNKNOWN_ERROR);
		obidebug(1, "\nError opening a column file");
		free(column_file_name);
		return NULL;
	}

	col_dir = opendir_in_dms(dms, column_directory_name);
	if (col_dir == NULL)
	{
		obi_set_errno(OBICOLDIR_UNKNOWN_ERROR);
		obidebug(1, "\nError opening a version file");
		free(column_file_name);
		free(column_directory_name);
		return NULL;
	}

	col_dir_fd = dirfd(col_dir);
	if (col_dir_fd < 0)
	{
		obi_set_errno(OBICOLDIR_UNKNOWN_ERROR);
		obidebug(1, "\nError opening a version file");
		free(column_file_name);
		free(column_directory_name);
		closedir(col_dir);
		return NULL;
	}

	column_file_descriptor = openat(col_dir_fd, column_file_name, O_RDWR);
	if (column_file_descriptor < 0)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError opening column file %s", column_file_name);
		free(column_file_name);
		free(column_directory_name);
		closedir(col_dir);
		return NULL;
	}

	free(column_file_name);
	free(column_directory_name);
	if (closedir(col_dir) < 0)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError closing a column directory");
		close(column_file_descriptor);
		return NULL;
	}

	// Allocate the memory for the column structure
	column = (OBIDMS_column_p) malloc(sizeof(OBIDMS_column_t));
	if (column == NULL)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError allocating the memory for a column structure");
		close(column_file_descriptor);
		return NULL;
	}

	// Read the header size
	if (read(column_file_descriptor, &header_size, sizeof(size_t)) < ((ssize_t) sizeof(size_t)))
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError reading the header size to open a column");
		close(column_file_descriptor);
		free(column);
		return NULL;
	}

	// Fill the column structure
	column->dms    			 = dms;
	column->column_directory = column_directory;
	column->header 			 = mmap(NULL,
			                  	  	header_size,
									PROT_READ | PROT_WRITE,
			                  	  	MAP_SHARED,
			                  	  	column_file_descriptor,
			                  	  	0
			                 	   );

	if (column->header == MAP_FAILED)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError mmapping the header of a column");
		close(column_file_descriptor);
		free(column);
		return NULL;
	}

	// Set the pointers relative to elements names informations in the header
	read_elt_names_informations(column->header);

	// Map the data
	column->data   			 = mmap(NULL,
			                 	 	(column->header)->data_size,
			                 	 	PROT_READ,
									MAP_SHARED,
			                 	 	column_file_descriptor,
			                 	 	header_size
			                	   );

	if (column->data == MAP_FAILED)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError mmapping the data of a column");
		munmap(column->header, header_size);
		close(column_file_descriptor);
		free(column);
		return NULL;
	}

	column->writable = false;

	// If the data type is OBI_STR, OBI_SEQ or OBI_QUAL or the column contains tuples, the associated indexer is opened
	// TODO maybe store a 'indexer' bool in the header instead
	if (((column->header)->returned_data_type == OBI_STR) || ((column->header)->returned_data_type == OBI_SEQ) || ((column->header)->returned_data_type == OBI_QUAL) || ((column->header)->tuples))
	{
		column->indexer = obi_open_indexer(dms, (column->header)->indexer_name);
		if (column->indexer == NULL)
		{
			obidebug(1, "\nError opening the indexer associated with a column");
			munmap(column->header, header_size);
			close(column_file_descriptor);
			free(column);
			return NULL;
		}
	}

	if (close(column_file_descriptor) < 0)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError closing a column file");
		return NULL;
	}

	// Add in the list of opened columns
	obi_dms_list_column(dms, column);

	// Set counter to 1
	column->counter = 1;

	return column;
}



OBIDMS_column_p obi_clone_column(OBIDMS_p         dms,
								 OBIDMS_column_p  line_selection,
								 const char*      column_name,
								 obiversion_t     version_number,
								 bool 		      clone_data)
{
	OBIDMS_column_p   column_to_clone;
	OBIDMS_column_p   new_column;
	index_t 		  nb_lines = 0;
	index_t			  nb_elements_per_line;
	OBIType_t		  data_type;
	size_t 			  line_size;
	index_t			  i, index;

	column_to_clone = obi_open_column(dms, column_name, version_number);
	if (column_to_clone == NULL)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError opening the column to clone");
		return NULL;
	}

	data_type = (column_to_clone->header)->returned_data_type;

	nb_elements_per_line = (column_to_clone->header)->nb_elements_per_line;

	if (clone_data && (line_selection == NULL))
		nb_lines = (column_to_clone->header)->line_count;
	else if (clone_data && (line_selection != NULL))
		nb_lines = (line_selection->header)->line_count;

	new_column = obi_create_column(dms,
								   column_name,
								   data_type,
								   nb_lines,
								   nb_elements_per_line,
								   (column_to_clone->header)->elements_names,
								   true,
								   (column_to_clone->header)->tuples,
								   (column_to_clone->header)->to_eval,
								   (column_to_clone->header)->indexer_name,
								   ((column_to_clone->header)->associated_column).column_name,
								   ((column_to_clone->header)->associated_column).version,
								   (column_to_clone->header)->comments
								  );

	if (new_column == NULL)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError creating the new column when cloning a column");
		// The new file is deleted TODO check if it exists before
		//const char* column_file_name = build_column_file_name(column_name, version_number);
		//if (remove(column_file_name) < 0)
		//	obidebug(1, "\nError deleting a bad cloned file");
		return NULL;
	}



	(new_column->header)->cloned_from = (column_to_clone->header)->version;

	if (clone_data && (line_selection == NULL))
	{
		if ((new_column->header)->data_size != (column_to_clone->header)->data_size)
		{
			obi_set_errno(OBICOL_UNKNOWN_ERROR);
			obidebug(1, "\nError cloning a column: the sizes of the data source and destination are not equal: source %zu bytes, destination %zu bytes.",
					(column_to_clone->header)->data_size, (new_column->header)->data_size);
			return NULL;
		}
		// Copy all the data to the new column
		memcpy(new_column->data, column_to_clone->data, (column_to_clone->header)->data_size);
		(new_column->header)->lines_used = (column_to_clone->header)->lines_used;
	}
	else if (clone_data && (line_selection != NULL))
	{
		line_size = obi_sizeof((new_column->header)->stored_data_type) * (new_column->header)->nb_elements_per_line;
		// Copy each line at the right index to the new column
		for (i=0; i<((line_selection->header)->lines_used); i++)
		{
			// Get the index in the line selection column
			index = obi_column_get_index_with_elt_idx(line_selection, i, 0);
			// Copy the line at the index in the column to clone to the new column
			memcpy((new_column->data)+(i*line_size), (column_to_clone->data)+(index*line_size), line_size);
		}
		(new_column->header)->lines_used = (line_selection->header)->lines_used;
	}

	// Close column_to_clone
	if (obi_close_column(column_to_clone) < 0)
	{
		obidebug(1, "\nError closing a column that has been cloned");
		// TODO return NULL or not?
	}

	return new_column;
}



int obi_close_column(OBIDMS_column_p column)
{
	int     ret_val = 0;

	// Truncate the column to the number of lines used if it's not read-only
	if (column->writable)
		ret_val = obi_truncate_column(column);

	(column->counter)--;

	if (column->counter == 0)
	{
		// Delete from the list of opened columns
		if (obi_dms_unlist_column(column->dms, column) < 0)
			ret_val = -1;

		// If the data type is OBI_STR, OBI_SEQ or OBI_QUAL, the associated indexer is closed
		if (((column->header)->returned_data_type == OBI_STR) || ((column->header)->returned_data_type == OBI_SEQ) || ((column->header)->returned_data_type == OBI_QUAL))
			if (obi_close_indexer(column->indexer) < 0)
				ret_val = -1;

		// Munmap data
		if (munmap(column->data, (column->header)->data_size) < 0)
		{
			obi_set_errno(OBICOL_UNKNOWN_ERROR);
			obidebug(1, "\nError munmapping column data");
			ret_val = -1;
		}

		// Munmap header
		if (munmap(column->header, (column->header)->header_size) < 0)
		{
			obi_set_errno(OBICOL_UNKNOWN_ERROR);
			obidebug(1, "\nError munmapping a column header");
			ret_val = -1;
		}

		// Close column directory
		if (obi_close_column_directory(column->column_directory) < 0)
			ret_val = -1;

		free(column);
	}

	return ret_val;
}



int obi_clone_column_indexer(OBIDMS_column_p column)
{
	char* new_indexer_name;

	new_indexer_name = obi_build_indexer_name((column->header)->name, (column->header)->version);
	if (new_indexer_name == NULL)
		return -1;

	column->indexer = obi_clone_indexer(column->indexer, new_indexer_name);	// TODO Need to lock this somehow?
	if (column->indexer == NULL)
	{
		obidebug(1, "\nError cloning a column's indexer to make it writable");
		return -1;
	}

	strcpy((column->header)->indexer_name, new_indexer_name);

	free(new_indexer_name);

	return 0;
}



int obi_truncate_column(OBIDMS_column_p column)	// TODO is it necessary to unmap/remap? -> yes the whole file for windows WLS
{
	size_t  file_size;
	size_t  data_size;
	index_t new_line_count;
	double  multiple;
	int 	column_file_descriptor;
	char* 	column_file_name;
	char*   column_directory_name;
	DIR*	col_dir;
	int		col_dir_fd;

	// Check if the column is read-only
	if (!(column->writable))
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError trying to truncate a read-only column");
    	return -1;
	}

	// Compute the new line count = the number of lines used rounded to the nearest greater multiple of page size greater than 0
	multiple = ceil((double) (ONE_IF_ZERO((column->header)->lines_used) * (column->header)->nb_elements_per_line * obi_sizeof((column->header)->stored_data_type)) / (double) getpagesize());
	new_line_count = floor((((int64_t) multiple) * ((int64_t) getpagesize())) / ((column->header)->nb_elements_per_line * obi_sizeof((column->header)->stored_data_type)));

	data_size = obi_array_sizeof((column->header)->stored_data_type, new_line_count, (column->header)->nb_elements_per_line);

	// Check that it is actually greater than the current data size, otherwise no need to truncate
	if ((column->header)->data_size == data_size)
		return 0;
	else if ((column->header)->data_size < data_size)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError truncating a column: The current data size seems smaller than needed.");
		return -1;
	}

	// Get the column file name
	column_file_name = build_column_file_name((column->header)->name, (column->header)->version);
	if (column_file_name == NULL)
		return -1;

	// Open the column file
	column_directory_name = obi_build_column_directory_name(column->column_directory->column_name);
	if (column_directory_name == NULL)
	{
		obi_set_errno(OBICOLDIR_UNKNOWN_ERROR);
		obidebug(1, "\nError opening a column file");
		free(column_file_name);
		return -1;
	}
	col_dir = opendir_in_dms(column->dms, column_directory_name);
	if (col_dir == NULL)
	{
		obi_set_errno(OBICOLDIR_UNKNOWN_ERROR);
		obidebug(1, "\nError opening a column file");
		free(column_file_name);
		free(column_directory_name);
		return -1;
	}
	col_dir_fd = dirfd(col_dir);
	if (col_dir_fd < 0)
	{
		obi_set_errno(OBICOLDIR_UNKNOWN_ERROR);
		obidebug(1, "\nError opening a column file");
		free(column_file_name);
		free(column_directory_name);
		closedir(col_dir);
		return -1;
	}
	column_file_descriptor = openat(col_dir_fd, column_file_name, O_RDWR);
	if (column_file_descriptor < 0)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError getting the file descriptor of a column file");
		free(column_file_name);
		free(column_directory_name);
		closedir(col_dir);
		return -1;
	}

	free(column_file_name);
	free(column_directory_name);
	if (closedir(col_dir) < 0)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError closing a column directory");
		close(column_file_descriptor);
		return -1;
	}

	// Unmap the data before truncating the file
	if (munmap(column->data, (column->header)->data_size) < 0)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError munmapping the data of a column before truncating");
		close(column_file_descriptor);
		return -1;
	}

	// Truncate the column file
	file_size = (column->header)->header_size + data_size;
	if (ftruncate(column_file_descriptor, file_size) < 0)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError truncating a column file at the number of lines used");
		close(column_file_descriptor);
		return -1;
	}

	// Remap the data
	column->data = mmap(NULL,
						data_size,
						PROT_READ | PROT_WRITE,
						MAP_SHARED,
						column_file_descriptor,
						(column->header)->header_size
					   );

	if (column->data == MAP_FAILED)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError re-mmapping the data of a column after truncating");
		close(column_file_descriptor);
		return -1;
	}

	// Set new line_count and new data size
	(column->header)->line_count = new_line_count;
	(column->header)->data_size = data_size;

	if (close(column_file_descriptor) < 0)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError closing a column file");
		return -1;
	}

	return 0;
}



int obi_enlarge_column(OBIDMS_column_p column)
{
	size_t  file_size;
	size_t  old_data_size;
	size_t  new_data_size;
	size_t  header_size;
	index_t old_line_count;
	index_t new_line_count;
	int 	column_file_descriptor;
	char* 	column_file_name;
	char*	column_directory_name;
	DIR*	col_dir;
	int		col_dir_fd;

	// Check if the column is read-only
	if (!(column->writable))
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError trying to enlarge a read-only column");
    	return -1;
	}

	// Get the column file name
	column_file_name = build_column_file_name((column->header)->name, (column->header)->version);
	if (column_file_name == NULL)
	{
		return -1;
	}

	// Open the column file
	column_directory_name = obi_build_column_directory_name(column->column_directory->column_name);
	if (column_directory_name == NULL)
	{
		obi_set_errno(OBICOLDIR_UNKNOWN_ERROR);
		obidebug(1, "\nError opening a column file");
		free(column_file_name);
		return -1;
	}
	col_dir = opendir_in_dms(column->dms, column_directory_name);
	if (col_dir == NULL)
	{
		obi_set_errno(OBICOLDIR_UNKNOWN_ERROR);
		obidebug(1, "\nError opening a column file");
		free(column_file_name);
		free(column_directory_name);
		return -1;
	}
	col_dir_fd = dirfd(col_dir);
	if (col_dir_fd < 0)
	{
		obi_set_errno(OBICOLDIR_UNKNOWN_ERROR);
		obidebug(1, "\nError opening a column file");
		free(column_file_name);
		free(column_directory_name);
		closedir(col_dir);
		return -1;
	}

	column_file_descriptor = openat(col_dir_fd, column_file_name, O_RDWR);
	if (column_file_descriptor < 0)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError getting the file descriptor of a column file");
		free(column_file_name);
		free(column_directory_name);
		closedir(col_dir);
		return -1;
	}

	free(column_file_name);
	free(column_directory_name);
	if (closedir(col_dir) < 0)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError closing a column directory");
		close(column_file_descriptor);
		return -1;
	}

	// Calculate the new file size
	old_line_count = (column->header)->line_count;
	new_line_count = old_line_count * COLUMN_GROWTH_FACTOR;

	if (new_line_count > MAXIMUM_LINE_COUNT)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError enlarging a column file: new line count greater than the maximum allowed");
		close(column_file_descriptor);
		return -1;
	}
	old_data_size = (column->header)->data_size;
	new_data_size = obi_array_sizeof((column->header)->stored_data_type, new_line_count, (column->header)->nb_elements_per_line);
	header_size = (column->header)->header_size;
	file_size = header_size + new_data_size;

	// Enlarge the file
	if (ftruncate(column_file_descriptor, file_size) < 0)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError enlarging a column file");
		close(column_file_descriptor);
		return -1;
	}

	// Unmap and remap the data
	if (munmap(column->data, old_data_size) < 0)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError munmapping the data of a column before enlarging");
		close(column_file_descriptor);
		return -1;
	}

	column->data  = mmap(NULL,
						 new_data_size,
						 PROT_READ | PROT_WRITE,
						 MAP_SHARED,
						 column_file_descriptor,
						 header_size
						);
	if (column->data == MAP_FAILED)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError re-mmapping the data of a column after enlarging the file");
		close(column_file_descriptor);
		return -1;
	}

	// Set new line count and new data size
	(column->header)->line_count = new_line_count;
	(column->header)->data_size = new_data_size;

	// Initialize new data lines to NA
	obi_ini_to_NA_values(column, old_line_count, new_line_count - old_line_count);

	if (close(column_file_descriptor) < 0)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError closing a column file");
		return -1;
	}

	return 0;
}


int obi_column_write_comments(OBIDMS_column_p column, const char* comments)
{
	if (comments == NULL)
		return 0;	// TODO or error? or set to empty string? discuss

	if (strlen(comments) > COMMENTS_MAX_LENGTH)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError: comments too long (maximum length: %d, length: %lu, comments: %s",
				COMMENTS_MAX_LENGTH, strlen(comments), comments);
		return -1;
	}

	strcpy((column->header)->comments, comments);

	return 0;
}


int obi_column_add_comment(OBIDMS_column_p column, const char* key, const char* value)
{
	char* new_comments = NULL;

	new_comments = obi_add_comment((column->header)->comments, key, value);
	if (new_comments == NULL)
	{
		obidebug(1, "\nError adding a comment in a column, key: %s, value: %s", key, value);
		return -1;
	}

	if (obi_column_write_comments(column, new_comments) < 0)
	{
		obidebug(1, "\nError adding a comment in a column, key: %s, value: %s", key, value);
		return -1;
	}

	return 0;
}


void obi_set_column_to_value(OBIDMS_column_p column,
						  	 index_t first_line_nb,
							 index_t nb_lines,
							 void* value_p)
{
	index_t i, start, end, nb_elements;

	nb_elements = nb_lines*((column->header)->nb_elements_per_line);
	start = first_line_nb*((column->header)->nb_elements_per_line);
	end = start + nb_elements;

	switch ((column->header)->stored_data_type) {

	case OBI_VOID:  break;

	case OBI_INT:   for (i=start;i<end;i++)
					{
						obiint_t value = *((obiint_t*)value_p);
						*(((obiint_t*) (column->data)) + i) = value;
					}
					break;

	case OBI_FLOAT: for (i=start;i<end;i++)
					{
						obifloat_t value = *((obifloat_t*)value_p);
						*(((obifloat_t*) (column->data)) + i) = value;
					}
					break;

	case OBI_BOOL:  for (i=start;i<end;i++)
					{
						obibool_t value = *((obibool_t*)value_p);
						*(((obibool_t*) (column->data)) + i) = value;
					}
					break;

	case OBI_CHAR:  for (i=start;i<end;i++)
					{
						obichar_t value = *((obichar_t*)value_p);
						*(((obichar_t*) (column->data)) + i) = value;
					}
					break;

	case OBI_IDX:   for (i=start;i<end;i++)
					{
						index_t value = *((index_t*)value_p);
						*(((index_t*) (column->data)) + i) = value;
					}
					break;

	case OBI_SEQ:   break;
	case OBI_STR:   break;
	case OBI_QUAL:  break;
	}
}


void obi_ini_to_NA_values(OBIDMS_column_p column,
						  index_t first_line_nb,
						  index_t nb_lines)
{
	index_t i, start, end, nb_elements;

	nb_elements = nb_lines*((column->header)->nb_elements_per_line);
	start = first_line_nb*((column->header)->nb_elements_per_line);
	end = start + nb_elements;

	switch ((column->header)->stored_data_type)
	{
	case OBI_VOID:  // TODO;
					break;

	case OBI_INT:   for (i=start;i<end;i++)
					{
						*(((obiint_t*) (column->data)) + i) = OBIInt_NA;
					}
					break;

	case OBI_FLOAT: for (i=start;i<end;i++)
					{
						*(((obifloat_t*) (column->data)) + i) = OBIFloat_NA;
					}
					break;

	case OBI_BOOL:  for (i=start;i<end;i++)
					{
						*(((obibool_t*) (column->data)) + i) = OBIBool_NA;
					}
					break;

	case OBI_CHAR:  for (i=start;i<end;i++)
					{
						*(((obichar_t*) (column->data)) + i) = OBIChar_NA;
					}
					break;

	case OBI_IDX:   for (i=start;i<end;i++)
					{
						*(((index_t*) (column->data)) + i) = OBIIdx_NA;
					}
					break;
	case OBI_SEQ:   break;
	case OBI_STR:   break;
	case OBI_QUAL:  break;
	}
}



OBIDMS_column_header_p obi_column_get_header_from_name(OBIDMS_p dms, const char* column_name, obiversion_t version_number)
{
	OBIDMS_column_header_p 		header;
	OBIDMS_column_directory_p	column_directory;
	char* 						column_file_name;
	int 						column_file_descriptor;
	size_t 						header_size;
	char*						column_directory_name;
	DIR*						col_dir;
	int							col_dir_fd;

	// Get the column directory structure associated to the column
	column_directory = obi_open_column_directory(dms, column_name);
	if (column_directory == NULL)
	{
		obidebug(1, "\nError opening a column directory structure");
		return NULL;
	}

	// Get the latest version number if not provided
	if (version_number < 0)
	{
		version_number = obi_get_latest_version_number(column_directory);
		if (version_number < 0)
		{
			obidebug(1, "\nError getting the latest version number in a column directory");
			return NULL;
		}
	}

	// Get the column file name
	column_file_name = build_column_file_name(column_name, version_number);
	if (column_file_name == NULL)
	{
		return NULL;
	}

	// Open the column file
	column_directory_name = obi_build_column_directory_name(column_name);
	if (column_directory_name == NULL)
	{
		obi_set_errno(OBICOLDIR_UNKNOWN_ERROR);
		obidebug(1, "\nError opening a column file");
		free(column_file_name);
		return NULL;
	}

	col_dir = opendir_in_dms(dms, column_directory_name);
	if (col_dir == NULL)
	{
		obi_set_errno(OBICOLDIR_UNKNOWN_ERROR);
		obidebug(1, "\nError opening a column file");
		free(column_file_name);
		free(column_directory_name);
		return NULL;
	}
	col_dir_fd = dirfd(col_dir);
	if (col_dir_fd < 0)
	{
		obi_set_errno(OBICOLDIR_UNKNOWN_ERROR);
		obidebug(1, "\nError opening a column file");
		free(column_file_name);
		free(column_directory_name);
		closedir(col_dir);
		return NULL;
	}
	column_file_descriptor = openat(col_dir_fd, column_file_name, O_RDWR);
	if (column_file_descriptor < 0)
	{
		obidebug(1, "\nError opening a column file");
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		free(column_file_name);
		return NULL;
	}

	free(column_file_name);
	free(column_directory_name);
	if (closedir(col_dir) < 0)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError closing a column directory");
		close(column_file_descriptor);
		return NULL;
	}

	// Read the header size
	if (read(column_file_descriptor, &header_size, sizeof(size_t)) < ((ssize_t) sizeof(size_t)))
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError reading the header size to read a header");
		close(column_file_descriptor);
		return NULL;
	}

	// Map the header structure
	header = mmap(NULL,
			 	  header_size,
				  PROT_READ | PROT_WRITE,
				  MAP_SHARED,
				  column_file_descriptor,
				  0
			 	 );

	if (header == MAP_FAILED)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError mmapping the header of a column");
		close(column_file_descriptor);
		return NULL;
	}

	// Read the element names informations (storing pointers on informations)
	read_elt_names_informations(header);

	if (close(column_file_descriptor) < 0)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError closing a column file");
		return NULL;
	}

	// Close column directory
	if (obi_close_column_directory(column_directory) < 0)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError closing a column directory when reading a column header");
		return NULL;
	}

	return header;
}



int obi_close_header(OBIDMS_column_header_p header)
{
	if (munmap(header, header->header_size) < 0)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError munmapping a column header");
		return -1;
	}
	return 0;
}



index_t obi_column_get_element_index_from_name(OBIDMS_column_p column, const char* element_name)
{
	int* elt_names_idx;

	elt_names_idx = bsearch_user_data(element_name, (column->header)->sorted_elements_idx, (column->header)->nb_elements_per_line, sizeof(index_t), column->header, cmp_elements_names_with_name_and_idx);

	if (elt_names_idx != NULL)
		return (index_t)(*elt_names_idx);

	obi_set_errno(OBI_ELT_IDX_ERROR);
	obidebug(0, "\nError: could not find element name %s", element_name);
	return OBIIdx_NA;
}


char* obi_get_elements_names(OBIDMS_column_p column)
{
	char* elements_names;
	int   i, j;
	int   elt_idx;
	int   len;

	elements_names = (char*) malloc((column->header)->elements_names_length * sizeof(char));
	if (elements_names == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating memory for elements names");
		return NULL;
	}

	j = 0;
	for (i=0; i < (column->header)->nb_elements_per_line; i++)
	{
		elt_idx = ((column->header)->elements_names_idx)[i];
		len = strlen(((column->header)->elements_names)+elt_idx);
		memcpy(elements_names+j, ((column->header)->elements_names)+elt_idx, len*sizeof(char));
		j = j + len;
		elements_names[j] = ';';
		j++;
	}

	elements_names[j - 1] = '\0';

	return elements_names;
}



int obi_column_prepare_to_set_value(OBIDMS_column_p column, index_t line_nb, index_t elt_idx)
{
	// Check if the column is read-only
	if (!(column->writable))
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError trying to set a value in a read-only column");
    	return -1;
	}

	// Check that the line number is not greater than the maximum allowed
	if (line_nb >= MAXIMUM_LINE_COUNT)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError trying to set a value at a line number greater than the maximum allowed");
    	return -1;
	}

	// Check that the element index is not greater than the number of elements per line of the column
	if (elt_idx >= (column->header)->nb_elements_per_line)
	{
		obi_set_errno(OBI_ELT_IDX_ERROR);
		obidebug(0, "\nError trying to set a value at an element index greater than the number of elements per line of the column");
    	return -1;
	}

	// Check if the file needs to be enlarged
	while ((line_nb+1) > (column->header)->line_count)
	{
		// Enlarge the file
		if (obi_enlarge_column(column) < 0)
	    	return -1;
	}

	// Update lines used
	if ((line_nb+1) > (column->header)->lines_used)
		(column->header)->lines_used = line_nb+1;

	return 0;
}



int obi_column_prepare_to_get_value(OBIDMS_column_p column, index_t line_nb)
{
	if ((line_nb+1) > ((column->header)->line_count))
	{
		obi_set_errno(OBI_LINE_IDX_ERROR);
		obidebug(0, "\nError trying to get a value that is beyond the current number of lines of the column");
		return -1;
	}
	return 0;
}


int obi_dms_has_unfinished_columns(OBIDMS_p dms)
{
	struct dirent*         dms_dirent;
	struct dirent*  	   col_dirent;
	DIR*           		   col_dir;
	size_t	      		   i,j;
	char*		   		   column_dir_path;
	char*          		   col_name;
	char*		   		   col_version_str;
	obiversion_t  		   col_version;
	OBIDMS_column_header_p col_header;
	int  				   ret_value;

	ret_value = 0;

	// Find column directories
	rewinddir(dms->directory);
	while ((dms_dirent = readdir(dms->directory)) != NULL)
	{
		if ((dms_dirent->d_name)[0] == '.')
			continue;
		i=0;
		while (((dms_dirent->d_name)[i] != '.') && (i < strlen(dms_dirent->d_name)))
			i++;
		if ((i != strlen(dms_dirent->d_name)) && (strcmp((dms_dirent->d_name)+i, ".obicol") == 0))	// Found a column directory
		{
			column_dir_path = obi_dms_get_full_path(dms, dms_dirent->d_name);
			if (column_dir_path == NULL)
			{
				obidebug(1, "\nError getting a column directory path when deleting unfinished columns");
				ret_value = -1;
			}
			col_name = (char*) malloc(strlen(dms_dirent->d_name) * sizeof(char));
			if (col_name == NULL)
			{
				obi_set_errno(OBI_MALLOC_ERROR);
				obidebug(1, "\nError allocating memory for a column name when deleting unfinished columns: directory %s", dms_dirent->d_name);
				ret_value = -1;
				continue;
			}
			strncpy(col_name, dms_dirent->d_name, i);
			col_name[i] = '\0';
			col_dir = opendir_in_dms(dms, dms_dirent->d_name);
			if (col_dir == NULL)
			{
				obidebug(1, "\nError opening a column directory when deleting unfinished columns");
				ret_value = -1;
				continue;
			}

			// Iteration on files of this column directory
			while ((col_dirent = readdir(col_dir)) != NULL)
			{
				if ((col_dirent->d_name)[0] == '.')
					continue;
				i=0;
				j=0;
				while (((col_dirent->d_name)[i] != '@') && ((col_dirent->d_name)[i] != '.'))
					i++;
				if ((col_dirent->d_name)[i] == '@')	// Found a column file
				{
					i++;
					j=i;
					while ((col_dirent->d_name)[j] != '.')
						j++;
					col_version_str = (char*) malloc(strlen(col_dirent->d_name) * sizeof(char));
					if (col_version_str == NULL)
					{
						obi_set_errno(OBI_MALLOC_ERROR);
						obidebug(1, "\nError allocating memory for a column version when deleting unfinished columns: directory %s", dms_dirent->d_name);
						ret_value = -1;
						continue;
					}
					strncpy(col_version_str, (col_dirent->d_name)+i, j-i);
					col_version_str[j-i] = '\0';
					col_version = atoi(col_version_str);
					free(col_version_str);
					col_header = obi_column_get_header_from_name(dms, col_name, col_version);
					if (col_header == NULL)		// TODO discuss if delete file or not
					{
						obidebug(1, "\nError reading a column header when deleting unfinished columns: file %s", col_dirent->d_name);
						ret_value = -1;
						continue;
					}

					// Check if the column is finished and delete it if not
					if (col_header->finished == false)
						ret_value = 1;
					// Close the header
					if (obi_close_header(col_header) < 0)
						ret_value = -1;
				}
			}

			// Close column directory
			if (closedir(col_dir) < 0)
			{
				obi_set_errno(OBICOL_UNKNOWN_ERROR);
				obidebug(1, "\nError closing a column directory when deleting unfinished columns");
				ret_value = -1;
				continue;
			}

			free(col_name);
		}
	}

	return ret_value;
}


int obi_clean_unfinished_columns(OBIDMS_p dms)
{
	struct dirent*         dms_dirent;
	struct dirent*  	   col_dirent;
	DIR*           		   col_dir;
	size_t	      		   i,j;
	char*          		   column_file_path;
	char*		   		   column_dir_path;
	char*          		   col_name;
	char*		   		   col_version_str;
//	char*				   version_file;
	obiversion_t  		   col_version;
	OBIDMS_column_header_p col_header;
//	int 				   n;
	char*                  col_to_delete[1000];
	char*                  dir_to_delete[1000];
	int 				   ddir;
	int					   dcol;
	int					   d;
	int  				   ret_value;

	ret_value = 0;

	// Find column directories
	ddir = 0;
	rewinddir(dms->directory);
	while ((dms_dirent = readdir(dms->directory)) != NULL)
	{
		if ((dms_dirent->d_name)[0] == '.')
			continue;
		i=0;
		while (((dms_dirent->d_name)[i] != '.') && (i < strlen(dms_dirent->d_name)))
			i++;
		if ((i != strlen(dms_dirent->d_name)) && (strcmp((dms_dirent->d_name)+i, ".obicol") == 0))	// Found a column directory
		{
			column_dir_path = obi_dms_get_full_path(dms, dms_dirent->d_name);
			if (column_dir_path == NULL)
			{
				obidebug(1, "\nError getting a column directory path when deleting unfinished columns");
				ret_value = -1;
			}
			col_name = (char*) malloc(strlen(dms_dirent->d_name) * sizeof(char));
			if (col_name == NULL)
			{
				obi_set_errno(OBI_MALLOC_ERROR);
				obidebug(1, "\nError allocating memory for a column name when deleting unfinished columns: directory %s", dms_dirent->d_name);
				ret_value = -1;
				continue;
			}
			strncpy(col_name, dms_dirent->d_name, i);
			col_name[i] = '\0';
			col_dir = opendir_in_dms(dms, dms_dirent->d_name);
			if (col_dir == NULL)
			{
				obidebug(1, "\nError opening a column directory when deleting unfinished columns");
				ret_value = -1;
				continue;
			}

			// Iteration on files of this column directory
			dcol = 0;
			while ((col_dirent = readdir(col_dir)) != NULL)
			{
				if ((col_dirent->d_name)[0] == '.')
					continue;
				i=0;
				j=0;
				while (((col_dirent->d_name)[i] != '@') && ((col_dirent->d_name)[i] != '.'))
					i++;
				if ((col_dirent->d_name)[i] == '@')	// Found a column file
				{
					i++;
					j=i;
					while ((col_dirent->d_name)[j] != '.')
						j++;
					col_version_str = (char*) malloc(strlen(col_dirent->d_name) * sizeof(char));
					if (col_version_str == NULL)
					{
						obi_set_errno(OBI_MALLOC_ERROR);
						obidebug(1, "\nError allocating memory for a column version when deleting unfinished columns: directory %s", dms_dirent->d_name);
						ret_value = -1;
						continue;
					}
					strncpy(col_version_str, (col_dirent->d_name)+i, j-i);
					col_version_str[j-i] = '\0';
					col_version = atoi(col_version_str);
					free(col_version_str);
					col_header = obi_column_get_header_from_name(dms, col_name, col_version);
					if (col_header == NULL)		// TODO discuss if delete file or not
					{
						obidebug(1, "\nError reading a column header when deleting unfinished columns: file %s", col_dirent->d_name);
						ret_value = -1;
						continue;
					}

					// Check if the column is finished and delete it if not
					if (col_header->finished == false)
					{
						// Build file and dir paths
						column_file_path = obi_column_full_path(dms, col_name, col_version);
						if (column_file_path == NULL)
						{
							obidebug(1, "\nError getting a column file path when deleting unfinished columns");
							ret_value = -1;
							continue;
						}

						// Add the column path in the list of files to delete (can't delete while in loop)
						col_to_delete[dcol] = column_file_path;
						dcol++;
					}
					// Close the header
					if (obi_close_header(col_header) < 0)
						ret_value = -1;
				}
			}

			// Delete all column files in to_delete list
			for (d=0; d<dcol; d++)
			{
				if (remove(col_to_delete[d]) < 0)
				{
					obi_set_errno(OBICOL_UNKNOWN_ERROR);
					obidebug(1, "\nError deleting a column file when deleting unfinished columns: file %s", col_to_delete[d]);
					ret_value = -1;
				}
				free(col_to_delete[d]);
			}

			// Close column directory
			if (closedir(col_dir) < 0)
			{
				obi_set_errno(OBICOL_UNKNOWN_ERROR);
				obidebug(1, "\nError closing a column directory when deleting unfinished columns");
				ret_value = -1;
				continue;
			}

			// Add column dir in list to delete if it's empty
			// TODO commented because causes bug when cloning AVL using column version for name. to discuss
//			n = count_dir(column_dir_path);
//			if (n == 1)		// Only file left is the version file
//			{
//				// Delete the version file
//				version_file = obi_version_file_full_path(dms, col_name);
//				if (version_file == NULL)
//				{
//					obidebug(1, "\nError getting a version file path when deleting unfinished columns");
//					ret_value = -1;
//					continue;
//				}
//				if (remove(version_file) < 0)
//				{
//					obi_set_errno(OBICOL_UNKNOWN_ERROR);
//					obidebug(1, "\nError deleting a version file when deleting unfinished columns: file %s", version_file);
//					ret_value = -1;
//				}
//				free(version_file);
//				dir_to_delete[ddir] = column_dir_path;
//				ddir++;
//			}
//			else
//				free(column_dir_path);

			free(col_name);
		}
	}

	// Delete all column dir in to_delete list
	for (d=0; d<ddir; d++)
	{
		if (remove(dir_to_delete[d]) < 0)
		{
			obi_set_errno(OBICOL_UNKNOWN_ERROR);
			obidebug(1, "\nError deleting a column directory when deleting unfinished columns: directory %s", dir_to_delete[d]);
			ret_value = -1;
		}
		free(dir_to_delete[d]);
	}

	return ret_value;
}


