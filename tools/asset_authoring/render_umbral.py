"""Umbral fireball v4: shared spell, three socket-bound casting performances."""
from pathlib import Path
import os
import math, json, subprocess
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
import render as b
import render_variants as v

ROOT = Path(os.environ.get("UMBRAL_ASSET_OUTPUT", str(Path(__file__).resolve().parents[2] / "builds/asset-work/vfx"))).resolve()
if ROOT.is_relative_to(Path(__file__).resolve().parents[2] / "assets"):
    raise ValueError("Author into staging, never into a versioned release")
ROOT.mkdir(parents=True, exist_ok=True)
OUT=ROOT/'v4-umbral'
if not OUT.exists() and (ROOT.parent/'vfx-spec.json').exists():
    OUT=ROOT.parent
ASSETS=OUT/'assets'
ASSETS.mkdir(parents=True,exist_ok=True)
FPS=30
FRAMES=120
RELEASE=36
HIT=60
TAU=math.tau
PROFILE_IDS=['mouth','hand','kick']
LABELS={'mouth':('BOCA','Inspira, concentra e expele.'),'hand':('MÃO','Conjura na palma e arremessa.'),'kick':('CHUTE','Forma a bola, prepara a perna e chuta.')}
ACTOR_ROOT=(175,386)
LOCAL_ROOT=(150,352)
TARGET=(735,264)
INK=(25,31,47,255)
MID=(43,52,74,255)
LIGHT=(70,85,114,255)
EDGE=(112,133,159,255)
EYES=(169,226,245,255)

def lerp(a,c,u):return tuple(x+(y-x)*u for x,y in zip(a,c))
def ease_between(t,a,c):return b.smooth((t-a)/(c-a))
def world(p):return (p[0]-LOCAL_ROOT[0]+ACTOR_ROOT[0],p[1]-LOCAL_ROOT[1]+ACTOR_ROOT[1])

