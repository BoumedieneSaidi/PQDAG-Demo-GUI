# Use an official base image that is suitable for building C/C++ applications
FROM ubuntu:latest

# Install build tools and dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    gdb \
    libboost-all-dev \
    libsparsehash-dev \
    cmake \
    pkg-config \
    gdbserver \
    vim \
    git \
    libsnappy-dev \
    zlib1g-dev \
    libbz2-dev \
    libgflags-dev \
    liblz4-dev \
    libzstd-dev \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory to /app
WORKDIR /app

# Clone and build RocksDB
RUN git clone https://github.com/facebook/rocksdb.git && \
    cd rocksdb && \
    make -j$(nproc) shared_lib && \
    make install-shared && \
    ldconfig

# Set the LD_LIBRARY_PATH environment variable
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

# Copy the NewFastEncoder source code
COPY NewFastEncoder /app/NewFastEncoder

# Build the application
WORKDIR /app/NewFastEncoder/Release
RUN make clean && make

# Set default working directory back to /app
WORKDIR /app

# Default entrypoint to run the fragmentation
ENTRYPOINT ["/app/NewFastEncoder/Release/NewFastEncoder"]
