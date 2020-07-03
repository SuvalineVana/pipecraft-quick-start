#include <stdio.h>
#include <math.h>
#include <stdbool.h>

#include "upperband.h"
#include "_sse.h"
#include "sse_banded_LCS_alignment.h"
#include "obidmscolumn.h"
#include "obiview.h"



inline static uchar_v hash4m128(uchar_v frag)
{
	uchar_v words;

	vUInt8 mask_03= _MM_SET1_EPI8(0x03);        // charge le registre avec 16x le meme octet
	vUInt8 mask_FC= _MM_SET1_EPI8(0xFC);

	frag.m = _MM_SRLI_EPI64(frag.m,1);         // shift logic a droite sur 2 x 64 bits
	frag.m = _MM_AND_SI128(frag.m,mask_03);    // and sur les 128 bits


	words.m= _MM_SLLI_EPI64(frag.m,2);
	words.m= _MM_AND_SI128(words.m,mask_FC);
	frag.m = _MM_SRLI_SI128(frag.m,1);
	words.m= _MM_OR_SI128(words.m,frag.m);

	words.m= _MM_SLLI_EPI64(words.m,2);
	words.m= _MM_AND_SI128(words.m,mask_FC);
	frag.m = _MM_SRLI_SI128(frag.m,1);
	words.m= _MM_OR_SI128(words.m,frag.m);

	words.m= _MM_SLLI_EPI64(words.m,2);
	words.m= _MM_AND_SI128(words.m,mask_FC);
	frag.m = _MM_SRLI_SI128(frag.m,1);
	words.m= _MM_OR_SI128(words.m,frag.m);

	return words;
}

#ifdef __SSE2__

inline static int anyzerom128(vUInt8 data)
{
	vUInt8 mask_00= _MM_SETZERO_SI128();
	uint64_v tmp;
	tmp.m = _MM_CMPEQ_EPI8(data,mask_00);
	return (int)(tmp.c[0]!=0 || tmp.c[1]!=0);
}

#else

inline static int anyzerom128(vUInt8 data)
{
	int i;
	um128 tmp;
	tmp.i = data;
	for (i=0;i<8;i++)
		if (tmp.s8[i]==0)
			return 1;
	return 0;
}

#endif


inline static void dumpm128(unsigned short *table,vUInt8 data)
{
	memcpy(table,&data,16);
}


/**
 * Compute 4mer occurrence table from a DNA sequence
 *
 *	sequence : a pointer to the null terminated nuc sequence
 *	table    : a pointer to a 256 cells unisgned char table for
 *	           storing the occurrence table
 *	count    : pointer to an int value used as a return value
 *	           containing the global word counted
 *
 *	returns the number of words observed in the sequence with a
 *	count greater than 255.
 */
int build_table(const char* sequence, unsigned char *table, int *count)
{
	int overflow = 0;
	int wc=0;
	int i;
	vUInt8 mask_00= _MM_SETZERO_SI128();

	uchar_v frag;
	uchar_v words;
	uchar_v zero;

	char* s;

	s=(char*)sequence;

	memset(table,0,256*sizeof(unsigned char));

	// encode ascii sequence with  A : 00 C : 01  T: 10   G : 11

	for(frag.m=_MM_LOADU_SI128((vUInt8*)s);
		! anyzerom128(frag.m);
		s+=12,frag.m=_MM_LOADU_SI128((vUInt8*)s))
	{
		words= hash4m128(frag);

	//    printf("%d %d %d %d\n",words.c[0],words.c[1],words.c[2],words.c[3]);

		if (table[words.c[0]]<255)  table[words.c[0]]++;  else overflow++;
		if (table[words.c[1]]<255)  table[words.c[1]]++;  else overflow++;
		if (table[words.c[2]]<255)  table[words.c[2]]++;  else overflow++;
		if (table[words.c[3]]<255)  table[words.c[3]]++;  else overflow++;
		if (table[words.c[4]]<255)  table[words.c[4]]++;  else overflow++;
		if (table[words.c[5]]<255)  table[words.c[5]]++;  else overflow++;
		if (table[words.c[6]]<255)  table[words.c[6]]++;  else overflow++;
		if (table[words.c[7]]<255)  table[words.c[7]]++;  else overflow++;
		if (table[words.c[8]]<255)  table[words.c[8]]++;  else overflow++;
		if (table[words.c[9]]<255)  table[words.c[9]]++;  else overflow++;
		if (table[words.c[10]]<255) table[words.c[10]]++; else overflow++;
		if (table[words.c[11]]<255) table[words.c[11]]++; else overflow++;

		wc+=12;
	}

	zero.m=_MM_CMPEQ_EPI8(frag.m,mask_00);
	//printf("frag=%d %d %d %d\n",frag.c[0],frag.c[1],frag.c[2],frag.c[3]);
	//printf("zero=%d %d %d %d\n",zero.c[0],zero.c[1],zero.c[2],zero.c[3]);
	words = hash4m128(frag);

	if (zero.c[0]+zero.c[1]+zero.c[2]+zero.c[3]==0)
	{
		for(i=0;zero.c[i+3]==0;i++,wc++)
		{
			if (table[words.c[i]]<255)
				(table[words.c[i]])++;
			else
				(overflow)++;
		}
	}
	if (count)
		*count=wc;
	return overflow;
}


