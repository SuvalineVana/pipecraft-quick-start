/****************************************************************************
 * OBIDMS columns header file                                               *
 ****************************************************************************/

/**
 * @file obidmscolumn.h
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 * @date 12 May 2015
 * @brief Header file for the functions and structures shared by all the OBIDMS columns.
 */


#ifndef OBIDMSCOLUMN_H_
#define OBIDMSCOLUMN_H_

#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>
#include <stdbool.h>
#include <time.h>
#include <stdbool.h>

#include "obidms.h"
#include "obitypes.h"
#include "obierrno.h"
#include "obilittlebigman.h"
#include "obidmscolumndir.h"
#include "obiblob_indexer.h"


// TODO delete useless ones, add default nb?
#define ELEMENTS_NAMES_MAX (1000000)     	  	/**< The maximum length of the list of elements names.	// TODO Discuss
                                	       	   	 */
#define NB_ELTS_MAX_IF_DEFAULT_NAME (1000000) 	/**< The maximum number of elements per line if the default element names
										   	   	 *   are used ("0\01\02\0...\0n"), considering ELEMENTS_NAMES_MAX.  // TODO not up to date
										   	   	 */
#define COLUMN_GROWTH_FACTOR (2)	 	  		/**< The growth factor when a column is enlarged.
                                	   	   	   	 */
#define MAXIMUM_LINE_COUNT (1000000000)   		/**< The maximum line count for the data of a column (1E9). //TODO
                                	       	   	 */
#define COMMENTS_MAX_LENGTH (4096)        		/**< The maximum length for comments.
 	 	 	 	 	 	 	 	 	       	   	 */
#define FORMATTED_ELT_NAMES_SEPARATOR '\0'		/**< The separator between elements names once formatted to be stored in columns.
 	 	 	 	 	 	 	 	 	       	   	 */
#define NOT_FORMATTED_ELT_NAMES_SEPARATOR ';'   /**< The separator between elements names before being formatted to be stored in columns (e.g. as sent by the upper layer).
 	 	 	 	 	 	 	 	 	 	 	 	 */


/**
 * @brief Structure referencing a column by its name and its version.
 */
typedef struct Column_reference {
	char 	   	 column_name[OBIDMS_COLUMN_MAX_NAME+1];    /**< Name of the column.
	 	 	 	 	 	 	 	 	 	 	 	 	 	    */
	obiversion_t version;				   		    	   /**< Version of the column.
	 	 	 	 	 	 	 	 	 	 	 	 	 	    */
} Column_reference_t, *Column_reference_p;


/**
 * @brief OBIDMS column header structure.
 */
typedef struct OBIDMS_column_header {
	size_t				header_size;		   				    			/**< Size of the header in bytes.
	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 */
	size_t				data_size;			   				    			/**< Size of the data in bytes.
	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 */
	index_t				line_count;							    			/**< Number of lines of data allocated.
	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 */
	index_t				lines_used;							    			/**< Number of lines of data used (the highest index where data has been entered + 1).
	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 */
	index_t				nb_elements_per_line;   			   				/**< Number of elements per line.
	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 */
	OBIType_t			returned_data_type;		    						/**< Type of the data that is returned when getting an
															 	 	 	 	 *   element from the column.
															 	 	 	 	 */
	OBIType_t			stored_data_type;		    						/**< Type of the data that is actually stored in the data
															 	 	 	 	 *   part of the column.
															 	 	 	 	 */
	bool				tuples;												/**< A boolean indicating whether the column contains indices referring to indexed tuples.
																			 */
	bool				to_eval;											/**< A boolean indicating whether the column contains expressions that should be evaluated
																			 *   (typically OBI_STR columns containing character strings to be evaluated by Python).
																			 */
	time_t				creation_date;			    						/**< Date of creation of the file.
	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 */
	obiversion_t		version;				   							/**< Version of the column.
	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 */
	obiversion_t		cloned_from;			    						/**< Version of the column from which this column
															 	 	 	 	 *   was cloned from (-1 if it was not created by cloning
															 	 	 	 	 *   another column).
															 	 	 	 	 */
	char            	name[OBIDMS_COLUMN_MAX_NAME+1]; 	    			/**< The column name as a NULL terminated string.
	                                             	 	 	 	 	 	 	 */
	char            	indexer_name[INDEXER_MAX_NAME+1]; 					/**< If there is one, the indexer name as a NULL terminated string.
	                                             	 	 	 	 	 	 	 */
	Column_reference_t 	associated_column;									/**< If there is one, the reference to the associated column.
	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 */
	bool                finished;											/**< A boolean indicating whether the column was properly closed by the view that created it.
																			 */
	char 				comments[COMMENTS_MAX_LENGTH+1];					/**< Comments stored as a classical zero end C string.
												 	 	 	 	 	 	 	 */
	int64_t				elements_names_length;								/**< Length of the character array where the elements names are stored.
																			 */
	char*				elements_names;										/**< Pointer in mem_arnea on the names of the line elements with '\0' as separator
																 	 	 	 *   and '\0\0' as terminal flag.
																 	 	 	 *	 (default are the indices: "0\01\02\0...\0n\0\0").
																 	 	 	 */
	int64_t* 		    elements_names_idx;									/**< Pointer in mem_arena on the index for the start of each element name in elements_names.
																			 */
	int64_t*			sorted_elements_idx;								/**< Index for the sorted element names in elements_names_idx.
																			 */
	byte_t              mem_arena[];										/**< Memory array where the elements names, the elements names index and the sorted elements index are stored.
	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 */
} OBIDMS_column_header_t, *OBIDMS_column_header_p;


