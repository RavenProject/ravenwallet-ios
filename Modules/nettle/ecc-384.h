#if (GMP_NUMB_BITS) == 64
#include "ecc-384-64.h"
#elif (GMP_NUMB_BITS) == 32
#include "ecc-384-32.h"
#else
#error unsupported GMP_NUMB_BITS
#endif
