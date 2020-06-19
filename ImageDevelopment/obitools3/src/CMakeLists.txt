cmake_minimum_required(VERSION 3.9)

set(CMAKE_POSITION_INDEPENDENT_CODE ON)

SET(PYTHONLIB "po" CACHE STRING "Location of the python site-package directory")

project (cobitools3 LANGUAGES C)

set(CMAKE_BUILD_TYPE Release)

include_directories(${CMAKE_CURRENT_SOURCE_DIR})

file(GLOB_RECURSE CSRC "*.c")

add_library(cobitools3 SHARED   obisig.c
                                obierrno.c
								obidms_taxonomy.c
								obiblob_indexer.c
								obi_lcs.c
								obidmscolumn_str.c
								bloom.c
								build_reference_db.c
								obidmscolumn_array.c
								obidmscolumn_idx.c
								obidmscolumn_bool.c
								libjson/json_utils.c
								libjson/cJSON.c
								obidmscolumn_blob.c
								dna_seq_indexer.c
								obi_ecotag.c
								encode.c
								obiavl.c
								sse_banded_LCS_alignment.c
								kmer_similarity.c
								obidmscolumn_qual.c
								obi_clean.c
								utils.c
								uint8_indexer.c
								murmurhash2.c
								obidmscolumn_char.c
								obiview.c
								obidmscolumn_int.c
								linked_list.c
								obiblob.c
								hashtable.c
								obidmscolumn.c
								char_str_indexer.c
								obidmscolumn_float.c
								upperband.c
								crc64.c
								obidmscolumn_seq.c
								obilittlebigman.c
								obidmscolumndir.c
								obidms.c
								obi_ecopcr.c
								libecoPCR/libthermo/nnparams.c
								libecoPCR/ecoapat.c
								libecoPCR/libapat/libstki.c
								libecoPCR/libapat/apat_search.c
								libecoPCR/libapat/apat_parse.c
								libecoPCR/ecodna.c
								libecoPCR/ecoMalloc.c
								libecoPCR/ecoError.c
								obitypes.c
								array_indexer.c)

find_package(OpenMP)
if(OpenMP_C_FOUND)
    target_link_libraries(cobitools3 PUBLIC OpenMP::OpenMP_C)
endif()
					
install(TARGETS cobitools3 DESTINATION ${PYTHONLIB})
								