static inline vUInt16 partial_min_sum(vUInt8 ft1,vUInt8 ft2)
{
	vUInt8   mini;
	vUInt16  minilo;
	vUInt16  minihi;
	vUInt8 mask_00= _MM_SETZERO_SI128();

	mini      = _MM_MIN_EPU8(ft1,ft2);
	minilo    = _MM_UNPACKLO_EPI8(mini,mask_00);
	minihi    = _MM_UNPACKHI_EPI8(mini,mask_00);

	return _MM_ADDS_EPU16(minilo,minihi);
}


int compare_tables(unsigned char *t1, int over1, unsigned char* t2,  int over2)
{
	vUInt8   ft1;
	vUInt8   ft2;
	vUInt8  *table1=(vUInt8*)t1;
	vUInt8  *table2=(vUInt8*)t2;
	ushort_v summini;
	int      i;
	int      total;

	ft1 = _MM_LOADU_SI128(table1);
	ft2 = _MM_LOADU_SI128(table2);
	summini.m = partial_min_sum(ft1,ft2);
	table1++;
	table2++;


	for (i=1;i<16;i++,table1++,table2++)
	{
		ft1 = _MM_LOADU_SI128(table1);
		ft2 = _MM_LOADU_SI128(table2);
		summini.m = _MM_ADDS_EPU16(summini.m, partial_min_sum(ft1,ft2));

	}

	// Finishing the sum process

	summini.m = _MM_ADDS_EPU16(summini.m,_MM_SRLI_SI128(summini.m,8)); // sum the 4 firsts with the 4 lasts
	summini.m = _MM_ADDS_EPU16(summini.m,_MM_SRLI_SI128(summini.m,4));

	total = summini.c[0]+summini.c[1];
	total+= (over1 < over2) ? over1:over2;

	return total;
}


int threshold4(int wordcount, double identity)
{
	int error;
	int lmax;

	wordcount+=3;
	error = (int)floor((double)wordcount * ((double)1.0-identity));
	lmax  = (wordcount - error) / (error + 1);
	if (lmax < 4)
		return 0;
	return    (lmax  - 3) \
			* (error + 1) \
			+ ((wordcount - error) % (error + 1));
}


int thresholdLCS4(int32_t reflen, int32_t lcs)
{
	int nbfrag;
	int smin;
	int R;
	int common;

	nbfrag = (reflen - lcs)*2 + 1;
	smin   = lcs/nbfrag;
	R = lcs - smin * nbfrag;
	common = MAX(smin - 2,0) * R + MAX(smin - 3,0) * (nbfrag - R);
	return  common;
}


Kmer_table_p hash_seq_column(Obiview_p view, OBIDMS_column_p seq_col, index_t seq_idx)		// TODO move in another file (obi_lcs.c?)
{
	size_t       i;
	size_t       seq_count;
	int32_t      count;
	Kmer_table_p ktable;
	char*        seq;

	fprintf(stderr,"Building kmer tables...");

	seq_count = (view->infos)->line_count;

	// Allocate memory for the table structure
	ktable = (Kmer_table_p) malloc(sizeof(Kmer_table_t) * seq_count);
	if (ktable == NULL)
		return NULL;

	for (i=0; i < seq_count; i++)
	{
		seq = obi_get_seq_with_elt_idx_and_col_p_in_view(view, seq_col, i, seq_idx);
		if (seq == NULL)
			return NULL;	// TODO or not
		ktable[i].table = malloc(256 * sizeof(unsigned char));
		if (ktable[i].table == NULL)
			return NULL;
		ktable[i].over = build_table(seq, ktable[i].table, &count);
		free(seq);
	}

	fprintf(stderr," : Done\n");

	return ktable;
}


