"""Carpado do Eclipse: one forward pike somersault and an authored heel strike."""
from pathlib import Path
import os
import math, json, random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
import render as b
import render_variants as v
import render_umbral as u

ROOT = Path(os.environ.get("UMBRAL_ASSET_OUTPUT", str(Path(__file__).resolve().parents[2] / "builds/asset-work/vfx"))).resolve()
if ROOT.is_relative_to(Path(__file__).resolve().parents[2] / "assets"):
    raise ValueError("Author into staging, never into a versioned release")
ROOT.mkdir(parents=True, exist_ok=True)
OUT=ROOT/'mortal-carpado'
if not OUT.exists() and (ROOT.parent/'vfx-spec.json').exists():OUT=ROOT.parent
ASSETS=OUT/'assets';ASSETS.mkdir(parents=True,exist_ok=True)
FPS=30;N=126;HIT_FRAME=59;HIT=HIT_FRAME/FPS
ORIGIN=(180,320);TARGET=(735,350)
HEEL_OFFSET=(-11,6)
LILAC=(187,119,255,255);VIOLET=(121,68,222,255);PALE=(245,218,255,255);CYAN=(174,222,255,255)

def ease(t,a,z):return b.smooth((t-a)/(z-a))
def mix(a,z,k):return tuple(x+(y-x)*k for x,y in zip(a,z))
def add(a,z):return(a[0]+z[0],a[1]+z[1])
def rot(p,a):return(p[0]*math.cos(a)-p[1]*math.sin(a),p[0]*math.sin(a)+p[1]*math.cos(a))

def pose(t):
    """Pike posture is a hip fold; both knee chains are collinear while airborne."""
    crouch=ease(t,.08,.49)*(1-ease(t,.6,.78))
    landing=ease(t,HIT,2.17)*(1-ease(t,2.2,2.67))
    bend=max(crouch,landing)
    knee_front=mix((10,35),(25,25),bend);foot_front=mix((21,67),(33,51),bend)
    knee_back=mix((-12,36),(-29,27),bend);foot_back=mix((-24,71),(-35,54),bend)
    hand_front=mix((37,-23),(-44,-17),ease(t,.12,.5))
    hand_back=mix((-36,-18),(-49,-8),ease(t,.12,.5))
    hand_front=mix(hand_front,(34,-99),ease(t,.53,.76))
    hand_back=mix(hand_back,(-15,-108),ease(t,.53,.76))
    if .53<t<.6:
        launch=ease(t,.53,.6)
        foot_front=mix(foot_front,(19,81),launch);knee_front=mix(knee_front,(11,40.5),launch)
        foot_back=mix(foot_back,(-12,82),launch);knee_back=mix(knee_back,(-9.5,41),launch)
    if .6<=t<=HIT:
        # Extended takeoff -> straight pike -> opened heel strike.
        fold=ease(t,.83,1.12)*(1-ease(t,1.52,HIT))
        open_strike=ease(t,1.55,HIT)
        front=mix((19,81),(57,-65),fold)
        back=mix((-12,82),(36,-74),fold)
        front=mix(front,(35,74),open_strike)
        back=mix(back,(-6,79),open_strike)
        foot_front=front;foot_back=back
        # Exactly straight knees for the airborne pike, with a small stance offset.
        knee_front=((front[0]+3)*.5,front[1]*.5)
        knee_back=((back[0]-7)*.5,back[1]*.5)
        hand_front=mix(hand_front,(50,-63),fold)
        hand_back=mix(hand_back,(33,-77),fold)
        hand_front=mix(hand_front,(45,-28),open_strike)
        hand_back=mix(hand_back,(-45,-38),open_strike)
    if t>HIT:
        contact=ease(t,HIT,2.15)
        foot_front=mix((35,74),foot_front,contact)
        foot_back=mix((-6,79),foot_back,contact)
        knee_front=mix((19,37),knee_front,contact)
        knee_back=mix((-6,39.5),knee_back,contact)
        hand_front=mix((45,-28),(36,-18),ease(t,2.1,2.5))
        hand_back=mix((-45,-38),(-34,-22),ease(t,2.1,2.5))
    if t>=2.8:
        # Rest pose for the return hop, matching the beginning of the loop.
        foot_front=(21,67);foot_back=(-24,71);knee_front=(10,35);knee_back=(-12,36)
        hand_front=(37,-23);hand_back=(-36,-18);bend=0
    angle=math.tau*ease(t,.70,HIT)
    head=(-8-8*bend,-85+15*bend)
    return {'foot':foot_front,'backFoot':foot_back,'knee':knee_front,'backKnee':knee_back,
      'hand':hand_front,'backHand':hand_back,'head':head,'angle':angle,'bend':bend}

