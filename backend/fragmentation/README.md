# PQDAG Fragmentation - NewFastEncoder

This is the **first step** of the PQDAG distributed RDF database system. It fragments RDF data using characteristic sets.

## Overview

The fragmentation process transforms RDF data into optimized fragments:
- **Input**: RDF files in N-Triples (.nt) or Turtle (.ttl) format
- **Output**: Multiple fragments with SPO and OPS orderings
- **Algorithm**: Characteristic Set-based fragmentation (groups entities by their predicate sets)

## Technology Stack

- **Language**: C++ with C++20 standard
- **Dependencies**: 
  - RocksDB 10.10 (key-value storage)
  - Boost (C++ utilities)
  - Compression libraries (snappy, zlib, bz2, lz4, zstd)
- **Build System**: Make
- **Containerization**: Docker

## Quick Start

### 1. Build the Docker Image (one time only)

```bash
cd backend/fragmentation
docker build -t newfastencoder .
```

**Build time**: 
- Initial build: ~16 minutes (compiles RocksDB from source)
- Rebuild after code changes: ~28 seconds (thanks to Docker layer caching)
- Image size: 3.47 GB

### 2. Prepare Storage Structure

The fragmentation requires 3 directories:

```
storage/
├── rawdata/      # INPUT: Place your RDF files here (.nt or .ttl)
├── bindata/      # TEMPORARY: Intermediate files (can be deleted after)
└── outputdata/   # OUTPUT: Final fragments
```

Clean and recreate temporary directories before each run:

```bash
rm -rf storage/bindata storage/outputdata
mkdir -p storage/bindata storage/outputdata
```

### 3. Run Fragmentation

```bash
docker run --rm \
  -v "$(pwd)/../../storage/rawdata":/rawdata \
  -v "$(pwd)/../../storage/bindata":/bindata \
  -v "$(pwd)/../../storage/outputdata":/outputdata \
  newfastencoder \
  /rawdata/ /bindata/data.nt
```

**Arguments**:
- First argument (`/rawdata/`): Directory containing RDF files (reads ALL files automatically)
- Second argument (`/bindata/data.nt`): Output filename for encoded data

**Note**: The code automatically reads ALL `.nt` and `.ttl` files in the rawdata directory.


## Output Structure

### Intermediate Files (`bindata/`)

These files are temporary and can be deleted after successful fragmentation:

- `data.nt` - Encoded triples
- `data.nt_spo` - SPO-sorted triples
- `data.nt_ops` - OPS-sorted triples
- `nodes.dic` - Dictionary mapping (strings to IDs)
- `schema.txt` - Predicate schema
- `so_db/` - RocksDB for subjects/objects
- `predicates_db/` - RocksDB for predicates

### Final Output (`outputdata/`)

Each fragment consists of 3 files:

- `<fragmentID>.data` - Fragment triple data
- `<fragmentID>.dic` - Dictionary for the fragment
- `<fragmentID>.schema` - Schema information

Additional files:

- `predicates.txt` - Global predicate information
- `spo_index.txt` - SPO index for lookups
- `ops_index.txt` - OPS index for lookups

## Algorithm Details

The fragmentation uses **Characteristic Sets**:

1. **Encoding**: Parse RDF and convert strings to numeric IDs
2. **Sorting**: Create SPO and OPS orderings for efficient access
3. **Fragmentation**: Group entities by their predicate sets
   - Each unique set of predicates = one fragment
   - Stores both SPO and OPS orderings
4. **Dictionary Indexing**: Create reverse lookup (ID to string)
5. **Re-encoding**: Optimize fragment encoding

## Troubleshooting

### RocksDB Version Issues

If you see errors about `librocksdb.so.X.X`, the code is pre-compiled with a different RocksDB version. The Dockerfile handles this by:
1. Cloning RocksDB 10.10 from source
2. Compiling with C++20 standard
3. Embedding code and compiling during Docker build

### C++20 Compatibility

RocksDB 10.10 requires C++20. The Makefiles are configured with:
- `CXXFLAGS = -std=c++20 -I/usr/local/include`

## Docker Image Details

The image is optimized for portability:

- ✅ **Pre-compiled**: No compilation needed at runtime
- ✅ **Portable**: Works on any system with Docker
- ✅ **Self-contained**: All dependencies embedded
- ✅ **Fast rebuild**: Layer caching for quick iterations

**Dockerfile highlights**:
```dockerfile
# Compiles RocksDB from source
RUN git clone https://github.com/facebook/rocksdb.git && \
    cd rocksdb && make -j$(nproc) shared_lib && make install-shared

# Embeds and compiles application code
COPY NewFastEncoder /app/NewFastEncoder
RUN make clean && make

# Sets default entrypoint
ENTRYPOINT ["/app/NewFastEncoder/Release/NewFastEncoder"]
```

## Next Steps

After fragmentation, the fragments are ready for:
- **Step 2**: Allocation (distribute fragments to machines)
- **Step 3**: Core/Query Execution (SPARQL queries on distributed data)