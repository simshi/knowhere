/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#include <faiss/gpu/impl/scan/IVFInterleavedImpl.cuh>

namespace faiss {
namespace gpu {

#ifndef KNOWHERE_WITH_MACA
IVF_INTERLEAVED_IMPL(kSortThreadCount, 32, 2)
#endif

}
} // namespace faiss
