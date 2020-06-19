#ifndef _SSE_H_
#define _SSE_H_

#include <string.h>

#include <inttypes.h>
#ifdef __SSE2__
#include <xmmintrin.h>
#else
typedef long long __m128i __attribute__ ((__vector_size__ (16), __may_alias__));
#endif /* __SSE2__ */

#ifndef MAX
#define MAX(x,y) (((x)>(y)) ? (x):(y))
#define MIN(x,y) (((x)<(y)) ? (x):(y))
#endif

#define ALIGN __attribute__((aligned(16)))
typedef __m128i vUInt8;
typedef __m128i vInt8;

typedef __m128i vUInt16;
typedef __m128i vInt16;

typedef __m128i vUInt64;

typedef union
{
     __m128i i;
     int64_t  s64[ 2];
     int16_t  s16[ 8];
     int8_t   s8 [16];
     uint8_t  u8 [16];
     uint16_t u16[8 ];
	 uint32_t u32[4 ];
     uint64_t u64[2 ];
} um128;

typedef union
    {
	    vUInt8 m;
	    uint8_t c[16];
    } uchar_v;

typedef union
	{
		vUInt16 m;
		uint16_t c[8];
	} ushort_v;

typedef union
	{
		vUInt64 m;
		uint64_t c[2];
	} uint64_v;


#ifdef __SSE2__

static inline int8_t _s2_extract_epi8(__m128i r, const int p)
{
#define ACTIONP(r,x) return _mm_extract_epi16(r,x) & 0xFF
#define ACTIONI(r,x) return _mm_extract_epi16(r,x) >> 8
	switch (p) {
	case  0:  ACTIONP(r,0);
	case  1:  ACTIONI(r,0);
	case  2:  ACTIONP(r,1);
	case  3:  ACTIONI(r,1);
	case  4:  ACTIONP(r,2);
	case  5:  ACTIONI(r,2);
	case  6:  ACTIONP(r,3);
	case  7:  ACTIONI(r,3);
	case  8:  ACTIONP(r,4);
	case  9:  ACTIONI(r,4);
	case 10:  ACTIONP(r,5);
	case 11:  ACTIONI(r,5);
	case 12:  ACTIONP(r,6);
	case 13:  ACTIONI(r,6);
	case 14:  ACTIONP(r,7);
	case 15:  ACTIONI(r,7);
	}
#undef ACTIONP
#undef ACTIONI

	return 0;
}

static inline __m128i _s2_max_epi8(__m128i a, __m128i b)
{
	__m128i mask  = _mm_cmpgt_epi8( a, b );
	a = _mm_and_si128   (a,mask );
	b = _mm_andnot_si128(mask,b);
	return _mm_or_si128(a,b);
}

static inline __m128i _s2_min_epi8(__m128i a, __m128i b)
{
	__m128i mask  = _mm_cmplt_epi8( a, b );
	a = _mm_and_si128   (a,mask );
	b = _mm_andnot_si128(mask,b);
	return _mm_or_si128(a,b);
}

static inline __m128i _s2_insert_epi8(__m128i r, int b, const int p)
{
#define ACTIONP(r,x) return _mm_insert_epi16(r,(_mm_extract_epi16(r,x) & 0xFF00) | (b & 0x00FF),x)
#define ACTIONI(r,x) return _mm_insert_epi16(r,(_mm_extract_epi16(r,x) & 0x00FF) | ((b << 8)& 0xFF00),x)
	switch (p) {
	case  0:  ACTIONP(r,0);
	case  1:  ACTIONI(r,0);
	case  2:  ACTIONP(r,1);
	case  3:  ACTIONI(r,1);
	case  4:  ACTIONP(r,2);
	case  5:  ACTIONI(r,2);
	case  6:  ACTIONP(r,3);
	case  7:  ACTIONI(r,3);
	case  8:  ACTIONP(r,4);
	case  9:  ACTIONI(r,4);
	case 10:  ACTIONP(r,5);
	case 11:  ACTIONI(r,5);
	case 12:  ACTIONP(r,6);
	case 13:  ACTIONI(r,6);
	case 14:  ACTIONP(r,7);
	case 15:  ACTIONI(r,7);
	}
#undef ACTIONP
#undef ACTIONI

	return _mm_setzero_si128();
}

