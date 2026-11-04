/* One selected performance may make sound. Never mix fifteen autoplaying clips. */
const soundPreview=(()=>{
 let player=null,token=0,clip=-1;
 const control=document.createElement('label');control.innerHTML='Golpe com som <select id="sound-clip">'+groups.flatMap((g,gi)=>g.names.map((name,v)=>`<option value="${gi*3+v}">${String(gi*3+v+1).padStart(2,'0')} · ${name}</option>`)).join('')+'</select>';
 const button=document.createElement('button');button.id='listen';button.textContent='Assistir com som';
 document.querySelector('nav').append(control,button);
 function stop(){token++;if(player){player.pause();player.currentTime=0;player=null;}clip=-1;}
 async function play(index){stop();const current=token;clip=index;player=new Audio(DATA.audio[String(index)]);player.volume=.85;
  states[index].paused=false;states[index].time=0;clock=0;playing=true;speed=1;document.querySelector('#speed').value='1';document.querySelector('#play').textContent='Pausar todas';
  detailIndex=index;document.querySelector('#detailTitle').textContent=groups[Math.floor(index/3)].names[index%3]+' · som e movimento';if(!document.querySelector('dialog').open)document.querySelector('dialog').showModal();
  try{await player.play();if(token!==current)return;player.onended=()=>{if(token===current)stop();};}catch(e){if(token===current){stop();button.textContent='Tentar som novamente';}}
 }
 button.onclick=()=>play(+document.querySelector('#sound-clip').value);
 document.querySelector('dialog').addEventListener('close',stop);
 document.querySelector('#play').addEventListener('click',()=>{if(!playing)stop();});
 document.querySelector('#speed').addEventListener('change',stop);document.querySelector('#restart').addEventListener('click',stop);
 document.querySelector('#sound-clip').addEventListener('change',stop);
 document.querySelector('#reduced').addEventListener('change',stop);
 document.querySelectorAll('article input').forEach(el=>el.addEventListener('input',stop));
 document.querySelectorAll('[data-pause]').forEach(el=>el.addEventListener('click',stop));
 // Audio clock prevents accumulated requestAnimationFrame drift during the preview.
 function sync(){if(player&&!player.paused&&clip>=0){states[clip].time=Math.min(3.199,player.currentTime);clock=states[clip].time;}requestAnimationFrame(sync);}requestAnimationFrame(sync);
 return {play,stop,get active(){return !!player;},get clip(){return clip;}};
})();
window.soundPreview=soundPreview;
