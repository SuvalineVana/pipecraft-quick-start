/****************************************************************************
 * OBIDMS AVL tree functions	                                            *
 ****************************************************************************/

/**
 * @file obiavl.c
 * @author Celine Mercier
 * @date December 3rd 2015
 * @brief Functions handling AVL trees for storing and retrieving blobs.
 */


#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <time.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <math.h>

#include "bloom.h"
#include "crc64.h"
#include "obiavl.h"
#include "obiblob.h"
#include "obierrno.h"
#include "obitypes.h"
#include "obidebug.h"
#include "encode.h"
#include "utils.h"


#define DEBUG_LEVEL 0	// TODO has to be defined somewhere else (cython compil flag?)



/**************************************************************************
 *
 * D E C L A R A T I O N   O F   T H E   P R I V A T E   F U N C T I O N S
 *
 **************************************************************************/


/**
 * @brief Internal function building the full path of an AVL directory containing an AVL or an AVL group.
 *
 * @warning The returned pointer has to be freed by the caller.
 *
 * @param dms A pointer to the OBIDMS to which the AVL tree belongs.
 * @param avl_name The name of the AVL tree or the base name of the AVL tree group.
 *
 * @returns A pointer to the full path of the AVL directory.
 * @retval NULL if an error occurred.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
char* get_full_path_of_avl_dir(OBIDMS_p dms, const char* avl_name);


/**
 * @brief Internal function building the file name for an AVL tree file.
 *
 * @warning The returned pointer has to be freed by the caller.
 *
 * @param avl_name The name of the AVL tree.
 *
 * @returns A pointer to the name of the file where the AVL tree is stored.
 * @retval NULL if an error occurred.
 *
 * @since December 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static char* build_avl_file_name(const char* avl_name);


/**
 * @brief Internal function building the file name for an AVL tree file.
 *
 * @warning The returned pointer has to be freed by the caller.
 *
 * @param avl_name The name of the AVL tree.
 *
 * @returns A pointer to the name of the file where the data referred to by the AVL tree is stored.
 * @retval NULL if an error occurred.
 *
 * @since December 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static char* build_avl_data_file_name(const char* avl_name);


/**
 * @brief Internal function returning the size of an AVL tree header on this platform,
 *        including the size of the bloom filter associated with the AVL tree.
 *
 * @returns The size of an AVL tree header in bytes.
 *
 * @since December 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
size_t get_avl_header_size(void);


/**
 * @brief Internal function returning the initial size of an AVL tree on this platform.
 *
 * @returns The initial size of an AVL tree in bytes.
 *
 * @since December 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
size_t get_initial_avl_size(void);


/**
 * @brief Internal function returning the size, on this platform, of the header of the data
 *        referred to by an AVL tree.
 *
 * @returns The size of an AVL data header in bytes.
 *
 * @since December 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
size_t get_avl_data_header_size(void);


/**
 * @brief Internal function returning the initial size, on this platform, of the data
 *        referred to by an AVL tree.
 *
 * @returns The initial size of an AVL data array in bytes.
 *
 * @since December 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
size_t get_initial_avl_data_size(void);


/**
 * @brief Internal function truncating an AVL tree file to the minimum size that is a multiple of the page size.
 *
 * @param avl A pointer to the AVL tree structure.
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int truncate_avl_to_size_used(OBIDMS_avl_p avl);


/**
 * @brief Internal function truncating an AVL tree data file to the minimum size that is a multiple of the page size.
 *
 * @param avl A pointer to the the data structure referred to by an AVL tree.
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int truncate_avl_data_to_size_used(OBIDMS_avl_data_p avl_data);


/**
 * @brief Internal function enlarging an AVL tree.
 *
 * @param avl A pointer to the AVL tree structure.
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since December 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int grow_avl(OBIDMS_avl_p avl);


/**
 * @brief Internal function enlarging the data array referred to by an AVL tree.
 *
 * @param avl A pointer to the AVL tree structure.
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since December 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int grow_avl_data(OBIDMS_avl_data_p avl_data);


/**
 * @brief Internal function closing an AVL data structure where the data referred to by an AVL tree is stored.
 *
 * @param avl_data A pointer to the data structure referred to by an AVL tree.
 * @param writable Whether the AVL is writable or not (and therefore if the files can and should be truncated to the used size).
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since December 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int close_avl_data(OBIDMS_avl_data_p avl_data, bool writable);


/**
 * @brief Internal function unmapping the tree and data parts of an AVL tree structure.
 *
 * @param avl A pointer to the AVL tree structure.
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int unmap_an_avl(OBIDMS_avl_p avl);


/**
 * @brief Internal function (re)mapping the tree and data parts of an AVL tree structure.
 *
 * @param avl A pointer to the AVL tree structure.
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int remap_an_avl(OBIDMS_avl_p avl);


/**
 * @brief Internal function creating and adding a new AVL in an AVL group.
 *
 * @warning The previous AVL in the list of the group is unmapped,
 * 			if it's not the 1st AVL being added.
 *
 * @param avl_group A pointer on the AVL tree group structure.
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int add_new_avl_in_group(OBIDMS_avl_group_p avl_group);


/**
 * @brief Internal function adding an existing AVL in an AVL group.
 *
 * The AVL is hard-linked in the AVL group directory, and opened for that group.
 *
 * @param avl_group_dest A pointer on the destination AVL group to which the AVL should be added.
 * @param avl_group_source A pointer on the source AVL group where the AVL already exists.
 * @param avl_idx Index of the AVL in the source AVL group.
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since June 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int add_existing_avl_in_group(OBIDMS_avl_group_p avl_group_dest, OBIDMS_avl_group_p avl_group_source, int avl_idx);


/**
 * @brief Internal function testing if a value might already be stored in an AVL tree.
 *
 * The function checks a bloom filter. No false negatives, possible false positives.
 *
 * @param avl A pointer to the AVL tree structure.
 * @param value A pointer to the blob structure.
 *
 * @retval 0 if the value is definitely not already stored in the AVL tree.
 * @retval 1 if the value might already be stored in the AVL tree.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int maybe_in_avl(OBIDMS_avl_p avl, Obi_blob_p value);


/**
 * @brief Internal function storing a value (blob) in the data array referred to by an AVL tree.
 *
 * @param avl A pointer to the AVL tree structure.
 * @param value A pointer to the value (blob structure).
 *
 * @returns The index of the stored value.
 * @retval -1 if an error occurred.
 *
 * @since December 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
index_t avl_add_value_in_data_array(OBIDMS_avl_p avl, Obi_blob_p value);


/**
 * @brief Internal function initializing a node in an AVL tree.
 *
 * @param avl A pointer to the AVL tree structure.
 * @param node_idx The index of the node to initialize in the mmapped AVL tree.
 *
 * @returns The node structure initialized.
 *
 * @since December 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
AVL_node_p avl_create_node(OBIDMS_avl_p avl, index_t node_idx);


/**
 * @brief Internal function updating the balance factors in an AVL tree
 *        after adding a node, only in the subtree that will have to be balanced.
 *        That subtree is found using the avl->path_idx array and the directions taken
 *        down the tree to add the new node are stored in the avl->path_dir array.
 *
 * @param avl A pointer to the AVL tree structure.
 *
 * @since December 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
void avl_update_balance_factors(OBIDMS_avl_p avl);


/**
 * @brief Internal function rotating a node with a "left left rotation".
 *
 * @param avl A pointer to the AVL tree structure.
 * @param node A pointer to the node that has to be rotated.
 * @param node_idx The index of the node that has to be rotated.
 *
 * @returns The new root of the subtree.
 *
 * @since December 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
index_t avl_rotate_leftleft(OBIDMS_avl_p avl, AVL_node_p node, index_t node_idx);

/**
 * @brief Internal function rotating a node with a "left right rotation".
 *
 * @param avl A pointer to the AVL tree structure.
 * @param node A pointer to the node that has to be rotated.
 * @param node_idx The index of the node that has to be rotated.
 *
 * @returns The new root of the subtree.
 *
 * @since December 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
index_t avl_rotate_leftright(OBIDMS_avl_p avl, AVL_node_p node, index_t node_idx);


/**
 * @brief Internal function rotating a node with a "right left rotation".
 *
 * @param avl A pointer to the AVL tree structure.
 * @param node A pointer to the node that has to be rotated.
 * @param node_idx The index of the node that has to be rotated.
 *
 * @returns The new root of the subtree.
 *
 * @since December 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
index_t avl_rotate_rightleft(OBIDMS_avl_p avl, AVL_node_p node, index_t node_idx);


/**
 * @brief Internal function rotating a node with a "right right rotation".
 *
 * @param avl A pointer to the AVL tree structure.
 * @param node A pointer to the node that has to be rotated.
 * @param node_idx The index of the node that has to be rotated.
 *
 * @returns The new root of the subtree.
 *
 * @since December 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
index_t avl_rotate_rightright(OBIDMS_avl_p avl, AVL_node_p node, index_t node_idx);


/**
 * @brief Internal function balancing one node.
 *
 * @param avl A pointer to the AVL tree structure.
 * @param node A pointer to the node that has to be balanced.
 * @param node_idx The index of the node that has to be balanced.
 *
 * @returns The new root of the subtree.
 *
 * @since December 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
index_t avl_balance_node(OBIDMS_avl_p avl, AVL_node_p node, index_t node_idx);


/**
 * @brief Internal function balancing the nodes of an AVL tree after adding a node,
 *        only in the subtree that eventually has to be balanced.
 *        That subtree is found using the avl->path_idx array.
 *
 * @param avl A pointer to the AVL tree structure.
 *
 * @since December 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
void avl_balance(OBIDMS_avl_p avl);


/**
 * @brief Internal function printing a depth first traverse of a node.
 *
 * @param avl A pointer to the AVL tree structure.
 * @param node A pointer to the node.
 * @param node_idx The index of the node.
 * @param depth The depth of the node.
 *
 * @since December 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
void avl_print_node(OBIDMS_avl_p avl, AVL_node_p node, index_t node_idx, int depth);


/**
 * @brief Internal function printing a depth first traverse of an AVL tree.
 *
 * @param avl A pointer to the AVL tree structure.
 *
 * @since December 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
void avl_print(OBIDMS_avl_p avl);


/************************************************************************
 *
 * D E F I N I T I O N   O F   T H E   P R I V A T E   F U N C T I O N S
 *
 ************************************************************************/


