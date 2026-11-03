from harness_io import results_dir
"""Prove the rule suite detects two representative gameplay regressions."""
import json
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
sources = {str(path.relative_to(ROOT)): path.read_text() for directory in ["scripts", "content"] for path in (ROOT / directory).rglob("*") if path.suffix in {".gd", ".tres"}}
mutations = {
    "Combustão removed": ("content/umbrals/ember/mechanics/combustion.gd", "effect.burn += strength", "effect.burn += 0"),
    "Fourth energy incorrectly allowed": ("scripts/domain/cast_evaluator.gd", "result.valid = int(result.energy) <= 3", "result.valid = int(result.energy) <= 3 + 1"),
}
detected = []
for name, (target, before, after) in mutations.items():
    original = sources[target]
    if original.count(before) != 1:
        raise RuntimeError(f"Mutation target changed: {name}")
    with tempfile.TemporaryDirectory(prefix="umbral-mutation-") as directory:
        folder = Path(directory)
        (folder / "tests").mkdir()
        (folder / "project.godot").write_text('config_version=5\n[application]\nconfig/name="Umbral isolated mutation test"\n')
        for relative, source in sources.items():
            destination = folder / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_text(source.replace(before, after) if relative == target else source)
        (folder / "tests/support").mkdir()
        for helper in (ROOT / "tests/support").glob("*.gd"):
            (folder / "tests/support" / helper.name).write_text(helper.read_text())
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
(results_dir() / "mutation-report.json").write_text(json.dumps(report, indent=2))
print(json.dumps(report))
