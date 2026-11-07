from harness_io import results_dir
"""Prove the rule suite detects eight representative gameplay regressions."""
import json
import shutil
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
mutations = {
    "Combustão removed": ("scripts/battle/traits.gd", 'if int(values.damage) > 0: values.burn += amount', 'if int(values.damage) > 0: values.burn += 0'),
    "Fourth shared action incorrectly allowed": ("const ENERGY = 3", "const ENERGY = 4"),
    "Seed reaction consumption removed": ('scripts/battle/round_resolution.gd', 'if not reaction.is_empty() and bool(reaction.consume): Conditions.consume(target, str(reaction.condition))', 'if false: Conditions.consume(target, str(reaction.condition))'),
    "Reserve cards reinserted as one owner block": ('scripts/battle/card_cycle.gd', 'for incoming in returning: _interleave_draw(incoming)', 'for incoming in returning: deck = incoming + deck'),
    "Explicit capture destination ignored": ('scripts/battle/rewards.gd', 'destination = capture_slot', 'destination = -1'),
    "Partial KO ignored at encounter start": ('\tif _needs_replacement():\n\t\tphase = "replacement"', '\tif active_party(true).is_empty() and not reserves().is_empty():\n\t\tphase = "replacement"'),
    "Declined replacement prompt repeated": ('scripts/battle/battle_view.gd', 'if int(individual.hp) <= 0 and not declined_replacements.has(int(individual.uid)): return true', 'if int(individual.hp) <= 0: return true'),
    "Delayed voluntary KO replacement blocked": ('if outgoing.is_empty() or int(outgoing.get("slot", -1)) < 0: return false', 'if outgoing.is_empty() or int(outgoing.get("slot", -1)) < 0 or int(outgoing.hp) <= 0: return false'),
}
detected = []
for name, mutation in mutations.items():
    print("Checking mutation: " + name, flush=True)
    target, before, after = mutation if len(mutation) == 3 else ("scripts/rules.gd", *mutation)
    original = (ROOT / target).read_text()
    if original.count(before) != 1:
        raise RuntimeError(f"Mutation target changed: {name}")
    with tempfile.TemporaryDirectory(prefix="umbral-mutation-") as directory:
        folder = Path(directory)
        shutil.copytree(ROOT / "scripts", folder / "scripts")
        shutil.copytree(ROOT / "content", folder / "content")
        (folder / "tests").mkdir()
        shutil.copytree(ROOT / "tests/support", folder / "tests/support")
        (folder / "project.godot").write_text('config_version=5\n[application]\nconfig/name="Umbral isolated mutation test"\n')
        (folder / target).write_text(original.replace(before, after))
        (folder / "tests/rules_test.gd").write_text((ROOT / "tests/rules_test.gd").read_text())
        result = subprocess.run(["godot", "--headless", "--path", str(folder), "--script", "tests/rules_test.gd"], capture_output=True, text=True, timeout=120)
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
