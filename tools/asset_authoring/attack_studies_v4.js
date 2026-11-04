/* Illustrated elemental assets and restrained, articulated performances.
 * Source PNG is preserved in attacks/woodland-elements@1.0.0.
 * Effects use local deformation, never gameplay randomness or simulation time.
 */
const ElementArt = (() => {
 const tiles = new Map();
 function tile(n) {
  if (tiles.has(n)) return tiles.get(n);
  const img=assets.vfxAtlas, x=Math.round(n%4*img.width/4), y=Math.round(Math.floor(n/4)*img.height/4);
  const w=Math.round((n%4+1)*img.width/4)-x, h=Math.round((Math.floor(n/4)+1)*img.height/4)-y;
  const cv=document.createElement('canvas');cv.width=w;cv.height=h;
  const ctx=cv.getContext('2d');ctx.drawImage(img,x,y,w,h,0,0,w,h);
  // Transparent source padding must not make a water ribbon or bolt needle-thin.
  const pixels=ctx.getImageData(0,0,w,h).data;let l=w,t=h,r=0,b=0;
  for(let yy=0;yy<h;yy++)for(let xx=0;xx<w;xx++)if(pixels[(yy*w+xx)*4+3]>16){l=Math.min(l,xx);t=Math.min(t,yy);r=Math.max(r,xx);b=Math.max(b,yy);}
  const trimmed=document.createElement('canvas');trimmed.width=r-l+1;trimmed.height=b-t+1;
  trimmed.getContext('2d').drawImage(cv,l,t,trimmed.width,trimmed.height,0,0,trimmed.width,trimmed.height);
  tiles.set(n,trimmed);return trimmed;
 }
 function draw(c,n,x,y,w,h,angle=0,alpha=1,phase=0) {
  if(alpha<=0||w<=0||h<=0)return;
  const img=tile(n);c.save();c.translate(x,y);c.rotate(angle);c.globalAlpha*=alpha;c.imageSmoothingEnabled=false;
  // Coherent travelling displacement inside the silhouette; no frame-to-frame noise.
  const strips=20, amp=n<4?2.2:n<8?.6:n<12?2.4:1.1;
  for(let k=0;k<strips;k++){
   const sw=img.width/strips, u=k/(strips-1), sway=Math.sin(u*9-phase*tau)*Math.sin(u*Math.PI)*amp;
   c.drawImage(img,k*sw,0,sw,img.height,-w/2+k*w/strips,-h/2+sway,w/strips+.25,h);
  }
  c.restore();
 }
 function strand(c,n,points,width,phase,alpha=1) {
  // Shared ribbon vertices prevent open seams on the outside of a bend.
  const img=tile(n), count=points.length-1;c.save();c.globalAlpha*=alpha;c.imageSmoothingEnabled=false;
  const edges=points.map((p,k)=>{const a=points[Math.max(0,k-1)],b=points[Math.min(count,k+1)],dx=b[0]-a[0],dy=b[1]-a[1],len=Math.hypot(dx,dy)||1;
   return [[p[0]-dy/len*width/2,p[1]+dx/len*width/2],[p[0]+dy/len*width/2,p[1]-dx/len*width/2]];});
  function tri(src,dst){const [a,b,d]=src,[A,B,D]=dst,den=a[0]*(b[1]-d[1])+b[0]*(d[1]-a[1])+d[0]*(a[1]-b[1]);if(Math.abs(den)<.001)return;
   const tr=j=>[(A[j]*(b[1]-d[1])+B[j]*(d[1]-a[1])+D[j]*(a[1]-b[1]))/den,(A[j]*(d[0]-b[0])+B[j]*(a[0]-d[0])+D[j]*(b[0]-a[0]))/den,(A[j]*(b[0]*d[1]-d[0]*b[1])+B[j]*(d[0]*a[1]-a[0]*d[1])+D[j]*(a[0]*b[1]-b[0]*a[1]))/den];
   const [aa,cc,ee]=tr(0),[bb,dd,ff]=tr(1),cx=(A[0]+B[0]+D[0])/3,cy=(A[1]+B[1]+D[1])/3;
   c.save();c.beginPath();dst.forEach((p,k)=>{const dx=p[0]-cx,dy=p[1]-cy,l=Math.hypot(dx,dy)||1,pt=[p[0]+dx/l*.45,p[1]+dy/l*.45];k?c.lineTo(...pt):c.moveTo(...pt);});c.closePath();c.clip();c.transform(aa,bb,cc,dd,ee,ff);c.drawImage(img,0,0);c.restore();
  }
  for(let k=0;k<count;k++){const x=k/count*img.width,xx=(k+1)/count*img.width;
   tri([[x,0],[xx,0],[x,img.height]],[edges[k][0],edges[k+1][0],edges[k][1]]);
   tri([[xx,0],[xx,img.height],[x,img.height]],[edges[k+1][0],edges[k+1][1],edges[k][1]]);}
  c.restore();
 }
 return {draw,strand};
})();

