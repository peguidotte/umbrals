"""Two original, animated fire spell variants. Uses render.py drawing helpers."""
from pathlib import Path
import os
import math, random, json, subprocess, zipfile, shutil
import numpy as np
from PIL import Image, ImageDraw
import render as b

ROOT = Path(os.environ.get("UMBRAL_ASSET_OUTPUT", str(Path(__file__).resolve().parents[2] / "builds/asset-work/vfx"))).resolve()
if ROOT.is_relative_to(Path(__file__).resolve().parents[2] / "assets"):
    raise ValueError("Author into staging, never into a versioned release")
ROOT.mkdir(parents=True, exist_ok=True)
FPS=30
TAU=math.tau
RED=(214,46,34,255)
ORANGE=(255,112,22,255)
GOLD=(255,201,57,255)
IVORY=(255,250,206,255)
WINE=(103,23,47,255)

def smooth_shape(pts):
    """Closed Catmull-Rom curve, expressed as cubic Bézier segments."""
    n=len(pts); cmds=[('M',*pts[0])]
    for i in range(n):
        p0,p1,p2,p3=[np.array(pts[j%n],dtype=float) for j in [i-1,i,i+1,i+2]]
        cmds.append(('C',*(p1+(p2-p0)/6),*(p2-(p3-p1)/6),*p2))
    return cmds+[('Z',)]

def blob(im,x,y,rx,ry,phase,color,outline=None,lobes=7,width=1.5):
    pts=[]
    for a in np.linspace(0,TAU,70,endpoint=False):
        r=1+.095*math.sin(a*lobes+phase)+.044*math.sin(a*(lobes+3)-phase*1.6)
        pts.append((x+math.cos(a)*rx*r,y+math.sin(a)*ry*r))
    b.path(im,smooth_shape(pts),color,outline,width)

def ribbon(im,points,widths,color,outline=None):
    pts=np.array(points); normals=[]
    for i,p in enumerate(pts):
        d=pts[min(i+1,len(pts)-1)]-pts[max(0,i-1)]
        d=d/max(.001,np.linalg.norm(d));normals.append(np.array([-d[1],d[0]]))
    left=[tuple(p+n*w) for p,n,w in zip(pts,normals,widths)]
    right=[tuple(p-n*w) for p,n,w in zip(pts,normals,widths)]
    b.path(im,smooth_shape(left+right[::-1]),color,outline,1.3)

def fire_stream(im,x,y,length,span,phase,angle=math.pi,colors=(RED,ORANGE,GOLD),alpha=1):
    pts=[]; widths=[]
    dx,dy=math.cos(angle),math.sin(angle);nx,ny=-dy,dx
    for i in range(9):
        u=i/8
        v=span*(math.sin(u*5.8-phase)*u*.55+math.sin(u*10.3-phase*1.7)*u*.18)
        pts.append((x+dx*length*u+nx*v,y+dy*length*u+ny*v))
        widths.append((1-u)**.9*(span*.45)*(1+.24*math.sin(u*8-phase)))
    def col(c): return (*c[:3],round(c[3]*alpha))
    ribbon(im,pts,widths,col(colors[0]),col(WINE))
    ribbon(im,pts,[w*.68 for w in widths],col(colors[1]))
    ribbon(im,pts[:-1],[w*.27 for w in widths[:-1]],col(colors[2]))

def curl(im,x,y,r,phase,color,width=3,angle=0,turns=.84):
    pts=[]
    for u in np.linspace(0,1,75):
        a=angle+u*TAU*turns
        rad=r*(1-.76*u)
        pts.append((x+math.cos(a)*rad,y+math.sin(a)*rad*.85))
    b.line(im,pts,color,width)

def hot_orb(im,cx,cy,r,ph,kind):
    blob(im,cx,cy,r*1.12,r,ph,RED,WINE,lobes=8,width=2)
    blob(im,cx+2,cy-2,r*.97,r*.83,ph+1.1,ORANGE,lobes=7)
    blob(im,cx+6,cy-4,r*.73,r*.66,-ph+.7,GOLD,lobes=5)
    if kind=='organic':
        curl(im,cx+5,cy-4,r*.49,ph,IVORY,5,ph*.28,.88)
        b.ellipse(im,(cx+2-r*.2,cy-5-r*.2,cx+2+r*.2,cy-5+r*.2),IVORY)
        curl(im,cx-8,cy+8,r*.76,ph,(239,84,20,255),4,ph*.28+1.2,.46)
    else:
        blob(im,cx+12,cy-3,r*.53,r*.43,ph,IVORY,lobes=4)
        b.arc(im,cx+1,cy,r*1.02,-1.25,-.3,(255,234,139,255),3)
        b.arc(im,cx,cy,r*.82,.45,1.9,(245,75,27,255),3)