Kmer_table_p hash_two_seq_columns(Obiview_p view1, OBIDMS_column_p seq1_col, index_t seq1_idx,
								  Obiview_p view2, OBIDMS_column_p seq2_col, index_t seq2_idx)
{
	size_t       seq1_count;
	size_t       seq2_count;
	Kmer_table_p ktable1;
	Kmer_table_p ktable2;
	Kmer_table_p ktable;

	seq1_count = (view1->infos)->line_count;
	seq2_count = (view2->infos)->line_count;

	// Build the two tables then concatenate them
	ktable1 = hash_seq_column(view1, seq1_col, seq1_idx);
	if (ktable1 == NULL)
		return NULL;
	ktable2 = hash_seq_column(view2, seq2_col, seq2_idx);
	if (ktable2 == NULL)
		return NULL;

	// Realloc to hold the 2 tables
	ktable = realloc(ktable1, sizeof(Kmer_table_t) * (seq1_count + seq2_count));
	if (ktable == NULL)
	{
		free_kmer_tables(ktable2, seq2_count);
		return NULL;
	}

	// Concatenate
	memcpy(ktable+seq1_count, ktable2, sizeof(Kmer_table_t) * seq2_count);

	// Free copied table
	free(ktable2);

	return ktable;
}


void free_kmer_tables(Kmer_table_p ktable, size_t count)
{
	size_t      i;

	for (i=0; i < count; i++)
		free(ktable[i].table);

	free(ktable);
}


bool is_possible(Kmer_table_p ktable, index_t idx1, index_t idx2, int l1, int l2, double threshold, bool normalize, int reference, bool similarity_mode)
{
	int32_t reflen;
    int32_t lcs;
    int32_t mincount;

    if ((l1 < 12) || (l2 < 12))
    	return true;

    if ((reference==ALILEN) || (reference==MAXLEN))
		reflen = l1;
	else
		reflen = l2;

	if (normalize)
		lcs = (int32_t)ceil((double)reflen * threshold);
	else
	{
		if (! similarity_mode)
			threshold = reflen - threshold;
		lcs = (int32_t) threshold;
	}

	mincount = thresholdLCS4(l1, lcs);

	return compare_tables(ktable[idx1].table, ktable[idx1].over, ktable[idx2].table, ktable[idx2].over) >= mincount;
}


void align_filters(Kmer_table_p ktable, Obi_blob_p seq1, Obi_blob_p seq2, index_t idx1, index_t idx2,
		double threshold, bool normalize, int reference, bool similarity_mode, double* score, int* LCSmin,
		bool can_be_identical)
{	// score takes value -2 if filters are not passed, -1 if filters are passed and >= 0 with max score if the 2 sequences are identical.
	// TODO move to obi_lcs.c?

	int l1;
	int l2;
	l1 = seq1->length_decoded_value;

	*score = -2.0;

	if (can_be_identical)
	{
		if (obi_blob_compare(seq1, seq2) == 0) // seqs are identical: return max score
		{
			if (similarity_mode && normalize)
				*score = 1.0;
			else if (!similarity_mode)
				*score = 0.0;
			else
				*score = l1;
			return;
		}
	}

	else if ((similarity_mode && normalize && (threshold == 1.0)) ||
			(!similarity_mode && (threshold == 0.0)))
	{  // The sequences must be identical but are not
		return;
	}

	if (threshold != 0.0)
	{
		l2 = seq2->length_decoded_value;

		if (l1 >= l2)
		{
			*LCSmin = calculateLCSmin(l1, l2, threshold, normalize, reference, similarity_mode);
			if (l2 >= *LCSmin)
			{
				if (is_possible(ktable, idx1, idx2, l1, l2, threshold, normalize, reference, similarity_mode))		// 4-mers filter
					*score = -1.0;
			}
		}
		else
		{
			*LCSmin = calculateLCSmin(l2, l1, threshold, normalize, reference, similarity_mode);
			if (l1 >= *LCSmin)
			{
				if (is_possible(ktable, idx2, idx1, l2, l1, threshold, normalize, reference, similarity_mode))		// 4-mers filter
					*score = -1.0;
			}
		}
	}
	else
		*LCSmin = 0;
}
