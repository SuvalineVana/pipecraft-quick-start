/********************************************************************
 * Obiview functions                                                 *
 ********************************************************************/

/**
 * @file obiview.c
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 * @date 16 December 2015
 * @brief Obiview functions.
 */


#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <inttypes.h>
#include <math.h>
//#include <ctype.h>

#include "obiview.h"
#include "obidms.h"
#include "obidmscolumn.h"
#include "obidmscolumn_idx.h"
#include "obidmscolumn_blob.h"
#include "obidmscolumn_bool.h"
#include "obidmscolumn_char.h"
#include "obidmscolumn_float.h"
#include "obidmscolumn_int.h"
#include "obidmscolumn_qual.h"
#include "obidmscolumn_seq.h"
#include "obidmscolumn_str.h"
#include "obidmscolumn_array.h"
#include "obierrno.h"
#include "obidebug.h"
#include "obilittlebigman.h"
#include "hashtable.h"
#include "linked_list.h"
#include "utils.h"
#include "obiblob.h"
#include "libjson/json_utils.h"


#define DEBUG_LEVEL 0	// TODO has to be defined somewhere else (cython compil flag?)


/**************************************************************************
 *
 * D E C L A R A T I O N   O F   T H E   P R I V A T E   F U N C T I O N S
 *
 **************************************************************************/


/**
 * Internal function building the file name where the informations about a finished, read-only obiview are stored.
 *
 * @warning The returned pointer has to be freed by the caller.
 *
 * @param view_name The name of the view.
 *
 * @returns A pointer to the file name.
 * @retval NULL if an error occurred.
 *
 * @since June 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static char* build_obiview_file_name(const char* view_name);


/**
 * Internal function building the file name where the informations about an unfinished, writable obiview are stored.
 *
 * @warning The returned pointer has to be freed by the caller.
 *
 * @param view_name The name of the view.
 *
 * @returns A pointer to the file name.
 * @retval NULL if an error occurred.
 *
 * @since February 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static char* build_unfinished_obiview_file_name(const char* view_name);


/**
 * Internal function checking if a view is finished.
 *
 * @param dms The DMS.
 * @param view_name The name of the view.
 *
 * @retval 1 if the view is finished.
 * @retval 0 if the view is not finished.
 * @retval -1 if the view does not exist or if an error occurred.
 *
 * @since October 2018
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static int view_is_finished(OBIDMS_p dms, const char* view_name);


/**
 * Internal function calculating the initial size of the file where the informations about an obiview are stored.
 *
 * @returns The initial size of the file in bytes, rounded to a multiple of page size.
 *
 * @since June 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static size_t get_platform_view_file_size(void);


/**
 * @brief Internal function enlarging a view file.
 *
 * @param view A pointer on the view.
 * @param new_size The new size needed, in bytes (not necessarily rounded to a page size multiple).
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since August 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static int enlarge_view_file(Obiview_p view, size_t new_size);


/**
 * @brief Internal function creating a file containing all the informations on a view.
 *
 * The file is named with the name of the view.
 *
 * @param dms The DMS to which the view belongs.
 * @param view_name The name of the view.
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since June 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static int create_obiview_file(OBIDMS_p dms, const char* view_name);


/**
 * @brief Internal function to update the column references of a view.
 *
 * The column references stored in the mapped view infos structures are updated
 * to match the columns opened in the opened view structure.
 *
 * @warning The column pointer array should be up to date before using this function.
 * @warning Aliases are not updated by this function and have to be edited separately.
 * 			This function simply reads the column pointer array associated with the view
 * 			and fills the column names and versions in the column reference array accordingly,
 * 			without touching the alias.
 *          That means that for example if there is a shift in the column pointer array, this
 *          function should not be used.
 *
 * @param view A pointer on the view.
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since June 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static int update_column_refs(Obiview_p view);


/**
 * @brief Internal function creating the column dictionary associated with a view.
 *
 * The column dictionary is built from the column references array, and associates each column alias
 * with the pointer on the column.
 *
 * @warning The column reference array and the column pointer array should be up to date before using this function.
 *
 * @param view A pointer on the view.
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since July 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static int create_column_dict(Obiview_p view);


/**
 * @brief Internal function updating the column dictionary associated with a view.
 *
 * The column dictionary is built from the column references array, and associates each column alias
 * with the pointer on the column.
 *
 * @warning The column reference array and the column pointer array should be up to date before using this function.
 *
 * @param view A pointer on the view.
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since July 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static int update_column_dict(Obiview_p view);


/**
 * @brief Internal function updating the column reference array and the column dictionary associated with a view.
 *
 * The column reference array is updated from the column pointer array, then the column dictionary that
 * and associates each column alias with the pointer on the column is updated from the column reference array.
 *
 * @warning The column pointer array should be up to date before using this function.
 * @warning Aliases are not updated by this function and have to be edited separately.
 * 			This function simply reads the column pointer array associated with the view
 * 			and fills the column names and versions in the column reference array accordingly,
 * 			without touching the alias.
 *          That means that for example if there is a shift in the column pointer array, this
 *          function should not be used.
 *
 * @param view A pointer on the view.
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since July 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static int update_column_refs_and_dict(Obiview_p view);


/**
 * @brief Internal function to update the line count in the context of a view.
 *
 * All columns of the view are enlarged to contain at least the new line count.
 *
 * @warning The view must be writable.
 *
 * @param view A pointer on the view.
 * @param line_count The new line count.
 *
 * @returns A value indicating the success of the operation.
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since February 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static int update_lines(Obiview_p view, index_t line_count);


/**
 * @brief Internal function to clone a column in the context of a view.
 *
 * Clones with the right line selection and replaces the cloned columns with the new ones in the view.
 * If there is a line selection, all columns have to be cloned, otherwise only the column of interest is cloned.
 *
 * @param view A pointer on the view.
 * @param column_name The name of the column in the view that should be cloned.
 *
 * @returns A pointer on the new column.
 * @retval NULL if an error occurred.
 *
 * @since February 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static OBIDMS_column_p clone_column_in_view(Obiview_p view, const char* column_name);


/**
 * @brief Saves a view, updating its informations in the view file.
 *
 * @warning The view must be writable.
 *
 * @param view A pointer on the view.
 *
 * @returns A value indicating the success of the operation.
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since February 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static int save_view(Obiview_p view);


/**
 * @brief Rename a view file once the view is finished, replacing the '*.obiview_unfinished' extension with '*.obiview'.
 *
 * @param view A pointer on the view.
 *
 * @returns A value indicating the success of the operation.
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since February 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static int rename_finished_view(Obiview_p view);


/**
 * @brief Finishes a view: check the predicates, save all the informations, rename the view file.
 *
 * @param view A pointer on the view.
 *
 * @returns A value indicating the success of the operation.
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since February 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static int finish_view(Obiview_p view);

/**
 * @brief Closes an opened view.
 *
 * @warning Doesn't save the view.
 *
 * @param view A pointer on the view.
 *
 * @returns A value indicating the success of the operation.
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @see obi_save_and_close_view()
 * @since February 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static int close_view(Obiview_p view);


/**
 * @brief Internal function preparing to set a value in a column, in the context of a view.
 *
 * The function checks that the view is not read-only, clones the column or all columns if needed,
 * and updates the line count if needed.
 *
 * @param view The view.
 * @param column_pp A pointer on the pointer on the column, to allow replacing the column if it is cloned.
 * @param line_nb_p A pointer on the index of the line that will be modified, to allow replacing it if needed.
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static int prepare_to_set_value_in_column(Obiview_p view, OBIDMS_column_p* column_pp, index_t* line_nb_p);


/**
 * @brief Internal function preparing to get a value from a column, in the context of a view.
 *
 * The function checks that the line index is not beyond the current line count of the view,
 * and modifies it if there is a line selection associated with the view.
 *
 * @param view The view.
 * @param line_nb_p A pointer on the index of the line, to allow replacing it if needed.
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static int prepare_to_get_value_from_column(Obiview_p view, index_t* line_nb_p);


/****** PREDICATE FUNCTIONS *******/

/**
 * @brief Internal function checking if a view has a NUC_SEQUENCE_COLUMN column.
 *
 * The function checks that the view has a column with the name attributed to obligatory
 * nucleotide sequence columns.
 *
 * @param view The view.
 *
 * @returns A character string describing the predicate.
 * @retval NULL if the predicate is false or if there was an error.
 *
 * @since July 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static char* view_has_nuc_sequence_column(Obiview_p view);


/**
 * @brief Internal function checking if a view has a QUALITY_COLUMN column.
 *
 * The function checks that the view has a column with the name attributed to obligatory
 * quality columns.
 *
 * @param view The view.
 *
 * @returns A character string describing the predicate.
 * @retval NULL if the predicate is false or if there was an error.
 *
 * @since July 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static char* view_has_quality_column(Obiview_p view);


/**
 * @brief Internal function checking if a view has a ID_COLUMN column.
 *
 * The function checks that the view has a column with the name attributed to obligatory
 * id columns.
 *
 * @param view The view.
 *
 * @returns A character string describing the predicate.
 * @retval NULL if the predicate is false or if there was an error.
 *
 * @since July 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static char* view_has_id_column(Obiview_p view);


/**
 * @brief Internal function checking if a view has a DEFINITION_COLUMN column.
 *
 * The function checks that the view has a column with the name attributed to obligatory
 * definition columns.
 *
 * @param view The view.
 *
 * @returns A character string describing the predicate.
 * @retval NULL if the predicate is false or if there was an error.
 *
 * @since July 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static char* view_has_definition_column(Obiview_p view);


/**
 * @brief Internal function checking that all the quality columns of a view and their associated sequence columns
 * 		  correspond properly:
 * 		  	- when a line is defined for either column, it must also be defined for the other column
 * 		  	- when a line is defined, the lengths of the sequence and of the quality must be equal
 *
 * @param view The view.
 *
 * @returns A character string describing the predicate.
 * @retval NULL if the predicate is false or if there was an error.
 *
 * @since July 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static char* view_check_qual_match_seqs(Obiview_p view);


/**
 * @brief Internal function checking one predicate function on a view.
 *
 * @param view The view.
 * @param predicate_function The predicate function to use.
 *
 * @returns A character string describing the predicate.
 * @retval NULL if the predicate is false or if there was an error.
 *
 * @since July 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static char* view_check_one_predicate(Obiview_p view, char* (*predicate_function)(Obiview_p view));


/**
 * @brief Internal function checking all the predicates associated with a view.
 *
 * @param view The view.
 * @param write Whether the verified predicates should be written in the view comments.
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if at least one of the predicates is false or if there was an error.
 *
 * @since July 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static int view_check_all_predicates(Obiview_p view, bool write);


/************************************************************************
 *
 * D E F I N I T I O N   O F   T H E   P R I V A T E   F U N C T I O N S
 *
 ************************************************************************/


static char* build_obiview_file_name(const char* view_name)
{
	char* file_name;

	// Build file name
	file_name = (char*) malloc((strlen(view_name) + 8 + 1)*sizeof(char));
	if (file_name == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating memory for a view file name");
		return NULL;
	}
	if (sprintf(file_name, "%s.obiview", view_name) < 0)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nProblem building an obiview file name");
		return NULL;
	}

	return file_name;
}


static char* build_unfinished_obiview_file_name(const char* view_name)
{
	char* file_name;

	// Build file name
	file_name = (char*) malloc((strlen(view_name) + 19 + 1)*sizeof(char));
	if (file_name == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating memory for a view file name");
		return NULL;
	}
	if (sprintf(file_name, "%s.obiview_unfinished", view_name) < 0)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nProblem building an unfinished obiview file name");
		return NULL;
	}

	return file_name;
}


static int view_is_finished(OBIDMS_p dms, const char* view_name)
{
	struct dirent* dp;
	char*		   file_name;

	// Check finished views
	// Create file name
	file_name = build_obiview_file_name(view_name);
	if (file_name == NULL)
		return -1;

	rewinddir(dms->view_directory);
	while ((dp = readdir(dms->view_directory)) != NULL)
	{
		if ((dp->d_name)[0] == '.')
			continue;
		if (strcmp(dp->d_name, file_name) == 0)
		{
			free(file_name);
			return true;
		}
	}

	free(file_name);

	// Check unfinished views
	// Create file name
	file_name = build_unfinished_obiview_file_name(view_name);
	if (file_name == NULL)
		return -1;

	rewinddir(dms->view_directory);
	while ((dp = readdir(dms->view_directory)) != NULL)
	{
		if ((dp->d_name)[0] == '.')
			continue;
		if (strcmp(dp->d_name, file_name) == 0)
		{
			free(file_name);
			return false;
		}
	}

	free(file_name);

	return -1;
}


static size_t get_platform_view_file_size()
{
	size_t obiview_size;
	size_t rounded_obiview_size;
	double multiple;

	obiview_size = sizeof(Obiview_infos_t);

	multiple = 	ceil((double) (obiview_size) / (double) getpagesize());

	rounded_obiview_size = multiple * getpagesize();

	return rounded_obiview_size;
}


static int enlarge_view_file(Obiview_p view, size_t new_size)
{
	int    obiview_file_descriptor;
	double multiple;
	size_t rounded_new_size;
	char*  file_name;

	// Create file name
	file_name = build_unfinished_obiview_file_name((view->infos)->name);
	if (file_name == NULL)
		return -1;

    // Open view file
	obiview_file_descriptor = openat((view->dms)->view_dir_fd, file_name, O_RDWR, 0777);
	if (obiview_file_descriptor < 0)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError opening a view file");
		free(file_name);
		return -1;
	}

	free(file_name);

	// Round new size to a multiple of page size	// TODO make function in utils
	multiple = 	ceil((double) new_size / (double) getpagesize());
	rounded_new_size = multiple * getpagesize();

	// Enlarge the file
	if (ftruncate(obiview_file_descriptor, rounded_new_size) < 0)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError enlarging a view file");
		close(obiview_file_descriptor);
		return -1;
	}

	// Unmap and remap the file
	if (munmap(view->infos, (view->infos)->file_size) < 0)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError munmapping a view file when enlarging");
		close(obiview_file_descriptor);
		return -1;
	}

	view->infos = mmap(NULL,
					   rounded_new_size,
					   PROT_READ | PROT_WRITE,
					   MAP_SHARED,
					   obiview_file_descriptor,
					   0
					  );
	if (view->infos == MAP_FAILED)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError re-mmapping a view file after enlarging the file");
		close(obiview_file_descriptor);
		return -1;
	}

	// Set new size
	(view->infos)->file_size = rounded_new_size;

	if (close(obiview_file_descriptor) < 0)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError closing a view file");
		return -1;
	}

	return 0;
}


