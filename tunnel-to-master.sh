#!/bin/bash
###############################################################################
# SSH Tunnel to PQDAG GUI on Master Node
# This script creates an SSH tunnel through the bastion to access the GUI
###############################################################################

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo "=========================================="
echo -e "${GREEN}PQDAG GUI - SSH Tunnel${NC}"
echo "=========================================="
echo ""
echo -e "${BLUE}Configuration:${NC}"
echo "  Bastion:  bsaidi@193.55.163.204"
echo "  Master:   ubuntu@192.168.165.27"
echo ""
echo -e "${GREEN}URLs accessibles après connexion:${NC}"
echo "  Frontend:  http://localhost:9000"
echo "  Backend:   http://localhost:9080"
echo ""
echo -e "${YELLOW}Instructions:${NC}"
echo "  1. Entrez le mot de passe: bsaidi"
echo "  2. Ouvrez votre navigateur sur http://localhost:9000"
echo "  3. Appuyez sur Ctrl+C pour arrêter le tunnel"
echo ""
echo "=========================================="
echo ""

# Create SSH tunnel with port forwarding
# -L 9000:192.168.165.27:80   → Forward local port 9000 to master port 80 (frontend)
# -L 9080:192.168.165.27:8080 → Forward local port 9080 to master port 8080 (backend)
# -J bsaidi@193.55.163.204    → Jump through bastion
# -N                          → Don't execute remote command (just forward ports)
# -v                          → Verbose mode for debugging

ssh -L 9000:192.168.165.27:80 \
    -L 9080:192.168.165.27:8080 \
    -J bsaidi@193.55.163.204 \
    -N \
    ubuntu@192.168.165.27
