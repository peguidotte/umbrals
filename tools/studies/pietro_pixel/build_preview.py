"""Export the isolated art study; never changes the game's production boot."""
import argparse,hashlib,json,shutil,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--output',type=Path,required=True);a=p.parse_args();out=a.output.resolve();project=out/'project';build=out/'build';project.mkdir(parents=True,exist_ok=True);build.mkdir(exist_ok=True)
for rel in ['assets/characters/pietro-pixel-pilot/versions/0.2.0','assets/world/pietro-pixel-study/versions/0.1.0','tools/studies/pietro_pixel']:
 shutil.copytree(ROOT/rel,project/rel,dirs_exist_ok=True)
inputs={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for folder in ['assets/characters/pietro-pixel-pilot/versions/0.2.0','assets/world/pietro-pixel-study/versions/0.1.0','tools/studies/pietro_pixel'] for p in (ROOT/folder).rglob('*') if p.is_file() and p.suffix not in ('.uid','.import','.pyc') and '__pycache__' not in p.parts}
# Review-only reference is deliberately included in this standalone study.
for ignore in project.rglob('.gdignore'):ignore.unlink()
(project/'project.godot').write_text('''config_version=5
[application]
config/name="Pietro — estudo visual"
run/main_scene="res://tools/studies/pietro_pixel/study.tscn"
[display]
window/size/viewport_width=1600
window/size/viewport_height=1000
window/stretch/mode="canvas_items"
[rendering]
renderer/rendering_method="gl_compatibility"
textures/default_filters/use_nearest_mipmap_filter=false
''')
(project/'export_presets.cfg').write_text('''[preset.0]
name="Web"
platform="Web"
runnable=true
export_filter="all_resources"
include_filter="*.json"
exclude_filter="tools/studies/pietro_pixel/test*"
[preset.0.options]
variant/extensions_support=false
variant/thread_support=false
vram_texture_compression/for_desktop=true
vram_texture_compression/for_mobile=false
html/canvas_resize_policy=2
''')
with (out/'import.log').open('w') as log: subprocess.run(['godot','--headless','--editor','--path',str(project),'--quit'],stdout=log,stderr=subprocess.STDOUT,check=True)
with (out/'export.log').open('w') as log: subprocess.run(['godot','--headless','--path',str(project),'--export-release','Web',str(build/'index.html')],stdout=log,stderr=subprocess.STDOUT,check=True)
(out/'scope.json').write_text(json.dumps({'scope':'standalone art study; production boot and runtime-lock unchanged','build':str(build),'logical_size':[1600,1000],'inputs':inputs},indent=2)+'\n');print(build)
