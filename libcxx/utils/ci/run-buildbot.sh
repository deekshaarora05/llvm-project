#!/usr/bin/env bash
#===----------------------------------------------------------------------===##
#
# Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
# See https://llvm.org/LICENSE.txt for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
#===----------------------------------------------------------------------===##

set -ex

BUILDER="${1}"
MONOREPO_ROOT="$(git rev-parse --show-toplevel)"
BUILD_DIR="${MONOREPO_ROOT}/build/${BUILDER}"

args=()
args+=("-DLLVM_ENABLE_PROJECTS=libcxx;libunwind;libcxxabi")
args+=("-DLIBCXX_CXX_ABI=libcxxabi")

case "${BUILDER}" in
generic-cxx03)
    export CC=clang
    export CXX=clang++
    args+=("-DLLVM_LIT_ARGS=-sv --show-unsupported --param=std=c++03")
;;
generic-cxx11)
    export CC=clang
    export CXX=clang++
    args+=("-DLLVM_LIT_ARGS=-sv --show-unsupported --param=std=c++11")
;;
generic-cxx14)
    export CC=clang
    export CXX=clang++
    args+=("-DLLVM_LIT_ARGS=-sv --show-unsupported --param=std=c++14")
;;
generic-cxx17)
    export CC=clang
    export CXX=clang++
    args+=("-DLLVM_LIT_ARGS=-sv --show-unsupported --param=std=c++17")
;;
generic-cxx2a)
    export CC=clang
    export CXX=clang++
    args+=("-DLLVM_LIT_ARGS=-sv --show-unsupported --param=std=c++2a")
;;
generic-noexceptions)
    export CC=clang
    export CXX=clang++
    args+=("-DLLVM_LIT_ARGS=-sv --show-unsupported")
    args+=("-DLIBCXX_ENABLE_EXCEPTIONS=OFF")
    args+=("-DLIBCXXABI_ENABLE_EXCEPTIONS=OFF")
;;
generic-32bit)
    export CC=clang
    export CXX=clang++
    args+=("-DLLVM_LIT_ARGS=-sv --show-unsupported")
    args+=("-DLLVM_BUILD_32_BITS=ON")
;;
generic-gcc)
    export CC=gcc
    export CXX=g++
    # FIXME: Re-enable experimental testing on GCC. GCC cares about the order
    #        in which we link -lc++experimental, which causes issues.
    args+=("-DLLVM_LIT_ARGS=-sv --show-unsupported --param enable_experimental=False")
;;
generic-asan)
    export CC=clang
    export CXX=clang++
    args+=("-DLLVM_USE_SANITIZER=Address")
    args+=("-DLLVM_LIT_ARGS=-sv --show-unsupported")
;;
generic-msan)
    export CC=clang
    export CXX=clang++
    args+=("-DLLVM_USE_SANITIZER=MemoryWithOrigins")
    args+=("-DLLVM_LIT_ARGS=-sv --show-unsupported")
;;
generic-tsan)
    export CC=clang
    export CXX=clang++
    args+=("-DLLVM_USE_SANITIZER=Thread")
    args+=("-DLLVM_LIT_ARGS=-sv --show-unsupported")
;;
generic-ubsan)
    export CC=clang
    export CXX=clang++
    args+=("-DLLVM_USE_SANITIZER=Undefined")
    args+=("-DLIBCXX_ABI_UNSTABLE=ON")
    args+=("-DLLVM_LIT_ARGS=-sv --show-unsupported")
;;
generic-with_llvm_unwinder)
    export CC=clang
    export CXX=clang++
    args+=("-DLLVM_LIT_ARGS=-sv --show-unsupported")
    args+=("-DLIBCXXABI_USE_LLVM_UNWINDER=ON")
;;
generic-singlethreaded)
    export CC=clang
    export CXX=clang++
    args+=("-DLLVM_LIT_ARGS=-sv --show-unsupported")
    args+=("-DLIBCXX_ENABLE_THREADS=OFF")
    args+=("-DLIBCXXABI_ENABLE_THREADS=OFF")
    args+=("-DLIBCXX_ENABLE_MONOTONIC_CLOCK=OFF")
;;
x86_64-apple-system)
    export CC=clang
    export CXX=clang++
    args+=("-DLLVM_LIT_ARGS=-sv --show-unsupported")
    args+=("-C${MONOREPO_ROOT}/libcxx/cmake/caches/Apple.cmake")
;;
x86_64-apple-system-noexceptions)
    export CC=clang
    export CXX=clang++
    args+=("-DLLVM_LIT_ARGS=-sv --show-unsupported")
    args+=("-C${MONOREPO_ROOT}/libcxx/cmake/caches/Apple.cmake")
    args+=("-DLIBCXX_ENABLE_EXCEPTIONS=OFF")
    args+=("-DLIBCXXABI_ENABLE_EXCEPTIONS=OFF")
;;
*)
    echo "${BUILDER} is not a known configuration"
    exit 1
;;
esac

echo "--- Generating CMake"
rm -rf "${BUILD_DIR}"
cmake -S "${MONOREPO_ROOT}/llvm" -B "${BUILD_DIR}" -GNinja -DCMAKE_BUILD_TYPE=RelWithDebInfo "${args[@]}"

echo "--- Building libc++ and libc++abi"
ninja -C "${BUILD_DIR}" check-cxx-deps cxxabi

echo "+++ Running the libc++ tests"
ninja -C "${BUILD_DIR}" check-cxx

echo "+++ Running the libc++abi tests"
ninja -C "${BUILD_DIR}" check-cxxabi

# echo "+++ Running the libc++ benchmarks"
# ninja -C "${BUILD_DIR}" check-cxx-benchmarks