char* get_full_path_of_avl_dir(OBIDMS_p dms, const char* avl_name)
{
	char* avl_dir_name;

	avl_dir_name = obi_dms_get_full_path(dms, INDEXER_DIR_NAME);
	if (avl_dir_name == NULL)
	{
		obidebug(1, "\nError getting path for the DMS AVL directory");
		return NULL;
	}
	strcat(avl_dir_name, "/");
	strcat(avl_dir_name, avl_name);

	return avl_dir_name;
}


static char* build_avl_file_name(const char* avl_name)
{
	char* file_name;

	// Test if the AVL name is not too long
	if (strlen(avl_name) >= AVL_MAX_NAME)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError due to AVL tree name too long");
		return NULL;
	}

	// Build the file name
	file_name = (char*) malloc((strlen(avl_name) + 5)*sizeof(char));
	if (file_name == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating memory for an AVL file name");
		return NULL;
	}
	if (sprintf(file_name,"%s.oda", avl_name) < 0)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError building an AVL tree file name");
		free(file_name);
		return NULL;
	}

	return file_name;
}


static char* build_avl_data_file_name(const char* avl_name)
{
	char* file_name;

	// Build the file name
	file_name = (char*) malloc((strlen(avl_name) + 5)*sizeof(char));
	if (file_name == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating memory for an AVL data file name");
		return NULL;
	}
	if (sprintf(file_name,"%s.odd", avl_name) < 0)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError building an AVL tree data file name");
		return NULL;
	}

	return file_name;
}


size_t get_avl_header_size()
{
	size_t header_size;
	size_t rounded_header_size;
	double multiple;

	header_size = sizeof(OBIDMS_avl_header_t) + bloom_filter_size(MAX_NODE_COUNT_PER_AVL, BLOOM_FILTER_ERROR_RATE);

	multiple = ceil((double) header_size / (double) getpagesize());

	rounded_header_size = multiple * getpagesize();

	return rounded_header_size;
}


size_t get_initial_avl_size()
{
	size_t s;
	size_t m;

	m = 1;
	s = getpagesize() * m;

	return s;
}


size_t get_avl_data_header_size()
{
	size_t header_size;
	size_t rounded_header_size;
	double multiple;

	header_size = sizeof(OBIDMS_avl_data_header_t);

	multiple = 	ceil((double) header_size / (double) getpagesize());

	rounded_header_size = multiple * getpagesize();

	return rounded_header_size;
}


size_t get_initial_avl_data_size()
{
	size_t s;
	size_t m;

	m = 1;
	s = getpagesize() * m;

	return s;
}


int truncate_avl_to_size_used(OBIDMS_avl_p avl)	// TODO is it necessary to unmap/remap?
{
	size_t  			file_size;
	size_t  			new_data_size;
	double  			multiple;
	int 				file_descriptor;

	// Compute the new size: used size rounded to the nearest greater multiple of page size greater than 0
	multiple = ceil((double) (ONE_IF_ZERO((avl->header)->nb_items * sizeof(AVL_node_t))) / (double) getpagesize());
	new_data_size = ((size_t) multiple) * getpagesize();

	// Check that it is actually greater than the current size of the file, otherwise no need to truncate
	if ((avl->header)->avl_size == new_data_size)
		return 0;

	// Get the file descriptor
	file_descriptor = avl->avl_fd;

	// Unmap the tree before truncating the file
	if (munmap(avl->tree, (avl->header)->avl_size) < 0)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError munmapping the tree of an AVL before truncating");
		return -1;
	}

	// Truncate the file
	file_size = (avl->header)->header_size + new_data_size;
	if (ftruncate(file_descriptor, file_size) < 0)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError truncating an AVL file");
		return -1;
	}

	// Remap the data
	avl->tree = mmap(NULL,
			         new_data_size,
					 PROT_READ | PROT_WRITE,
					 MAP_SHARED,
					 file_descriptor,
					 (avl->header)->header_size
					);
	if (avl->tree == MAP_FAILED)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError re-mmapping the tree of an AVL after truncating");
		return -1;
	}

	// Set new data size and new max node count
	(avl->header)->avl_size     = new_data_size;
	(avl->header)->nb_items_max	= (index_t) floor(((double) (avl->header)->avl_size) / ((double) sizeof(AVL_node_t)));

	return 0;
}


int truncate_avl_data_to_size_used(OBIDMS_avl_data_p avl_data)	// TODO is it necessary to unmap/remap?
{
	size_t  			file_size;
	index_t  			new_data_size;
	double  			multiple;
	int 				file_descriptor;

	// Compute the new size: used size rounded to the nearest greater multiple of page size greater than 0
	multiple = ceil((double) (ONE_IF_ZERO((avl_data->header)->data_size_used)) / (double) getpagesize());
	new_data_size = ((index_t) multiple) * getpagesize();

	// Check that it is actually greater than the current size of the file, otherwise no need to truncate
	if ((avl_data->header)->data_size_max == new_data_size)
		return 0;

	// Get the file descriptor
	file_descriptor = avl_data->data_fd;

	// Unmap the data before truncating the file
	if (munmap(avl_data->data, (avl_data->header)->data_size_max) < 0)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError munmapping the data of an AVL before truncating");
		return -1;
	}

	// Truncate the file
	file_size = (avl_data->header)->header_size + new_data_size;
	if (ftruncate(file_descriptor, file_size) < 0)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError truncating an AVL data file");
		return -1;
	}

	// Remap the data
	avl_data->data = mmap(NULL,
					      new_data_size,
						  PROT_READ | PROT_WRITE,
						  MAP_SHARED,
						  file_descriptor,
						  (avl_data->header)->header_size
					     );

	if (avl_data->data == MAP_FAILED)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError re-mmapping the data of an AVL after truncating");
		return -1;
	}

	// Set new data size
	(avl_data->header)->data_size_max = new_data_size;

	return 0;
}


