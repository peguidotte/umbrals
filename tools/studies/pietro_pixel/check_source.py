"""Source and mask QA for the isolated study, independent of aesthetic approval."""
from pathlib import Path
import hashlib,json
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[3]
c=ROOT/'assets/characters/pietro-pixel-pilot/versions/0.2.1';w=ROOT/'assets/world/pietro-pixel-study/versions/0.1.0';p=c/'source.png';im=Image.open(p);data=json.loads((c/'rig.json').read_text())
assert hashlib.sha256(p.read_bytes()).hexdigest()=='cc20c83377533cc93c79e141f6490bcc8e056f36a05013f28b66111956c0bbfa'
assert im.mode=='RGBA' and im.size==(1254,1254)
alpha=im.getchannel('A');mask=Image.new('L',im.size);d=ImageDraw.Draw(mask)
for polygon in [data['body_mask']]+[leg['mask'] for leg in data['legs']]:d.polygon([tuple(x) for x in polygon],fill=255)
missing=sum(a>16 and b==0 for a,b in zip(alpha.tobytes(),mask.tobytes()))
assert missing==0,{'uncovered_source_pixels':missing}
for leg in data['legs']:assert alpha.getpixel(tuple(leg['sole']))>220
for path in [p,w/'plate.png',w/'review/approved-scene.png']:
 with Image.open(path) as decoded:decoded.load()
print(json.dumps({'checks':6,'failed':0,'uncovered_source_pixels':missing,'source_alpha_extrema':alpha.getextrema(),'source_bytes':p.stat().st_size,'static_source_sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'scope':'identity, transparency, masks and pivot pixels; not visual acceptance'}))
