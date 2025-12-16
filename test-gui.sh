#!/bin/bash
###############################################################################
# Test PQDAG GUI - Script interactif
###############################################################################

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║         🧪 TEST PQDAG GUI SUR LE CLUSTER                  ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

echo -e "${BLUE}📋 Instructions pour tester l'application :${NC}"
echo ""
echo "1️⃣  ${YELLOW}Ouvrez un NOUVEAU terminal${NC} et exécutez :"
echo "   ${GREEN}./tunnel-to-master.sh${NC}"
echo ""
echo "2️⃣  Entrez le mot de passe : ${GREEN}bsaidi${NC}"
echo ""
echo "3️⃣  Une fois connecté, le tunnel restera actif"
echo ""
echo "4️⃣  ${YELLOW}Revenez à ce terminal${NC} et appuyez sur ENTRÉE"
echo ""
read -p "▶ Appuyez sur ENTRÉE une fois le tunnel établi..."

echo ""
echo -e "${BLUE}🔍 Vérification de la connectivité...${NC}"
echo ""

# Test frontend
echo -n "Frontend (port 9000): "
if curl -s -o /dev/null -w "%{http_code}" http://localhost:9000 | grep -q "200"; then
    echo -e "${GREEN}✅ OK${NC}"
    FRONTEND_OK=1
else
    echo -e "${RED}❌ Non accessible${NC}"
    FRONTEND_OK=0
fi

# Test backend
echo -n "Backend  (port 9080): "
if curl -s http://localhost:9080/api/fragmentation/status > /dev/null 2>&1; then
    echo -e "${GREEN}✅ OK${NC}"
    BACKEND_OK=1
else
    echo -e "${RED}❌ Non accessible${NC}"
    BACKEND_OK=0
fi

echo ""

if [ $FRONTEND_OK -eq 1 ] && [ $BACKEND_OK -eq 1 ]; then
    echo -e "${GREEN}✅ Tous les services sont accessibles !${NC}"
    echo ""
    echo "🌐 ${YELLOW}Ouverture du navigateur...${NC}"
    
    # Detect browser and open
    if command -v xdg-open > /dev/null; then
        xdg-open http://localhost:9000 &
    elif command -v gnome-open > /dev/null; then
        gnome-open http://localhost:9000 &
    elif command -v firefox > /dev/null; then
        firefox http://localhost:9000 &
    elif command -v google-chrome > /dev/null; then
        google-chrome http://localhost:9000 &
    else
        echo "⚠️  Impossible d'ouvrir automatiquement"
        echo "   Ouvrez manuellement : http://localhost:9000"
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${GREEN}🎉 L'application est prête !${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📍 URLs :"
    echo "   Frontend : http://localhost:9000"
    echo "   Backend  : http://localhost:9080"
    echo ""
    echo "🧪 Test du pipeline :"
    echo "   1. Onglet Fragmentation"
    echo "   2. Upload un fichier RDF"
    echo "   3. Cliquez sur 'Fragment RDF File'"
    echo "   4. Allez dans l'onglet Allocation"
    echo "   5. Lancez l'allocation et la distribution"
    echo ""
    echo "⚠️  Pour arrêter le tunnel :"
    echo "   - Retournez au terminal du tunnel"
    echo "   - Appuyez sur Ctrl+C"
    echo ""
else
    echo -e "${RED}❌ Problème de connectivité${NC}"
    echo ""
    echo "🔧 Vérifications :"
    echo "   1. Le tunnel est-il lancé ? (./tunnel-to-master.sh)"
    echo "   2. Avez-vous entré le bon mot de passe ? (bsaidi)"
    echo "   3. La connexion SSH est-elle établie ?"
    echo ""
    echo "📝 Pour relancer le test : ./test-gui.sh"
fi

echo ""
