/* Explicit image controls. All previews use the processed pixels sent to Studio. */
globalThis.P2RImageEditor=(()=>{
 const element=(tag,parent,text)=>{const e=document.createElement(tag);if(text!==undefined)e.textContent=text;parent.append(e);return e};
 function drawSlice(ctx,img,rect,scale,w,h){
  const [l,t,x2,y2]=rect,r=img.width-x2,b=img.height-y2,fit=Math.min(1,w/Math.max(1,(l+r)*scale),h/Math.max(1,(t+b)*scale));
  const dx=[0,l*scale*fit,w-r*scale*fit,w],dy=[0,t*scale*fit,h-b*scale*fit,h],sx=[0,l,x2,img.width],sy=[0,t,y2,img.height];
  for(let y=0;y<3;y++)for(let x=0;x<3;x++)if(sx[x+1]>sx[x]&&sy[y+1]>sy[y]&&dx[x+1]>dx[x]&&dy[y+1]>dy[y])ctx.drawImage(img,sx[x],sy[y],sx[x+1]-sx[x],sy[y+1]-sy[y],dx[x],dy[y],dx[x+1]-dx[x],dy[y+1]-dy[y]);
 }
 async function create(doc,assets,api){
  const container=document.getElementById('image-controls');container.replaceChildren();const nodes=new Map();const walk=n=>{nodes.set(n.id,n);n.children.forEach(walk)};walk(doc.design);const states=[],urls=[];
  const image=async hash=>{const r=await fetch('/assets/'+hash+'/png',{headers:{Authorization:'Bearer '+api.token}});if(!r.ok)throw Error('Cannot load image preview');const url=URL.createObjectURL(await r.blob());const img=new Image();try{await new Promise((ok,no)=>{img.onload=ok;img.onerror=()=>no(Error('Image preview failed'));img.src=url});return img}finally{URL.revokeObjectURL(url)}};
  const dirty=()=>api.dirty('Image settings changed. Apply the settings before sending.');
  const checkbox=(parent,label,value=false)=>{const line=element('label',parent);line.className='image-option';const input=element('input',line);input.type='checkbox';input.checked=value;line.append(document.createTextNode(' '+label));input.onchange=dirty;return input};
  const number=(parent,label,value,min,max)=>{const line=element('label',parent,label+' '),input=element('input',line);input.type='number';input.min=min;input.max=max;input.value=value;input.oninput=dirty;return input};
  async function process(s){
   const a=s.asset,n=s.node,options={tint:s.tint?.checked??s.autoTint,dilate:s.dilate?.checked||false};
   if(s.glow?.checked)options.glow={radius:Number(s.radius.value)};
   const v=s.rendered,result=await api.request('/assets','POST',{png:api.base64(new Uint8Array(v.bytes)),viewBox:v.viewBox,shapeWidth:v.shapeWidth,shapeHeight:v.shapeHeight,rotation:v.rotation,options});
   const stored=doc.assets.find(v=>v.key===a.key);stored.contentHash=result.hash;
   if(a.kind!=='smooth')n.rasterBounds=result.bounds;
   delete n.tintColor;delete n.slice;delete n.glow;
   if(s.eligible&&result.tintColor)n.tintColor=result.tintColor;
   const glowKey=a.key+':glow';doc.assets=doc.assets.filter(v=>v.key!==glowKey);
   if(result.glow){const color=s.glowColor.value;if(!/^#[\da-f]{6}$/i.test(color))throw Error('Glow color must be #RRGGBB');n.glow={key:glowKey,color,opacity:Number(s.glowOpacity.value),bounds:result.glow.bounds};if(n.glow.opacity<0||n.glow.opacity>1||!Number.isFinite(n.glow.opacity))throw Error('Glow opacity must be 0–1');doc.assets.push({key:glowKey,shapeId:n.id,name:a.name+' glow',contentHash:result.glow.hash,generatedGlow:true});}
   if(s.slice?.checked){const [l,t,r,b]=s.edges.map(v=>Number(v.value));if(![l,t,r,b].every(v=>Number.isFinite(v)&&v>=0)||l+r>=result.width||t+b>=result.height)throw Error('Slice insets overlap or are outside the image');n.slice={rect:[l,t,result.width-r,result.height-b],scale:result.bounds.width/result.width};}
   s.result=result;s.preview=await image(result.hash);s.glowPreview=result.glow?await image(result.glow.hash):null;
   if(s.previews){render(s);s.note.textContent=options.tint&&!result.tintColor?'Multiple colors detected; kept the original colors.':result.tintColor?'One white mask is reused; Studio applies '+result.tintColor+'.':'Original image colors retained.';}
  }
  function render(s){
   const n=s.node,img=s.preview;s.previews.replaceChildren();
   for(const [w,h]of [[160,80],[80,160],[200,110]]){const frame=element('div',s.previews),canvas=element('canvas',frame),b=s.result.bounds,g=n.glow?.bounds;
    const left=Math.min(0,b.x,g?.x??0),top=Math.min(0,b.y,g?.y??0),right=Math.max(w,w+b.x+b.width-n.width,g?w+g.x+g.width-n.width:0),bottom=Math.max(h,h+b.y+b.height-n.height,g?h+g.y+g.height-n.height:0);
    canvas.width=Math.ceil(right-left);canvas.height=Math.ceil(bottom-top);canvas.setAttribute('aria-label',`${s.asset.name} preview ${w} by ${h}`);const ctx=canvas.getContext('2d');
    if(s.glowPreview){const glow=document.createElement('canvas');glow.width=Math.max(1,Math.round(w+g.width-n.width));glow.height=Math.max(1,Math.round(h+g.height-n.height));const gc=glow.getContext('2d');gc.drawImage(s.glowPreview,0,0,glow.width,glow.height);gc.globalCompositeOperation='source-in';gc.fillStyle=n.glow.color;gc.fillRect(0,0,glow.width,glow.height);ctx.globalAlpha=n.glow.opacity;ctx.drawImage(glow,g.x-left,g.y-top);ctx.globalAlpha=1;}
    const temp=document.createElement('canvas');temp.width=Math.max(1,Math.round(w+b.width-n.width));temp.height=Math.max(1,Math.round(h+b.height-n.height));const tc=temp.getContext('2d');if(n.slice)drawSlice(tc,img,n.slice.rect,n.slice.scale,temp.width,temp.height);else tc.drawImage(img,0,0,temp.width,temp.height);
    if(n.tintColor){tc.globalCompositeOperation='source-in';tc.fillStyle=n.tintColor;tc.fillRect(0,0,temp.width,temp.height);}ctx.drawImage(temp,b.x-left,b.y-top);element('small',frame,`${w} × ${h}`);
   }
  }
  for(let i=0;i<assets.length;i++){
   const a=assets[i],n=nodes.get(a.shapeId),s={asset:a,node:n,rendered:a.kind==='smooth'?await api.smoothPNG(a.spec):a,eligible:a.kind!=='smooth'&&!a.fallback&&!n.rasterSubtree};
   s.autoTint=s.eligible&&doc.options?.autoTint!==false&&['path','boolean','svg-raw','image','ellipse'].includes(n.type);states.push(s);api.status(`Preparing image ${i+1} of ${assets.length}: ${a.name}`);await process(s);
   if(!s.eligible)continue;
   const card=element('section',container);card.className='card';card.addEventListener('input',()=>s.dirty=true);card.addEventListener('change',()=>s.dirty=true);element('h2',card,a.name);s.note=element('p',card);s.note.className='muted';s.tint=checkbox(card,'Reuse monochrome image as a tintable mask',s.autoTint);s.dilate=checkbox(card,'Experimental RGB edge dilation (alpha unchanged)');s.glow=checkbox(card,'Add a silhouette glow');
   const row=element('div',card);row.className='image-fields';s.radius=number(row,'Glow radius',8,1,32);s.glowOpacity=number(row,'Glow opacity',.7,0,1);s.glowOpacity.step=.1;const gl=element('label',row,'Glow color ');s.glowColor=element('input',gl);s.glowColor.type='color';s.glowColor.value='#85b5ff';s.glowColor.oninput=dirty;
   s.slice=checkbox(card,'Use nine-slice scaling');const edges=element('div',card);edges.className='image-fields';s.edges=['Left','Top','Right','Bottom'].map(name=>number(edges,name,0,0,1023));
   const suggest=element('button',card,'Suggest slices from source corners');suggest.className='secondary';const bounds=s.result.bounds,ratio=s.result.width/bounds.width;const canSuggest=n.radius>0&&n.radii?.every(v=>v===n.radius)&&Math.abs(bounds.x)<.1&&Math.abs(bounds.y)<.1&&Math.abs(bounds.width-n.width)<.1&&Math.abs(bounds.height-n.height)<.1;
   suggest.disabled=!canSuggest;suggest.onclick=()=>{const v=Math.min(Math.ceil(n.radius*ratio),Math.floor(Math.min(s.result.width,s.result.height)/2)-1);s.edges.forEach(e=>e.value=Math.max(0,v));s.slice.checked=true;s.dirty=true;dirty()};
   const apply=element('button',card,'Apply image settings');apply.onclick=async()=>{if(api.busy())return;api.processing(true);try{await process(s);s.dirty=false;if(states.some(v=>v.dirty))api.dirty('Apply the remaining changed image settings before sending.');else {api.ready();api.status('Image settings applied. Review the previews, then send to Studio.')}}catch(e){s.dirty=true;api.dirty(e.message)}finally{api.processing(false)}};
   s.previews=element('div',card);s.previews.className='image-previews';render(s);s.note.textContent=s.result.tintColor?'Tintable mask ready. Colors remain editable in Studio.':'Source colors preserved. Slicing and glow are optional styling changes.';
  }
  return {destroy(){for(const url of urls)URL.revokeObjectURL(url);container.replaceChildren()},states};
 }
 return {create,drawSlice};
})();
