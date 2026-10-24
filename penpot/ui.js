let doc,token;const el=id=>document.getElementById(id),status=s=>el('status').textContent=s;
const parentOrigin=document.referrer?new URL(document.referrer).origin:'https://design.penpot.app';
const post=type=>parent.postMessage({type},parentOrigin);
const base64=bytes=>{let s='';for(let i=0;i<bytes.length;i+=8192)s+=String.fromCharCode(...bytes.subarray(i,i+8192));return btoa(s)};
async function request(path,method='GET',value){const r=await fetch(path,{method,headers:{Authorization:'Bearer '+token,...(value?{'Content-Type':'application/json'}:{})},body:value?JSON.stringify(value):undefined});const data=await r.json();if(!r.ok)throw Error(data.error||'Companion request failed');return data}
const connect=async()=>{token=(await(await fetch('/session')).json()).token;const state=await request('/upload-status');el('connection').textContent=state.configured?'Helper running · image uploads ready.':'Helper running · image uploads need setup using the link below.';status('Select a board, then prepare and send it to Studio.')};
connect().catch(()=>{el('connection').textContent='Cannot reach the helper. Run Start-Bridge.ps1, keep its window open, then reopen this companion.';status('Local connection unavailable.')});
function download(name,data){const url=URL.createObjectURL(new Blob([data],{type:'application/json'}));const a=document.createElement('a');a.href=url;a.download=name;a.click();setTimeout(()=>URL.revokeObjectURL(url),1000)}
function refresh(){el('json').value=JSON.stringify(doc,null,2);el('send').disabled=false;el('save').disabled=false}
el('export').onclick=()=>{el('send').disabled=true;el('save').disabled=true;status('Reading your selection…');post('export')};
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
   const nodes=new Map();const walk=n=>{nodes.set(n.id,n);n.children.forEach(walk)};walk(doc.design);
   for(let i=0;i<m.assets.length;i++){
    const a=m.assets[i];status(`Preparing image ${i+1} of ${m.assets.length}: ${a.name}`);
    const result=await request('/assets','POST',{png:base64(new Uint8Array(a.bytes)),viewBox:a.viewBox,shapeWidth:a.shapeWidth,shapeHeight:a.shapeHeight,rotation:a.rotation});
    doc.assets.find(v=>v.key===a.key).contentHash=result.hash;nodes.get(a.shapeId).rasterBounds=result.bounds;
   }
   refresh();status('Design and images prepared. Studio will upload new images and reuse existing ones automatically.');
  }
 }catch(error){status('Preparation failed: '+error.message);el('send').disabled=true;el('save').disabled=true}
});
