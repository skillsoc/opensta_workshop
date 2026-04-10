#!/bin/bash
# =============================================================================
# run.sh - Run the OpenSTA Workshop Docker container
# =============================================================================
# Usage:
#   ./run.sh             # Start interactive shell
#   ./run.sh <command>   # Run a specific command
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSHOP_DIR="$(dirname "$SCRIPT_DIR")"
IMAGE_NAME="opensta-workshop"

# Check if image exists
if ! docker image inspect "$IMAGE_NAME" > /dev/null 2>&1; then
    echo "Error: Docker image '$IMAGE_NAME' not found."
    echo "Please build it first with: ./build.sh"
    exit 1
fi

echo "Starting OpenSTA Workshop container..."
echo "Workshop directory mounted at: /workspace"
echo ""

if [ $# -gt 0 ]; then
    # Run a specific command
    docker run --rm -it -v "$WORKSHOP_DIR":/workspace "$IMAGE_NAME" "$@"
else
    # Interactive shell
    docker run --rm -it -v "$WORKSHOP_DIR":/workspace "$IMAGE_NAME"
fi
