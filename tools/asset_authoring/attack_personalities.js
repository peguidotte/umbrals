/* Presentation-only choreography. Event seconds are shared with audio/export. */
const MotionV5=(()=>{
 const profiles={
  ember:{name:'Brasa',mass:.70,breath:.045,tempo:1.30,settle:.40},
  ignivar:{name:'Ignivar',mass:1.25,breath:.040,tempo:.85,settle:.64},
  moss:{name:'Musgo',mass:1.05,breath:.022,tempo:.70,settle:.65},
  verdalio:{name:'Verdálio',mass:2.20,breath:.015,tempo:.46,settle:.95},
  dew:{name:'Orvalho',mass:.65,breath:.055,tempo:1.15,settle:.50},
  mareveu:{name:'Marevéu',mass:1.05,breath:.045,tempo:.80,settle:.76},
  volt:{name:'Faísca',mass:.55,breath:.020,tempo:1.85,settle:.32},
  tempestral:{name:'Tempestral',mass:1.35,breath:.018,tempo:1.45,settle:.58}
 };
 const specs=DATA.choreography;
 const range=(t,a,b)=>clamp((t-a)/(b-a));
 const out=x=>1-Math.pow(1-clamp(x),3);
 function sample(index,t){const s=specs[index],w=range(t,s.start,s.release),u=range(t,s.release,s.contact),after=Math.max(0,t-s.contact-s.hold),h=clamp(after/.82);
  // The hero pose and victim hold at contact; the environment keeps running.
  const actionTime=t<s.contact?t:t<s.contact+s.hold?s.contact:t-s.hold;
  return {s,t,w,u,after,h,actionTime,active:t>=s.start&&t<s.end,charge:t>=s.start&&t<s.release,travel:t>=s.release&&t<s.contact,impact:t>=s.contact&&t<s.end,
   wind:Math.pow(w,1.6)*(1-out(range(t,s.release,s.release+.11))),
   snap:out(range(t,s.release-.025,s.release+.075))*(1-out(range(t,s.contact+.10,s.contact+.62))),
   follow:Math.sin(after*17)*Math.exp(-after*7),settle:1-smooth(range(t,s.contact+.18,s.end))};
 }
 function idle(id,t){let p=Anatomy.idle(id,t),f=Anatomy.forms[id].family,pr=profiles[id];if(reduced)return p;
  const a=t*tau*pr.tempo/3.2;p.inflate=Math.sin(a)*pr.breath;p.head=Math.sin(a*.65)*.025;p.bob=-Math.max(0,Math.sin(a))*1.5;
  if(f==='ember'){p.tail=.11*Math.sin(a-.6);p.ear=.08*Math.sin(a*1.4);p.head+=.03*Math.sin(a*.4);}
  if(f==='moss'){p.crest=.027*Math.sin(a);p.fore=.012*Math.sin(a);p.head=.025*Math.sin(a*.45);}
  if(f==='dew'){p.crest=.07*Math.sin(a-.8);p.tail=.09*Math.sin(a-1.3);p.ear=.05*Math.sin(a+.6);}
  if(f==='volt'){p.crest=.07*Math.sin(a*1.7);p.fore=.03*Math.sin(a*1.3);p.hind=-.03*Math.sin(a*1.3);}
  return p;
 }
 function pose(index,t,id){const z=sample(index,t),s=z.s,p=idle(id,t),a=z.wind,b=z.snap,r=z.follow,f=Anatomy.forms[id].family,adult=profiles[id].mass>1;
  if(reduced||!z.active)return p;
  p.blink=0;p.inflate=0;p.bob=0;p.head=0;p.tail=0;p.fore=0;p.hind=0;p.crest=0;p.ear=0;
  switch(index){
   case 0:p.x-=14*a+17*b;p.bob=12*a-8*b;p.head=-.23*a+.32*b;p.jaw=.55*b;p.inflate=.17*a-.07*b;p.fore=.17*a-.22*b;p.hind=-.13*a+.20*b;p.tail=-.20*a+.24*b;break;
   case 1:p.x-=14*a;p.bob=14*a-5*b;p.rotation=.16*a-.19*b;p.tail=-.50*a+.61*b-.09*r;p.head=.20*a-.25*b;p.fore=-.32*a+.30*b;p.hind=.30*a-.24*b;break;
   case 2:p.x+=10*b;p.bob=10*a-13*b;p.fore=-.58*a+.48*b;p.hind=.20*a-.18*b;p.head=-.13*a+.15*b;p.rotation=-.12*a+.14*b;p.tail=.20*a-.32*b;break;
   case 3:p.x-=10*a;p.x+=12*b;p.fore=-.58*a+.58*b;p.crest=.12*a-.15*b;p.rotation=.08*a-.10*b;p.head=-.08*a+.12*b;p.bob=8*a+3*b;break;
   case 4:p.bob=-16*a+15*b;p.fore=-.30*a+.35*b;p.hind=-.20*a+.21*b;p.head=-.10*a+.16*b;p.crest=.10*a-.18*b;p.inflate=.05*a-.07*b;break;
   case 5:p.crest=-.36*a+.43*b;p.fore=.20*a-.15*b;p.head=-.12*a+.16*b;p.bob=8*a-6*b;p.rotation=.05*a-.06*b;break;
   case 6:p.x-=10*a+21*b;p.bob=9*a-3*b;p.head=-.21*a+.25*b;p.jaw=.38*b;p.inflate=.13*a-.11*b;p.crest=-.13*a+.24*b;p.tail=.22*a-.28*b;p.fore=.16*a-.19*b;break;
   case 7:p.rotation=.11*a-.13*b;p.bob=12*a-10*b;p.inflate=.21*a-.12*b;p.crest=-.29*a+.36*b;p.head=.13*a-.21*b;p.tail=.29*a-.34*b;p.fore=-.13*a+.24*b;break;
   case 8:p.bob=18*a-39*b;p.hind=-.39*a+.40*b;p.fore=.30*a-.38*b;p.tail=-.28*b;p.crest=.22*a-.28*b;p.rotation=-.07*a+.11*b;break;
   case 9:p.bob=7*a-7*b;p.head=-.16*a+.16*b;p.crest=-.25*a+.37*b;p.fore=.20*a-.26*b;p.hind=-.17*a+.21*b;p.inflate=.04*a-.03*b;break;
   case 10:p.bob=13*a-9*b;p.inflate=.12*a-.07*b;p.crest=.20*a-.25*b;p.fore=-.27*a+.25*b;p.hind=.24*a-.18*b;p.head=.18*a-.18*b;break;
   case 11:p.bob=-9*a+11*b;p.fore=-.54*a+.49*b;p.hind=.24*a-.19*b;p.rotation=-.10*a+.14*b;p.crest=-.24*b;p.head=.16*b;break;
   default:{const flight=out(z.u),back=smooth(range(t,s.contact+.26,2.55)),reach=300*flight*(1-back);p.x+=reach;
    p.fore=-.40*a+.43*b;p.hind=.36*a-.42*b;p.crest=-.29*b;p.head=.13*b;
    if(index===12){p.bob=17*a-7*b;p.rotation=-.15*b+.07*r;}
    if(index===13){p.y-=Math.sin(z.u*Math.PI)*117*(1-back);p.bob=18*a+14*b*(z.impact?1:0);p.rotation=-.28*Math.sin(z.u*Math.PI)+.23*b;p.fore=.39*b;p.hind=-.43*b;}
    if(index===14){p.y-=Math.sin(z.u*Math.PI)*37*(1-back);p.rotation=-tau*flight*(1-back);p.fore=-.56*b;p.hind=.56*b;p.crest=-.32*b;
     // Spin about the shell, rather than swinging the whole sprite below its feet.
     const center=adult?66:55;p.x-=center*Math.sin(p.rotation);p.y+=center*(Math.cos(p.rotation)-1);
    }
   }
  }
  p.head-=r*.055;p.crest+=r*.08;p.tail+=r*.06;p.ear=-.16*a+.18*b;
  const follow=Math.sin(Math.max(0,t-s.release)*20)*Math.exp(-Math.max(0,t-s.release)*5);
  if(f==='volt'){p.joints.wing=[.58,.50,.40,.32,.24,.18];p.wing=-.11*a+.25*b+.06*follow;p.joints.feeler=[.76,.39,...Anatomy.forms[id].antenna,.12,.22];p.feeler=.12*a-.18*b+.06*follow;}
  if(f==='moss'){p.joints.bough=[.43,.48,.31,.25,.19,.23];p.bough=.09*a-.15*b+.04*r;}
  if(f==='dew'){p.joints.fin=[.59,.57,.57,.75,.15,.23];p.fin=-.12*a+.24*b+.05*follow;}
  // Larger forms transfer more weight; small forms recover with a spring.
  if(!adult){p.bob*=1.14;p.head*=1.1;p.tail*=1.1;}
  for(const key of ['head','tail','fore','hind','crest','wing','feeler','bough','fin'])if(p[key])p[key]=Math.max(-.65,Math.min(.65,p[key]));
  return p;
 }
 function reaction(id,index,t,delay=0){const s=specs[index],p=idle(id,t),elapsed=t-s.contact-delay,pr=profiles[id],family=Anatomy.forms[id].family;
  p.x=0;if(reduced||elapsed<0)return p;
  const a=Math.max(0,elapsed-s.hold),strike=out(a/.09),recover=1-smooth(a/(.55+pr.settle)),kick=strike*recover,heavy=index>=12?1.5:1;
  let push=22*heavy/Math.sqrt(pr.mass)*kick,twist=.15*heavy*kick,up=0;
  if(s.mode==='push'){push=32/Math.sqrt(pr.mass)*out(a/.17)*recover;twist=.09*kick;}
  if(s.mode==='flow'){push=36/Math.sqrt(pr.mass)*out(a/.30)*recover;push+=Math.sin(clamp((a-.13)/.35)*Math.PI)*8/pr.mass;twist=.06*kick;p.head=-.15*kick;}
  if(s.mode==='wave'){push=44/Math.sqrt(pr.mass)*out(a/.28)*recover;twist=.13*kick;up=-12*Math.sin(clamp(a/.45)*Math.PI)/pr.mass;}
  if(s.mode==='cut'){twist=-.25*kick;push*=.7;up=-7*Math.sin(clamp(a/.25)*Math.PI);p.head=.31*kick;}
  if(s.mode==='lash'){const pull=Math.sin(clamp((a-.10)/.34)*Math.PI);push=push*.7-pull*17/pr.mass;twist=-.17*kick+.12*pull;p.head=.24*kick;}
  if(s.mode==='pierce'){const hits=[0,.10,.20].reduce((sum,d)=>sum+(a>=d?Math.exp(-(a-d)*20):0),0);push=10/pr.mass*hits;twist=-.08*hits;p.head=.13*hits;}
  if(s.mode==='bloom'){up=-17*Math.sin(clamp(a/.40)*Math.PI)/pr.mass;push*=.8;twist=-.12*kick;}
  if(s.mode==='lift'){up=-25*Math.sin(clamp(a/.42)*Math.PI)/pr.mass;push*=.7;}
  if(s.mode==='shock'){const flick=Math.sin(a*62)*Math.exp(-a*10);push=8*kick+flick*3;twist=flick*.045;p.crest=flick*.16;p.fore=flick*.17;}
  if(s.mode==='pulse'){push=31/Math.sqrt(pr.mass)*out(a/.14)*recover;twist=.11*kick;p.inflate=-.08*kick;}
  if(s.mode==='bind'){push=9*kick;twist=-.06*kick;p.inflate=-.11*kick;p.head=.25*kick;p.bob=12*kick;}
  if(s.mode==='ram'){push*=1.25;twist=.19*kick;p.head=-.20*kick;}
  if(s.mode==='slam'){push*=.9;up=-17*Math.sin(clamp(a/.29)*Math.PI)/pr.mass;twist=.23*kick;p.inflate=-.12*kick;}
  if(s.mode==='spin'){push*=1.1;twist=-.26*kick+.08*Math.sin(a*15)*Math.exp(-a*5);up=-9*Math.sin(clamp(a/.34)*Math.PI);}
  p.x=-push;p.y+=up;p.rotation=twist;p.blink=.85*kick;p.head+=.18*kick;p.bob=5*kick;
  if(family==='ember'){p.fore+=-.30*kick;p.hind=.28*kick;p.tail=-.38*kick;p.ear=-.26*kick;p.bob+=5*kick;}
  if(family==='moss'){p.rotation*=.45;p.fore+=-.19*kick;p.crest+=-.14*kick;p.head+=.12*kick;p.bob+=7*kick;p.x*=.6;}
  if(family==='dew'){p.inflate+=-.17*kick;p.crest+=.27*kick;p.tail=-.29*kick;p.head+=-.17*kick;p.bob+=8*kick;}
  if(family==='volt'){p.fore+=.30*kick;p.hind=-.27*kick;p.head+=-.18*kick;p.crest+=-.30*kick;p.bob+=9*kick;p.rotation*=.7;}
  return p;
 }
 function life(id,state,t){const family=Anatomy.forms[id].family,pr=profiles[id],p=idle(id,t),w=Math.sin(clamp((t-.28)/2.45)*Math.PI);
  if(reduced)return p;
  if(state===2)return pose({ember:1,moss:4,dew:7,volt:13}[family],t,id);
  if(state===3){let r=reaction(id,{ember:0,moss:4,dew:8,volt:13}[family],t-.25);r.x+=121;return r;}
  if(state===1){p.bob+=(family==='moss'?6:12)*w;p.head-=.15*w;p.fore-=.24*w;p.hind+=.22*w;p.tail-=.23*w;p.crest-=.19*w;p.inflate+=.08*w;}
  if(state===4){p.bob+=(family==='volt'?16:10)*w;p.fore=-.30*w;p.hind=.25*w;p.head=.15*w;p.crest=-.28*w;p.tail=-.40*w;}
  if(state===5){if(family==='moss'){p.crest=.15*w;p.fore=-.24*w;p.head=-.12*w;p.bob=-7*w;}else{p.y-=Math.sin(clamp((t-.42)/1.20)*Math.PI)*(pr.mass<1?30:18);p.fore=-.30*w;p.hind=.22*w;p.tail=.26*w;p.crest=.20*w;}}
  return p;
 }
 return {profiles,specs,sample,pose,reaction,idle,life,range,out};
})();
