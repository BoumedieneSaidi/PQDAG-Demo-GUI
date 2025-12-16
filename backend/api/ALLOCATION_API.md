# Allocation API Documentation

## Endpoints

### 1. Start Allocation
Execute the allocation pipeline (steps 1-3: statistics, graph generation, METIS).

**Endpoint**: `POST /api/allocation/start`

**Request Body**:
```json
{
  "datasetName": "watdiv100k",
  "numMachines": 10,
  "cleanAfter": true
}
```

**Response**:
```json
{
  "status": "success",
  "message": "Allocation completed successfully",
  "statistics": {
    "totalFragments": 918,
    "totalEdges": 87374,
    "executionTime": 12.5,
    "dbStatFile": "/path/to/db.stat",
    "graphFile": "/path/to/fragments_graph.quad"
  },
  "distribution": [
    { "machineId": 1, "fragmentCount": 89, "workerIp": "192.168.165.101" },
    { "machineId": 2, "fragmentCount": 93, "workerIp": "192.168.165.138" },
    ...
  ],
  "affectationFile": "/path/to/affectation_weighted_metis.txt"
}
```

### 2. Distribute to Cluster
Distribute fragments to the cluster (step 4).

**Endpoint**: `POST /api/allocation/distribute`

**Request Body**:
```json
{
  "datasetName": "watdiv100k"
}
```

**Response**:
```json
{
  "status": "success",
  "message": "Distribution completed successfully"
}
```

### 3. Get Allocation Results
Retrieve allocation results for a dataset.

**Endpoint**: `GET /api/allocation/results/{datasetName}`

**Response**: Same as Start Allocation response.

## Testing

### Test Allocation
```bash
curl -X POST http://localhost:8080/api/allocation/start \
  -H "Content-Type: application/json" \
  -d '{
    "datasetName": "watdiv100k",
    "numMachines": 10,
    "cleanAfter": true
  }' | jq .
```

### Test Distribution
```bash
curl -X POST http://localhost:8080/api/allocation/distribute \
  -H "Content-Type: application/json" \
  -d '{
    "datasetName": "watdiv100k"
  }' | jq .
```

### Get Results
```bash
curl http://localhost:8080/api/allocation/results/watdiv100k | jq .
```

## Implementation Details

### Steps Executed

#### Step 1: Statistics (stat_MPI.py)
- Runs in Docker with MPI (4 processes)
- Analyzes fragment files from `storage/outputdata/`
- Generates `db.stat` with fragment statistics

#### Step 2: Graph Generation (generate_fragments_graph.py)
- Reads `db.stat`
- Generates weighted dependency graph
- Outputs `fragments_graph.quad`

#### Step 3: METIS Allocation (weighted_metis.py)
- Graph partitioning using METIS algorithm
- Balances fragments across N machines
- Outputs `affectation_weighted_metis.txt`

#### Step 4: Distribution (distribute_fragments.py)
- Creates tar archives per worker
- Transfers via SSH/SCP (jump host supported)
- Extracts on workers
- Loads into BTrees

### Configuration

Edit `application.properties`:
```properties
# Workspace root (where PQDAG GUI is located)
workspace.root=/home/boumi/Documents/PQDAG GUI

# Docker image for allocation
docker.image=pqdag-allocation:latest
```

### Prerequisites

1. Docker image must be built:
   ```bash
   cd backend/allocation
   docker build -t pqdag-allocation:latest .
   ```

2. SSH keys must be configured for cluster access:
   ```bash
   ./setup-ssh-cluster.sh
   ```

3. Fragments must exist in `storage/outputdata/`

## Error Handling

All endpoints return error responses in this format:
```json
{
  "status": "error",
  "message": "Error description here"
}
```

Common errors:
- `Config generation failed`: Invalid dataset name or workspace path
- `Statistics calculation failed`: Missing fragments or Docker issues
- `Graph generation failed`: db.stat file missing or corrupted
- `METIS allocation failed`: Invalid graph or number of machines
- `Distribution failed`: SSH connection issues or missing affectation file
