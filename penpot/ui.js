let doc,token,imageEditor,imageBusy=false;const el=id=>document.getElementById(id),status=s=>el('status').textContent=s;
const parentOrigin=document.referrer?new URL(document.referrer).origin:'https://design.penpot.app';
const post=(type,options)=>parent.postMessage({type,options},parentOrigin);
const optionElements=['text-mode','native-groups','behaviors','smoothing','tokens','runtime-themes','auto-tint'];
const exportOptions=()=>({textMode:el('text-mode').value,nativeGroups:el('native-groups').checked,behaviors:el('behaviors').checked,smoothing:Number(el('smoothing').value),tokens:el('tokens').checked,runtimeThemes:el('runtime-themes').checked,autoTint:el('auto-tint').checked});
try{const saved=JSON.parse(localStorage.getItem('penpot-bridge-export-options')||'null');if(saved){if(['auto','live','exact'].includes(saved.textMode))el('text-mode').value=saved.textMode;el('native-groups').checked=saved.nativeGroups!==false;el('behaviors').checked=saved.behaviors===true;el('tokens').checked=saved.tokens!==false;el('runtime-themes').checked=saved.runtimeThemes===true;el('auto-tint').checked=saved.autoTint!==false;if([0,.6,1].includes(saved.smoothing))el('smoothing').value=String(saved.smoothing)}}catch{}
for(const id of optionElements)el(id).onchange=()=>{doc=undefined;imageEditor?.destroy();imageEditor=null;el('send').disabled=true;el('save').disabled=true;try{localStorage.setItem('penpot-bridge-export-options',JSON.stringify(exportOptions()))}catch{}status('Options changed. Prepare the selection again.')};
function preparing(value){el('export').disabled=value;for(const id of optionElements)el(id).disabled=value}
const base64=bytes=>{let s='';for(let i=0;i<bytes.length;i+=8192)s+=String.fromCharCode(...bytes.subarray(i,i+8192));return btoa(s)};
async function request(path,method='GET',value){const r=await fetch(path,{method,headers:{Authorization:'Bearer '+token,...(value?{'Content-Type':'application/json'}:{})},body:value?JSON.stringify(value):undefined});const data=await r.json();if(!r.ok)throw Error(data.error||'Companion request failed');return data}
const connect=async()=>{token=(await(await fetch('/session')).json()).token;const state=await request('/upload-status');el('connection').textContent=state.configured?'Helper running · image uploads ready.':'Helper running · image uploads need setup using the link below.';status('Select a board, then prepare and send it to Studio.')};
connect().catch(()=>{el('connection').textContent='Cannot reach the helper. Run Start-Penpot-Bridge.cmd, keep its window open, then reopen this companion.';status('Local connection unavailable.')});
async function smoothPNG(spec){
 const geometry=P2RCorners.surface(spec),url=URL.createObjectURL(new Blob([geometry.svg],{type:'image/svg+xml'}));
 try{const img=new Image();await new Promise((resolve,reject)=>{img.onload=resolve;img.onerror=()=>reject(Error('Cannot render smooth corners'));img.src=url});const canvas=document.createElement('canvas');canvas.width=geometry.width*2;canvas.height=geometry.height*2;canvas.getContext('2d').drawImage(img,0,0);const blob=await new Promise(resolve=>canvas.toBlob(resolve,'image/png'));if(!blob)throw Error('Smooth corner image failed');return {bytes:new Uint8Array(await blob.arrayBuffer()),viewBox:[0,0,geometry.width,geometry.height],shapeWidth:geometry.width,shapeHeight:geometry.height,rotation:0}}finally{URL.revokeObjectURL(url)}
}
function download(name,data){const url=URL.createObjectURL(new Blob([data],{type:'application/json'}));const a=document.createElement('a');a.href=url;a.download=name;a.click();setTimeout(()=>URL.revokeObjectURL(url),1000)}
function refresh(){preparing(false);el('json').value=JSON.stringify(doc,null,2);el('send').disabled=false;el('save').disabled=false;el('summary').textContent=`${doc.design.width} × ${doc.design.height} pixels · ${doc.assets.length} prepared image surfaces`}
el('export').onclick=()=>{imageEditor?.destroy();imageEditor=null;preparing(true);el('send').disabled=true;el('save').disabled=true;status('Reading your selection…');post('export',exportOptions())};
el('send').onclick=async()=>{try{await request('/document','POST',doc);status('Sent to Studio. Click Receive from Penpot, then review and import.')}catch(e){status(e.message)}};
el('save').onclick=async()=>{try{await request('/document','POST',doc);const bundle=await request('/bundle');download('penpot-design.json',JSON.stringify(bundle));status('Portable bundle downloaded. It includes image pixels for automatic Roblox upload.')}catch(e){status(e.message)}};
window.addEventListener('message',async e=>{
 if(e.source!==parent||e.origin!==parentOrigin)return;const m=e.data;
 try{
  if(m.type==='error')throw Error(m.message);
  if(m.type==='document'){
   doc=m.document;el('name').textContent=doc.design.name;let count=0;const walk=n=>{count++;n.children.forEach(walk)};walk(doc.design);
   el('summary').textContent=`${count} elements · ${doc.design.width} × ${doc.design.height} pixels · ${doc.assets.length} image surfaces`;
   el('details').textContent=doc.warnings.join('\n');
   if(doc.assets.length){status(`Rendering ${doc.assets.length} image surfaces…`);post('assets')}else{refresh();status('Design prepared. Send it directly or download a bundle.')}
  }
  if(m.type==='assets'){
   imageEditor=await P2RImageEditor.create(doc,m.assets,{request,token,base64,smoothPNG,status,ready:refresh,dirty:s=>{el('send').disabled=true;el('save').disabled=true;status(s)},busy:()=>imageBusy,processing:value=>{imageBusy=value;preparing(value);for(const e of el('image-controls').querySelectorAll('input,button')){if(value)e.dataset.wasDisabled=String(e.disabled);e.disabled=value||e.dataset.wasDisabled==='true'}if(value){el('send').disabled=true;el('save').disabled=true}}});
   refresh();status('Design and images prepared. Studio will upload new images and reuse existing ones automatically.');
  }
 }catch(error){preparing(false);status('Preparation failed: '+error.message);el('send').disabled=true;el('save').disabled=true}
});
