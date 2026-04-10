#!/bin/bash
# =============================================================================
# build.sh - Build the OpenSTA Workshop Docker image
# =============================================================================
# Usage:
#   ./build.sh          # Build for Linux
#   ./build.sh wsl2     # Build for Windows WSL2
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

IMAGE_NAME="opensta-workshop"

if [ "$1" = "wsl2" ]; then
    echo "Building OpenSTA Workshop image for WSL2..."
    docker build -f Dockerfile.wsl2 -t "$IMAGE_NAME" .
else
    echo "Building OpenSTA Workshop image for Linux..."
    docker build -f Dockerfile.linux -t "$IMAGE_NAME" .
fi

echo ""
echo "========================================"
echo " Build complete!"
echo " Image: $IMAGE_NAME"
echo ""
echo " To start the workshop environment:"
echo "   ./run.sh"
echo "========================================"
