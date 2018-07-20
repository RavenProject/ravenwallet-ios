#if GMP_NUMB_BITS == 64
#include "ecc-256-64.h"
#elif GMP_NUMB_BITS == 32
#include "ecc-256-32.h"
#else
#error unsupported GMP_NUMB_BITS
#endif
