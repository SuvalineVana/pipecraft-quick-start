/********************************************************************
 * OBIDMS header file                                               *
 ********************************************************************/

/**
 * @file obidmscolumn.h
 * @author Eric Coissac (eric.coissac@metabarcoding.org)
 * @date 23 May 2015
 * @brief Header file for the OBIDMS functions and structures.
 */


#ifndef OBIDMS_H_
#define OBIDMS_H_


#include <stdlib.h>
#include <sys/stat.h>
#include <errno.h>
#include <dirent.h>
#include <string.h>
#include <stdio.h>
#include <stdbool.h>

#include "obierrno.h"
#include "obitypes.h"


#define OBIDMS_MAX_NAME (247) 	    			/**< The maximum length of an OBIDMS name.
 	 	 	 	 	 	 	 	 	 	 	 	 */
#define INDEXER_DIR_NAME "OBIBLOB_INDEXERS"  	/**< The name of the Obiblob indexer directory.
                                	 	 	 	 */
#define VIEW_DIR_NAME "VIEWS"					/**< The name of the view directory.
												 */
#define TAXONOMY_DIR_NAME "TAXONOMY"    		/**< The name of the taxonomy directory.
                                	 	 	 	 */
#define MAX_NB_OPENED_COLUMNS (1000) 			/**< The maximum number of columns open at the same time.
                                	 	 	 	 */
#define MAX_NB_OPENED_DMS (1000) 			    /**< The maximum number of DMS open at the same time for a given program.
                                	 	 	 	 */
#define MAX_NB_OPENED_INDEXERS (1000) 			/**< The maximum number of indexers open at the same time.
                                	 	 	 	 */
#define MAX_PATH_LEN (1024)						/**< Maximum length for the character string defining a
 	 	 	 	 	 	 	 	 	 	 	 	 *	 file or directory path.
 	 	 	 	 	 	 	 	 	 	 	 	 */


struct OBIDMS_column;							/**< Declarations to avoid circular dependencies. */
typedef struct OBIDMS_column* OBIDMS_column_p;  /**< Declarations to avoid circular dependencies. */

/**
 * @brief Structure listing the columns opened in a DMS, identified by their name and version number.
 */
typedef struct Opened_columns_list {
	int	 		 			nb_opened_columns;	  				/**< Number of opened columns.
	 	   	   	   	   	   	   	   	   	   	   	   	   	   	   	 */
	OBIDMS_column_p		 	columns[MAX_NB_OPENED_COLUMNS+1]; 	/**< Array of pointers on the opened columns.
 	   	   	   	   	   	   	 	 	 	 	 	 	 	 	 	 */
} Opened_columns_list_t, *Opened_columns_list_p;


// TODO Need to find a way to not refer to AVLs specifically
struct OBIDMS_avl_group;								/**< Declarations to avoid circular dependencies. */
typedef struct OBIDMS_avl_group* OBIDMS_avl_group_p;	/**< Declarations to avoid circular dependencies. */
typedef OBIDMS_avl_group_p Obi_indexer_p;				/**< Declarations to avoid circular dependencies. */

/**
 * @brief Structure listing the indexers opened in a DMS, identified by their name.
 */
typedef struct Opened_indexers_list {
	int		 		 		nb_opened_indexers;					/**< Number of opened indexers.
	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 */
	Obi_indexer_p		    indexers[MAX_NB_OPENED_INDEXERS+1];	/**< Array of pointers on the opened indexers.
	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 */
} Opened_indexers_list_t, *Opened_indexers_list_p;


/**
 * @brief A structure stored in an information file and containing comments and additional informations on the DMS
 * including the command line history.
 *
 * A pointer on the comments is kept in the OBIDMS structure when a DMS is opened.
 */
typedef struct OBIDMS_infos {
	bool	                little_endian;                  	/** Whether the DMS is in little endian.
																 */
	size_t                  file_size;                          /** The size of the file in bytes.
																 */
	size_t			     	used_size;    						/**< Used size in bytes.
	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 */
	bool					working; 							/**< If the DMS is currently working (being used by a process).
	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 */
	char 			    	comments[];							/**< Comments, additional informations on the DMS including
																 *   the command line history.
 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 */
} OBIDMS_infos_t, *OBIDMS_infos_p;


