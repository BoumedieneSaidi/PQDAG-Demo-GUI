# 🎯 PQDAG Complete Pipeline Guide

This document explains how to use the complete **Fragmentation → Allocation → Distribution** pipeline for PQDAG.

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Starting the System](#starting-the-system)
3. [Pipeline Workflow](#pipeline-workflow)
4. [Troubleshooting](#troubleshooting)

---

## 🔧 Prerequisites

### Backend API (Spring Boot)

The backend must be running on port **8080**:

```bash
cd backend/api
mvn spring-boot:run
```

✅ Verify: `curl http://localhost:8080/api/health`

### Frontend (Angular)

The frontend should be running on port **4200**:

```bash
cd frontend
ng serve
```

✅ Verify: Open http://localhost:4200

### Docker (for allocation)

Make sure Docker is running and the allocation image is built:

```bash
docker images | grep pqdag-allocation
```

### SSH Access (for distribution)

Ensure SSH keys are configured for cluster access:

```bash
ssh pqdag-master 'echo "Connection OK"'
ssh pqdag-worker-1 'echo "Connection OK"'
```

---

## 🚀 Starting the System

### Option 1: Using the GUI (Recommended)

1. **Open the application**: http://localhost:4200

2. **Navigate between tabs**:
   - Click **📦 Fragmentation** for the fragmentation interface
   - Click **🎯 Allocation** for the allocation interface

### Option 2: Using REST API directly

See [backend/api/ALLOCATION_API.md](backend/api/ALLOCATION_API.md) for curl examples.

---

## 📊 Pipeline Workflow

### Step 1: Fragmentation 📦

**Goal**: Transform RDF data into fragments

1. **Upload RDF file**:
   - Drag & drop or click to select `.nt` or `.ttl` file
   - File will be uploaded to `storage/rawdata/`

2. **Configure fragmentation**:
   - ☑️ Check "Clean raw data after fragmentation" (optional)
   - Click **▶ Start Fragmentation**

3. **View results**:
   - **918 fragments** generated (for watdiv100k)
   - **110,828 triples** processed
   - **Execution time**: ~1.4s
   - **Throughput**: ~77,319 triples/second

4. **Next step**:
   - Click **🚀 Start Allocation & Distribution** button
   - Or manually switch to the **🎯 Allocation** tab

**Generated files**:
```
storage/
├── outputdata/
│   ├── 1.data, 1.dic, 1.schema
│   ├── 2.data, 2.dic, 2.schema
│   ├── ... (918 fragments)
│   ├── spo_index.txt
│   ├── ops_index.txt
│   └── predicates.txt
```

---

### Step 2: Allocation 🎯

**Goal**: Optimize fragment distribution across cluster nodes

1. **Configure allocation**:
   - **Dataset Name**: `watdiv100k` (auto-filled)
   - **Number of Machines**: `10` (adjust as needed)

2. **Start allocation**:
   - Click **🚀 Start Allocation**
   - Wait for the 3-step pipeline to complete:
     - ✓ Statistics Generation (stat_MPI.py with MPI)
     - ✓ Graph Generation (dependency graph)
     - ✓ METIS Partitioning (optimal allocation)

3. **View results**:
   - **Total Fragments**: 1,836 (918 × 2 for SPO+OPS)
   - **Graph Edges**: 174,748
   - **Execution Time**: ~20s
   - **Distribution**: 89-94 fragments per machine (balanced)

4. **Inspect visualizations**:
   - **📈 Bar Chart**: Fragment count per worker
   - **📋 Table**: Detailed distribution with percentages
   - **📁 Files**: db.stat, fragments_graph.quad, affectation file

**Generated files**:
```
storage/
├── allocation_results/
│   ├── db.stat (1.1M - fragment statistics)
│   ├── fragments_graph.quad (1.1M - dependency graph)
│   └── affectation_weighted_metis.txt (8K - allocation mapping)
```

---

### Step 3: Distribution 📤

**Goal**: Deploy fragments to cluster workers via SSH

1. **Distribute to cluster**:
   - Click **📤 Distribute to Cluster**
   - The system will:
     - Create 10 tar.gz archives (one per worker)
     - Transfer via SCP through jump host
     - Extract on each worker
     - Load into BTrees

2. **Monitor distribution**:
   - Progress indicator shows transfer status
   - Success message confirms completion

3. **Verify on cluster**:
   ```bash
   ssh pqdag-worker-1 'ls -la /home/ubuntu/mounted_vol/pqdag_data/watdiv100k/*.data | wc -l'
   # Output: 89 (fragments on worker 1)
   ```

**Cluster layout**:
```
Master (192.168.165.27):
└── /home/ubuntu/mounted_vol/pqdag_temp_data/
    ├── spo_index.txt
    ├── ops_index.txt
    └── predicates.txt

Worker 1 (192.168.165.101):
└── /home/ubuntu/mounted_vol/pqdag_data/watdiv100k/
    ├── 1.data, 1.dic, 1.schema
    ├── 5.data, 5.dic, 5.schema
    └── ... (89 fragments)

Worker 2-10: (similar structure, 89-94 fragments each)
```

---

## 🧪 Testing the Complete Pipeline

### Quick Test (using existing fragments)

If you already have fragments in `storage/outputdata/`:

```bash
cd /home/boumi/Documents/PQDAG\ GUI
./test-complete-pipeline.sh
```

### Full Test (from scratch)

1. Place RDF file in `storage/rawdata/watdiv100k.nt`
2. Open GUI: http://localhost:4200
3. Follow the workflow: Fragmentation → Allocation → Distribution

### API Test (command line)

```bash
# 1. Fragmentation
curl -X POST http://localhost:8080/api/fragmentation/start \
  -H "Content-Type: application/json" \
  -d '{"inputFilePath": "/home/boumi/Documents/PQDAG GUI/storage/rawdata/watdiv100k.nt", "inputFormat": "NT"}'

# 2. Allocation
curl -X POST http://localhost:8080/api/allocation/start \
  -H "Content-Type: application/json" \
  -d '{"datasetName": "watdiv100k", "numMachines": 10, "cleanAfter": true}' | jq .

# 3. Distribution
curl -X POST http://localhost:8080/api/allocation/distribute \
  -H "Content-Type: application/json" \
  -d '{"datasetName": "watdiv100k"}' | jq .
```

---

## 🐛 Troubleshooting

### Backend not responding

```bash
# Check if backend is running
curl http://localhost:8080/api/health

# If not, restart it
cd backend/api
pkill -f "spring-boot:run"
mvn spring-boot:run
```

### Frontend not loading

```bash
# Check if Angular dev server is running
curl http://localhost:4200

# If not, restart it
cd frontend
pkill -f "ng serve"
ng serve
```

### Docker allocation fails

```bash
# Check Docker is running
docker ps

# Check allocation image exists
docker images | grep pqdag-allocation

# If missing, rebuild it
cd backend/allocation
docker build -t pqdag-allocation:latest .
```

### SSH distribution fails

```bash
# Test SSH connectivity
ssh pqdag-master 'echo "Master OK"'
ssh pqdag-worker-1 'echo "Worker 1 OK"'

# Re-setup SSH if needed
./setup-ssh-cluster.sh
```

### Port conflicts

```bash
# Backend (port 8080)
lsof -ti:8080 | xargs kill -9

# Frontend (port 4200)
lsof -ti:4200 | xargs kill -9
```

### Storage folder issues

```bash
# Check fragment count
ls -1 storage/outputdata/*.data | wc -l

# Check allocation results
ls -lh storage/allocation_results/

# Clean up for fresh start
rm -rf storage/outputdata/*
rm -rf storage/allocation_results/*
rm -rf storage/allocation_temp/*
```

---

## 📚 Additional Resources

- **Backend API Documentation**: [backend/api/ALLOCATION_API.md](backend/api/ALLOCATION_API.md)
- **Frontend Documentation**: [frontend/README.md](frontend/README.md)
- **Cluster Access**: [CLUSTER_ACCESS.md](CLUSTER_ACCESS.md)
- **Docker Setup**: [DOCKER.md](DOCKER.md)

---

## 🎉 Success Indicators

✅ **Fragmentation complete**:
- 918 fragments in `storage/outputdata/`
- Green success banner with metrics

✅ **Allocation complete**:
- db.stat (1.1M), fragments_graph.quad (1.1M), affectation file (8K)
- Distribution chart shows balanced allocation

✅ **Distribution complete**:
- All 10 workers have fragments in `/home/ubuntu/mounted_vol/pqdag_data/watdiv100k/`
- Green "Success" message in GUI

---

## 📞 Support

For issues or questions:
- Check the troubleshooting section above
- Review component READMEs
- Examine backend logs: `/tmp/pqdag-api.log`
- Check frontend console: Browser DevTools → Console

---

**Last Updated**: December 16, 2025  
**Version**: 2.0.0 (Phase 2 - Allocation Complete)
