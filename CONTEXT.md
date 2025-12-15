# PQDAG-Demo-GUI Project Context

## Project Overview
- **Project Name**: PQDAG-Demo-GUI
- **Purpose**: Graphical User Interface for PQDAG (a distributed RDF database system)
- **Repository**: https://github.com/BoumedieneSaidi/PQDAG-Demo-GUI.git
- **Owner**: BoumedieneSaidi
- **Main Branch**: main
- **Current Feature Branch**: feature/angular-frontend

## About PQDAG
PQDAG is a distributed RDF database system for managing and querying large-scale RDF data through fragmentation and distribution.

## Current Status
- ✅ Repository created on GitHub (Dec 15, 2025)
- ✅ Backend API implemented with Spring Boot (merged to develop)
- ✅ Docker integration for fragmentation engine
- ✅ Angular frontend with drag & drop upload and metrics dashboard
- ✅ Full workflow tested and working
- ⏳ Frontend branch ready for merge

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
1. **Fragmentation** ✅ - Creates fragments from RDF data (IMPLEMENTED)
2. **Allocation** - Distributes fragments to different machines (to be added)
3. **Core** - Handles query execution (to be added)

### Repository Structure
```
PQDAG-Demo-GUI/
├── backend/
│   ├── api/                      # Spring Boot REST API
│   │   ├── src/main/java/com/pqdag/
│   │   │   ├── controller/       # REST controllers
│   │   │   ├── service/          # Business logic
│   │   │   ├── model/            # Data models
│   │   │   └── config/           # Configuration
│   │   ├── pom.xml
│   │   └── Dockerfile
│   └── fragmentation/            # NewFastEncoder C++ fragmentation engine
│       ├── NewFastEncoder/       # C++ source code
│       ├── Dockerfile
│       └── README.md
├── frontend/                     # Angular application
│   ├── src/
│   │   ├── app/
│   │   │   ├── components/       # UI components
│   │   │   │   ├── file-upload/
│   │   │   │   └── fragmentation-results/
│   │   │   ├── services/         # HTTP services
│   │   │   ├── models/           # TypeScript interfaces
│   │   │   └── config/           # API configuration
│   │   └── styles.scss
│   ├── angular.json
│   └── package.json
├── storage/                      # Data directories
│   ├── rawdata/                  # Uploaded RDF files
│   ├── bindata/                  # Temporary intermediate files
│   └── outputdata/               # Final fragment files
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

#### Étape 1 : Build de l'image (une seule fois)
```bash
cd /path/to/backend/fragmentation
docker build -t newfastencoder .
```

#### Étape 2 : Préparation de l'espace de stockage
L'utilisateur configure un **répertoire de travail** dans la GUI :
```
/espace-de-stockage/          # Configurable dans la GUI
├── rawdata/                  # INPUT - Fichiers RDF (.nt, .ttl)
│   ├── file1.nt             # Peut contenir PLUSIEURS fichiers
│   ├── file2.nt             # Le code lit TOUS les fichiers du dossier
│   └── dataset.ttl
├── bindata/                  # TEMPORAIRE - Fichiers intermédiaires
│   ├── data.nt              # (peut être supprimé après)
│   ├── data.nt_spo
│   ├── data.nt_ops
│   ├── nodes.dic
│   ├── schema.txt
│   ├── so_db/               # RocksDB pour sujets/objets
│   ├── predicates_db/       # RocksDB pour prédicats
│   └── fragment_*
└── outputdata/               # OUTPUT - Résultats finaux
    ├── fragment_spo_*        # Fragments SPO
    ├── fragment_ops_*        # Fragments OPS
    ├── predicates.txt        # Schema des prédicats
    ├── spo_index.txt         # Index SPO
    └── ops_index.txt         # Index OPS
```

#### Étape 3 : Exécution de la fragmentation
```bash
# Préparer les dossiers
rm -r bindata outputdata
mkdir bindata outputdata

# Lancer la fragmentation
docker run -it --rm \
  -v /espace-de-stockage/rawdata:/rawdata \
  -v /espace-de-stockage/bindata:/bindata \
  -v /espace-de-stockage/outputdata:/outputdata \
  newfastencoder \
  /app/NewFastEncoder/Release/NewFastEncoder /rawdata/ /bindata/data.nt
