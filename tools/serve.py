"""Serve the Web build locally. Open the printed address on your own computer."""
import functools
import http.server
from pathlib import Path

root = Path(__file__).resolve().parents[1] / "builds/web"
if not (root / "index.html").is_file():
    raise SystemExit("Build first: bash tools/build.sh Web")
server = http.server.ThreadingHTTPServer(("127.0.0.1", 8000), functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(root)))
print("Umbral: Ecos do Bosque — http://127.0.0.1:8000 — Ctrl+C to stop.", flush=True)
try:
    server.serve_forever()
except KeyboardInterrupt:
    server.server_close()
