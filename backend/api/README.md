# PQDAG API - Spring Boot

REST API for managing PQDAG fragmentation operations.

## Prerequisites

- Java 17+
- Maven 3.9+
- Docker (for containerized deployment)

## Development

### Run locally

```bash
cd backend/api
mvn spring-boot:run
```

The API will be available at `http://localhost:8080`

### Build

```bash
mvn clean package
```

### Run with Docker

```bash
docker build -t pqdag-api .
docker run -p 8080:8080 pqdag-api
```

## API Endpoints

### Health Check
```
GET /api/health
```

Returns API status and timestamp.

## Configuration

Edit `src/main/resources/application.properties` to configure:
- Server port
- Storage paths
- CORS settings
- File upload limits
