"""Shared output location for standalone tools and the isolated task runner."""
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def results_dir():
    result = Path(os.environ.get('UMBRAL_RESULTS_DIR', str(ROOT / 'test-results'))).resolve()
    result.mkdir(parents=True, exist_ok=True)
    return result
