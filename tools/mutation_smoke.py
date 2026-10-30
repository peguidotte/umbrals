"""Prove the rule suite detects eight representative gameplay regressions."""
import json
import shutil
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
original = (ROOT / "scripts/rules.gd").read_text()
mutations = {
    "Combustão removed": ('if species == "ember" and damage > 0: burn += strength', 'if species == "ember" and damage > 0: burn += 0'),
    "Fourth shared action incorrectly allowed": ("const ENERGY = 3", "const ENERGY = 4"),
    "Seed reaction consumption removed": ('if not reaction.is_empty() and bool(reaction.consume): Conditions.consume(target, str(reaction.condition))', 'if false: Conditions.consume(target, str(reaction.condition))'),
    "Reserve cards reinserted as one owner block": ('for incoming in returning: _interleave_draw(incoming)', 'for incoming in returning: deck = incoming + deck'),
    "Explicit capture destination ignored": ('destination = capture_slot', 'destination = -1'),
    "Partial KO ignored at encounter start": ('\tif _needs_replacement():\n\t\tphase = "replacement"', '\tif active_party(true).is_empty() and not reserves().is_empty():\n\t\tphase = "replacement"'),
    "Declined replacement prompt repeated": ('and not declined_replacements.has(int(individual.uid))', ''),
    "Delayed voluntary KO replacement blocked": ('if outgoing.is_empty() or int(outgoing.get("slot", -1)) < 0: return false', 'if outgoing.is_empty() or int(outgoing.get("slot", -1)) < 0 or int(outgoing.hp) <= 0: return false'),
}
detected = []
for name, (before, after) in mutations.items():
    if original.count(before) != 1:
        raise RuntimeError(f"Mutation target changed: {name}")
    with tempfile.TemporaryDirectory(prefix="umbral-mutation-") as directory:
        folder = Path(directory)
        (folder / "scripts").mkdir()
        shutil.copytree(ROOT / "scripts/battle", folder / "scripts/battle")
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