static int create_obiview_file(OBIDMS_p dms, const char* view_name)
{
	char* 				file_name;
	int 				obiview_file_descriptor;
	size_t  			file_size;

	// Create file name
	file_name = build_unfinished_obiview_file_name(view_name);
	if (file_name == NULL)
		return -1;

    // Create file
	obiview_file_descriptor = openat(dms->view_dir_fd, file_name, O_RDWR | O_CREAT | O_EXCL, 0777);
	if (obiview_file_descriptor < 0)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError creating an obiview file");
		free(file_name);
		return -1;
	}

	free(file_name);

	// Truncate file to the initial size
	file_size = get_platform_view_file_size();

	if (ftruncate(obiview_file_descriptor, file_size) < 0)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError truncating an obiview file to the right size");
		close(obiview_file_descriptor);
		return -1;
	}

	// Write file size
	if (write(obiview_file_descriptor, &file_size, sizeof(size_t)) < ((ssize_t) sizeof(size_t)))
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError writing the file size in an obiview file");
		close(obiview_file_descriptor);
		return -1;
	}

	if (close(obiview_file_descriptor) < 0)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError closing a view file");
		return -1;
	}

	return 0;
}


static int update_column_refs(Obiview_p view)
{
	int i;
	OBIDMS_column_p column;

	for (i=0; i < (view->infos)->column_count; i++)
	{
		column = *((OBIDMS_column_p*)ll_get(view->columns, i));
		if (column == NULL)
		{
			obi_set_errno(OBIVIEW_ERROR);
			obidebug(1, "\nError getting a column from the linked list of column pointers of a view");
			return -1;
		}
		strcpy(((((view->infos)->column_references)[i]).column_refs).column_name, (column->header)->name);
		((((view->infos)->column_references)[i]).column_refs).version = (column->header)->version;
	}
	return 0;
}


static int create_column_dict(Obiview_p view)
{
	int i;
	OBIDMS_column_p* column_pp;

	view->column_dict = ht_create(MAX_NB_OPENED_COLUMNS);
	if (view->column_dict == NULL)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError creating a column dictionary");
		return -1;
	}

	// Rebuild the dictionary from the column references and the column pointer array associated with the view
	for (i=0; i < (view->infos)->column_count; i++)
	{
		// Check that each alias is unique
		if (ht_get(view->column_dict, (((view->infos)->column_references)[i]).alias) != NULL)
		{
			obi_set_errno(OBIVIEW_ERROR);
			obidebug(1, "\nError: the name/alias identifying a column in a view is not unique: %s", (((view->infos)->column_references)[i]).alias);
			return -1;
		}

		column_pp = (OBIDMS_column_p*) ll_get(view->columns, i);
		if (column_pp == NULL)
		{
			obi_set_errno(OBIVIEW_ERROR);
			obidebug(1, "\nError getting a column from the linked list of column pointers of a view when creating a column dictionary");
			return -1;
		}

		if (ht_set(view->column_dict, (((view->infos)->column_references)[i]).alias, column_pp) < 0)
		{
			obi_set_errno(OBIVIEW_ERROR);
			obidebug(1, "\nError adding a column in a column dictionary");
			return -1;
		}
	}

	return 0;
}


static int update_column_dict(Obiview_p view)
{
	// Re-initialize the dictionary to rebuild it from scratch
	ht_free(view->column_dict);

	if (create_column_dict(view) < 0)
		return -1;

	return 0;
}


static int update_column_refs_and_dict(Obiview_p view)
{
	if (update_column_refs(view) < 0)
		return -1;
	return update_column_dict(view);
}


static int update_lines(Obiview_p view, index_t line_count)
{
	int             i;
	OBIDMS_column_p column;

	// Check that the view is not read-only
	if (view->read_only)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError trying to update the line count of all columns in a read-only view");
		return -1;
	}

	for (i=0; i<((view->infos)->column_count); i++)
	{
		column = *((OBIDMS_column_p*)ll_get(view->columns, i));
		if (column == NULL)
		{
			obi_set_errno(OBIVIEW_ERROR);
			obidebug(1, "\nError getting a column from the linked list of column pointers of a view when updating view lines");
			return -1;
		}

		// Clone the column first if needed
		if (!(column->writable))
		{
			column = clone_column_in_view(view, (((view->infos)->column_references)[i]).alias);
			if (column == NULL)
			{
				obidebug(1, "\nError cloning a column in a view when updating its line count");
				return -1;
			}
		}

		// Enlarge the column if needed
		while (line_count > (column->header)->line_count)
		{
			if (obi_enlarge_column(column) < 0)
		    	return -1;
		}

		// Set the number of lines used to the new view line count
		(column->header)->lines_used = line_count;
	}

	(view->infos)->line_count = line_count;

	return 0;
}


static OBIDMS_column_p clone_column_in_view(Obiview_p view, const char* column_name)
{
	int i;
	OBIDMS_column_p column = NULL;
	OBIDMS_column_p new_column = NULL;
	OBIDMS_column_p column_buffer;

	// Check that the view is not read-only
	if (view->read_only)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError trying to delete a column in a read-only view");
		return NULL;
	}

	for (i=0; i<((view->infos)->column_count); i++)
	{
		if ((view->line_selection != NULL) || (!strcmp((((view->infos)->column_references)[i]).alias, column_name)))
		{ // Clone with the right line selection and replace (for all columns if there is a line selection)

			// Save pointer to close column after cloning
			column_buffer = *((OBIDMS_column_p*)ll_get(view->columns, i));
			if (column_buffer == NULL)
			{
				obi_set_errno(OBIVIEW_ERROR);
				obidebug(1, "\nError getting a column to clone from the linked list of column pointers of a view");
				return NULL;
			}

			// Clone and replace the column in the view
			column = obi_clone_column(view->dms, view->line_selection, (column_buffer->header)->name, (column_buffer->header)->version, true);
			if (column == NULL)
			{
				obi_set_errno(OBIVIEW_ERROR);
				obidebug(1, "\nError cloning a column to replace in a view");
				return NULL;
			}

			// Change the pointer in the linked list of column pointers
			if (ll_set(view->columns, i, column) < 0)
			{
				obi_set_errno(OBIVIEW_ERROR);
				obidebug(1, "\nError changing the column pointer of a cloned column in the linked list of column pointers of a view");
				return NULL;
			}

			// Close old cloned column
			obi_close_column(column_buffer);

			if (!strcmp((((view->infos)->column_references)[i]).alias, column_name))
				// Found the column to return
				new_column = column;
		}
	}

	// Close old line selection
	if (view->line_selection != NULL)
	{
		obi_close_column(view->line_selection);
		view->line_selection = NULL;
		// Update line selection reference
		(((view->infos)->line_selection).column_name)[0] = '\0';
		((view->infos)->line_selection).version = -1;
	}

	// Update column refs and dict
	if (update_column_refs_and_dict(view) < 0)
	{
		obidebug(1, "\nError updating columns references and dictionary after cloning a column in a view");
		return NULL;
	}

	return new_column;
}


static int save_view(Obiview_p view)
{
	// Check that the view is not read-only
	if (view->read_only)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError trying to save a read-only view");
		return -1;
	}

	// Store reference for the line selection associated with that view if there is one
	if (view->line_selection != NULL)		// Unnecessary in theory, the line selection references are already saved
	{
		strcpy(((view->infos)->line_selection).column_name, ((view->line_selection)->header)->name);
		((view->infos)->line_selection).version = ((view->line_selection)->header)->version;
		(view->infos)->all_lines = false;
	}
	else	// Necessary because line selection could have been deleted if a column was cloned
	{
		(((view->infos)->line_selection).column_name)[0] = '\0';
		((view->infos)->line_selection).version = -1;
		(view->infos)->all_lines = true;
	}

	if (update_column_refs(view) < 0)
	{
		obidebug(1, "\nError updating column references when saving a view");
		return -1;
	}

	return 0;
}


static int rename_finished_view(Obiview_p view)
{
	char* old_name;
	char* new_name;
	char* path_old_name;
	char* path_new_name;
	char* full_path_old_name;
	char* full_path_new_name;

	old_name = build_unfinished_obiview_file_name((view->infos)->name);
	new_name = build_obiview_file_name((view->infos)->name);

	path_old_name = malloc(MAX_PATH_LEN);
	path_new_name = malloc(MAX_PATH_LEN);

	strcpy(path_old_name, "VIEWS/");
	strcat(path_old_name, old_name);

	strcpy(path_new_name, "VIEWS/");
	strcat(path_new_name, new_name);

	full_path_old_name = obi_dms_get_full_path(view->dms, path_old_name);
	full_path_new_name = obi_dms_get_full_path(view->dms, path_new_name);

	if (rename(full_path_old_name, full_path_new_name) < 0)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError renaming the file of a finished view: %s", full_path_new_name);
		free(old_name);
		free(new_name);
		return -1;
	}

	free(old_name);
	free(new_name);
	free(path_new_name);
	free(path_old_name);
	free(full_path_old_name);
	free(full_path_new_name);

	return 0;
}


static int finish_view(Obiview_p view)
{
	int             i;
	OBIDMS_column_p column;

	// Check that the view is not read-only
	if (view->read_only)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError trying to save a read-only view");
		return -1;
	}

	// Add count column if it's a NUC_SEQ_VIEW with no count column // TODO discuss
	if ((!strcmp((view->infos)->view_type, VIEW_TYPE_NUC_SEQS)) && (!obi_view_column_exists(view, COUNT_COLUMN)))
	{
		if (obi_create_auto_count_column(view) < 0)
		{
			obidebug(1, "\nError creating an automatic count column when finishing a view");
			return -1;
		}
	}

	// Add id column if it's a NUC_SEQ_VIEW with no id column // TODO discuss
	if ((!strcmp((view->infos)->view_type, VIEW_TYPE_NUC_SEQS)) && (!obi_view_column_exists(view, ID_COLUMN)))
	{
		if (obi_create_auto_id_column(view, NULL) < 0)
		{
			obidebug(1, "\nError creating an automatic id column when finishing a view");
			return -1;
		}
	}

	// Check predicates
	if (view_check_all_predicates(view, true) < 0)
	{
		obidebug(1, "\nView predicates not respected, view rollbacked");
		obi_rollback_view(view);  // TODO discuss, maybe never call from C layer
		return -1;
	}

	if (save_view(view) < 0)
		return -1;

	 // Add the time in the view comments
	 time_t t;
	 t = time(&t);
	 if (obi_view_add_comment(view, "Date created", strtok(ctime(&t), "\n")) < 0)
	 {
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError adding the date of creation when finishing a view");
		return -1;
	}

	if (rename_finished_view(view) < 0)
		return -1;

	// Flag the columns as finished
	for (i=0; i < ((view->infos)->column_count); i++)
	{
		column = *((OBIDMS_column_p*)ll_get(view->columns, i));
		if (column == NULL)
		{
			obi_set_errno(OBIVIEW_ERROR);
			obidebug(1, "\nError getting a column to flag it as finished when finishing a view");
			return -1;
		}
		if (column->writable)
			(column->header)->finished = true;
	}

	// Flag the line selection column as finished
	 if (view->line_selection != NULL)
	 {
		 column = view->line_selection;
     	 if (column->writable)
     		 (column->header)->finished = true;
	 }

	// Flag the view as finished
	(view->infos)->finished = true;

	return 0;
}


static int close_view(Obiview_p view)
{
	int i;
	int ret_value;
	OBIDMS_column_p column;

	ret_value = 0;

	for (i=0; i < ((view->infos)->column_count); i++)
	{
		column = *((OBIDMS_column_p*)ll_get(view->columns, i));
		if (column == NULL)
		{
			obi_set_errno(OBIVIEW_ERROR);
			obidebug(1, "\nError getting a column to close from the linked list of column pointers of a view");
			return -1;
		}
		if (obi_close_column(column) < 0)
		{
			obidebug(1, "\nError closing a column while closing a view");
			ret_value = -1;
		}
	}

	// Close line selection if there is one
	if (view->line_selection != NULL)
	{
		if (obi_close_column(view->line_selection) < 0)
		{
			obidebug(1, "\nError closing a line selection while closing a view");
			ret_value = -1;
		}
	}

	// Free the linked list of column pointers
	ll_free(view->columns);

	// Free the column dictionary
	ht_free(view->column_dict);

	// Unmap view file
	if (obi_view_unmap_file(view->dms, view->infos) < 0)
	{
		obidebug(1, "\nError unmaping a view file while closing a view");
		ret_value = -1;
	}

	free(view);

	return ret_value;
}


static int prepare_to_set_value_in_column(Obiview_p view, OBIDMS_column_p* column_pp, index_t* line_nb_p)
{
	int   i;
	char* column_name = NULL;

	// Check that the view is not read-only
	if (view->read_only)
	{
		obidebug(1, "\nError trying to set a value in a column in a read-only view");
		return -1;
	}

	// If there is a line selection associated with the view or if the column
	// is read-only, all columns or this column respectively must be cloned
	if ((view->line_selection != NULL) || (!((*column_pp)->writable)))
	{
		// Get the name/alias of the column from the pointer
		for (i=0; i<((view->infos)->column_count); i++)
		{
			if (obi_view_get_column(view, (((view->infos)->column_references)[i]).alias) == *column_pp)
				column_name = (((view->infos)->column_references)[i]).alias;
		}
		if (column_name == NULL)
		{
			obi_set_errno(OBIVIEW_ERROR);
			obidebug(1, "\nError trying to clone a column in a view: column alias not found from pointer");
			return -1;
		}

		(*column_pp) = clone_column_in_view(view, column_name);
		if ((*column_pp) == NULL)
		{
			obidebug(1, "\nError trying to clone a column to modify it");
			return -1;
		}
	}

	if (((*line_nb_p)+1) > (view->infos)->line_count)
	{
		if (update_lines(view, ((*line_nb_p)+1)) < 0)
			return -1;
	}

	return 0;
}


static int prepare_to_get_value_from_column(Obiview_p view, index_t* line_nb_p)
{
	if (((*line_nb_p)+1) > ((view->infos)->line_count))
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError trying to get a value that is beyond the current line count of the view");
		return -1;
	}

	if (view->line_selection != NULL)
		(*line_nb_p) = *(((index_t*) ((view->line_selection)->data)) + (*line_nb_p));

	return 0;
}



/****** PREDICATE FUNCTIONS *******/

