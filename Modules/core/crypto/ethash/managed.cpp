// ethash: C/C++ implementation of Ethash, the Ethereum Proof of Work algorithm.
// Copyright 2018-2019 Pawel Bylica.
// Licensed under the Apache License, Version 2.0.

#include "ethash-internal.hpp"

#include <memory>
#include <mutex>

#if !defined(__has_cpp_attribute)
#define __has_cpp_attribute(x) 0
#endif

#if __has_cpp_attribute(gnu::noinline)
#define ATTRIBUTE_NOINLINE [[gnu::noinline]]
#elif _MSC_VER
#define ATTRIBUTE_NOINLINE __declspec(noinline)
#else
#define ATTRIBUTE_NOINLINE
#endif