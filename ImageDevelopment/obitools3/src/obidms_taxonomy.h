/********************************************************************
 * OBIDMS taxonomy header file                                      *
 ********************************************************************/

/**
 * @file obidms_taxonomy.h
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 * @date March 2nd 2016
 * @brief Header file for the functions handling the reading and writing of taxonomy files.
 */


#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>

#include "obidms.h"


#define MIN_LOCAL_TAXID (10000000)     	  /**< The minimum taxid for a taxon added locally (i.e. not an NCBI taxon).
                                	       */
#define TAX_NAME_LEN (1024)				  /**< The maximum length for the taxonomy name.
                                	       */


/**
 * @brief Structure for a taxon as stored in a .tdx file.
 */
typedef struct {
	int32_t  taxid;        /**< Taxid.
	 	 	    		    */
	int32_t  rank;         /**< Rank index.
	    				    */
	int32_t	 parent;       /**< Index, in the taxid index, of the parent node in the taxonomic tree.
	    					*/
	int32_t  name_length;  /**< Length of the taxon scientific name.
							*/
	char     name[];	   /**< Scientific name of the taxon.
							*/
} ecotxformat_t;


/**
 * @brief Structure for a taxon as stored in a taxonomy structure.
 */
typedef struct ecotxnode {
	int32_t           taxid;		 	/**< Taxid.		// TODO discuss that this is will be the current taxid even if the struct was accessed through a deprecated one
	    								 */
	int32_t           rank;		        /**< Rank index in ecorankidx_t structure.
	 	 	 	 	 	 	 	 	 	 */
	int32_t  		  farest;		    /**< Longest branch length, used to compute distances between taxa faster.
	 	 	 	 	 	 	 	 	 	 */
	int32_t			  idx;			    /**< Index in the ecotxidx_t structure.
	 	 	 	 	 	 	 	 	 	 */
	struct ecotxnode* parent;			/**< Pointer on the parent node in the taxonomic tree.
	 	 	 	 	 	 	 	 	 	 */
	char*			  name;		   		/**< Scientific name of the taxon.
										 */
	char*			  preferred_name;	/**< Preferred name of the taxon if there is one, otherwise NULL.
										 */
	bool			  local;			/**< A boolean indicating whether the taxon is local or not.
	 	 	 	 	 	 	 	 	 	 */
} ecotx_t;


/**
 * @brief Structure for the taxon index in a taxonomy structure.
 */
typedef struct {
	int32_t count;			/**< Number of taxa.
	 	 	 	 	 	 	 */
	int32_t ncbi_count;		/**< Number of NCBI taxa.
	 	 	 	 	 	 	 */
	int32_t local_count;	/**< Number of taxa added locally.
 	 	 	 	 	 	 	 */
	int32_t max_taxid;		/**< Maximum taxid existing in the taxon index.
	 	 	 	 	 	 	 */
	int32_t buffer_size;	/**< Number of taxa.	// TODO kept this but not sure of its use
 	 	 	 	 	 	 	 */
	ecotx_t taxon[];		/**< Taxon array.
 	 	 	 	 	 	 	 */
} ecotxidx_t;


/**
 * @brief Structure for the rank index in a taxonomy structure.
 */
typedef struct {
	int32_t count;		/**< Number of ranks.
 	 	 	 	 	 	 */
	char*   label[];	/**< Array of rank names.
	 	 	 	 	 	 */
} ecorankidx_t;


/**
 * @brief Structure for a taxon name as stored in a .ndx file.
 */
typedef struct {
 	int32_t  is_scientific_name;	/**< A boolean indicating whether the name is a scientific name or not.
	 	 	 	 	 	 	 	 	 */
	int32_t  name_length;			/**< The name length.
	 	 	 	 	 	 	 	 	 */
	int32_t  class_length;			/**< The name class length.
	 	 	 	 	 	 	 	 	 */
	int32_t  taxid;       			/**< Index of the taxon in the taxid index.
									 */
	char     names[];       		/**< Taxon name and name class concatenated.
	 	 	 	 	 	 	 	 	 */
} econameformat_t;


