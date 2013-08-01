#ifndef crypto_stream_salsa2012_H
#define crypto_stream_salsa2012_H

/*
 *  WARNING: This is just a stream cipher. It is NOT authenticated encryption.
 *  While it provides some protection against eavesdropping, it does NOT
 *  provide any security against active attacks.
 *  Unless you know what you're doing, what you are looking for is probably
 *  the crypto_box functions.
 */

#include "export.h"

#define crypto_stream_salsa2012_KEYBYTES 32
#define crypto_stream_salsa2012_NONCEBYTES 8

#ifdef __cplusplus
extern "C" {
#endif

SODIUM_EXPORT
int crypto_stream_salsa2012(unsigned char *,unsigned long long,const unsigned char *,const unsigned char *);

SODIUM_EXPORT
int crypto_stream_salsa2012_xor(unsigned char *,const unsigned char *,unsigned long long,const unsigned char *,const unsigned char *);

SODIUM_EXPORT
int crypto_stream_salsa2012_beforenm(unsigned char *,const unsigned char *);

SODIUM_EXPORT
int crypto_stream_salsa2012_afternm(unsigned char *,unsigned long long,const unsigned char *,const unsigned char *);

SODIUM_EXPORT
int crypto_stream_salsa2012_xor_afternm(unsigned char *,const unsigned char *,unsigned long long,const unsigned char *,const unsigned char *);

#ifdef __cplusplus
}
#endif

#define crypto_stream_salsa2012_ref crypto_stream_salsa2012
#define crypto_stream_salsa2012_ref_xor crypto_stream_salsa2012_xor
#define crypto_stream_salsa2012_ref_beforenm crypto_stream_salsa2012_beforenm
#define crypto_stream_salsa2012_ref_afternm crypto_stream_salsa2012_afternm
#define crypto_stream_salsa2012_ref_xor_afternm crypto_stream_salsa2012_xor_afternm

#endif