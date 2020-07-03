/****************************************************************************
 * Linked list header file	                                                *
 ****************************************************************************/

/**
 * @file linked_list.h
 * @author Celine Mercier
 * @date February 22th 2017
 * @brief Header file for linked list functions.
 */


#ifndef LINKED_LIST_H_
#define LINKED_LIST_H_


#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>


/**
 * @brief Structure for a node in a double linked chain.
 */
typedef struct Linked_list_node {
	void*                      value;    				     		/**< A pointer (the value kept).
																	 */
	struct Linked_list_node* next;    							/**< A pointer on the next node.
																	 */
	struct Linked_list_node* previous;    				    	/**< A pointer on the previous node.
																	 */
} Linked_list_node_t, *Linked_list_node_p;


/**
 * @brief Adds a new node at the end of a linked list.
 *
 * Works even if it is the first node.
 *
 * @param head A pointer on the first node of the linked list, or NULL if the list is empty.
 * @param value The value to associate with the node.
 *
 * @returns A pointer on the new head node of the linked list.
 * @retval NULL if an error occurred.
 *
 * @since February 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
Linked_list_node_p ll_add(Linked_list_node_p head, void* value);


/**
 * @brief Sets a value at a given index of the list.
 *
 * @param head A pointer on the first node of the linked list, or NULL if the list is empty.
 * @param idx The index of the node at which the value should be changed.
 * @param value The new value to associate with the node.
 *
 * @returns A value indicating the success of the operation.
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since February 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int ll_set(Linked_list_node_p head, int idx, void* value);


/**
 * @brief Gets a node from its index.
 *
 * @warning The pointer returned is a pointer on the node and not on the value.
 *
 * @param head A pointer on the first node of the linked list, or NULL if the list is empty.
 * @param idx The index of the node to retrieve.
 *
 * @returns A pointer on the retrieved node.
 * @retval NULL if an error occurred.
 *
 * @since February 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
Linked_list_node_p ll_get(Linked_list_node_p head, int idx);


/**
 * @brief Deletes a node.
 *
 * @param head A pointer on the first node of the linked list.
 * @param idx The index of the node to delete.
 *
 * @returns A pointer on the new head node of the linked list.
 * @retval NULL if the list is now empty, or if the node did not exist.	  // TODO discuss
 *
 * @since February 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
Linked_list_node_p ll_delete(Linked_list_node_p head, int idx);


/**
 * @brief Frees all the nodes of a linked list.
 *
 * @param head A pointer on the first node of the linked list.
 *
 * @since February 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
void ll_free(Linked_list_node_p head);


#endif /* LINKED_LIST_H_ */

