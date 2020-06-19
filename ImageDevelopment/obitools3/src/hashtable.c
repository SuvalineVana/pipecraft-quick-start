/****************************************************************************
 * Hash table source file	                                                *
 ****************************************************************************/

/**
 * @file hashtable.c
 * @author Celine Mercier
 * @date July 26th 2016
 * @brief Source file for hash table functions.
 */


#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include "string.h"

#include "murmurhash2.h"
#include "hashtable.h"


// Create a new hashtable
hashtable_p ht_create(size_t size)
{
	hashtable_p hashtable = NULL;
	size_t		i;

	// Allocate the table
	hashtable = malloc(sizeof(hashtable_t));
	if (hashtable == NULL)
		return NULL;

	// Allocate the head nodes
	hashtable->table = malloc(size * sizeof(entry_p));
	if (hashtable->table == NULL)
		return NULL;

	// Initialize the head nodes
	for (i=0; i<size; i++)
		hashtable->table[i] = NULL;

	hashtable->size = size;

	return hashtable;
}


// Create an entry
entry_p ht_new_entry(const char* key, void* value)
{
	entry_p new_entry;

	new_entry = malloc(sizeof(entry_t));
	if (new_entry == NULL)
		return NULL;

	new_entry->key = strdup(key);
	if (new_entry->key == NULL)
		return NULL;

	new_entry->value = value;

	new_entry->next = NULL;

	return new_entry;
}


// Delete an entry
int ht_delete_entry(hashtable_p hashtable, const char* key)
{
	entry_p last  = NULL;
	entry_p entry = NULL;
	size_t  bin   = 0;

	bin = murmurhash2(key, strlen(key), SEED);
	bin = bin % hashtable->size;

	// Step through the bin looking for the value
	entry = hashtable->table[bin];

	while ((entry != NULL) && (strcmp(key, entry->key ) != 0))
	{
		last = entry;
		entry = entry->next;
	}

	if (entry == NULL)	// key not found
		return -1;

	// Link the entries before and after the entry
	if (last != NULL)	// If not head node
		last->next = entry->next;
	else	// If head node
		hashtable->table[bin] = entry->next;

	// Free the entry
	free(entry->key);
	free(entry->value);
	free(entry);

	return 0;
}


// Set a new entry in the hash table. If the key is already in the table, the value is replaced by the new one
int ht_set(hashtable_p hashtable, const char* key, void* value)
{
	size_t  bin       = 0;
	entry_p new_entry = NULL;
	entry_p next      = NULL;
	entry_p last      = NULL;

	if ((key == NULL) || (value == NULL))
		return -1;

	bin = murmurhash2(key, strlen(key), SEED);
	bin = bin % hashtable->size;

	next = hashtable->table[bin];

	while ((next != NULL) && (strcmp(key, next->key) != 0))
	{
		last = next;
		next = next->next;
	}

	// If the key is already in the table, the value is replaced
	if ((next != NULL) && (strcmp(key, next->key) == 0))
		new_entry->value = value;

	// Else, create the new entry and link it at the end of the list
	else
	{
		// Create the new entry
		new_entry = ht_new_entry(key, value);
		if (new_entry == NULL)
			return -1;

		// If it is the first entry of that bin, we're at the head node of the list, and we replace it with the new entry
		if (last == NULL)
			hashtable->table[bin] = new_entry;

		// Else link the new entry at the end of the list
		else
			last->next = new_entry;
	}
	return 0;
}


// Retrieve a value from a hash table
void* ht_get(hashtable_p hashtable, const char* key)
{
	size_t  bin = 0;
	entry_p entry;

	bin = murmurhash2(key, strlen(key), SEED);
	bin = bin % hashtable->size;

	// Step through the bin looking for the value
	entry = hashtable->table[bin];

	while ((entry != NULL) && (strcmp(key, entry->key ) != 0))
		entry = entry->next;

	if (entry == NULL)
		return NULL;

	else
		return entry->value;
}


// Free the hash table
void ht_free(hashtable_p hashtable)
{
	size_t  i;
	entry_p entry;
	entry_p next;

	for (i=0; i < hashtable->size; i++)
	{
		next = hashtable->table[i];
		while (next != NULL)
		{
			entry = next;
			free(entry->key);
			next = entry->next;
			free(entry);
		}
	}
	free(hashtable->table);
	free(hashtable);
}


