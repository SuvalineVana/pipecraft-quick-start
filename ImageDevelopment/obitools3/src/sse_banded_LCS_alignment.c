/****************************************************************************
 * LCS alignment of two sequences				                            *
 ****************************************************************************/

/**
 * @file sse_banded_LCS_alignment.c
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 * @date November 7th 2012
 * @brief Functions handling the alignment of two sequences to compute their Longest Common Sequence.
 */



#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <stdint.h>
#include <stdbool.h>
#include <limits.h>

#include "obierrno.h"
#include "obidebug.h"
#include "utils.h"
#include "_sse.h"
#include "sse_banded_LCS_alignment.h"
#include "obiblob.h"
#include "encode.h"	// TODO move putBlobInSeq function to encode.c ?


#define DEBUG_LEVEL 0	// TODO has to be defined somewhere else (cython compil flag?)



/**************************************************************************
 *
 * D E C L A R A T I O N   O F   T H E   P R I V A T E   F U N C T I O N S
 *
 **************************************************************************/


/**
 * @brief Internal function printing a 128 bits register as 8 16-bits integers.
 *
 * @param r The register to print.
 *
 * @author Eric Coissac (eric.coissac@metabarcoding.org)
 */
static void printreg(__m128i r);


/**
 * @brief Internal function extracting a 16-bits integer from a 128 bits register.
 *
 * @param r The register to read.
 * @param p The position at which the integer should be read (between 0 and 7).
 *
 * @returns The extracted integer.
 *
 * @author Eric Coissac (eric.coissac@metabarcoding.org)
 */
static inline int extract_reg(__m128i r, int p);


