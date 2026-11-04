/* Weight, species identity and visible consequences. Standalone authoring only. */
const v5=MotionV5,representatives={ember:0,moss:3,dew:6,volt:9};
const baseTargets={ignivar:'ember',verdalio:'moss',mareveu:'dew',tempestral:'volt'};
let victimChoice='auto',cameraMotion=true;
function victimId(index){let id=victimChoice==='auto'?v5.specs[index].target:victimChoice;return evolved?id:(baseTargets[id]||id);}
function spritePose(c,index,id,p,size=166,mirror=false,x=0){c.save();if(mirror){c.translate(x,0);c.scale(-1,1);}const r=RigStudy.draw(c,index,0,id,false,{pose:p,socket:Anatomy.socket(index,id),size});Anatomy.face(c,r,id,p);c.restore();return r;}
function sourceRig(c,index,id,t,draw=true){const p=v5.pose(index,t,id),socket=Anatomy.socket(index,id);return draw?spritePose(c,index,id,p):{p,socket:RigStudy.project(socket,id,Anatomy.forms[id].family,p,166),joint:uv=>RigStudy.project(uv,id,Anatomy.forms[id].family,p,166)};}
function fragment(c,x,y,dx,dy,a,material,seed=0){const fade=Math.pow(1-clamp(a/.8),1.5);if(a<0||fade<=0)return;const f=1-Math.exp(-a*5),xx=x+dx*f,yy=y+dy*f+55*a*a;
 if(material==='moss'){leaf(c,xx,yy,5*fade,seed+a*8,'#adc675');poly(c,[[xx-3,yy],[xx+3,yy-4],[xx+5,yy+2]],'#8a6440',fade);}
 else if(material==='dew'){ellipse(c,xx,yy,2+fade,3+3*fade,'#9feaf1',fade);dot(c,xx-1,yy-2,1,'#f4ffff',fade);}
 else line(c,[[xx-dx*.07*fade,yy-dy*.07*fade],[xx,yy]],material==='ember'?'#ffca6d':'#b9efff',1+seed%2,fade);
}
function floorTrace(c,index,z,rig){if(reduced)return;const family=Anatomy.forms[evolved?groups[Math.floor(index/3)].adult:groups[Math.floor(index/3)].base].family;
 const w=z.wind;for(let k=0;k<3;k++){const x=96+k*23;
  if(family==='moss'&&w>.1)wood(c,[[x,271],[x-14*w,276],[x-26*w,273]],2,w*.8);
  if(family==='ember'&&z.snap>.1)line(c,[[x,270],[x-16*z.snap,272]],'#806e51',2,z.snap*.7);
  if(family==='dew'&&w>.1)ring(c,x,271,14*w,'#80d7e5',w*.5,.18);
 }
 if(index>=12&&z.t>z.s.release&&z.t<z.s.contact){let a=z.u;for(let k=0;k<7;k++)fragment(c,121,271,-22-k*7,-10-hash(k)*19,a*.5,'moss',k);}
}
function chargeArt(c,index,rig,z){if(!z.charge||reduced)return;const [x,y]=rig.socket,w=z.w,col=groups[Math.floor(index/3)].color;
 if(index<3){const art=[0,1,2][index];ElementArt.draw(c,art,x,y,12+30*w,12+25*w,index===1?-.6:0,w*.9,z.t*2);for(let k=0;k<5;k++){const d=(1-w)*24,a=k*2.4;dot(c,x+Math.cos(a)*d,y+Math.sin(a)*d,1.4,col,w);}}
 if(index>=3&&index<6){if(index===3){const a=rig.joint([.6,.65]);wood(c,[a,[x-9,y-17*w],[x,y]],4,w);}for(let k=0;k<4;k++){const a=k*2.4;leaf(c,x+Math.cos(a)*15*(1-w),y+Math.sin(a)*12*(1-w),4+w*2,a+w,'#a8c986');}}
 if(index>=6&&index<9){const size=8+w*19;ElementArt.draw(c,index===7?9:8,x,y,size*1.4,size,0,w,z.t*2);for(let k=0;k<6;k++){const a=k*2.4,d=31*(1-w);ellipse(c,x+Math.cos(a)*d,y+Math.sin(a)*d,1.5+w,2+w,col,w);}}
 if(index>=9){const other=rig.joint(Anatomy.forms[evolved?groups[Math.floor(index/3)].adult:groups[Math.floor(index/3)].base].antennaB);if(index===9||index===13)bolt(c,...other,x,y,Math.floor(z.t*22),1,w);
  const uv=[[.24,.54],[.40,.44],[.52,.50],[.63,.38],[.72,.27]],pts=uv.map(rig.joint),count=Math.max(2,Math.ceil(w*5));line(c,pts.slice(0,count),'#a4e3ee',3,w*.85);
  if(index===10||index===14)ElementArt.draw(c,13,x,y,26+34*w,24+30*w,z.t*2,w*.8,z.t*3);
 }
}
function travelArt(c,index,from,to,z,rig){if(reduced)return;const s=z.s,u=Math.pow(z.u,index===3?.6:index===7?1.2:.85),arc=index===1?60:index===2?39:0;
 const path=f=>[mix(from[0],to[0],f),mix(from[1],to[1],f)-Math.sin(f*Math.PI)*arc],p=path(u),angle=Math.atan2(to[1]-from[1]-arc*Math.PI*Math.cos(u*Math.PI),to[0]-from[0]);
 if(z.travel){
  if([0,1,2,6].includes(index)){const art=index===6?8:index,wh=index===0?[125,56]:index===1?[82,106]:index===2?[70,70]:[112,46];
   for(let k=3;k>0;k--){const a=path(clamp(u-k*.035));ElementArt.draw(c,art,...a,wh[0]*(1-k*.11),wh[1]*(1-k*.11),index===2?z.t*5:angle,.12*(4-k),z.t*5-k*.1);}
   ElementArt.draw(c,art,...p,...wh,index===2?z.t*5:angle,1,z.t*5);
  }
  if(index===3){const end=[mix(from[0],to[0]+8,u),mix(from[1],to[1],u)],pts=Array.from({length:30},(_,k)=>{const f=k/29;return[mix(from[0],end[0],f),mix(from[1],end[1],f)+Math.sin(f*7-z.t*10)*24*f*(1-u*.55)];});ElementArt.strand(c,4,pts,48,z.t*3);}
  if(index===4)for(let k=0;k<9;k++){const f=k/8,g=smooth((u-f*.78)/.22);if(g>0){const xx=mix(from[0],to[0],f),ground=mix(274,to[1]+42,f);ElementArt.draw(c,5,xx,ground-38*g,43+f*14,77*g,0,1,z.t);}}
  if(index===5)for(let k=0;k<5;k++){const f=clamp(u-k*.035),a=path(f);ElementArt.draw(c,6,a[0]-k*5,a[1]+(k-2)*(7+u*9),68,28,(k-2)*.10,1,z.t*4);}
  if(index===7){const pts=Array.from({length:28},(_,k)=>{const f=k/27;return[mix(rig.socket[0],p[0],f),mix(rig.socket[1],p[1],f)+Math.sin(f*8-z.t*15)*22*Math.sin(f*Math.PI)];});ElementArt.strand(c,9,pts,62,z.t*3);}
  if(index===8){ElementArt.draw(c,10,mix(from[0],to[0],u),237,139,99,0,1,z.t*3);for(let k=1;k<4;k++)ring(c,mix(from[0],to[0],u)-k*23,278,23,'#7ed2df',.25,.17);}
  if(index===9){for(const a of [rig.socket,rig.joint(Anatomy.forms[evolved?'tempestral':'volt'].antennaB)]){const pts=quadPath(a,to,0,18).map(([x,y],k)=>[x,y+(k%3-1)*3*Math.sin(k/18*Math.PI)]);ElementArt.strand(c,12,pts,26,z.t*5);}}
  if(index===10)for(let k=2;k>=0;k--){const a=path(clamp(u-k*.09));ElementArt.draw(c,13,...a,43+k*5,77+k*5,z.t*3,.9-k*.2,z.t*4);}
  if(index===11)ElementArt.draw(c,13,...p,67+u*24,37+u*38,z.t*4,1,z.t*4);
  if(index>=12){let a=rig.joint([.60,.50]);ElementArt.draw(c,index===14?13:14,a[0]+(index===14?0:47),a[1],index===14?150:82,index===14?136:101,index===13?.65:index===14?z.t*8:0,.95,z.t*5);}
 }
 if(z.impact&&z.after<.45){const k=1-smooth(z.after/.45);
  if(index===3){const pts=quadPath(rig.socket,to,-20,25).map(([x,y])=>[mix(rig.socket[0],x,k),y]);ElementArt.strand(c,4,pts,37,z.t*3,k);}
  if(index===7){const pts=quadPath(rig.socket,to,24,25);ElementArt.strand(c,9,pts,50*k,z.t*3,k*.7);}
  if(index===11)ElementArt.draw(c,13,...to,62+30*(1-k),92,0,k,z.t*3);
 }
}
function contactArt(c,index,x,y,z,delay=0,targetFamily='moss'){
 const s=z.s,a=z.t-s.contact-delay,after=Math.max(0,a-s.hold);if(a<0||a>1.30)return;const gi=Math.floor(index/3),fade=Math.pow(1-clamp(after/.82),1.5),f=v5.out(after/.36),dir=index===1?-.6:index===13?.8:0;
 if(reduced){ring(c,x,y,29,groups[gi].color,.8);return;}
 // A clear first contact silhouette; debris then takes over as the core dissipates.
 let art=[3,7,11,15,15][gi],w=gi===4?149:gi===1?91:127,h=gi===2?109:w;
 if(s.mode==='cut'){art=1;w=91;h=140;}
 if(s.mode==='bloom'){art=2;w=137;h=137;}
 if(s.mode==='pierce'){w=78;h=78;}
 if(s.mode==='lift'){art=5;w=99;h=130;y+=9;}
 ElementArt.draw(c,art,x,y,w*(.62+.48*f),h*(.62+.48*f),dir,fade,z.t*4);
 if(after<.10){const k=1-after/.1;line(c,[[x-23,y-10],[x+23,y+10]],'#fff1cc',2,k);dot(c,x,y,4,'#fff6df',k);}
 for(let k=0;k<10;k++){const angle=dir+(hash(k+index*9)-.5)*5.2,dist=28+hash(k+12)*65;fragment(c,x,y,Math.cos(angle)*dist,Math.sin(angle)*dist-15,after,gi===0?'ember':gi===1?'moss':gi===2?'dew':'volt',k);}
 if(index===5||index===7)for(let k=1;k<s.beats.length;k++){const b=z.t-s.beats[k];if(b>=0&&b<.24)ElementArt.draw(c,index===5?7:11,x+(k-1)*9,y-8,70,70,0,(1-b/.24)*.65,b*3);}
 // Target sheds its own material, independently of the incoming element.
 for(let k=0;k<5;k++)fragment(c,x,y+23,(hash(k+50)-.5)*65,-15-hash(k+71)*30,after,targetFamily,k);
 const groundFade=(1-smooth(after/1.2))*.48;
 if(gi===0)ellipse(c,x,277,17+f*12,4,'#30252c',groundFade);
 if(gi===1)for(let k=0;k<5;k++)leaf(c,x+(hash(k)-.5)*65,277,3,k,'#6d7c45');
 if(gi===2){ellipse(c,x,277,19+f*38,4+f*2,'#4198b3',groundFade);ring(c,x,277,10+f*58,'#a1e0e5',fade*.5,.16);}
 if(gi>=3)for(let k=0;k<3;k++){const b=after-k*.09;if(b>=0&&b<.10)bolt(c,x-15+k*12,y-21,x+17-k*5,y+24,k+index,1,(1-b/.1)*.5);}
 // Local optional light, never a full-screen flash.
 if(camera.flash&&a<.08)dot(c,x,y,29,groups[gi].color,.14*(1-a/.08));
 const n=Math.min(1,after/.055),alpha=(1-smooth(after/.95))*n;if(alpha>0){c.save();c.translate(x+7,y-58-after*27);c.scale(1+.22*Math.sin(n*Math.PI),1+.22*Math.sin(n*Math.PI));c.globalAlpha=alpha;c.font='bold 22px Georgia';c.textAlign='center';c.fillStyle='#fff0d1';c.strokeStyle='#111b27';c.lineWidth=3;const text='−'+impactValues[index];c.strokeText(text,0,0);c.fillText(text,0,0);c.restore();}
}
function drawVictim(c,index,t,x,y,delay,size){const id=victimId(index),f=Anatomy.forms[id].family,z=v5.sample(index,t),p=v5.reaction(id,index,t,delay);p.y=y;
 // Preserve the vertical impulse from the reaction, while moving the floor anchor.
 const vertical=v5.reaction(id,index,t,delay).y-267;p.y+=vertical;
 ellipse(c,x,y+3,profilesWidth(id,size),7,'#061013',.8);
 const rig=spritePose(c,representatives[f],id,p,size,true,x);
 if(!reduced&&t>z.s.contact+delay&&t<z.s.contact+delay+.40){const a=t-z.s.contact-delay;for(let k=0;k<3;k++)fragment(c,x,y,-10-k*13,-5-k*3,a,'moss',k);}
 return {id,family:f,point:[x,y-size*.40],rig};
}
function profilesWidth(id,size){return size*(Anatomy.forms[id].family==='moss'?.37:.29);}
function renderV5(index,time,target){const canvas=target||canvases[index],c=canvas.getContext('2d');if(!window.exportMode&&!target){const r=canvas.getBoundingClientRect();if(r.bottom<0||r.top>innerHeight)return;}
 const gi=Math.floor(index/3),g=groups[gi],id=evolved?g.adult:g.base,z=v5.sample(index,time),s=z.s,tx=501,ys=gi===1?[193,283]:[267];
 c.clearRect(0,0,640,360);c.imageSmoothingEnabled=false;c.save();c.beginPath();c.rect(0,30,640,286);c.clip();
 const after=Math.max(0,time-s.contact),trauma=!reduced&&cameraMotion&&z.impact?Math.exp(-after*11)*(index>=12?4.2:index===4?3.6:2.4):0;
 c.translate(Math.sin(after*43)*trauma,Math.sin(after*31+.5)*trauma*.6);
 const bg=assets.background,sw=bg.height*640/300;c.drawImage(bg,(bg.width-sw)/2,0,sw,bg.height,-6,25,652,294);c.fillStyle='#07131922';c.fillRect(0,29,640,288);
 const rigBefore=sourceRig(c,index,id,time,false),release=sourceRig(c,index,id,s.release,false),to=[tx,gi===1?210:207];
 ellipse(c,121,271,56-(index>=12?Math.sin(z.u*Math.PI)*8:0),8,'#061013',.85);floorTrace(c,index,z,rigBefore);
 const victims=ys.map((y,k)=>drawVictim(c,index,time,tx,y,k*.045,gi===1?102:146));
 if(index===4)ys.forEach(y=>travelArt(c,index,release.socket,[tx,y-42],z,rigBefore));
 if(index>=12&&!reduced&&z.travel)for(let k=2;k>0;k--){c.save();c.globalAlpha=.09*(3-k);sourceRig(c,index,id,Math.max(s.release,time-k*.027));c.restore();}
 const rig=sourceRig(c,index,id,time);chargeArt(c,index,rig,z);
 if(index!==4){if(gi===1)ys.forEach(y=>travelArt(c,index,rig.socket,[tx,y-42],z,rig));else travelArt(c,index,[7,9,10,11].includes(index)?rig.socket:release.socket,to,z,rig);}
 victims.forEach((v,k)=>contactArt(c,index,tx,ys[k]-(gi===1?42:60),z,k*.045,v.family));
 if(index>=12&&z.impact&&!reduced){const a=z.after;if(a<.6){ring(c,rig.p.x,274,15+v5.out(a/.6)*42,'#9ba5a0',(1-a/.6)*.35,.15);}}
 if(reduced&&z.active)ring(c,...rig.socket,13,g.color,.8);
 if(showJoints){ring(c,...rig.socket,8,g.color,.95);c.fillStyle='#f3e6c5';c.font='10px sans-serif';c.fillText(RigStudy.specs[index].label,rig.socket[0]+10,rig.socket[1]-9);}
 c.restore();c.fillStyle='#0b171cf5';c.fillRect(0,0,640,30);c.fillRect(0,316,640,44);c.fillStyle='#dec88d';c.font='12px sans-serif';c.fillText(`${String(index+1).padStart(2,'0')} / ${'ABC'[index%3]}  ${g.names[index%3].toUpperCase()}`,13,20);c.textAlign='right';c.fillStyle=g.color;c.fillText(Anatomy.forms[id].name.toUpperCase(),627,20);c.textAlign='left';
 c.font='11px sans-serif';c.fillStyle=g.color;const phase=time<s.start?'PRESENÇA':time<s.release?'TENSÃO':time<s.contact?'RUPTURA':time<s.contact+s.hold?'CONTATO':time<2.3?'CONSEQUÊNCIA':'RECUPERAÇÃO';c.fillText(phase,13,336);c.fillStyle='#bac6b6';c.textAlign='right';c.fillText('SAÍDA: '+RigStudy.specs[index].label+' · ALVO: '+Anatomy.forms[victimId(index)].name,627,336);c.textAlign='left';c.fillStyle='#36504d';c.fillRect(13,347,614,2);c.fillStyle=g.color;c.fillRect(13,347,614*clamp(time/3.2),2);
}
render=renderV5;
drawLife=function(index,t,state=lifeState.value){const canvas=lifeCanvases[index];if(!window.exportMode){const r=canvas.getBoundingClientRect();if(r.bottom<0||r.top>innerHeight)return;}const c=canvas.getContext('2d'),id=formIds[index],f=Anatomy.forms[id],p=v5.life(id,state,t);p.x+=39;p.y-=71;
 c.clearRect(0,0,320,240);c.drawImage(assets.background,0,0,assets.background.width,assets.background.height,0,0,320,240);c.fillStyle='#0b171c55';c.fillRect(0,0,320,240);ellipse(c,160,199,60,8,'#061013',.8);spritePose(c,representatives[f.family],id,p,158);
 c.fillStyle='#0b171cf5';c.fillRect(0,0,320,31);c.fillRect(0,209,320,31);c.fillStyle='#f3e6c5';c.font='15px Georgia';c.fillText(f.name,12,21);c.font='11px sans-serif';c.fillStyle='#bac6b6';c.fillText(Anatomy.states[state].toUpperCase(),12,228);c.textAlign='right';c.fillText(v5.profiles[id].mass>1?'PESO / FIRMEZA':'AGILIDADE / IMPULSO',307,228);c.textAlign='left';
};
window.renderFrame=time=>{window.exportMode=true;canvases.forEach((_,i)=>renderV5(i,time));return canvases.map(c=>c.toDataURL('image/png').split(',')[1]);};
window.renderLifeFrame=(t,s)=>{window.exportMode=true;lifeCanvases.forEach((_,i)=>drawLife(i,t,s));return lifeCanvases.map(c=>c.toDataURL('image/png').split(',')[1]);};
window.choreographySpecs=()=>v5.specs;
window.personalityMetrics=()=>Object.entries(v5.profiles).map(([id,p])=>({id,...p,states:Anatomy.states.map((name,state)=>({name,poses:[.1,.65,1.05,1.45,2.4,3.15].map(t=>v5.life(id,state,t))}))}));
window.performanceMetrics=()=>v5.specs.map((s,index)=>({index,poses:[0,s.release-.05,s.release+.08,s.contact,2.9].map(t=>({t,forms:[groups[Math.floor(index/3)].base,groups[Math.floor(index/3)].adult].map(id=>{const p=v5.pose(index,t,id);return{id,x:p.x,y:p.y,rotation:p.rotation,head:p.head,fore:p.fore,hind:p.hind,tail:p.tail,crest:p.crest};})})),reactions:Object.keys(v5.profiles).map(id=>({id,...v5.reaction(id,index,s.contact+s.hold+.15)}))}));
window.emissionMetrics=()=>v5.specs.map((s,index)=>({index,forms:[groups[Math.floor(index/3)].base,groups[Math.floor(index/3)].adult].map(id=>{const rig=sourceRig(document.createElement('canvas').getContext('2d'),index,id,s.release),p=v5.pose(index,s.release,id);return{id,uv:Anatomy.socket(index,id),release:RigStudy.project(Anatomy.socket(index,id),id,Anatomy.forms[id].family,p,166),drawSocket:rig.socket};})}));
const victimLabel=document.createElement('label');victimLabel.innerHTML='Quem recebe <select id="victim"><option value="auto">Alternar por golpe</option>'+['ignivar','verdalio','mareveu','tempestral'].map(id=>`<option value="${id}">${Anatomy.forms[id].name}</option>`).join('')+'</select>';document.querySelector('nav').append(victimLabel);document.querySelector('#victim').onchange=e=>victimChoice=e.target.value;
const motionLabel=document.createElement('label');motionLabel.innerHTML='<input id="camera-motion" type="checkbox" checked> Impacto de câmera';document.querySelector('nav').append(motionLabel);document.querySelector('#camera-motion').onchange=e=>cameraMotion=e.target.checked;
document.querySelector('h1').textContent='O peso de cada Umbral.';document.querySelector('header p').textContent='Quinze golpes com tensão, ruptura e consequência. Alterne quem recebe para sentir corpos, materiais e reações diferentes.';
document.querySelector('#actor-library p').textContent='Brasa e Faísca são ágeis; Ignivar carrega o impulso no corpo. Musgo e Verdálio firmam raízes. Orvalho e Marevéu acumulam pressão e deixam os apêndices acompanhar o fluxo.';
document.querySelectorAll('article .caption p').forEach((p,i)=>p.textContent=RigStudy.specs[i].label+' · '+v5.specs[i].signature+'. Preparação, contato e recuperação próprios.');
