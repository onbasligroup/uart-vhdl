#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE="uart-vhdl:latest"

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker not found"
  exit 1
fi

if [[ $# -eq 0 ]]; then
  CMD=(make cocotb-test)
else
  CMD=("$@")
fi

docker build -t "$IMAGE" "$ROOT_DIR"
docker run --rm -v "$ROOT_DIR:/workspace" -w /workspace "$IMAGE" "${CMD[@]}"
