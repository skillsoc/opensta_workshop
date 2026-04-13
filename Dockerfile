FROM ubuntu:22.04

# ---------------------------------------------------------------------------
# Layer 1: Environment Setup
# ---------------------------------------------------------------------------
# Prevents interactive prompts during package installation (important for Docker)
# Ensures fully automated build without hanging (e.g., timezone selection)
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# ---------------------------------------------------------------------------
# Layer 2: Install System Dependencies
# ---------------------------------------------------------------------------
# This layer installs all required tools and libraries in ONE step to:
#   - Improve Docker caching
#   - Avoid repeated apt-get update
#   - Maintain consistent package versions
#
# Categories:
#   - build-essential, gcc, g++ → Compilation toolchain
#   - cmake → Build system for OpenSTA
#   - tcl-dev → OpenSTA uses Tcl interface
#   - bison, flex → Parsing (EDA tools need this)
#   - swig → Interface generation
#   - eigen → Matrix computations in OpenSTA
#   - zlib, bz2, readline → Compression + CLI support
#   - gtkwave → Waveform viewer
#   - git, wget → Fetch source code
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        clang \
        gcc \
        g++ \
        tcl-dev \
        tcl \
        swig \
        bison \
        flex \
        libfl-dev \
        libeigen3-dev \
        zlib1g-dev \
        autoconf \
        gperf \
        libbz2-dev \
        libreadline-dev \
        gtkwave \
        git \
        wget \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Layer 3: Build and Install CUDD (BDD Library)
# ---------------------------------------------------------------------------
# CUDD (Binary Decision Diagram library) is used in OpenSTA for:
#   - Conditional timing arcs
#   - Logic-dependent delay evaluation
#
# Important:
#   --enable-shared → Generates shared libraries (.so)
#   Required so OpenSTA can dynamically link with CUDD
#
# Install path: /usr/local (standard for compiler/linker detection)
WORKDIR /tmp/cudd
RUN wget -O cudd.tar.gz https://sourceforge.net/projects/cudd-mirror/files/cudd-3.0.0.tar.gz/download \
    && tar xzf cudd.tar.gz \
    && cd cudd-3.0.0 \
    && ./configure --enable-shared --prefix=/usr/local \
    && make -j$(nproc) \
    && make install \
    && ldconfig \
    && cd / && rm -rf /tmp/cudd

# ---------------------------------------------------------------------------
# Layer 4: Environment Variables for CUDD Integration
# ---------------------------------------------------------------------------
# These variables ensure:
#   - Compiler finds header files
#   - Linker finds libraries
#   - Runtime loader finds shared libraries
#
# Without this:
#   → OpenSTA build fails with "cannot find libcudd"
#   → or runtime errors (missing .so files)
ENV CUDD_DIR=/usr/local
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
ENV CPLUS_INCLUDE_PATH=/usr/local/include:$CPLUS_INCLUDE_PATH
ENV LIBRARY_PATH=/usr/local/lib:$LIBRARY_PATH

# ---------------------------------------------------------------------------
# Layer 5: Build and Install OpenSTA (WITH CUDD)
# ---------------------------------------------------------------------------
# OpenSTA is a gate-level static timing analysis engine.
#
# Flow inside OpenSTA:
#   read_verilog → netlist
#   read_liberty → timing models
#   read_sdc     → constraints
#   report_timing → slack analysis
#
# CMake flags:
#   -DCUDD_DIR → enables conditional timing using CUDD
#   -DBUILD_TESTING=OFF → faster build
#   -DGTEST_ROOT=OFF → avoids unnecessary dependencies
RUN apt-get update && apt-get install -y libgtest-dev \
    && cd /usr/src/gtest \
    && cmake . \
    && make \
    && cp lib/*.a /usr/lib \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/opensta
RUN git clone --depth 1 https://github.com/The-OpenROAD-Project/OpenSTA.git . \
    && mkdir build \
    && cd build \
    && cmake \
        -DCUDD_DIR=/usr/local \
        -DCUDD_INCLUDE_DIR=/usr/local/include \
        -DCUDD_LIBRARY=/usr/local/lib/libcudd.so \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DBUILD_TESTING=OFF \
        .. \
    && make -j$(nproc) \
    && make install \
    && cd / \
    && rm -rf /tmp/opensta

RUN apt-get purge -y --auto-remove \
        autoconf \
        gperf \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ---------------------------------------------------------------------------
# Layer 8: Workspace Setup
# ---------------------------------------------------------------------------
# Default directory inside container where designs will be mounted
WORKDIR /workspace


RUN git clone https://github.com/skillsoc/opensta_workshop.git

# Install Micro via the official shell script
RUN curl https://getmic.ro | bash && mv micro /usr/local/bin/
RUN apt-get update && apt-get install -y vim && rm -rf /var/lib/apt/lists/*

RUN echo "alias sta='source /workspace/opensta_workshop/scripts/sta.csh'" >> /root/.bashrc

# ---------------------------------------------------------------------------
# Default Command
# ---------------------------------------------------------------------------
CMD ["/bin/bash"]
