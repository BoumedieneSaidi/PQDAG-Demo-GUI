#!/bin/bash
###############################################################################
# PQDAG GUI - Deployment Script for Cluster Master
# This script deploys the complete application stack to the master node
###############################################################################

set -e  # Exit on error

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

function print_header() {
    echo ""
    echo "=========================================="
    echo -e "${GREEN}$1${NC}"
    echo "=========================================="
    echo ""
}

function print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

function print_success() {
    echo -e "${GREEN}✅${NC} $1"
}

function print_error() {
    echo -e "${RED}❌${NC} $1"
}

function print_step() {
    echo -e "${BLUE}➜${NC} $1"
}

###############################################################################
# Configuration
###############################################################################
MASTER_HOST="pqdag-master"
MASTER_IP="192.168.165.27"
MASTER_USER="ubuntu"
DEPLOY_DIR="/home/ubuntu/mounted_vol/pqdag-gui"
REMOTE_STORAGE="/home/ubuntu/mounted_vol/pqdag_data"

print_header "PQDAG GUI - Deployment to Master"

echo "Target:"
echo "  Host: $MASTER_HOST ($MASTER_IP)"
echo "  User: $MASTER_USER"
echo "  Directory: $DEPLOY_DIR"
echo ""

###############################################################################
# Step 1: Verify SSH connectivity
###############################################################################
print_step "Step 1/7: Verifying SSH connectivity"

if ssh -o ConnectTimeout=5 $MASTER_HOST "echo 'connected'" &>/dev/null; then
    print_success "SSH connection OK"
else
    print_error "Cannot connect to master"
    echo ""
    echo "Please ensure:"
    echo "  1. SSH configuration is set up: ./setup-ssh-cluster.sh"
    echo "  2. You can reach the bastion: ssh bastion"
    echo "  3. VPN is active if required"
    exit 1
fi

###############################################################################
# Step 2: Check Docker on master
###############################################################################
print_step "Step 2/7: Checking Docker installation on master"

if ssh $MASTER_HOST "which docker" &>/dev/null; then
    DOCKER_VERSION=$(ssh $MASTER_HOST "docker --version")
    print_success "Docker installed: $DOCKER_VERSION"
else
    print_error "Docker not installed on master"
    echo ""
    echo "Installing Docker..."
    ssh $MASTER_HOST "curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh && sudo usermod -aG docker $MASTER_USER"
    print_success "Docker installed"
fi

# Check docker-compose
if ssh $MASTER_HOST "which docker-compose" &>/dev/null; then
    COMPOSE_VERSION=$(ssh $MASTER_HOST "docker-compose --version")
    print_success "Docker Compose installed: $COMPOSE_VERSION"
else
    print_info "Installing Docker Compose..."
    ssh $MASTER_HOST "sudo curl -L \"https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose"
    print_success "Docker Compose installed"
fi

###############################################################################
# Step 3: Prepare deployment directory
###############################################################################
print_step "Step 3/7: Preparing deployment directory on master"

ssh $MASTER_HOST "mkdir -p $DEPLOY_DIR/storage/{rawdata,bindata,outputdata,allocation_results,allocation_temp}"
print_success "Directory structure created"

###############################################################################
# Step 4: Transfer application files
###############################################################################
print_step "Step 4/7: Transferring application files"

# Create a temporary archive excluding unnecessary files
TEMP_ARCHIVE="/tmp/pqdag-gui-$(date +%s).tar.gz"

print_info "Creating deployment archive..."
tar -czf "$TEMP_ARCHIVE" \
    --exclude='node_modules' \
    --exclude='.git' \
    --exclude='storage/rawdata/*' \
    --exclude='storage/bindata/*' \
    --exclude='storage/outputdata/*' \
    --exclude='storage/allocation_results/*' \
    --exclude='storage/allocation_temp/*' \
    --exclude='backend/api/target' \
    --exclude='frontend/dist' \
    --exclude='*.log' \
    --exclude='*.pem' \
    --exclude='*.key' \
    --exclude='config_runtime.yaml' \
    --exclude='worker_ips.txt' \
    -C "$(pwd)" \
    .

ARCHIVE_SIZE=$(du -h "$TEMP_ARCHIVE" | cut -f1)
print_success "Archive created: $ARCHIVE_SIZE"

print_info "Transferring to master..."
scp "$TEMP_ARCHIVE" $MASTER_HOST:/tmp/pqdag-gui.tar.gz
print_success "Files transferred"

