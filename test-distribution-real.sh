#!/bin/bash
###############################################################################
# Test de VRAIE distribution des fragments vers le cluster
# Ce script exécute distribute_fragments.py avec un petit sous-ensemble
###############################################################################

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "=========================================="
echo "Test Distribution RÉELLE - PQDAG Cluster"
echo "=========================================="
echo ""

###############################################################################
# Vérifications préalables
###############################################################################
echo -e "${YELLOW}Vérifications préalables${NC}"

# Vérifier configuration SSH
if ! grep -q "Host bastion" ~/.ssh/config 2>/dev/null; then
    echo -e "${RED}❌ Configuration SSH manquante${NC}"
    echo "Exécutez: ./setup-ssh-cluster.sh"
    exit 1
fi
echo -e "${GREEN}✅ Configuration SSH OK${NC}"

# Vérifier fichiers d'allocation
if [ ! -f "storage/allocation_results/affectation_weighted_metis.txt" ]; then
    echo -e "${RED}❌ Fichier d'affectation manquant${NC}"
    echo "Exécutez: ./test-allocation-simple.sh"
    exit 1
fi
echo -e "${GREEN}✅ Fichier d'affectation OK${NC}"

# Vérifier fragments
FRAGMENT_COUNT=$(ls -1 storage/outputdata/*.data 2>/dev/null | wc -l)
if [ $FRAGMENT_COUNT -eq 0 ]; then
    echo -e "${RED}❌ Aucun fragment détecté${NC}"
    exit 1
fi
echo -e "${GREEN}✅ $FRAGMENT_COUNT fragments détectés${NC}"
echo ""

###############################################################################
# Générer config_runtime.yaml
###############################################################################
echo -e "${YELLOW}Génération du fichier de configuration runtime${NC}"

cd backend/allocation
python3 generate_config.py watdiv100k "/home/boumi/Documents/PQDAG GUI"
RESULT=$?
cd ../..

if [ $RESULT -ne 0 ]; then
    echo -e "${RED}❌ Échec de génération de config_runtime.yaml${NC}"
    exit 1
fi
echo -e "${GREEN}✅ config_runtime.yaml généré${NC}"
echo ""

###############################################################################
# Afficher la configuration
###############################################################################
echo -e "${YELLOW}Configuration de distribution${NC}"
echo "Dataset: watdiv100k"
echo "Fragments: $FRAGMENT_COUNT"
echo "Workers: 10"
echo "Destination cluster: /home/ubuntu/pqdag/data/"
echo ""

###############################################################################
# Demander confirmation
###############################################################################
echo -e "${YELLOW}⚠️  ATTENTION: Cette opération va:${NC}"
echo "  1. Créer 10 archives (une par worker)"
echo "  2. Transférer les archives vers le cluster via SSH"
echo "  3. Extraire les archives sur chaque worker"
echo ""
echo -n "Continuer? (y/N): "
read -r CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "Annulé."
    exit 0
fi
echo ""

###############################################################################
# Exécuter la distribution
###############################################################################
echo -e "${YELLOW}Démarrage de la distribution...${NC}"
echo ""

python3 backend/allocation/distribute_fragments.py \
    --config_file backend/allocation/config_runtime.yaml

RESULT=$?
echo ""

if [ $RESULT -eq 0 ]; then
    echo "=========================================="
    echo -e "${GREEN}✅ Distribution terminée avec succès${NC}"
    echo "=========================================="
    echo ""
    echo "Résumé:"
    echo "  - Archives créées: 10"
    echo "  - Fragments distribués: $FRAGMENT_COUNT"
    echo "  - Workers configurés: 10"
    echo ""
    echo "Prochaines étapes:"
    echo "  1. Vérifier les fragments sur les workers:"
    echo "     ssh pqdag-worker-1 'ls -lh /home/ubuntu/pqdag/data/'"
    echo ""
    echo "  2. Charger les fragments dans les BTrees:"
    echo "     (À implémenter dans fragments_loader.py)"
else
    echo "=========================================="
    echo -e "${RED}❌ La distribution a échoué${NC}"
    echo "=========================================="
    echo ""
    echo "Vérifiez:"
    echo "  - La connectivité SSH vers le cluster"
    echo "  - Les permissions sur les workers"
    echo "  - L'espace disque disponible"
fi