int grow_avl(OBIDMS_avl_p avl)		// TODO Lock when needed
{
	size_t	file_size;
	size_t 	old_data_size;
	size_t 	new_data_size;
	size_t 	header_size;
	int 	avl_file_descriptor;

	avl_file_descriptor = avl->avl_fd;

	// Calculate the new file size
	old_data_size = (avl->header)->avl_size;
	new_data_size = old_data_size * AVL_GROWTH_FACTOR;
	header_size = (avl->header)->header_size;
	file_size = header_size + new_data_size;

	// Enlarge the file
	if (ftruncate(avl_file_descriptor, file_size) < 0)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError enlarging an AVL tree file");
		return -1;
	}

	// Unmap and re-map the data

	if (munmap(avl->tree, old_data_size) < 0)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError munmapping the tree of an AVL tree file before enlarging");
		return -1;
	}

	avl->tree = mmap(NULL,
					 new_data_size,
					 PROT_READ | PROT_WRITE,
					 MAP_SHARED,
					 avl_file_descriptor,
					 header_size
					);

	if (avl->tree == MAP_FAILED)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError re-mmapping the tree of an AVL tree file after enlarging the file");
		return -1;
	}

	// Set the new avl size
	(avl->header)->avl_size = new_data_size;

	// Set new maximum number of items
	(avl->header)->nb_items_max	 = (index_t) floor(((double) (avl->header)->avl_size) / ((double) sizeof(AVL_node_t)));

	return 0;
}


int grow_avl_data(OBIDMS_avl_data_p avl_data)		// TODO Lock when needed
{
	size_t 	file_size;
	index_t old_data_size;
	index_t new_data_size;
	size_t 	header_size;
	int 	avl_data_file_descriptor;

	avl_data_file_descriptor = avl_data->data_fd;

	// Calculate the new file size
	old_data_size = (avl_data->header)->data_size_max;
	new_data_size = old_data_size * AVL_GROWTH_FACTOR;
	header_size = (avl_data->header)->header_size;
	file_size = header_size + new_data_size;

	// Enlarge the file
	if (ftruncate(avl_data_file_descriptor, file_size) < 0)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError enlarging an AVL tree data file");
		return -1;
	}

	// Unmap and re-map the data

	if (munmap(avl_data->data, old_data_size) < 0)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError munmapping the data of an AVL tree data file before enlarging");
		return -1;
	}

	avl_data->data = mmap(NULL,
						  new_data_size,
						  PROT_READ | PROT_WRITE,
						  MAP_SHARED,
						  avl_data_file_descriptor,
						  header_size
						 );

	if (avl_data->data == MAP_FAILED)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError re-mmapping the data of an AVL tree data file after enlarging the file");
		return -1;
	}

	// Set new data size
	(avl_data->header)->data_size_max = new_data_size;

	// Initialize new data to 0
	memset((avl_data->data)+old_data_size, 0, new_data_size - old_data_size);

	return 0;
}


int close_avl_data(OBIDMS_avl_data_p avl_data, bool writable)
{
	int ret_val = 0;

	if (writable)
		ret_val = truncate_avl_data_to_size_used(avl_data);

	if (munmap(avl_data->data, (avl_data->header)->data_size_max) < 0)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError munmapping the data of an AVL tree data file");
		ret_val = -1;
	}

	if (munmap(avl_data->header, (avl_data->header)->header_size) < 0)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError munmapping the header of an AVL tree data file");
		ret_val = -1;
	}

	if (close(avl_data->data_fd) < 0)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError closing an AVL tree data file");
		ret_val = -1;
	}

	free(avl_data);

	return ret_val;
}


int unmap_an_avl(OBIDMS_avl_p avl)
{
	if (munmap((avl->data)->data, ((avl->data)->header)->data_size_max) < 0)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError unmapping the data of an AVL tree");
		return -1;
	}
	if (munmap(avl->tree, (avl->header)->avl_size) < 0)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError unmapping the tree of an AVL tree");
		return -1;
	}
	return 0;
}


int remap_an_avl(OBIDMS_avl_p avl)
{
	(avl->data)->data = mmap(NULL,
							 ((avl->data)->header)->data_size_max,
							 PROT_READ,
							 MAP_SHARED,
							 (avl->data)->data_fd,
							 ((avl->data)->header)->header_size);
	if ((avl->data)->data == NULL)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError mapping the data of an AVL tree");
		return -1;
	}

	avl->tree = mmap(NULL,
					 (avl->header)->avl_size,
					 PROT_READ,
					 MAP_SHARED,
					 avl->avl_fd,
					 (avl->header)->header_size);
	if (avl->tree == NULL)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError mapping the tree of an AVL tree");
		return -1;
	}

	return 0;
}


int add_new_avl_in_group(OBIDMS_avl_group_p avl_group)
{
	// Check that maximum number of AVLs in a group was not reached
	if (avl_group->last_avl_idx == (MAX_NB_OF_AVLS_IN_GROUP - 1))
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError: Trying to add new AVL in AVL group but maximum number of AVLs in a group reached");
		return -1;
	}

	// Unmap the previous AVL if it's not the 1st
	// Not done anymore, currently keeping all mapped for efficiency reasons
//	if (avl_group->last_avl_idx > 0)
//		if (unmap_an_avl((avl_group->sub_avls)[avl_group->last_avl_idx]) < 0)
//			return -1;

	// Increment current AVL index
	(avl_group->last_avl_idx)++;

	// Create the new AVL
	(avl_group->sub_avls)[avl_group->last_avl_idx] = obi_create_avl(avl_group->dms, avl_group->name, avl_group->last_avl_idx);
	if ((avl_group->sub_avls)[avl_group->last_avl_idx] == NULL)
	{
		obidebug(1, "\nError creating a new AVL tree in a group");
		return -1;
	}

	return 0;
}


int add_existing_avl_in_group(OBIDMS_avl_group_p avl_group_dest, OBIDMS_avl_group_p avl_group_source, int avl_idx)
{
	if (link(obi_get_full_path_of_avl_file_name(avl_group_source->dms, avl_group_source->name, avl_idx), obi_get_full_path_of_avl_file_name(avl_group_dest->dms, avl_group_dest->name, avl_idx)) < 0)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError creating a hard link to an existing AVL tree file");
		return -1;
	}
	if (link(obi_get_full_path_of_avl_data_file_name(avl_group_source->dms, avl_group_source->name, avl_idx), obi_get_full_path_of_avl_data_file_name(avl_group_dest->dms, avl_group_dest->name, avl_idx)) < 0)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError creating a hard link to an existing AVL data file");
		return -1;
	}

	// Increment current AVL index
	(avl_group_dest->last_avl_idx)++;

	// Open AVL for that group 		TODO ideally not needed because AVL open twice, but needed for now
	avl_group_dest->sub_avls[avl_group_dest->last_avl_idx] = obi_open_avl(avl_group_source->dms, avl_group_source->name, avl_idx);
	if ((avl_group_dest->sub_avls)[avl_group_dest->last_avl_idx] == NULL)
	{
		obidebug(1, "\nError opening an AVL to add in an AVL group");
		return -1;
	}

	return 0;
}


int maybe_in_avl(OBIDMS_avl_p avl, Obi_blob_p value)
{
	return (bloom_check(&((avl->header)->bloom_filter), value, obi_blob_sizeof(value)));
}


index_t avl_add_value_in_data_array(OBIDMS_avl_p avl, Obi_blob_p value)
{
	index_t value_idx;
	int value_size;

	value_idx = ((avl->data)->header)->data_size_used;

	// Grow the data if needed
	value_size = obi_blob_sizeof(value);
	while (((avl->data)->header)->data_size_max < (value_idx + value_size))
	{
		if (grow_avl_data(avl->data) < 0)
			return -1;
	}

	// Store the value itself at the end of the data
	memcpy((((avl->data)->data)+value_idx), value, value_size);

	// Update the data size
	((avl->data)->header)->data_size_used = value_idx + value_size;

	// Update the number of items
	(((avl->data)->header)->nb_items)++;

	return value_idx;
}


AVL_node_p avl_create_node(OBIDMS_avl_p avl, index_t node_idx)
{
	AVL_node_p node;

	node = (avl->tree)+node_idx;

	node->left_child     = -1;
	node->right_child    = -1;
	node->balance_factor = 0;
	node->value          = -1;
	node->crc64          = 0; 	// TODO no NA value

	return node;
}


// Update the balance factors of the nodes from the node that will need balancing
void avl_update_balance_factors(OBIDMS_avl_p avl)
{
	uint8_t    n;
	AVL_node_p node;

	// Update balance factors from the node where balancing might be needed
	node=(avl->tree)+((avl->path_idx)[1]);

	for (n=1; (avl->path_dir)[n] != -1; n++)
	{
		if ((avl->path_dir)[n]) // Went right
		{
			(node->balance_factor)--;
			node=RIGHT_CHILD(node);
		}
		else 	// Went left
		{
			(node->balance_factor)++;
			node=LEFT_CHILD(node);
		}
	}
}