/**
 * @brief Internal function aligning two sequences, computing the lengths of their Longest Common Subsequence and of their alignment.
 *
 * @warning The first argument (seq1) must correspond to the longest sequence.
 *
 * @param seq1 The first sequence, the longest of the two, as prepared by putSeqInSeq() or putBlobInSeq().
 * @param seq2 The second sequence, the shortest of the two, as prepared by putSeqInSeq() or putBlobInSeq().
 * @param l1 The length of the first sequence.
 * @param l2 The length of the second sequence.
 * @param bandLengthLeft The length of the left band for the banded alignment, as computed by calculateLeftBandLength().
 * @param bandLengthTotal The length of the complete band for the banded alignment, as computed by calculateSSEBandLength().
 * @param address A pointer, aligned on a 16 bits boundary, on the int array where the initial values for the alignment length are stored,
 *                as prepared for the alignment by initializeAddressWithGaps().
 * @param lcs_length A pointer on the int where the LCS length will be stored.
 * @param ali_length A pointer on the int where the alignment length will be stored.
 *
 * @since 2012
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
void sse_banded_align_lcs_and_ali_len(int16_t* seq1, int16_t* seq2, int l1, int l2, int bandLengthLeft, int bandLengthTotal, int16_t* address, int* lcs_length, int* ali_length);


/**
 * @brief Internal function aligning two sequences, computing the length of their Longest Common Subsequence (and not the alignment length).
 *
 * @warning The first argument (seq1) must correspond to the longest sequence.
 *
 * @param seq1 The first sequence, the longest of the two, as prepared by putSeqInSeq() or putBlobInSeq().
 * @param seq2 The second sequence, the shortest of the two, as prepared by putSeqInSeq() or putBlobInSeq().
 * @param l1 The length of the first sequence.
 * @param l2 The length of the second sequence.
 * @param bandLengthLeft The length of the left band for the banded alignment, as computed by calculateLeftBandLength().
 * @param bandLengthTotal The length of the complete band for the banded alignment, as computed by calculateSSEBandLength().
 * @param lcs_length A pointer on the int where the LCS length will be stored.
 *
 * @since 2012
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
void sse_banded_align_just_lcs(int16_t* seq1, int16_t* seq2, int l1, int l2, int bandLengthLeft, int bandLengthTotal, int* lcs_length);


/**
 * @brief Internal function calculating the length of the left band for the banded alignment.
 *
 * @param lmax The length of the longest sequence to align.
 * @param LCSmin The minimum length of the LCS to be above the chosen threshold, as computed by calculateLCSmin().
 *
 * @returns The length of the left band.
 *
 * @since 2012
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int calculateLeftBandLength(int lmax, int LCSmin);


/**
 * @brief Internal function calculating the length of the right band for the banded alignment.
 *
 * @param lmin The length of the shortest sequence to align.
 * @param LCSmin The minimum length of the LCS to be above the chosen threshold, as computed by calculateLCSmin().
 *
 * @returns The length of the right band.
 *
 * @since 2012
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int calculateRightBandLength(int lmin, int LCSmin);


/**
 * @brief Internal function calculating the length of the complete band for the banded alignment.
 *
 * @param bandLengthRight The length of the right band for the banded alignment, as computed by calculateRightBandLength().
 * @param bandLengthLeft The length of the left band for the banded alignment, as computed by calculateLeftBandLength().
 *
 * @returns The length of the complete band.
 *
 * @since 2012
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int calculateSSEBandLength(int bandLengthRight, int bandLengthLeft);


/**
 * @brief Internal function calculating the size to allocate for the int array where the alignment length will be stored in the matrix.
 *
 * @param maxLen The length of the longest sequence to align.
 * @param LCSmin The minimum length of the LCS to be above the chosen threshold, as computed by calculateLCSmin().
 *
 * @returns The size to allocate in bytes.
 *
 * @since 2012
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
int calculateSizeToAllocate(int maxLen, int LCSmin);


/**
 * @brief Internal function initializing the int array corresponding to a sequence to align with default values.
 *
 * @param seq The int array corresponding to the sequence to align, as prepared by putSeqInSeq() or putBlobInSeq().
 * @param size The number of positions to initialize.
 * @param iniValue The value that the positions should be initialized to.
 *
 * @since 2012
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
void iniSeq(int16_t* seq, int size, int16_t iniValue);


/**
 * @brief Internal function building the int array corresponding to a sequence to align.
 *
 * Each nucleotide is stored as a short int (int16_t).
 *
 * @param seq A pointer on the allocated int array.
 * @param s A pointer on the character string corresponding to the sequence.
 * @param l The length of the sequence.
 * @param reverse A boolean indicating whether the sequence should be written reversed
 *                (for the second sequence to align).
 *
 * @since 2012
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
void putSeqInSeq(int16_t* seq, char* s, int l, bool reverse);


/**
 * @brief Internal function building the int array corresponding to an obiblob containing a sequence.
 *
 * Each nucleotide is stored as a short int (int16_t).
 *
 * @param seq A pointer on the allocated int array.
 * @param b A pointer on the obiblob containing the sequence.
 * @param l The length of the (decoded) sequence.
 * @param reverse A boolean indicating whether the sequence should be written reversed
 *                (for the second sequence to align).
 *
 * @since 2012
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
void putBlobInSeq(int16_t* seq, Obi_blob_p b, int l, bool reverse);


/**
 * @brief Internal function preparing an int array with the initial values for the alignment lengths before the alignment.
 *
 * The int array containing the initial alignment lengths (corresponding to the first line of the diagonalized band of the alignment matrix)
 * needs to be initialized with external gap lengths before the alignment.
 *
 * @param address A pointer, aligned on a 16 bits boundary, on the int array where the initial values for the alignment length are to be stored.
 * @param bandLengthTotal The length of the complete band for the banded alignment, as computed by calculateSSEBandLength().
 * @param bandLengthLeft The length of the left band for the banded alignment, as computed by calculateLeftBandLength().
 * @param lmax The length of the longest sequence to align.
 *
 * @since 2012
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
void initializeAddressWithGaps(int16_t* address, int bandLengthTotal, int bandLengthLeft, int lmax);


/**
 * @brief Internal function aligning two sequences, computing the lengths of their Longest Common Subsequence and of their alignment.
 *
 * @warning The first argument (seq1) must correspond to the longest sequence.
 *
 * @param seq1 The first sequence, the longest of the two, as prepared by putSeqInSeq() or putBlobInSeq().
 * @param seq2 The second sequence, the shortest of the two, as prepared by putSeqInSeq() or putBlobInSeq().
 * @param l1 The length of the first sequence.
 * @param l2 The length of the second sequence.
 * @param normalize Whether the score should be normalized with the reference sequence length.
 * @param reference The reference length. 0: The alignment length; 1: The longest sequence's length; 2: The shortest sequence's length.
 * @param similarity_mode Whether the score should be expressed in similarity (true) or distance (false).
 * @param address A pointer, aligned on a 16 bits boundary, on an allocated int array where the initial values for the alignment length will be stored.
 * @param LCSmin The minimum length of the LCS to be above the chosen threshold, as computed by calculateLCSmin().
 * @param lcs_length A pointer on the int where the LCS length will be stored.
 * @param ali_length A pointer on the int where the alignment length will be stored.
 *
 * @returns The alignment score (normalized according to the parameters).
 *
 * @since 2012
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 */
double sse_banded_lcs_align(int16_t* seq1, int16_t* seq2, int l1, int l2, bool normalize, int reference, bool similarity_mode, int16_t* address, int LCSmin, int* lcs_length, int* ali_length);



/************************************************************************
 *
 * D E F I N I T I O N   O F   T H E   P R I V A T E   F U N C T I O N S
 *
 ************************************************************************/


static void  printreg(__m128i r)
{
	int16_t a0,a1,a2,a3,a4,a5,a6,a7;

	a0= _MM_EXTRACT_EPI16(r,0);
	a1= _MM_EXTRACT_EPI16(r,1);
	a2= _MM_EXTRACT_EPI16(r,2);
	a3= _MM_EXTRACT_EPI16(r,3);
	a4= _MM_EXTRACT_EPI16(r,4);
	a5= _MM_EXTRACT_EPI16(r,5);
	a6= _MM_EXTRACT_EPI16(r,6);
	a7= _MM_EXTRACT_EPI16(r,7);

fprintf(stderr, "a00 :-> %7d  %7d  %7d  %7d "
		" %7d  %7d  %7d  %7d "
		"\n"
		, a0,a1,a2,a3,a4,a5,a6,a7
		);
}


