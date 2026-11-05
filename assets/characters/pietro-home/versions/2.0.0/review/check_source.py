from pathlib import Path
from PIL import Image
import hashlib,json
root=Path(__file__).resolve().parents[6]
r=root/'assets/characters/pietro-home/versions/2.0.0'
m=json.loads((r/'manifest.json').read_text());p=json.loads((r/'poses.json').read_text())
im=Image.open(r/'atlas.png');a=im.getchannel('A');rows=[]
assert im.mode=='RGBA'
assert hashlib.sha256((r/'atlas.png').read_bytes()).hexdigest()==m['provenance']['original_sha256']
ref=m['provenance']['approved_identity_reference']
assert hashlib.sha256((r/'review/approved-concept.png').read_bytes()).hexdigest()==ref['sha256']
for i,f in enumerate(p['frames']):
 x,y,w,h=f['region'];px,py=f['pivot'];assert 0<=x<x+w<=im.width and 0<=y<y+h<=im.height
 alpha=a.crop((x,y,x+w,y+h));mask=alpha.point(lambda z:255 if z>8 else 0);b=mask.getbbox();solid=alpha.point(lambda z:255 if z>64 else 0).getbbox()
 assert b is not None and min(b[0],b[1],w-b[2],h-b[3])>=8,'Visible art clips region'
 assert abs(solid[3]-py)<=.01,'Pivot floats below/above actual boot sole'
 assert 0<px<w and 0<py<h
 cell=(int(i%4*im.width/4),int(i//4*im.height/2),int((i%4+1)*im.width/4),int((i//4+1)*im.height/2))
 original=a.crop(cell);solid_pixels=sum(original.histogram()[9:]);ratio=solid_pixels/(original.width*original.height)
 assert .05<ratio<.4,'Missing art or contaminated opaque background'
 assert alpha.getextrema()[1]>=240
 rows.append({'pose':i,'region':f['region'],'pivot':f['pivot'],'visible_pixels':solid_pixels,'solid_fraction_of_cell':round(ratio,4),'visible_height_world':(solid[3]-solid[1])*p['source_scale'],'head_top_relative_to_pivot_world':(solid[1]-py)*p['source_scale'],'edge_margin_pixels':min(b[0],b[1],w-b[2],h-b[3])})
assert max(x['visible_height_world'] for x in rows)-min(x['visible_height_world'] for x in rows)<6,'Body volume drifts'
assert max(x['head_top_relative_to_pivot_world'] for x in rows)-min(x['head_top_relative_to_pivot_world'] for x in rows)<6,'Head bounces'
assert len({im.crop((f['region'][0],f['region'][1],sum(f['region'][::2]),sum(f['region'][1::2]))).tobytes() for f in [p['frames'][n] for n in p['walk']]})==6,'Duplicate walk frame'
report={'status':'passed','scope':'Source and selected runtime regions only; rendered review remains separate','atlas_sha256':m['provenance']['original_sha256'],'reference_sha256':ref['sha256'],'atlas_dimensions':im.size,'alpha_extrema':a.getextrema(),'frame_count':len(rows),'walk_frames':len(p['walk']),'poses':rows}
out=root/'test-results/pietro-asset-qa';out.mkdir(parents=True,exist_ok=True);(out/'report.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
