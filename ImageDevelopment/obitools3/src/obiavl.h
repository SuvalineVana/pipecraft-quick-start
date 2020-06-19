/****************************************************************************
 * OBIDMS AVL tree header file	                                            *
 ****************************************************************************/

/**
 * @file obiavl.h
 * @author Celine Mercier
 * @date December 3rd 2015
 * @brief Header file for handling AVL trees for storing and retrieving blobs.
 */


#ifndef OBIAVL_H_
#define OBIAVL_H_


#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <time.h>
#include <sys/types.h>
#include <dirent.h>
#include <stdbool.h>

#include "obidms.h"
#include "obiblob.h"
#include "obitypes.h"
#include "bloom.h"
#include "utils.h"
#include "encode.h"


#define MAX_NB_OF_AVLS_IN_GROUP (1000)						/**< The maximum number of AVL trees in a group.	// TODO discuss
                              	  	 	 	 	 	 	 	 */
#define MAX_NODE_COUNT_PER_AVL (5000000)					/**< The maximum number of nodes in an AVL tree.
															 *   Only used to decide when to create a new AVL in a group, and to initialize the bloom filter // TODO discuss. Try 30M?
                              	  	 	 	 	 	 	 	 */
#define MAX_DATA_SIZE_PER_AVL (1073741824)		            /**< The maximum size of the data referred to by an AVL tree in a group.
 	 	 	 	 	 	 	         	 	 	 	 	 	 *   Only used to decide when to create a new AVL in a group.
 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 *   Should not be greater than int32_t max (2,147,483,647), as indexes will have to be stored on 32 bits.
 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 */
#define AVL_MAX_DEPTH (1024)								/**< The maximum depth of an AVL tree. Used to save paths through the tree.
                              	  	 	 	 	 	 	 	 */
#define AVL_MAX_NAME (250) 				     				/**< The maximum length of an AVL tree name.
                              	  	 	 	 	 	 	 	 */
#define AVL_GROWTH_FACTOR (2)								/**< The growth factor when an AVL tree is enlarged.
                                	 	 	 	 	 	 	 */
#define LEFT_CHILD(node)	(avl->tree)+(node->left_child)  /**< Pointer to the left child of a node in an AVL tree.
															 */
#define RIGHT_CHILD(node)	(avl->tree)+(node->right_child) /**< Pointer to the right child of a node in an AVL tree.
															 */


/**
 * @brief AVL tree node structure.
 */
typedef struct AVL_node {
	index_t  left_child;	  /**< Index of left less child node.
	  	 	 	 	 	 	   */
	index_t  right_child; 	  /**< Index of right greater child node.
	 	 	 	 	 	 	   */
	int8_t   balance_factor;  /**< Balance factor of the node.
							   */
	index_t  value;			  /**< Index of the value associated with the node in the data array.
							   */
	uint64_t crc64;			  /**< Cyclic Redundancy Check code on 64 bits associated with the value.
	 	 	 	 	 	 	   */
} AVL_node_t, *AVL_node_p;


/**
 * @brief OBIDMS AVL tree data header structure.
 */
typedef struct OBIDMS_avl_data_header {
	size_t		header_size;						/**< Size of the header in bytes.
	 	 	 	 	 	 	 	 	 	 	 	 	 */
	index_t		data_size_used;						/**< Size of the data used in bytes.
	 	 	 	 	 	 	 	 	 	 	 	 	 */
	index_t		data_size_max;						/**< Max size of the data in bytes.
	 	 	 	 	 	 	 	 	 	 	 	 	 */
	index_t		nb_items;							/**< Number of items.
	 	 	 	 	 	 	 	 	 	 	 	 	 */
	char    	avl_name[AVL_MAX_NAME+1];			/**< The AVL tree name as a NULL terminated string.
													 */
	time_t		creation_date;			    	    /**< Date of creation of the file.
												     */
} OBIDMS_avl_data_header_t, *OBIDMS_avl_data_header_p;


/**
 * @brief OBIDMS AVL tree data structure.
 */
typedef struct OBIDMS_avl_data {
	OBIDMS_avl_data_header_p	header; 		 	/**< A pointer to the header of the AVL tree data.
	 	 	 	 	 	 	 	 	 	 	 	 	 */
	byte_t*                 	data;   		 	/**< A pointer to the beginning of the data.
													 */
	int							data_fd;	        /**< File descriptor of the file containing the data.
	 	 	 	 	 	 	 	 	 	 	 	 	 */
} OBIDMS_avl_data_t, *OBIDMS_avl_data_p;


