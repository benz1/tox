#ifndef crypto_sign_H
#define crypto_sign_H

#include <stdlib.h>

#include "crypto_sign_ed25519.h"
#include "export.h"

#ifdef __cplusplus
extern "C" {
#endif

#define crypto_sign_BYTES crypto_sign_ed25519_BYTES
SODIUM_EXPORT
size_t  crypto_sign_bytes(void);

#define crypto_sign_PUBLICKEYBYTES crypto_sign_ed25519_PUBLICKEYBYTES
SODIUM_EXPORT
size_t  crypto_sign_publickeybytes(void);

#define crypto_sign_SECRETKEYBYTES crypto_sign_ed25519_SECRETKEYBYTES
SODIUM_EXPORT
size_t  crypto_sign_secretkeybytes(void);

#define crypto_sign_PRIMITIVE "ed25519"
SODIUM_EXPORT
const char *crypto_sign_primitive(void);

SODIUM_EXPORT
int crypto_sign_seed_keypair(unsigned char *pk, unsigned char *sk,
                             const unsigned char *seed);

SODIUM_EXPORT
int crypto_sign_keypair(unsigned char *pk, unsigned char *sk);

SODIUM_EXPORT
int crypto_sign(unsigned char *sm, unsigned long long *smlen,
                const unsigned char *m, unsigned long long mlen,
                const unsigned char *sk);

SODIUM_EXPORT
int crypto_sign_open(unsigned char *m, unsigned long long *mlen,
                     const unsigned char *sm, unsigned long long smlen,
                     const unsigned char *pk);

#ifdef __cplusplus
}
#endif

#endif
