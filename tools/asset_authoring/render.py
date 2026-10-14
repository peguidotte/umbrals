"""Original 2D fire spell: transparent sprites, metadata and a rendered preview.
Requires Pillow, numpy and aggdraw. Run: python render.py
"""
from pathlib import Path
import os
import json, math, random, subprocess
import numpy as np
import aggdraw
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(os.environ.get("UMBRAL_ASSET_OUTPUT", str(Path(__file__).resolve().parents[2] / "builds/asset-work/vfx"))).resolve()
if ROOT.is_relative_to(Path(__file__).resolve().parents[2] / "assets"):
    raise ValueError("Author into staging, never into a versioned release")
ROOT.mkdir(parents=True, exist_ok=True)
ASSETS = ROOT / 'assets'
ASSETS.mkdir(exist_ok=True)
S = 2
FPS = 30
W, H = 960, 540
TAU = math.tau

def clamp(x, a=0, b=1): return max(a, min(b, x))
def smooth(x): x = clamp(x); return x*x*(3-2*x)
def rgba(w, h): return Image.new('RGBA', (w*S, h*S))
def line(im, pts, color, width=1):
    ImageDraw.Draw(im).line([(x*S,y*S) for x,y in pts], fill=color, width=max(1,round(width*S)), joint='curve')
def ellipse(im, box, color, outline=None, width=1):
    ImageDraw.Draw(im).ellipse(tuple(round(v*S) for v in box), fill=color, outline=outline, width=max(1,round(width*S)))
def path(im, cmds, color, outline=None, width=1):
    p = aggdraw.Path()
    for cmd in cmds:
        op, *v = cmd
        v = [x*S for x in v]
        if op=='M': p.moveto(*v)
        elif op=='L': p.lineto(*v)
        elif op=='C': p.curveto(*v)
        elif op=='Q': pass
        elif op=='Z': p.close()
    ctx=aggdraw.Draw(im)
    ctx.path(p,aggdraw.Pen(outline,width*S) if outline else None, aggdraw.Brush(color) if color else None)
    ctx.flush()

def poly(im,pts,color,outline=None,width=1):
    path(im,[('M',*pts[0])]+[('L',*p) for p in pts[1:]]+[('Z',)],color,outline,width)

def gradient_path(im, cmds, stops, outline=None, width=1):
    mask=Image.new('L',im.size)
    path(mask,cmds,255)
    # A continuous horizontal gradient with a warm leading edge.
    arr=np.empty((im.height,im.width,4),dtype=np.uint8)
    positions=np.array([a[0]*S for a in stops])
    cols=np.array([a[1] for a in stops])
    for c in range(3): arr[:,:,c]=np.interp(np.arange(im.width),positions,cols[:,c]).astype(np.uint8)[None,:]
    arr[:,:,3]=np.array(mask)
    im.alpha_composite(Image.fromarray(arr))
    if outline: path(im,cmds,None,outline,width)

def arc(im,cx,cy,r,a0,a1,color,width=2, squash=1):
    pts=[(cx+r*math.cos(a),cy+squash*r*math.sin(a)) for a in np.linspace(a0,a1,90)]
    line(im,pts,color,width)

def glow(im, amount=1):
    a=im.getchannel('A')
    bright=Image.new('RGBA',im.size,(255,87,13,0))
    bright.putalpha(a.point(lambda v:int(v*.28*amount)).filter(ImageFilter.GaussianBlur(15*S)))
    soft=im.filter(ImageFilter.GaussianBlur(5*S))
    soft.putalpha(soft.getchannel('A').point(lambda v:int(v*.42*amount)))
    bright.alpha_composite(soft)
    bright.alpha_composite(im)
    return bright

def opacity(im,alpha):
    out=im.copy(); out.putalpha(out.getchannel('A').point(lambda a:round(a*clamp(alpha)))); return out

def sparkle(im,x,y,r,color=(255,241,176,255), angle=0):
    pts=[]
    for i in range(8):
        a=i*math.pi/4+angle; rr=r if i%2==0 else r*.24
        pts.append((x+rr*math.cos(a),y+rr*math.sin(a)))
    poly(im,pts,color)

