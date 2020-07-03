/****************************************************************************
 * Header file for utility functions                                        *
 ****************************************************************************/

/**
 * @file utils.h
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 * @date 29 March 2016
 * @brief Header file for utility functions.
 */


#ifndef UTILS_H_
#define UTILS_H_

#include <stdio.h>
#include <sys/stat.h>

#include "obidms.h"
#include "obitypes.h"


#define FORMATTED_TIME_LENGTH (1024)    					/**< The length allocated for the character string containing a formatted date.
 	 	 	 	 	 	 	 	 	     	 	 	 	 	 */
#define ONE_IF_ZERO(x) (((x)==0)?1:(x))						/**< If x is equal to 0, x takes the value 1.
                                	   	 	 	 	 	 	 */
#define DNA_ALPHA   "acgtbdefhijklmnopqrsuvwxyz#![]"	    /**< DNA alphabet (IUPAC).
 	 	 	 	  //"ABCDEFGHIJKLMNOPQRSTUVWXYZ#![]" 	 	 */
#define CDNA_ALPHA  "tgcavhefdijmlknopqysabwxrz#!]["		/**< Complementary DNA alphabet (IUPAC).
 	 	 	 	  //"TVGHEFCDIJMLKNOPQYSAABWXRZ#!][" 	 	 */



/**
 * @brief Copy the content of a file into another file.
 *
 * @param src_file_path The path to the source file to copy.
 * @param dest_file_path The path to the destination file.
 *
 * @retval 0 if the operation was successfully completed.
 * @retval -1 if an error occurred.
 *
 * @since July 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int copy_file(const char* src_file_path, const char* dest_file_path);


/**
 * @brief Counts the number of digits of a number.
 *
 * @param i The number.
 *
 * @returns The number of digits of the number.
 *
 * @since July 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int digit_count(index_t i);


/**
 * @brief Builds a word from a prefix and an index, with the form prefix_index.
 *
 * @warning The returned pointer has to be freed by the caller.
 *
 * @param prefix The prefix for the word.
 * @param idx The index to use as suffix.
 *
 * @returns The built word.
 *
 * @since July 2017
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
char* build_word_with_idx(const char* prefix, index_t idx);


/**
 * @brief Counts the number of files and directories in a directory.
 *
 * @param dir_path The absolute path of the directory.
 *
 * @returns The number of files and directories in the directory.
 *
 * @since April 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int count_dir(char* dir_path);


/**
 * @brief Formats a date in a way that is easy to read.
 *
 * @warning The pointer returned must be freed by the caller.
 *
 * @param date A date.
 *
 * @returns The date formatted in a way that is easy to read.
 *
 * @since October 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
char* obi_format_date(time_t date);


/**
 * @brief Allocates a chunk of memory aligned on 16 bytes boundary.
 *
 * @warning The pointer returned must be freed by the caller.
 * @warning The memory chunk pointed at by the returned pointer can be
 *          smaller than the size asked for, since the address is shifted
 *          to be aligned.
 *
 * @param size The size in bytes of the memory chunk to be allocated.
 * 			   Ideally the closest multiple of 16 greater than the wanted size.
 * @param shift A pointer on an integer corresponding to the shift made to align
 * 				the address. Used to free the memory chunk.
 *
 * @returns The pointer on the aligned memory.
 *
 * @since May 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
void* obi_get_memory_aligned_on_16(int size, int* shift);


/**
 * @brief Version of quick sort modified to allow the user to provide an
 *        additional pointer sent to the comparison function.
 *
 * @param key This is the pointer to the object that serves as key for the search, type-casted as a void*.
 * @param base This is the pointer to the first object of the array where the search is performed, type-casted as a void*.
 * @param num This is the number of elements in the array pointed by base.
 * @param size This is the size in bytes of each element in the array.
 * @param user_data This is an additional pointer passed to the comparison function.
 * @param cmp This is the function that compares two elements, eventually with an additional pointer.
 *
 * @returns A pointer to an entry in the array that matches the search key.
 * @retval NULL if key is not found.
 *
 * @since January 2017
 * @author original code modified by Celine Mercier (celine.mercier@metabarcoding.org)
 */
void* bsearch_user_data(const void* key, const void* base, size_t num, size_t size, const void* user_data,
              	  	  	int (*cmp)(const void *key, const void *elt, const void* user_data));


/**
 * @brief Version of quick sort modified to allow the user to provide an
 *        additional pointer sent to the comparison function.
 *
 * @param aa This is the pointer to the first element of the array to be sorted.
 * @param n This is the number of elements in the array pointed by base.
 * @param es This is the size in bytes of each element in the array.
 * @param user_data This is an additional pointer passed to the comparison function.
 * @param cmp This is the function that compares two elements, eventually with an additional pointer.
 *
 * @since January 2017
 * @author original code modified by Celine Mercier (celine.mercier@metabarcoding.org)
 */
void qsort_user_data(void *aa, size_t n, size_t es, const void *user_data, int (*cmp)(const void *, const void *, const void *));


/**
 * Function returning the reverse complement of a nucleotide sequence.
 *
 * @warning The sequence must be in lower case.
 * @warning The sequence will be replaced by its reverse complement without being copied.
 *
 * @param nucAcSeq The nucleotide sequence.
 *
 * @returns The reverse complemented sequence.
 *
 * @since December 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 * @note Copied from ecoPCR source code
 */
char* reverse_complement_sequence(char* nucAcSeq);


/**
 * Function returning the reverse complement of a pattern.
 *
 * @warning The pattern must be in lower case.
 * @warning The pattern will be replaced by its reverse complement without being copied.
 *
 * @param nucAcSeq The pattern.
 *
 * @returns The reverse complemented pattern.
 *
 * @since December 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 * @note Copied from ecoPCR source code
 */
char* reverse_complement_pattern(char* nucAcSeq);


#endif /* UTILS_H_ */
