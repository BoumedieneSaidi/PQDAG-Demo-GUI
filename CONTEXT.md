# PQDAG-Demo-GUI Project Context

## Project Overview
- **Project Name**: PQDAG-Demo-GUI
- **Purpose**: Graphical User Interface for PQDAG (a distributed RDF database system)
- **Repository**: https://github.com/BoumedieneSaidi/PQDAG-Demo-GUI.git
- **Owner**: BoumedieneSaidi
- **Current Branch**: main

## About PQDAG
PQDAG is a distributed RDF database system.

## Current Status
- ✅ Repository created on GitHub (Dec 15, 2025)
- ✅ Local repository initialized
- ✅ Initial commit created
- ✅ Pushed to GitHub successfully

## Git Setup Commands Used
```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin git@github.com:BoumedieneSaidi/PQDAG-Demo-GUI.git
git branch -M main
git push -u origin main
```

## Project Architecture

### PQDAG System Overview
PQDAG has **3 main steps**:
1. **Fragmentation** - Creates fragments from RDF data
2. **Allocation** - Distributes fragments to different machines
3. **Core** - Handles query execution

### Repository Structure
```
PQDAG-Demo-GUI/
├── backend/
│   ├── fragmentation/       # Step 1: RDF Fragmentation
│   ├── allocation/          # Step 2: Fragment Distribution (to be added)
│   └── core/                # Step 3: Query Execution (to be added)
├── frontend/                # GUI application (to be created)
├── README.md
└── CONTEXT.md
```

## Fragmentation Step (Step 1)

### Overview
The fragmentation step processes RDF data and creates fragments using a containerized C++ application called **NewFastEncoder**.

### Technology Stack
- **Language**: C++
- **Key Libraries**: 
  - RocksDB (for efficient data storage and indexing)
  - Boost (C++ utilities)
  - Snappy, zlib, bz2, lz4, zstd (compression)
- **Containerization**: Docker
- **Build System**: Make

### Main Components

#### 1. **FastEncoder** (Main entry point)
The main workflow in `FastEncoder.cpp`:
1. **Encoding**: Load and encode RDF data
2. **Sorting**: Sort triples by SPO (Subject-Predicate-Object) and OPS (Object-Predicate-Subject)
3. **Fragmentation**: Create fragments based on characteristic sets
4. **Dictionary Indexing**: Reverse the dictionary file
5. **Re-encoding**: Re-encode fragments with optimized IDs
6. **Output**: Copy schema and index files

#### 2. **Key Classes**
- **`partitioner_store`**: Loads and encodes RDF data
- **`Sorter`**: External sorting for large RDF files (SPO and OPS ordering)
- **`Fragmenter`**: Creates fragments based on characteristic sets
  - Uses `characteristicSetToFragmentID` mapping
  - Generates unique fragment IDs
  - Tracks fragment statistics (distinct subjects, triples count)
- **`DictionaryIndexer`**: Manages string-to-ID dictionary mapping
- **`FragmentReencoder`**: Re-encodes fragments with optimized encoding
- **`ReferenceIndexer`**: Manages node-to-fragment references
- **`TurtleParser`**: Parses Turtle/N-Triples RDF format

#### 3. **Input/Output**
- **Input**: 
  - RDF data files (in `/rawdata/` directory in container)
  - Format: N-Triples (.nt) or Turtle (.ttl)
- **Intermediate Output** (`/bindata/`):
  - `data.nt` - Encoded triples
  - `data.nt_spo` - SPO sorted
  - `data.nt_ops` - OPS sorted
  - `nodes.dic` - Dictionary file
  - `schema.txt` - Predicate schema
  - Fragment files (`fragment_spo_*`, `fragment_ops_*`)
- **Final Output** (`/outputdata/`):
  - Re-encoded fragments
  - `predicates.txt` - Predicate information
  - Index files

### Docker Workflow
```bash
# Build Docker image
docker build -t newfastencoder .

# Prepare directories
rm -r bindata outputdata
mkdir bindata outputdata

# Run fragmentation
docker run -it --rm \
  -v /$(pwd)/rawdata:/rawdata \
  -v /$(pwd)/bindata:/bindata \
  -v /$(pwd)/outputdata:/outputdata \
  newfastencoder \
  /app/NewFastEncoder/Release/NewFastEncoder /rawdata/ /bindata/watdiv100k.nt
```

### Fragmentation Algorithm
Based on **Characteristic Sets**:
- Groups entities by their set of predicates
- Each unique characteristic set gets a fragment ID
- Stores both SPO and OPS orderings
- Tracks metadata: distinct subjects (DS), triple counts

## Discussion History

### Session 1 - December 15, 2025

#### Initial Setup
- **Question**: Can we push to GitHub even if there's nothing to push?
- **Answer**: Yes, as long as there's at least one commit locally. You need to:
  1. Initialize Git repository (`git init`)
  2. Create at least one file and commit it
  3. Add remote origin
  4. Push to GitHub

#### Repository Initialization
- Created initial README.md file with basic project description
- Successfully initialized Git repository
- Successfully pushed initial commit to GitHub
- Repository is now live and ready for development

#### Project Architecture Discussion
- Decided on `backend/` directory structure (instead of `PQDAG/`)
- Added fragmentation code to `backend/fragmentation/`
- Analyzed the fragmentation step:
  - Uses Docker container with C++ application
  - Implements characteristic set-based fragmentation
  - Processes: Encoding → Sorting → Fragmentation → Indexing → Re-encoding

## Next Steps
- **Phase 1**: Continue discussion to understand Allocation and Core steps
- Understand the complete workflow between the 3 steps
- Define GUI requirements for each step
- Choose GUI technology stack
- Design UI/UX mockups

## Current Phase
🗣️ **Discovery & Planning Phase** - Understanding the fragmentation step. Next: Allocation and Core steps.