// Fill a SSE Register with 16 time the same 8bits integer value
#define _MM_SET1_EPI8(x)        _mm_set1_epi8(x)
#define _MM_INSERT_EPI8(r,x,i)	_s2_insert_epi8((r),(x),(i))
#define _MM_CMPEQ_EPI8(x,y)     _mm_cmpeq_epi8((x),(y))
#define _MM_CMPGT_EPI8(x,y)     _mm_cmpgt_epi8((x),(y))
#define _MM_CMPLT_EPI8(x,y)     _mm_cmplt_epi8((x),(y))
#define _MM_MAX_EPI8(x,y)       _s2_max_epi8((x),(y))
#define _MM_MIN_EPI8(x,y)       _s2_min_epi8((x),(y))
#define _MM_ADD_EPI8(x,y)       _mm_add_epi8((x),(y))
#define _MM_SUB_EPI8(x,y)       _mm_sub_epi8((x),(y))
#define _MM_EXTRACT_EPI8(r,p)   _s2_extract_epi8((r),(p))

#define _MM_MIN_EPU8(x,y)       _mm_min_epu8((x),(y))

// Fill a SSE Register with 8 time the same 16bits integer value
#define _MM_SET1_EPI16(x)       _mm_set1_epi16(x)

#define _MM_INSERT_EPI16(r,x,i)	_mm_insert_epi16((r),(x),(i))
#define _MM_CMPEQ_EPI16(x,y)    _mm_cmpeq_epi16((x),(y))
#define _MM_CMPGT_EPI16(x,y)    _mm_cmpgt_epi16((x),(y))
#define _MM_CMPGT_EPU16(x,y)    _mm_cmpgt_epu16((x),(y))    // n'existe pas ??
#define _MM_CMPLT_EPI16(x,y)    _mm_cmplt_epi16((x),(y))
#define _MM_MAX_EPI16(x,y)      _mm_max_epi16((x),(y))
#define _MM_MIN_EPI16(x,y)      _mm_min_epi16((x),(y))
#define _MM_ADD_EPI16(x,y)      _mm_add_epi16((x),(y))
#define _MM_SUB_EPI16(x,y)      _mm_sub_epi16((x),(y))
#define _MM_EXTRACT_EPI16(r,p)  _mm_extract_epi16((r),(p))
#define _MM_UNPACKLO_EPI8(a,b)  _mm_unpacklo_epi8((a),(b))
#define _MM_UNPACKHI_EPI8(a,b)  _mm_unpackhi_epi8((a),(b))
#define _MM_ADDS_EPU16(x,y)     _mm_adds_epu16((x),(y))

// Multiplication
#define _MM_MULLO_EPI16(x,y)    _mm_mullo_epi16((x), (y))

#define _MM_SRLI_EPI64(r,x)     _mm_srli_epi64((r),(x))
#define _MM_SLLI_EPI64(r,x)     _mm_slli_epi64((r),(x))

// Set a SSE Register to 0
#define _MM_SETZERO_SI128() _mm_setzero_si128()

#define _MM_AND_SI128(x,y)     _mm_and_si128((x),(y))
#define _MM_ANDNOT_SI128(x,y)  _mm_andnot_si128((x),(y))
#define _MM_OR_SI128(x,y)      _mm_or_si128((x),(y))
#define _MM_XOR_SI128(x,y)     _mm_xor_si128((x),(y))
#define _MM_SLLI_SI128(r,s)	   _mm_slli_si128((r),(s))
#define _MM_SRLI_SI128(r,s)    _mm_srli_si128((r),(s))

// Load a SSE register from an unaligned address
#define _MM_LOADU_SI128(x) _mm_loadu_si128(x)

// Load a SSE register from an aligned address (/!\ not defined when SSE not available)
#define _MM_LOAD_SI128(x)  _mm_load_si128(x)

// #define	_MM_UNPACKLO_EPI8(x,y) _mm_unpacklo_epi8((x),(y))

#else /* __SSE2__ Not defined */

static inline __m128i _em_set1_epi8(int x)
{
	um128 a;

	x&=0xFF;
	a.s8[0]=x;
	a.s8[1]=x;
	a.u16[1]=a.u16[0];
	a.u32[1]=a.u32[0];
	a.u64[1]=a.u64[0];

	return a.i;
}