/**
 * @brief Structure for a taxon name as stored in a taxonomy structure.
 */
typedef struct {
	char*   		  name;					/**< Taxon name.
	 	 	 	 	 	 	 	 	 	 	 */
	char*   		  class_name;			/**< Name class.
	 	 	 	 	 	 	 	 	 	 	 */
	int32_t 		  is_scientific_name;	/**< A boolean indicating whether the name is a scientific name or not.
	 	 	 	 	 	 	 	 	 	 	 */
	struct ecotxnode* taxon;				/**< Pointer on the taxon in the taxon index.
	 	 	 	 	 	 	 	 	 	 	 */
} econame_t;


/**
 * @brief Structure for the name index in a taxonomy structure.
 */
typedef struct {
	int32_t   count;		/**< Number of names.
	 	 	 	 	 	 	 */
	econame_t names[];		/**< Array of names.
	 	 	 	 	 	 	 */
} econameidx_t;


/**
 * @brief Structure for a taxid/index pair as stored in a taxonomy structure.
 */
typedef struct {
	int32_t taxid;		/**< Taxid.
	 	 	 	 	 	 */
	int32_t idx;		/**< Index of the taxid in the taxon index, -1 if the taxid is deprecated.
	 	 	 	 	 	 */
} ecomerged_t;


/**
 * @brief Structure for a merged taxid index in a taxonomy structure.
 *
 * This index includes all deprecated taxids that now refer to different taxids, and
 * the deprecated taxids that are deleted.
 *
 */
typedef struct {
	int32_t     count;		/**< Number of taxid/index pairs.
 	 	 	 	 	 	 	 */
	ecomerged_t merged[];	/**< Array of taxid/index pairs.
	 	 	 	 	 	 	 */
} ecomergedidx_t;


/**
 * @brief Structure for a taxonomy.
 */
typedef struct OBIDMS_taxonomy_t {
	char            tax_name[TAX_NAME_LEN];		/**< Taxonomy name.
	 	 	 	 	 	 	 	 	 	 	 	 */
	OBIDMS_p        dms;						/**< A pointer on the DMS to which the taxonomy belongs.
 	 	 	 	 	 	 	 	 	 	 	 	 */
	ecomergedidx_t* merged_idx;					/**< Merged taxid index.
	 	 	 	 	 	 	 	 	 	 	 	 */
	ecorankidx_t*   ranks;						/**< Taxonomic ranks.
	 	 	 	 	 	 	 	 	 	 	 	 */
	econameidx_t*   names;						/**< Taxon names.
 	 	 	 	 	 	 	 	 	 	 	 	 */
	econameidx_t*   preferred_names;			/**< Taxon preferred names (i.e. added locally).
	 	 	 	 	 	 	 	 	 	 	 	 */
	ecotxidx_t*     taxa;						/**< Taxa.
	 	 	 	 	 	 	 	 	 	 	 	 */
} OBIDMS_taxonomy_t, *OBIDMS_taxonomy_p;



