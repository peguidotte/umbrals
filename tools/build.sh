#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source tools/environment.sh
exec python tools/harness.py build "${1:-Web}" "${@:2}"