static inline __m128i _em_insert_epi8(__m128i r, int x, const int i)
{
	um128 a;
	a.i=r;
	a.s8[i]=x & 0xFF;
	return a.i;
}

static inline __m128i _em_cmpeq_epi8(__m128i a, __m128i b)
{
	um128 x;
	um128 y;
	um128 r;

	x.i=a;
	y.i=b;

#define R(z) 	r.s8[z]=(x.s8[z]==y.s8[z]) ? 0xFF:0
	R(0);
	R(1);
	R(2);
	R(3);
	R(4);
	R(5);
	R(6);
	R(7);
	R(8);
	R(9);
	R(10);
	R(11);
	R(12);
	R(13);
	R(14);
	R(15);
#undef R

	return r.i;
}

static inline __m128i _em_cmpgt_epi8(__m128i a, __m128i b)
{
	um128 x;
	um128 y;
	um128 r;

	x.i=a;
	y.i=b;

#define R(z) 	r.s8[z]=(x.s8[z]>y.s8[z]) ? 0xFF:0
	R(0);
	R(1);
	R(2);
	R(3);
	R(4);
	R(5);
	R(6);
	R(7);
	R(8);
	R(9);
	R(10);
	R(11);
	R(12);
	R(13);
	R(14);
	R(15);
#undef R

	return r.i;
}

static inline __m128i _em_cmplt_epi8(__m128i a, __m128i b)
{
	um128 x;
	um128 y;
	um128 r;

	x.i=a;
	y.i=b;

#define R(z) 	r.s8[z]=(x.s8[z]<y.s8[z]) ? 0xFF:0
	R(0);
	R(1);
	R(2);
	R(3);
	R(4);
	R(5);
	R(6);
	R(7);
	R(8);
	R(9);
	R(10);
	R(11);
	R(12);
	R(13);
	R(14);
	R(15);
#undef R

	return r.i;
}

static inline __m128i _em_max_epi8(__m128i a, __m128i b)
{
	um128 x;
	um128 y;
	um128 r;

	x.i=a;
	y.i=b;

#define R(z) 	r.s8[z]=MAX(x.s8[z],y.s8[z])
	R(0);
	R(1);
	R(2);
	R(3);
	R(4);
	R(5);
	R(6);
	R(7);
	R(8);
	R(9);
	R(10);
	R(11);
	R(12);
	R(13);
	R(14);
	R(15);
#undef R

	return r.i;
}

static inline __m128i _em_min_epi8(__m128i a, __m128i b)
{
	um128 x;
	um128 y;
	um128 r;

	x.i=a;
	y.i=b;

#define R(z) 	r.s8[z]=MIN(x.s8[z],y.s8[z])
	R(0);
	R(1);
	R(2);
	R(3);
	R(4);
	R(5);
	R(6);
	R(7);
	R(8);
	R(9);
	R(10);
	R(11);
	R(12);
	R(13);
	R(14);
	R(15);
#undef R

	return r.i;
}

static inline __m128i _em_add_epi8(__m128i a, __m128i b)
{
	um128 x;
	um128 y;
	um128 r;

	x.i=a;
	y.i=b;

#define R(z) 	r.s8[z]=x.s8[z]+y.s8[z]
	R(0);
	R(1);
	R(2);
	R(3);
	R(4);
	R(5);
	R(6);
	R(7);
	R(8);
	R(9);
	R(10);
	R(11);
	R(12);
	R(13);
	R(14);
	R(15);
#undef R

	return r.i;
}

static inline __m128i _em_sub_epi8(__m128i a, __m128i b)
{
	um128 x;
	um128 y;
	um128 r;

	x.i=a;
	y.i=b;

#define R(z) 	r.s8[z]=x.s8[z]+y.s8[z]
	R(0);
	R(1);
	R(2);
	R(3);
	R(4);
	R(5);
	R(6);
	R(7);
	R(8);
	R(9);
	R(10);
	R(11);
	R(12);
	R(13);
	R(14);
	R(15);
#undef R

	return r.i;
}


static inline int _em_extract_epi8(__m128i r, const int i)
{
	um128 a;

	a.i=r;

	return a.s8[i] & 0xFF;
}