// Preserve appendage volume; weight transfer and follow-through carry the big gesture.
const priorAttack=Anatomy.attack, priorStatePose=Anatomy.statePose;
function refinePose(p,index,q,id) {
 if(reduced)return p;
 const wind=RigStudy.windowPulse(q,0,.24,.38), snap=RigStudy.windowPulse(q,.29,.39,.55);
 for(const key of ['head','tail','fore','hind','crest','ear','jaw'])p[key]=Math.tanh((p[key]||0)/.65)*.65;
 if(index===1){p.tail=-.44*wind+.54*snap;p.x-=7*wind;p.rotation=.12*wind-.13*snap;p.head=.13*wind-.18*snap;p.bob+=5*wind-4*snap;}
 // Lower appendages get narrower influence, protecting torso and neighbouring feet.
 p.joints={...p.joints};for(const key of ['fore','hind']){let b=p.joints[key];if(b)p.joints[key]=[...b.slice(0,4),b[4]*.80,b[5]*.91];}
 const family=Anatomy.forms[id].family, flutter=Math.sin(q*15)*RigStudy.windowPulse(q,.33,.52,.98);
 if(family==='volt'){
  p.joints.wing=[.58,.50,.40,.32,.24,.18];p.wing=-.13*wind+.24*snap+.06*flutter;
  p.joints.feeler=[.76,.39,...Anatomy.forms[id].antenna,.12,.22];p.feeler=.12*wind-.17*snap+.07*flutter;
 }
 if(family==='moss'){p.joints.bough=[.43,.48,.31,.25,.19,.23];p.bough=.09*wind-.15*snap+.04*flutter;}
 if(family==='dew'){p.joints.fin=[.59,.57,.57,.75,.15,.23];p.fin=-.11*wind+.19*snap+.06*flutter;}
 return p;
}
Anatomy.attack=(index,q,id,t)=>refinePose(priorAttack(index,q,id,t),index,q,id);
Anatomy.statePose=(id,state,t)=>{
 if(state===2)return Anatomy.attack({ember:1,moss:3,dew:7,volt:9}[Anatomy.forms[id].family],(t-.30)/2.45,id,t);
 return refinePose(priorStatePose(id,state,t),-1,(t-.30)/2.45,id);
};
// Anatomy.draw's closure used the old pose factory; provide the refined pose explicitly.
const priorDraw=Anatomy.draw;
Anatomy.draw=(c,index,q,id,t,options={})=>priorDraw(c,index,q,id,t,{...options,pose:options.pose||Anatomy.attack(index,q,id,t)});

