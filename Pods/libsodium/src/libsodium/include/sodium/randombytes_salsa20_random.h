
#ifndef randombytes_salsa20_random_H
#define randombytes_salsa20_random_H

#include <stdint.h>
#include <stdlib.h>

#include "export.h"

#ifdef __cplusplus
extern "C" {
#endif

SODIUM_EXPORT
extern struct randombytes_implementation randombytes_salsa20_implementation;

SODIUM_EXPORT
const char *randombytes_salsa20_implementation_name(void);

SODIUM_EXPORT
uint32_t    randombytes_salsa20_random(void);

SODIUM_EXPORT
void        randombytes_salsa20_random_stir(void);

SODIUM_EXPORT
uint32_t    randombytes_salsa20_random_uniform(const uint32_t upper_bound);

SODIUM_EXPORT
void        randombytes_salsa20_random_buf(void * const buf, const size_t size);

SODIUM_EXPORT
int         randombytes_salsa20_random_close(void);

#ifdef __cplusplus
}
#endif

#endif