def projectile(t,kind):
    im=b.rgba(640,384);cx,cy=454,192;ph=t*TAU
    if kind=='organic':
        # Five independent tongues continually fold back into the main flame.
        for k in [0,4,1,3,2]:
            off=(k-2)*15; length=205+(2-abs(k-2))*39
            x=cx-12-abs(k-2)*9;y=cy+off
            fire_stream(im,x,y,length,43-abs(k-2)*5,ph+k*1.7,
                        angle=math.pi+off*.0025,colors=(RED,ORANGE,GOLD))
        hot_orb(im,cx,cy,45+3*math.sin(ph),ph,'organic')
        b.path(im,[('M',cx-23,cy-18),('C',cx-59,cy-35,cx-100,cy-35-8*math.sin(ph),cx-128,cy-12),
          ('C',cx-96,cy-27,cx-68,cy-16,cx-48,cy-4)],None,(255,233,123,245),3)
    else:
        for k in [-2,2,-1,1,0]:
            fire_stream(im,cx-11,cy+k*9,302-abs(k)*37,38-abs(k)*4,ph+k*1.2,
              math.pi+k*.048,colors=((192,33,45,255),(251,87,19,255),(255,205,59,255)))
        # A bright, stretched core with an irregular flame front.
        ribbon(im,[(cx+19,cy),(cx-35,cy-3),(cx-89,cy+4*math.sin(ph)),(cx-150,cy-6*math.cos(ph)),(cx-230,cy)],
          [18,16,12,6,.3],IVORY)
        hot_orb(im,cx,cy,39+2*math.sin(ph),ph,'comet')
        for k in range(2):
            a=-1.6+k*2.4+math.sin(ph)*.07
            b.arc(im,cx+17,cy,62+k*9,a,a+.87,(255,220,112,170-k*30),2-k*.3,.92)
        for k in range(7):
            u=(t+k*.153)%1;x=cx-76-u*294;y=cy+math.sin(k*3.1)*73
            b.line(im,[(x,y),(x-24-u*18,y)],(255,185,76,int(160*(1-u))),1.1)
    # Advected embers use a periodic birth/death cycle, avoiding a sprite-loop pop.
    for k in range(25 if kind=='comet' else 20):
        u=(t+k*.0837)%1;x=cx-36-u*337;y=cy+math.sin(k*2.73)*(28+u*45)+math.sin(ph+k)*7*u
        alpha=int(225*math.sin(math.pi*u)**.6)
        rr=(1.3+k%4*.45)*(1-u*.55)
        b.ellipse(im,(x-rr*2,y-rr*.5,x+rr*2,y+rr*.5),(255,155+k%3*31,44,alpha))
        if k%7==0:b.sparkle(im,x,y,rr*2,(255,235,151,alpha),ph)
    return b.glow(im,.9 if kind=='organic' else 1.05)

def charge(t,kind):
    im=b.rgba(384,384);cx=cy=192;ph=t*TAU
    grow=b.smooth(t/.77);compress=1-.17*b.smooth((t-.82)/.18)
    r=(3+31*grow)*compress
    # The orbit contracts into the core while the core keeps circulating.
    for k in range(4):
        a=ph*1.03+k*TAU/4;rad=84-37*b.smooth(t)
        x=cx+math.cos(a)*rad;y=cy+math.sin(a)*rad*.75
        fire_stream(im,x,y,27+grow*18,12+grow*6,ph+k,
          a+math.pi/2,colors=(RED,ORANGE,GOLD),alpha=math.sin(math.pi*t)**.45)
    for k in range(20):
        u=(t*1.1+k*.049)%1;aa=k*2.399+t*1.4
        rr=105*(1-u)+7;x=cx+math.cos(aa)*rr;y=cy+math.sin(aa)*rr*.83
        a=int(210*math.sin(math.pi*u)*grow)
        b.line(im,[(x+math.cos(aa)*6,y+math.sin(aa)*5),(x,y)],(255,174,56,a),1.4)
    if r>3: hot_orb(im,cx,cy,r,ph,kind)
    if kind=='comet' and t>.6:
        alpha=int(170*b.smooth((t-.6)/.4))
        for k in range(4):
            a=k*TAU/4+.2
            b.line(im,[(cx+math.cos(a)*r*1.35,cy+math.sin(a)*r*1.35),(cx+math.cos(a)*r*2.2,cy+math.sin(a)*r*2.2)],(255,220,125,alpha),1.3)
    return b.glow(im,.83)