/**
 * @brief A structure describing an OBIDMS instance
 *
 * A pointer to this structure is returned on creation
 * and opening of an OBITools Data Management System (DMS)
 */
typedef struct OBIDMS {
	char					dms_name[OBIDMS_MAX_NAME+1];		/** The name of the DMS.
																 */
	char					directory_path[MAX_PATH_LEN+1];   	/**< The absolute path of the directory
																 *   containing the DMS.
																 */
	DIR*					directory;							/**< A directory entry usable to
																 *   refer and scan the database directory.
																 */
	int     				dir_fd;								/**< The file descriptor of the directory entry
																 *   usable to refer and scan the database directory.
																 */
	DIR*					indexer_directory;					/**< A directory entry usable to
																 *   refer and scan the indexer directory.
																 */
	int						indexer_dir_fd;						/**< The file descriptor of the directory entry
																 *   usable to refer and scan the indexer directory.
																 */
	DIR*					view_directory;						/**< A directory entry usable to
																 *   refer and scan the view directory.
																 */
	int						view_dir_fd;						/**< The file descriptor of the directory entry
																 *   usable to refer and scan the view directory.
																 */
	DIR*					tax_directory;						/**< A directory entry usable to
																 *   refer and scan the taxonomy directory.
																 */
	int						tax_dir_fd;							/**< The file descriptor of the directory entry
																 *   usable to refer and scan the taxonomy directory.
																 */
	Opened_columns_list_p 	opened_columns;						/**< List of opened columns.
	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 */
	Opened_indexers_list_p 	opened_indexers;					/**< List of opened indexers.
	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 */
	OBIDMS_infos_p 			infos;							    /**< A pointer on the mapped DMS information file.
 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 */
} OBIDMS_t, *OBIDMS_p;


/**
 * @brief Global Array of DMS pointers listing all the DMS opened by a program.
 */
extern OBIDMS_p global_opened_dms_list[MAX_NB_OPENED_DMS+1];
extern int global_opened_dms_counter_list[MAX_NB_OPENED_DMS+1];


/**
 * @brief Checks if an OBIDMS contains unfinished views or columns.
 *
 * @param dms A pointer on the DMS.
 *
 * @returns An integer value indicating whether the DMS is clean or not.
 * @retval 1 if the DMS is clean.
 * @retval 0 if the DMS contains unfinished views or columns.
 * @retval -1 if an error occurred.
 *
 * @since September 2019
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_dms_is_clean(OBIDMS_p dms);


/**
 * @brief Cleans an OBIDMS that contains unfinished views or columns and tags it as not working
 *        (not being used by a process).
 *
 * @param dms_path A pointer to a C string containing the path to the DMS.
 *
 * @retval 0 on success.
 * @retval -1 if an error occurred.
 *
 * @since September 2019
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_clean_dms(const char* dms_path);


/**
 * @brief Checks if an OBIDMS exists.
 *
 * @param dms_path A pointer to a C string containing the path to the database.
 *
 * @returns An integer value indicating the status of the database.
 * @retval 1 if the database exists.
 * @retval 0 if the database does not exist.
 * @retval -1 if an error occurred.
 *
 * @since May 2015
 * @author Eric Coissac (eric.coissac@metabarcoding.org)
 */
int obi_dms_exists(const char* dms_path);


/**
 * @brief Creates a new OBITools Data Management instance (OBIDMS).
 *
 * A `DMS` is implemented as a directory. This function checks
 * if a directory with this name does not already exist
 * before creating the new database.
 *
 * A directory to store Obiblob indexers is also created.
 *
 * @param dms_path A pointer to a C string containing the path to the database.
 *                 The actual directory name used to store the DMS will be
 *                 `<dms_name>.obidms`.
 *
 * @returns A pointer to an OBIDMS structure describing the newly created DMS.
 * @retval NULL if an error occurred.
 *
 * @see obi_close_dms()
 * @since May 2015
 * @author Eric Coissac (eric.coissac@metabarcoding.org)
 */
OBIDMS_p obi_create_dms(const char* dms_name);


