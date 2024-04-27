/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#pragma once

#include <cuda.h>
#include <faiss/gpu/utils/DeviceDefs.cuh>

namespace faiss {
namespace gpu {

#ifndef KNOWHERE_WITH_MACA
#define WARP_SIZE_MASK (0xffffffff)
#else
#define WARP_SIZE_MASK (0xffffffffffffffff)
#endif

// defines to simplify the SASS assembly structure file/line in the profiler
#if CUDA_VERSION >= 9000
#define SHFL_SYNC(VAL, SRC_LANE, WIDTH) \
    __shfl_sync(WARP_SIZE_MASK, VAL, SRC_LANE, WIDTH)
#else
#define SHFL_SYNC(VAL, SRC_LANE, WIDTH) __shfl(VAL, SRC_LANE, WIDTH)
#endif

template <typename T>
__forceinline__ __device__ T
shfl(const T val, int srcLane, int width = kWarpSize) {
#if CUDA_VERSION >= 9000
    return __shfl_sync(WARP_SIZE_MASK, val, srcLane, width);
#else
    return __shfl(val, srcLane, width);
#endif
}

// CUDA SDK does not provide specializations for T*
template <typename T>
__forceinline__ __device__ T* shfl(
        T* const val,
        int srcLane,
        int width = kWarpSize) {
    static_assert(sizeof(T*) == sizeof(long long), "pointer size");
    long long v = (long long)val;

    return (T*)shfl(v, srcLane, width);
}

template <typename T>
__forceinline__ __device__ T
shfl_up(const T val, unsigned int delta, int width = kWarpSize) {
#if CUDA_VERSION >= 9000
    return __shfl_up_sync(WARP_SIZE_MASK, val, delta, width);
#else
    return __shfl_up(val, delta, width);
#endif
}

// CUDA SDK does not provide specializations for T*
template <typename T>
__forceinline__ __device__ T* shfl_up(
        T* const val,
        unsigned int delta,
        int width = kWarpSize) {
    static_assert(sizeof(T*) == sizeof(long long), "pointer size");
    long long v = (long long)val;

    return (T*)shfl_up(v, delta, width);
}

template <typename T>
__forceinline__ __device__ T
shfl_down(const T val, unsigned int delta, int width = kWarpSize) {
#if CUDA_VERSION >= 9000
    return __shfl_down_sync(WARP_SIZE_MASK, val, delta, width);
#else
    return __shfl_down(val, delta, width);
#endif
}

// CUDA SDK does not provide specializations for T*
template <typename T>
__forceinline__ __device__ T* shfl_down(
        T* const val,
        unsigned int delta,
        int width = kWarpSize) {
    static_assert(sizeof(T*) == sizeof(long long), "pointer size");
    long long v = (long long)val;
    return (T*)shfl_down(v, delta, width);
}

template <typename T>
__forceinline__ __device__ T
shfl_xor(const T val, int laneMask, int width = kWarpSize) {
#if CUDA_VERSION >= 9000
    return __shfl_xor_sync(WARP_SIZE_MASK, val, laneMask, width);
#else
    return __shfl_xor(val, laneMask, width);
#endif
}

// CUDA SDK does not provide specializations for T*
template <typename T>
__forceinline__ __device__ T* shfl_xor(
        T* const val,
        int laneMask,
        int width = kWarpSize) {
    static_assert(sizeof(T*) == sizeof(long long), "pointer size");
    long long v = (long long)val;
    return (T*)shfl_xor(v, laneMask, width);
}

// CUDA 9.0+ has half shuffle
#if CUDA_VERSION < 9000
__forceinline__ __device__ half
shfl(half v, int srcLane, int width = kWarpSize) {
    unsigned int vu = v.x;
    vu = __shfl(vu, srcLane, width);

    half h;
    h.x = (unsigned short)vu;
    return h;
}

__forceinline__ __device__ half
shfl_xor(half v, int laneMask, int width = kWarpSize) {
    unsigned int vu = v.x;
    vu = __shfl_xor(vu, laneMask, width);

    half h;
    h.x = (unsigned short)vu;
    return h;
}
#endif // CUDA_VERSION

} // namespace gpu
} // namespace faiss