static inline __m128i _em_min_epu8(__m128i a, __m128i b)
{
	um128 x;
	um128 y;
	um128 r;

	x.i=a;
	y.i=b;

#define R(z) 	r.u8[z]=MIN(x.u8[z],y.u8[z])
	R(0);
	R(1);
	R(2);
	R(3);
	R(4);
	R(5);
	R(6);
	R(7);
	R(8);
	R(9);
	R(10);
	R(11);
	R(12);
	R(13);
	R(14);
	R(15);
#undef R

	return r.i;
}

static inline __m128i _em_set1_epi16(int x)
{
	um128 a;

	x&=0xFFFF;
	a.s16[0]=x;
	a.s16[1]=x;
	a.u32[1]=a.u32[0];
	a.u64[1]=a.u64[0];

	return a.i;
}

static inline __m128i _em_insert_epi16(__m128i r, int x, const int i)
{
	um128 a;
	a.i=r;
	a.s16[i]=x & 0xFFFF;
	return a.i;
}

static inline __m128i _em_cmpeq_epi16(__m128i a, __m128i b)
{
	um128 x;
	um128 y;
	um128 r;

	x.i=a;
	y.i=b;

#define R(z) 	r.s16[z]=(x.s16[z]==y.s16[z]) ? 0xFFFF:0
	R(0);
	R(1);
	R(2);
	R(3);
	R(4);
	R(5);
	R(6);
	R(7);
#undef R

	return r.i;
}

static inline __m128i _em_cmpgt_epi16(__m128i a, __m128i b)
{
	um128 x;
	um128 y;
	um128 r;

	x.i=a;
	y.i=b;

#define R(z) 	r.s16[z]=(x.s16[z]>y.s16[z]) ? 0xFFFF:0
	R(0);
	R(1);
	R(2);
	R(3);
	R(4);
	R(5);
	R(6);
	R(7);
#undef R

	return r.i;
}

static inline __m128i _em_cmplt_epi16(__m128i a, __m128i b)
{
	um128 x;
	um128 y;
	um128 r;

	x.i=a;
	y.i=b;

#define R(z) 	r.s16[z]=(x.s16[z]<y.s16[z]) ? 0xFFFF:0
	R(0);
	R(1);
	R(2);
	R(3);
	R(4);
	R(5);
	R(6);
	R(7);
#undef R

	return r.i;
}

static inline __m128i _em_max_epi16(__m128i a, __m128i b)
{
	um128 x;
	um128 y;
	um128 r;

	x.i=a;
	y.i=b;


#define R(z) 	r.s16[z]=MAX(x.s16[z],y.s16[z])
	R(0);
	R(1);
	R(2);
	R(3);
	R(4);
	R(5);
	R(6);
	R(7);
#undef R

	return r.i;
}

static inline __m128i _em_min_epi16(__m128i a, __m128i b)
{
	um128 x;
	um128 y;
	um128 r;

	x.i=a;
	y.i=b;


#define R(z) 	r.s16[z]=MIN(x.s16[z],y.s16[z])
	R(0);
	R(1);
	R(2);
	R(3);
	R(4);
	R(5);
	R(6);
	R(7);
#undef R

	return r.i;
}

static inline __m128i _em_add_epi16(__m128i a, __m128i b)
{
	um128 x;
	um128 y;
	um128 r;

	x.i=a;
	y.i=b;

#define R(z) 	r.s16[z]=x.s16[z]+y.s16[z]
	R(0);
	R(1);
	R(2);
	R(3);
	R(4);
	R(5);
	R(6);
	R(7);
#undef R

	return r.i;
}

static inline __m128i _em_sub_epi16(__m128i a, __m128i b)
{
	um128 x;
	um128 y;
	um128 r;

	x.i=a;
	y.i=b;

#define R(z) 	r.s16[z]=x.s16[z]+y.s16[z]
	R(0);
	R(1);
	R(2);
	R(3);
	R(4);
	R(5);
	R(6);
	R(7);
#undef R

	return r.i;
}

static inline int _em_extract_epi16(__m128i r, const int i)
{
	um128 a;
	a.i=r;
	return a.s16[i] & 0xFFFF;
}

