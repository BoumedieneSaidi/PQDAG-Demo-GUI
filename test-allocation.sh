#!/bin/bash
###############################################################################
# Test Script for PQDAG Allocation System (Docker)
# This script tests the allocation pipeline step by step
###############################################################################

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "=========================================="
echo "PQDAG Allocation - Test Suite (Docker)"
echo "=========================================="
echo ""

DATASET_NAME=${1:-test_dataset}
WORKSPACE_ROOT="/app"

echo -e "${YELLOW}📋 Dataset: $DATASET_NAME${NC}"
echo ""

###############################################################################
# Test 1: Verify Docker image exists
###############################################################################
echo -e "${YELLOW}Test 1: Vérification de l'image Docker${NC}"
if docker image inspect pqdag-allocation:latest >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Image pqdag-allocation:latest existe${NC}"
else
    echo -e "${RED}❌ Image non trouvée. Construire avec: docker build -t pqdag-allocation:latest backend/allocation/${NC}"
    exit 1
fi
echo ""

###############################################################################
# Test 2: Verify Python dependencies in container
###############################################################################
echo -e "${YELLOW}Test 2: Vérification des dépendances Python${NC}"
docker run --rm pqdag-allocation:latest bash -c "
    python3 -c 'import yaml' && echo '✅ PyYAML OK' || echo '❌ PyYAML manquant'
    python3 -c 'import mpi4py' && echo '✅ mpi4py OK' || echo '❌ mpi4py manquant'
    python3 -c 'import pymetis' && echo '✅ pymetis OK' || echo '❌ pymetis manquant'
"
echo ""

###############################################################################
# Test 3: Verify MPI runtime
###############################################################################
echo -e "${YELLOW}Test 3: Vérification du runtime MPI${NC}"
docker run --rm pqdag-allocation:latest bash -c "
    which mpiexec && echo '✅ mpiexec trouvé' || echo '❌ mpiexec manquant'
    mpiexec --version | head -n1
"
echo ""

###############################################################################
# Test 4: Generate dynamic configuration
###############################################################################
echo -e "${YELLOW}Test 4: Génération de la configuration dynamique${NC}"
docker run --rm \
    -v "$(pwd)/storage:/app/storage" \
    -v "$(pwd)/backend/allocation:/app/allocation" \
    pqdag-allocation:latest \
    python3 generate_config.py $DATASET_NAME $WORKSPACE_ROOT

if [ -f "backend/allocation/config_runtime.yaml" ]; then
    echo -e "${GREEN}✅ Configuration générée: backend/allocation/config_runtime.yaml${NC}"
    echo ""
    echo "Contenu:"
    head -20 backend/allocation/config_runtime.yaml
else
    echo -e "${RED}❌ Échec de génération de config${NC}"
    exit 1
fi
echo ""