static char* view_has_nuc_sequence_column(Obiview_p view)
{
	char* predicate;

	predicate = (char*) malloc((strlen("The view has an associated nucleotide sequence column.") + 1) * sizeof(char));
	if (predicate == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating memory for predicate character string.");
		return NULL;
	}

	strcpy(predicate, "The view has an associated nucleotide sequence column.");

	if (obi_view_get_column(view, NUC_SEQUENCE_COLUMN) != NULL)
		return predicate;
	else
	{
		obidebug(1, "\nError checking the predicate: %s", predicate);
		return NULL;
	}
}


static char* view_has_quality_column(Obiview_p view)
{
	char* predicate;

	predicate = (char*) malloc((strlen("The view has an associated sequence quality column.") + 1) * sizeof(char));
	if (predicate == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating memory for predicate character string.");
		return NULL;
	}

	strcpy(predicate, "The view has an associated sequence quality column.");

	if (obi_view_get_column(view, QUALITY_COLUMN) != NULL)
		return predicate;
	else
	{
		obidebug(1, "\nError checking the predicate: %s", predicate);
		return NULL;
	}
}


static char* view_has_id_column(Obiview_p view)
{
	char* predicate;

	predicate = (char*) malloc((strlen("The view has an associated identifier column.") + 1) * sizeof(char));
	if (predicate == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating memory for predicate character string.");
		return NULL;
	}

	strcpy(predicate, "The view has an associated identifier column.");

	if (obi_view_get_column(view, ID_COLUMN) != NULL)
		return predicate;
	else
	{
		obidebug(1, "\nError checking the predicate: %s", predicate);
		return NULL;
	}
}


static char* view_has_definition_column(Obiview_p view)
{
	char* predicate;

	predicate = (char*) malloc((strlen("The view has an associated definition column.") + 1) * sizeof(char));
	if (predicate == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating memory for predicate character string.");
		return NULL;
	}

	strcpy(predicate, "The view has an associated definition column.");

	if (obi_view_get_column(view, DEFINITION_COLUMN) != NULL)
		return predicate;
	else
	{
		obidebug(1, "\nError checking the predicate: %s", predicate);
		return NULL;
	}
}


static char* view_check_qual_match_seqs(Obiview_p view)
{
	index_t 		i, j, k;
	index_t			nb_elements_per_line;
	int	    		qual_len;
	const uint8_t*	qual;
	char* 			seq;
	OBIDMS_column_p column;
	OBIDMS_column_p qual_column;
	OBIDMS_column_p seq_column;
	char* 			predicate;
	bool			at_least_one_qual_col;

	// Go through all columns in the view and check the predicate for all quality columns
	at_least_one_qual_col = false;
	for (i=0; i < ((view->infos)->column_count); i++)
	{
		column = *((OBIDMS_column_p*)ll_get(view->columns, i));
		if (column == NULL)
		{
			obi_set_errno(OBIVIEW_ERROR);
			obidebug(1, "\nError getting a column to clone from the linked list of column pointers of view %s", (view->infos)->name);
			return NULL;
		}

		// Check if it's a quality column
		if ((column->header)->returned_data_type == OBI_QUAL)
		{
			at_least_one_qual_col = true;
			// Check that the quality arrays match the sequences of the associated column
			qual_column = column;
			seq_column = obi_open_column(view->dms, ((qual_column->header)->associated_column).column_name, ((qual_column->header)->associated_column).version);
			if (seq_column == NULL)
			{
				obidebug(1, "\nError checking the predicate for view %s: The sequences and sequence quality arrays match.", (view->infos)->name);
				return NULL;
			}

			// Close and reopen indexers to remap them properly, because in writable mode they are mostly unmapped
			if (obi_close_indexer(qual_column->indexer) < 0)
			{
				obidebug(1, "\nError closing the quality indexer when checking the predicate for view %s: The sequences and sequence quality arrays match.", (view->infos)->name);
				return NULL;
			}
			qual_column->indexer = obi_open_avl_group(view->dms, (qual_column->header)->indexer_name);
			if (qual_column->indexer == NULL)
			{
				obidebug(1, "\nError reopening the quality indexer when checking the predicate for view %s: The sequences and sequence quality arrays match.", (view->infos)->name);
				return NULL;
			}
			if (obi_close_indexer(seq_column->indexer) < 0)
			{
				obidebug(1, "\nError closing the sequence indexer when checking the predicate for view %s: The sequences and sequence quality arrays match.", (view->infos)->name);
				return NULL;
			}
			seq_column->indexer = obi_open_avl_group(view->dms, (seq_column->header)->indexer_name);
			if (seq_column->indexer == NULL)
			{
				obidebug(1, "\nError reopening the sequence indexer when checking the predicate for view %s: The sequences and sequence quality arrays match.", (view->infos)->name);
				return NULL;
			}

			nb_elements_per_line = (qual_column->header)->nb_elements_per_line;
			// Check that the quality and the sequence columns have the same number of elements per line
			if (nb_elements_per_line != (seq_column->header)->nb_elements_per_line)
			{
				obidebug(1, "\nError checking the predicate for view %s: The sequences and sequence quality arrays match.", (view->infos)->name);
				return NULL;
			}

			// Check each sequence and its quality
			for (j=0; j < (view->infos)->line_count; j++)
			{
				for (k=0; k < nb_elements_per_line; k++)
				{
					qual = obi_get_qual_int_with_elt_idx_and_col_p_in_view(view, qual_column, j, k, &qual_len);
					seq = obi_get_seq_with_elt_idx_and_col_p_in_view(view, seq_column, j, k);
					if ((qual != OBIQual_int_NA) && (seq != OBISeq_NA))
					{
						// Test that the lengths of the quality and the sequence are equal
						if ((size_t)qual_len != strlen(seq))
						{
							obidebug(1, "\nError checking the predicate for view %s: The sequences and sequence quality arrays match.", (view->infos)->name);
							return NULL;
						}
					}
					// Test if one value is NA and not the other
					else if (((qual == OBIQual_int_NA) && (seq != OBISeq_NA)) || ((qual != OBIQual_int_NA) && (seq == OBISeq_NA)))
					{
						obidebug(1, "\nError checking the predicate for view %s: The sequences and sequence quality arrays match.", (view->infos)->name);
						return NULL;
					}
					free(seq);
				}
			}

			obi_close_column(seq_column);
		}
	}

	if (at_least_one_qual_col)
	{
		predicate = (char*) malloc((strlen("The sequences and sequence quality arrays match.") + 1) * sizeof(char));
		if (predicate == NULL)
		{
			obi_set_errno(OBI_MALLOC_ERROR);
			obidebug(1, "\nError allocating memory for predicate character string.");
			return NULL;
		}
		strcpy(predicate, "The sequences and sequence quality arrays match.");
	}
	else
	{
		predicate = (char*) malloc(1 * sizeof(char));
		if (predicate == NULL)
		{
			obi_set_errno(OBI_MALLOC_ERROR);
			obidebug(1, "\nError allocating memory for predicate character string.");
			return NULL;
		}
		strcpy(predicate, "");
	}

	return predicate;
}


static char* view_check_one_predicate(Obiview_p view, char* (*predicate_function)(Obiview_p view))
{
	return predicate_function(view);
}


static int view_check_all_predicates(Obiview_p view, bool write)
{
	int    i;
	char*  predicate = NULL;

	for (i=0; i < view->nb_predicates; i++)
	{
		// Check predicate
		predicate = view_check_one_predicate(view, (view->predicate_functions)[i]);
		if (predicate == NULL)
		{
			// TODO discuss what to do
			return -1;
		}
		else
		{
			if ((write) && (predicate[0]!='\0'))
			{
				// Add predicate in comments
				if (obi_view_add_comment(view, PREDICATE_KEY, predicate) < 0)
				{
					obi_set_errno(OBIVIEW_ERROR);
					obidebug(1, "\nError adding a verified predicate (%s) in the comments of a view.", predicate);
					free(predicate);
					return -1;
				}
			}
			free(predicate);
		}
	}
	return 0;
}


// TODO predicate function that goes through each line / each elements


/**********************************************************************
 *
 * D E F I N I T I O N   O F   T H E   P U B L I C   F U N C T I O N S
 *
 **********************************************************************/


bool obi_view_exists(OBIDMS_p dms, const char* view_name)
{
	struct dirent* dp;
	char*		   file_name;

	// Check finished views
	// Create file name
	file_name = build_obiview_file_name(view_name);
	if (file_name == NULL)
		return -1;

	rewinddir(dms->view_directory);
	while ((dp = readdir(dms->view_directory)) != NULL)
	{
		if ((dp->d_name)[0] == '.')
			continue;
		if (strcmp(dp->d_name, file_name) == 0)
		{
			free(file_name);
			return true;
		}
	}

	free(file_name);

	// Check unfinished views
	// Create file name
	file_name = build_unfinished_obiview_file_name(view_name);
	if (file_name == NULL)
		return -1;

	rewinddir(dms->view_directory);
	while ((dp = readdir(dms->view_directory)) != NULL)
	{
		if ((dp->d_name)[0] == '.')
			continue;
		if (strcmp(dp->d_name, file_name) == 0)
		{
			free(file_name);
			return true;
		}
	}

	free(file_name);

	return false;
}


Obiview_p obi_new_view(OBIDMS_p dms, const char* view_name, Obiview_p view_to_clone, index_t* line_selection, const char* comments)
{
	Obiview_p 		view;
	int 			i;
	index_t 		line_nb;
	OBIDMS_column_p column;
	int             comments_ok;

	// Check that the DMS is a valid pointer
	if (dms == NULL)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError creating a view: DMS pointer is NULL");
		return NULL;
	}

	// Check that the view name pointer is valid
	if (view_name == NULL)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError creating a view: view name is NULL");
		return NULL;
	}

	// Check uniqueness of name
	if (obi_view_exists(dms, view_name))
	{
		obi_set_errno(OBIVIEW_ALREADY_EXISTS_ERROR);
		obidebug(1, "\nName of new view ('%s') already exists", view_name);
		return NULL;
	}

	// Check that the view name is not 'taxonomy' (used for URIs)
	if (strcmp(view_name, "taxonomy") == 0)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nView name can not be 'taxonomy'");
		return NULL;
	}

	// Allocate memory for view structure
	view = (Obiview_p) malloc(sizeof(Obiview_t));
	if (view == NULL)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError allocating memory for a view");
		return NULL;
	}

	view->dms = dms;
	view->read_only = false;

	// Create view file
	if (create_obiview_file(dms, view_name) < 0)
	{
		free(view);
		return NULL;
	}

	// Map view file
	view->infos = obi_view_map_file(dms, view_name, false);
	if (view->infos == NULL)
	{
		obidebug(1, "\nError mapping the informations of a new view");
		free(view);
		return NULL;
	}

	// Flag the view as being a work in progress
	(view->infos)->finished = false;

	// Write used size in view file for initial structure
	(view->infos)->used_size = sizeof(Obiview_infos_t);

	// Clone view to clone if there is one
	if (view_to_clone != NULL)
	{
		if ((view_to_clone->infos)->finished == false)
		{
			obi_set_errno(OBIVIEW_ERROR);
			obidebug(1, "\nA view can not be cloned if it is not finished");
			obi_view_unmap_file(view->dms, view->infos);
			free(view);
			return NULL;
		}

		// If the view to clone has an associated line selection and there is no new line selection, open the associated line selection
		if ((view_to_clone->line_selection != NULL) && (line_selection == NULL))
		{
			view->line_selection = obi_open_column(dms, ((view_to_clone->line_selection)->header)->name, ((view_to_clone->line_selection)->header)->version);
			if (view->line_selection == NULL)
			{
				obi_view_unmap_file(view->dms, view->infos);
				free(view);
				return NULL;
			}
			(view->infos)->line_count = (view_to_clone->infos)->line_count;
		}
		// If there is a new line selection, build it by combining it with the one from the view to clone if there is one
		else if (line_selection != NULL)
		{
			view->line_selection = obi_create_column(view->dms, LINES_COLUMN_NAME, OBI_IDX, 0, 1, NULL, false, false, false, NULL, NULL, -1, NULL);
			if ((view->line_selection) == NULL)
			{
				obidebug(1, "\nError creating a column corresponding to a line selection");
				obi_view_unmap_file(view->dms, view->infos);
				free(view);
				return NULL;
			}

			(view->infos)->all_lines = false;
			(view->infos)->line_count = 0;
			i = 0;
			for (i=0; line_selection[i] != -1; i++)
			{
				line_nb = line_selection[i];

				if (line_nb > (view_to_clone->infos)->line_count)
				{
					obi_set_errno(OBIVIEW_ERROR);
					obidebug(1, "\nError trying to select a line for a new view that is beyond the line count of the view to clone");
					obi_close_column(view->line_selection);
					obi_view_unmap_file(view->dms, view->infos);
					free(view);
					return NULL;
				}

				if (view_to_clone->line_selection != NULL)
					line_nb = obi_column_get_index_with_elt_idx(view_to_clone->line_selection, line_nb, 0);

				if (obi_column_set_index_with_elt_idx(view->line_selection, ((view->line_selection)->header)->lines_used, 0, line_nb) < 0)
				{
					obi_close_column(view->line_selection);
					obi_view_unmap_file(view->dms, view->infos);
					free(view);
					return NULL;
				}

				// Update view line count
				((view->infos)->line_count)++;
			}
		}
		else	// If there is no line selection associated with the view to clone or the new view
		{
			view->line_selection = NULL;
			(view->infos)->all_lines = true;
			(view->infos)->line_count = (view_to_clone->infos)->line_count;
		}

		// Fill informations
		strcpy((view->infos)->view_type, (view_to_clone->infos)->view_type);
		strcpy((view->infos)->created_from, (view_to_clone->infos)->name);
	}

	// Else, fill empty view structure
	else
	{
		(view->infos)->column_count 	  = 0;
		(view->infos)->line_count   	  = 0;
		(view->infos)->all_lines		  = true;
		((view->infos)->created_from)[0]  = '\0';
		((view->infos)->view_type)[0]     = '\0';
		view->line_selection     		  = NULL;
		view->columns                     = NULL;
	}

	// Fill last informations
	strcpy((view->infos)->name, view_name);
	(view->infos)->creation_date = time(NULL);

	// Fill automatic predicate functions
	view->nb_predicates = 1;
	view->predicate_functions = malloc((view->nb_predicates) * sizeof(char* (*) (Obiview_p)));
	if (view->predicate_functions == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating memory for view predicates");
		return NULL;
	}
	(view->predicate_functions)[0] = view_check_qual_match_seqs;

	// Write comments
	// Comments must be a json string, even empty
	if ((strcmp(comments, "") == 0) || (comments == NULL))
		comments_ok = obi_view_write_comments(view, "{}");
	else
		comments_ok = obi_view_write_comments(view, comments);
	if (comments_ok < 0)
	{
		obidebug(1, "\nError writing comments when creating a view");
		close_view(view);
		return NULL;
	}

	// Add the comment specifying the name of the cloned view if there is one
	if (view_to_clone != NULL)
	{
		if (obi_view_add_comment(view, "Cloned from", (view_to_clone->infos)->name) < 0)
		{
			obidebug(1, "\nError adding comment about cloned view when creating a view");
			close_view(view);
			return NULL;
		}
	}

	// Store reference for line selection
	if (view->line_selection == NULL)
	{
		(((view->infos)->line_selection).column_name)[0] = '\0';
		((view->infos)->line_selection).version = -1;
	}
	else
	{
		strcpy(((view->infos)->line_selection).column_name, ((view->line_selection)->header)->name);
		((view->infos)->line_selection).version = ((view->line_selection)->header)->version;
	}

	// Initialize linked list of column pointers
	view->columns = NULL;

	// Create the column dictionary (hash table) associating column names (or aliases) to column pointers
	if (create_column_dict(view) < 0)
	{
		close_view(view);
		return NULL;
	}

	// Once the view has been created with all its elements and informations, add the columns if the view is cloned from another view
	if (view_to_clone != NULL)
	{
		(view->infos)->column_count = 0;
		for (i=0; i<((view_to_clone->infos)->column_count); i++)
		{
			column = *((OBIDMS_column_p*)ll_get(view_to_clone->columns, i));
			if (column == NULL)
			{
				obi_set_errno(OBIVIEW_ERROR);
				obidebug(1, "\nError getting a column from the linked list of column pointers of a view");
				return NULL;
			}
			if (obi_view_add_column(view,
									(column->header)->name,
									(column->header)->version,
									(((view_to_clone->infos)->column_references)[i]).alias,
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
									false)
					< 0)
			{
				obidebug(1, "\nError adding a column in a new view from a view to clone");
				if (view->line_selection != NULL)
					obi_close_column(view->line_selection);
				obi_view_unmap_file(view->dms, view->infos);
				free(view);
				return NULL;
			}
		}
	}

	return view;
}


