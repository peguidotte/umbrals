/* Form-specific anatomy calibrated against the unmodified source atlas.
 * Slots are authored explicitly, never inferred from gameplay evolution order.
 */
const Anatomy = (()=>{
 const forms={
  ember:{family:'ember',name:'Brasa',mouth:[.91,.57],tail:[.31,.11],fore:[.81,.74],eye:[.77,.50],head:[.70,.53],ears:[.62,.31]},
  ignivar:{family:'ember',name:'Ignivar',mouth:[.89,.50],tail:[.31,.08],fore:[.91,.93],eye:[.80,.44],head:[.72,.48],ears:[.68,.29]},
  moss:{family:'moss',name:'Musgo',fore:[.47,.90],root:[.84,.93],crest:[.62,.18],mouth:[.77,.60],eye:[.74,.51],head:[.77,.54],ears:[.60,.22]},
  verdalio:{family:'moss',name:'Verdálio',fore:[.57,.88],root:[.84,.93],crest:[.76,.09],mouth:[.80,.58],eye:[.79,.50],head:[.80,.52],ears:[.76,.16]},
  volt:{family:'volt',name:'Faísca',antenna:[.88,.20],antennaB:[.76,.13],shell:[.31,.51],fore:[.73,.88],mouth:[.69,.66],eye:[.58,.61],head:[.62,.61],ears:[.80,.17]},
  tempestral:{family:'volt',name:'Tempestral',antenna:[.88,.24],antennaB:[.79,.11],shell:[.39,.45],fore:[.83,.84],mouth:[.79,.66],eye:[.73,.56],head:[.76,.58],ears:[.83,.18]},
  dew:{family:'dew',name:'Orvalho',mouth:[.91,.63],reservoir:[.45,.43],hind:[.33,.92],fore:[.64,.94],eye:[.77,.51],head:[.80,.58],ears:[.73,.29]},
  mareveu:{family:'dew',name:'Marevéu',mouth:[.92,.51],reservoir:[.46,.41],hind:[.36,.90],fore:[.67,.94],eye:[.83,.44],head:[.81,.49],ears:[.72,.24]}
 };
 const states=['Repouso','Preparação','Conjuração','Dano','Defesa','Celebração'];
 function socket(index,id){let part=RigStudy.specs[index].part;return forms[id][part]||forms[id].shell||forms[id].mouth;}
 function decorate(p,id){let f=forms[id],base=RigStudy.joints[f.family],data=DATA.regions[id];if(data.grounding)p.ground=[data.grounding.foot[0]/data.rect[2],data.grounding.foot[1]/data.rect[3]];p.joints={...base,head:[f.head[0]-.09,f.head[1]+.12,f.head[0],f.head[1],.19,.24],ear:[f.ears[0],f.ears[1]+.10,...f.ears,.15,.20],jaw:[f.mouth[0]-.10,f.mouth[1],f.mouth[0]-.03,f.mouth[1]+.045,.12,.09]};if(id==='ember')p.joints.fore=[.69,.66,.79,.73,.18,.16];if(id==='moss')p.joints.fore=[.48,.72,.47,.89,.18,.20];if(f.family==='volt')p.joints.crest=[.70,.50,...f.ears,.20,.30];p.eye=f.eye;return p;}
 function idle(id,t){let p={x:121,y:267,rotation:0,sx:1,sy:1,head:0,tail:0,fore:0,hind:0,crest:0,ear:0,jaw:0,bob:0,inflate:0,blink:0};if(reduced)return decorate(p,id);let f=forms[id],a=t*tau/3.2,breathe=Math.sin(a),look=Math.sin(a*.7+.6);p.inflate=.035*breathe;p.bob=-1.6*(breathe+1);p.head=.035*look;p.blink=RigStudy.windowPulse(t%3.2,2.25,2.32,2.43);if(f.family==='ember'){p.tail=.10*Math.sin(a+.7);p.ear=.09*Math.sin(a*1.6);p.fore=.025*Math.sin(a)}if(f.family==='moss'){p.crest=.045*Math.sin(a+.9);p.head=.025*Math.sin(a*.8);p.fore=.018*breathe;}if(f.family==='dew'){p.crest=.09*Math.sin(a+.7);p.tail=.11*Math.sin(a-.5);p.ear=.07*Math.sin(a+1.5);}if(f.family==='volt'){p.crest=.13*Math.sin(a*1.7);p.fore=.035*Math.sin(a+1);p.hind=-.025*Math.sin(a+1)}return decorate(p,id);}
 function attack(index,q,id,t){let p=RigStudy.pose(index,q),f=forms[id];decorate(p,id);if(reduced)return p;let w=RigStudy.windowPulse(q,0,.25,.38),fire=RigStudy.windowPulse(q,.29,.39,.56),recover=q>.61&&q<1?Math.sin((q-.61)*Math.PI*9)*Math.pow((1-q)/.39,2):0;
  if(q<0||q>=1)return idle(id,t);
  // A held anticipation, sharp release and damped recovery are visible in the actor.
  p.head*=1.20;p.fore*=1.18;p.hind*=1.12;p.crest*=1.12;p.ear=-.18*w+.21*fire+.04*recover;p.jaw=[0,6].includes(index)?.42*fire:.05*fire;p.blink=.6*RigStudy.windowPulse(q,.02,.10,.17);p.tail+=.10*recover;p.head-=.05*recover;
  if(index===1){p.tail=-.86*w+1.08*fire-.14*recover;p.head=.22*w-.23*fire;p.fore=-.31*w+.30*fire;p.hind=.36*w-.19*fire;p.rotation=.13*w-.19*fire;}
  if(index===7){p.inflate=.24*w-.11*fire;p.crest=-.39*w+.51*fire-.06*recover;}
  return p;
 }
 function statePose(id,state,t){let p=idle(id,t),q=(t-.30)/2.45,w=RigStudy.windowPulse(q,0,.25,.52),fire=RigStudy.windowPulse(q,.25,.40,.65),end=RigStudy.windowPulse(q,.58,.75,1),family=forms[id].family;if(reduced)return p;
  if(state===1){p.head-=.16*w;p.bob+=9*w;p.fore-=.28*w;p.hind+=.24*w;p.crest-=.19*w;p.tail-=.30*w;p.inflate+=.10*w;}
  if(state===2){let representative={ember:1,moss:3,dew:7,volt:9}[family];return attack(representative,q,id,t);}
  if(state===3){p.x-=20*fire;p.rotation=-.17*fire;p.head=-.35*fire;p.fore=.40*fire;p.hind=-.25*fire;p.bob=8*fire;p.blink=fire;p.crest=-.30*fire;p.tail=.35*fire-.13*end;}
  if(state===4){p.bob+=14*w;p.fore=-.43*w;p.hind=.28*w;p.head=.12*w;p.tail=-.55*w;p.crest=-.35*w;p.inflate-=.06*w;}
  if(state===5){let joy=Math.sin(clamp((q-.12)/.65)*Math.PI);p.y-=family==='moss'?0:22*joy;p.bob-=family==='moss'?12*joy:0;p.fore=-.49*joy;p.hind=.26*joy;p.tail=.45*joy;p.crest=.27*joy;p.head=-.17*joy;p.ear=.30*joy;p.jaw=.10*joy;}
  return p;
 }
 function face(c,rig,id,p){if(reduced)return;let f=forms[id],e=rig.joint(f.eye),m=rig.joint(f.mouth);if(p.blink>.45){line(c,[[e[0]-3,e[1]],[e[0]+4,e[1]+1]],f.family==='dew'?'#58afc0':f.family==='moss'?'#9c804c':'#413336',2,p.blink)}if(p.jaw>.1){ellipse(c,m[0]-2,m[1]+1,3+5*p.jaw,1+6*p.jaw,'#241c25',.95);line(c,[[m[0]-5,m[1]-1],[m[0]+2,m[1]-1]],'#f5e7c6',1,.9)}}
 function draw(c,index,q,id,t,options={}){let p=options.pose||attack(index,q,id,t);let rig=RigStudy.draw(c,index,q,id,false,{pose:p,socket:socket(index,id),size:options.size||166});face(c,rig,id,p);return rig;}
 return {forms,states,socket,decorate,idle,attack,statePose,draw,face};
})();
