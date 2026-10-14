#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source tools/environment.sh
target="${1:-Web}"
case "$target" in
  Web) output="builds/web/index.html" ;;
  Windows) output="builds/windows/Umbral.exe" ;;
  Linux) output="builds/linux/Umbral.x86_64" ;;
  *) echo "Usage: bash tools/build.sh [Web|Windows|Linux]" >&2; exit 2 ;;
esac
mkdir -p "$(dirname "$output")" test-results
touch builds/.gdignore test-results/.gdignore
godot --headless --path . --editor --import --quit >test-results/build-import.log 2>&1
if rg -n 'SCRIPT ERROR:|^ERROR:' test-results/build-import.log; then exit 1; fi
godot --headless --path . --export-release "$target" "$output" >"test-results/export-$target.log" 2>&1
if rg -n 'SCRIPT ERROR:|^ERROR:' "test-results/export-$target.log"; then exit 1; fi
test -s "$output"
echo "Built $target: $output"