Obiview_p obi_new_view_cloned_from_name(OBIDMS_p dms, const char* view_name, const char* view_to_clone_name, index_t* line_selection, const char* comments)
{
	Obiview_p view;
	Obiview_p view_to_clone;

	view_to_clone = obi_open_view(dms, view_to_clone_name);
	if (view_to_clone == NULL)
		return NULL;
	view = obi_new_view(dms, view_name, view_to_clone, line_selection, comments);

	close_view(view_to_clone);

	return view;
}


Obiview_p obi_new_view_nuc_seqs(OBIDMS_p dms, const char* view_name, Obiview_p view_to_clone, index_t* line_selection, const char* comments, bool quality_column, bool create_default_columns)
{
	Obiview_p 		view;
	OBIDMS_column_p associated_nuc_column;
	int				nb_predicates;

	if (view_to_clone != NULL)
	{ // Check that the view to clone is already a NUC_SEQS view
		if (strcmp((view_to_clone->infos)->view_type, VIEW_TYPE_NUC_SEQS))
		{
			obi_set_errno(OBIVIEW_ERROR);
			obidebug(1, "Trying to clone a non-NUC SEQS view to create a NUC SEQS view");
			return NULL;
		}
		// Check if there is a quality column
		if (obi_view_get_column(view_to_clone, QUALITY_COLUMN) != NULL)
			quality_column = true;
		else
			quality_column = false;
	}

	view = obi_new_view(dms, view_name, view_to_clone, line_selection, comments);
	if (view == NULL)
		return NULL;

	strcpy((view->infos)->view_type, VIEW_TYPE_NUC_SEQS);

	if ((view_to_clone == NULL) && create_default_columns)
	{
		// Adding sequence column
		if (obi_view_add_column(view, NUC_SEQUENCE_COLUMN, -1, NULL, OBI_SEQ, 0, 1, NULL, false, false, false, NULL, NULL, -1, "{}", true) < 0)	// discuss using same indexer "NUC_SEQ_INDEXER"
		{
			obidebug(1, "Error adding an obligatory column in a nucleotide sequences view");
			return NULL;
		}
		// Adding id column
		if (obi_view_add_column(view, ID_COLUMN, -1, NULL, OBI_STR, 0, 1, NULL, false, false, false, NULL, NULL, -1, "{}", true) < 0)
		{
			obidebug(1, "Error adding an obligatory column in a nucleotide sequences view");
			return NULL;
		}
		// Adding definition column
		if (obi_view_add_column(view, DEFINITION_COLUMN, -1, NULL, OBI_STR, 0, 1, NULL, false, false, false, NULL, NULL, -1, "{}", true) < 0)
		{
			obidebug(1, "Error adding an obligatory column in a nucleotide sequences view");
			return NULL;
		}
		// Adding quality column
		if (quality_column)
		{
			associated_nuc_column = obi_view_get_column(view, NUC_SEQUENCE_COLUMN);
			if (obi_view_add_column(view, QUALITY_COLUMN, -1, NULL, OBI_QUAL, 0, 1, NULL, false, false, false, NULL, (associated_nuc_column->header)->name, (associated_nuc_column->header)->version, "{}", true) < 0)		// TODO discuss automatic association
			{
				obidebug(1, "Error adding an obligatory column in a nucleotide sequences view");
				return NULL;
			}
		}
	}

	// Add predicate functions specific to the view type
	// TODO macros?

//	if (quality_column)  TODO
//		nb_predicates = view->nb_predicates + 4;
//	else
    nb_predicates = view->nb_predicates + 3;

	if (view->nb_predicates == 0)
		view->predicate_functions = malloc(nb_predicates * sizeof(char* (*) (Obiview_p)));
	else
		view->predicate_functions = realloc(view->predicate_functions, nb_predicates * sizeof(char* (*) (Obiview_p)));

	if (view->predicate_functions == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating memory for view predicates");
		return NULL;
	}

	(view->predicate_functions)[(view->nb_predicates)] = view_has_nuc_sequence_column;
	(view->predicate_functions)[(view->nb_predicates) + 1] = view_has_id_column;
	(view->predicate_functions)[(view->nb_predicates) + 2] = view_has_definition_column;
//	if (quality_column)   # TODO discuss. Commented bc for example with obi annotate, clone view so clone predicate, then modify seq, so quality is deleted, and predicate boom
//		(view->predicate_functions)[(view->nb_predicates) + 3] = view_has_quality_column;

	view->nb_predicates = nb_predicates;

	return view;
}


Obiview_p obi_new_view_nuc_seqs_cloned_from_name(OBIDMS_p dms, const char* view_name, const char* view_to_clone_name, index_t* line_selection, const char* comments)
{
	Obiview_p view;
	Obiview_p view_to_clone;

	view_to_clone = obi_open_view(dms, view_to_clone_name);
	if (view_to_clone == NULL)
		return NULL;
	view = obi_new_view_nuc_seqs(dms, view_name, view_to_clone, line_selection, comments, false, false);

	close_view(view_to_clone);

	return view;
}


Obiview_p obi_clone_view(OBIDMS_p dms, Obiview_p view_to_clone, const char* view_name, index_t* line_selection, const char* comments)
{
	if (view_to_clone == NULL)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError: pointer on view to clone is NULL");
		return NULL;
	}

	if (strcmp((view_to_clone->infos)->view_type, VIEW_TYPE_NUC_SEQS) == 0)
		return obi_new_view_nuc_seqs(dms, view_name, view_to_clone, line_selection, comments, false, false);
	else	// Non-typed view
		return obi_new_view(dms, view_name, view_to_clone, line_selection, comments);
}


Obiview_p obi_clone_view_from_name(OBIDMS_p dms, const char* view_to_clone_name, const char* view_name, index_t* line_selection, const char* comments)
{
	Obiview_p view;
	Obiview_p view_to_clone;

	view_to_clone = obi_open_view(dms, view_to_clone_name);
	if (view_to_clone == NULL)
	{
		obidebug(1, "\nError: could not open view to clone");
		return NULL;
	}

	view = obi_clone_view(dms, view_to_clone, view_name, line_selection, comments);

	close_view(view_to_clone);

	return view;
}


Obiview_infos_p obi_view_map_file(OBIDMS_p dms, const char* view_name, bool finished)
{
	char*				file_name;
	Obiview_infos_p		view_infos;
	int 				obiview_file_descriptor;
	size_t  			file_size;
	int 				open_flag;
	int					mmap_flag;

	// Create file name
	if (finished)
		file_name = build_obiview_file_name(view_name);
	else
		file_name = build_unfinished_obiview_file_name(view_name);
	if (file_name == NULL)
		return NULL;

	// Set flags (read-only or not)
	if (finished)
	{
		open_flag = O_RDONLY;
		mmap_flag = PROT_READ;
	}
	else
	{
		open_flag = O_RDWR;
		mmap_flag = PROT_READ | PROT_WRITE;
	}

    // Open view file
	obiview_file_descriptor = openat(dms->view_dir_fd, file_name, open_flag, 0777);
	if (obiview_file_descriptor < 0)
	{
		if (errno == ENOENT)
		{
			obidebug(1, "\nError opening an obiview file: View %s does not exist", view_name);
		}
		else
		{
			obidebug(1, "\nError opening an obiview file");
		}
		obi_set_errno(OBIVIEW_ERROR);
		free(file_name);
		return NULL;
	}

	free(file_name);

	// Get file size
	if (read(obiview_file_descriptor, &file_size, sizeof(size_t)) < ((ssize_t) sizeof(size_t)))
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError reading the file size in an obiview file");
		close(obiview_file_descriptor);
		return NULL;
	}

	// Map the view infos structure
	view_infos = mmap(NULL,
				 	  file_size,
					  mmap_flag,
					  MAP_SHARED,
					  obiview_file_descriptor,
					  0
	   	   	 	 	 );
	if (view_infos == NULL)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError mapping an obiview file");
		return NULL;
	}

	if (close(obiview_file_descriptor) < 0)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError closing a view file");
		return NULL;
	}

	return view_infos;
}


int obi_view_unmap_file(OBIDMS_p dms, Obiview_infos_p view_infos)
{
	char* 	file_name;
	int 	obiview_file_descriptor;
	size_t  file_size;

	// Get file name
	if (view_infos->finished)
		file_name = build_obiview_file_name(view_infos->name);
	else
		file_name = build_unfinished_obiview_file_name(view_infos->name);
	if (file_name == NULL)
		return -1;

	// Open view file
	obiview_file_descriptor = openat(dms->view_dir_fd, file_name, O_RDONLY, 0777);
	if (obiview_file_descriptor < 0)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError opening an obiview file (%s) >%s<", file_name, dms->dms_name);
		free(file_name);
		return -1;
	}

	free(file_name);

	// Unmap the view infos structure
	file_size = view_infos->file_size;
	if (munmap(view_infos, file_size) < 0)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError unmapping an obiview file");
		close(obiview_file_descriptor);
		return -1;
	}

	if (close(obiview_file_descriptor) < 0)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError closing a view file");
		return -1;
	}

	return 0;
}


Obiview_p obi_open_view(OBIDMS_p dms, const char* view_name)
{
	Obiview_p			view;
	const char* 		column_name;
	obiversion_t		column_version;
	OBIDMS_column_p		column_pointer;
	int					i;

	// Check that the DMS is a valid pointer
	if (dms == NULL)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError opening a view: DMS pointer is NULL");
		return NULL;
	}

	// Check that the view name pointer is valid
	if (view_name == NULL)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError opening a view: view name is NULL");
		return NULL;
	}

	// Allocate the memory for the view structure
	view = (Obiview_p) malloc(sizeof(Obiview_t));
	if (view == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating memory for a view");
		return NULL;
	}

	// Initialize view informations
	view->dms = dms;
	view->read_only = true;
	view->nb_predicates = 0;
	view->predicate_functions = NULL;
	view->columns = NULL;

	// Map view file
	view->infos = obi_view_map_file(dms, view_name, true);
	if ((view->infos) == NULL)
	{
		free(view);
		return NULL;
	}

	// Open the line selection associated with the view
	if ((view->infos)->all_lines)
		view->line_selection = NULL;
	else
	{
		view->line_selection = obi_open_column(dms, ((view->infos)->line_selection).column_name, ((view->infos)->line_selection).version);
		if (view->line_selection == NULL)
		{
			obidebug(1, "\nError opening a line selection for a view");
			obi_view_unmap_file(view->dms, view->infos);
			free(view);
			return NULL;
		}
	}

	// Open the columns to read
	for (i=0; i < ((view->infos)->column_count); i++)
	{
		column_name = ((((view->infos)->column_references)[i]).column_refs).column_name;
		column_version = ((((view->infos)->column_references)[i]).column_refs).version;

		column_pointer = obi_open_column(dms, column_name, column_version);
		if (column_pointer == NULL)
		{
			obidebug(1, "\nError opening a column for a view: column %d: %s, version %d", i, column_name, column_version);
			close_view(view);
			return NULL;
		}
		view->columns = ll_add(view->columns, column_pointer);
		if (view->columns == NULL)
		{
			obidebug(1, "\nError adding a column in the column linked list of a view: column %d: %s, version %d", i, column_name, column_version);
			close_view(view);
			return NULL;
		}
	}

	// Create the column dictionary associating each column alias with its pointer
	if (create_column_dict(view) < 0)
	{
		obidebug(1, "\nError creating the column dictionary when opening a view");
		close_view(view);
		return NULL;
	}

	return view;
}