CONTACT_FOOT=rot(add(pose(HIT)['foot'],HEEL_OFFSET),pose(HIT)['angle'])
CONTACT_ROOT=(TARGET[0]-CONTACT_FOOT[0],TARGET[1]-CONTACT_FOOT[1])

def root_at(t):
    if t<.6:
        p=pose(t);sole=max(p['foot'][1]+9,p['backFoot'][1]+5)
        return(180-5*ease(t,.1,.5),396-sole)
    if t<=HIT:
        z=b.clamp((t-.6)/(HIT-.6));x=175+(CONTACT_ROOT[0]-175)*z**.98
        y=306+(CONTACT_ROOT[1]-306)*z-115*math.sin(math.pi*z)
        return(x,y)
    if t<2.2:return mix(CONTACT_ROOT,(725,334),ease(t,HIT,2.17))
    if t<2.8:return mix((725,334),(725,320),ease(t,2.2,2.67))
    if t<3.36:
        z=b.clamp((t-2.8)/.56);return(725+(180-725)*b.smooth(z),320-28*math.sin(math.pi*z))
    return ORIGIN

def foot_at(t):return add(root_at(t),rot(add(pose(t)['foot'],HEEL_OFFSET),pose(t)['angle']))

def actor(t):
    raw=b.rgba(384,384);p=pose(t);center=(192,192)
    def pt(q):return add(center,q)
    def limb(points,w=12,front=True):u.limb(raw,[pt(q) for q in points],w,front)
    def shape(points,color,outline=None,w=1.4):b.poly(raw,[pt(q) for q in points],color,outline,w)
    # Shadow creature from the previous demo, with a violet-accented athletic rig.
    b.path(raw,[('M',*pt((-10,9))),('C',*pt((-43,15)),*pt((-59,2)),*pt((-64,-20))),
      ('C',*pt((-75,14)),*pt((-44,37)),*pt((-6,25))),('Z',)],u.INK,u.LIGHT,1.4)
    limb([(-7,0),p['backKnee'],p['backFoot']],12,False)
    bx,by=p['backFoot'];shape([(bx-12,by-7),(bx+7,by-5),(bx+10,by+5),(bx-14,by+5)],u.INK,u.LIGHT)
    limb([(-17,-46),(-36,-35),p['backHand']],9,False)
    bend=p['bend'];shoulder=(-5-7*bend,-48+10*bend)
    b.path(raw,[('M',*pt((-24,shoulder[1]))),('L',*pt((8,shoulder[1]-4))),
      ('C',*pt((22,-30)),*pt((14,-12)),*pt((12,6))),('L',*pt((-14,8))),
      ('C',*pt((-16,-12)),*pt((-31,-25)),*pt((-24,shoulder[1]))),('Z',)],u.MID,u.EDGE,1.7)
    shape([(-18,shoulder[1]+7),(5,shoulder[1]+2),(10,-15),(-2,-8),(-16,-22)],u.LIGHT)
    shape([(-13,-1),(10,-2),(11,7),(-13,9)],(82,62,133,255),u.EDGE,1)
    u.beast_head(raw,pt(p['head']),'kick',t)
    # Leading legs are not bent into a tucked somersault.
    limb([(3,0),p['knee'],p['foot']],14)
    fx,fy=p['foot'];shape([(fx-10,fy-9),(fx+8,fy-8),(fx+12,fy+3),(fx+4,fy+9),(fx-13,fy+6)],u.MID,u.EDGE)
    b.line(raw,[pt((fx-8,fy+4)),pt((fx+7,fy+3))],LILAC,2)
    elbow=mix((24,-40),p['hand'],.53)
    limb([(8,shoulder[1]),elbow,p['hand']],9)
    hx,hy=p['hand'];b.ellipse(raw,(*pt((hx-5,hy-5)),*pt((hx+6,hy+5))),u.LIGHT,u.EDGE,1)
    # Place/rotate in a fixed hip-centred cell; no world travel is baked in.
    out=b.rgba(384,384)
    b.place(out,raw,(192,192),(192,192),1,-math.degrees(p['angle']))
    return out

