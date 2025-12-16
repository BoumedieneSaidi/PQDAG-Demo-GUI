# Docker Deployment Guide

This guide explains how to run the PQDAG system using Docker and Docker Compose.

## Prerequisites

- Docker 20.10+
- Docker Compose 2.0+

**Installation:**
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install docker.io docker-compose-v2

# macOS
brew install docker docker-compose

# Or install Docker Desktop (includes both)
```

## Quick Start

### 1. Build all services
```bash
./docker.sh build
```

This builds:
- ✅ Backend API (Spring Boot)
- ✅ Allocation Service (Python + MPI + METIS)
- ✅ Frontend (Angular + Nginx)

### 2. Start the system
```bash
./docker.sh up
```

Access the application:
- 🌐 **Frontend**: http://localhost:4200
- 🔧 **Backend API**: http://localhost:8080
- 📊 **Health Check**: http://localhost:8080/api/health

### 3. Run allocation
```bash
./docker.sh run-allocation watdiv100k
```

## Docker Commands

### Service Management
```bash
# Start all services
./docker.sh up

# Stop all services
./docker.sh down

# Restart services
./docker.sh restart

# Check status
./docker.sh status
```

### Logs and Debugging
```bash
# View all logs
./docker.sh logs

# View specific service logs
./docker.sh logs api
./docker.sh logs allocation
./docker.sh logs frontend

# Open shell in allocation container
./docker.sh exec-allocation
```

### Maintenance
```bash
# Clean Docker resources
./docker.sh clean

# Rebuild everything from scratch
./docker.sh rebuild
```

## Manual Docker Commands

If you prefer to use docker-compose directly:

```bash
# Build
docker-compose build

# Start (detached)
docker-compose up -d

# Stop
docker-compose down

# View logs
docker-compose logs -f api

# Execute command in container
docker-compose exec allocation bash

# Run allocation pipeline manually
docker-compose exec allocation bash -c "
  python3 generate_config.py test_dataset /app
  mpiexec -n 4 python3 stat_MPI.py /app/storage/outputdata /app/storage/allocation_results/db.stat
"
```

## Volume Mapping

The `storage/` directory is mounted into containers:

```
./storage  →  /app/storage (in containers)
├── rawdata/           # Input RDF files
├── bindata/           # Binary encoded data
├── outputdata/        # Generated fragments
├── allocation_results/  # Allocation outputs
└── allocation_temp/   # Temporary files
```

## Environment Variables

### Backend API
- `SPRING_PROFILES_ACTIVE=docker`
- `STORAGE_PATH=/app/storage`

### Allocation Service
- `WORKSPACE_ROOT=/app`
- `PYTHONUNBUFFERED=1`

## SSH Keys for Cluster Distribution

To distribute fragments to remote workers:

```bash
# Mount your SSH keys (read-only)
# Already configured in docker-compose.yml
volumes:
  - ~/.ssh:/home/pqdag/.ssh:ro
```

Edit `backend/allocation/master` and `backend/allocation/workers` with your cluster IPs.

## Troubleshooting

### Port already in use
```bash
# Check what's using port 8080
sudo lsof -i :8080

# Or change ports in docker-compose.yml
ports:
  - "8081:8080"  # Use 8081 instead
```

### Allocation container exits immediately
```bash
# Check logs
docker-compose logs allocation

# The container uses 'tail -f /dev/null' to stay running
# This allows on-demand execution via 'docker-compose exec'
```

### Permission issues with volumes
```bash
# Fix ownership
sudo chown -R $USER:$USER storage/

# Or run with user mapping in docker-compose.yml
user: "${UID}:${GID}"
```

### Python dependencies not found
```bash
# Rebuild allocation image
docker-compose build --no-cache allocation
```

## Development Workflow

### 1. Code Changes

**Backend API (Java):**
```bash
# Rebuild only API service
docker-compose build api
docker-compose up -d api
```

**Allocation (Python):**
```bash
# Code is mounted, no rebuild needed
docker-compose restart allocation
```

**Frontend (Angular):**
```bash
# Rebuild frontend
docker-compose build frontend
docker-compose up -d frontend
```

### 2. Testing

```bash
# Run allocation tests
docker-compose exec allocation bash -c "
  cd /app/allocation
  python3 -m pytest tests/
"

# Run API tests
docker-compose exec api bash -c "
  cd /app
  mvn test
"
```

## Production Deployment

### Option 1: Docker Compose on single host
```bash
# Set production environment
export SPRING_PROFILES_ACTIVE=production

# Start with restart policy
docker-compose up -d
```

### Option 2: Docker Swarm (cluster)
```bash
# Initialize swarm
docker swarm init

# Deploy stack
docker stack deploy -c docker-compose.yml pqdag
```

### Option 3: Kubernetes
See `k8s/` directory for Kubernetes manifests (coming soon).

## Resource Limits

Default resource limits in docker-compose.yml:

```yaml
services:
  api:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G

  allocation:
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 4G
```

Adjust based on your workload.

## Health Checks

All services include health checks:

```bash
# Check health status
docker-compose ps

# Manual health check
curl http://localhost:8080/api/health
curl http://localhost:4200
```

## Next Steps

1. ✅ Start services: `./docker.sh up`
2. ✅ Upload RDF file via frontend
3. ✅ Run fragmentation
4. ✅ Run allocation: `./docker.sh run-allocation`
5. ✅ Check results in `storage/allocation_results/`
