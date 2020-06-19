/****************************************************************************
 * Utility functions                                                       *
 ****************************************************************************/

/**
 * @file utils.c
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 * @date 29 March 2016
 * @brief Code for utility functions.
 */

#include <fcntl.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <dirent.h>
#include <unistd.h>
#include <time.h>
#include <math.h>

#include "utils.h"
#include "obidebug.h"
#include "obierrno.h"


#define DEBUG_LEVEL 0	// TODO has to be defined somewhere else (cython compil flag?)


/**************************************************************************
 *
 * D E C L A R A T I O N   O F   T H E   P R I V A T E   F U N C T I O N S
 *
 **************************************************************************/


/**
 * Internal function returning the complement of a nucleotide base.
 *
 * @warning The base must be in lower case.
 *
 * @param nucAc The nucleotide base.
 *
 * @returns The complement of the nucleotide base.
 * @retval The nucleotide base itself if no complement was found.
 *
 * @since December 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 * @note Copied from ecoPCR source code
 */
static char nuc_base_complement(char nucAc);


/**
 * Internal function returning the complement of a nucleotide sequence.
 *
 * @warning The sequence must be in lower case.
 * @warning The sequence will be replaced by its complement without being copied.
 *
 * @param nucAcSeq The nucleotide sequence.
 *
 * @returns The complemented sequence.
 *
 * @since December 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 * @note Copied from ecoPCR source code
 */
static char* nuc_seq_complement(char* nucAcSeq);


/**
 * Internal function returning the reverse of a nucleotide sequence.
 *
 * @warning The sequence must be in lower case.
 * @warning The sequence will be replaced by its reverse without being copied.
 *
 * @param str The nucleotide sequence.
 * @param isPattern Whether the sequence is a pattern. TODO
 *
 * @returns The reversed sequence.
 *
 * @since December 2016
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 * @note Copied from ecoPCR source code
 */
static char* reverse_sequence(char* str, char isPattern);


/************************************************************************
 *
 * D E F I N I T I O N   O F   T H E   P R I V A T E   F U N C T I O N S
 *
 ************************************************************************/

static char nuc_base_complement(char nucAc)
{
    char* c;

    if ((c = strchr(DNA_ALPHA, nucAc)))
        return CDNA_ALPHA[(c - DNA_ALPHA)];
    else
        return nucAc;
}


static char* nuc_seq_complement(char* nucAcSeq)
{
    char *s;

    for (s = nucAcSeq ; *s ; s++)
        *s = nuc_base_complement(*s);

    return nucAcSeq;
}


static char* reverse_sequence(char* str, char isPattern)
{
        char *sb, *se, c;

        if (! str)
            return str;

        sb = str;
        se = str + strlen(str) - 1;

        while(sb <= se) {
           c    = *sb;
          *sb++ = *se;
          *se-- = c;
        }

		sb = str;
		se = str + strlen(str) - 1;

		if (isPattern)
			for (;sb < se; sb++)
			{
				if (*sb=='#')
				{
					if (((se - sb) > 2) && (*(sb+2)=='!'))
					{
						*sb='!';
						sb+=2;
						*sb='#';
					}
					else
					{
						*sb=*(sb+1);
						sb++;
						*sb='#';
					}
				}
				else if (*sb=='!')
					{
						*sb=*(sb-1);
						*(sb-1)='!';
					}
			}

        return str;
}


/**********************************************************************
 *
 * D E F I N I T I O N   O F   T H E   P U B L I C   F U N C T I O N S
 *
 **********************************************************************/


int copy_file(const char* src_file_path, const char* dest_file_path)
{
	int src_fd, dst_fd, n, err;
	unsigned char buffer[4096];

	src_fd = open(src_file_path, O_RDONLY);
	if (src_fd == -1)
    {
		obi_set_errno(OBI_UTILS_ERROR);
		obidebug(1, "\nError opening a file to copy");
        return -1;
    }
    dst_fd = open(dest_file_path, O_CREAT | O_WRONLY, 0777);  // overwrite if already exists
    if (dst_fd == -1)
    {
		obi_set_errno(OBI_UTILS_ERROR);
		obidebug(1, "\nError opening a file to write a copy: %s", dest_file_path);
        return -1;
    }

    while (1)
    {
        err = read(src_fd, buffer, 4096);
        if (err == -1)
        {
    		obi_set_errno(OBI_UTILS_ERROR);
    		obidebug(1, "\nProblem reading a file to copy");
            return -1;
        }
        n = err;

        if (n == 0)
        	break;

        err = write(dst_fd, buffer, n);
        if (err == -1)
        {
    		obi_set_errno(OBI_UTILS_ERROR);
    		obidebug(1, "\nProblem writing to a file while copying");
            return -1;
        }
    }

    if (close(src_fd) < 0)
    {
		obi_set_errno(OBI_UTILS_ERROR);
		obidebug(1, "\nError closing a file after copying it");
        return -1;
    }
    if (close(dst_fd) < 0)
    {
		obi_set_errno(OBI_UTILS_ERROR);
		obidebug(1, "\nError closing a file after copying to it");
        return -1;
    }

    return 0;
}