def tongue(im,x,y,angle,length,width,phase,colors):
    """A tapering, curved, hand-drawn flame with a nested hot center."""
    dx,dy=math.cos(angle),math.sin(angle); nx,ny=-dy,dx
    curl=math.sin(phase)*.18*length
    def at(u,v): return (x+dx*u+nx*v,y+dy*u+ny*v)
    cmds=[('M',*at(0,-width*.52)),
          ('C',*at(length*.26,-width*.72),*at(length*.65,curl-width*.24),*at(length,curl)),
          ('C',*at(length*.64,curl+width*.08),*at(length*.5,-width*.08),*at(length*.34,width*.48)),
          ('C',*at(length*.12,width*.78),*at(-width*.22,width*.37),*at(0,-width*.52)),('Z',)]
    path(im,cmds,colors[0],(106,24,43,230),1.2)
    inner=[('M',*at(-1,-width*.28)),
           ('C',*at(length*.22,-width*.34),*at(length*.56,curl-width*.12),*at(length*.8,curl*.83)),
           ('C',*at(length*.35,curl*.2+width*.16),*at(length*.12,width*.3),*at(-1,-width*.28)),('Z',)]
    path(im,inner,colors[1])

def projectile(t):
    im=rgba(512,320); cx,cy=348,160
    ph=t*TAU
    f=math.sin(ph); g=math.sin(ph+1.8)
    # Separate trailing flame tongues add depth behind the main silhouette.
    tongue(im,cx-55,cy-25,math.pi+.23,155+12*f,24,ph,((232,48,26,245),(255,151,29,255)))
    tongue(im,cx-76,cy+21,math.pi-.34,151-10*g,28,ph+1,((227,43,30,240),(255,126,18,255)))
    outer=[('M',cx+48,cy),
      ('C',cx+48,cy-29,cx+17,cy-51,cx-18,cy-48),
      ('C',cx-62,cy-47,cx-86,cy-79-7*f,cx-144,cy-80-9*f),
      ('C',cx-128,cy-58,cx-101,cy-55,cx-86,cy-36),
      ('C',cx-122,cy-49,cx-167,cy-54-10*g,cx-222,cy-40-11*g),
      ('C',cx-180,cy-39,cx-169,cy-13,cx-108,cy-14),
      ('C',cx-150,cy+4,cx-184,cy-8+8*f,cx-247,cy+17+10*f),
      ('C',cx-179,cy+8,cx-172,cy+33,cx-135,cy+28),
      ('C',cx-106,cy+47,cx-145,cy+52+6*g,cx-161,cy+63+6*g),
      ('C',cx-117,cy+76,cx-88,cy+53,cx-60,cy+43),
      ('C',cx-27,cy+61,cx+18,cy+51,cx+39,cy+28),
      ('C',cx+47,cy+18,cx+48,cy+8,cx+48,cy),('Z',)]
    gradient_path(im,outer,[(85,(171,27,49)),(155,(237,48,29)),(270,(255,102,19)),(400,(255,187,39))],(117,24,48,255),2.2)
    middle=[('M',cx+37,cy-2),
      ('C',cx+40,cy-31,cx+2,cy-39,cx-24,cy-34),
      ('C',cx-58,cy-31,cx-82,cy-57-4*f,cx-117,cy-60-4*f),
      ('C',cx-85,cy-36,cx-78,cy-22,cx-62,cy-19),
      ('C',cx-103,cy-22,cx-135,cy-37,cx-178,cy-30),
      ('C',cx-139,cy-18,cx-108,cy-6,cx-72,cy-6),
      ('C',cx-101,cy+14,cx-144,cy+14+6*g,cx-183,cy+21+7*g),
      ('C',cx-146,cy+23,cx-111,cy+39,cx-78,cy+24),
      ('C',cx-53,cy+29,cx-37,cy+43,cx-8,cy+35),
      ('C',cx+19,cy+32,cx+34,cy+21,cx+37,cy-2),('Z',)]
    gradient_path(im,middle,[(150,(255,108,15)),(260,(255,183,30)),(391,(255,224,93))])
    # A twisting negative-space ribbon makes the silhouette feel illustrated.
    path(im,[('M',cx-15,cy-32),('C',cx-47,cy-18,cx-73,cy-15,cx-113,cy-31),
             ('C',cx-74,cy-9,cx-60,cy+5,cx-24,cy-5),
             ('C',cx-6,cy-11,cx+3,cy-21,cx-15,cy-32),('Z',)],(255,125,19,255))
    core=[('M',cx+28,cy-2),('C',cx+28,cy-23,cx+9,cy-29,cx-9,cy-23),
          ('C',cx-28,cy-20,cx-42,cy-11,cx-75,cy-14-2*f),
          ('C',cx-54,cy-2,cx-48,cy+12,cx-21,cy+9),
          ('C',cx-37,cy+22,cx-50,cy+24,cx-66,cy+20+2*g),
          ('C',cx-43,cy+34,cx-12,cy+30,cx+9,cy+19),
          ('C',cx+25,cy+11,cx+28,cy+4,cx+28,cy-2),('Z',)]
    gradient_path(im,core,[(270,(255,231,116)),(349,(255,251,217)),(380,(255,255,237))])
    # Thin cel-shaded contours and a sharp leading glint.
    path(im,[('M',cx+28,cy-33),('C',cx+44,cy-22,cx+45,cy-9,cx+43,cy+2)],None,(255,245,164,255),2.4)
    path(im,[('M',cx-66,cy+45),('C',cx-26,cy+55,cx+10,cy+48,cx+29,cy+30)],None,(248,76,26,230),2)
    # Detached ember fragments: reproducible, advect backwards and wiggle.
    for k in range(12):
        u=(t+k*.087)%1
        x=cx-65-u*235; y=cy+math.sin(k*2.7)*57+math.sin(ph+k)*7
        a=int(220*(1-u)); r=(2.2+((k*13)%7)/5)*(1-u*.45)
        tail=9+u*13
        poly(im,[(x+r,y),(x-tail,y-r*.7),(x-tail*.5,y+r*.5)],(255,167+(k%3)*20,55,a))
        if k%4==0: sparkle(im,x,y,r*1.7,(255,236,155,a))
    return glow(im, .85)

