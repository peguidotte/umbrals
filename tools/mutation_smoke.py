"""Prove the rule suite detects two representative gameplay regressions."""
import json
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
original = (ROOT / "scripts/rules.gd").read_text()
mutations = {
    "Combustão removed": ("burn += trait_value", "burn += 0"),
    "Fourth energy incorrectly allowed": ("result.valid = int(result.energy) <= ENERGY", "result.valid = int(result.energy) <= ENERGY + 1"),
}
detected = []
for name, (before, after) in mutations.items():
    if original.count(before) != 1:
        raise RuntimeError(f"Mutation target changed: {name}")
    with tempfile.TemporaryDirectory(prefix="umbral-mutation-") as directory:
        folder = Path(directory)
        (folder / "scripts").mkdir()
        (folder / "tests").mkdir()
        (folder / "project.godot").write_text('config_version=5\n[application]\nconfig/name="Umbral isolated mutation test"\n')
        (folder / "scripts/rules.gd").write_text(original.replace(before, after))
        (folder / "scripts/content.gd").write_text((ROOT / "scripts/content.gd").read_text())
        (folder / "tests/rules_test.gd").write_text((ROOT / "tests/rules_test.gd").read_text())
        result = subprocess.run(["godot", "--headless", "--path", str(folder), "--script", "tests/rules_test.gd"], capture_output=True, text=True, timeout=60)
        output = result.stdout + result.stderr
        if "SCRIPT ERROR:" in output or "ERROR:" in output:
            raise RuntimeError(f"Mutation must fail behaviorally, not crash: {name}\n{output}")
        reports = [json.loads(line) for line in result.stdout.splitlines() if line.startswith('{')]
        report = next(item for item in reports if item.get("suite") == "umbral_rules")
        if result.returncode == 0 or report["checks"] <= 0 or report["failed"] <= 0:
            raise AssertionError(f"Undetected gameplay regression: {name}")
        detected.append({"mutation": name, "failing_checks": report["failed"]})
report = {"suite": "umbral_mutation_smoke", "detected": detected, "failed": 0}
(ROOT / "test-results/mutation-report.json").write_text(json.dumps(report, indent=2))
print(json.dumps(report))
