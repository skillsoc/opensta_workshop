# Docker Setup for OpenSTA Workshop

This directory contains Docker configurations for building a consistent OpenSTA environment.

## Files

| File | Description |
|------|-------------|
| `Dockerfile.linux` | Dockerfile for Linux hosts |
| `Dockerfile.wsl2` | Dockerfile for Windows WSL2 hosts |
| `docker-compose.yml` | Docker Compose configuration |
| `build.sh` | Build script |
| `run.sh` | Run script |

## Quick Start

### Option 1: Using build/run scripts

```bash
# Build the image
chmod +x build.sh run.sh
./build.sh        # For Linux
./build.sh wsl2   # For Windows WSL2

# Start the container
./run.sh
```

### Option 2: Using Docker Compose

```bash
docker compose build
docker compose run opensta
```

### Option 3: Manual Docker commands

```bash
# Build
docker build -f Dockerfile.linux -t opensta-workshop .

# Run (mount workshop directory)
cd ..
docker run -it -v $(pwd):/workspace opensta-workshop
```

## What's Installed

- **Ubuntu 22.04** base image
- **OpenSTA** (built from source, latest version)
- **Icarus Verilog** (for RTL simulation)
- **Build tools**: gcc, cmake, make
- **Editors**: vim, nano

## Windows WSL2 Setup

1. Install WSL2: `wsl --install` in PowerShell (admin)
2. Install [Docker Desktop](https://www.docker.com/products/docker-desktop/)
3. In Docker Desktop → Settings → General → Enable "Use WSL 2 based engine"
4. In Settings → Resources → WSL Integration → Enable your Linux distro
5. Open a WSL terminal and run the build/run scripts

## Troubleshooting

- **"Cannot connect to Docker daemon"**: Ensure Docker Desktop is running
- **Build fails on cmake**: Check internet connectivity (needs to clone OpenSTA repo)
- **Permission denied on scripts**: Run `chmod +x build.sh run.sh`
- **WSL2: slow file access**: Keep workshop files inside WSL filesystem (`/home/...`), not on Windows mounts (`/mnt/c/...`)