def charge(t):
    im=rgba(384,384); cx=cy=192
    grow=smooth(t); r=3+grow*30
    # Converging arcs, never a full mechanical circle.
    for k in range(3):
        rad=(83-35*grow)+k*10
        a=t*4.5+k*TAU/3
        arc(im,cx,cy,rad,a,a+.95,(255,125+k*25,34,int(180*math.sin(math.pi*t)**.5)),2.1-k*.25,.8)
    for k in range(14):
        a=k*2.399+t*.8; u=(t*1.25+k*.073)%1
        dist=92*(1-u)+9
        x=cx+math.cos(a)*dist; y=cy+math.sin(a)*dist*.8
        aa=int(210*math.sin(math.pi*u)*smooth(t*5))
        line(im,[(x+math.cos(a)*6,y+math.sin(a)*5),(x,y)],(255,154,46,aa),1.8)
        ellipse(im,(x-1.2,y-1.2,x+1.2,y+1.2),(255,227,117,aa))
    for k in range(6):
        a=k*TAU/6+t*3; base=(cx+math.cos(a)*r*.35,cy+math.sin(a)*r*.35)
        tongue(im,*base,a,r*(1.28+.2*math.sin(t*15+k)),r*.55,t*18+k,((247,70,21,255),(255,194,47,255)))
    ellipse(im,(cx-r,cy-r,cx+r,cy+r),(255,124,21,255),outline=(246,70,26,255),width=2)
    ellipse(im,(cx-r*.72,cy-r*.72,cx+r*.72,cy+r*.72),(255,214,75,255))
    ellipse(im,(cx-r*.4,cy-r*.44,cx+r*.43,cy+r*.4),(255,251,207,255))
    if t>.72:
        sparkle(im,cx+5,cy-5,8*smooth((t-.72)/.28),(255,255,231,255),t)
    return glow(im,.65)