static inline int extract_reg(__m128i r, int p)
{
	switch (p) {
	case 0: return(_MM_EXTRACT_EPI16(r,0));
	case 1: return(_MM_EXTRACT_EPI16(r,1));
	case 2: return(_MM_EXTRACT_EPI16(r,2));
	case 3: return(_MM_EXTRACT_EPI16(r,3));
	case 4: return(_MM_EXTRACT_EPI16(r,4));
	case 5: return(_MM_EXTRACT_EPI16(r,5));
	case 6: return(_MM_EXTRACT_EPI16(r,6));
	case 7: return(_MM_EXTRACT_EPI16(r,7));
	}
	return(0);
}


void sse_banded_align_lcs_and_ali_len(int16_t* seq1, int16_t* seq2, int l1, int l2, int bandLengthLeft, int bandLengthTotal, int16_t* address, int* lcs_length, int* ali_length)
{
	register int j;
	int k1, k2;
	int max, diff;
	int l_reg, l_loc;
	int line;
	int numberOfRegistersPerLine;
	int numberOfRegistersFor3Lines;

	bool even_line;
	bool odd_line;
	bool even_BLL;
	bool odd_BLL;

	um128*  SSEregisters;
	um128*  p_diag;
	um128*  p_gap1;
	um128*  p_gap2;
	um128*  p_diag_j;
	um128*  p_gap1_j;
	um128*  p_gap2_j;
	um128   current;

	um128*  l_ali_SSEregisters;
	um128*  p_l_ali_diag;
	um128*  p_l_ali_gap1;
	um128*  p_l_ali_gap2;
	um128*  p_l_ali_diag_j;
	um128*  p_l_ali_gap1_j;
	um128*  p_l_ali_gap2_j;
	um128   l_ali_current;

	um128  nucs1;
	um128  nucs2;
	um128  scores;

	um128 boolean_reg;

	// Initialisations

	odd_BLL = bandLengthLeft & 1;
	even_BLL  = !odd_BLL;

	max = INT16_MAX - l1;

	numberOfRegistersPerLine = bandLengthTotal / 8;
	numberOfRegistersFor3Lines = 3 * numberOfRegistersPerLine;

	SSEregisters = (um128*) calloc(numberOfRegistersFor3Lines * 2, sizeof(um128));
	l_ali_SSEregisters = SSEregisters + numberOfRegistersFor3Lines;

	// preparer registres SSE

	for (j=0; j<numberOfRegistersFor3Lines; j++)
		l_ali_SSEregisters[j].i = _MM_LOAD_SI128((const __m128i*)(address+j*8));

	p_diag    = SSEregisters;
	p_gap1    = SSEregisters+numberOfRegistersPerLine;
	p_gap2    = SSEregisters+2*numberOfRegistersPerLine;

	p_l_ali_diag    = l_ali_SSEregisters;
	p_l_ali_gap1    = l_ali_SSEregisters+numberOfRegistersPerLine;
	p_l_ali_gap2    = l_ali_SSEregisters+2*numberOfRegistersPerLine;

	// Loop on diagonals = 'lines' :
	for (line=2; line <= l1+l2; line++)
	{
		odd_line = line & 1;
		even_line  = !odd_line;

		// loop on the registers of a line :
		for (j=0; j < numberOfRegistersPerLine; j++)
		{
			p_diag_j       = p_diag+j;
			p_gap1_j       = p_gap1+j;
			p_gap2_j       = p_gap2+j;
			p_l_ali_diag_j = p_l_ali_diag+j;
			p_l_ali_gap1_j = p_l_ali_gap1+j;
			p_l_ali_gap2_j = p_l_ali_gap2+j;

		// comparing nucleotides for diagonal scores :

			// k1 = position of the 1st nucleotide to align for seq1 and k2 = position of the 1st nucleotide to align for seq2
			if (odd_line && odd_BLL)
				k1 = (line / 2) + ((bandLengthLeft+1) / 2) - j*8;
			else
				k1 = (line / 2) + (bandLengthLeft/2) - j*8;

			k2 = line - k1 - 1;

			nucs1.i = _MM_LOADU_SI128((const __m128i*)(seq1+l1-k1));
			nucs2.i = _MM_LOADU_SI128((const __m128i*)(seq2+k2));

//			if (print)
//			{
//				fprintf(stderr, "\nnucs, r %d, k1 = %d, k2 = %d\n", j, k1, k2);
//				printreg(nucs1.i);
//				printreg(nucs2.i);
//			}

		// computing diagonal score :
			scores.i = _MM_AND_SI128(_MM_CMPEQ_EPI16(nucs1.i, nucs2.i), _MM_SET1_EPI16(1));
			current.i = _MM_ADDS_EPU16(p_diag_j->i, scores.i);

		// Computing alignment length

			l_ali_current.i = p_l_ali_diag_j->i;
			boolean_reg.i = _MM_CMPGT_EPI16(p_gap1_j->i, current.i);
			l_ali_current.i = _MM_OR_SI128(
								_MM_AND_SI128(p_l_ali_gap1_j->i, boolean_reg.i),
								_MM_ANDNOT_SI128(boolean_reg.i, l_ali_current.i));
			current.i = _MM_OR_SI128(
							_MM_AND_SI128(p_gap1_j->i, boolean_reg.i),
							_MM_ANDNOT_SI128(boolean_reg.i, current.i));
			boolean_reg.i = _MM_AND_SI128(
								_MM_CMPEQ_EPI16(p_gap1_j->i, current.i),
								_MM_CMPLT_EPI16(p_l_ali_gap1_j->i, l_ali_current.i));
			l_ali_current.i = _MM_OR_SI128(
								_MM_AND_SI128(p_l_ali_gap1_j->i, boolean_reg.i),
								_MM_ANDNOT_SI128(boolean_reg.i, l_ali_current.i));
			current.i = _MM_OR_SI128(
							_MM_AND_SI128(p_gap1_j->i, boolean_reg.i),
							_MM_ANDNOT_SI128(boolean_reg.i, current.i));
			boolean_reg.i = _MM_CMPGT_EPI16(p_gap2_j->i, current.i);
			l_ali_current.i = _MM_OR_SI128(
								_MM_AND_SI128(p_l_ali_gap2_j->i, boolean_reg.i),
								_MM_ANDNOT_SI128(boolean_reg.i, l_ali_current.i));
			current.i = _MM_OR_SI128(
							_MM_AND_SI128(p_gap2_j->i, boolean_reg.i),
							_MM_ANDNOT_SI128(boolean_reg.i, current.i));
			boolean_reg.i = _MM_AND_SI128(
								_MM_CMPEQ_EPI16(p_gap2_j->i, current.i),
								_MM_CMPLT_EPI16(p_l_ali_gap2_j->i, l_ali_current.i));
			l_ali_current.i = _MM_OR_SI128(
								_MM_AND_SI128(p_l_ali_gap2_j->i, boolean_reg.i),
								_MM_ANDNOT_SI128(boolean_reg.i, l_ali_current.i));
			current.i = _MM_OR_SI128(
							_MM_AND_SI128(p_gap2_j->i, boolean_reg.i),
							_MM_ANDNOT_SI128(boolean_reg.i, current.i));

//			if (print)
//			{
//				fprintf(stderr, "\nline = %d", line);
//				fprintf(stderr, "\nDiag, r %d : ", j);
//				printreg((*(p_diag_j)).i);
//				fprintf(stderr, "Gap1      : ");
//				printreg((*(p_gap1_j)).i);
//				fprintf(stderr, "Gap2      : ");
//				printreg((*(p_gap2_j)).i);
//				fprintf(stderr, "current   : ");
//				printreg(current.i);
//				fprintf(stderr, "L ALI\nDiag  r %d : ", j);
//				printreg((*(p_l_ali_diag_j)).i);
//				fprintf(stderr, "Gap1      : ");
//				printreg((*(p_l_ali_gap1_j)).i);
//				fprintf(stderr, "Gap2      : ");
//				printreg((*(p_l_ali_gap2_j)).i);
//				fprintf(stderr, "current   : ");
//				printreg(l_ali_current.i);
//			}

		// diag = gap1 and gap1 = current
			p_diag_j->i = p_gap1_j->i;
			p_gap1_j->i = current.i;

		// l_ali_diag = l_ali_gap1 and l_ali_gap1 = l_ali_current+1
			p_l_ali_diag_j->i = p_l_ali_gap1_j->i;
			p_l_ali_gap1_j->i = _MM_ADD_EPI16(l_ali_current.i, _MM_SET1_EPI16(1));
		}

		// shifts for gap2, to do only once all the registers of a line have been computed     Copier gap2 puis le charger depuis la copie?

		for (j=0; j < numberOfRegistersPerLine; j++)
		{
			if ((odd_line && even_BLL) || (even_line && odd_BLL))
			{
				p_gap2[j].i       = _MM_LOADU_SI128((const __m128i*)((p_gap1[j].s16)-1));
				p_l_ali_gap2[j].i = _MM_LOADU_SI128((const __m128i*)((p_l_ali_gap1[j].s16)-1));
				if (j == 0)
				{
					p_gap2[j].i = _MM_INSERT_EPI16(p_gap2[j].i, 0, 0);
					p_l_ali_gap2[j].i = _MM_INSERT_EPI16(p_l_ali_gap2[j].i, max, 0);
				}
			}
			else
			{
				p_gap2[j].i       = _MM_LOADU_SI128((const __m128i*)(p_gap1[j].s16+1));
				p_l_ali_gap2[j].i = _MM_LOADU_SI128((const __m128i*)(p_l_ali_gap1[j].s16+1));
				if (j == numberOfRegistersPerLine - 1)
				{
					p_gap2[j].i = _MM_INSERT_EPI16(p_gap2[j].i, 0, 7);
					p_l_ali_gap2[j].i = _MM_INSERT_EPI16(p_l_ali_gap2[j].i, max, 7);
				}
			}
		}
		// end shifts for gap2

	}

/*  /// Recovering LCS and alignment lengths  \\\  */

	// finding the location of the results in the registers :
	diff = l1-l2;
	if ((diff & 1) && odd_BLL)
		l_loc = (int) floor((double)(bandLengthLeft) / (double)2) - floor((double)(diff) / (double)2);
	else
		l_loc = (int) floor((double)(bandLengthLeft) / (double)2) - ceil((double)(diff) / (double)2);

	l_reg = (int)floor((double)l_loc/(double)8.0);

//	if (print)
//		fprintf(stderr, "\nl_reg = %d, l_loc = %d\n", l_reg, l_loc);

	l_loc = l_loc - l_reg*8;

	// extracting the results from the registers :
	*lcs_length = extract_reg(p_gap1[l_reg].i, l_loc);
	*ali_length = extract_reg(p_l_ali_gap1[l_reg].i, l_loc) - 1;

	// freeing the registers
	free(SSEregisters);
}


