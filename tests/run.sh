#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
IMAGE_TAG="dotfiles-test:latest"

docker build --pull -t "$IMAGE_TAG" -f "$SCRIPT_DIR/Dockerfile" "$PROJECT_ROOT"
docker run --rm "$IMAGE_TAG" "functions ga"
docker run --rm "$IMAGE_TAG" "fisher list | grep tide"