RNG=random.Random(482)
DEBRIS=[(RNG.uniform(-math.pi,math.pi),RNG.uniform(75,230),RNG.uniform(1.1,3.7),RNG.random()) for _ in range(58)]

def debris(im,t,cx,cy,kind):
    u=b.clamp(t/.96);birth=b.smooth(t/.05)
    for k,(a,dist,size,delay) in enumerate(DEBRIS):
        progress=1-(1-u)**3
        x=cx+math.cos(a)*dist*progress+(32 if kind=='comet' else 7)*progress
        y=cy+math.sin(a)*dist*.79*progress+42*u*u
        alpha=int(255*(1-u)**.75*birth)
        r=size*(1-u*.35)
        if k%9==0:b.sparkle(im,x,y,r*2,(255,228,135,alpha),a)
        else:
            tx=math.cos(a)*(9*(1-u)+2);ty=math.sin(a)*(9*(1-u)+2)
            b.line(im,[(x-tx,y-ty),(x,y)],(255,147+k%3*35,46,alpha),max(.8,r*.7))

def impact_organic(t):
    im=b.rgba(640,640);cx=cy=320
    expand=1-(1-b.clamp(t/.32))**3;fade=1-b.smooth((t-.35)/.63)
    debris(im,t,cx,cy,'organic')
    if t<.7:
        r=25+173*(1-(1-t/.7)**3);alpha=int(170*(1-t/.7))
        for k in range(3):b.arc(im,cx,cy+36,r,k*TAU/3+.3,k*TAU/3+1.6,(255,167,56,alpha),2,.42)
    flames=b.rgba(640,640)
    for k in range(8):
        a=k*TAU/8+.12
        r=(70+17*math.sin(k*3.1))*expand
        # The tips inherit the explosion's velocity before they curl and rise.
        base=(cx+math.cos(a)*r*.28,cy+math.sin(a)*r*.28)
        pts=[];widths=[]
        for j in range(7):
            u=j/6
            angle=a+u*u*(.7+math.sin(k)*.2)+t*.8
            dist=r*u*1.45
            pts.append((base[0]+math.cos(angle)*dist,base[1]+math.sin(angle)*dist-28*t*u))
            widths.append((28+6*math.sin(k))*expand*fade*(1-u)**.7+.1)
        ribbon(flames,pts,widths,RED,WINE)
        ribbon(flames,pts,[w*.72 for w in widths],ORANGE)
        ribbon(flames,pts[:-1],[w*.35 for w in widths[:-1]],GOLD)
    r=(8+62*expand)*fade
    if r>1:
        blob(flames,cx,cy,r,r*.93,t*19,ORANGE,WINE,lobes=7)
        blob(flames,cx+6,cy-5,r*.76,r*.65,-t*15,GOLD,lobes=5)
        curl(flames,cx,cy-4,r*.58,t,IVORY,max(1.5,r*.12),t*6,.86)
        b.ellipse(flames,(cx-r*.2,cy-4-r*.2,cx+r*.2,cy-4+r*.2),IVORY)
    im.alpha_composite(b.opacity(flames,fade**.45))
    # Small pockets of residual fire lift away, leaving the destination visible.
    for k in range(6):
        u=b.clamp((t-.25-k*.032)/.66)
        alpha=math.sin(math.pi*u)**1.2
        x=cx+(k-2.5)*29+math.sin(u*6+k)*13
        y=cy+42-140*u
        fire_stream(im,x,y,28+u*32,16*(1-u)+5,u*7+k,-math.pi/2,
          colors=(RED,ORANGE,GOLD),alpha=alpha*.82)
    flash=1-b.clamp(t/.09)
    if flash>0:
        b.sparkle(im,cx,cy,72*flash,(255,253,225,int(255*flash)),.2)
    return b.glow(im,.8)

