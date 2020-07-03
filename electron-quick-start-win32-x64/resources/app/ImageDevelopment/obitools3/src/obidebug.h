/****************************************************************************
 * Header file for the debugging code                                       *
 ****************************************************************************/

/**
 * @file obidebug.h
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 * @date 25 June 2015
 * @brief Header file for the debugging code.
 */


#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <limits.h>


//#ifndef DEBUG_LEVEL			// TODO
//#define DEBUG_LEVEL MAXINT
//#endif


//#ifdef OBIDEBUG
#define obidebug(debug_level, message, ...) \
	{if (debug_level > DEBUG_LEVEL) \
		{fprintf(stderr, "DEBUG %s:%d:%s, obi_errno = %d, errno = %d : " \
				message "\n", __FILE__, __LINE__, __func__, obi_errno, errno, ##__VA_ARGS__); \
		} \
	}
//#else
//#define obidebug(debug_level, message, ...)
//#endif