void sse_banded_align_just_lcs(int16_t* seq1, int16_t* seq2, int l1, int l2, int bandLengthLeft, int bandLengthTotal, int* lcs_length)
{
	register int j;
	int k1, k2;
	int diff;
	int l_reg, l_loc;
	int line;
	int numberOfRegistersPerLine;
	int numberOfRegistersFor3Lines;

	bool even_line;
	bool odd_line;
	bool even_BLL;
	bool odd_BLL;

	um128*  SSEregisters;
	um128*  p_diag;
	um128*  p_gap1;
	um128*  p_gap2;
	um128*  p_diag_j;
	um128*  p_gap1_j;
	um128*  p_gap2_j;
	um128   current;

	um128  nucs1;
	um128  nucs2;
	um128  scores;

	// Initialisations

	odd_BLL = bandLengthLeft & 1;
	even_BLL = !odd_BLL;

	numberOfRegistersPerLine = bandLengthTotal / 8;
	numberOfRegistersFor3Lines   = 3 * numberOfRegistersPerLine;

	SSEregisters = malloc(numberOfRegistersFor3Lines * sizeof(um128));
	if (SSEregisters == NULL)
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating memory for SSE registers for LCS alignment");
	}

	// preparer registres SSE

	for (j=0; j<numberOfRegistersFor3Lines; j++)
		(*(SSEregisters+j)).i       = _MM_SETZERO_SI128();

	p_diag    = SSEregisters;
	p_gap1    = SSEregisters+numberOfRegistersPerLine;
	p_gap2    = SSEregisters+2*numberOfRegistersPerLine;

	// Loop on diagonals = 'lines' :
	for (line=2; line <= l1+l2; line++)
	{
		odd_line = line & 1;
		even_line  = !odd_line;

		// loop on the registers of a line :
		for (j=0; j < numberOfRegistersPerLine; j++)
		{
			p_diag_j = p_diag+j;
			p_gap1_j = p_gap1+j;
			p_gap2_j = p_gap2+j;

		// comparing nucleotides for diagonal scores :

			// k1 = position of the 1st nucleotide to align for seq1 and k2 = position of the 1st nucleotide to align for seq2
			if (odd_line && odd_BLL)
				k1 = (line / 2) + ((bandLengthLeft+1) / 2) - j*8;
			else
				k1 = (line / 2) + (bandLengthLeft/2) - j*8;

			k2 = line - k1 - 1;

			nucs1.i = _MM_LOADU_SI128((const __m128i*)(seq1+l1-k1));
			nucs2.i = _MM_LOADU_SI128((const __m128i*)(seq2+k2));

		// computing diagonal score :
			scores.i = _MM_AND_SI128(_MM_CMPEQ_EPI16(nucs1.i, nucs2.i), _MM_SET1_EPI16(1));
			current.i = _MM_ADDS_EPU16((*(p_diag_j)).i, scores.i);

		// current = max(gap1, current)
			current.i = _MM_MAX_EPI16((*(p_gap1_j)).i, current.i);

		// current  = max(gap2, current)
			current.i = _MM_MAX_EPI16((*(p_gap2_j)).i, current.i);

		// diag = gap1 and gap1 = current
			(*(p_diag_j)).i = (*(p_gap1_j)).i;
			(*(p_gap1_j)).i = current.i;
		}

		// shifts for gap2, to do only once all the registers of a line have been computed

			for (j=0; j < numberOfRegistersPerLine; j++)
			{
				if ((odd_line && even_BLL) || (even_line && odd_BLL))
				{
					(*(p_gap2+j)).i = _MM_LOADU_SI128((const __m128i*)(((*(p_gap1+j)).s16)-1));
					if (j == 0)
					{
						(*(p_gap2+j)).i = _MM_INSERT_EPI16((*(p_gap2+j)).i, 0, 0);
					}
				}
				else
				{
					(*(p_gap2+j)).i = _MM_LOADU_SI128((const __m128i*)(((*(p_gap1+j)).s16)+1));
					if (j == numberOfRegistersPerLine - 1)
					{
						(*(p_gap2+j)).i = _MM_INSERT_EPI16((*(p_gap2+j)).i, 0, 7);
					}
				}
			}
		// end shifts for gap2
	}

