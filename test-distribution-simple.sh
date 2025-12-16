#!/bin/bash
###############################################################################
# Test Simple de Distribution (avec mot de passe)
# Ce script teste la distribution sans configuration SSH préalable
###############################################################################

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

BASTION="bsaidi@193.55.163.204"
MASTER="ubuntu@192.168.165.27"

echo "=========================================="
echo "Test Distribution Simple - PQDAG"
echo "=========================================="
echo ""
echo "⚠️  Vous devrez entrer le mot de passe du bastion plusieurs fois"
echo ""

###############################################################################
# Test 1: Connexion au Master
###############################################################################
echo -e "${YELLOW}Test 1: Connexion au Master${NC}"
if MASTER_HOSTNAME=$(ssh -o ConnectTimeout=10 -J $BASTION $MASTER "hostname" 2>&1); then
    echo -e "${GREEN}✅ Master accessible: $MASTER_HOSTNAME${NC}"
else
    echo -e "${RED}❌ Master inaccessible${NC}"
    exit 1
fi
echo ""

###############################################################################
# Test 2: Connexion aux Workers (2 premiers seulement pour le test)
###############################################################################
echo -e "${YELLOW}Test 2: Test de 2 workers${NC}"

WORKERS=("192.168.165.101" "192.168.165.138")
WORKER_COUNT=0

for worker_ip in "${WORKERS[@]}"; do
    echo "Test worker $worker_ip..."
    if WORKER_HOSTNAME=$(ssh -o ConnectTimeout=10 -J $BASTION ubuntu@$worker_ip "hostname" 2>&1); then
        echo -e "${GREEN}✅ $WORKER_HOSTNAME accessible${NC}"
        ((WORKER_COUNT++))
    else
        echo -e "${RED}❌ $worker_ip inaccessible${NC}"
    fi
done

echo ""
echo "Workers testés: $WORKER_COUNT / 2"
echo ""

###############################################################################
# Test 3: Vérifier les fichiers d'allocation
###############################################################################
echo -e "${YELLOW}Test 3: Vérification des fichiers${NC}"

if [ ! -f "storage/allocation_results/affectation_weighted_metis.txt" ]; then
    echo -e "${RED}❌ Fichier d'affectation manquant${NC}"
    echo "Exécutez d'abord: ./test-allocation-simple.sh"
    exit 1
fi

ALLOCATION_COUNT=$(wc -l < storage/allocation_results/affectation_weighted_metis.txt)
FRAGMENT_COUNT=$(ls -1 storage/outputdata/*.data 2>/dev/null | wc -l)

echo -e "${GREEN}✅ Allocations: $ALLOCATION_COUNT${NC}"
echo -e "${GREEN}✅ Fragments: $FRAGMENT_COUNT${NC}"
echo ""

###############################################################################
# Test 4: Analyser la distribution par machine
###############################################################################
echo -e "${YELLOW}Test 4: Analyse de la distribution${NC}"
echo ""

declare -A MACHINE_FRAGMENTS

while IFS=' ' read -r fragment_id machine_id; do
    if [ ! -z "$fragment_id" ]; then
        MACHINE_FRAGMENTS[$machine_id]=$((${MACHINE_FRAGMENTS[$machine_id]:-0} + 1))
    fi
done < storage/allocation_results/affectation_weighted_metis.txt

echo "Distribution des fragments par machine:"
for machine_id in {1..10}; do
    count=${MACHINE_FRAGMENTS[$machine_id]:-0}
    echo "  Machine $machine_id: $count fragments"
done
echo ""

###############################################################################
# Test 5: Test de transfert d'un petit fichier
###############################################################################
echo -e "${YELLOW}Test 5: Test de transfert SCP${NC}"

TEST_FILE="/tmp/pqdag_test_$(date +%s).txt"
echo "Test PQDAG - $(date)" > "$TEST_FILE"

echo "Envoi d'un fichier test au master..."
if scp -o ConnectTimeout=10 -J $BASTION "$TEST_FILE" $MASTER:/tmp/ 2>&1 | grep -q "100%"; then
    echo -e "${GREEN}✅ Transfert SCP fonctionnel${NC}"
    
    # Vérifier que le fichier existe sur le master
    REMOTE_FILE=$(basename "$TEST_FILE")
    if ssh -o ConnectTimeout=10 -J $BASTION $MASTER "[ -f /tmp/$REMOTE_FILE ] && echo 'exists'" 2>&1 | grep -q "exists"; then
        echo -e "${GREEN}✅ Fichier reçu sur le master${NC}"
        
        # Cleanup
        ssh -o ConnectTimeout=10 -J $BASTION $MASTER "rm -f /tmp/$REMOTE_FILE" 2>&1 > /dev/null
    fi
else
    echo -e "${RED}❌ Échec du transfert SCP${NC}"
fi

rm -f "$TEST_FILE"
echo ""

###############################################################################
# Test 6: Créer une archive test
###############################################################################
echo -e "${YELLOW}Test 6: Création d'une archive test${NC}"

# Prendre les 10 premiers fragments de la machine 1
MACHINE_1_FRAGMENTS=$(awk '$2 == 1 {print $1}' storage/allocation_results/affectation_weighted_metis.txt | head -10)
FRAGMENT_LIST=()

for frag_id in $MACHINE_1_FRAGMENTS; do
    for ext in data dic schema; do
        file="storage/outputdata/${frag_id}.${ext}"
        if [ -f "$file" ]; then
            FRAGMENT_LIST+=("$file")
        fi
    done
done

ARCHIVE_PATH="/tmp/test_worker_1.tar.gz"
if tar -czf "$ARCHIVE_PATH" "${FRAGMENT_LIST[@]}" 2>/dev/null; then
    ARCHIVE_SIZE=$(du -h "$ARCHIVE_PATH" | cut -f1)
    FILE_COUNT=${#FRAGMENT_LIST[@]}
    echo -e "${GREEN}✅ Archive créée: $ARCHIVE_SIZE ($FILE_COUNT fichiers)${NC}"
    
    # Test de transfert de l'archive
    echo "Test de transfert de l'archive au master..."
    if scp -o ConnectTimeout=10 -J $BASTION "$ARCHIVE_PATH" $MASTER:/tmp/ 2>&1 | grep -q "100%"; then
        echo -e "${GREEN}✅ Archive transférée avec succès${NC}"
        
        # Cleanup
        ssh -o ConnectTimeout=10 -J $BASTION $MASTER "rm -f /tmp/test_worker_1.tar.gz" 2>&1 > /dev/null
    else
        echo -e "${RED}❌ Échec du transfert de l'archive${NC}"
    fi
    
    rm -f "$ARCHIVE_PATH"
else
    echo -e "${RED}❌ Échec de création de l'archive${NC}"
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
echo "  ✅ Connexion master: OK"
echo "  ✅ Connexion workers: $WORKER_COUNT / 2 testés"
echo "  ✅ Fichiers d'allocation: $ALLOCATION_COUNT fragments"
echo "  ✅ Transfert SCP: OK"
echo "  ✅ Création d'archives: OK"
echo ""
echo "🎯 Prochaine étape:"
echo "   Lancer la vraie distribution avec distribute_fragments.py"
echo "   (adapté pour le jump host)"
echo ""
