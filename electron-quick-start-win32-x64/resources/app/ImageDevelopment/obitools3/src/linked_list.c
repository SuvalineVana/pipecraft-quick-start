/****************************************************************************
 * Linked list source file	                                                *
 ****************************************************************************/

/**
 * @file linked_list.c
 * @author Celine Mercier
 * @date February 22th 2017
 * @brief Source file for linked list functions.
 */


#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>

#include "linked_list.h"


/**
 * @brief Creates a new node.
 *
 * @warning The returned pointer has to be freed by the caller.
 *
 * @returns A pointer on the new node.
 * @retval NULL if an error occurred.
 *
 * @since February 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
static Linked_list_node_p create_node(void);


static Linked_list_node_p create_node()
{
	Linked_list_node_p node;

	node = malloc(sizeof(Linked_list_node_t));
	if (node == NULL)
		return NULL;

	node->value = NULL;
	node->previous = NULL;
	node->next = NULL;

	return node;
}


// Add a value at the end of a linked list
Linked_list_node_p ll_add(Linked_list_node_p head, void* value)
{
	Linked_list_node_p node = head;
	Linked_list_node_p new_node = NULL;

	// First node
	if (head == NULL)
	{
		head = create_node();
		if (head == NULL)
			return NULL;
		head->value = value;
	}

	else
	{
		while (node->next != NULL)
			node = node->next;

		new_node = create_node();
		if (new_node == NULL)
			return NULL;
		node->next = new_node;
		new_node->previous = node;
		new_node->value = value;
	}

	return head;
}


// Set a value at a given index of the list
int ll_set(Linked_list_node_p head, int idx, void* value)
{
	int i = 0;
	Linked_list_node_p node = head;

	while ((node != NULL) && (i < idx))
	{
		node = node->next;
		i++;
	}

	if (node == NULL)	// End of list reached before index
		return -1;

	node->value = value;

	return 0;
}


// Get a node with its index
Linked_list_node_p ll_get(Linked_list_node_p head, int idx)
{
	int i = 0;
	Linked_list_node_p node = head;

	while ((node != NULL) && (i < idx))
	{
		node = node->next;
		i++;
	}

	return node;
}


// Delete a node
Linked_list_node_p ll_delete(Linked_list_node_p head, int idx)
{
	int i = 0;
	Linked_list_node_p node = head;

	while ((node != NULL) && (i < idx))
	{
		node = node->next;
		i++;
	}

	if (node == NULL)	// Node didn't exist
		return NULL;

	if (node->previous != NULL)
		(node->previous)->next = node->next;
	else  // deleting head node: head changes
		head = node->next;

	if (node->next != NULL)
		(node->next)->previous = node->previous;

	free(node);

	return head;
}


// Free the linked list
void ll_free(Linked_list_node_p head)
{
	Linked_list_node_p node = head;
	Linked_list_node_p previous = head;

	while (node != NULL)
	{
		previous = node;
		node = node->next;
		free(previous);
	}
}


// Get the index of a node from its value (TODO useless?) -- kinda assumes unique values
//int ll_get_index(Linked_list_node_p head, void* value)
//{
//
//}
