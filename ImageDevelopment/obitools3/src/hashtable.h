/****************************************************************************
 * Hash table header file	                                                *
 ****************************************************************************/

/**
 * @file hashtable.h
 * @author Celine Mercier
 * @date July 26th 2016
 * @brief Header file for hash table functions.
 */


#ifndef HASHTABLE_H_
#define HASHTABLE_H_


#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>


#define SEED (0x9747b28c)   		/**< The seed used by the hash function.
                                	 */


/**
 * @brief Structure for an entry.
 */
typedef struct entry_s {
	char*           key;		/**< Key used to refer to the entry.
	 	 	 	 	 	 	 	 */
	void*           value;		/**< Pointer on the value to be stored.
	 	 	 	 	 	 	 	 */
	struct entry_s* next;		/**< Pointer on the next entry in the bin.
	 	 	 	 	 	 	 	 */
} entry_t, *entry_p;


/**
 * @brief Structure for a hash table.
 */
typedef struct hashtable {
	size_t size;			/**< Number of bins in the table.
	 	 	 	 	 	 	 */
	entry_p* table;			/**< Table of bins.
	 	 	 	 	 	 	 */
} hashtable_t, *hashtable_p;


/**
 * @brief Creates a new hashtable.
 *
 * @param size The number of bins in the hash table.
 *
 * @returns A pointer to the newly created hash table.
 * @retval NULL if an error occurred.
 *
 * @since July 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
hashtable_p ht_create(size_t size);


/**
 * @brief Inserts a new entry in the hash table.
 * 		  If the key is already in the table, the value is replaced by the new one.
 *
 * @param hashtable A pointer on the hash table structure.
 * @param key The key.
 * @param value A pointer on the value associated with the key.
 *
 * @retval 0 if the entry was correctly set.
 * @retval -1 if an error occurred.
 *
 * @since July 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int ht_set(hashtable_p hashtable, const char* key, void* value);


/**
 * @brief Retrieves a value from a hash table.
 *
 * @param hashtable A pointer on the hash table structure.
 * @param key The key.
 *
 * @returns A pointer on the value associated with the key.
 * @retval NULL if the key was not found.
 *
 * @since July 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
void* ht_get(hashtable_p hashtable, const char* key);


/**
 * @brief Deletes an entry.
 *
 * @param hashtable A pointer on the hash table structure.
 * @param key The key.
 *
 * @retval 0 if the entry was correctly deleted.
 * @retval -1 if an error occurred.
 *
 * @since July 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int ht_delete_entry(hashtable_p hashtable, const char* key);


/**
 * @brief Frees a hash table.
 *
 * @param hashtable A pointer on the hash table structure.
 *
 * @since July 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
void ht_free(hashtable_p hashtable);


#endif /* HASHTABLE_H_ */