// TODO return a pointer on the column?
int obi_view_add_column(Obiview_p    view,
						char*  column_name,
						obiversion_t version_number,
						const char*  alias,
						OBIType_t    data_type,
						index_t      nb_lines,
						index_t      nb_elements_per_line,
						char*        elements_names,
						bool         elt_names_formatted,
						bool		 tuples,
						bool         to_eval,
						const char*  indexer_name,
						const char*  associated_column_name,
						obiversion_t associated_column_version,
						const char*  comments,
						bool         create)	// all infos for creation or open
{
	int             			i;
	OBIDMS_column_p 			column;
	OBIDMS_column_p 			column_buffer;

	//for ( ; *column_name; ++column_name) *column_name = tolower(*column_name);

	// Check that the view is not read-only
	if (view->read_only)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError trying to add a column in a read-only view");
		return -1;
	}

	// If there is a line selection , clone the columns to delete the line selection
	if (create && (view->line_selection != NULL))
	{
		for (i=0; i<((view->infos)->column_count); i++)
		{
			{ // Clone with the right line selection and replace for all columns
				// Save pointer to close column after cloning
				column_buffer = *((OBIDMS_column_p*)ll_get(view->columns, i));
				if (column_buffer == NULL)
				{
					obi_set_errno(OBIVIEW_ERROR);
					obidebug(1, "\nError getting a column to clone from the linked list of column pointers of a view");
					return -1;
				}

				// Clone and replace the column in the view
				column = obi_clone_column(view->dms, view->line_selection, (column_buffer->header)->name, (column_buffer->header)->version, 1);
				if (column == NULL)
				{
					obi_set_errno(OBIVIEW_ERROR);
					obidebug(1, "\nError cloning a column to replace in a view");
					return -1;
				}

				// Change the pointer in the linked list of column pointers
				if (ll_set(view->columns, i, column) < 0)
				{
					obi_set_errno(OBIVIEW_ERROR);
					obidebug(1, "\nError changing the column pointer of a cloned column in the linked list of column pointers of a view");
					return -1;
				}

				// Close old cloned column
				obi_close_column(column_buffer);
			}
		}

		// Close old line selection
		if (view->line_selection != NULL)
		{
			obi_close_column(view->line_selection);
			view->line_selection = NULL;
			// Update line selection reference
			(((view->infos)->line_selection).column_name)[0] = '\0';
			((view->infos)->line_selection).version = -1;
		}
	}

	// Update the line count if needed
	if (create)
	{
		if ((view->infos)->line_count > nb_lines)
			nb_lines = (view->infos)->line_count;
		else if (nb_lines > (view->infos)->line_count)
			update_lines(view, nb_lines);
	}

	// Open or create the column
	if (create)
	{	// Create column
		column = obi_create_column(view->dms, column_name, data_type, nb_lines, nb_elements_per_line, elements_names, elt_names_formatted, tuples, to_eval, indexer_name, associated_column_name, associated_column_version, comments);
		if (column == NULL)
		{
			obidebug(1, "\nError creating a column to add to a view");
			return -1;
		}
		(column->header)->lines_used = nb_lines;
	}
	else
	{ // Open column
		column = obi_open_column(view->dms, column_name, version_number);
		if (column == NULL)
		{
			obidebug(1, "\nError opening a column to add to a view: %s, version %d", column_name, version_number);
			return -1;
		}
		 // - If there is a line selection:
		 // 		- The column's lines_used attribute must be at least the view's line count
		 // - If there is no line selection:
		 //    	- If it's the first column in the view:
		 //		 	- The view's line count is set to the column's lines_used attribute
		 //  	- If it's not the first column in the view:
		 //  		- The column's lines_used attribute must be equal to the view's line count
		if ((view->line_selection != NULL) && ((column->header)->lines_used < (view->infos)->line_count))
		{ // - If there is a line selection, the column's lines_used attribute must be at least the view's line count
			obi_set_errno(OBIVIEW_ERROR);
			obidebug(1, "\nError adding an existing column to a view: the column's lines_used attribute (%lld) must be equal to or greater than the view's line count (%lld)", (column->header)->lines_used, (view->infos)->line_count);
			return -1;
		}
		else if (view->line_selection == NULL)
		{ // If there is no line selection:
			if ((view->infos)->column_count == 0)	// If it's the first column in the view:
				(view->infos)->line_count = (column->header)->lines_used;   // The view's line count is set to the column's lines_used attribute
			else if ((column->header)->lines_used != (view->infos)->line_count)
			{ // If it's not the first column in the view, the column's lines_used attribute must be equal to the view's line count
				obi_set_errno(OBIVIEW_ERROR);
				obidebug(1, "\nError adding an existing column to a view: the column's lines_used attribute (%lld) must be equal to the view's line count (%lld)", (column->header)->lines_used, (view->infos)->line_count);
				return -1;
			}
		}
	}

	// Store column pointer in the view structure
	view->columns = ll_add(view->columns, column);
	if (view->columns == NULL)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError adding a column in the linked list of column pointers of a view: column %s, version %d", column_name, version_number);
		return -1;
	}

	// If an alias is not defined, it's the original name of the column.
	if ((alias == NULL) || (*alias == '\0'))
		alias = column_name;

	// Save column alias
	strcpy((((view->infos)->column_references)[(view->infos)->column_count]).alias, alias);

	// Update column count in view
	(view->infos)->column_count++;

	// Update column references and dictionary
	if (update_column_refs_and_dict(view) < 0)
	{
		obidebug(1, "\nError updating column references and dictionary after adding a column to a view");
		return -1;
	}

	// Print dict
//	for (i=0; i<((view->infos)->column_count); i++)
//	{
//		fprintf(stderr, "\n\n2305 alias: %s", (((view->infos)->column_references)[i]).alias);
//		fprintf(stderr, "\npointer: %x\n", obi_view_get_column(view, (((view->infos)->column_references)[i]).alias));
//	}

	return 0;
}


int obi_view_delete_column(Obiview_p view, const char* column_name, bool delete_file)
{
	int  i;
	bool found;
	OBIDMS_column_p column;
	char* col_to_delete_path;

	// Check that the view is not read-only
	if (view->read_only)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError trying to delete a column in a read-only view");
		return -1;
	}

	found = false;
	for (i=0; i<((view->infos)->column_count); i++)
	{
		if ((!found) && (!strcmp((((view->infos)->column_references)[i]).alias, column_name)))
		{
			column = *((OBIDMS_column_p*)ll_get(view->columns, i));
			if (column == NULL)
			{
				obi_set_errno(OBIVIEW_ERROR);
				obidebug(1, "\nError getting a column from the linked list of column pointers of a view when deleting a column from a view");
				return -1;
			}
			// Keep column path if need to delete the file
			if (delete_file)
			{
				col_to_delete_path = obi_column_full_path(view->dms, column->header->name, column->header->version);
				if (col_to_delete_path == NULL)
				{
					obidebug(1, "\nError getting a column file path when deleting a column");
					return -1;
				}
			}

			obi_close_column(column);

			// Delete file if needed
			if (delete_file)
			{
				if (remove(col_to_delete_path) < 0)
				{
					obi_set_errno(OBICOL_UNKNOWN_ERROR);
					obidebug(1, "\nError deleting a column file when deleting unfinished columns: file %s", col_to_delete_path);
					return -1;
				}
				free(col_to_delete_path);
			}

			view->columns = ll_delete(view->columns, i);
			// TODO how do we check for error? NULL can be empty list
			found = true;
		}
		if (found)
		{
			if (i != (((view->infos)->column_count) - 1))	// not the last one
			{	// Shift the references
				strcpy((((view->infos)->column_references)[i]).alias, (((view->infos)->column_references)[i+1]).alias);
				strcpy(((((view->infos)->column_references)[i]).column_refs).column_name, ((((view->infos)->column_references)[i+1]).column_refs).column_name);
				((((view->infos)->column_references)[i]).column_refs).version = ((((view->infos)->column_references)[i+1]).column_refs).version;
			}
			else  	// Last column
			{
				strcpy((((view->infos)->column_references)[i]).alias, "");
				strcpy(((((view->infos)->column_references)[i]).column_refs).column_name, "");
				((((view->infos)->column_references)[i]).column_refs).version = -1;
			}
		}
	}

	if (!found)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError trying to delete a column: column not found");
		return -1;
	}

	((view->infos)->column_count)--;

	// Update column dictionary
	update_column_dict(view);

	return 0;
}


OBIDMS_column_p obi_view_get_column(Obiview_p view, const char* column_name)
{
	OBIDMS_column_p* column_pp;
	column_pp = (OBIDMS_column_p*)(ht_get(view->column_dict, column_name));
	if (column_pp == NULL)
		return NULL;
	return (*column_pp);
}


OBIDMS_column_p* obi_view_get_pointer_on_column_in_view(Obiview_p view, const char* column_name)
{
	return (OBIDMS_column_p*)(ht_get(view->column_dict, column_name));
}


bool obi_view_column_exists(Obiview_p view, const char* column_name)
{
	if (obi_view_get_column(view, column_name) == NULL)
		return false;
	else
		return true;
}


int obi_view_create_column_alias(Obiview_p view, const char* current_name, const char* alias)
{
	int i;
	bool found;

	// Check that the view is not read-only
	if (view->read_only)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError trying to change a column alias in a read-only view");
		return -1;
	}

	// Check that the new alias is unique
	if (ht_get(view->column_dict, alias) != NULL)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError: the new name/alias identifying a column in a view is not unique");
		return -1;
	}

	// Set the new alias in the column references
	found = false;
	for (i=0; i<((view->infos)->column_count); i++)
	{
		if (!strcmp((((view->infos)->column_references)[i]).alias, current_name))
		{
			strcpy((((view->infos)->column_references)[i]).alias, alias);
			found = true;
		}
	}

	if (found == false)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError: can't find the column '%s' to change its alias", current_name);
		return -1;
	}

	// Update the column dictionary
	update_column_dict(view);

	return 0;
}


int obi_view_write_comments(Obiview_p view, const char* comments)
{
	size_t new_size;

	// Check that the view is not read-only
	if (view->read_only)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError trying to write comments in a read-only view");
		return -1;
	}

	if (comments == NULL)
		return 0;	// TODO or error? discuss

	new_size = sizeof(Obiview_infos_t) + strlen(comments) + 1;

	// Check if the file has to be enlarged
	if (new_size >= (view->infos)->file_size)
	{
		if (enlarge_view_file(view, new_size) < 0)
			return -1;
	}

	strcpy((view->infos)->comments, comments);

	(view->infos)->used_size = new_size;

	return 0;
}


int obi_view_add_comment(Obiview_p view, const char* key, const char* value)
{
	char* new_comments = NULL;

	// Check that the view is not read-only
	if (view->read_only)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError trying to add a comment to a read-only view");
		return -1;
	}

	new_comments = obi_add_comment((view->infos)->comments, key, value);
	if (new_comments == NULL)
	{
		obidebug(1, "\nError adding a comment to a view, key: %s, value: %s", key, value);
		return -1;
	}

	if (obi_view_write_comments(view, new_comments) < 0)
	{
		obidebug(1, "\nError adding a comment to a view, key: %s, value: %s", key, value);
		return -1;
	}

	free(new_comments);

	return 0;
}


int obi_save_and_close_view(Obiview_p view)
{
	// Finish and save the view if it is not read-only
	if ( ! (view->read_only))
		if (finish_view(view) < 0)
			return -1;

	if (close_view(view) < 0)
		return -1;

	return 0;
}


int obi_dms_has_unfinished_views(OBIDMS_p dms)
{
	struct dirent*  dp;
	int		        i;
	char*           full_path;
	char*		    relative_path;
	Obiview_infos_p view_infos;
	char*           view_name;
	int    			ret_value;

	ret_value = 0;

	// Look for unfinished views and delete them
	rewinddir(dms->view_directory);
	while ((dp = readdir(dms->view_directory)) != NULL)
	{
		if ((dp->d_name)[0] == '.')
			continue;
		i=0;
		while ((dp->d_name)[i] != '.')
			i++;
		relative_path = (char*) malloc(strlen(VIEW_DIR_NAME) + strlen(dp->d_name) + 2);
		strcpy(relative_path, VIEW_DIR_NAME);
		strcat(relative_path, "/");
		strcat(relative_path, dp->d_name);
		full_path = obi_dms_get_full_path(dms, relative_path);
		free(relative_path);
		if (full_path == NULL)
		{
			obidebug(1, "\nError getting the full path to a view file when cleaning unfinished views");
			ret_value = -1;
			continue;
		}

		if (strcmp((dp->d_name)+i, ".obiview_unfinished") == 0)
			ret_value = 1;

		else if (strcmp((dp->d_name)+i, ".obiview") == 0)
		{  // Check if the view was properly flagged as finished
			view_name = (char*) malloc((i+1) * sizeof(char));
			if (view_name == NULL)
			{
				obi_set_errno(OBI_MALLOC_ERROR);
				obidebug(1, "\nError allocating memory for a view name when deleting unfinished views: file %s", dp->d_name);
				ret_value = -1;
				continue;
			}
			strncpy(view_name, dp->d_name, i);
			view_name[i] = '\0';
			view_infos = obi_view_map_file(dms, view_name, true);
			if (view_infos == NULL)
			{
				obidebug(1, "\nError reading a view file when deleting unfinished views: file %s", dp->d_name);
				ret_value = -1;
				continue;
			}
			if (view_infos->finished == false)
				ret_value = 1;
		}
	}

	return ret_value;
}


int obi_clean_unfinished_views(OBIDMS_p dms)
{
	struct dirent*  dp;
	int		        i;
	char*           full_path;
	char*		    relative_path;
	Obiview_infos_p view_infos;
	char*           view_name;
	int    			ret_value;
	char*           to_delete[1000];
	int 			d;

	ret_value = 0;
	d = 0;

	// Look for unfinished views and delete them
	rewinddir(dms->view_directory);
	while ((dp = readdir(dms->view_directory)) != NULL)
	{
		if ((dp->d_name)[0] == '.')
			continue;
		i=0;
		while ((dp->d_name)[i] != '.')
			i++;
		relative_path = (char*) malloc(strlen(VIEW_DIR_NAME) + strlen(dp->d_name) + 2);
		strcpy(relative_path, VIEW_DIR_NAME);
		strcat(relative_path, "/");
		strcat(relative_path, dp->d_name);
		full_path = obi_dms_get_full_path(dms, relative_path);
		free(relative_path);
		if (full_path == NULL)
		{
			obidebug(1, "\nError getting the full path to a view file when cleaning unfinished views");
			ret_value = -1;
			continue;
		}
		if (strcmp((dp->d_name)+i, ".obiview_unfinished") == 0)
		{
			// Add to the list of files to delete (deleting in loop not safe)
			to_delete[d] = full_path;
			d++;
		}
		else if (strcmp((dp->d_name)+i, ".obiview") == 0)
		{  // Check if the view was properly flagged as finished
			view_name = (char*) malloc((i+1) * sizeof(char));
			if (view_name == NULL)
			{
				obi_set_errno(OBI_MALLOC_ERROR);
				obidebug(1, "\nError allocating memory for a view name when deleting unfinished views: file %s", dp->d_name);
				ret_value = -1;
				continue;
			}
			strncpy(view_name, dp->d_name, i);
			view_name[i] = '\0';
			view_infos = obi_view_map_file(dms, view_name, true);
			if (view_infos == NULL)
			{
				obidebug(1, "\nError reading a view file when deleting unfinished views: file %s", dp->d_name);
				ret_value = -1;
				continue;
			}
			if (view_infos->finished == false)
			{
				// Add to the list of files to delete (deleting in loop not safe)
				to_delete[d] = full_path;
				d++;
			}
		}
	}

	for (i=0; i<d; i++)
	{
		if (remove(to_delete[i]) < 0)
		{
			obi_set_errno(OBIVIEW_ERROR);
			obidebug(1, "\nError deleting a view file when deleting unfinished views: file %s", to_delete[i]);
			ret_value = -1;
		}
		free(to_delete[i]);
	}

	return ret_value;
}