// Left Left Rotate
index_t avl_rotate_leftleft(OBIDMS_avl_p avl, AVL_node_p node, index_t node_idx)
{
	AVL_node_p left_child = LEFT_CHILD(node);
	index_t left_child_idx = node->left_child;

	node->left_child = left_child->right_child;
	left_child->right_child = node_idx;

	node->balance_factor = 0;
	left_child->balance_factor = 0;

	return left_child_idx;
}


// Left Right Rotate
index_t avl_rotate_leftright(OBIDMS_avl_p avl, AVL_node_p node, index_t node_idx)
{
	AVL_node_p left_child = LEFT_CHILD(node);
	index_t left_child_idx = node->left_child;
	AVL_node_p rc_of_lc = RIGHT_CHILD(left_child);
	index_t rc_of_lc_idx = left_child->right_child;

	node->left_child = rc_of_lc->right_child;
	left_child->right_child = rc_of_lc->left_child;
	rc_of_lc->left_child = left_child_idx;
	rc_of_lc->right_child = node_idx;

	if (rc_of_lc->balance_factor == -1)
	{
		left_child->balance_factor = 1;
		node->balance_factor = 0;
	}
	else if (rc_of_lc->balance_factor == 0)
	{
		left_child->balance_factor = 0;
		node->balance_factor = 0;
	}
	else	// if (rc_of_lc->balance_factor == 1)
	{
		left_child->balance_factor = 0;
		node->balance_factor = -1;
	}

	rc_of_lc->balance_factor = 0;

	return rc_of_lc_idx;
}


// Right Left Rotate
index_t avl_rotate_rightleft(OBIDMS_avl_p avl, AVL_node_p node, index_t node_idx)
{
	AVL_node_p right_child = RIGHT_CHILD(node);
	index_t right_child_idx = node->right_child;;
	AVL_node_p lc_of_rc = LEFT_CHILD(right_child);
	index_t lc_of_rc_idx = right_child->left_child;

	node->right_child = lc_of_rc->left_child;
	right_child->left_child = lc_of_rc->right_child;
	lc_of_rc->right_child = right_child_idx;
	lc_of_rc->left_child = node_idx;

	if (lc_of_rc->balance_factor == 1)
	{
		right_child->balance_factor = 1;
		node->balance_factor = 0;
	}
	else if (lc_of_rc->balance_factor == 0)
	{
		right_child->balance_factor = 0;
		node->balance_factor = 0;
	}
	else	// if (lc_of_rc->balance_factor == -1)
	{
		right_child->balance_factor = 0;
		node->balance_factor = 1;
	}

	lc_of_rc->balance_factor = 0;

	return lc_of_rc_idx;
}


// Right Right Rotate
index_t avl_rotate_rightright(OBIDMS_avl_p avl, AVL_node_p node, index_t node_idx)
{
	AVL_node_p right_child = RIGHT_CHILD(node);
	index_t right_child_idx = node->right_child;

	node->right_child = right_child->left_child;
	right_child->left_child = node_idx;

	node->balance_factor = 0;
	right_child->balance_factor = 0;

	return right_child_idx;
}


// Balance a given node
index_t avl_balance_node(OBIDMS_avl_p avl, AVL_node_p node, index_t node_idx)
{
	index_t new_root = 0;

	if (node->balance_factor == 2)
	{ // Left Heavy
		if ((LEFT_CHILD(node))->balance_factor == -1)
			new_root = avl_rotate_leftright(avl, node, node_idx);
		else
			new_root = avl_rotate_leftleft(avl, node, node_idx);
	}
	else if (node->balance_factor == -2)
	{ // Right Heavy
		if ((RIGHT_CHILD(node))->balance_factor == 1)
			new_root = avl_rotate_rightleft(avl, node, node_idx);
		else
			new_root = avl_rotate_rightright(avl, node, node_idx);
	}
	else
	// Node is balanced
		new_root = node_idx;

	return new_root;
}


// Balance a given tree
void avl_balance(OBIDMS_avl_p avl)
{
	index_t    new_root;
	index_t    node_index;
	AVL_node_p node_to_balance;
	AVL_node_p parent_of_node_to_balance;

	node_index = (avl->path_idx)[1];
	node_to_balance = (avl->tree)+node_index;
	parent_of_node_to_balance = (avl->tree)+((avl->path_idx)[0]);

	// Balance the 2nd node stored in the path (the first is only kept to connect the new root
	// of the subtree if needed).
	new_root = avl_balance_node(avl, node_to_balance, node_index);

	if (new_root != node_index)
	// If the root of the subtree has changed
	{
		// If the subtree's root is the tree's root, store the new root
		if (node_index == (avl->header)->root_idx)
			(avl->header)->root_idx = new_root;
		// Else, connect the new subtree's root to the parent of the subtree
		else if ((avl->path_dir)[0])	   // Subtree is the right child of its parent
			parent_of_node_to_balance->right_child = new_root;
		else	   // Subtree is the left child of its parent
			parent_of_node_to_balance->left_child = new_root;
	}
}


// Print a depth first traverse of a node
void avl_print_node(OBIDMS_avl_p avl, AVL_node_p node, index_t node_idx, int depth)
{
	int i = 0;

	if (node->left_child != -1)
		avl_print_node(avl, LEFT_CHILD(node), node->left_child, depth+2);

	for (i = 0; i < depth; i++)
		putchar(' ');

	fprintf(stderr, "Node idx: %lld, Value idx: %lld, Left child: %lld, Right child: %lld, "
			"Balance factor: %d, CRC: %llu\nValue:", node_idx, node->value, node->left_child, node->right_child, node->balance_factor, node->crc64);
	print_bits(((avl->data)->data)+(node->value), obi_blob_sizeof((Obi_blob_p)(((avl->data)->data)+(node->value))));

	if (node->right_child != -1)
		avl_print_node(avl, RIGHT_CHILD(node), node->right_child, depth+2);
}


// Print a depth first traverse of a tree
void avl_print(OBIDMS_avl_p avl)
{
	fprintf(stderr, "\nRoot index: %lld\n", (avl->header)->root_idx);
	avl_print_node(avl, (avl->tree)+((avl->header)->root_idx), (avl->header)->root_idx, 0);
}


/**********************************************************************
 *
 * D E F I N I T I O N   O F   T H E   P U B L I C   F U N C T I O N S
 *
 **********************************************************************/


char* obi_build_avl_name_with_idx(const char* avl_name, int avl_idx)
{
	char* avl_name_with_idx;
	int   avl_idx_length;

	if (avl_idx < 0)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError building an AVL tree name with index: index < 0");
		return NULL;
	}

	avl_idx_length = avl_idx == 0 ? 1 : (int)(log10(avl_idx)+1);
	avl_name_with_idx = malloc((strlen(avl_name) + avl_idx_length + 2)*sizeof(char));
	if (avl_name_with_idx == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating memory for an AVL name");
		return NULL;
	}
	if (sprintf(avl_name_with_idx, "%s_%u", avl_name, avl_idx) < 0)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError building an AVL tree name with index");
		return NULL;
	}

	return avl_name_with_idx;
}


char* obi_get_full_path_of_avl_file_name(OBIDMS_p dms, const char* avl_name, int avl_idx)
{
	char* complete_avl_name;
	char* full_path;
	char* avl_file_name;

	if (avl_idx >= 0)
	{
		complete_avl_name = obi_build_avl_name_with_idx(avl_name, avl_idx);
		if (complete_avl_name == NULL)
			return NULL;
	}
	else
	{
		complete_avl_name = (char*) malloc((strlen(avl_name)+1)*sizeof(char));
		if (complete_avl_name == NULL)
		{
    		obi_set_errno(OBI_MALLOC_ERROR);
    		obidebug(1, "\nError allocating memory for an AVL name");
			return NULL;
		}
		strcpy(complete_avl_name, avl_name);
	}

	avl_file_name = build_avl_file_name(complete_avl_name);
	if (avl_file_name == NULL)
	{
		free(complete_avl_name);
		return NULL;
	}

	full_path = get_full_path_of_avl_dir(dms, avl_name);
	if (full_path == NULL)
	{
		free(complete_avl_name);
		free(avl_file_name);
		return NULL;
	}

	strcat(full_path, "/");
	strcat(full_path, avl_file_name);

	free(complete_avl_name);

	return full_path;
}


