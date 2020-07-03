
#ifndef UPPERBAND_H_
#define UPPERBAND_H_

// TODO doc

#include <stdbool.h>
#include <stdio.h>

#include "obiblob.h"
#include "obiview.h"
#include "obidmscolumn.h"


typedef struct {
	unsigned char* table;      	// 4mer occurrence table built using the build_table function
	int32_t        over;        // count of 4mers with an occurrence greater than 255 (overflow)
} Kmer_table_t, *Kmer_table_p;


// TODO doc

Kmer_table_p hash_seq_column(Obiview_p view, OBIDMS_column_p seq_col, index_t seq_idx);
Kmer_table_p hash_two_seq_columns(Obiview_p view1, OBIDMS_column_p seq1_col, index_t seq1_idx,
								  Obiview_p view2, OBIDMS_column_p seq2_col, index_t seq2_idx);
void align_filters(Kmer_table_p ktable, Obi_blob_p seq1, Obi_blob_p seq2, index_t idx1, index_t idx2, double threshold, bool normalize, int reference, bool similarity_mode, double* score, int* LCSmin, bool can_be_identical);
void free_kmer_tables(Kmer_table_p ktable, size_t count);

#endif