/*  /// Recovering LCS and alignment lengths  \\\  */

	// finding the location of the results in the registers :
	diff = l1-l2;
	if ((diff & 1) && odd_BLL)
		l_loc = (int) floor((double)(bandLengthLeft) / (double)2) - floor((double)(diff) / (double)2);
	else
		l_loc = (int) floor((double)(bandLengthLeft) / (double)2) - ceil((double)(diff) / (double)2);

	l_reg = (int)floor((double)l_loc/(double)8.0);
	//fprintf(stderr, "\nl_reg = %d, l_loc = %d\n", l_reg, l_loc);
	l_loc = l_loc - l_reg*8;

	// extracting LCS from the registers :
	*lcs_length = extract_reg((*(p_gap1+l_reg)).i, l_loc);

	// freeing the registers
	free(SSEregisters);
}


int calculateLeftBandLength(int lmax, int LCSmin)
{
	return (lmax - LCSmin);
}


int calculateRightBandLength(int lmin, int LCSmin)
{
	return (lmin - LCSmin);
}


int calculateSSEBandLength(int bandLengthRight, int bandLengthLeft)
{
	int bandLengthTotal= (double)(bandLengthRight + bandLengthLeft) / 2.0 + 1.0;

	return (bandLengthTotal & (~ (int)7)) + (( bandLengthTotal & (int)7) ? 8:0); // Calcule le multiple de 8 superieur
}