```

**Note importante** : 
- Le 1er argument (`/rawdata/`) = **répertoire** contenant les fichiers RDF
- Le 2ème argument (`/bindata/data.nt`) = nom du fichier de sortie encodé
- Le code lit **TOUS les fichiers** du répertoire `/rawdata/` automatiquement (via la fonction `getdir()`)
- Formats supportés : N-Triples (.nt) et Turtle (.ttl)

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

### Git Workflow Strategy

#### Branch Structure
```
main          # Stable, production-ready code
  └── develop       # Integration branch
        └── feature/backend-setup   # Current: Backend setup & fragmentation
```

#### Git Flow Pattern
- **main**: Protected branch, only for stable releases
- **develop**: Integration branch for ongoing development
- **feature/***: Feature branches for specific work
- **Current branch**: `feature/backend-setup`

#### Development Workflow
1. Create feature branch from develop
2. Work on feature
3. Test and validate
4. Merge to develop
5. After testing on develop, merge to main

### Docker Optimization Journey

#### Initial Approach (Volume-Mounted Code)
- Problem: RocksDB version mismatch (precompiled with 9.8, Docker has 10.10)
- Solution: Volume mount source code and compile inside container
- Issue: Not portable, requires manual compilation

#### C++20 Compatibility Fix
**Problem**: RocksDB 10.10 requires C++20 standard
- Error: `defaulted operator== only available with '-std=c++20'`

**Solution**: Modified Makefiles permanently
1. `backend/fragmentation/NewFastEncoder/Release/makefile`:
   - Added: `CXXFLAGS = -std=c++20 -I/usr/local/include`
2. `backend/fragmentation/NewFastEncoder/Release/src/subdir.mk`:
   - Modified compilation rule: `g++ -std=c++20 -g -O0 -I/usr/local/include ...`

#### Final Approach (Embedded Code)
**Dockerfile Optimization**:
```dockerfile
# Copy source code into image
COPY NewFastEncoder /app/NewFastEncoder

# Compile during build (not runtime)
WORKDIR /app/NewFastEncoder/Release
RUN make clean && make

# Set entrypoint
ENTRYPOINT ["/app/NewFastEncoder/Release/NewFastEncoder"]
```

**Benefits**:
- ✅ Portable: Works anywhere without manual fixes
- ✅ Fast rebuild: 28 seconds (vs 16 minutes initial) thanks to layer caching
- ✅ Pre-compiled: No compilation at runtime
- ✅ Simplified command: Just mount data volumes

**Build Performance**:
- Initial build: ~16 minutes (RocksDB compilation)
- Rebuild after code changes: ~28 seconds (cached layers)
- Image size: 3.47 GB

### Fragmentation Test Results ✅

#### Test Configuration
- **Dataset**: watdiv100k.nt (15 MB, 110,828 triples)
- **Docker Command**:
```bash
docker run --rm \
  -v "/home/boumi/Documents/PQDAG GUI/storage/rawdata":/rawdata \
  -v "/home/boumi/Documents/PQDAG GUI/storage/bindata":/bindata \
  -v "/home/boumi/Documents/PQDAG GUI/storage/outputdata":/outputdata \
  newfastencoder \
  /rawdata/ /bindata/data.nt
```

#### Performance Metrics
```
Total triples processed: 110,828
┌─────────────────────┬──────────┐
│ Phase               │ Time     │
├─────────────────────┼──────────┤
│ Data encoding       │ 0.096s   │
│ Dictionaries        │ 0.005s   │
│ Sorting (SPO+OPS)   │ 0.094s   │
│ Fragmentation       │ 0.410s   │
│ Re-encoding         │ 0.300s   │
├─────────────────────┼──────────┤
│ TOTAL               │ 0.952s   │
└─────────────────────┴──────────┘

Throughput: ~116,000 triples/second
```

#### Output Generated
- **918 fragments** created
- Each fragment has 3 files:
  - `.data` - Fragment data (23 bytes to 1.2 MB)
  - `.dic` - Dictionary mapping
  - `.schema` - Schema information
- **Index files**:
  - `predicates.txt` (4.4 KB)
  - `spo_index.txt` (20 KB)
  - `ops_index.txt` (1.3 KB)

#### Validation
- ✅ All fragments generated successfully
- ✅ Performance: <1 second for 100k triples
- ✅ Output structure correct (data, dic, schema files)
- ✅ Indexes created properly
- ✅ Docker solution is portable and reproducible

### Storage Configuration

#### Directory Structure
```
storage/                    # Excluded from Git (.gitignore)
├── rawdata/               # INPUT - RDF files
│   └── watdiv100k.nt     # Test dataset (15 MB, 110k triples)
├── bindata/               # TEMPORARY - Intermediate files
│   ├── data.nt           # Encoded triples
│   ├── data.nt_spo       # SPO sorted
│   ├── data.nt_ops       # OPS sorted
│   └── nodes.dic         # Dictionary
└── outputdata/            # OUTPUT - Final fragments (918 files)
    ├── 794.data, 794.dic, 794.schema
    ├── 795.data, 795.dic, 795.schema
    ├── ... (918 fragments total)
    ├── predicates.txt
    ├── spo_index.txt
    └── ops_index.txt
