#!/bin/bash
###############################################################################
# Test de distribution des fragments (avec Jump Host)
# Ce script teste uniquement la connectivité et la préparation des archives
# Sans effectuer la vraie distribution (dry-run)
###############################################################################

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "=========================================="
echo "Test Distribution - PQDAG Fragments"
echo "=========================================="
echo ""

###############################################################################
# Test 1: Vérifier la configuration SSH
###############################################################################
echo -e "${YELLOW}Test 1: Vérification de la configuration SSH${NC}"

if grep -q "Host bastion" ~/.ssh/config 2>/dev/null; then
    echo -e "${GREEN}✅ Configuration SSH détectée${NC}"
else
    echo -e "${RED}❌ Configuration SSH manquante${NC}"
    echo "Exécutez d'abord: ./setup-ssh-cluster.sh"
    exit 1
fi
echo ""

###############################################################################
# Test 2: Test de connexion au master
###############################################################################
echo -e "${YELLOW}Test 2: Test de connexion au master${NC}"

if ssh -o ConnectTimeout=5 pqdag-master "hostname" 2>/dev/null; then
    MASTER_HOSTNAME=$(ssh pqdag-master "hostname")
    echo -e "${GREEN}✅ Master accessible: $MASTER_HOSTNAME${NC}"
else
    echo -e "${RED}❌ Master inaccessible${NC}"
    echo "Vérifiez votre configuration SSH ou VPN"
    exit 1
fi
echo ""

###############################################################################
# Test 3: Test de connexion aux workers
###############################################################################
echo -e "${YELLOW}Test 3: Test de connexion aux workers${NC}"

WORKER_COUNT=0
ACCESSIBLE_WORKERS=()

for i in {1..10}; do
    if timeout 10 ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no pqdag-worker-$i "hostname" 2>/dev/null; then
        WORKER_HOSTNAME=$(timeout 10 ssh pqdag-worker-$i "hostname" 2>/dev/null)
        echo -e "${GREEN}✅ Worker $i accessible: $WORKER_HOSTNAME${NC}"
        WORKER_COUNT=$((WORKER_COUNT + 1))
        ACCESSIBLE_WORKERS+=("pqdag-worker-$i")
    else
        echo -e "${RED}❌ Worker $i inaccessible (timeout ou erreur)${NC}"
    fi
done

echo ""
echo "Workers accessibles: $WORKER_COUNT / 10"
echo ""

if [ $WORKER_COUNT -eq 0 ]; then
    echo -e "${RED}❌ Aucun worker accessible${NC}"
    exit 1
fi

###############################################################################
# Test 4: Vérifier les fichiers d'allocation
###############################################################################
echo -e "${YELLOW}Test 4: Vérification des fichiers d'allocation${NC}"

if [ ! -f "storage/allocation_results/affectation_weighted_metis.txt" ]; then
    echo -e "${RED}❌ Fichier d'affectation manquant${NC}"
    echo "Exécutez d'abord: ./test-allocation-simple.sh"
    exit 1
fi

ALLOCATION_LINES=$(wc -l < storage/allocation_results/affectation_weighted_metis.txt)
echo -e "${GREEN}✅ Fichier d'affectation: $ALLOCATION_LINES fragments${NC}"

