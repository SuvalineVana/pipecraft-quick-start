/****************************************************************************
 * OBITypes functions                                                       *
 ****************************************************************************/

/**
 * @file obitypes.h
 * @author Eric Coissac (eric.coissac@metabarcoding.org)
 * @date 23 May 2015
 * @brief Functions for the handling of OBITypes.
 */


#include <string.h>

#include "obitypes.h"
#include "obidebug.h"
#include "obierrno.h"


#define DEBUG_LEVEL 0	// TODO has to be defined somewhere else (cython compil flag?)


size_t obi_sizeof(OBIType_t type)
{
	size_t size=0;

	switch (type) {
	case OBI_VOID:  size = 1;
					break;

	case OBI_INT:   size = sizeof(obiint_t);
					break;

	case OBI_FLOAT: size = sizeof(obifloat_t);
					break;

	case OBI_BOOL:  size = sizeof(obibool_t);
					break;

	case OBI_CHAR:  size = sizeof(obichar_t);
					break;

	case OBI_QUAL:	size = sizeof(index_t);
					break;

	case OBI_STR:	size = sizeof(index_t);
					break;

	case OBI_SEQ:	size = sizeof(index_t);
					break;

	case OBI_IDX:	size = sizeof(index_t);
					break;

	default:        size = 0;
	}

	return size;
}


size_t obi_array_sizeof(OBIType_t type, index_t nb_lines, index_t nb_elements_per_line)
{
	size_t size;
	size_t rsize;
	size_t psize;

	size = obi_sizeof(type) * nb_lines * nb_elements_per_line;

	psize = getpagesize();
	rsize = size % psize;

	// Round at a size multiple of pagesize
	if (rsize)
		size = (size / psize) * psize + psize;

	return size;
}


char* name_data_type(int data_type)
{
	char* name = NULL;

	switch (data_type)
	{
		case OBI_VOID:  name = strdup("OBI_VOID");
						break;

		case OBI_INT:   name = strdup("OBI_INT");
						break;

		case OBI_FLOAT: name = strdup("OBI_FLOAT");
						break;

		case OBI_BOOL:  name = strdup("OBI_BOOL");
						break;

		case OBI_CHAR:  name = strdup("OBI_CHAR");
						break;

		case OBI_QUAL:  name = strdup("OBI_QUAL");
						break;

		case OBI_STR:   name = strdup("OBI_STR");
						break;

		case OBI_SEQ:   name = strdup("OBI_SEQ");
						break;

		case OBI_IDX:   name = strdup("OBI_IDX");
						break;
	}

	if (name == NULL)
		obidebug(1, "Problem with the data type");

	return name;
}




