#!/bin/bash
###############################################################################
# PQDAG Allocation System - Setup Script
# This script installs all prerequisites for the allocation system
###############################################################################

set -e  # Exit on error

echo "=========================================="
echo "PQDAG Allocation - Prerequisites Setup"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Detect OS
OS=$(uname -s)
echo "🔍 Detected OS: $OS"
echo ""

###############################################################################
# 1. Check Python 3
###############################################################################
echo "📦 Step 1/4: Checking Python 3..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo -e "${GREEN}✅ $PYTHON_VERSION found${NC}"
else
    echo -e "${RED}❌ Python 3 not found${NC}"
    echo "Please install Python 3.8+ first"
    exit 1
fi
echo ""

###############################################################################
# 2. Install system dependencies (MPI and METIS)
###############################################################################
echo "📦 Step 2/4: Installing system dependencies (MPI, METIS)..."

if [[ "$OS" == "Linux" ]]; then
    # Check if we have apt-get (Debian/Ubuntu)
    if command -v apt-get &> /dev/null; then
        echo "Using apt-get package manager..."
        echo "This may require sudo password:"
        
        # Install OpenMPI
        if ! dpkg -l | grep -q openmpi-bin; then
            echo "Installing OpenMPI..."
            sudo apt-get update
            sudo apt-get install -y openmpi-bin libopenmpi-dev
        else
            echo -e "${GREEN}✅ OpenMPI already installed${NC}"
        fi
        
        # Install METIS
        if ! dpkg -l | grep -q libmetis-dev; then
            echo "Installing METIS library..."
            sudo apt-get install -y libmetis-dev
        else
            echo -e "${GREEN}✅ METIS already installed${NC}"
        fi
        
    # Check if we have yum (RedHat/CentOS)
    elif command -v yum &> /dev/null; then
        echo "Using yum package manager..."
        sudo yum install -y openmpi openmpi-devel metis metis-devel
    else
        echo -e "${YELLOW}⚠️  Unknown package manager. Please install manually:${NC}"
        echo "   - OpenMPI (for mpi4py)"
        echo "   - METIS library (for pymetis)"
    fi
    
elif [[ "$OS" == "Darwin" ]]; then
    # macOS with Homebrew
    if command -v brew &> /dev/null; then
        echo "Using Homebrew package manager..."
        
        # Install OpenMPI
        if ! brew list open-mpi &> /dev/null; then
            echo "Installing OpenMPI..."
            brew install open-mpi
        else
            echo -e "${GREEN}✅ OpenMPI already installed${NC}"
        fi
        
        # Install METIS
        if ! brew list metis &> /dev/null; then
            echo "Installing METIS..."
            brew install metis
        else
            echo -e "${GREEN}✅ METIS already installed${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Homebrew not found. Please install from https://brew.sh${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠️  Unsupported OS: $OS${NC}"
    echo "Please install manually: OpenMPI, METIS"
fi
echo ""

###############################################################################
# 3. Install Python packages
###############################################################################
echo "📦 Step 3/4: Installing Python packages..."

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -f "$SCRIPT_DIR/requirements.txt" ]; then
    echo "Installing from requirements.txt..."
    pip3 install -r "$SCRIPT_DIR/requirements.txt"
    echo -e "${GREEN}✅ Python packages installed${NC}"
else
    echo -e "${YELLOW}⚠️  requirements.txt not found${NC}"
    echo "Installing packages manually..."
    pip3 install PyYAML mpi4py pymetis
fi
echo ""

###############################################################################
# 4. Verify installation
###############################################################################
echo "📦 Step 4/4: Verifying installation..."
echo ""

# Test PyYAML
if python3 -c "import yaml" 2>/dev/null; then
    echo -e "${GREEN}✅ PyYAML${NC}"
else
    echo -e "${RED}❌ PyYAML${NC}"
fi

# Test mpi4py
if python3 -c "import mpi4py" 2>/dev/null; then
    echo -e "${GREEN}✅ mpi4py${NC}"
else
    echo -e "${RED}❌ mpi4py${NC}"
fi

# Test pymetis
if python3 -c "import pymetis" 2>/dev/null; then
    echo -e "${GREEN}✅ pymetis${NC}"
else
    echo -e "${RED}❌ pymetis (may require manual METIS installation)${NC}"
fi

# Test mpiexec
if command -v mpiexec &> /dev/null; then
    echo -e "${GREEN}✅ mpiexec ($(mpiexec --version | head -n1))${NC}"
else
    echo -e "${RED}❌ mpiexec${NC}"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}✅ Setup complete!${NC}"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Configure your cluster IPs in 'master' and 'workers' files"
echo "  2. Set up passwordless SSH to all workers"
echo "  3. Run allocation with: python3 stat_MPI.py ..."
echo ""