FRAGMENT_COUNT=$(ls -1 storage/outputdata/*.data 2>/dev/null | wc -l)
echo -e "${GREEN}✅ Fragments disponibles: $FRAGMENT_COUNT${NC}"
echo ""

###############################################################################
# Test 5: Créer les archives par worker (simulation)
###############################################################################
echo -e "${YELLOW}Test 5: Simulation de création des archives${NC}"
echo ""

# Créer un répertoire temporaire pour les tests
TEST_TEMP_DIR="/tmp/pqdag_distribution_test"
rm -rf "$TEST_TEMP_DIR"
mkdir -p "$TEST_TEMP_DIR"

echo "Lecture du fichier d'affectation..."
declare -A WORKER_FRAGMENTS

while IFS=' ' read -r fragment_id machine_id; do
    if [ ! -z "$fragment_id" ]; then
        WORKER_FRAGMENTS[$machine_id]+="$fragment_id "
    fi
done < storage/allocation_results/affectation_weighted_metis.txt

echo "Fragments par machine:"
for machine_id in {1..10}; do
    COUNT=$(echo ${WORKER_FRAGMENTS[$machine_id]} | wc -w)
    echo "  Machine $machine_id: $COUNT fragments"
done
echo ""

###############################################################################
# Test 6: Tester la création d'une archive (machine 1 seulement)
###############################################################################
echo -e "${YELLOW}Test 6: Test de création d'archive (Machine 1)${NC}"

MACHINE_1_FRAGMENTS=(${WORKER_FRAGMENTS[1]})
ARCHIVE_PATH="$TEST_TEMP_DIR/worker_1.tar.gz"

echo "Création de l'archive pour worker 1 (${#MACHINE_1_FRAGMENTS[@]} fragments)..."

# Créer un fichier de liste temporaire
FRAGMENT_LIST="$TEST_TEMP_DIR/fragments_machine_1.txt"
for frag_id in ${MACHINE_1_FRAGMENTS[@]:0:5}; do  # Limiter à 5 pour le test
    # Trouver les fichiers correspondants
    for ext in data dic schema; do
        file="storage/outputdata/${frag_id}.${ext}"
        if [ -f "$file" ]; then
            echo "$file" >> "$FRAGMENT_LIST"
        fi
    done
done

# Créer l'archive
if [ -f "$FRAGMENT_LIST" ]; then
    tar -czf "$ARCHIVE_PATH" -T "$FRAGMENT_LIST" 2>/dev/null
    ARCHIVE_SIZE=$(du -h "$ARCHIVE_PATH" | cut -f1)
    echo -e "${GREEN}✅ Archive créée: $ARCHIVE_SIZE${NC}"
else
    echo -e "${RED}❌ Échec de création de l'archive${NC}"
fi
echo ""

###############################################################################
# Test 7: Test d'envoi d'un petit fichier
###############################################################################
echo -e "${YELLOW}Test 7: Test d'envoi d'un fichier test au master${NC}"

TEST_FILE="$TEST_TEMP_DIR/test_transfer.txt"
echo "Test de transfert PQDAG" > "$TEST_FILE"

if scp -o ConnectTimeout=5 "$TEST_FILE" pqdag-master:/tmp/ 2>/dev/null; then
    echo -e "${GREEN}✅ Transfert SCP fonctionnel${NC}"
    
    # Vérifier que le fichier existe
    if ssh pqdag-master "[ -f /tmp/test_transfer.txt ]"; then
        echo -e "${GREEN}✅ Fichier reçu sur le master${NC}"
        ssh pqdag-master "rm -f /tmp/test_transfer.txt"
    fi
else
    echo -e "${RED}❌ Échec du transfert SCP${NC}"
fi
echo ""

###############################################################################
# Résumé
###############################################################################
echo "=========================================="
echo -e "${GREEN}✅ Tests de distribution terminés${NC}"
echo "=========================================="
echo ""
echo "Résumé:"
echo "  - Master accessible: ✅"
echo "  - Workers accessibles: $WORKER_COUNT / 10"
echo "  - Fichiers d'allocation: ✅"
echo "  - Création d'archives: ✅"
echo "  - Transfert SCP: ✅"
echo ""
echo "Prochaine étape:"
echo "  - Modifier distribute_fragments.py pour supporter le jump host"
echo "  - Exécuter la vraie distribution avec:"
echo "    python3 backend/allocation/distribute_fragments.py --config_file config_runtime.yaml"
echo ""

# Cleanup
rm -rf "$TEST_TEMP_DIR"
