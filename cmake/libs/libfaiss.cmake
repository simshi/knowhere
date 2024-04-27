knowhere_file_glob(
  GLOB FAISS_SRCS thirdparty/faiss/faiss/*.cpp
  thirdparty/faiss/faiss/impl/*.cpp thirdparty/faiss/faiss/invlists/*.cpp
  thirdparty/faiss/faiss/utils/*.cpp)

knowhere_file_glob(GLOB FAISS_AVX512_SRCS
                   thirdparty/faiss/faiss/impl/*avx512.cpp)

knowhere_file_glob(GLOB FAISS_AVX2_SRCS
                   thirdparty/faiss/faiss/impl/*avx.cpp
                   thirdparty/faiss/faiss/impl/pq4_fast_scan_search_1.cpp
                   thirdparty/faiss/faiss/impl/pq4_fast_scan_search_qbs.cpp
                   thirdparty/faiss/faiss/utils/partitioning_avx2.cpp
                   thirdparty/faiss/faiss/IndexPQFastScan.cpp
                   thirdparty/faiss/faiss/IndexIVFPQFastScan.cpp)

list(REMOVE_ITEM FAISS_SRCS ${FAISS_AVX512_SRCS})

# start GPU support

if (WITH_MACA)
  message(STATUS "Build with MACA support")
  set(MACA_PATH "/opt/maca")
  # env?
  set(CUDA_PATH "${MACA_PATH}/tools/cu-bridge")
  set(CUCC_PATH "${MACA_PATH}/tools/cu-bridge")

  list(PREPEND CMAKE_MODULE_PATH "${MACA_PATH}/tools/cu-bridge/cmake_module/maca")
  list(PREPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake/modules/maca")
  set(CMAKE_MACA_COMPILER "${MACA_PATH}/mxgpu_llvm/bin/mxcc")

  enable_language(CUDA)
  find_package(CUDAToolkit REQUIRED)
endif()

if (WITH_CUDA)
  message(STATUS "Build with CUDA support")
    if("${CMAKE_CUDA_ARCHITECTURES}" STREQUAL "")
    set(CMAKE_CUDA_ARCHITECTURES 86)
  endif()
  enable_language(CUDA)
  find_package(CUDAToolkit REQUIRED)
  if(${CUDAToolkit_VERSION_MAJOR} GREATER 10)
    # cuda11 support --threads for compile some large .cu more efficient
    add_compile_options($<$<COMPILE_LANGUAGE:CUDA>:--threads=4>)
  endif()
endif()

if (WITH_CUDA OR WITH_MACA)
  message(STATUS "Build with GPU support")
  knowhere_file_glob(
    GLOB FAISS_GPU_SRCS
    thirdparty/faiss/faiss/gpu/*.cpp
    thirdparty/faiss/faiss/gpu/impl/*.cpp
    thirdparty/faiss/faiss/gpu/utils/*.cpp
    thirdparty/faiss/faiss/gpu/*.cu
    thirdparty/faiss/faiss/gpu/impl/*.cu
    thirdparty/faiss/faiss/gpu/impl/*/*.cu
    thirdparty/faiss/faiss/gpu/utils/*.cu
    thirdparty/faiss/faiss/gpu/utils/*/*.cu
  )
  list(APPEND FAISS_SRCS ${FAISS_GPU_SRCS})
endif()
# end GPU support

if(__X86_64)
  set(UTILS_SRC src/simd/distances_ref.cc src/simd/hook.cc)
  set(UTILS_SSE_SRC src/simd/distances_sse.cc)
  set(UTILS_AVX_SRC src/simd/distances_avx.cc)
  set(UTILS_AVX512_SRC src/simd/distances_avx512.cc)

  add_library(utils_sse OBJECT ${UTILS_SSE_SRC})
  add_library(utils_avx OBJECT ${UTILS_AVX_SRC})
  add_library(utils_avx512 OBJECT ${UTILS_AVX512_SRC})

  target_compile_options(utils_sse PRIVATE -msse4.2 -mpopcnt)
  target_compile_options(utils_avx PRIVATE -mfma -mf16c -mavx2 -mpopcnt)
  target_compile_options(utils_avx512 PRIVATE -mfma -mf16c -mavx512f -mavx512dq
                                              -mavx512bw -mpopcnt)

  add_library(
    knowhere_utils STATIC
    ${UTILS_SRC} $<TARGET_OBJECTS:utils_sse> $<TARGET_OBJECTS:utils_avx>
    $<TARGET_OBJECTS:utils_avx512>)
  target_link_libraries(knowhere_utils PUBLIC glog::glog)
