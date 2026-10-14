#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source tools/environment.sh
mkdir -p test-results
touch test-results/.gdignore
# Root reports describe this attempt; earlier iteration evidence stays in artifacts/.
rm -f test-results/{asset-report.json,rules.log,mutation-report.json,ui-report.json,ui_state_test.log,ui_flow_test.log,startup_smoke.log,import.log}
python tools/asset_checks.py
godot --headless --path . --editor --import --quit >test-results/import.log 2>&1
if rg -n 'SCRIPT ERROR:|^ERROR:' test-results/import.log; then exit 1; fi
godot --headless --path . --script tests/rules_test.gd 2>&1 | tee test-results/rules.log
if rg -n 'SCRIPT ERROR:|^ERROR:' test-results/rules.log; then exit 1; fi
python - <<'PY'
import json
from pathlib import Path
results = [json.loads(line) for line in Path('test-results/rules.log').read_text().splitlines() if line.startswith('{')]
report = next(item for item in results if item.get('suite') == 'umbral_rules')
assert report['checks'] > 0 and report['failed'] == 0, report
PY
python tools/mutation_smoke.py
python tools/ui_checks.py
echo "Rules and scene startup passed."
