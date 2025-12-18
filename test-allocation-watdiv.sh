#!/bin/bash
###############################################################################
# Test PQDAG Allocation - watdiv100k (3 étapes seulement)
# 1. Statistics (stat_MPI.py) → db.stat
# 2. Graph (generate_fragments_graph.py) → fragments_graph.quad  
# 3. Allocation (weighted_metis.py) → affectation_weighted_metis.txt
###############################################################################

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "=========================================="
echo "Test Allocation - watdiv100k"
echo "=========================================="
echo ""

# Vérifier que les fragments existent
FRAGMENT_COUNT=$(ls -1 storage/outputdata/*.data 2>/dev/null | wc -l)
if [ $FRAGMENT_COUNT -eq 0 ]; then
    echo -e "${RED}❌ Aucun fragment trouvé dans storage/outputdata/${NC}"
    echo "Exécuter la fragmentation d'abord"
    exit 1
fi

echo -e "${GREEN}✅ $FRAGMENT_COUNT fragments détectés${NC}"
echo ""

###############################################################################
# ÉTAPE 1: Génération des statistiques (db.stat)
###############################################################################
echo -e "${YELLOW}=== ÉTAPE 1: Calcul des statistiques (MPI) ===${NC}"
echo "Commande: mpiexec -n 4 python3 stat_MPI.py"
echo ""

docker run --rm \
    -v "$(pwd)/storage:/app/storage" \
    -v "$(pwd)/backend/allocation:/app/allocation" \
    pqdag-allocation:latest \
    bash -c "cd /app/allocation && mpiexec -n 4 python3 stat_MPI.py /app/storage/outputdata /app/storage/allocation_results/db.stat"

if [ -f "storage/allocation_results/db.stat" ]; then
    STAT_LINES=$(wc -l < storage/allocation_results/db.stat)
    STAT_SIZE=$(du -h storage/allocation_results/db.stat | cut -f1)
    echo -e "${GREEN}✅ db.stat généré: $STAT_LINES lignes ($STAT_SIZE)${NC}"
    echo ""
    echo "Aperçu (5 premières lignes):"
    head -5 storage/allocation_results/db.stat
    echo ""
else
    echo -e "${RED}❌ Échec génération db.stat${NC}"
    exit 1
fi

###############################################################################
# ÉTAPE 2: Génération du graphe de fragments
###############################################################################
echo -e "${YELLOW}=== ÉTAPE 2: Génération du graphe de fragments ===${NC}"
echo "Commande: python3 generate_fragments_graph.py"
echo ""

docker run --rm \
    -v "$(pwd)/storage:/app/storage" \
    -v "$(pwd)/backend/allocation:/app/allocation" \
    pqdag-allocation:latest \
    python3 generate_fragments_graph.py \
        /app/storage/allocation_results/db.stat \
        /app/storage/allocation_results/fragments_graph.quad

if [ -f "storage/allocation_results/fragments_graph.quad" ]; then
    GRAPH_LINES=$(wc -l < storage/allocation_results/fragments_graph.quad)
    GRAPH_SIZE=$(du -h storage/allocation_results/fragments_graph.quad | cut -f1)
    echo -e "${GREEN}✅ fragments_graph.quad généré: $GRAPH_LINES arêtes ($GRAPH_SIZE)${NC}"
    echo ""
    echo "Aperçu (5 premières arêtes):"
    head -5 storage/allocation_results/fragments_graph.quad
    echo ""
else
    echo -e "${RED}❌ Échec génération graphe${NC}"
    exit 1
fi

###############################################################################
# ÉTAPE 3: Allocation avec METIS
###############################################################################
echo -e "${YELLOW}=== ÉTAPE 3: Allocation METIS ===${NC}"

# Nombre de machines depuis workers file
NUM_WORKERS=$(wc -l < backend/allocation/workers 2>/dev/null || echo "10")
echo "Nombre de workers: $NUM_WORKERS"
echo "Commande: python3 weighted_metis.py ... $NUM_WORKERS"
echo ""

docker run --rm \
    -v "$(pwd)/storage:/app/storage" \
    -v "$(pwd)/backend/allocation:/app/allocation" \
    pqdag-allocation:latest \
    bash -c "cd /app/allocation/allocation_approaches && python3 weighted_metis.py \
        /app/storage/allocation_results/fragments_graph.quad \
        /app/storage/allocation_results/affectation_weighted_metis.txt \
        $NUM_WORKERS"

if [ -f "storage/allocation_results/affectation_weighted_metis.txt" ]; then
    AFFECTATION_LINES=$(wc -l < storage/allocation_results/affectation_weighted_metis.txt)
    AFFECTATION_SIZE=$(du -h storage/allocation_results/affectation_weighted_metis.txt | cut -f1)
    echo -e "${GREEN}✅ Affectation générée: $AFFECTATION_LINES fragments alloués ($AFFECTATION_SIZE)${NC}"
    echo ""
    echo "Aperçu (10 premières allocations):"
    head -10 storage/allocation_results/affectation_weighted_metis.txt
    echo ""
    
    # Statistiques par machine
    echo "Distribution des fragments par machine:"
    cut -d' ' -f2 storage/allocation_results/affectation_weighted_metis.txt | sort | uniq -c | sort -n
    echo ""
else
    echo -e "${YELLOW}⚠️  Affectation non générée${NC}"
    echo "Vérifier que pymetis est installé dans l'image Docker"
fi

###############################################################################
# Résumé
###############################################################################
echo "=========================================="
echo -e "${GREEN}✅ Test d'allocation terminé${NC}"
echo "=========================================="
echo ""
echo "Fichiers générés dans storage/allocation_results/:"
ls -lh storage/allocation_results/
echo ""
echo "Prochaines étapes:"
echo "  ✅ Étapes 1-3 (stats, graph, allocation) testées"
echo "  ⏭️  Étape 4 (distribution) - sera intégrée dans le GUI"
echo "  📋 Étape 5 (chargement BTree) - exécutée sur le cluster"
echo ""