char* obi_get_full_path_of_avl_data_file_name(OBIDMS_p dms, const char* avl_name, int avl_idx)
{
	char* complete_avl_name;
	char* full_path;
	char* avl_data_file_name;

	if (avl_idx >= 0)
	{
		complete_avl_name = obi_build_avl_name_with_idx(avl_name, avl_idx);
		if (complete_avl_name == NULL)
			return NULL;
	}
	else
	{
		complete_avl_name = (char*) malloc((strlen(avl_name)+1)*sizeof(char));
		if (complete_avl_name == NULL)
		{
    		obi_set_errno(OBI_MALLOC_ERROR);
    		obidebug(1, "\nError allocating memory for an AVL name");
			return NULL;
		}
		strcpy(complete_avl_name, avl_name);
	}

	avl_data_file_name = build_avl_data_file_name(complete_avl_name);
	if (avl_data_file_name == NULL)
	{
		free(complete_avl_name);
		return NULL;
	}

	full_path = get_full_path_of_avl_dir(dms, avl_name);
	if (full_path == NULL)
	{
		free(complete_avl_name);
		free(avl_data_file_name);
		return NULL;
	}

	strcat(full_path, "/");
	strcat(full_path, avl_data_file_name);

	free(complete_avl_name);

	return full_path;
}


int obi_avl_exists(OBIDMS_p dms, const char* avl_name)
{
	struct stat buffer;
	char* 	    avl_dir_path;
	int 	    check_dir;

	// Build the AVL tree file path
	avl_dir_path = get_full_path_of_avl_dir(dms, avl_name);
	if (avl_dir_path == NULL)
		return -1;

	check_dir = stat(avl_dir_path, &buffer);

	free(avl_dir_path);

	if (check_dir == 0)
		return 1;
	else
		return 0;
}


OBIDMS_avl_p obi_create_avl(OBIDMS_p dms, const char* avl_name, int avl_idx)
{
	char* 				complete_avl_name;
	char*				avl_dir_name;
	char* 				avl_file_name;
	char* 				avl_data_file_name;
	size_t				header_size;
	size_t				data_size;
	size_t				file_size;
	int					avl_file_descriptor;
	int					avl_data_file_descriptor;
	int					avl_dir_fd;
	OBIDMS_avl_data_p   avl_data;
	OBIDMS_avl_p		avl;
 	DIR*				directory;
    struct stat 		buffer;
    int 				check_dir;

	// Get complete name of AVL if index
	if (avl_idx >= 0)
	{
		complete_avl_name = obi_build_avl_name_with_idx(avl_name, avl_idx);
		if (complete_avl_name == NULL)
			return NULL;
	}
	else
	{
		complete_avl_name = (char*) malloc((strlen(avl_name)+1)*sizeof(char));
		if (complete_avl_name == NULL)
		{
    		obi_set_errno(OBI_MALLOC_ERROR);
    		obidebug(1, "\nError allocating memory for an AVL name");
			return NULL;
		}
		strcpy(complete_avl_name, avl_name);
	}

	// Create that AVL's directory if needed
	avl_dir_name = get_full_path_of_avl_dir(dms, avl_name);
	if (avl_dir_name == NULL)
		return NULL;
	// Check if the AVL's directory already exists
	check_dir = stat(avl_dir_name, &buffer);
	// Create that AVL's directory if it doesn't already exist
   	if (check_dir < 0)
   	{
		if (mkdirat(dms->indexer_dir_fd, avl_dir_name, 00777) < 0)
		{
			obi_set_errno(OBI_AVL_ERROR);
			obidebug(1, "\nError creating an AVL directory");
			if (avl_idx >= 0)
				free(complete_avl_name);
			free(avl_dir_name);
			return NULL;
		}
   	}
    // Open the AVL directory
    directory = opendir(avl_dir_name);
	if (directory == NULL)
	{
		obidebug(1, "\nError opening an AVL directory");
		if (avl_idx >= 0)
			free(complete_avl_name);
		free(avl_dir_name);
		return NULL;
	}
	free(avl_dir_name);
    avl_dir_fd = dirfd(directory);
	if (avl_dir_fd < 0)
	{
		obidebug(1, "\nError getting an AVL directory file descriptor");
		if (avl_idx >= 0)
			free(complete_avl_name);
		return NULL;
	}

	// Create the data file

		// Build file name
	avl_data_file_name = build_avl_data_file_name(complete_avl_name);
	if (avl_data_file_name == NULL)
	{
		if (avl_idx >= 0)
			free(complete_avl_name);
		return NULL;
	}

		// Create file
	avl_data_file_descriptor = openat(avl_dir_fd, avl_data_file_name, O_RDWR | O_CREAT | O_EXCL, 0777);
	if (avl_data_file_descriptor < 0)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError creating an AVL tree data file");
		if (avl_idx >= 0)
			free(complete_avl_name);
		free(avl_data_file_name);
		return NULL;
	}
	free(avl_data_file_name);

		// Calculate the size needed
	header_size = get_avl_data_header_size();
	data_size   = get_initial_avl_data_size();
	file_size   = header_size + data_size;

		// Truncate the AVL tree data file to the right size
	if (ftruncate(avl_data_file_descriptor, file_size) < 0)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError truncating an AVL tree data file to the right size");
		if (avl_idx >= 0)
			free(complete_avl_name);
		close(avl_data_file_descriptor);
		return NULL;
	}

		// Allocate the memory for the AVL tree data structure
	avl_data = (OBIDMS_avl_data_p) malloc(sizeof(OBIDMS_avl_data_t));
	if (avl_data == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating the memory for the AVL tree data structure");
		if (avl_idx >= 0)
			free(complete_avl_name);
		close(avl_data_file_descriptor);
		return NULL;
	}

		// Fill the AVL tree data structure
	avl_data->header = mmap(NULL,
			                header_size,
			                PROT_READ | PROT_WRITE,
			                MAP_SHARED,
			                avl_data_file_descriptor,
			                0
			               );
	if (avl_data->header == MAP_FAILED)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError mmapping the header of an AVL tree data file");
		if (avl_idx >= 0)
			free(complete_avl_name);
		close(avl_data_file_descriptor);
		free(avl_data);
		return NULL;
	}

	avl_data->data   = mmap(NULL,
			                data_size,
			                PROT_READ | PROT_WRITE,
			                MAP_SHARED,
			                avl_data_file_descriptor,
			                header_size
			               );
	if (avl_data->data == MAP_FAILED)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError mmapping the data of an AVL tree data file");
		if (avl_idx >= 0)
			free(complete_avl_name);
		munmap(avl_data->header, header_size);
		close(avl_data_file_descriptor);
		free(avl_data);
		return NULL;
	}

	(avl_data->header)->header_size 	 = header_size;
	(avl_data->header)->data_size_max	 = data_size;
	(avl_data->header)->data_size_used   = 0;
	(avl_data->header)->nb_items	 	 = 0;
	(avl_data->header)->creation_date    = time(NULL);
	strcpy((avl_data->header)->avl_name, complete_avl_name);

	avl_data->data_fd = avl_data_file_descriptor;

	// Initialize all bits to 0
	memset(avl_data->data, 0, (avl_data->header)->data_size_max);


	// Create the AVL tree file

		// Build file name
	avl_file_name = build_avl_file_name(complete_avl_name);
	if (avl_file_name == NULL)
	{
		close_avl_data(avl_data, true);
		return NULL;
	}

		// Calculate the size needed
	header_size = get_avl_header_size();
	data_size = get_initial_avl_size();
	file_size = header_size + data_size;

		// Create file
	avl_file_descriptor = openat(avl_dir_fd, avl_file_name, O_RDWR | O_CREAT | O_EXCL, 0777);
	if (avl_file_descriptor < 0)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError creating an AVL tree file");
		if (avl_idx >= 0)
			free(complete_avl_name);
		close_avl_data(avl_data, true);
		free(avl_file_name);
		return NULL;
	}
	free(avl_file_name);

		// Truncate the AVL tree file to the right size
	if (ftruncate(avl_file_descriptor, file_size) < 0)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError truncating an AVL tree file to the right size");
		if (avl_idx >= 0)
			free(complete_avl_name);
		close_avl_data(avl_data, true);
		close(avl_file_descriptor);
		return NULL;
	}

		// Allocate the memory for the AVL tree structure
	avl = (OBIDMS_avl_p) malloc(sizeof(OBIDMS_avl_t));
	if (avl == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating the memory for the AVL tree structure");
		if (avl_idx >= 0)
			free(complete_avl_name);
		close_avl_data(avl_data, true);
		close(avl_file_descriptor);
		return NULL;
	}

		// Fill the AVL tree structure
	avl->header = mmap(NULL,
			           header_size,
			           PROT_READ | PROT_WRITE,
			           MAP_SHARED,
			           avl_file_descriptor,
			           0
			          );
	if (avl->header == MAP_FAILED)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError mmapping the header of an AVL tree file");
		if (avl_idx >= 0)
			free(complete_avl_name);
		close_avl_data(avl_data, true);
		close(avl_file_descriptor);
		free(avl);
		return NULL;
	}

	avl->tree  = mmap(NULL,
			          data_size,
			          PROT_READ | PROT_WRITE,
			          MAP_SHARED,
			          avl_file_descriptor,
			          header_size
			         );
	if (avl->tree == MAP_FAILED)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError mmapping the data of an AVL tree file");
		if (avl_idx >= 0)
			free(complete_avl_name);
		close_avl_data(avl_data, true);
		munmap(avl->header, header_size);
		close(avl_file_descriptor);
		free(avl);
		return NULL;
	}

	avl->dms       = dms;
	avl->data      = avl_data;
	avl->avl_fd    = avl_file_descriptor;

	(avl->header)->header_size 	 = header_size;
	(avl->header)->avl_size 	 = data_size;
	(avl->header)->nb_items	 	 = 0;
	(avl->header)->nb_items_max	 = (index_t) floor(((double) (avl->header)->avl_size) / ((double) sizeof(AVL_node_t)));
	(avl->header)->root_idx      = -1;
	(avl->header)->creation_date = time(NULL);
	strcpy((avl->header)->avl_name, complete_avl_name);

	// Bloom filter
	bloom_init(&((avl->header)->bloom_filter), MAX_NODE_COUNT_PER_AVL);

	free(complete_avl_name);

	if (closedir(directory) < 0)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError closing an AVL directory");
		return NULL;
	}

	return avl;
}