RNG=random.Random(71)
EMBERS=[(RNG.random()*TAU,RNG.uniform(100,213),RNG.uniform(2,5),RNG.random()) for _ in range(45)]

def impact(t):
    im=rgba(512,512); cx=cy=256
    enter=smooth(t/.18); die=1-smooth((t-.34)/.65)
    pulse=math.sin(math.pi*clamp(t/.72))
    radius=14+155*(1-(1-t)**3)
    # Expanding shockwave with broken warm rings.
    if t<.8:
        aa=int(235*(1-t/.8)**1.1)
        for k in range(4):
            a=k*TAU/4+.25+t*.4
            arc(im,cx,cy,radius,a,a+1.16,(255,187,58,aa),4*(1-t)+.8,.87)
        arc(im,cx,cy,radius*.88,.2+t,3.9+t,(248,79,27,aa//2),2,.87)
    # Ember cloud expands around the target and falls under gravity.
    for k,(a,dist,size,offset) in enumerate(EMBERS):
        u=clamp((t-.03)/.92)
        rr=dist*(1-(1-u)**2)
        x=cx+math.cos(a)*rr; y=cy+math.sin(a)*rr*.77+49*u*u
        alpha=int(255*clamp((1-u)*1.6)*smooth(t/.06))
        r=size*(1-u*.68)
        if k%6==0:
            sparkle(im,x,y,r*1.7,(255,224,108,alpha),a+u)
        else:
            poly(im,[(x+r*math.cos(a),y+r*math.sin(a)),
                (x-math.cos(a)*r*3-math.sin(a)*r*.5,y-math.sin(a)*r*3+math.cos(a)*r*.5),
                (x-math.cos(a)*r*2+math.sin(a)*r*.5,y-math.sin(a)*r*2-math.cos(a)*r*.5)],
                (255,125+(k%3)*40,35,alpha))
    # Rounded flame petals surround the hit point instead of one circular blob.
    flames=rgba(512,512)
    for k in range(11):
        a=k*TAU/11+.15
        length=(86+26*math.sin(k*3.4))*enter*die
        base=20*enter*die
        x=cx+math.cos(a)*base; y=cy+math.sin(a)*base
        tongue(flames,x,y,a,length,40*enter*die,t*17+k*1.8,
          ((240,64+(k%3)*7,24,255),(255,171+(k%3)*12,30,255)))
    # A rotating inner whirl that wraps the target as the petals disperse.
    core_r=(15+49*enter)*die
    if core_r>1:
        pts=[]
        for j in range(120):
            a=j*TAU/120
            rr=core_r*(1+.16*math.sin(a*6+t*17)+.075*math.sin(a*11-t*13))
            pts.append((cx+math.cos(a)*rr,cy+math.sin(a)*rr))
        poly(flames,pts,(255,181,32,255),(248,83,21,255),2)
        for k in range(4):
            a=k*TAU/4+t*5
            arc(flames,cx,cy,core_r*.65,a,a+1.1,(255,237,142,255),max(2,core_r*.16))
        ellipse(flames,(cx-core_r*.39,cy-core_r*.39,cx+core_r*.39,cy+core_r*.39),(255,248,193,255))
    flames=opacity(flames,die**.33)
    im.alpha_composite(flames)
    # Short, pointed contact flash; it is confined to the target.
    flash=clamp(1-t/.12)
    if flash>0:
        pts=[]
        for k in range(16):
            a=k*TAU/16+.15; rr=(92 if k%2==0 else 11)*flash
            pts.append((cx+math.cos(a)*rr,cy+math.sin(a)*rr))
        poly(im,pts,(255,253,224,int(255*flash)))
    return glow(im,.7)

def native(im): return im.resize((im.width//S,im.height//S),Image.Resampling.LANCZOS)

def make_sheet(frames,name,columns,anchor,fps,loop=False):
    fw,fh=frames[0].size; rows=math.ceil(len(frames)/columns)
    sheet=Image.new('RGBA',(fw*columns,fh*rows))
    for i,im in enumerate(frames): sheet.paste(im,((i%columns)*fw,(i//columns)*fh))
    sheet.save(ASSETS/f'{name}.png',optimize=True)
    frames[0].save(ASSETS/f'{name}.webp',save_all=True,append_images=frames[1:],duration=round(1000/fps),loop=0 if loop else 1,lossless=True)
    return {'image':f'assets/{name}.png','frameWidth':fw,'frameHeight':fh,'columns':columns,
      'frames':len(frames),'fps':fps,'anchor':{'x':anchor[0],'y':anchor[1]},'loop':loop}

FONT='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
BOLD='/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
def text(im,xy,s,size=14,color=(182,191,215,255),bold=False,anchor=None):
    ImageDraw.Draw(im).text((xy[0]*S,xy[1]*S),s,font=ImageFont.truetype(BOLD if bold else FONT,size*S),fill=color,anchor=anchor)

ORIGIN=(165,300); TARGET=(775,238)
def background():
    yy,xx=np.mgrid[0:H*S,0:W*S]; xx=xx/S; yy=yy/S
    vign=np.exp(-(((xx-W*.5)/(W*.7))**2+((yy-H*.42)/(H*.65))**2)*2)
    arr=np.zeros((H*S,W*S,4),dtype=np.uint8)
    for c,(base,gain) in enumerate([(9,10),(12,13),(22,19)]):arr[:,:,c]=(base+gain*vign).astype(np.uint8)
    arr[:,:,3]=255
    bg=Image.fromarray(arr)
    text(bg,(42,33),'BOLA DE FOGO',25,(242,241,235,255),True)
    text(bg,(43,72),'Chamas em camadas · rastro vivo · explosão no alvo',13,(125,141,171,255))
    text(bg,(918,40),'01 / FOGO',11,(235,131,65,255),False,'ra')
    for x in range(45,950,34):
        for y in range(132,425,34): ellipse(bg,(x,y,x+.8,y+.8),(64,78,106,63))
    for (x,y),label in [(ORIGIN,'ORIGEM'),(TARGET,'ALVO')]:
        ellipse(bg,(x-38,y+45,x+38,y+57),None,(66,80,110,150),1)
        ellipse(bg,(x-22,y-22,x+22,y+22),None,(100,128,163,88),1)
        line(bg,[(x-6,y),(x+6,y)],(145,172,205,150),1)
        line(bg,[(x,y-6),(x,y+6)],(145,172,205,150),1)
        text(bg,(x,y+78),label,11,(139,155,181,255),True,'mm')
    line(bg,[(42,461),(918,461)],(45,56,79,180),1)
    return bg

def place(canvas,im,position,anchor,scale=1,angle=0):
    # Rotate around the anchor using a transparent padded canvas.
    px,py=position; ax,ay=anchor
    if angle:
        padded=Image.new('RGBA',(im.width*2,im.height*2))
        center=(im.width,im.height)
        padded.paste(im,(round(center[0]-ax*S),round(center[1]-ay*S)))
        im=padded.rotate(angle,Image.Resampling.BICUBIC,center=center)
        ax,ay=center[0]/S,center[1]/S
    if scale!=1:
        im=im.resize((round(im.width*scale),round(im.height*scale)),Image.Resampling.LANCZOS)
        ax,ay=ax*scale,ay*scale
    canvas.alpha_composite(im,(round(px*S-ax*S),round(py*S-ay*S)))

def main():
    print('Drawing transparent sprites...',flush=True)
    charges=[native(charge(i/19)) for i in range(20)]
    projectiles=[native(projectile(i/24)) for i in range(24)]
    impacts=[native(impact(i/35)) for i in range(36)]
    metadata={'name':'Bola de fogo','version':1,'direction':'right','durationMs':3200,
      'timing':{'chargeMs':667,'flightMs':800,'impactMs':1200,'pauseMs':533},
      'charge':make_sheet(charges,'charge',5,(192,192),FPS),
      'projectile':make_sheet(projectiles,'projectile',6,(348,160),FPS,True),
      'impact':make_sheet(impacts,'impact',6,(256,256),FPS)}
    (ASSETS/'fireball.json').write_text(json.dumps(metadata,ensure_ascii=False,indent=2))
    print('Compositing preview...',flush=True)
    bg=background(); frames=[]; transparent=[]
    # Native sprites are upscaled to the antialiased preview render resolution.
    charges=[im.resize((im.width*S,im.height*S),Image.Resampling.LANCZOS) for im in charges]
    projectiles=[im.resize((im.width*S,im.height*S),Image.Resampling.LANCZOS) for im in projectiles]
    impacts=[im.resize((im.width*S,im.height*S),Image.Resampling.LANCZOS) for im in impacts]
    for i in range(96):
        t=i/FPS; scene=bg.copy(); fx=rgba(W,H)
        phase=0 if i<20 else 1 if i<44 else 2 if i<80 else -1
        if phase==0:
            im=charges[i]
            place(fx,im,ORIGIN,(192,192),.86)
        elif phase==1:
            u=(i-20)/24
            travel=u**.85
            x=ORIGIN[0]+(TARGET[0]-ORIGIN[0])*travel
            y=ORIGIN[1]+(TARGET[1]-ORIGIN[1])*travel-43*math.sin(math.pi*travel)
            slope=(TARGET[1]-ORIGIN[1]-43*math.pi*math.cos(math.pi*travel))/(TARGET[0]-ORIGIN[0])
            angle=-math.degrees(math.atan(slope))
            im=projectiles[(i-20)%24]
            place(fx,im,(x,y),(348,160),.76+min(u*2,1)*.1,angle)
        elif phase==2:
            im=impacts[i-44]
            place(fx,im,TARGET,(256,256),1)
        scene.alpha_composite(fx)
        for k,(label,x) in enumerate([('01  CONCENTRAÇÃO',43),('02  DISPARO',350),('03  IMPACTO',650)]):
            active=phase==k
            text(scene,(x,486),label,11,(255,186,95,255) if active else (84,99,128,255),True)
            if active:
                line(scene,[(x,462),(x+220,462)],(255,155,48,255),2)
        frames.append(native(scene).convert('RGB'))
        transparent.append(native(fx))
    # The same full trajectory is available without the preview backdrop.
    print('Encoding animation...',flush=True)
    transparent[0].save(ROOT/'fireball-transparent.webp',save_all=True,append_images=transparent[1:],duration=[33,33,34]*32,loop=0,lossless=True)
    p=subprocess.Popen(['ffmpeg','-y','-v','error','-f','rawvideo','-pix_fmt','rgb24','-s',f'{W}x{H}','-r',str(FPS),'-i','pipe:0','-c:v','libx264','-crf','18','-pix_fmt','yuv420p','-movflags','+faststart',str(ROOT/'fireball-preview.mp4')],stdin=subprocess.PIPE)
    for im in frames:p.stdin.write(im.tobytes())
    p.stdin.close()
    if p.wait()!=0: raise RuntimeError('ffmpeg failed')
    # A shared palette and ordered dithering keep the inline preview compact.
    subprocess.run(['ffmpeg','-y','-v','error','-i',str(ROOT/'fireball-preview.mp4'),
      '-filter_complex','fps=24,scale=768:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=192:stats_mode=diff[p];[s1][p]paletteuse=dither=bayer:bayer_scale=5',
      '-loop','0',str(ROOT/'fireball-preview.gif')],check=True)
    frames[35].save(ROOT/'projectile-still.png')
    frames[51].save(ROOT/'impact-still.png')
    strip=Image.new('RGB',(W,H*3))
    for row,idx in enumerate([18,34,51]):strip.paste(frames[idx],(0,H*row))
    strip.resize((768,1296),Image.Resampling.LANCZOS).save(ROOT/'contact-sheet.jpg',quality=92)
    print('Ready.',flush=True)

if __name__=='__main__': main()
