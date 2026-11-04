/* Review-only continuous sprite skinning. Original atlases are never rewritten.
 * Every emission socket is evaluated with exactly the same skin and root pose.
 */
const RigStudy = (() => {
 const specs = [
  {family:'ember',part:'mouth',label:'Boca',socket:[.94,.44],bones:[[-.15,.4],[.15,.05]],duration:1.45},
  {family:'ember',part:'tail',label:'Ponta da cauda',socket:[.18,.12],duration:1.75},
  {family:'ember',part:'fore',label:'Pata dianteira',socket:[.83,.91],duration:1.65},
  {family:'moss',part:'fore',label:'Braço de cipós',socket:[.65,.80],duration:1.70},
  {family:'moss',part:'root',label:'Raízes / apoio no chão',socket:[.88,.96],duration:1.90},
  {family:'moss',part:'crest',label:'Galhos da copa',socket:[.80,.13],duration:1.80},
  {family:'dew',part:'mouth',label:'Boca',socket:[.96,.52],duration:1.40},
  {family:'dew',part:'reservoir',label:'Reservatório dorsal',socket:[.41,.27],duration:1.85},
  {family:'dew',part:'hind',label:'Patas / nascente',socket:[.42,.94],duration:1.80},
  {family:'volt',part:'antenna',label:'Pontas das antenas',socket:[.90,.17],duration:1.30},
  {family:'volt',part:'shell',label:'Circuito da carapaça',socket:[.44,.39],duration:1.65},
  {family:'volt',part:'fore',label:'Patas dianteiras',socket:[.86,.88],duration:1.70},
  {family:'volt',part:'shell',label:'Carapaça / investida',socket:[.84,.54],duration:1.85},
  {family:'volt',part:'antenna',label:'Antenas / mergulho',socket:[.91,.17],duration:2.10},
  {family:'volt',part:'shell',label:'Carapaça / rotação',socket:[.47,.43],duration:2.00}
 ];
 const joints = {
  ember:{tail:[.48,.65,.20,.35,.32,.46],head:[.65,.56,.79,.40,.21,.26],fore:[.73,.64,.83,.84,.18,.24],hind:[.42,.69,.39,.87,.19,.20],crest:[.71,.38,.71,.22,.19,.22]},
  moss:{tail:[.40,.72,.19,.63,.21,.27],head:[.72,.49,.81,.43,.15,.18],fore:[.62,.65,.62,.85,.18,.21],hind:[.23,.71,.20,.89,.19,.19],crest:[.59,.44,.63,.16,.42,.27]},
  dew:{tail:[.38,.73,.18,.58,.23,.35],head:[.72,.59,.84,.49,.20,.22],fore:[.72,.73,.79,.90,.19,.17],hind:[.39,.75,.40,.91,.24,.16],crest:[.46,.58,.41,.29,.32,.34]},
  volt:{tail:[.36,.65,.15,.48,.22,.28],head:[.72,.62,.79,.59,.18,.20],fore:[.73,.71,.83,.87,.17,.21],hind:[.38,.72,.30,.87,.25,.20],crest:[.73,.47,.83,.17,.21,.33]}
 };
 function windowPulse(q,a,b,c){return smooth((q-a)/(b-a))*(1-smooth((q-b)/(c-b)))}
 function pose(index,q){
  const s=specs[index],on=q>=0&&q<1,p={x:121,y:267,rotation:0,sx:1,sy:1,head:0,tail:0,fore:0,hind:0,crest:0,bob:0,inflate:0};
  if(!on||reduced)return p;
  let wind=windowPulse(q,0,.26,.42),release=windowPulse(q,.25,.39,.60),recover=windowPulse(q,.61,.72,1),t=smooth((q-.29)/.35),back=smooth((q-.69)/.30);
  switch(index){
   case 0:p.head=-.24*wind+.25*release;p.bob=-5*wind;p.inflate=.09*wind;p.fore=.14*wind-.12*release;p.x-=8*release;p.tail=.12*wind;break;
   case 1:p.tail=-.67*wind+1.12*release-.18*recover;p.head=.18*wind-.18*release;p.hind=.27*wind-.15*release;p.fore=-.22*wind+.24*release;p.rotation=.11*wind-.18*release;p.x-=9*wind;p.bob=7*wind-5*release;break;
   case 2:p.fore=-.79*wind+.54*release;p.head=-.12*wind+.10*release;p.hind=.18*wind;p.bob=8*wind-9*release;p.tail=-.27*release;p.rotation=-.09*wind+.10*release;break;
   case 3:p.fore=-.68*wind+.77*release-.12*recover;p.crest=.14*wind-.18*release;p.head=-.1*wind+.12*release;p.hind=.18*release;p.rotation=.10*wind-.08*release;p.bob=4*wind;break;
   case 4:p.fore=-.28*wind+.42*release;p.hind=-.14*wind+.20*release;p.bob=-19*wind+13*release;p.crest=-.12*release;p.head=.14*release;p.inflate=-.05*release;break;
   case 5:p.crest=-.30*wind+.48*release-.10*recover;p.fore=.22*wind-.14*release;p.head=-.14*wind+.15*release;p.bob=5*wind-8*release;p.tail=-.16*release;break;
   case 6:p.head=-.29*wind+.26*release;p.crest=-.14*wind+.19*release;p.bob=-6*wind+3*release;p.inflate=.10*wind;p.x-=10*release;break;
   case 7:p.crest=-.32*wind+.42*release-.11*recover;p.tail=.32*wind-.40*release;p.head=.16*wind-.18*release;p.bob=6*wind;p.inflate=.16*wind-.08*release;p.rotation=.08*wind-.10*release;break;
   case 8:p.hind=-.40*wind+.55*release;p.fore=.24*wind-.43*release;p.tail=-.32*release;p.crest=.24*wind-.24*release;p.bob=18*wind-30*release;p.rotation=-.08*wind+.07*release;break;
   case 9:p.crest=-.27*wind+.38*release;p.head=-.13*wind+.16*release;p.fore=.19*wind-.23*release;p.bob=5*wind-4*release;p.inflate=.04*wind;break;
   case 10:p.crest=.20*wind-.18*release;p.head=.18*wind-.19*release;p.fore=-.22*wind+.22*release;p.hind=.18*wind-.18*release;p.bob=9*wind-6*release;p.inflate=.10*wind-.05*release;break;
   case 11:p.fore=-.67*wind+.70*release;p.hind=.24*wind-.18*release;p.crest=-.20*release;p.head=.14*release;p.bob=-10*wind+9*release;p.rotation=-.09*wind+.13*release;break;
   case 12:p.x+=326*t*(1-back);p.bob=12*wind-4*release;p.fore=-.43*wind+.40*release-.20*recover;p.hind=.40*wind-.42*release;p.crest=-.23*release;p.head=.12*release;p.rotation=-.11*release+.08*recover;break;
   case 13:{let jump=clamp((q-.23)/.43);p.x+=326*t*(1-back);p.y-=Math.sin(jump*Math.PI)*113;p.bob=15*wind;p.fore=.49*release-.23*recover;p.hind=-.57*release+.22*recover;p.crest=.28*release;p.head=.12*release;p.rotation=-.42*windowPulse(q,.25,.40,.55)+.25*windowPulse(q,.45,.61,.74);break;}
   case 14:p.x+=321*t*(1-back);p.y-=Math.sin(t*Math.PI)*44;p.rotation=-Math.PI*2*t+Math.PI*2*back;p.fore=-.63*release;p.hind=.64*release;p.crest=-.35*release;p.tail=.27*release;p.bob=8*wind;break;
  }
  return p;
 }
 function skin(uv,family,p){
  let u=uv[0],v=uv[1],dx=0,dy=0;
  for(const [name,b] of Object.entries(p.joints||joints[family])){
   let angle=p[name];if(!angle)continue;
   let [px,py,cx,cy,rx,ry]=b,d=((u-cx)/rx)**2+((v-cy)/ry)**2;
   let weight=Math.exp(-d*1.35);if(weight<.005)continue;
   let xx=u-px,yy=v-py;dx+=weight*(xx*Math.cos(angle)-yy*Math.sin(angle)-xx);dy+=weight*(xx*Math.sin(angle)+yy*Math.cos(angle)-yy);
  }
  if(p.inflate){let center=family==='dew'?[.40,.37]:family==='volt'?[.44,.46]:[.62,.61];let wt=Math.exp(-(((u-center[0])/.35)**2+((v-center[1])/.38)**2));dx+=(u-center[0])*p.inflate*wt;dy+=(v-center[1])*p.inflate*wt;}
  if(p.blink&&p.eye){let [ex,ey]=p.eye,weight=Math.exp(-(((u-ex)/.065)**2+((v-ey)/.055)**2)*1.7);dy+=(ey-v)*p.blink*.90*weight;}
  return [u+dx,v+dy];
 }
 function project(uv,id,family,p,size=152){let r=DATA.regions[id].rect,f=size/Math.max(r[2],r[3]),local=skin(uv,family,p),ground=p.ground||[.5,1],x=(local[0]-ground[0])*r[2]*f,y=(local[1]-ground[1])*r[3]*f+p.bob*Math.pow(clamp((ground[1]-uv[1])/ground[1]),.7);return [p.x+(x*Math.cos(p.rotation)-y*Math.sin(p.rotation))*p.sx,p.y+(x*Math.sin(p.rotation)+y*Math.cos(p.rotation))*p.sy]}
 function triangle(c,img,src,dst){
  let [a,b,d]=src,[A,B,D]=dst,den=a[0]*(b[1]-d[1])+b[0]*(d[1]-a[1])+d[0]*(a[1]-b[1]);if(Math.abs(den)<.001)return;
  const transform=axis=>[(A[axis]*(b[1]-d[1])+B[axis]*(d[1]-a[1])+D[axis]*(a[1]-b[1]))/den,(A[axis]*(d[0]-b[0])+B[axis]*(a[0]-d[0])+D[axis]*(b[0]-a[0]))/den,(A[axis]*(b[0]*d[1]-d[0]*b[1])+B[axis]*(d[0]*a[1]-a[0]*d[1])+D[axis]*(a[0]*b[1]-b[0]*a[1]))/den];
  let [aa,cc,ee]=transform(0),[bb,dd,ff]=transform(1);c.save();c.beginPath();let cx=(A[0]+B[0]+D[0])/3,cy=(A[1]+B[1]+D[1])/3;[A,B,D].forEach((p,i)=>{let dx=p[0]-cx,dy=p[1]-cy,len=Math.hypot(dx,dy)||1;let pt=[p[0]+dx/len*.32,p[1]+dy/len*.32];i?c.lineTo(...pt):c.moveTo(...pt)});c.closePath();c.clip();c.transform(aa,bb,cc,dd,ee,ff);c.drawImage(img,0,0);c.restore();
 }
 const textures=new Map();
 function texture(id){if(textures.has(id))return textures.get(id);let data=DATA.regions[id],r=data.rect,cv=document.createElement('canvas');cv.width=r[2];cv.height=r[3];cv.getContext('2d').drawImage(assets[data.atlas],...r,0,0,r[2],r[3]);textures.set(id,cv);return cv}
 function draw(c,index,q,id,ghost=false,options={}){let s=specs[index],p=options.pose||pose(index,q),img=texture(id),n=options.grid||14,size=options.size||152;let points=[];for(let j=0;j<=n;j++)for(let i=0;i<=n;i++)points.push(project([i/n,j/n],id,s.family,p,size));c.save();c.imageSmoothingEnabled=false;if(ghost)c.globalAlpha=.22;for(let j=0;j<n;j++)for(let i=0;i<n;i++){let a=j*(n+1)+i,b=a+1,d=a+n+1,e=d+1;let u=i/n*img.width,v=j/n*img.height,du=img.width/n,dv=img.height/n;triangle(c,img,[[u,v],[u+du,v],[u,v+dv]],[points[a],points[b],points[d]]);triangle(c,img,[[u+du,v],[u+du,v+dv],[u,v+dv]],[points[b],points[e],points[d]])}c.restore();return {p,socket:project(options.socket||s.socket,id,s.family,p,size),joint:uv=>project(uv,id,s.family,p,size)};}
 return {specs,pose,project,draw,windowPulse,joints};
})();
