/**
 * @file crc64.h
 * @date March 24th 2016
 * @brief Header file for CRC64 function.
 */

#include <stdint.h>


/**
 * @brief Generates and returns a 64-bit Cyclic Redundancy Check from a
 *        character string s of length l.
 */
uint64_t crc64(const char* s, uint64_t l);
