
#ifndef __SODIUM_UTILS_H__
#define __SODIUM_UTILS_H__

#include <stdlib.h>

#include "export.h"

#ifdef __cplusplus
extern "C" {
#endif

unsigned char *_sodium_alignedcalloc(unsigned char ** const unaligned_p,
                                     const size_t len);

SODIUM_EXPORT
void sodium_memzero(void * const pnt, const size_t len);

SODIUM_EXPORT
int sodium_memcmp(const void * const b1_, const void * const b2_, size_t size);

#ifdef __cplusplus
}
#endif

#endif
