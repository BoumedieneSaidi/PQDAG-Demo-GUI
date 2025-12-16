# Installation Guide - PQDAG System

This guide covers the installation of all prerequisites for the PQDAG system (Fragmentation + Allocation).

## System Requirements

- **OS**: Linux (Ubuntu 20.04+, Debian, CentOS) or macOS
- **Python**: 3.8+
- **Java**: JDK 11+ (for backend API and fragmentation)
- **Node.js**: 18+ (for frontend)
- **Docker**: Optional, for containerized deployment

---

## Installation Methods

### Method 1: Automated Setup (Recommended)

#### Step 1: Install Allocation Prerequisites
```bash
cd backend/allocation
./setup.sh
```

This installs:
- OpenMPI (for parallel statistics)
- METIS library (for graph partitioning)
- Python packages (PyYAML, mpi4py, pymetis)

#### Step 2: Install Backend API (Spring Boot)
```bash
cd backend/api
mvn clean install
```

#### Step 3: Install Frontend (Angular)
```bash
cd frontend
npm install
```

---

### Method 2: Docker Compose (Production)

**Coming soon**: Full docker-compose setup for all services.

```bash
# Build all services
docker-compose build

# Start all services
docker-compose up -d
```

---

### Method 3: Manual Installation

#### For Allocation System

**Ubuntu/Debian:**
```bash
# System dependencies
sudo apt-get update
sudo apt-get install -y openmpi-bin libopenmpi-dev libmetis-dev

# Python packages
pip3 install PyYAML mpi4py pymetis
```

**macOS:**
```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# System dependencies
brew install open-mpi metis

# Python packages
pip3 install PyYAML mpi4py pymetis
```

**RedHat/CentOS:**
```bash
# System dependencies
sudo yum install -y openmpi openmpi-devel metis metis-devel

# Python packages
pip3 install PyYAML mpi4py pymetis
```

#### For Backend API

```bash
# Install Java 11+ if not installed
sudo apt-get install openjdk-11-jdk  # Ubuntu/Debian
# or
brew install openjdk@11              # macOS

# Install Maven
sudo apt-get install maven           # Ubuntu/Debian
# or
brew install maven                   # macOS

# Build project
cd backend/api
mvn clean install
```

#### For Frontend

```bash
# Install Node.js 18+ if not installed
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs       # Ubuntu/Debian
# or
brew install node                    # macOS

# Install Angular CLI
npm install -g @angular/cli

# Install dependencies
cd frontend
npm install
```

---

## Cluster Setup (for Allocation Distribution)

### 1. Configure Cluster Nodes

Edit the IP addresses of your cluster:

```bash
# Master node IP
echo "192.168.1.100" > backend/allocation/master

# Worker nodes IPs (one per line)
cat > backend/allocation/workers << EOF
192.168.1.101
192.168.1.102
192.168.1.103
EOF
```

### 2. Setup Passwordless SSH

On the master node:

```bash
# Generate SSH key if not exists
ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa

# Copy to all workers
for worker in $(cat backend/allocation/workers); do
    ssh-copy-id ubuntu@$worker
done

# Test connection
for worker in $(cat backend/allocation/workers); do
    ssh ubuntu@$worker "hostname"
done
```

### 3. Install Dependencies on All Workers

```bash
# On each worker node, run:
sudo apt-get update
sudo apt-get install -y openjdk-11-jdk python3 python3-pip

# Or use a deployment script (coming soon)
```

---

## Verification

### Test Allocation Prerequisites

```bash
# Test MPI
mpiexec -n 4 python3 -c "from mpi4py import MPI; print(f'Rank {MPI.COMM_WORLD.Get_rank()}')"

# Test METIS
python3 -c "import pymetis; print('PyMETIS OK')"

# Test YAML
python3 -c "import yaml; print('PyYAML OK')"
```

### Test Backend API

```bash
cd backend/api
mvn spring-boot:run

# In another terminal
curl http://localhost:8080/api/health
```

### Test Frontend

```bash
cd frontend
ng serve

# Open browser to http://localhost:4200
```

---

## Troubleshooting

### pymetis Installation Fails

If `pip install pymetis` fails, you may need to install METIS from source:

```bash
# Download and install METIS
wget http://glaros.dtc.umn.edu/gkhome/fetch/sw/metis/metis-5.1.0.tar.gz
tar -xzf metis-5.1.0.tar.gz
cd metis-5.1.0
make config
make
sudo make install

# Then install pymetis
pip3 install pymetis
```

### mpi4py Installation Fails

Make sure OpenMPI is properly installed:

```bash
# Check MPI installation
which mpicc
mpiexec --version

# Reinstall mpi4py
pip3 install --no-cache-dir mpi4py
```

### SSH Connection Issues

```bash
# Debug SSH connection
ssh -v ubuntu@worker_ip

# Check SSH key permissions
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
chmod 700 ~/.ssh
```

---

## Next Steps

After installation:

1. **Run Fragmentation**: Upload RDF file and fragment it
2. **Run Allocation**: Allocate fragments to cluster nodes
3. **Query System**: Execute SPARQL queries on distributed fragments

See each component's README for detailed usage instructions.