int calculateSizeToAllocate(int maxLen, int LCSmin)
{
	int size;

	size = calculateLeftBandLength(maxLen, LCSmin);

	size *=  2;
	size  =  (size & (~ (int)7)) + ((size & (int)7) ? 8:0); // Closest greater 8 multiple
	size *=  3;
	size +=  16;

	return(size*sizeof(int16_t));
}


void iniSeq(int16_t* seq, int size, int16_t iniValue)
{
	int16_t* target = seq;
	int16_t* end = target + (size_t)size;

	for (; target < end; target++)
		*target = iniValue;
}


void putSeqInSeq(int16_t* seq, char* s, int l, bool reverse)
{
	int16_t *target=seq;
	int16_t *end = target + (size_t)l;
	char    *source=s;

	if (reverse)
		for (source=s + (size_t)l-1; target < end; target++, source--)
			*target=*source;
	else
		for (; target < end; source++,target++)
			*target=*source;
}


void putBlobInSeq(int16_t* seq, Obi_blob_p b, int l, bool reverse)
{
	size_t  i;
	uint8_t shift;
	uint8_t mask;
	uint8_t nuc;

	int16_t* target = seq;
	int16_t* end = target + (size_t) l;

	if (reverse)
	{
		for (i = l-1; target < end; target++, i--)
		{
			shift = 6 - 2*(i % 4);
			mask = NUC_MASK_2B << shift;
			nuc = (b->value[i/4] & mask) >> shift;

			*target = (int16_t)nuc+1;	// +1 because nucleotide can't be == 0 (0 is a default value used to initialize some registers)
		}
	}
	else
	{
		for (i=0; target < end; target++, i++)
		{
			shift = 6 - 2*(i % 4);
			mask = NUC_MASK_2B << shift;
			nuc = (b->value[i/4] & mask) >> shift;

			*target = (int16_t)nuc+1;	// +1 because nucleotide can't be == 0 (0 is a default value used to initialize some registers)
		}
	}
}


void initializeAddressWithGaps(int16_t* address, int bandLengthTotal, int bandLengthLeft, int lmax)
{
	int i;
	int address_00, x_address_10, address_01, address_01_shifted;
	int numberOfRegistersPerLine;
	int bm;
	int value=INT16_MAX-lmax;

	numberOfRegistersPerLine = bandLengthTotal / 8;
	bm = bandLengthLeft%2;

	for (i=0; i < (3*numberOfRegistersPerLine*8); i++)
		address[i] = value;


	// 0,0 set to 1 and 0,1 and 1,0 set to 2

	address_00   = bandLengthLeft / 2;

	x_address_10 = address_00 + bm - 1;
	address_01   = numberOfRegistersPerLine*8 + x_address_10;

	address_01_shifted = numberOfRegistersPerLine*16 + address_00 - bm;

	// fill address_00, address_01,+1, address_01_shifted,+1

	address[address_00] = 1;
	address[address_01] = 2;
	address[address_01+1] = 2;
	address[address_01_shifted] = 2;
	address[address_01_shifted+1] = 2;
}