print_info "Extracting on master..."
ssh $MASTER_HOST "cd $DEPLOY_DIR && tar -xzf /tmp/pqdag-gui.tar.gz && rm /tmp/pqdag-gui.tar.gz"
print_success "Files extracted"

rm -f "$TEMP_ARCHIVE"

###############################################################################
# Step 5: Create master-specific configuration
###############################################################################
print_step "Step 5/7: Creating master configuration"

# Create docker-compose override for master
cat > /tmp/docker-compose.override.yml <<EOF
version: '3.8'

services:
  api:
    ports:
      - "8080:8080"
    volumes:
      - $REMOTE_STORAGE:/app/storage
    environment:
      - WORKSPACE_ROOT=/app
    restart: always

  allocation:
    volumes:
      - $REMOTE_STORAGE:/app/storage
      - $DEPLOY_DIR/backend/allocation:/app/allocation
      - ~/.ssh:/home/pqdag/.ssh:ro
    restart: always

  frontend:
    ports:
      - "80:80"  # Expose on port 80 for easy access
    restart: always
EOF

scp /tmp/docker-compose.override.yml $MASTER_HOST:$DEPLOY_DIR/
rm /tmp/docker-compose.override.yml
print_success "Configuration created"

# Create worker IPs file on master
ssh $MASTER_HOST "cat > $DEPLOY_DIR/backend/allocation/workers <<EOF
192.168.165.101
192.168.165.138
192.168.165.80
192.168.165.89
192.168.165.126
192.168.165.249
192.168.165.194
192.168.165.46
192.168.165.233
192.168.165.63
EOF"
print_success "Worker IPs configured"

###############################################################################
# Step 6: Build Docker images on master
###############################################################################
print_step "Step 6/7: Building Docker images on master"

print_info "Building backend API..."
ssh $MASTER_HOST "cd $DEPLOY_DIR && docker-compose build api" &
PID_API=$!

print_info "Building allocation service..."
ssh $MASTER_HOST "cd $DEPLOY_DIR && docker-compose build allocation" &
PID_ALLOC=$!

print_info "Building frontend..."
ssh $MASTER_HOST "cd $DEPLOY_DIR && docker-compose build frontend" &
PID_FRONT=$!

wait $PID_API $PID_ALLOC $PID_FRONT
print_success "All Docker images built"

###############################################################################
# Step 7: Start services
###############################################################################
print_step "Step 7/7: Starting services on master"

ssh $MASTER_HOST "cd $DEPLOY_DIR && docker-compose down || true"
ssh $MASTER_HOST "cd $DEPLOY_DIR && docker-compose up -d"

# Wait for services to be ready
print_info "Waiting for services to start..."
sleep 10

# Check service status
SERVICE_STATUS=$(ssh $MASTER_HOST "cd $DEPLOY_DIR && docker-compose ps --format json" | jq -r '.[].State' | grep -c "running" || echo "0")

if [ "$SERVICE_STATUS" -eq 3 ]; then
    print_success "All services running"
else
    print_error "Some services failed to start"
    ssh $MASTER_HOST "cd $DEPLOY_DIR && docker-compose ps"
fi

###############################################################################
# Summary
###############################################################################
print_header "Deployment Complete!"

echo "🎉 PQDAG GUI is now deployed on the master node!"
echo ""
echo "📍 Access URLs:"
echo "   Frontend:  http://$MASTER_IP"
echo "   Backend:   http://$MASTER_IP:8080"
echo ""
echo "🔧 Management commands (on master):"
echo "   View logs:     cd $DEPLOY_DIR && docker-compose logs -f"
echo "   Restart:       cd $DEPLOY_DIR && docker-compose restart"
echo "   Stop:          cd $DEPLOY_DIR && docker-compose down"
echo "   Status:        cd $DEPLOY_DIR && docker-compose ps"
echo ""
echo "📂 Data storage:"
echo "   Remote storage: $REMOTE_STORAGE"
echo "   Deployment dir: $DEPLOY_DIR"
echo ""
echo "🔍 Next steps:"
echo "   1. Access the GUI: http://$MASTER_IP"
echo "   2. Upload an RDF file"
echo "   3. Run fragmentation and allocation"
echo "   4. Distribute to workers"
echo ""
echo "💡 To SSH into master:"
echo "   ssh $MASTER_HOST"
echo ""
