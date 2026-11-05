"""Export a small actual-renderer comparison, without the production game."""
import argparse, hashlib, json, shutil, subprocess
from pathlib import Path
ROOT = Path(__file__).resolve().parents[3]
p = argparse.ArgumentParser(description=__doc__)
p.add_argument('--output', type=Path, required=True)
a = p.parse_args()
out = a.output.resolve(); project = out/'project'; build = out/'build'
project.mkdir(parents=True, exist_ok=True); build.mkdir(exist_ok=True)
files = [f'tools/studies/pietro_pixel/{name}.gd' for name in ['rig','upper_rig','texture_mesh','volume_rows']]
files += ['tools/studies/pietro_volume/review.gd','tools/studies/pietro_volume/review.tscn']
for version in ['0.3.0','0.4.0']:
 files += [f'assets/characters/pietro-pixel-pilot/versions/{version}/{name}' for name in ['source.png','rig.json']]
inputs = {}
for rel in files:
 source=ROOT/rel; target=project/rel; target.parent.mkdir(parents=True,exist_ok=True)
 shutil.copy2(source,target); inputs[rel]=hashlib.sha256(source.read_bytes()).hexdigest()
(project/'project.godot').write_text('''config_version=5
[application]
config/name="Pietro — comparação de volume"
run/main_scene="res://tools/studies/pietro_volume/review.tscn"
[display]
window/size/viewport_width=1400
window/size/viewport_height=1000
window/stretch/mode="canvas_items"
[rendering]
renderer/rendering_method="gl_compatibility"
''')
(project/'export_presets.cfg').write_text('''[preset.0]
name="Web"
platform="Web"
runnable=true
export_filter="all_resources"
include_filter="*.json"
exclude_filter=""
[preset.0.options]
variant/thread_support=false
vram_texture_compression/for_desktop=true
html/canvas_resize_policy=2
''')
for name,args in [('import',['--editor','--quit']),('export',['--export-release','Web',str(build/'index.html')])]:
 with (out/(name+'.log')).open('w') as log:
  subprocess.run(['godot','--headless','--path',str(project),*args],stdout=log,stderr=subprocess.STDOUT,check=True)
(out/'scope.json').write_text(json.dumps({'scope':'diagnostic poses only','inputs':inputs},indent=2)+'\n')
print(build)
