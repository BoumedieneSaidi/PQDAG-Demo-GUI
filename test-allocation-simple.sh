#!/bin/bash
###############################################################################
# Test Allocation Pipeline (3 étapes seulement)
# 1. Statistics (stat_MPI.py)
# 2. Fragment Graph (generate_fragments_graph.py)
# 3. METIS Allocation (weighted_metis.py)
###############################################################################

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

DATASET="watdiv100k"

echo "=========================================="
echo "Test Allocation - $DATASET"
echo "=========================================="
echo ""

# Vérifier les fragments
FRAGMENT_COUNT=$(ls -1 storage/outputdata/*.data 2>/dev/null | wc -l)
echo -e "${GREEN}✅ $FRAGMENT_COUNT fragments détectés${NC}"
echo ""

###############################################################################
# ÉTAPE 1: Calcul des statistiques avec MPI
###############################################################################
echo -e "${YELLOW}=== ÉTAPE 1: Calcul des statistiques (MPI) ===${NC}"
echo "Commande: mpiexec -n 4 python3 stat_MPI.py"
echo ""

docker run --rm \
    -v "$(pwd)/storage:/app/storage" \
    -v "$(pwd)/backend/allocation:/app/allocation" \
    pqdag-allocation:latest \
    bash -c "cd /app/allocation && mpiexec -n 4 python3 stat_MPI.py /app/storage/outputdata/ /app/storage/allocation_results/db"

if [ -f "storage/allocation_results/db.stat" ]; then
    LINES=$(wc -l storage/allocation_results/db.stat | awk '{print $1}')
    SIZE=$(du -h storage/allocation_results/db.stat | awk '{print $1}')
    echo ""
    echo -e "${GREEN}✅ ÉTAPE 1 RÉUSSIE${NC}"
    echo "   Fichier: db.stat"
    echo "   Lignes: $LINES"
    echo "   Taille: $SIZE"
    echo "   Aperçu:"
    head -3 storage/allocation_results/db.stat
else
    echo -e "${RED}❌ ÉCHEC ÉTAPE 1${NC}"
    exit 1
fi
echo ""

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
    python3 generate_fragments_graph.py /app/storage/allocation_results/db.stat /app/storage/allocation_results/fragments_graph.quad

if [ -f "storage/allocation_results/fragments_graph.quad" ]; then
    LINES=$(wc -l storage/allocation_results/fragments_graph.quad | awk '{print $1}')
    SIZE=$(du -h storage/allocation_results/fragments_graph.quad | awk '{print $1}')
    echo ""
    echo -e "${GREEN}✅ ÉTAPE 2 RÉUSSIE${NC}"
    echo "   Fichier: fragments_graph.quad"
    echo "   Arêtes: $LINES"
    echo "   Taille: $SIZE"
    echo "   Aperçu:"
    head -3 storage/allocation_results/fragments_graph.quad
else
    echo -e "${RED}❌ ÉCHEC ÉTAPE 2${NC}"
    exit 1
fi
echo ""

###############################################################################
# ÉTAPE 3: Allocation METIS
###############################################################################
echo -e "${YELLOW}=== ÉTAPE 3: Allocation avec METIS ===${NC}"
NUM_WORKERS=$(wc -l < backend/allocation/workers 2>/dev/null || echo "10")
echo "Nombre de workers: $NUM_WORKERS"
echo "Commande: python3 weighted_metis.py"
echo ""

docker run --rm \
    -v "$(pwd)/storage:/app/storage" \
    -v "$(pwd)/backend/allocation:/app/allocation" \
    pqdag-allocation:latest \
    bash -c "cd /app/allocation/allocation_approaches && python3 weighted_metis.py /app/storage/allocation_results/fragments_graph.quad /app/storage/allocation_results/affectation_weighted_metis.txt $NUM_WORKERS"

if [ -f "storage/allocation_results/affectation_weighted_metis.txt" ]; then
    LINES=$(wc -l storage/allocation_results/affectation_weighted_metis.txt | awk '{print $1}')
    SIZE=$(du -h storage/allocation_results/affectation_weighted_metis.txt | awk '{print $1}')
    echo ""
    echo -e "${GREEN}✅ ÉTAPE 3 RÉUSSIE${NC}"
    echo "   Fichier: affectation_weighted_metis.txt"
    echo "   Allocations: $LINES"
    echo "   Taille: $SIZE"
    echo "   Aperçu:"
    head -10 storage/allocation_results/affectation_weighted_metis.txt
    echo ""
    
    # Statistiques par machine
    echo "Distribution des fragments par machine:"
    awk '{print $2}' storage/allocation_results/affectation_weighted_metis.txt | sort | uniq -c
else
    echo -e "${RED}❌ ÉCHEC ÉTAPE 3${NC}"
    exit 1
fi
echo ""

###############################################################################
# RÉSUMÉ
###############################################################################
echo "=========================================="
echo -e "${GREEN}✅ PIPELINE D'ALLOCATION TERMINÉ${NC}"
echo "=========================================="
echo ""
echo "Résultats dans storage/allocation_results/:"
ls -lh storage/allocation_results/
echo ""
echo "Prochaine étape (à implémenter dans GUI):"
echo "  - Afficher les statistiques d'allocation"
echo "  - Visualiser la distribution des fragments"
echo "  - (Plus tard) Distribuer aux workers avec distribute_fragments.py"
echo ""