endif()

if(__AARCH64)
  set(UTILS_SRC src/simd/hook.cc src/simd/distances_ref.cc src/simd/distances_neon.cc)
  add_library(knowhere_utils STATIC ${UTILS_SRC})
  target_link_libraries(knowhere_utils PUBLIC glog::glog)
endif()

if(LINUX)
  set(BLA_VENDOR OpenBLAS)
endif()

if(APPLE)
  set(BLA_VENDOR Apple)
endif()

find_package(BLAS REQUIRED)
if(LINUX)
  set(BLA_VENDOR "")
endif()

find_package(LAPACK REQUIRED)

if(__X86_64)
  list(REMOVE_ITEM FAISS_SRCS ${FAISS_AVX2_SRCS})

  add_library(faiss_avx2 OBJECT ${FAISS_AVX2_SRCS})
  target_compile_options(
    faiss_avx2
    PRIVATE $<$<COMPILE_LANGUAGE:CXX>:
            -msse4.2
            -mavx2
            -mfma
            -mf16c
            -mpopcnt>)
  add_library(faiss_avx512 OBJECT ${FAISS_AVX512_SRCS})
  target_compile_options(
    faiss_avx512
    PRIVATE $<$<COMPILE_LANGUAGE:CXX>:
            -msse4.2
            -mavx2
            -mfma
            -mf16c
            -mavx512f
            -mavx512dq
            -mavx512bw
            -mpopcnt>)

  add_library(faiss STATIC ${FAISS_SRCS})

  add_dependencies(faiss faiss_avx2 faiss_avx512 knowhere_utils)
  target_compile_options(
    faiss
    PRIVATE $<$<COMPILE_LANGUAGE:CXX>:
            -msse4.2
            -mpopcnt
            -Wno-sign-compare
            -Wno-unused-variable
            -Wno-reorder
            -Wno-unused-local-typedefs
            -Wno-unused-function
            -Wno-strict-aliasing>)
  target_link_libraries(
    faiss PUBLIC OpenMP::OpenMP_CXX ${BLAS_LIBRARIES} ${LAPACK_LIBRARIES}
                 faiss_avx2 faiss_avx512 knowhere_utils)
  target_compile_definitions(faiss PRIVATE FINTEGER=int)
endif()

if(__AARCH64)
  knowhere_file_glob(GLOB FAISS_AVX_SRCS thirdparty/faiss/faiss/impl/*avx.cpp)

  list(REMOVE_ITEM FAISS_SRCS ${FAISS_AVX_SRCS})
  add_library(faiss STATIC ${FAISS_SRCS})

  target_compile_options(
    faiss
    PRIVATE $<$<COMPILE_LANGUAGE:CXX>:
            -Wno-sign-compare
            -Wno-unused-variable
            -Wno-reorder
            -Wno-unused-local-typedefs
            -Wno-unused-function
            -Wno-strict-aliasing>)

  add_dependencies(faiss knowhere_utils)
  target_link_libraries(faiss PUBLIC OpenMP::OpenMP_CXX ${BLAS_LIBRARIES}
                                     ${LAPACK_LIBRARIES} knowhere_utils)
  target_compile_definitions(faiss PRIVATE FINTEGER=int)
endif()


# start GPU support
if (WITH_CUDA OR WITH_MACA)
  target_link_libraries(faiss PUBLIC CUDA::cublas CUDA::cudart)

  if (WITH_CUDA)
    target_compile_options(faiss PRIVATE $<$<COMPILE_LANGUAGE:CUDA>:-Xfatbin=-compress-all>)
  else ()
    set(COMPILE_FLAGS_FOR_MACA
      -fPIC
      -DUSE_WARPSIZE64
      -DKNOWHERE_WITH_MACA
    )
    target_compile_options(faiss PRIVATE $<$<COMPILE_LANGUAGE:CXX>:${COMPILE_FLAGS_FOR_MACA}>)
    target_compile_options(faiss PRIVATE $<$<COMPILE_LANGUAGE:CUDA>:${COMPILE_FLAGS_FOR_MACA}>)
  endif()
endif()
# end GPU support