/**
 * @brief Opens an existing OBITools Data Management instance (OBIDMS).
 *
 * @param dms_path A pointer to a C string containing the path to the database.
 * @param cleaning A boolean indicating whether the DMS is being opened for cleaning unfinished views and columns.
 *
 * @returns A pointer to an OBIDMS structure describing the opened DMS.
 * @retval NULL if an error occurred.
 *
 * @see obi_close_dms()
 * @since May 2015
 * @author Eric Coissac (eric.coissac@metabarcoding.org)
 */
OBIDMS_p obi_open_dms(const char* dms_path, bool cleaning);


/**
 * @brief Opens an existing OBITools Data Management instance (OBIDMS).
 *
 * @warning No error is printed or saved if the DMS does not exist. For it to be the case, use obi_open_dms().
 *
 * @param dms_path A pointer to a C string containing the path to the database.
 *
 * @returns A pointer to an OBIDMS structure describing the opened DMS.
 * @retval NULL if the DMS does not exist or if an error occurred.
 *
 * @see obi_open_dms()
 * @see obi_close_dms()
 * @since May 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
OBIDMS_p obi_test_open_dms(const char* dms_name);


/**
 * @brief Creates or opens a new OBIDMS instance.
 *
 * If the database already exists, this function opens it, otherwise it
 * creates a new database.
 *
 * @param dms_path A pointer to a C string containing the path to the database.
 *
 * @returns A pointer to an OBIDMS structure describing the OBIDMS.
 * @retval NULL if an error occurred.
 *
 * @see obi_close_dms()
 * @since May 2015
 * @author Eric Coissac (eric.coissac@metabarcoding.org)
 */
OBIDMS_p obi_dms(const char* dms_path);


/**
 * @brief Closes an opened OBITools Data Management instance (OBIDMS).
 *
 * @param dms A pointer as returned by obi_create_dms() or obi_open_dms().
 * @param force Whether the DMS should be closed even if it is opened more than once.
 *
 * @returns An integer value indicating the success of the operation. Even on
 * 		    error, the `OBIDMS` structure is freed.
 * @retval 0 on success.
 * @retval -1 if an error occurred?-.
 *
 * @see obi_create_dms()
 * @see obi_open_dms()
 * @since May 2015
 * @author Eric Coissac (eric.coissac@metabarcoding.org)
 */
int obi_close_dms(OBIDMS_p dms, bool force);