int obi_rollback_view(Obiview_p view)
{
	int             i;
	int             ret_value;
	int             n;
	struct dirent*  dp;
	OBIDMS_column_p column;
	char*           column_file_path;
	char*           column_dir_name;
	char*           column_dir_path;
	char*           view_file_name;
	char*			view_relative_path;
	char*           view_full_path;

	ret_value = 0;

	// Don't rollback if view finished
	if (view->read_only)
		return ret_value;

	for (i=0; i<((view->infos)->column_count); i++)
	{
		column = *((OBIDMS_column_p*)ll_get(view->columns, i));
		if (column == NULL)
		{
			obi_set_errno(OBIVIEW_ERROR);
			obidebug(1, "\nError getting a column from the linked list of column pointers of a view when rollbacking the view");
			ret_value = -1;
			continue;
		}

		// Delete the column file if it was created by the view (it was if it is writable)
		if (column->writable)
		{
			// Build file and dir paths
			column_file_path = obi_column_full_path(view->dms, (column->header)->name, (column->header)->version);
			if (column_file_path == NULL)
			{
				obidebug(1, "\nError getting a column file path when rollbacking a view");
				ret_value = -1;
				continue;
			}
			column_dir_name = obi_build_column_directory_name((column->header)->name);
			if (column_dir_name == NULL)
			{
				obidebug(1, "\nError getting a column directory name when rollbacking a view");
				ret_value = -1;
			}
			column_dir_path = obi_dms_get_full_path(view->dms, column_dir_name);
			if (column_dir_path == NULL)
			{
				obidebug(1, "\nError getting a column directory path when rollbacking a view");
				ret_value = -1;
			}

			// Try to close the column (?)
			if (obi_close_column(column) < 0)
				ret_value = -1;

			// Delete the column file
			if (remove(column_file_path) < 0)
			{
				obi_set_errno(OBIVIEW_ERROR);
				obidebug(1, "\nError deleting a column file when rollbacking a view");
				ret_value = -1;
			}

			// Delete column dir if it's empty TODO doesn't happen because version file
			n = count_dir(column_dir_path);
			if (n == 0)
			{
				if (remove(column_dir_path) < 0)
				{
					obi_set_errno(OBIVIEW_ERROR);
					obidebug(1, "\nError deleting a column directory when rollbacking a view");
					ret_value = -1;
				}
			}
			free(column_file_path);
			free(column_dir_name);
			free(column_dir_path);
		}
	}
	// Delete line selection if there is one
	if (view->line_selection != NULL)
	{
		column = view->line_selection;
		if (column->writable)
		{
			// Build file and dir paths
			column_file_path = obi_column_full_path(view->dms, (column->header)->name, (column->header)->version);
			if (column_file_path == NULL)
			{
				obidebug(1, "\nError getting a column file path when rollbacking a view");
				ret_value = -1;
			}
			column_dir_name = obi_build_column_directory_name((column->header)->name);
			if (column_dir_name == NULL)
			{
				obidebug(1, "\nError getting a column directory name when rollbacking a view");
				ret_value = -1;
			}
			column_dir_path = obi_dms_get_full_path(view->dms, column_dir_name);
			if (column_dir_path == NULL)
			{
				obidebug(1, "\nError getting a column directory path when rollbacking a view");
				ret_value = -1;
			}

			// Try to close the column (?)
			if (obi_close_column(column) < 0)
				ret_value = -1;

			// Delete the column file
			if (remove(column_file_path) < 0)
			{
				obi_set_errno(OBIVIEW_ERROR);
				obidebug(1, "\nError deleting a column file when rollbacking a view");
				ret_value = -1;
			}

			// Delete column dir if it's empty  TODO doesn't happen because version file
			n = count_dir(column_dir_path);
			if (n == 0)
			{
				if (remove(column_dir_path) < 0)
				{
					obi_set_errno(OBIVIEW_ERROR);
					obidebug(1, "\nError deleting a column directory when rollbacking a view");
					ret_value = -1;
				}
			}
			free(column_file_path);
			free(column_dir_name);
			free(column_dir_path);
		}
	}

	// Delete view file
	view_file_name = (char*) malloc(strlen((view->infos)->name) + strlen(".obiview_unfinished") + 1);
	if (view_file_name == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating memory for a view file name");
		ret_value = -1;
	}
	else
	{
		strcpy(view_file_name, (view->infos)->name);
		strcat(view_file_name, ".obiview_unfinished");
		rewinddir((view->dms)->view_directory);
		while ((dp = readdir((view->dms)->view_directory)) != NULL)
		{
			if ((dp->d_name)[0] == '.')
				continue;
			if (strcmp(dp->d_name, view_file_name) == 0)
			{
				view_relative_path = (char*) malloc(strlen(VIEW_DIR_NAME) + strlen(view_file_name) + 2);
				strcpy(view_relative_path, VIEW_DIR_NAME);
				strcat(view_relative_path, "/");
				strcat(view_relative_path, view_file_name);
				view_full_path = obi_dms_get_full_path(view->dms, view_relative_path);
				remove(view_full_path);
				free(view_relative_path);
				free(view_full_path);
			}
		}
		free(view_file_name);
	}

	// Free the linked list of column pointers
	ll_free(view->columns);

	// Free the column dictionary
	ht_free(view->column_dict);
	free(view);

	return ret_value;
}


int obi_delete_view(OBIDMS_p dms, const char* view_name)
{
	char* view_file_name;
	char* view_relative_path;
	char* view_full_path;
	struct dirent*  dp;
	int finished_view;

	// Check that the view exists
	if (obi_view_exists(dms, view_name) == false)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError trying to delete a view: view '%s' does not exist", view_name);
		return -1;
	}

	// Check that the view is finished
	finished_view = view_is_finished(dms, view_name);
	if (finished_view == -1)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError trying to check if view '%s' is finished", view_name);
		return -1;
	}

	if (finished_view == 0)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError trying to delete a view: view '%s' is not finished", view_name);
		return -1;
	}

	// Delete view file
	view_file_name = (char*) malloc(strlen(view_name) + strlen(".obiview") + 1);
	if (view_file_name == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating memory for a view file name");
		return -1;
	}

	strcpy(view_file_name, view_name);
	strcat(view_file_name, ".obiview");
	rewinddir(dms->view_directory);
	while ((dp = readdir(dms->view_directory)) != NULL)
	{
		if ((dp->d_name)[0] == '.')
			continue;
		if (strcmp(dp->d_name, view_file_name) == 0)
		{
			view_relative_path = (char*) malloc(strlen(VIEW_DIR_NAME) + strlen(view_file_name) + 2);
			strcpy(view_relative_path, VIEW_DIR_NAME);
			strcat(view_relative_path, "/");
			strcat(view_relative_path, view_file_name);
			view_full_path = obi_dms_get_full_path(dms, view_relative_path);
			remove(view_full_path);
			free(view_relative_path);
			free(view_full_path);
		}
	}
	free(view_file_name);

	return 0;
}


int obi_create_auto_count_column(Obiview_p view)
{
	index_t         i;
	OBIDMS_column_p column;

	// Check that the view is not read-only
	if (view->read_only)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError trying to create an automatic count column in a read-only view");
		return -1;
	}

	if (obi_view_add_column(view, COUNT_COLUMN, -1, NULL, OBI_INT, 0, 1, NULL, false, false, false, NULL, NULL, -1, "{}", true) < 0)
	{
		obidebug(1, "Error adding an automatic count column in a view");
		return -1;
	}

	column = obi_view_get_column(view, COUNT_COLUMN);
	if (column == NULL)
	{
		obidebug(1, "Error adding an automatic count column in a view");
		return -1;
	}

	// Fill the column with 1s
	for (i=0; i < (view->infos)->line_count; i++)
	{
		if (obi_set_int_with_elt_idx_and_col_p_in_view(view, column, i, 0, 1) < 0)
		{
			obidebug(1, "Error adding an automatic count column in a view");
			return -1;
		}
	}

	return 0;
}


int obi_create_auto_id_column(Obiview_p view, const char* prefix)
{
	index_t         i;
	OBIDMS_column_p column;
	char*           id;

	// Check that the view is not read-only
	if (view->read_only)
	{
		obi_set_errno(OBIVIEW_ERROR);
		obidebug(1, "\nError trying to create an automatic count column in a read-only view");
		return -1;
	}

	// Delete old ID column if it exists
	if (obi_view_get_column(view, ID_COLUMN) != NULL)
	{
		if (obi_view_delete_column(view, ID_COLUMN, false) < 0)
		{
			obidebug(1, "Error deleting an ID column to replace it in a view");
			return -1;
		}
	}

	// Create the new ID column
	if (obi_view_add_column(view, ID_COLUMN, -1, NULL, OBI_STR, 0, 1, NULL, false, false, false, NULL, NULL, -1, "{}", true) < 0)
	{
		obidebug(1, "Error adding an automatic ID column in a view");
		return -1;
	}

	column = obi_view_get_column(view, ID_COLUMN);
	if (column == NULL)
	{
		obidebug(1, "Error adding an automatic ID column in a view");
		return -1;
	}

	// If prefix is NULL, use default prefix
	if (prefix == NULL)
		prefix = ID_PREFIX;

	// Fill the column with automatic ids
	for (i=0; i < (view->infos)->line_count; i++)
	{
		id = build_word_with_idx(prefix, i);
		if (id == NULL)
		{
			obidebug(1, "Error building an id for an automatic ID column");
			return -1;
		}
		if (obi_set_str_with_elt_idx_and_col_p_in_view(view, column, i, 0, id) < 0)
		{
			obidebug(1, "Error adding an automatic count column in a view");
			return -1;
		}
		free(id);
	}

	return 0;
}


// TODO Move to another file?
/*********** FOR BLOB COLUMNS ***********/

Obi_blob_p obi_get_blob_with_elt_idx_and_col_p_in_view(Obiview_p view, OBIDMS_column_p column_p, index_t line_nb, index_t element_idx)
{
	if (prepare_to_get_value_from_column(view, &line_nb) < 0)
		return OBIBlob_NA;
	return obi_column_get_blob_with_elt_idx(column_p, line_nb, element_idx);
}


Obi_blob_p obi_get_blob_with_elt_name_and_col_p_in_view(Obiview_p view, OBIDMS_column_p column_p, index_t line_nb, const char* element_name)
{
	index_t element_idx = obi_column_get_element_index_from_name(column_p, element_name);
	if (element_idx == OBIIdx_NA)
		return OBIBlob_NA;
	return obi_get_blob_with_elt_idx_and_col_p_in_view(view, column_p, line_nb, element_idx);
}


Obi_blob_p obi_get_blob_with_elt_idx_and_col_name_in_view(Obiview_p view, const char* column_name, index_t line_nb, index_t element_idx)
{
	OBIDMS_column_p column_p;
	column_p = obi_view_get_column(view, column_name);
	if (column_p == NULL)
		return OBIBlob_NA;
	return obi_get_blob_with_elt_idx_and_col_p_in_view(view, column_p, line_nb, element_idx);
}


Obi_blob_p obi_get_blob_with_elt_name_and_col_name_in_view(Obiview_p view, const char* column_name, index_t line_nb, const char* element_name)
{
	OBIDMS_column_p column_p;
	column_p = obi_view_get_column(view, column_name);
	if (column_p == NULL)
		return OBIBlob_NA;
	return obi_get_blob_with_elt_name_and_col_p_in_view(view, column_p, line_nb, element_name);
}

/*********** FOR BOOL COLUMNS ***********/

int obi_set_bool_with_elt_idx_and_col_p_in_view(Obiview_p view, OBIDMS_column_p column_p, index_t line_nb, index_t element_idx, obibool_t value)
{
	if (prepare_to_set_value_in_column(view, &column_p, &line_nb) < 0)
		return -1;
	return obi_column_set_obibool_with_elt_idx(column_p, line_nb, element_idx, value);
}


obibool_t obi_get_bool_with_elt_idx_and_col_p_in_view(Obiview_p view, OBIDMS_column_p column_p, index_t line_nb, index_t element_idx)
{
	if (prepare_to_get_value_from_column(view, &line_nb) < 0)
		return OBIBool_NA;
	return obi_column_get_obibool_with_elt_idx(column_p, line_nb, element_idx);
}


int obi_set_bool_with_elt_name_and_col_p_in_view(Obiview_p view, OBIDMS_column_p column_p, index_t line_nb, const char* element_name, obibool_t value)
{
	index_t element_idx = obi_column_get_element_index_from_name(column_p, element_name);
	if (element_idx == OBIIdx_NA)
		return -1;
	return obi_set_bool_with_elt_idx_and_col_p_in_view(view, column_p, line_nb, element_idx, value);
}


obibool_t obi_get_bool_with_elt_name_and_col_p_in_view(Obiview_p view, OBIDMS_column_p column_p, index_t line_nb, const char* element_name)
{
	index_t element_idx = obi_column_get_element_index_from_name(column_p, element_name);
	if (element_idx == OBIIdx_NA)
		return OBIBool_NA;
	return obi_get_bool_with_elt_idx_and_col_p_in_view(view, column_p, line_nb, element_idx);
}


int obi_set_bool_with_elt_name_and_col_name_in_view(Obiview_p view, const char* column_name, index_t line_nb, const char* element_name, obibool_t value)
{
	OBIDMS_column_p column_p;
	column_p = obi_view_get_column(view, column_name);
	if (column_p == NULL)
		return -1;
	return obi_set_bool_with_elt_name_and_col_p_in_view(view, column_p, line_nb, element_name, value);
}


int obi_set_bool_with_elt_idx_and_col_name_in_view(Obiview_p view, const char* column_name, index_t line_nb, index_t element_idx, obibool_t value)
{
	OBIDMS_column_p column_p;
	column_p = obi_view_get_column(view, column_name);
	if (column_p == NULL)
		return -1;
	return obi_set_bool_with_elt_idx_and_col_p_in_view(view, column_p, line_nb, element_idx, value);
}