OBIDMS_avl_p obi_open_avl(OBIDMS_p dms, const char* avl_name, int avl_idx)
{
	char* 	 			avl_file_name;
	char*				complete_avl_name;
	char*				avl_dir_name;
	char* 				avl_data_file_name;
	DIR*				directory;
	size_t				header_size;
	int					avl_file_descriptor;
	int					avl_data_file_descriptor;
	int					avl_dir_file_descriptor;
	OBIDMS_avl_data_p   avl_data;
	OBIDMS_avl_p		avl;

	// Get complete name of AVL if index
	if (avl_idx >= 0)
	{
		complete_avl_name = obi_build_avl_name_with_idx(avl_name, avl_idx);
		if (complete_avl_name == NULL)
			return NULL;
	}
	else
	{
		complete_avl_name = (char*) malloc((strlen(avl_name)+1)*sizeof(char));
		if (complete_avl_name == NULL)
		{
    		obi_set_errno(OBI_MALLOC_ERROR);
    		obidebug(1, "\nError allocating memory for an AVL name");
			return NULL;
		}
		strcpy(complete_avl_name, avl_name);
	}

    // Open the AVL directory
	avl_dir_name = get_full_path_of_avl_dir(dms, avl_name);
	if (avl_dir_name == NULL)
	{
		free(complete_avl_name);
		return NULL;
	}
    directory = opendir(avl_dir_name);
	if (directory == NULL)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError opening an AVL directory");
		free(complete_avl_name);
		free(avl_dir_name);
		return NULL;
	}
	free(avl_dir_name);
	avl_dir_file_descriptor = dirfd(directory);
	if (avl_dir_file_descriptor < 0)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError getting the file descriptor of an AVL directory");
		free(complete_avl_name);
		return NULL;
	}


	// Open the data file

		// Build file name
	avl_data_file_name = build_avl_data_file_name(complete_avl_name);
	if (avl_data_file_name == NULL)
		return NULL;

		// Open file
	avl_data_file_descriptor = openat(avl_dir_file_descriptor, avl_data_file_name, O_RDWR, 0777);
	if (avl_data_file_descriptor < 0)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError opening an AVL tree data file");
		free(complete_avl_name);
		free(avl_data_file_name);
		return NULL;
	}
	free(avl_data_file_name);

		// Allocate the memory for the AVL tree data structure
	avl_data = (OBIDMS_avl_data_p) malloc(sizeof(OBIDMS_avl_data_t));
	if (avl_data == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating the memory for the AVL tree data structure");
		free(complete_avl_name);
		close(avl_data_file_descriptor);
		return NULL;
	}

	// Read the header size
	if (read(avl_data_file_descriptor, &header_size, sizeof(size_t)) < ((ssize_t) sizeof(size_t)))
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError reading the header size to open an AVL tree data file");
		free(complete_avl_name);
		close(avl_data_file_descriptor);
		return NULL;
	}

		// Fill the avl data structure
	avl_data->header = mmap(NULL,
			                header_size,
							PROT_READ | PROT_WRITE,
			                MAP_SHARED,
			                avl_data_file_descriptor,
			                0
			               );
	if (avl_data->header == MAP_FAILED)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError mmapping the header of an AVL tree data file");
		free(complete_avl_name);
		close(avl_data_file_descriptor);
		free(avl_data);
		return NULL;
	}

	avl_data->data   = mmap(NULL,
			                (avl_data->header)->data_size_max,
			                PROT_READ,
			                MAP_SHARED,
			                avl_data_file_descriptor,
			                header_size
			               );
	if (avl_data->data == MAP_FAILED)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError mmapping the data of an AVL tree data file");
		free(complete_avl_name);
		munmap(avl_data->header, header_size);
		close(avl_data_file_descriptor);
		free(avl_data);
		return NULL;
	}

	avl_data->data_fd = avl_data_file_descriptor;


	// Open the AVL tree file

		// Build file name
	avl_file_name = build_avl_file_name(complete_avl_name);
	if (avl_file_name == NULL)
	{
		close_avl_data(avl_data, false);
		return NULL;
	}

		// Open file
	avl_file_descriptor = openat(avl_dir_file_descriptor, avl_file_name, O_RDWR, 0777);
	if (avl_file_descriptor < 0)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError opening an AVL tree file");
		free(complete_avl_name);
		close_avl_data(avl_data, false);
		free(avl_file_name);
		return NULL;
	}
	free(avl_file_name);

		// Allocate the memory for the AVL tree structure
	avl = (OBIDMS_avl_p) malloc(sizeof(OBIDMS_avl_t));
	if (avl == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating the memory for the AVL tree structure");
		free(complete_avl_name);
		close_avl_data(avl_data, false);
		close(avl_file_descriptor);
		return NULL;
	}

		// Read the header size
	if (read(avl_file_descriptor, &header_size, sizeof(size_t)) < ((ssize_t) sizeof(size_t)))
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError reading the header size to open an AVL tree");
		free(complete_avl_name);
		close_avl_data(avl_data, false);
		close(avl_file_descriptor);
		return NULL;
	}

		// Fill the avl structure
	avl->header = mmap(NULL,
			           header_size,
					   PROT_READ | PROT_WRITE,
			           MAP_SHARED,
			           avl_file_descriptor,
			           0
			          );
	if (avl->header == MAP_FAILED)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError mmapping the header of an AVL tree file");
		free(complete_avl_name);
		close_avl_data(avl_data, false);
		close(avl_file_descriptor);
		free(avl);
		return NULL;
	}

	avl->tree = mmap(NULL,
					 (avl->header)->avl_size,
			         PROT_READ,
			         MAP_SHARED,
			         avl_file_descriptor,
			         header_size
			        );
	if (avl->tree == MAP_FAILED)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError mmapping the data of an AVL tree file");
		free(complete_avl_name);
		close_avl_data(avl_data, false);
		munmap(avl->header, header_size);
		close(avl_file_descriptor);
		free(avl);
		return NULL;
	}

	avl->dms       = dms;
	avl->data      = avl_data;
	avl->avl_fd    = avl_file_descriptor;

	free(complete_avl_name);

	if (closedir(directory) < 0)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError closing an AVL directory");
		return NULL;
	}

	return avl;
}