def puff(im,x,y,r,ph,alpha,hot):
    if hot:
        shadow=(157,33,41,alpha);red=(225,64,25,alpha);orange=(255,136,23,alpha);light=(255,211,76,alpha)
    else:
        shadow=(39,33,43,alpha);red=(67,45,48,alpha);orange=(95,56,48,alpha);light=(127,67,43,alpha)
    blob(im,x,y,r,r*.91,ph,red,shadow,lobes=6,width=1.8)
    blob(im,x-r*.1,y-r*.14,r*.81,r*.67,ph+1.1,orange,lobes=5)
    blob(im,x-r*.16,y-r*.23,r*.49,r*.35,ph+.3,light,lobes=4)

def impact_comet(t):
    im=b.rgba(640,640);cx=cy=320
    expand=1-(1-b.clamp(t/.22))**3
    firefade=1-b.smooth((t-.2)/.51)
    debris(im,t,cx,cy,'comet')
    if t<.72:
        rr=15+230*(1-(1-t/.72)**3);alpha=int(210*(1-t/.72)**1.2)
        for k in range(4):b.arc(im,cx,cy+49,rr,.15+k*TAU/4,1.27+k*TAU/4,(255,183,64,alpha),max(.7,4*(1-t/.72)),.31)
        for k in range(3):b.arc(im,cx+14,cy,rr*.8,k*TAU/3+.4,k*TAU/3+1.25,(255,170,51,alpha//2),1.6,.85)
    # Billowing soot remains briefly behind the hot orange masses.
    for k in range(9):
        a=k*TAU/9+.1
        rr=(47+16*math.sin(k*3.1))*expand
        x=cx+math.cos(a)*rr*(1+t*.75)+18*t
        y=cy+math.sin(a)*rr*.78-61*t
        r=(29+10*math.cos(k*1.7))*(.4+.6*expand)*(1+t*.34)
        alpha=int(180*b.smooth((t-.15)/.22)*(1-b.smooth((t-.58)/.42)))
        if alpha>0:puff(im,x,y,r,t*5+k,alpha,False)
    # Back-to-front order and unequal puff radii break up the radial symmetry.
    flames=b.rgba(640,640)
    for k in [0,4,8,2,6,1,5,9,3,7]:
        a=k*TAU/10+.12
        rr=(54+17*math.sin(k*2.1))*expand
        x=cx+math.cos(a)*rr*(1+t*.5)+17*expand
        y=cy+math.sin(a)*rr*.76-23*t
        r=(39+10*math.cos(k*1.9))*expand*firefade
        if r>1:puff(flames,x,y,r,t*11+k,int(255*firefade**.4),True)
    for k in [0,2,1,3]:
        a=-.55+k*.93
        fire_stream(flames,cx+math.cos(a)*28,cy+math.sin(a)*28,
          (94+18*math.sin(k))*expand*firefade,30*expand*firefade,t*13+k,a,
          colors=(RED,ORANGE,GOLD),alpha=firefade)
    r=(13+51*expand)*firefade
    if r>1:
        blob(flames,cx+6,cy-3,r,r*.86,t*14,GOLD,lobes=7)
        blob(flames,cx+15,cy-9,r*.7,r*.54,t*16,IVORY,lobes=5)
    im.alpha_composite(flames)
    # A directional contact slash links the incoming comet to the explosion.
    flash=1-b.clamp(t/.105)
    if flash>0:
        b.sparkle(im,cx+9,cy,111*flash,(255,255,229,int(255*flash)),.06)
        ribbon(im,[(cx-81*flash,cy),(cx,cy),(cx+151*flash,cy-2)], [1,12*flash,.5],(255,246,180,int(255*flash)))
    return b.glow(im,1)

VARIANTS=[
 {'folder':'v2-chama-viva','kind':'organic','title':'CHAMA VIVA','subtitle':'Chamas orgânicas · núcleo em rotação · impacto em espiral','tag':'02 / FOGO',
  'chargeCount':24,'flightCount':28,'impactCount':42,'pauseCount':14,'flightScale':.84,'curve':55},
 {'folder':'v3-cometa-igneo','kind':'comet','title':'COMETA ÍGNEO','subtitle':'Disparo veloz · núcleo incandescente · explosão com volume','tag':'03 / FOGO',
  'chargeCount':24,'flightCount':20,'impactCount':48,'pauseCount':16,'flightScale':.91,'curve':24}
]

def background(v):
    im=b.background()
    # Replace only the header region, retaining the same review backdrop.
    # Generate its pixels directly so the title from v1 never bleeds through.
    yy,xx=np.mgrid[0:b.H*b.S,0:b.W*b.S];xx=xx/b.S;yy=yy/b.S
    vign=np.exp(-(((xx-b.W*.5)/(b.W*.7))**2+((yy-b.H*.42)/(b.H*.65))**2)*2)
    arr=np.zeros((b.H*b.S,b.W*b.S,4),dtype=np.uint8)
    for c,(base,gain) in enumerate([(9,10),(12,13),(22,19)]):arr[:,:,c]=(base+gain*vign).astype(np.uint8)
    arr[:,:,3]=255
    pure=Image.fromarray(arr)
    im.paste(pure.crop((0,0,b.W*b.S,108*b.S)),(0,0))
    b.text(im,(42,33),v['title'],25,(242,241,235,255),True)
    b.text(im,(43,72),v['subtitle'],13,(125,141,171,255))
    b.text(im,(918,40),v['tag'],11,(235,131,65,255),False,'ra')
    return im

def moving_position(v,u):
    progress=u**(.94 if v['kind']=='organic' else 1.22)
    dx=b.TARGET[0]-b.ORIGIN[0];dy=b.TARGET[1]-b.ORIGIN[1]
    x=b.ORIGIN[0]+dx*progress;y=b.ORIGIN[1]+dy*progress-v['curve']*math.sin(math.pi*progress)
    slope=(dy-v['curve']*math.pi*math.cos(math.pi*progress))/dx
    return (x,y),-math.degrees(math.atan(slope))

def write_variant(v):
    out=ROOT/v['folder'];assets=out/'assets';assets.mkdir(parents=True,exist_ok=True)
    kind=v['kind'];nc,nf,ni=v['chargeCount'],v['flightCount'],v['impactCount'];total=nc+nf+ni+v['pauseCount']
    print(v['title']+': drawing sprites',flush=True)
    charges=[b.native(charge(i/(nc-1),kind)) for i in range(nc)]
    projectiles=[b.native(projectile(i/32,kind)) for i in range(32)]
    impacts=[b.native((impact_organic if kind=='organic' else impact_comet)(i/(ni-1))) for i in range(ni)]
    oldassets=b.ASSETS;b.ASSETS=assets
    metadata={'name':v['title'],'version':2 if kind=='organic' else 3,'direction':'right','durationMs':total/FPS*1000,
      'timing':{'chargeMs':nc/FPS*1000,'flightMs':nf/FPS*1000,'impactMs':ni/FPS*1000,'pauseMs':v['pauseCount']/FPS*1000},
      'preview':{'chargeScale':.94,'projectileScale':v['flightScale'],'impactScale':.88 if kind=='organic' else 1,'curve':v['curve'],'progressExponent':.94 if kind=='organic' else 1.22},
      'charge':b.make_sheet(charges,'charge',6,(192,192),FPS),
      'projectile':b.make_sheet(projectiles,'projectile',8,(454,192),FPS,True),
      'impact':b.make_sheet(impacts,'impact',8,(320,320),FPS)}
    b.ASSETS=oldassets
    (assets/'fireball.json').write_text(json.dumps(metadata,ensure_ascii=False,indent=2))
    bg=background(v);frames=[];transparent=[]
    sprites={name:[im.resize((im.width*b.S,im.height*b.S),Image.Resampling.LANCZOS) for im in ims]
      for name,ims in [('charge',charges),('projectile',projectiles),('impact',impacts)]}
    print(v['title']+': compositing',flush=True)
    for i in range(total):
        fx=b.rgba(b.W,b.H);scene=bg.copy()
        if i<nc:
            stage=0
            # Slight upward anticipation keeps momentum continuous into launch.
            lift=-4*b.smooth((i/nc-.55)/.45)
            b.place(fx,sprites['charge'][i],(b.ORIGIN[0],b.ORIGIN[1]+lift),(192,192),.94)
        elif i<nc+nf:
            stage=1;u=(i-nc)/nf;pos,angle=moving_position(v,u)
            b.place(fx,sprites['projectile'][(i-nc)%32],pos,(454,192),v['flightScale']*(.87+.13*b.smooth(u*3)),angle)
        elif i<nc+nf+ni:
            stage=2;hit=i-nc-nf
            # The last travelling flame dissolves through contact instead of vanishing.
            if hit<5:
                pos,angle=moving_position(v,1)
                trail=b.opacity(sprites['projectile'][(nf+hit)%32],(1-hit/5)**2*.66)
                b.place(fx,trail,pos,(454,192),v['flightScale'],angle)
            b.place(fx,sprites['impact'][hit],b.TARGET,(320,320),.88 if kind=='organic' else 1)
        else:stage=-1
        scene.alpha_composite(fx)
        for k,(label,x) in enumerate([('01  CONCENTRAÇÃO',43),('02  DISPARO',350),('03  IMPACTO',650)]):
            b.text(scene,(x,486),label,11,(255,186,95,255) if stage==k else (84,99,128,255),True)
            if stage==k:b.line(scene,[(x,462),(x+220,462)],(255,155,48,255),2)
        frames.append(b.native(scene).convert('RGB'));transparent.append(b.native(fx))
    print(v['title']+': encoding',flush=True)
    transparent[0].save(out/'fireball-transparent.webp',save_all=True,append_images=transparent[1:],duration=[33,33,34]*(total//3)+[33]*(total%3),loop=0,lossless=True)
    p=subprocess.Popen(['ffmpeg','-y','-v','error','-f','rawvideo','-pix_fmt','rgb24','-s','960x540','-r','30','-i','pipe:0','-c:v','libx264','-crf','17','-pix_fmt','yuv420p','-movflags','+faststart',str(out/'fireball-preview.mp4')],stdin=subprocess.PIPE)
    for im in frames:p.stdin.write(im.tobytes())
    p.stdin.close()
    if p.wait()!=0:raise RuntimeError('Encoding failed')
    subprocess.run(['ffmpeg','-y','-v','error','-i',str(out/'fireball-preview.mp4'),'-filter_complex',
      'fps=24,scale=768:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=224:stats_mode=diff[p];[s1][p]paletteuse=dither=bayer:bayer_scale=4',
      '-loop','0',str(out/'fireball-preview.gif')],check=True)
    strip=Image.new('RGB',(960,540*3))
    for j,idx in enumerate([nc-3,nc+nf//2,nc+nf+int(ni*.22)]):strip.paste(frames[idx],(0,540*j))
    strip.resize((768,1296),Image.Resampling.LANCZOS).save(out/'contact-sheet.jpg',quality=94)
    frames[nc+nf//2].save(out/'projectile-still.png');frames[nc+nf+int(ni*.22)].save(out/'impact-still.png')
    readme=f'''# {v['title']} — bola de fogo, versão {metadata['version']}

{v['subtitle']}.

Animação original em 2D, baseada em princípios de animação de efeitos de fogo.
Prévia: GIF 768 × 432 e MP4 960 × 540, 30 fps, {total/FPS:.2f} s.

`assets/charge.png`, `assets/projectile.png` e `assets/impact.png` são sprites
com transparência real. Cada célula mantém o mesmo ponto de ancoragem.
As dimensões, a grade e os tempos estão em `assets/fireball.json`.
Os WebPs de cada fase e a animação completa também possuem canal alfa.

A concentração é reproduzida na origem; o projétil pode ser movido e girado
em qualquer trajetória; o impacto é reproduzido na chegada. O fundo e os
marcadores aparecem somente na prévia, não nos sprites.

Abra `index.html` para arrastar origem e alvo. Se precisar, execute
`python -m http.server 8080` na pasta e abra http://localhost:8080.

Referências e decisões visuais: `REFERENCIAS.md`.
'''
    (out/'README.md').write_text(readme)
    shutil.copyfile(ROOT/'REFERENCIAS.md',out/'REFERENCIAS.md')
    print(v['title']+': ready',flush=True)

if __name__=='__main__':
    for v in VARIANTS:write_variant(v)