obibool_t obi_get_bool_with_elt_idx_and_col_name_in_view(Obiview_p view, const char* column_name, index_t line_nb, index_t element_idx)
{
	OBIDMS_column_p column_p;
	column_p = obi_view_get_column(view, column_name);
	if (column_p == NULL)
		return OBIBool_NA;
	return obi_get_bool_with_elt_idx_and_col_p_in_view(view, column_p, line_nb, element_idx);
}


obibool_t obi_get_bool_with_elt_name_and_col_name_in_view(Obiview_p view, const char* column_name, index_t line_nb, const char* element_name)
{
	OBIDMS_column_p column_p;
	column_p = obi_view_get_column(view, column_name);
	if (column_p == NULL)
		return OBIBool_NA;
	return obi_get_bool_with_elt_name_and_col_p_in_view(view, column_p, line_nb, element_name);
}

/****************************************/


/*********** FOR CHAR COLUMNS ***********/

int obi_set_char_with_elt_idx_and_col_p_in_view(Obiview_p view, OBIDMS_column_p column, index_t line_nb, index_t element_idx, obichar_t value)
{
	if (prepare_to_set_value_in_column(view, &column, &line_nb) < 0)
		return -1;
	return obi_column_set_obichar_with_elt_idx(column, line_nb, element_idx, value);
}


obichar_t obi_get_char_with_elt_idx_and_col_p_in_view(Obiview_p view, OBIDMS_column_p column, index_t line_nb, index_t element_idx)
{
	if (prepare_to_get_value_from_column(view, &line_nb) < 0)
		return OBIChar_NA;
	return obi_column_get_obichar_with_elt_idx(column, line_nb, element_idx);
}


int obi_set_char_with_elt_name_and_col_p_in_view(Obiview_p view, OBIDMS_column_p column, index_t line_nb, const char* element_name, obichar_t value)
{
	index_t element_idx = obi_column_get_element_index_from_name(column, element_name);
	if (element_idx == OBIIdx_NA)
		return -1;
	return obi_set_char_with_elt_idx_and_col_p_in_view(view, column, line_nb, element_idx, value);
}


obichar_t obi_get_char_with_elt_name_and_col_p_in_view(Obiview_p view, OBIDMS_column_p column, index_t line_nb, const char* element_name)
{
	index_t element_idx = obi_column_get_element_index_from_name(column, element_name);
	if (element_idx == OBIIdx_NA)
		return OBIChar_NA;
	return obi_get_char_with_elt_idx_and_col_p_in_view(view, column, line_nb, element_idx);
}


int obi_set_char_with_elt_name_and_col_name_in_view(Obiview_p view, const char* column_name, index_t line_nb, const char* element_name, obichar_t value)
{
	OBIDMS_column_p column_p;
	column_p = obi_view_get_column(view, column_name);
	if (column_p == NULL)
		return -1;
	return obi_set_char_with_elt_name_and_col_p_in_view(view, column_p, line_nb, element_name, value);
}


int obi_set_char_with_elt_idx_and_col_name_in_view(Obiview_p view, const char* column_name, index_t line_nb, index_t element_idx, obichar_t value)
{
	OBIDMS_column_p column_p;
	column_p = obi_view_get_column(view, column_name);
	if (column_p == NULL)
		return -1;
	return obi_set_char_with_elt_idx_and_col_p_in_view(view, column_p, line_nb, element_idx, value);
}


obichar_t obi_get_char_with_elt_idx_and_col_name_in_view(Obiview_p view, const char* column_name, index_t line_nb, index_t element_idx)
{
	OBIDMS_column_p column_p;
	column_p = obi_view_get_column(view, column_name);
	if (column_p == NULL)
		return OBIChar_NA;
	return obi_get_char_with_elt_idx_and_col_p_in_view(view, column_p, line_nb, element_idx);
}


obichar_t obi_get_char_with_elt_name_and_col_name_in_view(Obiview_p view, const char* column_name, index_t line_nb, const char* element_name)
{
	OBIDMS_column_p column_p;
	column_p = obi_view_get_column(view, column_name);
	if (column_p == NULL)
		return OBIChar_NA;
	return obi_get_char_with_elt_name_and_col_p_in_view(view, column_p, line_nb, element_name);
}

/****************************************/


/*********** FOR FLOAT COLUMNS ***********/

int obi_set_float_with_elt_idx_and_col_p_in_view(Obiview_p view, OBIDMS_column_p column, index_t line_nb, index_t element_idx, obifloat_t value)
{
	if (prepare_to_set_value_in_column(view, &column, &line_nb) < 0)
		return -1;
	return obi_column_set_obifloat_with_elt_idx(column, line_nb, element_idx, value);
}


obifloat_t obi_get_float_with_elt_idx_and_col_p_in_view(Obiview_p view, OBIDMS_column_p column, index_t line_nb, index_t element_idx)
{
	if (prepare_to_get_value_from_column(view, &line_nb) < 0)
		return OBIFloat_NA;
	return obi_column_get_obifloat_with_elt_idx(column, line_nb, element_idx);
}


int obi_set_float_with_elt_name_and_col_p_in_view(Obiview_p view, OBIDMS_column_p column, index_t line_nb, const char* element_name, obifloat_t value)
{
	index_t element_idx = obi_column_get_element_index_from_name(column, element_name);
	if (element_idx == OBIIdx_NA)
		return -1;
	return obi_set_float_with_elt_idx_and_col_p_in_view(view, column, line_nb, element_idx, value);
}


obifloat_t obi_get_float_with_elt_name_and_col_p_in_view(Obiview_p view, OBIDMS_column_p column, index_t line_nb, const char* element_name)
{
	index_t element_idx = obi_column_get_element_index_from_name(column, element_name);
	if (element_idx == OBIIdx_NA)
		return OBIFloat_NA;
	return obi_get_float_with_elt_idx_and_col_p_in_view(view, column, line_nb, element_idx);
}


int obi_set_float_with_elt_name_and_col_name_in_view(Obiview_p view, const char* column_name, index_t line_nb, const char* element_name, obifloat_t value)
{
	OBIDMS_column_p column_p;
	column_p = obi_view_get_column(view, column_name);
	if (column_p == NULL)
		return -1;
	return obi_set_float_with_elt_name_and_col_p_in_view(view, column_p, line_nb, element_name, value);
}


int obi_set_float_with_elt_idx_and_col_name_in_view(Obiview_p view, const char* column_name, index_t line_nb, index_t element_idx, obifloat_t value)
{
	OBIDMS_column_p column_p;
	column_p = obi_view_get_column(view, column_name);
	if (column_p == NULL)
		return -1;
	return obi_set_float_with_elt_idx_and_col_p_in_view(view, column_p, line_nb, element_idx, value);
}


obifloat_t obi_get_float_with_elt_idx_and_col_name_in_view(Obiview_p view, const char* column_name, index_t line_nb, index_t element_idx)
{
	OBIDMS_column_p column_p;
	column_p = obi_view_get_column(view, column_name);
	if (column_p == NULL)
		return OBIFloat_NA;
	return obi_get_float_with_elt_idx_and_col_p_in_view(view, column_p, line_nb, element_idx);
}


obifloat_t obi_get_float_with_elt_name_and_col_name_in_view(Obiview_p view, const char* column_name, index_t line_nb, const char* element_name)
{
	OBIDMS_column_p column_p;
	column_p = obi_view_get_column(view, column_name);
	if (column_p == NULL)
		return OBIFloat_NA;
	return obi_get_float_with_elt_name_and_col_p_in_view(view, column_p, line_nb, element_name);
}

/****************************************/


/*********** FOR INT COLUMNS ***********/

int obi_set_int_with_elt_idx_and_col_p_in_view(Obiview_p view, OBIDMS_column_p column, index_t line_nb, index_t element_idx, obiint_t value)
{
	if (prepare_to_set_value_in_column(view, &column, &line_nb) < 0)
		return -1;
	return obi_column_set_obiint_with_elt_idx(column, line_nb, element_idx, value);
}


obiint_t obi_get_int_with_elt_idx_and_col_p_in_view(Obiview_p view, OBIDMS_column_p column, index_t line_nb, index_t element_idx)
{
	if (prepare_to_get_value_from_column(view, &line_nb) < 0)
		return OBIInt_NA;
	return obi_column_get_obiint_with_elt_idx(column, line_nb, element_idx);
}


int obi_set_int_with_elt_name_and_col_p_in_view(Obiview_p view, OBIDMS_column_p column, index_t line_nb, const char* element_name, obiint_t value)
{
	index_t element_idx = obi_column_get_element_index_from_name(column, element_name);
	if (element_idx == OBIIdx_NA)
		return -1;
	return obi_set_int_with_elt_idx_and_col_p_in_view(view, column, line_nb, element_idx, value);
}


obiint_t obi_get_int_with_elt_name_and_col_p_in_view(Obiview_p view, OBIDMS_column_p column, index_t line_nb, const char* element_name)
{
	index_t element_idx = obi_column_get_element_index_from_name(column, element_name);
	if (element_idx == OBIIdx_NA)
		return OBIInt_NA;
	return obi_get_int_with_elt_idx_and_col_p_in_view(view, column, line_nb, element_idx);
}


int obi_set_int_with_elt_name_and_col_name_in_view(Obiview_p view, const char* column_name, index_t line_nb, const char* element_name, obiint_t value)
{
	OBIDMS_column_p column_p;
	column_p = obi_view_get_column(view, column_name);
	if (column_p == NULL)
		return -1;
	return obi_set_int_with_elt_name_and_col_p_in_view(view, column_p, line_nb, element_name, value);
}


int obi_set_int_with_elt_idx_and_col_name_in_view(Obiview_p view, const char* column_name, index_t line_nb, index_t element_idx, obiint_t value)
{
	OBIDMS_column_p column_p;
	column_p = obi_view_get_column(view, column_name);
	if (column_p == NULL)
		return -1;
	return obi_set_int_with_elt_idx_and_col_p_in_view(view, column_p, line_nb, element_idx, value);
}


obiint_t obi_get_int_with_elt_idx_and_col_name_in_view(Obiview_p view, const char* column_name, index_t line_nb, index_t element_idx)
{
	OBIDMS_column_p column_p;
	column_p = obi_view_get_column(view, column_name);
	if (column_p == NULL)
		return OBIInt_NA;
	return obi_get_int_with_elt_idx_and_col_p_in_view(view, column_p, line_nb, element_idx);
}


obiint_t obi_get_int_with_elt_name_and_col_name_in_view(Obiview_p view, const char* column_name, index_t line_nb, const char* element_name)
{
	OBIDMS_column_p column_p;
	column_p = obi_view_get_column(view, column_name);
	if (column_p == NULL)
		return OBIInt_NA;
	return obi_get_int_with_elt_name_and_col_p_in_view(view, column_p, line_nb, element_name);
}

/****************************************/


/*********** FOR QUAL COLUMNS ***********/

int obi_set_qual_char_with_elt_idx_and_col_p_in_view(Obiview_p view, OBIDMS_column_p column, index_t line_nb, index_t element_idx, const char* value, int offset)
{
	if (prepare_to_set_value_in_column(view, &column, &line_nb) < 0)
		return -1;
	return obi_column_set_obiqual_char_with_elt_idx(column, line_nb, element_idx, value, offset);
}


int obi_set_qual_int_with_elt_idx_and_col_p_in_view(Obiview_p view, OBIDMS_column_p column, index_t line_nb, index_t element_idx, const uint8_t* value, int value_length)
{
	if (prepare_to_set_value_in_column(view, &column, &line_nb) < 0)
		return -1;
	return obi_column_set_obiqual_int_with_elt_idx(column, line_nb, element_idx, value, value_length);
}


char* obi_get_qual_char_with_elt_idx_and_col_p_in_view(Obiview_p view, OBIDMS_column_p column, index_t line_nb, index_t element_idx, int offset)
{
	if (prepare_to_get_value_from_column(view, &line_nb) < 0)
		return OBIQual_char_NA;
	return obi_column_get_obiqual_char_with_elt_idx(column, line_nb, element_idx, offset);
}


const uint8_t* obi_get_qual_int_with_elt_idx_and_col_p_in_view(Obiview_p view, OBIDMS_column_p column, index_t line_nb, index_t element_idx, int* value_length)
{
	if (prepare_to_get_value_from_column(view, &line_nb) < 0)
		return OBIQual_int_NA;
	return obi_column_get_obiqual_int_with_elt_idx(column, line_nb, element_idx, value_length);
}


int obi_set_qual_char_with_elt_name_and_col_p_in_view(Obiview_p view, OBIDMS_column_p column, index_t line_nb, const char* element_name, const char* value, int offset)
{
	index_t element_idx = obi_column_get_element_index_from_name(column, element_name);
	if (element_idx == OBIIdx_NA)
		return -1;
	return obi_set_qual_char_with_elt_idx_and_col_p_in_view(view, column, line_nb, element_idx, value, offset);
}


int obi_set_qual_int_with_elt_name_and_col_p_in_view(Obiview_p view, OBIDMS_column_p column, index_t line_nb, const char* element_name, const uint8_t* value, int value_length)
{
	index_t element_idx = obi_column_get_element_index_from_name(column, element_name);
	if (element_idx == OBIIdx_NA)
		return -1;
	return obi_set_qual_int_with_elt_idx_and_col_p_in_view(view, column, line_nb, element_idx, value, value_length);
}


char* obi_get_qual_char_with_elt_name_and_col_p_in_view(Obiview_p view, OBIDMS_column_p column, index_t line_nb, const char* element_name, int offset)
{
	index_t element_idx = obi_column_get_element_index_from_name(column, element_name);
	if (element_idx == OBIIdx_NA)
		return OBIQual_char_NA;
	return obi_get_qual_char_with_elt_idx_and_col_p_in_view(view, column, line_nb, element_idx, offset);
}


const uint8_t* obi_get_qual_int_with_elt_name_and_col_p_in_view(Obiview_p view, OBIDMS_column_p column, index_t line_nb, const char* element_name, int* value_length)
{
	index_t element_idx = obi_column_get_element_index_from_name(column, element_name);
	if (element_idx == OBIIdx_NA)
		return OBIQual_int_NA;
	return obi_get_qual_int_with_elt_idx_and_col_p_in_view(view, column, line_nb, element_idx, value_length);
}


int obi_set_qual_char_with_elt_name_and_col_name_in_view(Obiview_p view, const char* column_name, index_t line_nb, const char* element_name, const char* value, int offset)
{
	OBIDMS_column_p column_p;
	column_p = obi_view_get_column(view, column_name);
	if (column_p == NULL)
		return -1;
	return obi_set_qual_char_with_elt_name_and_col_p_in_view(view, column_p, line_nb, element_name, value, offset);
}