static inline __m128i _em_unpacklo_epi8(__m128i a, __m128i b)
{
	um128 x;
	um128 y;
	um128 r;

	x.i=a;
	y.i=b;

#define R(z) 	r.s16[z]=(((int16_t)(y.s8[z])) << 8) | (int16_t)(x.s8[z])
	R(0);
	R(1);
	R(2);
	R(3);
	R(4);
	R(5);
	R(6);
	R(7);
#undef R

	return r.i;
}

static inline __m128i _em_unpackhi_epi8(__m128i a, __m128i b)
{
	um128 x;
	um128 y;
	um128 r;

	x.i=a;
	y.i=b;

#define R(z) 	r.s16[z]=(((int16_t)(y.s8[z+8])) << 8) | (int16_t)(x.s8[z+8])
	R(0);
	R(1);
	R(2);
	R(3);
	R(4);
	R(5);
	R(6);
	R(7);
#undef R

	return r.i;
}

static inline __m128i _em_adds_epu16(__m128i a, __m128i b)
{
	um128 x;
	um128 y;
	um128 r;

	x.i=a;
	y.i=b;


#define R(z) 	r.u16[z]=x.u16[z]+y.u16[z]
	R(0);
	R(1);
	R(2);
	R(3);
	R(4);
	R(5);
	R(6);
	R(7);
#undef R

	return r.i;
}

static inline __m128i _em_srli_epi64(__m128i a, int b)
{
	um128 x;

	x.i=a;

	x.s64[0]>>=b;
	x.s64[1]>>=b;

	return x.i;
}

static inline __m128i _em_slli_epi64(__m128i a, int b)
{
	um128 x;

	x.i=a;

	x.s64[0]<<=b;
	x.s64[1]<<=b;

	return x.i;
}

static inline __m128i _em_setzero_si128()
{
	um128 x;

	x.s64[0]=x.s64[1]=0;

	return x.i;
}

static inline __m128i _em_and_si128(__m128i a, __m128i b)
{
	um128 x;
	um128 y;
	um128 r;

	x.i=a;
	y.i=b;


#define R(z) 	r.u64[z]=x.u64[z] & y.u64[z]
	R(0);
	R(1);
#undef R

	return r.i;
}

static inline __m128i _em_andnot_si128(__m128i a, __m128i b)
{
	um128 x;
	um128 y;
	um128 r;

	x.i=a;
	y.i=b;


#define R(z) 	r.u64[z]=(~x.u64[z]) & y.u64[z]
	R(0);
	R(1);
#undef R

	return r.i;
}

static inline __m128i _em_or_si128(__m128i a, __m128i b)
{
	um128 x;
	um128 y;
	um128 r;

	x.i=a;
	y.i=b;

#define R(z) 	r.u64[z]=x.u64[z] | y.u64[z]
	R(0);
	R(1);
#undef R

	return r.i;
}

static inline __m128i _em_xor_si128(__m128i a, __m128i b)
{
	um128 x;
	um128 y;
	um128 r;

	x.i=a;
	y.i=b;

#define R(z) 	r.u64[z]=x.u64[z] ^ y.u64[z]
	R(0);
	R(1);
#undef R

	return r.i;
}

static inline __m128i _em_slli_si128(__m128i a, int b)
{
	um128 x;

	x.i=a;

#define R(z) 	x.u8[z]=(z>=b) ? x.u8[z-b]:0
	R(15);
	R(14);
	R(13);
	R(12);
	R(11);
	R(10);
	R(9);
	R(8);
	R(7);
	R(6);
	R(5);
	R(4);
	R(3);
	R(2);
	R(1);
	R(0);
#undef R

	return x.i;
}

static inline __m128i _em_srli_si128(__m128i a, int b)
{
	um128 x;

	x.i=a;

#define R(z) 	x.u8[z]=((b+z) > 15) ? 0:x.u8[z+b]
	R(0);
	R(1);
	R(2);
	R(3);
	R(4);
	R(5);
	R(6);
	R(7);
	R(8);
	R(9);
	R(10);
	R(11);
	R(12);
	R(13);
	R(14);
	R(15);
#undef R

	return x.i;
}

