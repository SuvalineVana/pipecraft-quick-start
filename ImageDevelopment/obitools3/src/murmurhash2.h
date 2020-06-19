
#ifndef _BLOOM_MURMURHASH2
#define _BLOOM_MURMURHASH2


/**
 * @brief Generates and returns a hash code from a byte array.
 */
unsigned int murmurhash2(const void * key, int len, const unsigned int seed);

#endif
