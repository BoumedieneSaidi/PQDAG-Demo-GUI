# Dockerfile for PQDAG Allocation System
# Multi-stage build for optimized image size

FROM ubuntu:22.04 as builder

# Avoid interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    build-essential \
    openmpi-bin \
    libopenmpi-dev \
    libmetis-dev \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages
COPY requirements.txt /tmp/
RUN pip3 install --no-cache-dir --upgrade pip && \
    pip3 install --no-cache-dir -r /tmp/requirements.txt

# Final stage
FROM ubuntu:22.04

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies only
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    openmpi-bin \
    libopenmpi3 \
    libmetis5 \
    openssh-client \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy Python packages from builder
COPY --from=builder /usr/local/lib/python3.10/dist-packages /usr/local/lib/python3.10/dist-packages

# Create non-root user for security
RUN useradd -m -u 1000 pqdag && \
    mkdir -p /app/allocation /app/storage && \
    chown -R pqdag:pqdag /app

# Set working directory
WORKDIR /app/allocation

# Copy allocation scripts
COPY --chown=pqdag:pqdag . .

# Create storage directories
RUN mkdir -p /app/storage/outputdata \
             /app/storage/allocation_results \
             /app/storage/allocation_temp && \
    chown -R pqdag:pqdag /app/storage

# Switch to non-root user
USER pqdag

# Environment variables
ENV PYTHONUNBUFFERED=1
ENV WORKSPACE_ROOT=/app

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python3 -c "import yaml, mpi4py, pymetis" || exit 1

# Default command: interactive bash
CMD ["bash"]