/**
 * @brief OBIDMS column structure.
 *
 * A data structure of this type is returned by the functions
 * creating, opening or cloning an OBIDMS column.
 */
typedef struct OBIDMS_column {
	OBIDMS_p                	dms;			 	/**< A pointer to the OBIDMS structure to
	                                                 *   which the column belongs.
	 	 	 	 	 	 	 	 	 	 	 	 	 */
	OBIDMS_column_directory_p   column_directory;	/**< A pointer to the OBIDMS column directory
	                                                 *   structure to which the column belongs.
	 	 	 	 	 	 	 	 	 	 	 	 	 */
	OBIDMS_column_header_p		header; 		 	/**< A pointer to the header of the column.
	 	 	 	 	 	 	 	 	 	 	 	 	 */
	Obi_indexer_p    			indexer;		    /**< A pointer to the blob indexer associated
	                                                 *   with the column if there is one.
	 	 	 	 	 	 	 	 	 	 	 	 	 */
	void*                   	data;   		 	/**< A `void` pointer to the beginning of the data.
	                                 	 	         *
													 *   @warning Never use this member directly outside
													 *            of the code of the low level functions
													 *            of the OBIDMS.
													 */
	bool						writable;	     	/**< Indicates if the column is writable or not.
													 *       - `true` the column is writable
													 *       - `false` the column is read-only
													 *
													 * A column is writable only by its creator
													 * until it closes it.
													 */
	size_t						counter;			/**< Indicates by how many threads/programs
	                                                 *   (TODO) the column is used.
													 */
} OBIDMS_column_t, *OBIDMS_column_p;



/**
 * @brief Function building the full path to the version file of a column in an OBIDMS.
 *
 * @warning The returned pointer has to be freed by the caller.
 *
 * @param dms A pointer on the OBIDMS.
 * @param column_name The name of the OBIDMS column file.
 *
 * @returns A pointer to the version file name.
 * @retval NULL if an error occurred.
 *
 * @since October 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
char* obi_version_file_full_path(OBIDMS_p dms, const char* column_name);


/**
 * @brief Function building the full path to the version file of a column in an OBIDMS.
 *
 * @warning The returned pointer has to be freed by the caller.
 *
 * @param dms A pointer on the OBIDMS.
 * @param column_name The name of the OBIDMS column file.
 * @param version_number The version number of the OBIDMS column file.
 *
 * @returns A pointer to the version file name.
 * @retval NULL if an error occurred.
 *
 * @since October 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
char* obi_column_full_path(OBIDMS_p dms, const char* column_name, obiversion_t version_number);


/**
 * @brief Returns the latest version number of a column in a column directory using the column directory structure.
 *
 * @param column_directory A pointer as returned by obi_create_column_directory() or obi_open_column_directory().
 *
 * @returns The latest version number kept in the version file.
 * @retval -1 if an error occurred.
 *
 * @since May 2015
 * @author Eric Coissac (eric.coissac@metabarcoding.org)
 */
obiversion_t obi_get_latest_version_number(OBIDMS_column_directory_p column_directory);


/**
 * @brief Returns the latest version of a column in a column directory using the column name.
 *
 * @param dms A pointer on an OBIDMS.
 * @param column_name The column name.
 *
 * @returns The latest version number kept in the version file.
 * @retval -1 if an error occurred.
 *
 * @since May 2015
 * @author Eric Coissac (eric.coissac@metabarcoding.org)
 */
obiversion_t obi_column_get_latest_version_from_name(OBIDMS_p dms, const char* column_name);