double sse_banded_lcs_align(int16_t* seq1, int16_t* seq2, int l1, int l2, bool normalize, int reference, bool similarity_mode, int16_t* address, int LCSmin, int* lcs_length, int* ali_length)
{
	double id;
	int bandLengthRight, bandLengthLeft, bandLengthTotal;

	bandLengthLeft = calculateLeftBandLength(l1, LCSmin);
	bandLengthRight = calculateRightBandLength(l2, LCSmin);

//	fprintf(stderr, "\nBLL = %d, BLR = %d, LCSmin = %d\n", bandLengthLeft, bandLengthRight, LCSmin);

	bandLengthTotal = calculateSSEBandLength(bandLengthRight, bandLengthLeft);

//	fprintf(stderr, "\nBLT = %d\n", bandLengthTotal);

	if ((reference == ALILEN) && (normalize || !similarity_mode))
	{
		initializeAddressWithGaps(address, bandLengthTotal, bandLengthLeft, l1);
		sse_banded_align_lcs_and_ali_len(seq1, seq2, l1, l2, bandLengthLeft, bandLengthTotal, address, lcs_length, ali_length);
	}
	else
		sse_banded_align_just_lcs(seq1, seq2, l1, l2, bandLengthLeft, bandLengthTotal, lcs_length);

	id = (double) *lcs_length;

//	fprintf(stderr, "\nid before normalizations = %f", id);

	//fprintf(stderr, "\nlcs = %f, ali length = %d\n", id, ali_length);

	if (!similarity_mode && !normalize)
		switch(reference) {
			case ALILEN: id = *ali_length - id;
						break;
			case MAXLEN: id = l1 - id;
						break;
			case MINLEN: id = l2 - id;
		}

//	fprintf(stderr, "\n2>>> %f, %d\n", id, ali_length);
	if (normalize)
		switch(reference) {
			case ALILEN: id = id / (double) *ali_length;
						break;
			case MAXLEN: id = id / (double) l1;
						break;
			case MINLEN: id = id / (double) l2;
		}

//	fprintf(stderr, "\nid = %f\n", id);
	return(id);
}



/**********************************************************************
 *
 * D E F I N I T I O N   O F   T H E   P U B L I C   F U N C T I O N S
 *
 **********************************************************************/


int calculateLCSmin(int lmax, int lmin, double threshold, bool normalize, int reference, bool similarity_mode)
{
	int LCSmin;

	if (threshold > 0)
	{
		if (normalize)
		{
			if (reference == MINLEN)
				LCSmin = threshold*lmin;
			else 		// ref = maxlen or alilen
				LCSmin = threshold*lmax;
		}
		else if (similarity_mode)
			LCSmin = threshold;
		else if (reference == MINLEN) // not similarity_mode
			LCSmin = lmin - threshold;
		else	// not similarity_mode and ref = maxlen or alilen
			LCSmin = lmax - threshold;
	}
	else
		LCSmin = 0;

	return(LCSmin);
}


double generic_sse_banded_lcs_align(char* seq1, char* seq2, double threshold, bool normalize, int reference, bool similarity_mode, int* lcs_length, int* ali_length)
{
	double   id;
	int      l1, l2;
	int      lmax, lmin;
	int      sizeToAllocateForBand, sizeToAllocateForSeqs;
	int	     maxBLL;
	int      LCSmin;
	int      shift;
	int16_t* address;
	int16_t* iseq1;
	int16_t* iseq2;

	address = NULL;

	l1 = strlen(seq1);
	l2 = strlen(seq2);

	if (l1 > l2)
	{
		lmax = l1;
		lmin = l2;
	}
	else
	{
		lmax = l2;
		lmin = l1;
	}

	// Check that the sequences are not greater than what can be aligned using the 16 bits registers (as the LCS and alignment lengths are kept on 16 bits)
	if (lmax > SHRT_MAX)
	{
		obi_set_errno(OBI_ALIGN_ERROR);
		obidebug(1, "\nError: can not align sequences longer than %d (as the LCS and alignment lengths are kept on 16 bits)", SHRT_MAX);
		return 0; 		// TODO DOUBLE_MIN to flag error
	}

	// If the score is expressed as a normalized distance, get the corresponding identity
	if (!similarity_mode && normalize)
		threshold = 1.0 - threshold;

	// Calculate the minimum LCS length corresponding to the threshold
	LCSmin = calculateLCSmin(lmax, lmin, threshold, normalize, reference, similarity_mode);

	// Allocate space for matrix band if the alignment length must be computed
	if ((reference == ALILEN) && (normalize || !similarity_mode)) // cases in which alignment length must be computed
	{
		sizeToAllocateForBand = calculateSizeToAllocate(lmax, LCSmin);
		address = obi_get_memory_aligned_on_16(sizeToAllocateForBand, &shift);
		if (address == NULL)
		{
			obi_set_errno(OBI_MALLOC_ERROR);
			obidebug(1, "\nError getting a memory address aligned on 16 bytes boundary");
			return 0;	// TODO DOUBLE_MIN
		}
	}

	// Allocate space for the int16_t arrays representing the sequences
	maxBLL = calculateLeftBandLength(lmax, LCSmin);
	sizeToAllocateForSeqs = 2*maxBLL+lmax;
	iseq1 = (int16_t*) malloc(sizeToAllocateForSeqs*sizeof(int16_t));
	iseq2 = (int16_t*) malloc(sizeToAllocateForSeqs*sizeof(int16_t));
	if ((iseq1 == NULL) || (iseq2 == NULL))
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating memory for integer arrays to use in LCS alignment");
		return 0; 	// TODO DOUBLE_MIN
	}

	// Initialize the int arrays
	iniSeq(iseq1, (2*maxBLL)+lmax, 0);
	iniSeq(iseq2, (2*maxBLL)+lmax, 255);

	// Shift addresses to where the sequences have to be put
	iseq1 = iseq1+maxBLL;
	iseq2 = iseq2+maxBLL;

	// Put the DNA sequences in the int arrays. Longest sequence must be first argument of sse_align function
	if (l2 > l1)
	{
		putSeqInSeq(iseq1, seq2, l2, true);
		putSeqInSeq(iseq2, seq1, l1, false);
		// Compute alignment
		id = sse_banded_lcs_align(iseq1, iseq2, l2, l1, normalize, reference, similarity_mode, address, LCSmin, lcs_length, ali_length);
	}
	else
	{
		putSeqInSeq(iseq1, seq1, l1, true);
		putSeqInSeq(iseq2, seq2, l2, false);
		// Compute alignment
		id = sse_banded_lcs_align(iseq1, iseq2, l1, l2, normalize, reference, similarity_mode, address, LCSmin, lcs_length, ali_length);
	}

	// Free allocated elements
	if (address != NULL)
		free(address-shift);
	free(iseq1-maxBLL);
	free(iseq2-maxBLL);

	return(id);
}