```

## Next Steps

### Completed Features ✅
- ✅ Spring Boot REST API with all endpoints
- ✅ Docker integration with user mapping (no permission issues)
- ✅ Metrics parsing from Docker output
- ✅ File upload with validation (.nt, .ttl)
- ✅ Automatic cleanup (rawdata + bindata)
- ✅ Angular frontend with drag & drop
- ✅ Real-time metrics dashboard
- ✅ Full workflow tested and working

### Ready for Deployment
- ✅ Backend on branch `develop` (merged)
- ✅ Frontend on branch `feature/angular-frontend` (ready to merge)
- ⏳ Update documentation
- ⏳ Merge frontend to develop
- ⏳ Create deployment guide

### Future Enhancements
- [ ] WebSocket integration for live Docker logs
- [ ] Phase 2: Allocation Step
- [ ] Phase 3: Core/Query Step
- [ ] Docker Compose for full stack deployment
- [ ] Production optimization (nginx, SSL, etc.)

## Current Phase
✅ **Fragmentation GUI Complete** - Full workflow tested successfully with Angular frontend and Spring Boot backend.

## Backend API (Spring Boot)

### Technology Stack
- **Framework**: Spring Boot 3.2.1
- **Language**: Java 17
- **Build Tool**: Maven
- **Dependencies**:
  - Spring Web (REST API)
  - Spring WebSocket (for future live logs)
  - Spring DevTools
  - Lombok (reduce boilerplate)
  
### Configuration
- **Port**: 8080
- **CORS**: Enabled for `http://localhost:4200` (Angular dev server)
- **File Upload**: Max size 1GB
- **Storage Paths**:
  - rawdata: `../../storage/rawdata`
  - bindata: `../../storage/bindata`
  - outputdata: `../../storage/outputdata`

### REST Endpoints

#### 1. Health Check
```http
GET /api/health
```
**Response**:
```json
{
  "status": "UP",
  "service": "PQDAG API",
  "timestamp": 1734298765000
}
```

#### 2. File Upload
```http
POST /api/files/upload
Content-Type: multipart/form-data
```
**Parameters**:
- `files`: MultipartFile[] (one or more .nt or .ttl files)

**Response**:
```json
{
  "success": true,
  "message": "2 file(s) uploaded successfully",
  "uploadedFiles": ["dataset1.nt", "dataset2.nt"]
}
```

#### 3. List Files
```http
GET /api/files/list
```
**Response**:
```json
{
  "files": ["dataset1.nt", "dataset2.nt"],
  "totalSize": 15728640,
  "count": 2
}
```

#### 4. Clear Files
```http
DELETE /api/files/clear
```
**Response**:
```json
{
  "success": true,
  "message": "All files cleared successfully"
}
```

#### 5. Start Fragmentation
```http
POST /api/fragmentation/start
Content-Type: application/json
```
**Request Body**:
```json
{
  "cleanAfter": true
}
```

**Response**:
```json
{
  "success": true,
  "message": "Fragmentation completed successfully",
  "fragmentCount": 918,
  "totalTriples": 110828,
  "executionTimeSeconds": 1.522,
  "throughput": 72787,
  "encodingTime": 0.120111,
  "dictionariesTime": 0.00635933,
  "sortingTime": 0.0997743,
  "fragmentationTime": 0.974874,
  "reencodingTime": 0.31989,
  "dockerOutput": "..."
}
```

### Key Services

#### FragmentationService
**Purpose**: Execute Docker fragmentation and parse metrics

**Key Method**: `executeFragmentation(boolean cleanAfter)`
- Cleans bindata and outputdata directories
- Builds Docker command with user mapping (`--user $(id -u):$(id -g)`)
- Executes newfastencoder container
- Parses Docker output for metrics
- Counts generated fragments
- Optionally cleans rawdata and bindata after completion

**Docker Command**:
```bash
docker run --rm \
  --user 1000:1000 \
  -v /path/to/rawdata:/rawdata \
  -v /path/to/bindata:/bindata \
  -v /path/to/outputdata:/outputdata \
  newfastencoder \
  /rawdata/ /bindata/data.nt
```