/**
 * @brief Returns the header size in bytes of a column.
 *
 * The header size is rounded to a multiple of the memory page size.
 *
 * @param nb_elements_per_line The number of elements per line.
 * @param elts_names_length The length of elements_names including the two terminal '\0's.
 *
 * @returns The header size in bytes.
 *
 * @since May 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
size_t obi_calculate_header_size(index_t nb_elements_per_line, int64_t elts_names_length);


/**
 * @brief Creates a column.
 *
 * The minimum data size allocated is one memory page, and the data is initialized to the NA value of the OBIType.
 * If there is an indexer associated with the column, it is opened or created if it does not already exist.
 *
 * @warning If there is one element per line, elements_names should be equal to column_name.	// TODO change this condition?
 *
 * @param dms A pointer on an OBIDMS.
 * @param column_name The name of the new column.
 * @param data_type The OBIType code of the data.
 * @param nb_lines The number of lines to be stored (can be 0 if not known).
 * @param nb_elements_per_line The number of elements per line.
 * @param elements_names The names of the elements with ';' as separator (no terminal ';'),
 *                       NULL or "" if the default names are to be used ("0\01\02\0...\0n").
 * @param elt_names_formatted Whether the separator for the elements names is ';' (false), or '\0' (true, as formatted by format_elements_names()).
 * @param tuples A boolean indicating whether the column should contain indices referring to indexed tuples.
 * @param to_eval A boolean indicating whether the column contains expressions that should be evaluated
 *                (typically OBI_STR columns containing character strings to be evaluated by Python).
 * @param indexer_name The name of the indexer if there is one associated with the column.
 *                     If NULL or "", the indexer name is set as the column name.
 * @param associated_column_name The name of the associated column if there is one (otherwise NULL or "").
 * @param associated_column_version The version of the associated column if there is one (otherwise -1).
 * @param comments Optional comments associated with the column in JSON format (NULL, "" or "{}" if no comments associated).
 *
 * @returns A pointer on the newly created column structure.
 * @retval NULL if an error occurred.
 *
 * @since May 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
OBIDMS_column_p obi_create_column(OBIDMS_p     dms,
		                          const char*  column_name,
								  OBIType_t    data_type,
								  index_t      nb_lines,
								  index_t      nb_elements_per_line,
								  char*        elements_names,
								  bool		   elt_names_formatted,
								  bool         tuples,
								  bool         to_eval,
								  const char*  indexer_name,
								  const char*  associated_column_name,
								  obiversion_t associated_column_version,
								  const char*  comments
								 );


/**
 * @brief Opens a column in read-only mode.
 *
 * @param dms A pointer on an OBIDMS.
 * @param column_name The name of the column.
 * @param version_number The version of the column that should be opened (if -1, the latest version is retrieved).
 *
 * @returns A pointer on the opened column structure.
 * @retval NULL if an error occurred.
 *
 * @since July 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
OBIDMS_column_p obi_open_column(OBIDMS_p dms, const char* column_name, obiversion_t version_number);


/**
 * @brief Clones a column, and returns a pointer to the writable new column.
 *
 * @param dms A pointer on an OBIDMS.
 * @param column_name The name of the column to clone.
 * @param version_number The version of the column that should be cloned (if -1, the latest version is retrieved).
 * @param clone_data Whether the data should be copied or not.
 *
 * @returns A pointer to the created column.
 * @retval NULL if an error occurred.
 *
 * @since August 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
OBIDMS_column_p obi_clone_column(OBIDMS_p dms, OBIDMS_column_p line_selection, const char* column_name, obiversion_t version_number, bool clone_data);


/**
 * @brief Clones a column indexer to have it writable.
 *
 * @param column A pointer on an OBIDMS column.
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since November 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_clone_column_indexer(OBIDMS_column_p column);


/**
 * @brief Truncates a column to the number of lines used if it is not read-only and closes it.
 *
 * @warning This function does not flag the column as finished, only finish_view() in the obiview source file does that.
 *
 * @param column A pointer on an OBIDMS column.
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since July 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_close_column(OBIDMS_column_p column);


/**
 * @brief Truncates a column file to the number of lines used rounded to the nearest
 * 		  greater multiple of the page size.
 *
 * @param column A pointer on an OBIDMS column.
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since August 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_truncate_column(OBIDMS_column_p column);


/**
 * @brief Enlarges a column file.
 *
 * @param column A pointer on an OBIDMS column.
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since August 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_enlarge_column(OBIDMS_column_p column);


/**
 * @brief Writes comments to a column file.
 *
 * @warning This overwrites any other previous comments.
 *
 * @param column A pointer on an OBIDMS column.
 * @param comments A character string containing the comments.
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since August 2018
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_column_write_comments(OBIDMS_column_p column, const char* comments);


/**
 * @brief Adds comments to a column file.
 *
 * This reads the comments in the JSON format and adds the key value pair.
 * If the key already exists, the value format is turned to array and the new value is appended
 * if it is not already in the array.
 *
 * @param column A pointer on an OBIDMS column.
 * @param key The key.
 * @param value The value associated with the key.
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since August 2018
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_column_add_comment(OBIDMS_column_p column, const char* key, const char* value);


/*
 * @brief Sets the data in a column to the specified value.
 *
 * @warning The specified value should be the atomic value effectively stored in the column (i.e. it can not be a character string for example).
 *
 * @param column A pointer on an OBIDMS column.
 * @param start The first line number of the block that should be set.
 * @param nb_lines The number of lines that should be set.
 * @param value_p A pointer on the value to which the column should be set.
 *
 * @since May 2018
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
void obi_set_column_to_value(OBIDMS_column_p column,
						  	 index_t first_line_nb,
							 index_t nb_lines,
							 void* value_p);


/*
 * @brief Sets the data in a column to the NA value of the data OBIType.
 *
 * @param column A pointer on an OBIDMS column.
 * @param start The first line number of the block that should be set.
 * @param nb_lines The number of lines that should be set.
 *
 * @since August 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
void obi_ini_to_NA_values(OBIDMS_column_p column, index_t first_line_nb, index_t nb_lines);	// TODO make private?


/**
 * @brief Recovers the header of an OBIDMS column from the column name.
 *
 * @warning The header structure has to be munmapped by the caller.
 *
 * @param dms A pointer on an OBIDMS.
 * @param column_name The name of an OBIDMS column.
 * @param version_number The version of the column from which the header should be
 *        retrieved (-1: latest version).
 *
 * @returns A pointer on the mmapped header of the column.
 * @retval NULL if an error occurred.
 *
 * @since October 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
OBIDMS_column_header_p obi_column_get_header_from_name(OBIDMS_p dms, const char* column_name, obiversion_t version_number);


/**
 * @brief Munmap a mmapped header as returned by obi_column_get_header_from_name().
 *
 * @param header A pointer on the mmapped header structure.
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since October 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_close_header(OBIDMS_column_header_p header);


/**
 * @brief Recovers the index of an element in an OBIDMS column from the element's name.
 *
 * @param column A pointer on an OBIDMS column.
 * @param element_name The name of the element.
 *
 * @returns The index of the element in a line of the column.
 * @retval OBIIdx_NA if an error occurred.
 *
 * @since July 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
index_t obi_column_get_element_index_from_name(OBIDMS_column_p column, const char* element_name);


/**
 * @brief Recovers the elements names of the lines of a column, with ';' as separator (i.e. "0;1;2;...;n\0").
 *
 * @warning The returned pointer has to be freed by the caller.
 *
 * @param column A pointer on an OBIDMS column.
 *
 * @returns A pointer on a character array where the elements names are stored.
 * @retval NULL if an error occurred.
 *
 * @since January 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
char* obi_get_elements_names(OBIDMS_column_p column);


/**
 * @brief Prepares a column to set a value.
 *
 * @param column A pointer on an OBIDMS column.
 * @param line_nb The number of the line at which the value will be set.
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_column_prepare_to_set_value(OBIDMS_column_p column, index_t line_nb, index_t elt_idx);


/**
 * @brief Prepares a column to recover a value.
 *
 * @param column A pointer on an OBIDMS column.
 * @param line_nb The number of the line at which the value will be recovered.
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_column_prepare_to_get_value(OBIDMS_column_p column, index_t line_nb);


/**
 * @brief Goes through all the column files of a DMS and checks for views that have
 *        not been flagged as finished (done by the finish_view() function in the
 *        obiview source file).
 *
 * @param dms A pointer on an OBIDMS.
 *
 * @returns A boolean indicating whether unfinished views were found.
 *
 * @since September 2019
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_dms_has_unfinished_columns(OBIDMS_p dms);


/**
 * @brief Goes through all the column files of a DMS and deletes columns that have
 *        not been flagged as finished (done by the finish_view() function in the
 *        obiview source file).
 *
 * @param dms A pointer on an OBIDMS.
 *
 * @returns A value indicating the success of the operation.
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since October 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_clean_unfinished_columns(OBIDMS_p dms);


#endif /* OBIDMSCOLUMN_H_ */