/**
 * @brief OBIDMS AVL tree header structure.
 */
typedef struct OBIDMS_avl_header {
	size_t		header_size;						/**< Size of the header in bytes.
	 	 	 	 	 	 	 	 	 	 	 	 	 */
	size_t		avl_size;							/**< Size of the AVL tree in bytes.
	 	 	 	 	 	 	 	 	 	 	 	 	 */
	index_t		nb_items;							/**< Number of items in the AVL tree.
	 	 	 	 	 	 	 	 	 	 	 	 	 */
	index_t		nb_items_max;						/**< Maximum number of items in the AVL tree before it has to be enlarged.
	 	 	 	 	 	 	 	 	 	 	 	 	 */
	index_t		root_idx;							/**< Index of the root of the AVL tree.
	 	 	 	 	 	 	 	 	 	 	 	 	 */
	char    	avl_name[AVL_MAX_NAME+1];			/**< The AVL tree name as a NULL terminated string.
													 */
	time_t		creation_date;			    	    /**< Date of creation of the file.
												     */
	bloom_t 	bloom_filter;			    	    /**< Bloom filter associated with the AVL tree, enabling to know if a value
													 *   might already be stored in the data referred to by the tree.
     	 	 	 	 	 	 	 	 	 	 	 	 */
} OBIDMS_avl_header_t, *OBIDMS_avl_header_p;


/**
 * @brief OBIDMS AVL tree structure.
 */
typedef struct OBIDMS_avl {
	OBIDMS_p                	dms;			 			/**< A pointer to the OBIDMS structure to which the AVL tree belongs.
	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 */
	OBIDMS_avl_header_p			header; 	 				/**< A pointer to the header of the AVL tree.
	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 */
	struct AVL_node*           	tree;   		 			/**< A pointer to the root of the AVL tree.
	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 */
	index_t                     path_idx[AVL_MAX_DEPTH];	/**< The path taken to a node from the root as an array of node indices.
													 	     */
	int8_t                      path_dir[AVL_MAX_DEPTH];	/**< The path taken to a node from the root as an array of directions
															 *   (0 for left, -1 for right).
															 */
	OBIDMS_avl_data_p			data;						/**< A pointer to the structure containing the data
													 	 	 *   that the AVL tree references.
													 	 	 */
	int							avl_fd;						/**< The file descriptor of the file containing the AVL tree.
													 	 	 */
} OBIDMS_avl_t, *OBIDMS_avl_p;


/**
 * @brief OBIDMS AVL tree group structure.
 */
typedef struct OBIDMS_avl_group {
	OBIDMS_avl_p 	sub_avls[MAX_NB_OF_AVLS_IN_GROUP];		/**< Array containing the pointers to the AVL trees of the group.
	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 */
	int 			last_avl_idx;							/**< Index in the sub_avls array of the AVL tree currently being filled.
	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 */
	char			name[AVL_MAX_NAME+1];				 	/**< Base name of the AVL group. The AVL trees in it have names of the form basename_idx.
	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 */
	OBIDMS_p        dms;									/**< Pointer to the OBIDMS structure to which the AVL group belongs.
	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 */
	bool			writable;								/**< Indicates whether the AVL group is read-only or not.
															 */
	size_t			counter;								/**< Indicates by how many threads/programs (TODO) the AVL group is used.
													 	 	 */
} OBIDMS_avl_group_t, *OBIDMS_avl_group_p;



