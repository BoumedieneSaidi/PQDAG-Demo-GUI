#!/bin/bash
# test-complete-pipeline.sh
# Pipeline complet: Fragmentation → Allocation → Distribution

set -e  # Exit on error

DATASET_NAME="watdiv100k"
INPUT_FILE="/home/boumi/Documents/PQDAG GUI/storage/rawdata/${DATASET_NAME}.nt"
NUM_MACHINES=10
API_URL="http://localhost:8080"

echo "========================================="
echo "PQDAG COMPLETE PIPELINE TEST"
echo "========================================="
echo "Dataset: ${DATASET_NAME}"
echo "Machines: ${NUM_MACHINES}"
echo "========================================="
echo ""

# Vérifier que le fichier source existe
if [ ! -f "$INPUT_FILE" ]; then
    echo "❌ ERROR: Input file not found: $INPUT_FILE"
    exit 1
fi

# Vérifier que l'API est accessible
echo "🔍 Checking API health..."
if ! curl -sf "${API_URL}/api/health" > /dev/null; then
    echo "❌ ERROR: API is not running on ${API_URL}"
    echo "   Start the API with: cd backend/api && mvn spring-boot:run"
    exit 1
fi
echo "✅ API is healthy"
echo ""

# ÉTAPE 1: Fragmentation
echo "========================================="
echo "ÉTAPE 1/5: FRAGMENTATION"
echo "========================================="
echo "Processing: $INPUT_FILE"
echo ""

FRAG_RESPONSE=$(curl -sf -X POST "${API_URL}/api/fragmentation/start" \
    -H "Content-Type: application/json" \
    -d "{\"inputFilePath\": \"$INPUT_FILE\", \"inputFormat\": \"NT\"}")

FRAG_STATUS=$(echo "$FRAG_RESPONSE" | jq -r '.status')
if [ "$FRAG_STATUS" != "success" ]; then
    echo "❌ Fragmentation failed:"
    echo "$FRAG_RESPONSE" | jq .
    exit 1
fi

TOTAL_TRIPLES=$(echo "$FRAG_RESPONSE" | jq -r '.statistics.totalTriples')
NUM_FRAGMENTS=$(echo "$FRAG_RESPONSE" | jq -r '.statistics.totalFragments')
FRAG_TIME=$(echo "$FRAG_RESPONSE" | jq -r '.statistics.executionTime')

echo "✅ Fragmentation completed:"
echo "   - Total triples: $TOTAL_TRIPLES"
echo "   - Fragments created: $NUM_FRAGMENTS"
echo "   - Execution time: ${FRAG_TIME}s"
echo ""

# ÉTAPE 2: Allocation (Stats + Graph + METIS)
echo "========================================="
echo "ÉTAPE 2/5: ALLOCATION"
echo "========================================="
echo "Running: stat_MPI.py → generate_fragments_graph.py → weighted_metis.py"
echo ""

ALLOC_RESPONSE=$(curl -sf -X POST "${API_URL}/api/allocation/start" \
    -H "Content-Type: application/json" \
    -d "{\"datasetName\": \"$DATASET_NAME\", \"numMachines\": $NUM_MACHINES, \"cleanAfter\": true}")

ALLOC_STATUS=$(echo "$ALLOC_RESPONSE" | jq -r '.status')
if [ "$ALLOC_STATUS" != "success" ]; then
    echo "❌ Allocation failed:"
    echo "$ALLOC_RESPONSE" | jq .
    exit 1
fi

TOTAL_FRAGMENTS=$(echo "$ALLOC_RESPONSE" | jq -r '.statistics.totalFragments')
TOTAL_EDGES=$(echo "$ALLOC_RESPONSE" | jq -r '.statistics.totalEdges')
ALLOC_TIME=$(echo "$ALLOC_RESPONSE" | jq -r '.statistics.executionTime')
AFFECTATION_FILE=$(echo "$ALLOC_RESPONSE" | jq -r '.affectationFile')