/**
 * @brief Function checking whether a taxonomy is already registered in a DMS using its name.
 *
 * @param dms The path to the taxdump directory.
 *
 * @param dms A pointer on the DMS.
 * @param taxonomy_name The name (prefix) of the taxonomy.
 *
 * @retval 1 if the taxonomy exists.
 * @retval 0 if the taxonomy does not exist
 * @retval -1 if an error occurred.
 *
 * @since June 2018
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_taxonomy_exists(OBIDMS_p dms, const char* taxonomy_name);


/**
 * @brief Function reading an NCBI taxdump and loading its information into a taxonomy structure.
 *
 * @param taxdump The path to the taxdump directory.
 *
 * @returns A pointer on the read taxonomy structure.
 * @retval NULL if an error occurred.
 *
 * @since 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
OBIDMS_taxonomy_p obi_read_taxdump(const char* taxdump);


/**
 * @brief Function reading a binary taxonomy database (i.e. a set of .tdx, .ndx, .rdx, .adx, .ldx, .pdx files)
 * 		  and loading its information into a taxonomy structure.
 *
 * @param dms A pointer on the DMS to which the taxonomy belongs.
 * @param taxonomy_name The name (prefix) of the taxonomy.
 * @param read_alternative_names A boolean indicating whether names other than scientific and preferred names should be read.
 *
 * @returns A pointer on the read taxonomy structure.
 * @retval NULL if an error occurred.
 *
 * @since 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
OBIDMS_taxonomy_p obi_read_taxonomy(OBIDMS_p dms, const char* taxonomy_name, bool read_alternative_names);


/**
 * @brief Function writing a binary taxonomy database (i.e. a set of .tdx, .ndx, .rdx, .adx, .ldx, .pdx files).
 *
 * @param dms A pointer on the DMS to which the taxonomy belongs.
 * @param tax A pointer on the taxonomy structure.
 * @param tax_name The name (prefix) of the taxonomy.
 *
 * @returns An integer value indicating the success of the operation.
 * @retval 0 on success.
 * @retval -1 if an error occurred.
 *
 * @since 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_write_taxonomy(OBIDMS_p dms, OBIDMS_taxonomy_p tax, const char* tax_name);


/**
 * @brief Function closing a taxonomy structure.
 *
 * This function writes all changes to the binary files (local taxa and preferred names) and free all allocated memory for the structure.
 *
 * @param taxonomy A pointer on the taxonomy structure.
 *
 * @returns An integer value indicating the success of the operation.
 * @retval 0 on success.
 * @retval -1 if an error occurred.
 *
 * @since 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_close_taxonomy(OBIDMS_taxonomy_p taxonomy);


/**
 * @brief Function adding a local taxon to a taxonomy.
 *
 * @param tax A pointer on the taxonomy structure.
 * @param name The taxon scientific name.
 * @param rank_name The taxon rank name.
 * @param parent_taxid The taxid of the parent node in the taxonomic tree.
 * @param min_taxid The minimum taxid to give to the new taxon (the function will choose a new taxid >= min_taxid and >= MIN_LOCAL_TAXID).
 *
 * @returns An integer value indicating the success of the operation.
 * @retval 0 on success.
 * @retval -1 if an error occurred.
 *
 * @since 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_taxo_add_local_taxon(OBIDMS_taxonomy_p tax, const char* name, const char* rank_name, int32_t parent_taxid, int32_t min_taxid);


/**
 * @brief Function adding a preferred name to a taxon in a taxonomy, referred to by its taxid.
 *
 * @param tax A pointer on the taxonomy structure.
 * @param taxid The taxid of the taxon that should have a new preferred name.
 * @param preferred_name The new preferred name.
 *
 * @returns An integer value indicating the success of the operation.
 * @retval 0 on success.
 * @retval -1 if an error occurred.
 *
 * @since January 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_taxo_add_preferred_name_with_taxid(OBIDMS_taxonomy_p tax, int32_t taxid, const char* preferred_name);


/**
 * @brief Function adding a preferred name to a taxon in a taxonomy, referred to by the taxon pointer.
 *
 * @param tax A pointer on the taxonomy structure.
 * @param taxon A pointer on the taxon that should have a new preferred name.
 * @param preferred_name The new preferred name.
 *
 * @returns An integer value indicating the success of the operation.
 * @retval 0 on success.
 * @retval -1 if an error occurred.
 *
 * @since January 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int obi_taxo_add_preferred_name_with_taxon(OBIDMS_taxonomy_p tax, ecotx_t* taxon, const char* preferred_name);


/**
 * @brief Function returning the last common ancestor of two taxa.
 *
 * @param taxon1 A pointer on the first taxon.
 * @param taxon2 A pointer on the second taxon.
 *
 * @returns A pointer on the last common ancestor of the two taxa.
 * @retval NULL if an error occurred.
 */
ecotx_t* obi_taxo_get_lca(ecotx_t* taxon1, ecotx_t* taxon2);


/**
 * @brief Function returning the parent of a taxon at a given rank.
 *
 * @param taxon A pointer on the taxon.
 * @param rankidx The index of the rank wanted.
 *
 * @returns A pointer on the parent taxon at the wanted rank.
 * @retval NULL if no parent taxon was found at the wanted rank or if an error occurred.
 */