def bloom(im,gain=.75):
    """Baked, downsampled 12-unit glow; runtime uses no blur pass."""
    sm=im.resize((max(1,im.width//4),max(1,im.height//4)),Image.Resampling.LANCZOS)
    a=sm.getchannel('A').filter(ImageFilter.GaussianBlur(3*b.S))
    halo=Image.new('RGBA',sm.size,(255,92,16,0));halo.putalpha(a.point(lambda x:int(x*.27*gain)))
    halo=halo.resize(im.size,Image.Resampling.BILINEAR);halo.alpha_composite(im)
    return halo

def orb(im,x,y,r,ph):
    """Smooth leading hemisphere and rolling flame folds behind it."""
    def outline(scale,ox=0,oy=0):
        rr=r*scale
        pts=[]
        for a in np.linspace(0,TAU,64,endpoint=False):
            wav=.045+.08*max(0,-math.cos(a))
            rad=rr*(1+wav*math.sin(a*6+ph)+.025*math.sin(a*11-ph))
            pts.append((x+ox+math.cos(a)*rad,y+oy+math.sin(a)*rad*.9))
        return v.smooth_shape(pts)
    b.path(im,outline(1.12),v.RED,(114,26,42,255),1.8)
    b.path(im,outline(.96,2,-2),v.ORANGE)
    b.path(im,outline(.72,7,-4),v.GOLD)
    v.curl(im,x+6,y-3,r*.46,ph,v.IVORY,max(1.4,r*.13),ph*.2,.82)
    b.ellipse(im,(x+3-r*.2,y-4-r*.2,x+3+r*.2,y-4+r*.2),v.IVORY)
    b.path(im,[('M',x-r*.36,y-r*.68),('C',x-r*.65,y-r*.25,x-r*.47,y+r*.34,x-r*.18,y+r*.45)],None,(236,79,24,255),max(1,r*.075))
    b.arc(im,x+1,y,r*.99,-1.25,-.35,(255,227,125,255),max(1,r*.06),.87)

def projectile(t):
    im=b.rgba(512,256);x,y=369,128;ph=t*TAU
    for k in [1,-1,0]:
        v.fire_stream(im,x-8,y+k*17,218-abs(k)*31,49-abs(k)*8,ph+k*1.8,
          math.pi+k*.08,colors=((206,41,35,255),v.ORANGE,v.GOLD))
    orb(im,x,y,37+2*math.sin(ph),ph)
    # Two torn, curled highlights remain subordinate to the main flame body.
    b.path(im,[('M',x-30,y-15),('C',x-71,y-42,x-122,y-33-6*math.sin(ph),x-162,y-7),
      ('C',x-137,y-22,x-113,y-17,x-90,y-8)],None,(255,221,100,245),2.2)
    for k in range(18):
        u=(t+k*.0817)%1;xx=x-45-u*238;yy=y+math.sin(k*2.5)*(27+u*32)
        alpha=int(210*math.sin(math.pi*u)**.7)
        b.line(im,[(xx-4-u*8,yy),(xx,yy)],(255,172+k%3*25,57,alpha),1.3)
    return bloom(im,.65)

def charge(profile,t):
    im=b.rgba(256,256);x=y=128;ph=t*TAU
    if profile=='mouth':
        grow=b.smooth((t-.2)/.8);r=3+27*grow
        for k in range(3):
            a=k*TAU/3+ph*.3;rad=65*(1-grow*.6)
            b.arc(im,x,y,rad,a,a+.6,(255,157,46,int(120*math.sin(math.pi*t))),1.5,.75)
        for k in range(10):
            u=(t+k*.11)%1;xx=x+72*(1-u);yy=y+math.sin(k*2.7)*28*(1-u)
            b.line(im,[(xx+6,yy),(xx,yy)],(255,171,49,int(160*math.sin(math.pi*u)*grow)),1.2)
        orb(im,x,y,r,ph)
    elif profile=='hand':
        grow=b.smooth(t/.8);r=3+30*grow
        for k in range(3):
            a=ph*1.1+k*TAU/3;rad=52-13*grow
            b.arc(im,x,y,rad,a,a+.95,(255,183,67,int(170*math.sin(math.pi*t)**.5)),1.8,.75)
        orb(im,x,y,r,ph)
        for k in range(12):
            a=k*2.4+ph*.4;u=(t+k*.082)%1;rad=68*(1-u)
            xx=x+math.cos(a)*rad;yy=y+math.sin(a)*rad
            b.ellipse(im,(xx-1,yy-1,xx+1,yy+1),(255,211,105,int(190*math.sin(math.pi*u))))
    else:
        grow=b.smooth((t-.07)/.43);r=2+30*grow
        # Orb forms above a low ring; the character physically strikes its left edge.
        alpha=int(125*(1-b.smooth((t-.75)/.25)))
        b.arc(im,x,y+52,36,0,TAU,(246,142,46,alpha),1.7,.23)
        for k in range(9):
            u=(t*1.15+k*.109)%1
            xx=x+math.sin(k*2.5)*39*(1-u);yy=y+65*(1-u)
            b.line(im,[(xx,yy+4),(xx,yy)],(255,179,55,int(170*math.sin(math.pi*u)*grow)),1.3)
        orb(im,x,y,r,ph)
    return bloom(im,.55)

def release_flare(t):
    im=b.rgba(256,256);x=y=128;fade=1-b.smooth(t)
    for k in range(5):
        a=-.95+k*.47
        v.fire_stream(im,x,y,(19+53*t)*fade,16*fade,t*7+k,a,alpha=fade)
    if t<.5:b.sparkle(im,x,y,27*(1-t*2),(255,235,162,int(190*(1-t*2))),.2)
    return bloom(im,.5)

def impact(t):
    # The shared impact has one contact beat, a clear expanding body and a short tail.
    im=v.impact_comet(t)
    # Runtime rendering is source-over; glow is authored into the atlas.
    return im

def pose(profile,t):
    recoil=ease_between(t,1.2,1.3)*(1-ease_between(t,1.4,1.75))
    if profile=='mouth':
        breath=math.sin(math.pi*b.clamp(t/1.2))
        push=6*ease_between(t,1.05,1.2)-9*recoil
        head=(209+push,220-4*breath)
        return {'head':head,'socket':(head[0]+64,head[1]+6),'palm':(222,291),'foot':(233,354),'chest':breath}
    if profile=='hand':
        # Draw the palm back, then push it forward during the release phase.
        palm=lerp((243,263),(218,242),ease_between(t,0,.7))
        palm=lerp(palm,(279,236),ease_between(t,.87,1.2))
        palm=lerp(palm,(245,263),ease_between(t,1.45,1.8))
        return {'head':(171,209),'socket':(palm[0]+13,palm[1]-5),'palm':palm,'foot':(204,354),'chest':0}
    knee=lerp((199,320),(157,308),ease_between(t,.55,.95))
    foot=lerp((221,354),(124,313),ease_between(t,.55,.95))
    knee=lerp(knee,(220,283),ease_between(t,.97,1.2))
    foot=lerp(foot,(256,288),ease_between(t,.97,1.2))
    knee=lerp(knee,(240,281),ease_between(t,1.2,1.4))
    foot=lerp(foot,(299,275),ease_between(t,1.2,1.4))
    knee=lerp(knee,(199,320),ease_between(t,1.45,1.9))
    foot=lerp(foot,(221,354),ease_between(t,1.45,1.9))
    ball=(288,288+4*math.sin(t*4)*(1-ease_between(t,.85,1.2)))
    return {'head':(166+6*ease_between(t,.97,1.2)-4*recoil,210),'socket':ball,'palm':(230,252),'foot':foot,'knee':knee,'chest':0}

def limb(im,pts,width=13,front=True):
    v.ribbon(im,pts,[width,width*.92,width*.6],MID if front else INK,EDGE if front else LIGHT)
    if front:v.ribbon(im,[(x-2,y-2) for x,y in pts],[width*.32,width*.26,width*.2],LIGHT)

def beast_head(im,head,profile,t):
    x,y=head
    if profile=='mouth':
        b.path(im,[('M',x-37,y+13),('C',x-56,y-17,x-33,y-43,x+5,y-36),('L',x+33,y-22),('L',x+65,y-1),
          ('L',x+54,y+23),('C',x+20,y+39,x-12,y+35,x-37,y+13),('Z',)],MID,EDGE,1.8)
        b.poly(im,[(x-27,y-25),(x-31,y-68),(x-1,y-39)],INK,EDGE,1.5)
        b.poly(im,[(x+6,y-34),(x+13,y-59),(x+26,y-26)],LIGHT,EDGE,1.2)
        b.path(im,[('M',x+23,y+8),('C',x+35,y+3,x+53,y+4,x+64,y+7)],None,(9,15,24,255),4)
        b.poly(im,[(x+7,y-14),(x+30,y-14),(x+17,y-6)],EYES)
        b.poly(im,[(x+12,y-14),(x+16,y-13),(x+15,y-7)],INK)
        if .8<t<1.36:b.line(im,[(x+38,y+9),(x+61,y+8)],(255,146,59,230),2)
    else:
        # Two different demo silhouettes; final Umbral artwork can replace these rigs.
        b.path(im,[('M',x-28,y+4),('C',x-35,y-21,x-17,y-35,x+10,y-32),('L',x+33,y-13),
          ('L',x+29,y+15),('L',x+9,y+31),('L',x-18,y+26),('Z',)],MID,EDGE,1.7)
        horns=[[(x-25,y-17),(x-29,y-61),(x-7,y-31)],[(x+10,y-30),(x+18,y-56),(x+27,y-21)]]
        for pts in horns:b.poly(im,pts,INK,EDGE,1.4)
        b.poly(im,[(x-8,y-6),(x+5,y-2),(x-3,y+4)],EYES)
        b.poly(im,[(x+12,y-2),(x+27,y-5),(x+20,y+5)],EYES)
        b.line(im,[(x+6,y+12),(x+18,y+16)],(19,27,40,255),2)
        if profile=='kick':b.poly(im,[(x+19,y+7),(x+37,y+14),(x+23,y+19)],LIGHT)

def actor(profile,t):
    im=b.rgba(384,384);p=pose(profile,t)
    # Faint contact shadow anchors the motion while preserving transparent surroundings.
    b.ellipse(im,(107,351,246,366),(10,14,22,145))
    if profile=='mouth':
        b.path(im,[('M',151,277),('C',123,290,98,280,79,257),('C',78,284,97,311,149,309),('Z',)],INK,LIGHT,1.3)
        limb(im,[(162,291),(144,326),(122,354)],14,False)
        b.poly(im,[(106,356),(133,342),(148,356)],MID,EDGE,1)
        chest=8*p['chest']
        b.path(im,[('M',148,294),('C',132,271,148,243-chest,177,236-chest),('L',215,245),
          ('C',232,267,220,294,198,310),('L',158,310),('Z',)],MID,EDGE,1.8)
        b.path(im,[('M',180,246),('C',197,258,205,277,191,301),('L',210,287),('C',217,264,207,251,198,246),('Z',)],LIGHT)
        limb(im,[(196,292),(213,326),(229,351)],15)
        b.poly(im,[(208,357),(229,345),(245,357)],MID,EDGE,1.3)
        limb(im,[(203,254),(211,281),(226,294)],9)
        for k in range(3):b.poly(im,[(221+k*6,290),(232+k*5,301),(224+k*5,299)],LIGHT)
    elif profile=='hand':
        b.poly(im,[(133,341),(139,357),(156,359),(157,337)],INK,EDGE,1)
        b.poly(im,[(184,339),(187,357),(208,356),(200,335)],INK,EDGE,1)
        # The robe deliberately differs from the athletic and beast silhouettes.
        b.path(im,[('M',146,238),('L',180,233),('C',197,255,205,301,223,343),('L',179,330),
          ('L',156,345),('L',111,340),('C',135,299,126,260,146,238),('Z',)],INK,EDGE,1.8)
        b.path(im,[('M',152,243),('L',168,243),('L',192,325),('L',166,315),('Z',)],MID)
        limb(im,[(143,252),(122,278),(131,299)],9,False)
        palm=p['palm'];elbow=((184+palm[0])*.5,260)
        limb(im,[(183,247),elbow,palm],11)
        b.ellipse(im,(palm[0]-9,palm[1]-8,palm[0]+10,palm[1]+8),LIGHT,EDGE,1)
        for k in range(3):b.line(im,[(palm[0]+4,palm[1]-5+k*4),(palm[0]+16-k*2,palm[1]-10+k*6)],EDGE,3)
        b.poly(im,[(153,243),(169,269),(182,240)],LIGHT,EDGE,1)
    else:
        # Athletic rig: a clear wind-up, foot contact, extension and recovery.
        b.path(im,[('M',145,289),('C',108,297,100,282,84,269),('C',92,308,112,321,159,307),('Z',)],INK,LIGHT,1.2)
        limb(im,[(168,295),(155,329),(143,355)],14,False)
        b.poly(im,[(126,356),(146,347),(166,357)],MID,EDGE,1.3)
        limb(im,[(151,245),(132,264),(115,250)],10,False)
        b.path(im,[('M',146,241),('L',181,237),('C',197,260,194,279,184,302),('L',153,304),
          ('C',150,282,140,265,146,241),('Z',)],MID,EDGE,1.8)
        b.poly(im,[(152,248),(174,245),(184,281),(170,290),(157,279)],LIGHT)
        limb(im,[(179,247),(203,253),(228,245)],10)
        limb(im,[(174,294),p['knee'],(p['foot'][0]-15,p['foot'][1]-2)],14)
        fx,fy=p['foot'];b.poly(im,[(fx-26,fy-9),(fx-13,fy-13),(fx+4,fy-2),(fx,fy+7),(fx-25,fy+5)],MID,EDGE,1.5)
        b.line(im,[(fx-21,fy+4),(fx-1,fy+4)],LIGHT,2)
    beast_head(im,p['head'],profile,t)
    return im

def sprite_sheet(frames,name,cols,anchor,logical_size=None):
    old=b.ASSETS;b.ASSETS=ASSETS
    result=b.make_sheet(frames,name,cols,anchor,FPS,name=='projectile')
    b.ASSETS=old
    result['logicalWidth'],result['logicalHeight']=logical_size or frames[0].size
    # A lower tier reduces atlas area fourfold and keeps the same anchors in logical units.
    sheet=Image.open(ASSETS/f'{name}.png')
    sheet.resize((sheet.width//2,sheet.height//2),Image.Resampling.LANCZOS).save(ASSETS/f'{name}-low.png',optimize=True)
    result['lowImage']=f'assets/{name}-low.png'
    return result

def encode(frames,path,width=None):
    w,h=frames[0].size
    p=subprocess.Popen(['ffmpeg','-y','-v','error','-f','rawvideo','-pix_fmt','rgb24','-s',f'{w}x{h}','-r','30','-i','pipe:0','-c:v','libx264','-crf','17','-pix_fmt','yuv420p','-movflags','+faststart',str(path.with_suffix('.mp4'))],stdin=subprocess.PIPE)
    for im in frames:p.stdin.write(im.convert('RGB').tobytes())
    p.stdin.close()
    if p.wait()!=0:raise RuntimeError('Video encoding failed')
    if width:
        subprocess.run(['ffmpeg','-y','-v','error','-i',str(path.with_suffix('.mp4')),'-filter_complex',
          f'fps=24,scale={width}:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=224:stats_mode=diff[p];[s1][p]paletteuse=dither=bayer:bayer_scale=4',
          '-loop','0',str(path.with_suffix('.gif'))],check=True)

def bg(profile):
    oldo,oldt=b.ORIGIN,b.TARGET;b.ORIGIN=(175,308);b.TARGET=TARGET
    im=b.background();b.ORIGIN,b.TARGET=oldo,oldt
    # Overwrite header and origin marker with the unlabelled backdrop pixels.
    yy,xx=np.mgrid[0:b.H*b.S,0:b.W*b.S];xx=xx/b.S;yy=yy/b.S
    vign=np.exp(-(((xx-b.W*.5)/(b.W*.7))**2+((yy-b.H*.42)/(b.H*.65))**2)*2)
    arr=np.zeros((b.H*b.S,b.W*b.S,4),dtype=np.uint8)
    for c,(base,gain) in enumerate([(9,10),(12,13),(22,19)]):arr[:,:,c]=(base+gain*vign).astype(np.uint8)
    arr[:,:,3]=255;pure=Image.fromarray(arr)
    im.paste(pure.crop((0,0,b.W*b.S,110*b.S)),(0,0))
    im.paste(pure.crop((80*b.S,130*b.S,365*b.S,440*b.S)),(80*b.S,130*b.S))
    label,sub=LABELS[profile]
    b.text(im,(42,31),'UMBRAL · BOLA DE FOGO',23,(245,242,234,255),True)
    b.text(im,(43,72),sub,13,(137,151,179,255))
    b.text(im,(918,40),'04 / '+label,11,(240,157,72,255),False,'ra')
    b.ellipse(im,(107,380,250,396),None,(75,94,123,130),1)
    b.text(im,(178,424),'UMBRAL',11,(144,159,186,255),True,'mm')
    return im

def flight(source,u):
    p=u**1.08;dx=TARGET[0]-source[0];dy=TARGET[1]-source[1]
    curve=26;x=source[0]+dx*p;y=source[1]+dy*p-curve*math.sin(math.pi*p)
    angle=-math.degrees(math.atan2(dy-curve*math.pi*math.cos(math.pi*p),dx))
    return (x,y),angle

def main():
    print('V4: drawing shared fireball and impact',flush=True)
    pro=[b.native(projectile(i/24)) for i in range(24)]
    impacts=[b.native(impact(i/41)).resize((384,384),Image.Resampling.LANCZOS) for i in range(42)]
    flares=[b.native(release_flare(i/5)) for i in range(6)]
    meta={'id':'umbral-fireball-v4','durationMs':4000,'fps':30,'actorRoot':{'x':175,'y':386},'target':{'x':735,'y':264},
      'releaseMs':1200,'impactMs':2000,'phases':json.loads((OUT/'vfx-spec.json').read_text())['phases'],
      'projectile':sprite_sheet(pro,'projectile',6,(369,128)),
      'impact':sprite_sheet(impacts,'impact',6,(192,192),(640,640)),
      'release':sprite_sheet(flares,'release-flare',3,(128,128)),
      'profiles':{}}
    sprites={'projectile':[im.resize((im.width*b.S,im.height*b.S),Image.Resampling.LANCZOS) for im in pro],
      'impact':[im.resize((640*b.S,640*b.S),Image.Resampling.LANCZOS) for im in impacts],
      'release':[im.resize((im.width*b.S,im.height*b.S),Image.Resampling.LANCZOS) for im in flares]}
    all_frames={};all_fx={}
    for profile in PROFILE_IDS:
        print('V4: '+profile+' casting animation',flush=True)
        actors=[b.native(actor(profile,i/FPS)) for i in range(60)]
        charges=[b.native(charge(profile,i/35)) for i in range(36)]
        small_actors=[im.resize((256,256),Image.Resampling.LANCZOS) for im in actors]
        actor_meta=sprite_sheet(small_actors,profile+'-actor',8,(100,352*2/3),(384,384))
        charge_meta=sprite_sheet(charges,profile+'-charge',6,(128,128))
        socket_track=[{'x':pose(profile,i/FPS)['socket'][0],'y':pose(profile,i/FPS)['socket'][1]} for i in range(60)]
        meta['profiles'][profile]={'label':LABELS[profile][0],'description':LABELS[profile][1],'anchor':{'mouth':'mouth','hand':'right_hand','kick':'conjured_orb'}[profile],
          'releaseEvent':{'mouth':'mouth.release','hand':'hand.release','kick':'foot.contact'}[profile],
          'actor':actor_meta,'charge':charge_meta,'socketTrack':socket_track,
          'releaseSocket':socket_track[36],'actorAnchor':{'x':150,'y':352}}
        release_socket=world(pose(profile,1.2)['socket'])
        actor_sprites=[im.resize((384*b.S,384*b.S),Image.Resampling.LANCZOS) for im in actors]
        charge_sprites=[im.resize((256*b.S,256*b.S),Image.Resampling.LANCZOS) for im in charges]
        background=bg(profile);frames=[];fx_frames=[]
        for i in range(FRAMES):
            scene=background.copy();fx=b.rgba(960,540)
            b.place(scene,actor_sprites[min(i,59)],ACTOR_ROOT,LOCAL_ROOT)
            if i<RELEASE:
                stage=0;socket=world(pose(profile,i/FPS)['socket'])
                b.place(fx,charge_sprites[i],socket,(128,128),1)
            elif i<HIT:
                stage=1;u=(i-RELEASE)/(HIT-RELEASE);pos,angle=flight(release_socket,u)
                b.place(fx,sprites['projectile'][(i-RELEASE)%24],pos,(369,128),.79+.06*b.smooth(u*2),angle)
                if i-RELEASE<6:b.place(fx,sprites['release'][i-RELEASE],release_socket,(128,128),.88)
            elif i<HIT+42:
                stage=2;hit=i-HIT
                if hit<4:
                    pos,angle=flight(release_socket,1)
                    b.place(fx,b.opacity(sprites['projectile'][(24+hit)%24],(1-hit/4)**2*.4),pos,(369,128),.85,angle)
                b.place(fx,sprites['impact'][hit],TARGET,(320,320),.72)
            else:stage=-1
            scene.alpha_composite(fx)
            for k,(label,x) in enumerate([('01  PREPARAÇÃO',43),('02  LANÇAMENTO',350),('03  IMPACTO',650)]):
                b.text(scene,(x,486),label,11,(255,191,100,255) if stage==k else (84,99,128,255),True)
                if stage==k:b.line(scene,[(x,462),(x+220,462)],(255,155,48,255),2)
            frames.append(b.native(scene).convert('RGB'));fx_frames.append(b.native(fx))
        all_frames[profile]=frames;all_fx[profile]=fx_frames
        print('V4: encoding '+profile,flush=True)
        encode(frames,OUT/('fireball-'+profile),768 if profile=='kick' else None)
        # Complete FX-only launch: demonstration characters are excluded from this file.
        fx_frames[0].save(OUT/('fireball-'+profile+'-transparent.webp'),save_all=True,append_images=fx_frames[1:],duration=[33,33,34]*40,loop=0,lossless=True)
        frames[35].save(OUT/(profile+'-release-still.png'))
    (ASSETS/'fireball.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2))
    # A compact three-row comparison makes the personalised starts easy to compare.
    comparison=[]
    for i in range(FRAMES):
        im=Image.new('RGB',(960,1050),(11,15,25));d=ImageDraw.Draw(im)
        header=b.rgba(960,90);header.paste((11,15,25,255),(0,0,1920,180))
        b.text(header,(30,17),'UMBRAL · UM GOLPE, TRÊS LANÇAMENTOS',21,(245,240,229,255),True)
        b.text(header,(31,51),'Bola de fogo v4 · preparação própria, voo e impacto compartilhados',12,(143,160,187,255))
        im.paste(b.native(header).convert('RGB'),(0,0))
        for row,profile in enumerate(PROFILE_IDS):
            y=90+row*306
            im.paste(all_frames[profile][i].crop((0,138,960,410)),(0,y+29))
            label=b.rgba(960,29);label.paste((16,23,37,255),(0,0,1920,58))
            b.text(label,(31,6),LABELS[profile][0],12,(255,191,104,255),True)
            b.text(label,(155,6),LABELS[profile][1],12,(153,167,190,255))
            im.paste(b.native(label).convert('RGB'),(0,y))
            d.line((30,y+303,930,y+303),fill=(43,55,77),width=1)
        footer=b.rgba(960,34);footer.paste((11,15,25,255),(0,0,1920,68))
        b.text(footer,(31,8),'Silhuetas de demonstração · o fogo se solta no gesto de cada Umbral',11,(113,132,164,255))
        im.paste(b.native(footer).convert('RGB'),(0,1016))
        comparison.append(im)
    print('V4: encoding three-start comparison',flush=True)
    encode(comparison,OUT/'fireball-launch-comparison',768)
    comparison[35].save(OUT/'launch-comparison-still.jpg',quality=94)
    print('V4 ready',flush=True)

if __name__=='__main__':main()