const oldSource=screenSource;
screenSource=function(c,rig,index,q){
 if(reduced||q<0||q>=1)return;
 const [x,y]=rig.socket, charge=RigStudy.windowPulse(q,0,.28,.38), release=RigStudy.windowPulse(q,.32,.38,.50),gi=Math.floor(index/3);
 // Antenna bridge and ground cracks still communicate the mechanical origin.
 if([4,9,10,11,12,13,14].includes(index))oldSource(c,rig,index,q);
 const art=[0,1,2,6,5,6,8,9,10,12,13,13,14,12,13][index];
 if(charge>.01)ElementArt.draw(c,art,x,y,12+25*charge,12+25*charge,index===1?-.6:0,.85*charge,q*2);
 if(release>.01)ElementArt.draw(c,[3,7,11,15,15][gi],x,y,22+24*release,22+24*release,0,release*.65,q*3);
};

material=function(c,index,from,to,u,hit,q,rig){
 const [sx,sy]=from,[tx,ty]=to,travel=q>=.35&&q<.66,impact=q>=.66&&q<1;
 const arc=[0,68,42,0,0,26,0,34,0,0,0,0,0,0,0][index];
 const point=f=>[mix(sx,tx,f),mix(sy,ty,f)-Math.sin(f*Math.PI)*arc];
 const p=point(u),angle=Math.atan2(ty-sy-arc*Math.PI*Math.cos(u*Math.PI),tx-sx),phase=q*4;
 if(travel){
  switch(index){
   case 0:case 1:case 2:case 6:{
    const art=[0,1,2,0,0,0,8][index],sizes=index===0?[105,48]:index===1?[74,90]:index===2?[61,61]:[90,38];
    for(let k=3;k>0;k--){const f=Math.max(0,u-k*.055),a=point(f);ElementArt.draw(c,art,...a,sizes[0]*(1-k*.13),sizes[1]*(1-k*.13),angle,.12*(4-k),phase-k*.18);}
    ElementArt.draw(c,art,...p,...sizes,index===2?phase*.7:angle,1,phase);break;
   }
   case 3:{const end=[mix(sx,tx+14,smooth(u)),mix(sy,ty+32,u)],pts=Array.from({length:31},(_,k)=>{let t=k/30;return[mix(sx,end[0],t),mix(sy,end[1],t)+Math.sin(t*8-q*12)*22*t]});ElementArt.strand(c,4,pts,43,phase);break;}
   case 4:for(let k=0;k<8;k++){let f=k/7,z=smooth((u-f*.76)/.24);if(z>0)ElementArt.draw(c,5,mix(sx,tx,f),277-(28+f*13)*z,45+f*16,(56+f*26)*z,0,1,phase+k*.1);}break;
   case 5:for(let k=0;k<5;k++){const f=clamp(u-k*.032),a=point(f);ElementArt.draw(c,6,a[0]-k*4,a[1]+(k-2)*(8+u*9),57,29,(k-2)*.07,1,phase+k*.3);}break;
   case 7:{const pts=Array.from({length:35},(_,k)=>{let t=k/34;return[mix(sx,p[0],t),mix(sy,p[1],t)+Math.sin(t*8-q*13)*20*Math.sin(t*Math.PI)]});ElementArt.strand(c,9,pts,53,phase);ElementArt.draw(c,8,...p,48,31,angle,1,phase);break;}
   case 8:ElementArt.draw(c,10,mix(sx,tx,u),242,116,82,0,1,phase);for(let k=1;k<3;k++)ring(c,mix(sx,tx,u)-k*26,279,22,'#85d9eb',.35,.16);break;
   case 9:{let a=rig.secondary||rig.socket;for(const start of [a,rig.socket]){const pts=quadPath(start,to,start===a?12:-12,18);ElementArt.strand(c,12,pts,23,phase);}break;}
   case 10:for(let k=2;k>=0;k--){let f=clamp(u-k*.08),a=point(f);ElementArt.draw(c,13,...a,39+k*4,67+k*5,phase*.5,.8-k*.2,phase);}break;
   case 11:ElementArt.draw(c,13,...p,60+u*29,35+u*37,phase*.6,1,phase);break;
   case 12:{let a=rig.socket;ElementArt.draw(c,14,a[0]+50,a[1],81,98,0,1,phase);ElementArt.draw(c,12,a[0]-45,a[1]+18,115,33,0,.75,phase);break;}
   case 13:{let a=rig.socket;ElementArt.draw(c,14,a[0]+16,a[1]+9,73,96,1.0,1,phase);break;}
   case 14:{let a=rig.joint([.47,.43]);ElementArt.draw(c,13,...a,143,130,phase*2,.85,phase);break;}
  }
 }
 if(impact){
  if(index===3){const pts=quadPath(rig.socket,[tx,ty],-28,25).map(([x,y])=>[mix(rig.socket[0],x,1-smooth(hit)),y]);ElementArt.strand(c,4,pts,32,phase,1-hit);}
  if(index===4)for(let yy of [193,283])for(let k=0;k<3;k++)ElementArt.draw(c,5,tx-22+k*21,yy-31*(1-hit),40,67*(1-hit),0,1-hit,phase);
  if(Math.floor(index/3)===1)shield(c,121,261,hit);
 }
};