###############################################################################
# Test 5: Verify fragment files exist
###############################################################################
echo -e "${YELLOW}Test 5: Vérification des fichiers de fragments${NC}"
FRAGMENT_COUNT=$(ls -1 storage/outputdata/*.data 2>/dev/null | wc -l)
if [ $FRAGMENT_COUNT -gt 0 ]; then
    echo -e "${GREEN}✅ $FRAGMENT_COUNT fragments trouvés dans storage/outputdata/${NC}"
    
    # Check index files
    if [ -f "storage/outputdata/spo_index.txt" ]; then
        echo -e "${GREEN}✅ spo_index.txt présent${NC}"
    else
        echo -e "${RED}❌ spo_index.txt manquant${NC}"
    fi
    
    if [ -f "storage/outputdata/ops_index.txt" ]; then
        echo -e "${GREEN}✅ ops_index.txt présent${NC}"
    else
        echo -e "${RED}❌ ops_index.txt manquant${NC}"
    fi
else
    echo -e "${RED}❌ Aucun fragment trouvé. Exécuter la fragmentation d'abord.${NC}"
    exit 1
fi
echo ""

###############################################################################
# Test 6: Run stat_MPI.py (Statistics Calculation)
###############################################################################
echo -e "${YELLOW}Test 6: Calcul des statistiques (stat_MPI.py)${NC}"
echo "Commande: mpiexec -n 4 python3 stat_MPI.py ..."

docker run --rm \
    -v "$(pwd)/storage:/app/storage" \
    -v "$(pwd)/backend/allocation:/app/allocation" \
    pqdag-allocation:latest \
    bash -c "cd /app/allocation && mpiexec -n 4 python3 stat_MPI.py /app/storage/outputdata /app/storage/allocation_results/db.stat"

if [ -f "storage/allocation_results/db.stat" ]; then
    STAT_SIZE=$(wc -l storage/allocation_results/db.stat | awk '{print $1}')
    echo -e "${GREEN}✅ db.stat généré ($STAT_SIZE lignes)${NC}"
    echo "Aperçu:"
    head -5 storage/allocation_results/db.stat
else
    echo -e "${RED}❌ Échec de génération de db.stat${NC}"
    exit 1
fi
echo ""

###############################################################################
# Test 7: Generate Fragment Graph
###############################################################################
echo -e "${YELLOW}Test 7: Génération du graphe de fragments${NC}"
docker run --rm \
    -v "$(pwd)/storage:/app/storage" \
    -v "$(pwd)/backend/allocation:/app/allocation" \
    pqdag-allocation:latest \
    python3 generate_fragments_graph.py /app/storage/allocation_results/db.stat /app/storage/allocation_results/fragments_graph.quad

if [ -f "storage/allocation_results/fragments_graph.quad" ]; then
    GRAPH_SIZE=$(wc -l storage/allocation_results/fragments_graph.quad | awk '{print $1}')
    echo -e "${GREEN}✅ fragments_graph.quad généré ($GRAPH_SIZE arêtes)${NC}"
    echo "Aperçu:"
    head -5 storage/allocation_results/fragments_graph.quad
else
    echo -e "${RED}❌ Échec de génération du graphe${NC}"
    exit 1
fi
echo ""

###############################################################################
# Test 8: Run METIS Allocation (Optional - if 10 workers configured)
###############################################################################
echo -e "${YELLOW}Test 8: Allocation avec METIS (optionnel)${NC}"
NUM_WORKERS=$(wc -l < backend/allocation/workers)
echo "Nombre de workers configurés: $NUM_WORKERS"

if [ $NUM_WORKERS -gt 0 ]; then
    docker run --rm \
        -v "$(pwd)/storage:/app/storage" \
        -v "$(pwd)/backend/allocation:/app/allocation" \
        pqdag-allocation:latest \
        bash -c "cd /app/allocation/allocation_approaches && python3 weighted_metis.py /app/storage/allocation_results/fragments_graph.quad /app/storage/allocation_results/affectation_weighted_metis.txt $NUM_WORKERS"
    
    if [ -f "storage/allocation_results/affectation_weighted_metis.txt" ]; then
        AFFECTATION_SIZE=$(wc -l storage/allocation_results/affectation_weighted_metis.txt | awk '{print $1}')
        echo -e "${GREEN}✅ Affectation générée ($AFFECTATION_SIZE fragments alloués)${NC}"
        echo "Aperçu:"
        head -10 storage/allocation_results/affectation_weighted_metis.txt
    else
        echo -e "${YELLOW}⚠️  Affectation non générée (peut nécessiter pymetis)${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Aucun worker configuré dans backend/allocation/workers${NC}"
fi
echo ""

###############################################################################
# Summary
###############################################################################
echo "=========================================="
echo -e "${GREEN}✅ Tests d'allocation terminés${NC}"
echo "=========================================="
echo ""
echo "Fichiers générés dans storage/allocation_results/:"
ls -lh storage/allocation_results/ 2>/dev/null || echo "Aucun fichier"
echo ""
echo "Prochaines étapes:"
echo "  1. Vérifier les résultats dans storage/allocation_results/"
echo "  2. Distribuer aux workers: python3 distribute_fragments.py --config_file config_runtime.yaml"
echo "  3. Intégrer dans le GUI backend"
echo ""