inline static __m128i _em_loadu_si128(__m128i const *P)
{
	um128 tmp;
	um128 *pp=(um128*)P;

	tmp.u8[0]=(*pp).u8[0];
    tmp.u8[1]=(*pp).u8[1];
	tmp.u8[2]=(*pp).u8[2];
    tmp.u8[3]=(*pp).u8[3];
	tmp.u8[4]=(*pp).u8[4];
    tmp.u8[5]=(*pp).u8[5];
	tmp.u8[6]=(*pp).u8[6];
    tmp.u8[7]=(*pp).u8[7];
	tmp.u8[8]=(*pp).u8[8];
    tmp.u8[9]=(*pp).u8[9];
	tmp.u8[10]=(*pp).u8[10];
    tmp.u8[11]=(*pp).u8[11];
	tmp.u8[12]=(*pp).u8[12];
    tmp.u8[13]=(*pp).u8[13];
	tmp.u8[14]=(*pp).u8[14];
    tmp.u8[15]=(*pp).u8[15];
	return tmp.i;
}


#define _MM_SET1_EPI8(x)        _em_set1_epi8(x)
#define _MM_INSERT_EPI8(r,x,i)	_em_insert_epi8((r),(x),(i))
#define _MM_CMPEQ_EPI8(x,y)     _em_cmpeq_epi8((x),(y))
#define _MM_CMPGT_EPI8(x,y)     _em_cmpgt_epi8((x),(y))
#define _MM_CMPLT_EPI8(x,y)     _em_cmplt_epi8((x),(y))
#define _MM_MAX_EPI8(x,y)       _em_max_epi8((x),(y))
#define _MM_MIN_EPI8(x,y)       _em_min_epi8((x),(y))
#define _MM_ADD_EPI8(x,y)       _em_add_epi8((x),(y))
#define _MM_SUB_EPI8(x,y)       _em_sub_epi8((x),(y))
#define _MM_EXTRACT_EPI8(r,p)   _em_extract_epi8((r),(p))

#define _MM_MIN_EPU8(x,y)       _em_min_epu8((x),(y))

#define _MM_SET1_EPI16(x)       _em_set1_epi16(x)
#define _MM_INSERT_EPI16(r,x,i)	_em_insert_epi16((r),(x),(i))
#define _MM_CMPEQ_EPI16(x,y)    _em_cmpeq_epi16((x),(y))
#define _MM_CMPGT_EPI16(x,y)    _em_cmpgt_epi16((x),(y))
#define _MM_CMPLT_EPI16(x,y)    _em_cmplt_epi16((x),(y))
#define _MM_MAX_EPI16(x,y)      _em_max_epi16((x),(y))
#define _MM_MIN_EPI16(x,y)      _em_min_epi16((x),(y))
#define _MM_ADD_EPI16(x,y)      _em_add_epi16((x),(y))
#define _MM_SUB_EPI16(x,y)      _em_sub_epi16((x),(y))
#define _MM_EXTRACT_EPI16(r,p)  _em_extract_epi16((r),(p))
#define _MM_UNPACKLO_EPI8(a,b)  _em_unpacklo_epi8((a),(b))
#define _MM_UNPACKHI_EPI8(a,b)  _em_unpackhi_epi8((a),(b))
#define _MM_ADDS_EPU16(x,y)     _em_adds_epu16((x),(y))

#define _MM_SRLI_EPI64(r,x)     _em_srli_epi64((r),(x))
#define _MM_SLLI_EPI64(r,x)     _em_slli_epi64((r),(x))

#define _MM_SETZERO_SI128()     _em_setzero_si128()

#define _MM_AND_SI128(x,y)      _em_and_si128((x),(y))
#define _MM_ANDNOT_SI128(x,y)   _em_andnot_si128((x),(y))
#define _MM_OR_SI128(x,y)       _em_or_si128((x),(y))
#define _MM_XOR_SI128(x,y)      _em_xor_si128((x),(y))
#define _MM_SLLI_SI128(r,s)	    _em_slli_si128((r),(s))
#define _MM_SRLI_SI128(r,s)	    _em_srli_si128((r),(s))

#define _MM_LOADU_SI128(x)      _em_loadu_si128(x)
#define _MM_LOAD_SI128(x)       _em_loadu_si128(x)


#endif /* __SSE2__ */

#define _MM_NOT_SI128(x)     _MM_XOR_SI128((x),(_MM_SET1_EPI8(0xFFFF)))

#endif
