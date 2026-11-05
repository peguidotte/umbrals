"""Read-only pixel and provenance checks for the retained contact candidate."""
import json
import sys
from pathlib import Path
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from asset_pipeline import ROOT, digest


def verify():
    folder = ROOT / 'assets/characters/brasa-lifecycle/versions/1.1.0'
    manifest = json.loads((folder/'manifest.json').read_text())
    profile = json.loads((folder/'profile.json').read_text())['forms']['ember']
    checks = []
    for role, row in manifest['files'].items():
        assert digest(folder/row['path']) == row['sha256'], role
    checks.append('All retained image/data/source bytes match the immutable manifest')
    def frame(name, index):
        image = Image.open(folder/(name+'.png'))
        x,y=index%4*512,index//4*448
        return image.crop((x,y,x+512,y+448))
    original = Image.open(ROOT/'assets/characters/battle-creatures/versions/1.0.0/texture.png')
    idle = Image.new('RGBA',(512,448))
    idle.alpha_composite(original.crop((40,54,411,418)),(90,50))
    assert frame('settle',4).tobytes() == idle.tobytes()
    assert frame('revive',5).tobytes() == idle.tobytes()
    assert frame('revive',0).tobytes() == frame('knockout',3).tobytes()
    checks.append('Arrival/revival idle endpoints and held-KO recovery start match exact source pixels')
    assert len({frame('revive',i).tobytes() for i in range(6)}) == 6
    checks.append('Recovery contains six distinct forward poses, including four newly drawn rising poses')
    supports = {}
    for i,row in enumerate(profile['timelines']['walk']):
        x,y=row['contact']
        assert frame('walk',i).getpixel((x,y-2))[3] >= 192, (i,'Contact must touch an opaque foot pixel')
        projected = (x + row['offset'][0],y+row['offset'][1])
        supports.setdefault(row['support'],set()).add(projected)
    assert len(supports)==2 and all(len(points)==1 for points in supports.values())
    checks.append('All eight measured soles touch visible pixels; each four-pose stance has one world contact')
    assert manifest['metadata']['production_ready'] is False
    return {'checks':checks,'failed':0,'production_ready':False,'support_pixels':{key:list(next(iter(value))) for key,value in supports.items()}}


if __name__=='__main__': print(json.dumps(verify(),indent=2))