double obiblob_sse_banded_lcs_align(Obi_blob_p seq1, Obi_blob_p seq2, double threshold, bool normalize, int reference, bool similarity_mode, int* lcs_length, int* ali_length)
{
	double   id;
	int      l1, l2;
	int      lmax, lmin;
	int      sizeToAllocateForBand, sizeToAllocateForSeqs;
	int	     maxBLL;
	int      LCSmin;
	int      shift;
	int16_t* address;
	int16_t* iseq1;
	int16_t* iseq2;

	address = NULL;

	l1 = seq1->length_decoded_value;
	l2 = seq2->length_decoded_value;

	if (l1 > l2)
	{
		lmax = l1;
		lmin = l2;
	}
	else
	{
		lmax = l2;
		lmin = l1;
	}

	// Check that the sequences are not greater than what can be aligned using the 16 bits registers (as the LCS and alignment lengths are kept on 16 bits)
	if (lmax > SHRT_MAX)
	{
		obi_set_errno(OBI_ALIGN_ERROR);
		obidebug(1, "\nError: can not align sequences longer than %d (as the LCS and alignment lengths are kept on 16 bits)", SHRT_MAX);
		return 0; 		// TODO DOUBLE_MIN to flag error
	}

	// If the score is expressed as a normalized distance, get the corresponding identity
	if (!similarity_mode && normalize)
		threshold = 1.0 - threshold;

	// Calculate the minimum LCS length corresponding to the threshold
	LCSmin = calculateLCSmin(lmax, lmin, threshold, normalize, reference, similarity_mode);

	// Allocate space for matrix band if the alignment length must be computed
	if ((reference == ALILEN) && (normalize || !similarity_mode)) // cases in which alignment length must be computed
	{
		sizeToAllocateForBand = calculateSizeToAllocate(lmax, LCSmin);
		address = obi_get_memory_aligned_on_16(sizeToAllocateForBand, &shift);
		if (address == NULL)
		{
			obi_set_errno(OBI_MALLOC_ERROR);
			obidebug(1, "\nError getting a memory address aligned on a 16 bits boundary");
			return 0;	// TODO DOUBLE_MIN to flag error
		}
	}

	// Allocate space for the int16_t arrays representing the sequences
	maxBLL = calculateLeftBandLength(lmax, LCSmin);
	sizeToAllocateForSeqs = 2*maxBLL+lmax;
	iseq1 = (int16_t*) malloc(sizeToAllocateForSeqs*sizeof(int16_t));
	iseq2 = (int16_t*) malloc(sizeToAllocateForSeqs*sizeof(int16_t));
	if ((iseq1 == NULL) || (iseq2 == NULL))
	{
		obi_set_errno(OBI_MALLOC_ERROR);
		obidebug(1, "\nError allocating memory for integer arrays to use in LCS alignment");
		return 0; 	// TODO DOUBLE_MIN
	}

	// Initialize the int arrays
	iniSeq(iseq1, (2*maxBLL)+lmax, 0);
	iniSeq(iseq2, (2*maxBLL)+lmax, 255);

	// Shift addresses to where the sequences have to be put
	iseq1 = iseq1+maxBLL;
	iseq2 = iseq2+maxBLL;

	// Put the DNA sequences in the int arrays. Longest sequence must be first argument of sse_align function
	if (l2 > l1)
	{
		putBlobInSeq(iseq1, seq2, l2, true);
		putBlobInSeq(iseq2, seq1, l1, false);
		// Compute alignment
		id = sse_banded_lcs_align(iseq1, iseq2, l2, l1, normalize, reference, similarity_mode, address, LCSmin, lcs_length, ali_length);
	}
	else
	{
		putBlobInSeq(iseq1, seq1, l1, true);
		putBlobInSeq(iseq2, seq2, l2, false);
		// Compute alignment
		id = sse_banded_lcs_align(iseq1, iseq2, l1, l2, normalize, reference, similarity_mode, address, LCSmin, lcs_length, ali_length);
	}

	// Free allocated elements
	if (address != NULL)
		free(address-shift);
	free(iseq1-maxBLL);
	free(iseq2-maxBLL);

	return(id);
}