/**
 * @brief Function building the complete AVL name for an AVL with an associated index (for AVL groups).
 *
 * @warning The returned pointer has to be freed by the caller.
 *
 * @param avl_name The base name of the AVL tree.
 * @param avl_idx The index associated with that AVL.
 *
 * @returns A pointer to the complete name of the AVL.
 * @retval NULL if an error occurred.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
char* obi_build_avl_name_with_idx(const char* avl_name, int avl_idx);


/**
 * @brief Function building the full path of an AVL tree file.
 *
 * @warning The returned pointer has to be freed by the caller.
 *
 * @param dms A pointer to the OBIDMS to which the AVL tree belongs.
 * @param avl_name The name of the AVL tree.
 * @param avl_idx The index of the AVL if it's part of an AVL group, or -1 if not.
 *
 * @returns A pointer to the full path of the file where the AVL tree is stored.
 * @retval NULL if an error occurred.
 *
 * @since May 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
char* obi_get_full_path_of_avl_file_name(OBIDMS_p dms, const char* avl_name, int avl_idx);


/**
 * @brief Function building the file name for an AVL data file.
 *
 * @warning The returned pointer has to be freed by the caller.
 *
 * @param dms A pointer to the OBIDMS to which the AVL tree belongs.
 * @param avl_name The name of the AVL tree.
 * @param avl_idx The index of the AVL if it's part of an AVL group, or -1 if not.
 *
 * @returns A pointer to the full path of the file where the data referred to by the AVL tree is stored.
 * @retval NULL if an error occurred.
 *
 * @since May 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
char* obi_get_full_path_of_avl_data_file_name(OBIDMS_p dms, const char* avl_name, int avl_idx);


/**
 * @brief Checks if an AVL tree or AVL tree group already exists or not.
 *
 * @param dms The OBIDMS to which the AVL tree or AVL tree group belongs.
 * @param avl_name The name of the AVL tree or the base name of the AVL tree group.
 *
 * @returns A value indicating whether the AVL tree or AVL tree group exists or not.
 * @retval 1 if the AVL tree or AVL tree group exists.
 * @retval 0 if the AVL tree or AVL tree group does not exist.
 * @retval -1 if an error occurred.
 *
 * @since December 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_avl_exists(OBIDMS_p dms, const char* avl_name);


/**
 * @brief Creates an AVL tree. Fails if it already exists.
 *
 * Note: An AVL tree is made of two files (referred to by two structures).
 * 		 One file contains the tree referring to the data, and the other
 * 		 file contains the data itself. The AVL tree as a whole is referred
 * 		 to via the OBIDMS_avl structure. An AVL tree is stored in a directory
 * 		 with the same name, or with the base name of the AVL group if it is
 * 		 part of an AVL group.
 *
 * @param dms The OBIDMS to which the AVL tree belongs.
 * @param avl_name The name of the AVL tree.
 * @param avl_idx The index of the AVL tree if it is part of an AVL group,
 *        or -1 if it is not part of an AVL group.
 *
 * @returns A pointer to the newly created AVL tree structure.
 * @retval NULL if an error occurred.
 *
 * @since December 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
OBIDMS_avl_p obi_create_avl(OBIDMS_p dms, const char* avl_name, int avl_idx);


/**
 * @brief Opens an AVL tree in read-only mode. Fails if it does not already exist.
 *
 * Note: An AVL tree is made of two files (referred to by two structures).
 * 		 One file contains the tree referring to the data, and the other
 * 		 file contains the data itself. The AVL tree as a whole is referred
 * 		 to via the OBIDMS_avl structure.
 *
 * @param dms The OBIDMS to which the AVL tree belongs.
 * @param avl_name The name of the AVL tree.
 * @param avl_idx The index of the AVL tree if it is part of an AVL group,
 *        or -1 if it is not part of an AVL group.
 *
 * @returns A pointer to the AVL tree structure.
 * @retval NULL if an error occurred.
 *
 * @since December 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
OBIDMS_avl_p obi_open_avl(OBIDMS_p dms, const char* avl_name, int avl_idx);


/**
 * @brief Opens an AVL tree group and creates it if it does not already exist.
 *
 * Note: An AVL tree group is composed of multiple AVL trees that all have the
 *       same base name, and an index differentiating them.
 *
 * @param dms The OBIDMS to which the AVL tree belongs.
 * @param avl_name The base name of the AVL tree group.
 *
 * @returns A pointer to the AVL tree group structure.
 * @retval NULL if an error occurred.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
OBIDMS_avl_group_p obi_avl_group(OBIDMS_p dms, const char* avl_name);


/**
 * @brief Creates an AVL tree group.
 *
 * Note: An AVL tree group is composed of multiple AVL trees that all have the
 *       same base name, and an index differentiating them.
 *
 * @param dms The OBIDMS to which the AVL tree belongs.
 * @param avl_name The base name of the AVL tree group.
 *
 * @returns A pointer to the AVL tree group structure.
 * @retval NULL if an error occurred.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
OBIDMS_avl_group_p obi_create_avl_group(OBIDMS_p dms, const char* avl_name);


/**
 * @brief Opens an AVL tree group in read-only mode.
 *
 * Note: An AVL tree group is composed of multiple AVL trees that all have the
 *       same base name, and an index differentiating them.
 *
 * @param dms The OBIDMS to which the AVL tree belongs.
 * @param avl_name The base name of the AVL tree group.
 *
 * @returns A pointer to the AVL tree group structure.
 * @retval NULL if an error occurred.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
OBIDMS_avl_group_p obi_open_avl_group(OBIDMS_p dms, const char* avl_name);


/**
 * @brief Clones an AVL.
 *
 * The tree and the data are both cloned into the new AVL.
 *
 * @param avl A pointer on the AVL to clone.
 * @param new_avl A pointer on the new AVL to fill.
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since May 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_clone_avl(OBIDMS_avl_p avl, OBIDMS_avl_p new_avl);


/**
 * @brief Clones an AVL group.
 *
 * @warning The AVL group that has be cloned is closed by the function.
 *
 * @param avl_group A pointer on the AVL group to clone.
 * @param new_avl_name The name of the new AVL group.
 *
 * @returns A pointer on the new AVL group structure.
 * @retval NULL if an error occurred.
 *
 * @since May 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
OBIDMS_avl_group_p obi_clone_avl_group(OBIDMS_avl_group_p avl_group, const char* new_avl_name);


/**
 * @brief Closes an AVL tree.
 *
 * @param avl A pointer to the AVL tree structure to close and free.
 * @param writable Whether the AVL is writable or not (and therefore if the files can and should be truncated to the used size).
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since December 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_close_avl(OBIDMS_avl_p avl, bool writable);


/**
 * @brief Closes an AVL tree group.
 *
 * @param avl_group A pointer to the AVL tree group structure to close and free.
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_close_avl_group(OBIDMS_avl_group_p avl_group);


/**
 * @brief Recovers a value (blob) in an AVL tree.
 *
 * @warning The blob recovered must be decoded to get the original value.
 * @warning The blob recovered is mapped in memory.
 *
 * @param avl A pointer to the AVL tree.
 * @param index The index of the value in the data array.
 *
 * @returns A pointer to the blob recovered.
 *
 * @since December 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
Obi_blob_p obi_avl_get(OBIDMS_avl_p avl, index_t index);


/**
 * @brief Adds a value (blob) in an AVL tree.
 *
 * @warning The value given must be already be encoded into a blob structure (Obi_blob_t).
 * @warning If the value is already in the AVL tree, an error will be triggered.		// TODO to discuss
 *
 * @param avl A pointer to the AVL tree.
 * @param value The blob to add in the AVL tree.
 *
 * @returns The index of the value newly added in the AVL tree.
 * @retval -1 if an error occurred.
 *
 * @since December 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
index_t obi_avl_add(OBIDMS_avl_p avl, Obi_blob_p value);


/**
 * @brief Finds a value (blob) in an AVL tree.
 *
 * @warning The value given must be already be encoded into a blob structure (Obi_blob_t).
 *
 * @param avl A pointer to the AVL tree.
 * @param value The blob to add in the AVL tree.
 *
 * @returns The data index of the value.
 * @retval -1 if the value is not in the tree.
 *
 * @since December 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
index_t obi_avl_find(OBIDMS_avl_p avl, Obi_blob_p value);


/**
 * @brief Recovers a value (blob) in an AVL tree.
 *
 * @warning The blob recovered must be decoded to get the original value.
 * @warning The blob recovered is mapped in memory.
 *
 * @param avl_group A pointer to the AVL tree.
 * @param index The index of the value in the form of a 64-bit integer
 *              with the 32 left-most bits coding for the index of the tree of
 *              the group in which the value is stored, and the 32 right-most bits
 *              coding for the index at which the value is stored in that AVL tree.
 *
 * @returns A pointer to the blob recovered.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
Obi_blob_p obi_avl_group_get(OBIDMS_avl_group_p avl_group, index_t idx);


/**
 * @brief Adds a value (blob) in an AVL tree group, checking if it is already in it.
 *
 * @warning The value given must be already be encoded into a blob structure (Obi_blob_t).
 *
 * @param avl_group A pointer to the AVL tree group.
 * @param value The blob to add in the AVL tree group.
 *
 * @returns The index of the value newly added in the AVL tree group, in the form of a
 *          64-bit integer with the 32 left-most bits coding for the index of the tree
 *          of the group in which the value is stored, and the 32 right-most bits
 *          coding for the index at which the value is stored in that AVL tree.
 * @retval -1 if an error occurred.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
index_t obi_avl_group_add(OBIDMS_avl_group_p avl_group, Obi_blob_p value);


/**
 * @brief Recovers the name of an AVL group.
 *
 * @param avl_group A pointer on the AVL group structure.
 *
 * @returns A pointer on the name of the AVL group.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
const char* obi_avl_group_get_name(OBIDMS_avl_group_p avl_group);


#endif /* OBIAVL_H_ */