int digit_count(index_t i)
{
	int n_digits;

	if (i == 0)
		n_digits = 1;
	else
		n_digits = floor(log10(llabs(i))) + 1;

	return n_digits;
}


char* build_word_with_idx(const char* prefix, index_t idx)
{
	char* word;
	int   n_digits;

	n_digits = digit_count(idx);
	word = (char*) malloc((strlen(prefix) + 1+ n_digits + 1)*sizeof(char));
	if (word == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating memory for a character string");
		return NULL;
	}
	if (sprintf(word, "%s_%lld", prefix, idx) < 0)
	{
		obi_set_errno(OBI_UTILS_ERROR);
		obidebug(1, "\nProblem building a word from a prefix and an index");
		return NULL;
	}

	return word;
}


int count_dir(char* dir_path)
{
	struct dirent* dp;
	DIR*           fd;
	int            count;

	count = 0;
	if ((fd = opendir(dir_path)) == NULL)
	{
		obi_set_errno(OBI_UTILS_ERROR);
		obidebug(1, "Error opening a directory: %s\n", dir_path);
		return -1;
	}
	while ((dp = readdir(fd)) != NULL)
	{
		if ((dp->d_name)[0] == '.')
			continue;
		count++;
	}

	if (closedir(fd) < 0)
	{
		obi_set_errno(OBI_UTILS_ERROR);
		obidebug(1, "\nError closing a directory");
		return -1;
	}

	return count;
}


char* obi_format_date(time_t date)
{
	char*       formatted_time;
	struct tm*  tmp;

	formatted_time = (char*) malloc(FORMATTED_TIME_LENGTH*sizeof(char));
	if (formatted_time == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating memory to format a date");
		return NULL;
	}

	tmp = localtime(&date);
	if (tmp == NULL)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError formatting a date");
		return NULL;
	}

	if (strftime(formatted_time, FORMATTED_TIME_LENGTH, "%c", tmp) == 0)
	{
		obi_set_errno(OBICOL_UNKNOWN_ERROR);
		obidebug(1, "\nError formatting a date");
		return NULL;
	}

	return formatted_time;
}


void* obi_get_memory_aligned_on_16(int size, int* shift)
{
	void* memory;

	*shift = 0;

	memory = (void*) malloc(size);
	if (memory == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating memory");
		return NULL;
	}

	while ((((long long unsigned int) (memory))%16) != 0)
	{
		memory++;
		(*shift)++;
	}

	return (memory);
}


/*
 * A generic implementation of binary search for the Linux kernel
 *
 * Copyright (C) 2008-2009 Ksplice, Inc.
 * Author: Tim Abbott <tabbott@ksplice.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; version 2.
 */
void* bsearch_user_data(const void* key, const void* base, size_t num, size_t size, const void* user_data,
              	  	  	int (*cmp)(const void *key, const void *elt, const void* user_data))
{
	size_t start = 0;
	size_t end   = num;
	size_t mid;
    int result;

    while (start < end)
    {
    	mid = start + (end - start) / 2;
    	result = cmp(key, base + mid * size, user_data);
		if (result < 0)
			end = mid;
		else if (result > 0)
			start = mid + 1;
		else
			return (void*)base + mid * size;
    }

    return NULL;
}


/*
 * Copyright (c) 1992, 1993
 *      The Regents of the University of California.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */
/*
 * Qsort routine from Bentley & McIlroy's "Engineering a Sort Function".
 */

#define MIN(a,b) ((a) < (b) ? a : b)

#define swapcode(TYPE, parmi, parmj, n) {               \
        long i = (n) / sizeof (TYPE);                   \
        register TYPE *pi = (TYPE *) (parmi);           \
        register TYPE *pj = (TYPE *) (parmj);           \
        do {                                            \
                register TYPE   t = *pi;                \
                *pi++ = *pj;                            \
                *pj++ = t;                              \
        } while (--i > 0);                              \
}

