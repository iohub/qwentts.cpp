#!/bin/bash

# CUDA 编译架构：默认只编 Turing（sm_75），而不是 CMakeLists.txt 里为跨设备
# 分发准备的 61/75/80/86/89/120a/121a 多架构列表——那份列表会让 nvcc 对每
# 一种架构各生成一遍 device 代码，是本机 CUDA 编译慢的主因之一。
#
# 75 对应 Turing 架构（RTX 20 系 / T4 / GTX 16 系），本机显卡为 RTX 2080 Ti。
# 后缀 -real 产出该架构的原生 SASS，-virtual 则产出供前向 JIT 使用的 PTX；
# 这里只用 -real，不生成 PTX，因此产物只能在 sm_75 设备上运行（首次运行也不
# 需要 JIT）。换卡或需要分发时用环境变量覆盖即可，无需改脚本，例如：
#   CUDA_ARCH="75-real;86-real" ./buildcuda.sh
#   CUDA_ARCH=native ./buildcuda.sh
#
# 想进一步缩短编译时间，还可以追加 -DGGML_CUDA_FA_QUANTS=f16-f16
# 或 -DGGML_CUDA_FA_QUANTS="f16-f16;q8_0-q8_0"。
CUDA_ARCH="${CUDA_ARCH:-75-real}"

rm -rf build
mkdir build
cd build

cmake .. -DGGML_CUDA=ON \
    -DCMAKE_CUDA_COMPILER=/usr/local/cuda/bin/nvcc \
    -DCMAKE_CUDA_ARCHITECTURES="$CUDA_ARCH" \
    -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release -j "$(getconf _NPROCESSORS_ONLN)"