pulseImpact=function(c,index,tx,ty,h,direction){
 if(reduced||h<0||h>=1)return;
 const gi=Math.floor(index/3),art=[3,7,11,15,15][gi],v=index%3;
 const grow=.48+.72*Math.sin(Math.min(1,h*2)*Math.PI/2),fade=Math.pow(1-h,1.6),size=gi===4?138:gi===1?99:119;
 ElementArt.draw(c,art,tx,ty,size*grow,size*grow,gi===1?h*.4:0,fade,h*2);
 if(v===1&&gi===0)ElementArt.draw(c,1,tx,ty,83,112,-.5,fade,h*3);
 if(v===2&&gi===0)ElementArt.draw(c,2,tx,ty,103*grow,103*grow,h*1.2,fade*.7,h*2);
 // Material fragments move out, separate from the slower expanding contact mass.
 for(let k=0;k<7;k++){const a=direction+(hash(k+80)-.5)*5,d=(22+hash(k)*45)*Math.sin(h*Math.PI/2),x=tx+Math.cos(a)*d,y=ty+Math.sin(a)*d+h*h*24;
  if(gi===1)leaf(c,x,y,5*fade,a+h*4,'#a4c56c');
  else if(gi===2){ellipse(c,x,y,2.3*fade,4.5*fade,'#82e3f1',fade);dot(c,x-1,y-2,1,'#f0ffff',fade);}
  else line(c,[[x-Math.cos(a)*7,y-Math.sin(a)*7],[x,y]],gi===0?'#ffc86c':'#b5eafa',2,fade);
 }
 ring(c,tx,278,15+h*52,gi===2?'#87d5e5':'#b8a576',fade*.35,.18);
 if(camera.flash&&h<.12)dot(c,tx,ty,25,groups[gi].color,(1-h/.12)*.16);
 c.save();c.globalAlpha=fade*Math.min(1,h*12);c.font='bold 21px Georgia';c.textAlign='center';c.fillStyle='#f3e6c5';c.strokeStyle='#101c23';c.lineWidth=3;
 const number='−'+impactValues[index];c.strokeText(number,tx,ty-48-h*24);c.fillText(number,tx,ty-48-h*24);c.restore();
};

document.querySelector('#actor-library p').textContent='Oito formas com gestos articulados, transferência de peso e recuperação. Compare os seis estados e acompanhe de onde nasce cada golpe.';
const artSection=document.createElement('section');artSection.innerHTML='<small>Nova arte dos elementos</small><h2>Fogo, espinhos, água e tempestade.</h2><p>Dezesseis assets ilustrados, com textura e silhueta próprias, animados nos quinze estudos abaixo.</p><img alt="Prancha dos dezesseis efeitos elementais" style="display:block;width:min(100%,720px);margin:24px auto;background:#101e26;border-radius:12px" src="'+DATA.images.vfxAtlas+'">';
document.querySelector('main').append(artSection);
