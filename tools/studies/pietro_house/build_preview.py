"""Build opt-in experiment using the actual game sources. Production boot stays unchanged."""
from pathlib import Path
import argparse,hashlib,json,shutil,subprocess
ROOT=Path(__file__).resolve().parents[3]
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
out=a.output.resolve();project=out/'project';build=out/'build';project.mkdir(parents=True,exist_ok=True);build.mkdir(exist_ok=True)
folders=['scripts','scenes','content','assets','tools/studies/pietro_pixel','tools/studies/pietro_house']
inputs={}
for folder in folders:
 for source in (ROOT/folder).rglob('*'):
  if not source.is_file() or source.suffix in ('.pyc','.import') or '__pycache__' in source.parts:continue
  rel=source.relative_to(ROOT);target=project/rel;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,target)
  inputs[str(rel)]=hashlib.sha256(source.read_bytes()).hexdigest()
original=(ROOT/'project.godot').read_text();inputs['project.godot']=hashlib.sha256((ROOT/'project.godot').read_bytes()).hexdigest()
(project/'project.godot').write_text(original.replace('res://scenes/main.tscn','res://tools/studies/pietro_house/study.tscn').replace('godot/app_userdata/Feral Hand','godot/app_userdata/Umbral-Pietro-House-Experiment'))
(project/'export_presets.cfg').write_text('''[preset.0]
name="Web"
platform="Web"
runnable=true
export_filter="all_resources"
include_filter="assets/*.json,assets/*/*/versions/*/*.json"
exclude_filter="assets/*/*/versions/*/review/*,tools/studies/pietro_pixel/test*,tools/studies/pietro_house/test*"
[preset.0.options]
variant/extensions_support=false
variant/thread_support=false
vram_texture_compression/for_desktop=true
vram_texture_compression/for_mobile=false
html/canvas_resize_policy=2
''')
for name,command in [('import',['--editor','--quit']),('export',['--export-release','Web',str(build/'index.html')])]:
 with (out/(name+'.log')).open('w') as log:subprocess.run(['godot','--headless','--path',str(project),*command],stdout=log,stderr=subprocess.STDOUT,check=True)
(out/'scope.json').write_text(json.dumps({'base':'60b4e3045ebb9188f2a1f67771a8f6bf37d714f9','scope':'Actual main scene, house controller/camera/background and current creature renderer; experimental canvas injected at opt-in boot; no production replacement','inputs':inputs,'production_boot_unchanged':True,'production_pins_unchanged':True,'build':str(build)},indent=2)+'\n');print(build)