ecotx_t* obi_taxo_get_parent_at_rank(ecotx_t* taxon, int32_t rankidx);


/**
 * @brief Function returning a taxon given its taxid.
 *
 * @param taxonomy A pointer on the taxonomy.
 * @param taxid The taxid of the taxon.
 *
 * @returns A pointer on the wanted taxon.
 * @retval NULL if no taxon was found with the given taxid or if an error occurred.
 *
 * @since January 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
ecotx_t* obi_taxo_get_taxon_with_taxid(OBIDMS_taxonomy_p taxonomy, int32_t taxid);


/**
 * @brief Function checking whether a taxon is under another in the taxonomy tree.
 *
 * @param taxon A pointer on the first taxon.
 * @param other_taxid The taxid of the second taxon.
 *
 * @returns A value indicating whether the first taxon is under the second taxon in the taxonomy tree.
 * @retval 0 if the first taxon is not under the second taxon in the taxonomy tree.
 * @retval 1 if the first taxon is under the second taxon in the taxonomy tree.
 * @retval -1 if an error occurred.
 */
int obi_taxo_is_taxon_under_taxid(ecotx_t* taxon, int32_t other_taxid);


/**
 * @brief Function returning the parent of a taxon at the species level.
 *
 * @param taxon A pointer on the taxon.
 * @param taxonomy A pointer on the taxonomy structure.
 *
 * @returns A pointer on the parent taxon at the species level.
 * @retval NULL if no parent taxon was found at the wanted rank.
 */
ecotx_t* obi_taxo_get_species(ecotx_t* taxon, OBIDMS_taxonomy_p taxonomy);


/**
 * @brief Function returning the parent of a taxon at the genus level.
 *
 * @param taxon A pointer on the taxon.
 * @param taxonomy A pointer on the taxonomy structure.
 *
 * @returns A pointer on the parent taxon at the genus level.
 * @retval NULL if no parent taxon was found at the wanted rank.
 */
ecotx_t* obi_taxo_get_genus(ecotx_t* taxon, OBIDMS_taxonomy_p taxonomy);


/**
 * @brief Function returning the parent of a taxon at the family level.
 *
 * @param taxon A pointer on the taxon.
 * @param taxonomy A pointer on the taxonomy structure.
 *
 * @returns A pointer on the parent taxon at the family level.
 * @retval NULL if no parent taxon was found at the wanted rank.
 */
ecotx_t* obi_taxo_get_family(ecotx_t* taxon, OBIDMS_taxonomy_p taxonomy);


/**
 * @brief Function returning the parent of a taxon at the kingdom level.
 *
 * @param taxon A pointer on the taxon.
 * @param taxonomy A pointer on the taxonomy structure.
 *
 * @returns A pointer on the parent taxon at the kingdom level.
 * @retval NULL if no parent taxon was found at the wanted rank.
 */
ecotx_t* obi_taxo_get_kingdom(ecotx_t* taxon, OBIDMS_taxonomy_p taxonomy);


/**
 * @brief Function returning the parent of a taxon at the superkingdom level.
 *
 * @param taxon A pointer on the taxon.
 * @param taxonomy A pointer on the taxonomy structure.
 *
 * @returns A pointer on the parent taxon at the superkingdom level.
 * @retval NULL if no parent taxon was found at the wanted rank.
 */
ecotx_t* obi_taxo_get_superkingdom(ecotx_t* taxon, OBIDMS_taxonomy_p taxonomy);


/**
 * @brief Function returning the label of a rank in an ecorankidx_t structure.
 *
 * @param rank_idx The index of the rank.
 * @param ranks A pointer on an ecorankidx_t structure.
 *
 * @returns The label of a rank in the ecorankidx_t structure.
 * @retval NULL if there is no rank at that index.
 *
 * @see rank_label_to_index()
 */
const char* obi_taxo_rank_index_to_label(int32_t rank_idx, ecorankidx_t* ranks);


// TODO
int obi_taxo_is_taxid_included(OBIDMS_taxonomy_p taxonomy,
			     			   int32_t* restrict_to_taxids,
				    		   int32_t count,
					    	   int32_t taxid);