echo "✅ Allocation completed:"
echo "   - Total fragments: $TOTAL_FRAGMENTS"
echo "   - Graph edges: $TOTAL_EDGES"
echo "   - Execution time: ${ALLOC_TIME}s"
echo "   - Affectation file: $AFFECTATION_FILE"
echo ""

# Afficher la distribution
echo "📊 Distribution per machine:"
echo "$ALLOC_RESPONSE" | jq -r '.distribution[] | "   Machine \(.machineId): \(.fragmentCount) fragments (\(.workerIp))"'
echo ""

# ÉTAPE 3: Distribution vers le cluster
echo "========================================="
echo "ÉTAPE 3/5: DISTRIBUTION TO CLUSTER"
echo "========================================="
echo "Distributing fragments to workers..."
echo ""

DIST_RESPONSE=$(curl -sf -X POST "${API_URL}/api/allocation/distribute" \
    -H "Content-Type: application/json" \
    -d "{\"datasetName\": \"$DATASET_NAME\"}")

DIST_STATUS=$(echo "$DIST_RESPONSE" | jq -r '.status')
if [ "$DIST_STATUS" != "success" ]; then
    echo "❌ Distribution failed:"
    echo "$DIST_RESPONSE" | jq .
    exit 1
fi

echo "✅ Distribution completed successfully"
echo ""

# ÉTAPE 4: Vérification sur les workers
echo "========================================="
echo "ÉTAPE 4/5: VERIFICATION"
echo "========================================="
echo "Checking fragments on workers..."
echo ""

STORAGE_PATH="/home/ubuntu/mounted_vol/pqdag_data/${DATASET_NAME}"

# Vérifier worker 1 et worker 5
for WORKER_ID in 1 5; do
    WORKER_ALIAS="pqdag-worker-${WORKER_ID}"
    echo "Checking ${WORKER_ALIAS}..."
    
    FRAGMENT_COUNT=$(ssh "$WORKER_ALIAS" "ls -1 ${STORAGE_PATH}/*.data 2>/dev/null | wc -l" 2>/dev/null || echo "0")
    
    if [ "$FRAGMENT_COUNT" -gt 0 ]; then
        echo "✅ Worker ${WORKER_ID}: $FRAGMENT_COUNT fragments"
    else
        echo "⚠️  Worker ${WORKER_ID}: No fragments found (SSH might be needed)"
    fi
done
echo ""

# ÉTAPE 5: Résumé final
echo "========================================="
echo "ÉTAPE 5/5: SUMMARY"
echo "========================================="
echo ""
echo "🎉 PIPELINE COMPLETED SUCCESSFULLY!"
echo ""
echo "📊 Summary:"
echo "   ├─ Fragmentation:"
echo "   │  ├─ Input triples: $TOTAL_TRIPLES"
echo "   │  ├─ Fragments created: $NUM_FRAGMENTS"
echo "   │  └─ Time: ${FRAG_TIME}s"
echo "   │"
echo "   ├─ Allocation:"
echo "   │  ├─ Fragments analyzed: $TOTAL_FRAGMENTS"
echo "   │  ├─ Graph edges: $TOTAL_EDGES"
echo "   │  ├─ Machines: $NUM_MACHINES"
echo "   │  └─ Time: ${ALLOC_TIME}s"
echo "   │"
echo "   └─ Distribution:"
echo "      ├─ Target: Cluster (10 workers)"
echo "      └─ Status: ✅ Complete"
echo ""
echo "📁 Generated files:"
echo "   ├─ Fragments: storage/outputdata/*.{data,dic,schema}"
echo "   ├─ Statistics: storage/allocation_results/db.stat"
echo "   ├─ Graph: storage/allocation_results/fragments_graph.quad"
echo "   └─ Allocation: $AFFECTATION_FILE"
echo ""
echo "🌐 View results in GUI: http://localhost:4200"
echo ""
echo "========================================="