**Metrics Parsing**: Extracts from Docker output:
- Total triples
- Encoding time
- Dictionaries time
- Sorting time
- Fragmentation time
- Re-encoding time
- Total execution time
- Throughput (triples/second)

#### FileStorageService
**Purpose**: Manage file system operations

**Methods**:
- `uploadFiles()`: Save uploaded files to rawdata
- `listFiles()`: Get list of files with sizes
- `clearRawdata()`: Delete uploaded RDF files
- `clearBindata()`: Delete temporary intermediate files
- `getStorageSize()`: Calculate total storage size

**Directory Cleanup**: Uses `Files.walk()` with `Comparator.reverseOrder()` to delete files AND subdirectories

### Docker User Mapping Solution

**Problem**: Docker created files as root, Spring Boot couldn't delete them

**Solution**: Added `--user $(id -u):$(id -g)` to Docker command
- Files now created with application user ownership
- Cleanup works without permission issues
- No need for sudo or manual cleanup

## Frontend (Angular)

### Technology Stack
- **Framework**: Angular 18 (standalone components)
- **Language**: TypeScript
- **Styling**: SCSS with gradient design
- **HTTP Client**: Angular HttpClient
- **Build Tool**: Angular CLI

### Project Structure
```
frontend/src/app/
├── components/
│   ├── file-upload/              # Drag & drop file upload
│   │   ├── file-upload.component.ts
│   │   ├── file-upload.component.html
│   │   └── file-upload.component.scss
│   └── fragmentation-results/    # Metrics dashboard
│       ├── fragmentation-results.component.ts
│       ├── fragmentation-results.component.html
│       └── fragmentation-results.component.scss
├── services/
│   ├── file.service.ts           # File upload/list/clear
│   └── fragmentation.service.ts  # Start fragmentation
├── models/
│   ├── fragmentation-result.ts   # Result interface
│   ├── fragmentation-request.ts  # Request interface
│   └── upload-response.ts        # Upload response
├── config/
│   └── api.config.ts             # API base URL
├── app.component.ts
├── app.component.html
├── app.component.scss
└── app.config.ts                 # App configuration
```

### Key Components

#### FileUploadComponent
**Features**:
- Drag & drop zone with visual feedback
- File list with size display
- Remove individual files
- Validation (.nt and .ttl only)
- Upload progress indication
- Success/error messages

**Styling**:
- Modern gradient background
- Hover effects
- Responsive design
- Icons for file types

#### FragmentationResultsComponent
**Features**:
- 4 key metric cards:
  - Fragment count
  - Total triples
  - Execution time
  - Throughput (triples/sec)
- Phase breakdown with colored progress bars:
  - Data encoding (blue)
  - Dictionaries (green)
  - Sorting (orange)
  - Fragmentation (purple)
  - Re-encoding (red)
- Percentage calculation for each phase
- Responsive grid layout

### Services

#### FileService
**Methods**:
- `uploadFiles(files: FileList)`: Upload RDF files
- `listFiles()`: Get uploaded files list
- `clearFiles()`: Delete all files

#### FragmentationService
**Methods**:
- `startFragmentation(request: FragmentationRequest)`: Execute fragmentation

### Configuration

**API_CONFIG** (`config/api.config.ts`):
```typescript
export const API_CONFIG = {
  apiUrl: 'http://localhost:8080/api'
};
```

**Why not environment files?**
- Angular 18 standalone components don't auto-wire environment files
- Simpler centralized configuration
- No build configuration needed

### Styling
**Global styles** (`styles.scss`):
- CSS reset
- Modern gradient backgrounds
- Consistent color scheme
- Responsive typography

**Component styles**:
- Scoped SCSS per component
- Gradient effects
- Box shadows and borders
- Smooth transitions

## Deployment & Testing

### Backend Deployment
```bash
cd backend/api
mvn spring-boot:run
```
**Runs on**: http://localhost:8080

### Frontend Deployment
```bash
cd frontend
ng serve --open
```
**Runs on**: http://localhost:4200

### Full Workflow Test
1. ✅ Open http://localhost:4200
2. ✅ Drag & drop .nt or .ttl file
3. ✅ Click "Upload Files"
4. ✅ Check/uncheck "Clean after fragmentation"
5. ✅ Click "Start Fragmentation"
6. ✅ View real-time results with all metrics
7. ✅ Verify fragments created in storage/outputdata/
8. ✅ Verify cleanup if enabled (rawdata and bindata empty)