def glow(im,gain=.7):
    sm=im.resize((im.width//4,im.height//4),Image.Resampling.LANCZOS)
    alpha=sm.getchannel('A').filter(ImageFilter.GaussianBlur(3*b.S))
    halo=Image.new('RGBA',sm.size,(123,75,235,0));halo.putalpha(alpha.point(lambda x:int(x*.33*gain)))
    halo=halo.resize(im.size,Image.Resampling.BILINEAR);halo.alpha_composite(im);return halo

def takeoff(t):
    im=b.rgba(256,256);cx,cy=128,128;fade=1-b.smooth(t)
    for k in range(3):
        r=16+58*t+k*9;b.arc(im,cx,cy,r,.15+k,3.05+k,(173,153,231,int(155*fade)),1.5,.28)
    for k in range(12):
        a=k*2.4;r=(19+k%4*7)*t;x=cx+math.cos(a)*r;y=cy-32*math.sin(a)**2*t+15*t*t
        b.line(im,[(x,y+4),(x+math.cos(a)*3,y)],(177,159,227,int(160*fade)),1.7)
    return glow(im,.4)

def trail(t):
    im=b.rgba(384,384);root=root_at(t);center=(192,192)
    points=[]
    for d in np.linspace(.18,0,16):
        f=foot_at(max(.6,t-d));points.append((center[0]+f[0]-root[0],center[1]+f[1]-root[1]))
    width=[.5+7*(i/15)**.85 for i in range(16)]
    v.ribbon(im,points,width,(114,58,212,170))
    v.ribbon(im,points,[w*.6 for w in width],(194,124,255,225))
    v.ribbon(im,points,[w*.2 for w in width],(244,221,255,250))
    # A short crescent follows the actual foot, leaving the torso silhouette clear.
    theta=pose(t)['angle'];a=theta+.4
    b.arc(im,192,192,91,a-.78,a+.38,(204,166,255,155),2.4,.9)
    for k in range(8):
        u=(t*3+k*.127)%1;d=.04+.2*u;f=foot_at(max(.6,t-d))
        x=192+f[0]-root[0]+math.sin(k*2.1)*10;y=192+f[1]-root[1]+math.cos(k*2.3)*8
        b.ellipse(im,(x-1.4,y-1.4,x+1.4,y+1.4),(224,191,255,int(170*(1-u))))
    return glow(im,.8)

RNG=random.Random(518)
SHARDS=[(RNG.uniform(-math.pi,0),RNG.uniform(70,170),RNG.uniform(2,5)) for _ in range(26)]

def impact(t):
    im=b.rgba(512,384);cx,cy=256,170;ground=cy+46
    expand=1-(1-b.clamp(t/.36))**3;fade=1-b.smooth((t-.2)/.78)
    flash=1-b.clamp(t/.095)
    if flash>0:
        b.sparkle(im,cx,cy,43*flash,(255,239,255,int(245*flash)),.13)
        b.line(im,[(cx,cy-22*flash),(cx,ground)],(229,183,255,int(180*flash)),3)
    # A broken moon-coloured shockwave expands over the battle floor.
    radius=20+177*expand
    for k in range(4):
        a=k*math.tau/4+.12
        b.arc(im,cx,ground,radius,a,a+1.25,(170,112,244,int(210*fade)),3.5*(1-t)+.8,.27)
        b.arc(im,cx,ground,radius*.88,a+.13,a+1.16,(230,190,255,int(180*fade)),1.8,.27)
    # Three upward sweeps give the heel strike a local vertical burst.
    for k in [-1,0,1]:
        rise=(75-abs(k)*12)*expand
        pts=[(cx+k*8,ground),(cx+k*30,ground-rise*.5),(cx+k*47,ground-rise)]
        v.ribbon(im,pts,[20*fade,10*fade,.5],(119,54,205,int(175*fade)))
        v.ribbon(im,pts,[8*fade,4*fade,.2],(207,149,255,int(220*fade)))
    # Temporary cracks are part of the effect, not a permanent change to the arena.
    if t>.04:
        alpha=int(160*b.smooth(t/.1)*fade)
        for k in range(7):
            sign=-1 if k%2 else 1;dx=sign*(25+k*12)*expand
            pts=[(cx+sign*8,ground+5),(cx+dx*.43,ground+8+k%3*4),(cx+dx*.65,ground+3+k%2*11),(cx+dx,ground+9)]
            b.line(im,pts,(125,90,170,alpha),1.5)
    for k,(a,dist,size) in enumerate(SHARDS):
        u=b.clamp(t/.95);r=dist*(1-(1-u)**2)
        x=cx+math.cos(a)*r;y=ground+math.sin(a)*r*.64+48*u*u
        alpha=int(210*(1-u)**.8*b.smooth(t/.07));s=size*(1-u*.55)
        b.poly(im,[(x-s,y),(x,y-s*1.7),(x+s,y-s*.3),(x+s*.2,y+s)],(169,123,232,alpha))
        if k%7==0:b.sparkle(im,x,y,s*1.5,(233,204,255,alpha),a)
    for k in range(6):
        u=b.clamp((t-.05)/.95);x=cx+math.sin(k*2.4)*(35+75*u);y=ground-10-20*u
        r=(9+k%3*4)*(1-u)
        if r>0:v.blob(im,x,y,r*1.5,r,t*4+k,(110,102,145,int(105*(1-u))),lobes=5)
    return glow(im,.7)

def sheet(frames,name,cols,anchor,logical):
    old=b.ASSETS;b.ASSETS=ASSETS
    s=b.make_sheet(frames,name,cols,anchor,30,False);b.ASSETS=old
    s['logicalWidth'],s['logicalHeight']=logical
    im=Image.open(ASSETS/f'{name}.png');im.resize((im.width//2,im.height//2),Image.Resampling.LANCZOS).save(ASSETS/f'{name}-low.png',optimize=True)
    s['lowImage']=f'assets/{name}-low.png';return s

def background():
    yy,xx=np.mgrid[0:540*b.S,0:960*b.S];xx=xx/b.S;yy=yy/b.S
    light=np.exp(-(((xx-480)/620)**2+((yy-270)/380)**2)*2)
    arr=np.zeros((540*b.S,960*b.S,4),dtype=np.uint8)
    for c,(base,gain) in enumerate([(9,8),(12,12),(22,22)]):arr[:,:,c]=(base+gain*light).astype(np.uint8)
    arr[:,:,3]=255;im=Image.fromarray(arr)
    b.text(im,(38,28),'CARPADO DO ECLIPSE',25,(245,239,250,255),True)
    b.text(im,(39,68),'Salto · mortal com pernas estendidas · golpe de calcanhar',12,(140,154,183,255))
    b.text(im,(922,37),'UMBRAL / ACROBÁTICO',10,(192,141,251,255),False,'ra')
    for x in range(45,950,34):
        for y in range(122,438,34):b.ellipse(im,(x,y,x+.7,y+.7),(76,83,114,65))
    b.line(im,[(40,396),(920,396)],(87,100,130,120),1)
    b.line(im,[(38,468),(922,468)],(57,66,93,180),1)
    return im

def main():
    print('Carpado: animating the pike rig',flush=True)
    actors=[b.native(actor(i/FPS)).resize((256,256),Image.Resampling.LANCZOS) for i in range(N)]
    trails=[b.native(trail((22+i)/FPS)).resize((256,256),Image.Resampling.LANCZOS) for i in range(40)]
    takeoffs=[b.native(takeoff(i/17)) for i in range(18)]
    impacts=[b.native(impact(i/35)).resize((384,288),Image.Resampling.LANCZOS) for i in range(36)]
    meta={'name':'Carpado do Eclipse','id':'umbral-pike-somersault','fps':30,'durationMs':4200,'hitFrame':59,'hitMs':HIT*1000,
      'origin':{'x':180,'y':320},'target':{'x':735,'y':350},'contactFoot':{'x':CONTACT_FOOT[0],'y':CONTACT_FOOT[1]},
      'actor':sheet(actors,'actor',8,(128,128),(384,384)),
      'trail':sheet(trails,'foot-trail',8,(128,128),(384,384)),
      'takeoff':sheet(takeoffs,'takeoff',6,(128,128),(256,256)),
      'impact':sheet(impacts,'impact',6,(192,127.5),(512,384)),
      'phases':json.loads((OUT/'vfx-spec.json').read_text())['phases'],'tracks':[]}
    for i in range(N):
        t=i/FPS;p=pose(t);r=root_at(t);f=foot_at(t)
        xfactor=(r[0]-ORIGIN[0])/(CONTACT_ROOT[0]-ORIGIN[0])
        yextra=r[1]-(ORIGIN[1]+(CONTACT_ROOT[1]-ORIGIN[1])*xfactor)
        meta['tracks'].append({'root':{'x':r[0],'y':r[1]},'xFactor':xfactor,'yExtra':yextra,
          'angle':p['angle'],'foot':{'x':f[0],'y':f[1]},'localFoot':p['foot'],'localKnee':p['knee']})
    (ASSETS/'attack.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2))
    print('Carpado: compositing layers',flush=True)
    a=[im.resize((384*b.S,384*b.S),Image.Resampling.LANCZOS) for im in actors]
    trail_s=[im.resize((384*b.S,384*b.S),Image.Resampling.LANCZOS) for im in trails]
    launch_s=[im.resize((256*b.S,256*b.S),Image.Resampling.LANCZOS) for im in takeoffs]
    hit_s=[im.resize((512*b.S,384*b.S),Image.Resampling.LANCZOS) for im in impacts]
    bg=background();frames=[];full_alpha=[];fx_alpha=[]
    for i in range(N):
        t=i/FPS;r=root_at(t);scene=bg.copy();attack=b.rgba(960,540);fx=b.rgba(960,540)
        # A changing ground shadow preserves height and landing readability.
        height=320-r[1];shadow_w=max(19,42-height*.07)
        b.ellipse(scene,(r[0]-shadow_w,390,r[0]+shadow_w,400),(30,36,59,max(30,int(125-height*.25))))
        react=0 if t<HIT else math.sin(math.pi*b.clamp((t-HIT)/.3))*15
        tx,ty=TARGET[0]+react,TARGET[1]-react*.2
        color=(190,142,232,150) if HIT<=t<HIT+.25 else (107,135,166,115)
        b.ellipse(scene,(tx-19,ty-19,tx+19,ty+19),None,color,1.2)
        b.line(scene,[(tx-5,ty),(tx+5,ty)],color,1);b.line(scene,[(tx,ty-5),(tx,ty+5)],color,1)
        b.text(scene,(TARGET[0],433),'ALVO',10,(139,154,184,255),True,'mm')
        if 22<=i<62:
            for lag,alpha in [(4,.11),(2,.24)]:
                j=max(0,i-lag);b.place(attack,b.opacity(a[j],alpha),root_at(j/FPS),(192,192))
            b.place(fx,trail_s[i-22],r,(192,192))
        if 18<=i<36:b.place(fx,launch_s[i-18],(175,396),(128,128),1)
        if HIT_FRAME<=i<HIT_FRAME+36:b.place(fx,hit_s[i-HIT_FRAME],TARGET,(256,170))
        attack.alpha_composite(fx)
        b.place(attack,a[i],r,(192,192))
        scene.alpha_composite(attack)
        phase=0 if t<.6 else 1 if t<HIT else 2 if t<2.8 else 3
        for k,(label,x) in enumerate([('01  IMPULSO',39),('02  CARPADO',274),('03  IMPACTO',509),('04  RETORNO',744)]):
            b.text(scene,(x,490),label,11,(216,164,255,255) if phase==k else (87,103,137,255),True)
            if phase==k:b.line(scene,[(x,469),(x+175,469)],(190,120,249,255),2)
        frames.append(b.native(scene).convert('RGB'));full_alpha.append(b.native(attack));fx_alpha.append(b.native(fx))
    print('Carpado: encoding animation',flush=True)
    u.encode(frames,OUT/'carpado-do-eclipse',768)
    for ims,name in [(full_alpha,'attack-transparent.webp'),(fx_alpha,'vfx-transparent.webp')]:
        ims[0].save(OUT/name,save_all=True,append_images=ims[1:],duration=[33,33,34]*42,loop=0,lossless=True)
    strip=Image.new('RGB',(960,540*3))
    for row,index in enumerate([30,40,59]):strip.paste(frames[index],(0,row*540))
    strip.resize((768,1296),Image.Resampling.LANCZOS).save(OUT/'contact-sheet.jpg',quality=94)
    frames[40].save(OUT/'pike-still.png');frames[62].save(OUT/'impact-still.png')
    print('Carpado ready',flush=True)

if __name__=='__main__':main()