OBIDMS_avl_group_p obi_avl_group(OBIDMS_p dms, const char* avl_name)
{
	int exists;

	exists = obi_avl_exists(dms, avl_name);

	switch (exists)
	{
		case 0:
			return obi_create_avl_group(dms, avl_name);
		case 1:
			return obi_open_avl_group(dms, avl_name);
	};

	obidebug(1, "\nError checking if an AVL tree already exists");
	return NULL;
}


OBIDMS_avl_group_p obi_create_avl_group(OBIDMS_p dms, const char* avl_name)
{
	OBIDMS_avl_group_p avl_group;
	char* 			   avl_dir_name;

	avl_group = (OBIDMS_avl_group_p) malloc(sizeof(OBIDMS_avl_group_t));
	if (avl_group == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating the memory for an AVL group");
		return NULL;
	}

	avl_group->last_avl_idx = -1;
	avl_group->dms = dms;
	strcpy(avl_group->name, avl_name);

	// Create the directory for that AVL group
	avl_dir_name = get_full_path_of_avl_dir(dms, avl_name);
	if (avl_dir_name == NULL)
		return NULL;

	if (mkdirat(dms->indexer_dir_fd, avl_dir_name, 00777) < 0)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError creating an AVL directory");
		free(avl_dir_name);
		return NULL;
	}

	// Add in the list of open indexers
	obi_dms_list_indexer(dms, avl_group);

	// Set counter to 1
	avl_group->counter = 1;

	// Set as writable
	avl_group->writable = true;

	free(avl_dir_name);

	return avl_group;
}


OBIDMS_avl_group_p obi_open_avl_group(OBIDMS_p dms, const char* avl_name)
{
	OBIDMS_avl_group_p  avl_group;
	char*				avl_dir_name;
	int					avl_count;
	int					i;

	// Check if the group isn't already open
	avl_group = obi_dms_get_indexer_from_list(dms, avl_name);
	if (avl_group != NULL)	// Found it
	{
		// Increment counter
		(avl_group->counter)++;
		return avl_group;
	}

	avl_group = (OBIDMS_avl_group_p) malloc(sizeof(OBIDMS_avl_group_t));
	if (avl_group == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating the memory for an AVL group");
		return NULL;
	}

	// Count the AVLs
	avl_dir_name = get_full_path_of_avl_dir(dms, avl_name);
	if (avl_dir_name == NULL)
		return NULL;
	avl_count = count_dir(avl_dir_name) / 2;
	if (avl_count < 0)
	{
		obidebug(1, "\nError counting the AVLs in an AVL directory: %s", avl_name);
		return NULL;
	}

	// Open the AVLs
	for (i=0; i<avl_count; i++)
	{
		(avl_group->sub_avls)[i] = obi_open_avl(dms, avl_name, i);
		if ((avl_group->sub_avls)[i] == NULL)
			return NULL;
	}

	// Store the index of the last AVL (the one to be modified)
	avl_group->last_avl_idx = avl_count-1;
	strcpy(avl_group->name, avl_name);

	avl_group->dms = dms;

	// Add in the list of open indexers
	obi_dms_list_indexer(dms, avl_group);

	// Set counter to 1
	avl_group->counter = 1;

	// Set as read-only
	avl_group->writable = false;

	free(avl_dir_name);

	return avl_group;
}


int obi_clone_avl(OBIDMS_avl_p avl, OBIDMS_avl_p new_avl)
{
	// Grow the new AVL as needed before copying
	while (((new_avl->header)->nb_items_max) < ((avl->header)->nb_items))
	{
		if (grow_avl(new_avl) < 0)
			return -1;
	}
	while ((((new_avl->data)->header)->data_size_max) < (((avl->data)->header)->data_size_used))
	{
		if (grow_avl_data(new_avl->data) < 0)
			return -1;
	}

	// Clone AVL tree
	memcpy(new_avl->tree, avl->tree, (avl->header)->avl_size);
	memcpy(&((new_avl->header)->bloom_filter), &((avl->header)->bloom_filter), bloom_filter_size(MAX_NODE_COUNT_PER_AVL, BLOOM_FILTER_ERROR_RATE));
	(new_avl->header)->avl_size     = (avl->header)->avl_size;
	(new_avl->header)->nb_items     = (avl->header)->nb_items;
	(new_avl->header)->root_idx     = (avl->header)->root_idx;

	// Clone AVL data
	memcpy((new_avl->data)->data, (avl->data)->data, ((avl->data)->header)->data_size_used);
	((new_avl->data)->header)->data_size_used = ((avl->data)->header)->data_size_used;
	((new_avl->data)->header)->data_size_max  = ((avl->data)->header)->data_size_max;
	((new_avl->data)->header)->nb_items       = ((avl->data)->header)->nb_items;

	//avl_print(new_avl);
	return 0;
}


OBIDMS_avl_group_p obi_clone_avl_group(OBIDMS_avl_group_p avl_group, const char* new_avl_name)
{
	OBIDMS_avl_group_p new_avl_group;
	int i;

	// Create the new AVL group
	new_avl_group = obi_create_avl_group(avl_group->dms, new_avl_name);
	if (new_avl_group == NULL)
		return NULL;

	// Create hard links to all the full AVLs that won't be modified: all but the last one
	for (i=0; i<(avl_group->last_avl_idx); i++)
	{
		if (add_existing_avl_in_group(new_avl_group, avl_group, i) < 0)
		{
			obidebug(1, "\nError adding an existing AVL tree in a new group of AVL trees");
			return NULL;
		}
	}

	// Create the last AVL to copy data in it
	if (add_new_avl_in_group(new_avl_group) < 0)
	{
		obidebug(1, "\nError creating a new AVL tree in a new group of AVL trees");
		obi_close_avl_group(new_avl_group);
		return NULL;
	}

	// Copy the data from the last AVL to the new one that can be modified
	if ((((avl_group->sub_avls)[avl_group->last_avl_idx])->header)->nb_items > 0)
	{
		if (obi_clone_avl((avl_group->sub_avls)[avl_group->last_avl_idx], (new_avl_group->sub_avls)[new_avl_group->last_avl_idx]) < 0)
		{
			obidebug(1, "\nError copying an AVL tree in a new group of AVL trees");
			obi_close_avl_group(new_avl_group);
			return NULL;
		}
	}

	// Close old AVL group
	if (obi_close_avl_group(avl_group) < 0)
	{
		obidebug(1, "\nError closing a group of AVL trees after cloning it to make a new group");
		obi_close_avl_group(new_avl_group);
		return NULL;
	}

	return new_avl_group;
}


int obi_close_avl(OBIDMS_avl_p avl, bool writable)
{
	int ret_val = 0;

	ret_val = close_avl_data(avl->data, writable);

	if (writable)
		ret_val = truncate_avl_to_size_used(avl);

	if (munmap(avl->tree, (avl->header)->avl_size) < 0)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError munmapping the tree of an AVL tree file");
		ret_val = -1;
	}

	if (munmap(avl->header, (avl->header)->header_size) < 0)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError munmapping the header of an AVL tree file");
		ret_val = -1;
	}

	if (close(avl->avl_fd) < 0)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nError closing an AVL tree file");
		ret_val = -1;
	}

	free(avl);

	return ret_val;
}


int obi_close_avl_group(OBIDMS_avl_group_p avl_group)
{
	int i;
	int ret_val;

	ret_val = 0;

	(avl_group->counter)--;

	if (avl_group->counter == 0)
	{
		// Delete from the list of opened indexers
		ret_val = obi_dms_unlist_indexer(avl_group->dms, avl_group);

		// Close each AVL of the group
		for (i=0; i <= (avl_group->last_avl_idx); i++)
		{
			// Remap all but the last AVL (already mapped) before closing to truncate and close properly
			if (i < (avl_group->last_avl_idx))
			{
				if (remap_an_avl((avl_group->sub_avls)[i]) < 0)
					ret_val = -1;
			}
			if (obi_close_avl((avl_group->sub_avls)[i], avl_group->writable) < 0)
				ret_val = -1;
		}

		free(avl_group);
	}

	return ret_val;
}


Obi_blob_p obi_avl_get(OBIDMS_avl_p avl, index_t idx)
{
	return ((Obi_blob_p)(((avl->data)->data)+idx));
}