/**
 * @brief Internal function writing new comments in a DMS informations file.
 *
 * The new comments replace the pre-existing ones.
 * The informations file is enlarged if necessary.
 *
 * @param dms A pointer on the DMS.
 * @param comments The new comments that should be written.
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since September 2018
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_dms_write_comments(OBIDMS_p dms, const char* comments);


/**
 * @brief Adds comments to a DMS informations file.
 *
 * This reads the comments in the JSON format and adds the key value pair.
 * If the key already exists, the value format is turned into an array and the new value is appended
 * if it is not already in the array.
 *
 * @param column A pointer on an OBIDMS column.
 * @param key The key.
 * @param value The value associated with the key.
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since September 2018
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_dms_add_comment(OBIDMS_p dms, const char* key, const char* value);


/**
 * @brief Returns a column identified by its name and its version number from the list of opened columns.
 *
 * @param dms The OBIDMS.
 * @param column_name The column name that should be looked for.
 * @param version The version number of the column that should be looked for.
 *
 * @returns A pointer on the column if it was found in the list of opened columns.
 * @retval NULL if the column was not found in the list of opened columns.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
OBIDMS_column_p obi_dms_get_column_from_list(OBIDMS_p dms, const char* column_name, obiversion_t version);


/**
 * @brief Adds a column identified by its name and its version number in the list of opened columns.
 *
 * @warning obi_dms_get_column_from_list() should be used first to check if the column isn't already listed.
 *
 * @param dms The OBIDMS.
 * @param column A pointer on the column that should be added in the list of opened columns.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
void obi_dms_list_column(OBIDMS_p dms, OBIDMS_column_p column);


/**
 * @brief Removes a column identified by its name and its version number from the list of opened columns.
 *
 * @param dms The OBIDMS.
 * @param column A pointer on the column that should be removed from the list of opened columns.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_dms_unlist_column(OBIDMS_p dms, OBIDMS_column_p column);


/**
 * @brief Returns an indexer identified by its name from the list of opened indexers.
 *
 * @param dms The OBIDMS.
 * @param indexer_name The indexer name that should be looked for.
 *
 * @returns A pointer on the indexer if it was found in the list of opened indexers.
 * @retval NULL if the indexer was not found in the list of opened indexers.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
Obi_indexer_p obi_dms_get_indexer_from_list(OBIDMS_p dms, const char* indexer_name);


/**
 * @brief Adds an indexer identified by its name in the list of opened indexers.
 *
 * @warning obi_dms_get_indexer_from_list() should be used first to check if the indexer isn't already listed.
 *
 * @param dms The OBIDMS.
 * @param indexer A pointer on the indexer that should be added in the list of opened indexers.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
void obi_dms_list_indexer(OBIDMS_p dms, Obi_indexer_p indexer);


/**
 * @brief Removes an indexer identified by its name from the list of opened indexers.
 *
 * @param dms The OBIDMS.
 * @param column A pointer on the indexer that should be removed from the list of opened indexers.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_dms_unlist_indexer(OBIDMS_p dms, Obi_indexer_p indexer);


/**
 * @brief Gets the full path to the DMS.
 *
 * @warning The returned pointer has to be freed by the caller.
 *
 * @param dms The DMS.
 *
 * @returns A pointer to the full path.
 * @retval NULL if an error occurred.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
char* obi_dms_get_dms_path(OBIDMS_p dms);


/**
 * @brief Gets the full path of a file or a directory from its
 *        path relative to the DMS.
 *
 * @warning The returned pointer has to be freed by the caller.
 *
 * @param dms The DMS to which path_name is relative.
 * @param path_name The path name for the file or directory, relative to the DMS.
 *
 * @returns A pointer to the full path.
 * @retval NULL if an error occurred.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
char* obi_dms_get_full_path(OBIDMS_p dms, const char* path_name);


/**
 * @brief Opens a directory relative to the DMS.
 *
 * @param dms The DMS to which path_name is relative.
 * @param path_name The path name for the directory to be opened, relative to the DMS.
 *
 * @returns The directory stream of the opened directory.
 * @retval NULL if an error occurred.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
DIR* opendir_in_dms(OBIDMS_p dms, const char* path_name);


/**
 * @brief Imports a column, copying it from a DMS to another DMS, and returns the version of the column in the destination DMS.
 *
 * The eventual associated indexers are imported too. If an indexer with the same name already exists in the destination DMS,
 * they are not merged, the imported indexer is renamed.
 *
 * @warning The eventual associated column is not imported and needs to be imported separately.
 *
 * @param dms_path_1 The path to the source DMS (without the '.obidms' extension).
 * @param dms_path_2 The path to the destination DMS (without the '.obidms' extension). It is created if it doesn't already exist.
 * @param column_name The name of the column to import.
 * @param version_number The version of the column to import.
 *
 * @returns The new version of the column in the destination DMS.
 * @retval -1 if an error occurred.
 *
 * @since August 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
obiversion_t obi_import_column(const char* dms_path_1, const char* dms_path_2, const char* column_name, obiversion_t version_number);


/**
 * @brief Imports a view, copying it and all its associated columns from a DMS to another DMS.
 *
 * All the columns and the eventual associated indexers are imported. If an indexer with the same name already exists in the destination DMS,
 * they are not merged, the imported indexer is renamed.
 *
 * @param dms_path_1 The path to the source DMS (without the '.obidms' extension).
 * @param dms_path_2 The path to the destination DMS (without the '.obidms' extension). It is created if it doesn't already exist.
 * @param view_name_1 The name of the view to import.
 * @param view_name_2 The name of the imported view in the destination DMS.
 *
 * @retval 0 on success.
 * @retval -1 if an error occurred.
 *
 * @since August 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_import_view(const char* dms_path_1, const char* dms_path_2, const char* view_name_1, const char* view_name_2);


/**
 * @brief Closes all DMS in the global list of opened DMS.
 *        To be executed 'at exit' of programs.
 *
 * @since October 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
void obi_close_atexit(void);


#endif /* OBIDMS_H_ */
