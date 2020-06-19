/****************************************************************************
 * Header file for OBITypes                                                 *
 ****************************************************************************/

/**
 * @file obitypes.h
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 * @date 18 May 2015
 * @brief Header file for the handling of OBITypes.
 */


#ifndef OBITYPES_H_
#define OBITYPES_H_

#include <stdio.h>
#include <unistd.h>
#include <stdint.h>


#define OBIInt_NA (INT32_MIN)		/**< NA value for the type OBI_INT */
#define OBIIdx_NA (INT64_MIN)		/**< NA value for indices */
#define OBIFloat_NA (float_NA())	/**< NA value for the type OBI_FLOAT */
#define OBIChar_NA (0)				/**< NA value for the type OBI_CHAR */ // TODO not sure about this one as it can be impossible to distinguish from uninitialized values
#define OBISeq_NA (NULL)			/**< NA value for the type OBI_SEQ */  // TODO discuss
#define OBIStr_NA (NULL)			/**< NA value for the type OBI_STR */  // TODO discuss
#define OBIBlob_NA (NULL)			/**< NA value for the type Obiblobs */  // TODO discuss
#define OBIQual_char_NA (NULL)		/**< NA value for the type OBI_QUAL if the quality is in character string format */
#define OBIQual_int_NA (NULL)		/**< NA value for the type OBI_QUAL if the quality is in integer format */
#define OBITuple_NA (NULL)			/**< NA value for tuples of any type */


/**
 * @brief enum for the boolean OBIType.
 */
typedef enum OBIBool {
    OBIFalse   = 0,
    OBITrue    = 1,
    OBIBool_NA = 2
} obibool_t, *obibool_p; 		/**< a boolean true/false value */	// TODO check name convention?


/**
 * @brief enum OBITypes for the data type of the OBIDMS columns.
 */
typedef enum OBIType {
	OBI_VOID    = 0,     		/**< data type not specified */
	OBI_INT,			    	/**< a signed integer value (C type : int32_t) */
	OBI_FLOAT,					/**< a floating value (C type : double) */
	OBI_BOOL,					/**< a boolean true/false value, see obibool_t enum */
	OBI_CHAR,					/**< a character (C type : char) */
	OBI_QUAL,					/**< an index in a data structure (C type : int64_t) referring to a quality score array */
	OBI_STR,				    /**< an index in a data structure (C type : int64_t) referring to a character string */
	OBI_SEQ,					/**< an index in a data structure (C type : int64_t) referring to a DNA sequence */
	OBI_IDX					    /**< an index referring to a line in another column (C type : int64_t) */
} OBIType_t, *OBIType_p;


/**
 * Typedefs for the OBITypes.
 */
typedef int32_t obiint_t;
typedef double obifloat_t;
typedef char obichar_t;
typedef int64_t index_t;

typedef char byte_t;			/**< Defining byte type.
 	 	 	 	 	 	 	 	 */

typedef int32_t obiversion_t;	/**< Defining type for version numbers.
	 	 	 	 	 	 	 	 */


/**
 * @brief Union used to compute the NA value of the OBI_FLOAT OBIType.
 */
typedef union
{
    double value;
    unsigned int word[2];
} ieee_double;


/**
 * @brief Returns the NA value of the OBI_FLOAT OBIType.
 * This value corresponds to the float NA value as defined in R.
 */
static double float_NA(void)
{
    volatile ieee_double x;
    x.word[0] = 0x7ff00000;
    x.word[1] = 1954;
    return x.value;
}


/**
 * @brief Trick to suppress compilation warnings about unused
 *        float_NA function actually called in macro.
 */
static inline void suppress_warning(void) {
	(void)float_NA;
	(void)suppress_warning;
}


/**
 * @brief Returns the memory size in bytes of an OBIType.
 *
 * @param type The OBIType code used as query.
 *
 * @returns The size in bytes of the type.
 * @retval 0 if an error occurred (unknown type).
 *
 * @since May 2015
 * @author Eric Coissac (eric.coissac@metabarcoding.org)
 */
size_t obi_sizeof(OBIType_t type);


/**
 * @brief Returns the size required to store an array of elements with an OBIType.
 *
 * The returned size is large enough to store an array large enough
 * to store all the elements but rounded at a multiple of the memory page size.
 *
 * @param data_type The OBIType of the elements.
 * @param nb_lines The number of lines to be stored.
 * @param nb_elements_per_line The number of elements per line.
 *
 * @returns The size in bytes of the array.
 * @retval 0 if an error occurred (unknown type).
 *
 * @since May 2015
 * @author Eric Coissac (eric.coissac@metabarcoding.org)
 */
size_t obi_array_sizeof(OBIType_t data_type, index_t nb_lines, index_t nb_elements_per_line);


/**
 * @brief Returns the name in the form of a character string of an OBIType.
 *
 *
 * @param data_type The OBIType code used as query.
 *
 * @returns The name of the OBIType.
 * @retval NULL if an error occurred (unknown type or error allocating the memory for the character string).
 *
 * @since August 2015
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
char* name_data_type(int data_type);


#endif /* OBITYPES_H_ */
