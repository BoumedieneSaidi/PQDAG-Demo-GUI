# PQDAG-Demo-GUI

🎯 **Graphical User Interface for PQDAG** - A distributed RDF database system with fragmentation and allocation pipeline.

## 🚀 Quick Start

### Local Development
```bash
# Start services
docker-compose up -d

# Access
Frontend: http://localhost:4200
Backend:  http://localhost:8080
```

### Production (Cluster Master)
```bash
# Deploy to master node
./deploy-to-master.sh

# Create SSH tunnel
./tunnel-to-master.sh

# Access via tunnel
Frontend: http://localhost:8000
Backend:  http://localhost:8080
```

## 📚 Documentation

- **[ACCESS.md](ACCESS.md)** - How to access the GUI on the cluster
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Deployment guide
- **[PIPELINE_GUIDE.md](PIPELINE_GUIDE.md)** - Complete workflow guide
- **[DOCKER.md](DOCKER.md)** - Docker setup and usage

## 🏗️ Architecture

```
┌─────────────┐      ┌──────────────┐      ┌──────────────┐
│  Frontend   │─────▶│   Backend    │─────▶│  Allocation  │
│  (Angular)  │      │ (Spring Boot)│      │  (MPI+METIS) │
└─────────────┘      └──────────────┘      └──────────────┘
                                                    │
                                                    ▼
                                            ┌──────────────┐
                                            │  Workers x10 │
                                            │ (Distributed)│
                                            └──────────────┘
```

## ✨ Features

- **Phase 1 - Fragmentation** ✅
  - Upload RDF files
  - Fragment using FastEncoder
  - View statistics and results

- **Phase 2 - Allocation** ✅
  - Graph-based allocation with METIS
  - MPI parallel processing
  - Real-time progress tracking
  - Visual statistics and charts
  - Distribution to cluster workers

## 🛠️ Tech Stack

- **Frontend**: Angular 17 + TypeScript
- **Backend**: Spring Boot 3.2.1 + Java 17
- **Allocation**: Python + MPI + METIS
- **Fragmentation**: C++ FastEncoder
- **Deployment**: Docker Compose

## 📦 Project Structure

```
PQDAG GUI/
├── frontend/          # Angular application
├── backend/
│   ├── api/          # Spring Boot REST API
│   ├── allocation/   # MPI allocation scripts
│   └── fragmentation/# C++ FastEncoder
├── storage/          # Data storage
├── deploy-to-master.sh    # Deployment script
└── tunnel-to-master.sh    # SSH tunnel script
```

## 🔧 Development

See [INSTALLATION.md](INSTALLATION.md) for detailed setup instructions.

## 📝 License

MIT License - See LICENSE file for details