#define SWAPINIT(a, es) swaptype = ((char *)a - (char *)0) % sizeof(long) || \
        es % sizeof(long) ? 2 : es == sizeof(long)? 0 : 1;

static __inline void
swapfunc(char *a, char *b, int n, int swaptype)
{
        if (swaptype <= 1)
                swapcode(long, a, b, n)
        else
                swapcode(char, a, b, n)
}

#define swap(a, b)                                      \
        if (swaptype == 0) {                            \
                long t = *(long *)(a);                  \
                *(long *)(a) = *(long *)(b);            \
                *(long *)(b) = t;                       \
        } else                                          \
                swapfunc(a, b, es, swaptype)

#define vecswap(a, b, n)        if ((n) > 0) swapfunc(a, b, n, swaptype)

static __inline char *
med3(char *a, char *b, char *c, const void *user_data, int (*cmp)(const void *, const void *, const void *))
{
        return cmp(a, b, user_data) < 0 ?
               (cmp(b, c, user_data) < 0 ? b : (cmp(a, c, user_data) < 0 ? c : a ))
              :(cmp(b, c, user_data) > 0 ? b : (cmp(a, c, user_data) < 0 ? a : c ));
}

void
qsort_user_data(void *aa, size_t n, size_t es, const void *user_data, int (*cmp)(const void *, const void *, const void *))
{
        char *pa, *pb, *pc, *pd, *pl, *pm, *pn;
        int d, r, swaptype, swap_cnt;
        register char *a = aa;

loop:   SWAPINIT(a, es);
        swap_cnt = 0;
        if (n < 7) {
                for (pm = (char *)a + es; pm < (char *) a + n * es; pm += es)
                        for (pl = pm; pl > (char *) a && cmp(pl - es, pl, user_data) > 0;
                             pl -= es)
                                swap(pl, pl - es);
                return;
        }
        pm = (char *)a + (n / 2) * es;
        if (n > 7) {
                pl = (char *)a;
                pn = (char *)a + (n - 1) * es;
                if (n > 40) {
                        d = (n / 8) * es;
                        pl = med3(pl, pl + d, pl + 2 * d, user_data, cmp);
                        pm = med3(pm - d, pm, pm + d, user_data, cmp);
                        pn = med3(pn - 2 * d, pn - d, pn, user_data, cmp);
                }
                pm = med3(pl, pm, pn, user_data, cmp);
        }
        swap(a, pm);
        pa = pb = (char *)a + es;

        pc = pd = (char *)a + (n - 1) * es;
        for (;;) {
                while (pb <= pc && (r = cmp(pb, a, user_data)) <= 0) {
                        if (r == 0) {
                                swap_cnt = 1;
                                swap(pa, pb);
                                pa += es;
                        }
                        pb += es;
                }
                while (pb <= pc && (r = cmp(pc, a, user_data)) >= 0) {
                        if (r == 0) {
                                swap_cnt = 1;
                                swap(pc, pd);
                                pd -= es;
                        }
                        pc -= es;
                }
                if (pb > pc)
                        break;
                swap(pb, pc);
                swap_cnt = 1;
                pb += es;
                pc -= es;
        }
        if (swap_cnt == 0) {  /* Switch to insertion sort */
                for (pm = (char *) a + es; pm < (char *) a + n * es; pm += es)
                        for (pl = pm; pl > (char *) a && cmp(pl - es, pl, user_data) > 0;
                             pl -= es)
                                swap(pl, pl - es);
                return;
        }

        pn = (char *)a + n * es;
        r = MIN(pa - (char *)a, pb - pa);
        vecswap(a, pb - r, r);
        r = MIN((long)(pd - pc), (long)(pn - pd - es));
        vecswap(pb, pn - r, r);
        if ((r = pb - pa) > (int)es)
                qsort_user_data(a, r / es, es, user_data, cmp);
        if ((r = pd - pc) > (int)es) {
                /* Iterate rather than recurse to save stack space */
                a = pn - r;
                n = r / es;
                goto loop;
        }
/*              qsort(pn - r, r / es, es, cmp);*/
}


char* reverse_complement_pattern(char* nucAcSeq)
{
    return reverse_sequence(nuc_seq_complement(nucAcSeq), 1);
}


char* reverse_complement_sequence(char* nucAcSeq)
{
    return reverse_sequence(nuc_seq_complement(nucAcSeq), 0);
}

