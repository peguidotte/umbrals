/* Fifteen emission-driven performances. Each effect starts at its posed socket. */
const emissionStyles = ['Sopro / boca','Chicote / cauda','Semente ígnea / pata','Cipó / braço','Estouro / raízes','Rajada / galhos','Pressão / boca','Véu / reservatório','Onda / patas','Arco / antenas','Pulso / carapaça','Laço / patas','Investida / carapaça','Mergulho / antenas','Dínamo / carapaça'];
let showJoints=false;
const releaseQ=.35,contactQ=.66;
groups.forEach((g,gi)=>{g.duration=g.duration.map((_,v)=>RigStudy.specs[gi*3+v].duration)});
function quadPath(a,b,arch,n=30){return Array.from({length:n+1},(_,k)=>{let u=k/n;return [mix(a[0],b[0],u),mix(a[1],b[1],u)-Math.sin(u*Math.PI)*arch]})}
function poly(c,points,color,alpha=1){c.save();c.globalAlpha=alpha;c.fillStyle=color;c.beginPath();points.forEach((p,i)=>i?c.lineTo(...p):c.moveTo(...p));c.closePath();c.fill();c.restore()}
function ribbon(c,points,width,color,alpha=1){let top=[],bottom=[];points.forEach((p,i)=>{let before=points[Math.max(0,i-1)],after=points[Math.min(points.length-1,i+1)],dx=after[0]-before[0],dy=after[1]-before[1],len=Math.hypot(dx,dy)||1,w=width*(.20+.80*Math.sin(i/(points.length-1)*Math.PI));top.push([p[0]-dy/len*w,p[1]+dx/len*w]);bottom.push([p[0]+dy/len*w,p[1]-dx/len*w])});poly(c,top.concat(bottom.reverse()),color,alpha)}
function firePetal(c,x,y,length,angle,width,alpha=1){c.save();c.translate(x,y);c.rotate(angle);c.globalAlpha=alpha;for(let k=0;k<3;k++){let w=width*(1-k*.27),l=length*(1-k*.12);c.fillStyle=['#bd513c','#ef987b','#ffe5a0'][k];c.beginPath();c.moveTo(-l*.14,0);c.bezierCurveTo(l*.13,-w*1.6,l*.55,-w*.8,l,0);c.bezierCurveTo(l*.70,-w*.15,l*.41,w*1.3,l*.08,w*.55);c.bezierCurveTo(-l*.09,w*.3,-l*.16,w*.2,-l*.14,0);c.fill()}c.restore()}
function wood(c,pts,width,alpha=1){line(c,pts,'#213328',width+4,alpha);line(c,pts,'#795f39',width,alpha);line(c,pts.map(([x,y])=>[x-2,y-1]),'#a39459',Math.max(1,width*.23),alpha);for(let k=1;k<pts.length-1;k+=3){let [x,y]=pts[k];line(c,[[x-3,y-2],[x+1,y+2],[x+3,y+1]],'#493f2d',1,alpha*.8)}}
function rootSpire(c,x,y,height,bend,width,alpha){if(height<1)return;let pts=Array.from({length:16},(_,k)=>{let u=k/15;return [x+bend*u*u+Math.sin(u*4)*height*.07,y-height*u]});wood(c,pts,width,alpha);let tip=pts[15];leaf(c,tip[0],tip[1]+1,Math.min(9,height*.19),-1,'#a1bd83');for(let k=5;k<13;k+=4){let [xx,yy]=pts[k],dir=k%2?-1:1;wood(c,[[xx,yy],[xx+dir*9,yy-8],[xx+dir*15,yy-11]],width*.38,alpha);leaf(c,xx+dir*15,yy-11,5,dir*.7,'#7d9c69')}for(let j=0;j<4;j++){let a=j*1.7;let xx=x+Math.cos(a)*height*.35,yy=y-Math.sin(height*.05)*4;poly(c,[[xx-3,yy],[xx-1,yy-3],[xx+4,yy-1],[xx+3,yy+2]],'#a59e7c',alpha*.5)}}
function splash(c,x,y,u,n=18){if(u<0||u>1)return;for(let k=0;k<n;k++){let a=k*2.4,d=(17+hash(k+17)*72)*Math.sin(u*Math.PI*.5);let xx=x+Math.cos(a)*d,yy=y+Math.sin(a)*d*.8+u*u*47;ellipse(c,xx,yy,2+3*(1-u),3+5*(1-u),'#80d7e5',1-u);dot(c,xx-1,yy-2,1.5,'#effff4',1-u)}}
function zigRing(c,x,y,rx,ry,phase,alpha=1){let pts=[];for(let k=0;k<=48;k++){let a=k/48*tau,r=1+.08*Math.sin(k*2.1+phase*28);pts.push([x+Math.cos(a)*rx*r,y+Math.sin(a)*ry*r])}line(c,pts,'#88b9d5',6,alpha*.20);line(c,pts,'#e8cf81',2,alpha);}
function screenSource(c,rig,index,q){let g=groups[Math.floor(index/3)],charge=smooth(q/releaseQ),recoil=RigStudy.windowPulse(q,.35,.44,.63),[x,y]=rig.socket;if(q<0||q>1)return;
 if(q<releaseQ){let a=charge;switch(index){
  case 0:flame(c,x,y,3+charge*10,q);ellipse(c,...rig.joint([.68,.61]),19*charge,13*charge,'#ef987b',.14*charge);for(let k=0;k<7;k++){let t=(q*3+k/7)%1;dot(c,x+35*(1-t),y+(hash(k)-.5)*24*(1-t),1.8,'#f5c17b',a)}break;
  case 1:{let pts=[];for(let k=0;k<=20;k++)pts.push(rig.joint([mix(.47,.18,k/20),mix(.65,.12,k/20)]));line(c,pts,'#f9bb72',5,charge*.6);for(let k=0;k<3;k++){let a=-1+k*.7;firePetal(c,x,y,15*charge,a,4,charge)}break;}
  case 2:{let fore=rig.joint([.83,.91]);ring(c,...fore,charge*18,'#ef987b',charge,.28);for(let k=0;k<4;k++){let a=k*tau/4+q*7;flame(c,fore[0]+Math.cos(a)*12,fore[1]+Math.sin(a)*5,charge*4,q+k,charge)}break;}
  case 3:{let arm=rig.joint([.63,.69]);wood(c,[arm,[x-10,y-18],[x,y]],4,charge);leaf(c,x,y,charge*15,q*4,'#91c8a1');break;}
  case 4:for(let k=0;k<4;k++){let foot=rig.joint([.2+k*.22,.96]);line(c,[[foot[0]-10,foot[1]+2],[foot[0]+8,foot[1]-1],[foot[0]+18,foot[1]+4]],'#b4b28c',1,charge)}break;
  case 5:for(let k=0;k<5;k++){let cp=rig.joint([.3+k*.13,.12+Math.sin(k)*.04]);leaf(c,...cp,7*charge,k+q*5,'#c1da7f');dot(c,cp[0],cp[1],2*charge,'#f7e6ae')}break;
  case 6:dot(c,x,y,3+8*charge,'#80d7e5',.85);dot(c,x-3,y-3,3,'#e9fff0',charge);break;
  case 7:{let cp=rig.joint([.43,.35]);zigRing(c,...cp,31*charge,25*charge,q,charge*.7);for(let k=0;k<9;k++){let a=k*tau/9+q*8;dot(c,cp[0]+Math.cos(a)*28,cp[1]+Math.sin(a)*22,3,'#c6f3ed',charge)}break;}
  case 8:for(let k=0;k<3;k++){let foot=rig.joint([.35+k*.2,.96]);ring(c,...foot,24*charge,'#80d7e5',charge,.22)}break;
  case 9:{let other=rig.joint([.78,.10]);bolt(c,...other,x,y,Math.floor(q*36),1,charge);break;}
  case 10:{let circuit=[[.19,.55],[.34,.45],[.46,.55],[.57,.41],[.48,.30],[.62,.18]].map(rig.joint);line(c,circuit.slice(0,Math.max(2,Math.floor(charge*6))),'#90dceb',4,charge);ring(c,x,y,25*charge,'#e8cf81',charge);break;}
  case 11:case 12:case 13:case 14:{for(let k=0;k<3;k++){let a=rig.joint([.25+k*.24,.8]),b=rig.joint([.35+k*.23,.95]);bolt(c,...a,...b,k+Math.floor(q*25),1,charge)}if(index===13)bolt(c,...rig.joint([.78,.10]),x,y,Math.floor(q*28),1,charge);if(index===14)zigRing(c,...rig.joint([.47,.43]),35*charge,28*charge,q,charge);break;}
 }}
 if(recoil>0&&index<12){let backward=[x-22,y+5];if(index===1)backward=[x-8,y+27];if(index===4||index===8)backward=[x,y+8];for(let k=0;k<5;k++)line(c,[[mix(x,backward[0],k/5),mix(y,backward[1],k/5)],[backward[0]-hash(k)*10,backward[1]+(hash(k+10)-.5)*15]],g.color,1,recoil*.6)}
}
function material(c,index,from,to,u,hit,q,rig){let [sx,sy]=from,[tx,ty]=to,v=index%3,gi=Math.floor(index/3),travel=q>=releaseQ&&q<contactQ,impact=q>=contactQ&&q<1,fade=1-hit;
 let arc=index===1?80:index===2?46:index===5?35:index===7?38:0,path=quadPath(from,to,arc),p=path[Math.min(30,Math.floor(clamp(u)*30))];
 if(travel){switch(index){
 case 0:{for(let k=10;k>0;k--){let f=clamp(u-k*.012),x=mix(sx,tx,f),y=mix(sy,ty,f);flame(c,x-4*k,y+Math.sin(q*20+k)*k*.4,17-k*1.3,q+k*.1,.8-k*.04)}flame(c,...p,20,q);for(let k=0;k<3;k++)firePetal(c,p[0]-10,p[1],-35-k*5,Math.sin(q*19+k)*.16,4,.7);break;}
 case 1:{let angle=Math.atan2(ty-sy,tx-sx);let pts=[];for(let k=0;k<20;k++){let a=-1.25+k/19*2.5;pts.push([p[0]+Math.cos(a+angle)*17,p[1]+Math.sin(a+angle)*34])}ribbon(c,pts,9,'#dc663e');line(c,pts,'#ffdda0',3);for(let k=0;k<8;k++){let f=clamp(u-k*.022),pt=path[Math.round(f*30)];firePetal(c,...pt,16,Math.atan2(ty-sy,tx-sx)+2.8+k*.09,4,.55*(1-k/9))}break;}
 case 2:{let rr=9+u*4;flame(c,...p,rr,q);for(let k=0;k<5;k++){let a=k*tau/5+q*12;firePetal(c,p[0]+Math.cos(a)*9,p[1]+Math.sin(a)*9,13,a+1.5,4,.9)}for(let k=1;k<7;k++){let f=clamp(u-k*.03),pt=path[Math.round(f*30)];dot(c,...pt,2,'#ffdd94',1-k/7)}break;}
 case 3:{let end=[mix(sx,tx+12,smooth(u)),mix(sy,ty+38,u)],pts=[];for(let k=0;k<38;k++){let t=k/37;pts.push([mix(sx,end[0],t),mix(sy,end[1],t)+Math.sin(t*7-q*11)*23*t])}wood(c,pts,6);for(let k=3;k<38;k+=4){let [x,y]=pts[k];poly(c,[[x,y],[x-6,y-13],[x+5,y-3]],'#a9ca8d');if(k%3===0)leaf(c,x,y,8,k*.7,'#75a67b')}break;}
 case 4:{for(let k=0;k<10;k++){let f=k/9,z=smooth((u-f*.76)/.24),x=mix(sx,tx,f),y=mix(268,279,f);if(z<=0)continue;rootSpire(c,x,y,(23+hash(k+50)*32)*z,(hash(k+10)-.5)*23,6+f*3,1)}break;}
 case 5:{let center=[mix(sx,tx,u),mix(sy,ty,u)];for(let k=0;k<13;k++){let a=k/12*Math.PI-.5,spread=Math.sin(k*1.7)*15;let x=center[0]-Math.sin(a)*28,y=center[1]+(k-6)*8+spread;leaf(c,x,y,6+hash(k)*4,-.45+k*.08,'#a6c982');line(c,[[x-15,y+6],[x,y]],'#dec88d',1,.8)}for(let k=0;k<7;k++)leaf(c,center[0]-k*14,center[1]+Math.sin(k+q*6)*23,7,q*7+k,'#5d9475',1-k/8);break;}
 case 6:{let pts=quadPath([p[0]-36,p[1]],p,4,8);ribbon(c,pts,10,'#53abc6');ellipse(c,p[0],p[1],18,12,'#80d7e5');ellipse(c,p[0]+4,p[1]-4,8,4,'#e2fbf1');for(let k=0;k<5;k++)dot(c,p[0]-25-k*12,p[1]+Math.sin(q*20+k)*8,3-k*.3,'#80d7e5',.8-k*.12);break;}
 case 7:{let pts=[];for(let k=0;k<46;k++){let f=k/45;pts.push([mix(sx,p[0],f),mix(sy,p[1],f)+Math.sin(f*9-q*15)*22*Math.sin(f*Math.PI)])}ribbon(c,pts,12,'#287492',.8);ribbon(c,pts.map(([x,y],k)=>[x,y+Math.sin(k*.5-q*12)*4]),7,'#80d7e5',.9);line(c,pts,'#e0f6e9',2);for(let k=0;k<7;k++){let pt=pts[5+k*6];dot(c,pt[0],pt[1]-9,2,'#ddf8eb',.8)}break;}
 case 8:{let xx=mix(sx,tx,u),ground=270;poly(c,[[xx-65,ground],[xx-39,ground-18],[xx-22,ground-43],[xx+4,ground-49],[xx+20,ground-32],[xx+11,ground-17],[xx-1,ground-20],[xx+3,ground-30],[xx-9,ground-26],[xx-21,ground-8],[xx+28,ground]],'#3b8fac');line(c,[[xx-58,ground-3],[xx-31,ground-22],[xx-18,ground-43],[xx+4,ground-46],[xx+17,ground-31],[xx+8,ground-19]],'#c4f1e9',4);for(let k=0;k<10;k++)dot(c,xx-50+k*5,ground-5-Math.sin(k/9*Math.PI)*25,2,'#e8faef',.8);break;}
 case 9:{let a=rig.joint([.78,.10]);bolt(c,...a,tx,ty-9,Math.floor(q*35),2);bolt(c,...rig.socket,tx,ty+9,90+Math.floor(q*35),2);bolt(c,tx-26,ty-9,tx+16,ty+17,Math.floor(q*23),1);break;}
 case 10:{let pts=quadPath(from,to,0);line(c,pts,'#597c7c',2,.7);for(let k=0;k<3;k++){let f=clamp(u-k*.12),xx=mix(sx,tx,f),yy=mix(sy,ty,f);zigRing(c,xx,yy,8+k*3,17+k*4,q,.9-k*.22);bolt(c,xx-13,yy,xx+9,yy,12+k,2,.8-k*.2)}break;}
 case 11:{let xx=mix(sx,tx,u),yy=mix(sy,ty,u);zigRing(c,xx,yy,17+u*23,8+u*26,q);for(let k=0;k<6;k++){let a=k*tau/6+q*6;dot(c,xx+Math.cos(a)*(17+u*23),yy+Math.sin(a)*(8+u*26),2,'#e7efbc');}line(c,[[xx-42,yy+4],[xx-19,yy-1]],'#86bed2',1,.6);break;}
 case 12:{let pp=RigStudy.pose(index,q);for(let k=0;k<6;k++)line(c,[[pp.x-77-k*8,pp.y-30-k*6],[pp.x-8,pp.y-34-k*5]],k%2?'#91cbd8':'#e8cf81',k%2?1:2,.8-k*.1);zigRing(c,pp.x+45,pp.y-61,10,35,q,.9);break;}
 case 13:{let pp=rig.p;bolt(c,...rig.joint([.78,.10]),...rig.socket,Math.floor(q*30),2);for(let k=0;k<3;k++){let a=RigStudy.pose(index,q-.03*(k+1));line(c,[[a.x-25,a.y-68],[pp.x+16,pp.y-47]],'#90cad6',2,.6-k*.15)}break;}
 case 14:{let cp=rig.joint([.47,.43]);zigRing(c,...cp,66,56,q,.8);zigRing(c,...cp,50,40,-q,.6);for(let k=0;k<7;k++){let a=q*24+k*tau/7;firePetal(c,cp[0]+Math.cos(a)*56,cp[1]+Math.sin(a)*47,19,a+1.8,3,.8)}break;}
 }}
 if(impact){switch(gi){
 case 0:if(v===0){for(let k=0;k<5;k++){let a=-1.2+k*.55;flame(c,tx+Math.cos(a)*hit*40,ty+Math.sin(a)*hit*25,Math.max(.1,23*fade),q+k,fade)}sparks(c,tx,ty,hit,'#e8b576',18,true)}if(v===1){for(let k=0;k<9;k++)firePetal(c,tx,ty,15+hit*70,-1.4+k*.3,4*fade,fade);line(c,[[tx-18,ty+35],[tx+13,ty-40]],'#ffe3ac',3,fade)}if(v===2){for(let k=0;k<7;k++){let a=k*tau/7;let r=12+Math.sin(hit*Math.PI)*30;flame(c,tx+Math.cos(a)*r,ty+Math.sin(a)*r,Math.max(.1,16*fade),q+k,fade);firePetal(c,tx,ty,r*1.4,a,6*fade,fade)}flame(c,tx,ty,13*fade,q,fade)}break;
 case 1:if(v===0){let pull=1-smooth(hit),pts=quadPath(rig.socket,[tx,ty],-30,35).map(([x,y],k)=>[mix(rig.socket[0],x,pull),y+Math.sin(k*.2)*12*pull]);wood(c,pts,5,fade);for(let yy of [176,276])line(c,[[tx-29,yy-30],[tx+20,yy+21]],'#d3daa6',2,fade)}if(v===1){for(let yy of [190,286]){for(let k=0;k<3;k++)rootSpire(c,tx-30+k*19,yy,(51+k*9)*fade,(k-1)*16,10-k,fade);for(let k=0;k<8;k++){let a=k*2.4;poly(c,[[tx+Math.cos(a)*hit*45,yy-hit*25],[tx+Math.cos(a)*hit*45+6,yy-hit*25-4],[tx+Math.cos(a)*hit*45+9,yy-hit*25+4]],'#ae9e74',fade)}}}if(v===2){for(let k=0;k<16;k++){let a=k*2.4;leaf(c,tx+Math.cos(a)*hit*52,ty+Math.sin(a)*hit*65,7*fade,a+q*8,'#a2c27d')}}shield(c,121,261,hit);break;
 case 2:if(v===0)splash(c,tx,ty,hit,24);if(v===1){for(let k=0;k<4;k++){let yy=ty+(k-2)*17;line(c,[[tx-22*fade,yy],[tx+12*fade,yy+14],[tx+19*fade,yy+22]],'#80d7e5',5,fade)}splash(c,tx,ty,hit,16)}if(v===2){poly(c,[[tx-35,278],[tx-20,ty-20*fade],[tx+2,ty-52*fade],[tx+31,ty-12*fade],[tx+42,278]],'#80d7e5',fade*.7);splash(c,tx,ty-20,hit,23);ring(c,tx,278,hit*59,'#c4f1e9',fade,.2)}break;
 case 3:if(v===0){for(let k=0;k<4;k++)bolt(c,tx-30+k*19,ty-35,tx+17-k*9,ty+32,Math.floor(q*30)+k,1,fade)}if(v===1){zigRing(c,tx,ty,15+hit*42,15+hit*42,q,fade);for(let k=0;k<8;k++){let a=k*tau/8;bolt(c,tx,ty,tx+Math.cos(a)*55*hit,ty+Math.sin(a)*55*hit,k,1,fade)}}if(v===2){zigRing(c,tx,ty,28*fade+8,42*fade+8,q,fade);bolt(c,tx-15,ty-38,tx+18,ty+35,Math.floor(q*20),1,fade)}break;
 case 4:{zigRing(c,tx,ty,12+hit*(v===1?67:51),12+hit*46,q,fade);for(let k=0;k<5;k++){let a=-1.4+k*.64;bolt(c,tx,ty,tx+Math.cos(a)*hit*75,ty+Math.sin(a)*hit*62,k,1,fade)}for(let k=0;k<9;k++)dot(c,tx+(hash(k)-.5)*hit*95,277-Math.sin(hit*Math.PI)*(12+hash(k+1)*21),2,'#b4b28c',fade);break;}
 }}
}
function renderV2(index,time,target){
 let gi=Math.floor(index/3),g=groups[gi],v=index%3,s=RigStudy.specs[index],q=(time-.32)/s.duration,canvas=target||canvases[index],c=canvas.getContext('2d');
 if(!window.exportMode&&!target){let rect=canvas.getBoundingClientRect();if(rect.bottom<0||rect.top>innerHeight)return;}
 c.clearRect(0,0,640,360);c.imageSmoothingEnabled=false;let bg=assets.background,sw=bg.height*640/300;c.drawImage(bg,(bg.width-sw)/2,0,sw,bg.height,0,29,640,288);c.fillStyle='#07131944';c.fillRect(0,29,640,288);
 let active=q>=0&&q<1,hit=clamp((q-contactQ)/(1-contactQ)),impact=q>=contactQ&&q<1,ys=gi===1?[193,283]:[267],tx=513;
 ellipse(c,121,270,53,8,'#061013',.85);for(let yy of ys){ellipse(c,tx,yy+3,36,7,'#061013',.85);let recoil=impact&&!reduced?Math.sin(hit*12)*11*(1-hit):0;actor(c,'spore',tx+recoil,yy,gi===1?83:108,impact&&!reduced?Math.sin(hit*10)*.08*(1-hit):0,1,1);}
 let id=evolved?g.adult:g.base,fromPose=RigStudy.pose(index,releaseQ),from=RigStudy.project(s.socket,id,s.family,fromPose),to=[tx,gi===1?210:220],u=clamp((q-releaseQ)/(contactQ-releaseQ));
 if(active&&index===4&&!reduced)material(c,index,from,to,u,hit,q,{socket:from});
 if(index>=12&&active&&q>.35&&q<contactQ&&!reduced){for(let k=2;k>=1;k--){c.save();c.globalAlpha=.10;RigStudy.draw(c,index,q-k*.028,id,true);c.restore()}}
 let rig=RigStudy.draw(c,index,q,id);if(active&&!reduced){screenSource(c,rig,index,q);if(index!==4)material(c,index,[3,7,10].includes(index)?rig.socket:from,to,u,hit,q,rig)}
 if(active&&gi===2&&q>.72){for(let k=0;k<3;k++){let xx=tx-20+k*20,yy=215+hit*36;dot(c,xx,yy,3,'#80d7e5',1-hit*.5);line(c,[[xx,yy-7],[xx-2,yy]],'#c4eff1',2,1-hit*.5)}}
 if(reduced&&active){ring(c,...rig.socket,14,g.color,.8);if(q>contactQ)ys.forEach(yy=>ring(c,tx,yy-43,30,g.color,.8));}
 if(showJoints){for(let uv of [[.79,.40],[.48,.65],[.83,.84],[.39,.87],[.63,.16]]){let pt=rig.joint(uv);dot(c,...pt,2,'#fff2ca');}let pt=rig.socket;ring(c,...pt,8,g.color,.9);line(c,[[pt[0]-12,pt[1]],[pt[0]+12,pt[1]]],g.color,1);line(c,[[pt[0],pt[1]-12],[pt[0],pt[1]+12]],g.color,1)}
 c.fillStyle='#0b171cf2';c.fillRect(0,0,640,30);c.fillRect(0,316,640,44);c.fillStyle='#dec88d';c.font='12px sans-serif';c.fillText(`${String(index+1).padStart(2,'0')} / ${'ABC'[v]}  ${g.names[v].toUpperCase()}`,13,20);c.textAlign='right';c.fillStyle=g.color;c.fillText('SAÍDA: '+s.label.toUpperCase(),627,20);c.textAlign='left';let phase=q<0?'REPOUSO':q<.25?'PREPARAÇÃO CORPORAL':q<releaseQ?'TENSÃO / EMISSÃO':q<contactQ?'DISPARO / CONTRAPESO':q<.84?'IMPACTO / REAÇÃO':'RECUPERAÇÃO';if(q>=1)phase='REPOUSO';c.font='11px sans-serif';c.fillStyle=g.color;c.fillText(phase,13,335);c.fillStyle='#bac6b6';c.textAlign='right';c.fillText(g.owner,627,335);c.textAlign='left';c.fillStyle='#36504d';c.fillRect(13,347,614,2);c.fillStyle=g.color;c.fillRect(13,347,614*clamp(time/3.2),2);
}
render=renderV2;
const rigToggle=document.createElement('label');rigToggle.innerHTML='<input type="checkbox" id="joints"> Ver articulações e saída';document.querySelector('nav').append(rigToggle);document.querySelector('#joints').onchange=e=>showJoints=e.target.checked;
document.querySelectorAll('article .caption p').forEach((p,i)=>{p.textContent=RigStudy.specs[i].label+' · '+[
 'Pescoço recua, tórax expande e cabeça projeta a chama. Cabeça e patas compensam o sopro.',
 'Quadril prepara o giro, cauda varre em arco e pernas seguram o contrapeso do lançamento.',
 'Pata ergue a semente ígnea e golpeia à frente; ombro, cabeça e cauda reagem ao impulso.',
 'Braço recolhe o cipó, estende num chicote e acompanha a volta até a proteção.',
 'Corpo se ergue, patas batem no solo e o peso percorre raízes de madeira até os alvos.',
 'Galhos flexionam para trás e estalam; copa lança espinhos, tronco e braços amortecem.',
 'Cabeça inspira e avança num sopro; reservatório pulsa e pescoço absorve o recuo.',
 'Reservatório dorsal enche, véus abrem e liberam uma fita; cabeça e cauda fazem contrapeso.',
 'Patas comprimem a nascente, corpo salta e aterrissa; o deslocamento lança uma onda.',
 'Antenas convergem para carregar, abrem na descarga e oscilam ao recuperar.',
 'Circuito percorre a carapaça expandida; cabeça recolhe e patas abrem contra o pulso.',
 'Patas dianteiras levantam, desenham um laço e batem no chão para lançá-lo.',
 'Pernas impulsionam o corpo, antenas recuam e a carapaça recebe o impacto da investida.',
 'Patas comprimem para saltar, antenas apontam o mergulho e pernas absorvem a aterrissagem.',
 'Patas e antenas se recolhem, carapaça gira com um dínamo e o corpo se desenrola ao voltar.'
 ][i]});
window.renderFrame=(time)=>{window.exportMode=true;canvases.forEach((canvas,i)=>renderV2(i,time));return canvases.map(c=>c.toDataURL('image/png').split(',')[1])};
window.rigMetrics=()=>RigStudy.specs.map((s,i)=>{let g=groups[Math.floor(i/3)],id=evolved?g.adult:g.base,poses=[0,.24,.40,.66,1].map(q=>{let p=RigStudy.pose(i,q);return {q,root:[p.x,p.y],angles:[p.head,p.tail,p.fore,p.hind,p.crest],socket:RigStudy.project(s.socket,id,s.family,p)}});return {index:i,source:s.label,poses}});
