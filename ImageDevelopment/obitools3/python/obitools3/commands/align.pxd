#cython: language_level=3


cpdef align_columns(bytes dms_n, 
                    bytes input_view_1_n, 
                    bytes output_view_n,
                    bytes input_view_2_n=*,
                    bytes input_column_1_n=*, 
                    bytes input_column_2_n=*,
                    bytes input_elt_1_n=*, 
                    bytes input_elt_2_n=*,
                    bytes id_column_1_n=*, 
                    bytes id_column_2_n=*,
                    double threshold=*, bint normalize=*, 
                    int reference=*, bint similarity_mode=*,
                    bint print_seq=*, bint print_count=*,
                    bytes comments=*,
                    int thread_count=*)