index_t obi_avl_add(OBIDMS_avl_p avl, Obi_blob_p value)
{
	AVL_node_p       node_to_add = NULL;
	AVL_node_p       current_node;
	index_t          next, parent;
	index_t          value_data_idx;
	index_t          node_idx;
	Obi_blob_p 		 to_compare;
	int 			 comp;
	int 			 n;
	int 			 depth;
	uint64_t 		 crc;

	n = 0;
	depth = 0;
	crc = crc64((byte_t*)value, obi_blob_sizeof(value));

	// Check if first node
	if (!((avl->header)->nb_items))
	{
		node_to_add = avl_create_node(avl, 0);

		// Add the value in the data array and store its index
		value_data_idx = avl_add_value_in_data_array(avl, value);
		node_to_add->value = value_data_idx;
		node_to_add->crc64 = crc;

		// Update the number of items
		((avl->header)->nb_items)++;

		// Set the AVL tree root
		(avl->header)->root_idx = 0;

		return 0;
	}

	// Not first node
	next = (avl->header)->root_idx;
	parent = next;
	comp = 0;

	while (next != -1)
	{
		current_node = (avl->tree)+next;

		// Store path from the lowest node with a balance factor different than 0,
		// as it is the node that will have to be balanced.
		if (current_node->balance_factor != 0)
			// New lowest node with a balance factor different than 0
			n=0;
		(avl->path_idx)[n] = parent;	// Store parent
		(avl->path_dir)[n] = comp < 0;	// Store direction (0 if left, 1 if right)
		n++;

		parent = next;

		// Compare the crc of the value with the crc of the current node
		comp = (current_node->crc64) - crc;

		if (comp == 0)
		{ // check if really same value
			to_compare = obi_avl_get(avl, current_node->value);
			comp = obi_blob_compare(to_compare, value);
		}

		if (comp > 0)
			// Go to left child
			next = current_node->left_child;
		else if (comp < 0)
			// Go to right child
			next = current_node->right_child;
		else if (comp == 0)
			// Value already stored
		{	// TODO add an option to eventually return the value index? (useful for simple AVLs (not in groups))
			obi_set_errno(OBI_AVL_ERROR);
			obidebug(1, "\nValue to add already in AVL");
			return -1;
		}

		depth++;
	}

	// Check if the AVL tree has not become too big
	if (depth == AVL_MAX_DEPTH)
	{
		obi_set_errno(OBI_AVL_ERROR);
		obidebug(1, "\nThis AVL tree has reached the maximum depth (%d).", AVL_MAX_DEPTH);
		return -1;
	}

	// Grow the AVL tree if needed
	if ((avl->header)->nb_items == (avl->header)->nb_items_max)
	{
		if (grow_avl(avl) < 0)
			return -1;
	}

	// Initialize node at the end of the tree
	node_idx    = (avl->header)->nb_items;
	node_to_add = avl_create_node(avl, node_idx);

	// Add the value in the data array and store its index
	value_data_idx = avl_add_value_in_data_array(avl, value);
	node_to_add->value = value_data_idx;
	node_to_add->crc64 = crc;

	// Update the number of items
	((avl->header)->nb_items)++;

	// Add either as right or left child
	if (comp > 0)	// Add as left child
		((avl->tree)+parent)->left_child = node_idx;
	else		    // Add as right child
		((avl->tree)+parent)->right_child = node_idx;

	// End path
	(avl->path_idx)[n] = parent;
	(avl->path_dir)[n] = comp < 0;	// 0 if went left, 1 if went right
	n++;
	(avl->path_idx)[n] = -1;	// flag path end
	(avl->path_dir)[n] = -1;

	// Update balance factors
	avl_update_balance_factors(avl);

	// Balance tree
	avl_balance(avl);

	// Print tree
	//avl_print(avl);

	return value_data_idx;
}


// Find if a value is already in an AVL tree
index_t obi_avl_find(OBIDMS_avl_p avl, Obi_blob_p value)
{
	int              comp;
	index_t          next;
	Obi_blob_p		 to_compare;
	AVL_node_p       current_node;
	uint64_t         crc;

	crc = crc64((byte_t*)value, obi_blob_sizeof(value));

	next = (avl->header)->root_idx;
	while (next != -1)
	{
		current_node = (avl->tree)+next;

		// Compare the crc of the value with the crc of the current node
		comp = (current_node->crc64) - crc;

		if (comp == 0)
		{ // Check if really same value
			to_compare = obi_avl_get(avl, current_node->value);
			comp = obi_blob_compare(to_compare, value);
		}

		if (comp > 0)
			// Go to left child
			next = current_node->left_child;
		else if (comp < 0)
			// Go to right child
			next = current_node->right_child;
		else if (comp == 0)
		{	// Value found
			return current_node->value;
		}
	}
	// Value not found
	return -1;
}


Obi_blob_p obi_avl_group_get(OBIDMS_avl_group_p avl_group, index_t idx)
{
	int32_t avl_idx;
	index_t idx_in_avl;

	avl_idx = (int32_t) (idx >> 32);
	idx_in_avl = idx & 0x00000000FFFFFFFF;

	return obi_avl_get((avl_group->sub_avls)[avl_idx], idx_in_avl);
}


index_t obi_avl_group_add(OBIDMS_avl_group_p avl_group, Obi_blob_p value)
{
	int32_t index_in_avl;
	index_t index_with_avl;
	int     i;

	// Create 1st AVL if group is empty
	if (avl_group->last_avl_idx == -1)
	{
		if (add_new_avl_in_group(avl_group) < 0)
		{
			obidebug(1, "\nError creating the first AVL of an AVL group");
			return -1;
		}
	}
	
	// Check if already in current AVL
	if (maybe_in_avl((avl_group->sub_avls)[avl_group->last_avl_idx], value))
	{
		index_in_avl = (int32_t) obi_avl_find((avl_group->sub_avls)[avl_group->last_avl_idx], value);
		if (index_in_avl >= 0)
		{
			index_with_avl = avl_group->last_avl_idx;
			index_with_avl = index_with_avl << 32;
			index_with_avl = index_with_avl + index_in_avl;
			return index_with_avl;
		}
	}

	for (i=0; i < (avl_group->last_avl_idx); i++)
	{
		if (maybe_in_avl((avl_group->sub_avls)[i], value))
		{  // AVLS are not unmapped and remapped anymore as it is very costly and keeping all mapped seems to be handled well
			//if (remap_an_avl((avl_group->sub_avls)[i]) < 0)
			//	return -1;
			index_in_avl = (int32_t) obi_avl_find((avl_group->sub_avls)[i], value);
			//if (unmap_an_avl((avl_group->sub_avls)[i]) < 0)
			//	return -1;
			if (index_in_avl >= 0)
			{
				index_with_avl = i;
				index_with_avl = index_with_avl << 32;
				index_with_avl = index_with_avl + index_in_avl;
				return index_with_avl;
			}
		}
	}

	// Not found in any AVL: add in current

	// Check if the AVL group is writable
	if (!(avl_group->writable))
	{
		obi_set_errno(OBI_READ_ONLY_INDEXER_ERROR);	// Note: this error is read by the calling functions to clone the AVL group if needed
		return -1;
	}

	// Check if need to make new AVL
	if (((((avl_group->sub_avls)[avl_group->last_avl_idx])->header)->nb_items == MAX_NODE_COUNT_PER_AVL) || ((((((avl_group->sub_avls)[avl_group->last_avl_idx])->data)->header)->data_size_used + obi_blob_sizeof(value)) >= MAX_DATA_SIZE_PER_AVL))
	{
		if (add_new_avl_in_group(avl_group) < 0)
			return -1;
	}

	// Add in the current AVL
	index_in_avl = (int32_t) obi_avl_add((avl_group->sub_avls)[avl_group->last_avl_idx], value);
	if (index_in_avl < 0)
		return -1;

	bloom_add(&((((avl_group->sub_avls)[avl_group->last_avl_idx])->header)->bloom_filter), value, obi_blob_sizeof(value));

	// Build the index containing the AVL index
	index_with_avl = avl_group->last_avl_idx;
	index_with_avl = index_with_avl << 32;
	index_with_avl = index_with_avl + index_in_avl;

	return index_with_avl;
}


const char* obi_avl_group_get_name(OBIDMS_avl_group_p avl_group)
{
	return avl_group->name;
}