int obi_set_qual_char_with_elt_idx_and_col_name_in_view(Obiview_p view, const char* column_name, index_t line_nb, index_t element_idx, const char* value, int offset)
{
	OBIDMS_column_p column_p;
	column_p = obi_view_get_column(view, column_name);
	if (column_p == NULL)
		return -1;
	return obi_set_qual_char_with_elt_idx_and_col_p_in_view(view, column_p, line_nb, element_idx, value, offset);
}


char* obi_get_qual_char_with_elt_idx_and_col_name_in_view(Obiview_p view, const char* column_name, index_t line_nb, index_t element_idx, int offset)
{
	OBIDMS_column_p column_p;
	column_p = obi_view_get_column(view, column_name);
	if (column_p == NULL)
		return OBIQual_char_NA;
	return obi_get_qual_char_with_elt_idx_and_col_p_in_view(view, column_p, line_nb, element_idx, offset);
}


char* obi_get_qual_char_with_elt_name_and_col_name_in_view(Obiview_p view, const char* column_name, index_t line_nb, const char* element_name, int offset)
{
	OBIDMS_column_p column_p;
	column_p = obi_view_get_column(view, column_name);
	if (column_p == NULL)
		return OBIQual_char_NA;
	return obi_get_qual_char_with_elt_name_and_col_p_in_view(view, column_p, line_nb, element_name, offset);
}


int obi_set_qual_int_with_elt_name_and_col_name_in_view(Obiview_p view, const char* column_name, index_t line_nb, const char* element_name, const uint8_t* value, int value_length)
{
	OBIDMS_column_p column_p;
	column_p = obi_view_get_column(view, column_name);
	if (column_p == NULL)
		return -1;
	return obi_set_qual_int_with_elt_name_and_col_p_in_view(view, column_p, line_nb, element_name, value, value_length);
}


int obi_set_qual_int_with_elt_idx_and_col_name_in_view(Obiview_p view, const char* column_name, index_t line_nb, index_t element_idx, const uint8_t* value, int value_length)
{
	OBIDMS_column_p column_p;
	column_p = obi_view_get_column(view, column_name);
	if (column_p == NULL)
		return -1;
	return obi_set_qual_int_with_elt_idx_and_col_p_in_view(view, column_p, line_nb, element_idx, value, value_length);
}


const uint8_t* obi_get_qual_int_with_elt_idx_and_col_name_in_view(Obiview_p view, const char* column_name, index_t line_nb, index_t element_idx, int* value_length)
{
	OBIDMS_column_p column_p;
	column_p = obi_view_get_column(view, column_name);
	if (column_p == NULL)
		return OBIQual_int_NA;
	return obi_get_qual_int_with_elt_idx_and_col_p_in_view(view, column_p, line_nb, element_idx, value_length);
}


const uint8_t* obi_get_qual_int_with_elt_name_and_col_name_in_view(Obiview_p view, const char* column_name, index_t line_nb, const char* element_name, int* value_length)
{
	OBIDMS_column_p column_p;
	column_p = obi_view_get_column(view, column_name);
	if (column_p == NULL)
		return OBIQual_int_NA;
	return obi_get_qual_int_with_elt_name_and_col_p_in_view(view, column_p, line_nb, element_name, value_length);
}

/****************************************/


/*********** FOR SEQ COLUMNS ***********/

int obi_set_seq_with_elt_idx_and_col_p_in_view(Obiview_p view, OBIDMS_column_p column, index_t line_nb, index_t element_idx, const char* value)
{
	if (prepare_to_set_value_in_column(view, &column, &line_nb) < 0)
		return -1;
	return obi_column_set_obiseq_with_elt_idx(column, line_nb, element_idx, value);
}


char* obi_get_seq_with_elt_idx_and_col_p_in_view(Obiview_p view, OBIDMS_column_p column, index_t line_nb, index_t element_idx)
{
	if (prepare_to_get_value_from_column(view, &line_nb) < 0)
		return OBISeq_NA;
	return obi_column_get_obiseq_with_elt_idx(column, line_nb, element_idx);
}


int obi_set_seq_with_elt_name_and_col_p_in_view(Obiview_p view, OBIDMS_column_p column, index_t line_nb, const char* element_name, const char* value)
{
	index_t element_idx = obi_column_get_element_index_from_name(column, element_name);
	if (element_idx == OBIIdx_NA)
		return -1;
	return obi_set_seq_with_elt_idx_and_col_p_in_view(view, column, line_nb, element_idx, value);
}


char* obi_get_seq_with_elt_name_and_col_p_in_view(Obiview_p view, OBIDMS_column_p column, index_t line_nb, const char* element_name)
{
	index_t element_idx = obi_column_get_element_index_from_name(column, element_name);
	if (element_idx == OBIIdx_NA)
		return OBISeq_NA;
	return obi_get_seq_with_elt_idx_and_col_p_in_view(view, column, line_nb, element_idx);
}


int obi_set_seq_with_elt_name_and_col_name_in_view(Obiview_p view, const char* column_name, index_t line_nb, const char* element_name, const char* value)
{
	OBIDMS_column_p column_p;
	column_p = obi_view_get_column(view, column_name);
	if (column_p == NULL)
		return -1;
	return obi_set_seq_with_elt_name_and_col_p_in_view(view, column_p, line_nb, element_name, value);
}


int obi_set_seq_with_elt_idx_and_col_name_in_view(Obiview_p view, const char* column_name, index_t line_nb, index_t element_idx, const char* value)
{
	OBIDMS_column_p column_p;
	column_p = obi_view_get_column(view, column_name);
	if (column_p == NULL)
		return -1;
	return obi_set_seq_with_elt_idx_and_col_p_in_view(view, column_p, line_nb, element_idx, value);
}


char* obi_get_seq_with_elt_idx_and_col_name_in_view(Obiview_p view, const char* column_name, index_t line_nb, index_t element_idx)
{
	OBIDMS_column_p column_p;
	column_p = obi_view_get_column(view, column_name);
	if (column_p == NULL)
		return OBISeq_NA;
	return obi_get_seq_with_elt_idx_and_col_p_in_view(view, column_p, line_nb, element_idx);
}


char* obi_get_seq_with_elt_name_and_col_name_in_view(Obiview_p view, const char* column_name, index_t line_nb, const char* element_name)
{
	OBIDMS_column_p column_p;
	column_p = obi_view_get_column(view, column_name);
	if (column_p == NULL)
		return OBISeq_NA;
	return obi_get_seq_with_elt_name_and_col_p_in_view(view, column_p, line_nb, element_name);
}

/****************************************/


/*********** FOR STR COLUMNS ***********/

int obi_set_str_with_elt_idx_and_col_p_in_view(Obiview_p view, OBIDMS_column_p column, index_t line_nb, index_t element_idx, const char* value)
{
	if (prepare_to_set_value_in_column(view, &column, &line_nb) < 0)
		return -1;
	return obi_column_set_obistr_with_elt_idx(column, line_nb, element_idx, value);
}


const char* obi_get_str_with_elt_idx_and_col_p_in_view(Obiview_p view, OBIDMS_column_p column, index_t line_nb, index_t element_idx)
{
	if (prepare_to_get_value_from_column(view, &line_nb) < 0)
		return OBIStr_NA;
	return obi_column_get_obistr_with_elt_idx(column, line_nb, element_idx);
}


int obi_set_str_with_elt_name_and_col_p_in_view(Obiview_p view, OBIDMS_column_p column, index_t line_nb, const char* element_name, const char* value)
{
	index_t element_idx = obi_column_get_element_index_from_name(column, element_name);
	if (element_idx == OBIIdx_NA)
		return -1;
	return obi_set_str_with_elt_idx_and_col_p_in_view(view, column, line_nb, element_idx, value);
}


const char* obi_get_str_with_elt_name_and_col_p_in_view(Obiview_p view, OBIDMS_column_p column, index_t line_nb, const char* element_name)
{
	index_t element_idx = obi_column_get_element_index_from_name(column, element_name);
	if (element_idx == OBIIdx_NA)
		return OBIStr_NA;
	return obi_get_str_with_elt_idx_and_col_p_in_view(view, column, line_nb, element_idx);
}


int obi_set_str_with_elt_name_and_col_name_in_view(Obiview_p view, const char* column_name, index_t line_nb, const char* element_name, const char* value)
{
	OBIDMS_column_p column_p;
	column_p = obi_view_get_column(view, column_name);
	if (column_p == NULL)
		return -1;
	return obi_set_str_with_elt_name_and_col_p_in_view(view, column_p, line_nb, element_name, value);
}


int obi_set_str_with_elt_idx_and_col_name_in_view(Obiview_p view, const char* column_name, index_t line_nb, index_t element_idx, const char* value)
{
	OBIDMS_column_p column_p;
	column_p = obi_view_get_column(view, column_name);
	if (column_p == NULL)
		return -1;
	return obi_set_str_with_elt_idx_and_col_p_in_view(view, column_p, line_nb, element_idx, value);
}


const char* obi_get_str_with_elt_idx_and_col_name_in_view(Obiview_p view, const char* column_name, index_t line_nb, index_t element_idx)
{
	OBIDMS_column_p column_p;
	column_p = obi_view_get_column(view, column_name);
	if (column_p == NULL)
		return OBIStr_NA;
	return obi_get_str_with_elt_idx_and_col_p_in_view(view, column_p, line_nb, element_idx);
}


const char* obi_get_str_with_elt_name_and_col_name_in_view(Obiview_p view, const char* column_name, index_t line_nb, const char* element_name)
{
	OBIDMS_column_p column_p;
	column_p = obi_view_get_column(view, column_name);
	if (column_p == NULL)
		return OBIStr_NA;
	return obi_get_str_with_elt_name_and_col_p_in_view(view, column_p, line_nb, element_name);
}

/****************************************/


/*********** FOR COLUMNS WITH INDEXED VALUES ***********/


int obi_set_index_with_elt_idx_and_col_p_in_view(Obiview_p view, OBIDMS_column_p column, index_t line_nb, index_t element_idx, index_t value)
{
	if (prepare_to_set_value_in_column(view, &column, &line_nb) < 0)
		return -1;
	return obi_column_set_index_with_elt_idx(column, line_nb, element_idx, value);
}


index_t obi_get_index_with_elt_idx_and_col_p_in_view(Obiview_p view, OBIDMS_column_p column, index_t line_nb, index_t element_idx)
{
	if (prepare_to_get_value_from_column(view, &line_nb) < 0)
		return OBIIdx_NA;
	return obi_column_get_index_with_elt_idx(column, line_nb, element_idx);
}


int obi_set_index_with_elt_name_and_col_p_in_view(Obiview_p view, OBIDMS_column_p column, index_t line_nb, const char* element_name, index_t value)
{
	index_t element_idx = obi_column_get_element_index_from_name(column, element_name);
	if (element_idx == OBIIdx_NA)
		return -1;
	return obi_set_index_with_elt_idx_and_col_p_in_view(view, column, line_nb, element_idx, value);
}


index_t obi_get_index_with_elt_name_and_col_p_in_view(Obiview_p view, OBIDMS_column_p column, index_t line_nb, const char* element_name)
{
	index_t element_idx = obi_column_get_element_index_from_name(column, element_name);
	if (element_idx == OBIIdx_NA)
		return OBIIdx_NA;
	return obi_get_index_with_elt_idx_and_col_p_in_view(view, column, line_nb, element_idx);
}


int obi_set_index_with_elt_name_and_col_name_in_view(Obiview_p view, const char* column_name, index_t line_nb, const char* element_name, index_t value)
{
	OBIDMS_column_p column_p;
	column_p = obi_view_get_column(view, column_name);
	if (column_p == NULL)
		return -1;
	return obi_set_index_with_elt_name_and_col_p_in_view(view, column_p, line_nb, element_name, value);
}


int obi_set_index_with_elt_idx_and_col_name_in_view(Obiview_p view, const char* column_name, index_t line_nb, index_t element_idx, index_t value)
{
	OBIDMS_column_p column_p;
	column_p = obi_view_get_column(view, column_name);
	if (column_p == NULL)
		return -1;
	return obi_set_index_with_elt_idx_and_col_p_in_view(view, column_p, line_nb, element_idx, value);
}


index_t obi_get_index_with_elt_idx_and_col_name_in_view(Obiview_p view, const char* column_name, index_t line_nb, index_t element_idx)
{
	OBIDMS_column_p column_p;
	column_p = obi_view_get_column(view, column_name);
	if (column_p == NULL)
		return OBIIdx_NA;
	return obi_get_index_with_elt_idx_and_col_p_in_view(view, column_p, line_nb, element_idx);
}


index_t obi_get_index_with_elt_name_and_col_name_in_view(Obiview_p view, const char* column_name, index_t line_nb, const char* element_name)
{
	OBIDMS_column_p column_p;
	column_p = obi_view_get_column(view, column_name);
	if (column_p == NULL)
		return OBIIdx_NA;
	return obi_get_index_with_elt_name_and_col_p_in_view(view, column_p, line_nb, element_name);
}

/****************************************/


/*********** FOR ARRAY COLUMNS ***********/

int obi_set_array_with_col_p_in_view(Obiview_p view, OBIDMS_column_p column, index_t line_nb, const void* value, uint8_t elt_size, int32_t value_length)
{
	if (prepare_to_set_value_in_column(view, &column, &line_nb) < 0)
		return -1;
	return obi_column_set_array(column, line_nb, value, elt_size, value_length);
}


const void* obi_get_array_with_col_p_in_view(Obiview_p view, OBIDMS_column_p column, index_t line_nb, int32_t* value_length_p)
{
	if (prepare_to_get_value_from_column(view, &line_nb) < 0)
		return OBITuple_NA;
	return obi_column_get_array(column, line_nb, value_length_p);
}


int obi_set_array_with_col_name_in_view(Obiview_p view, const char* column_name, index_t line_nb, const void* value, uint8_t elt_size, int32_t value_length)
{
	OBIDMS_column_p column_p;
	column_p = obi_view_get_column(view, column_name);
	if (column_p == NULL)
		return -1;
	return obi_set_array_with_col_p_in_view(view, column_p, line_nb, value, elt_size, value_length);
}


const void* obi_get_array_with_col_name_in_view(Obiview_p view, const char* column_name, index_t line_nb, int32_t* value_length_p)
{
	OBIDMS_column_p column_p;
	column_p = obi_view_get_column(view, column_name);
	if (column_p == NULL)
		return OBITuple_NA;
	return obi_get_array_with_col_p_in_view(view, column_p, line_nb, value_length_p);
}

/****************************************/
