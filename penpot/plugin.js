/* Corner geometry adapted from Supercorner/figma-squircle. See THIRD-PARTY-NOTICES.md. */
globalThis.P2RCorners=(()=>{
 function path(w,h,radii,smoothing){
  const r=radii.map(v=>Math.max(0,Math.min(v,Math.min(w,h)/2))),s=Math.max(0,Math.min(smoothing,.999999));
  const params=r.map(radius=>{
   if(!radius)return {r:0,p:0};
   const smooth=Math.min(s,Math.min(w,h)/2/radius-1),p=(1+smooth)*radius;
   const arc=Math.sin(Math.PI/4*(1-smooth))*radius*Math.SQRT2;
   const c=radius*Math.tan(Math.PI/8*smooth)*Math.cos(Math.PI/4*smooth),d=c*Math.tan(Math.PI/4*smooth);
   const b=(p-arc-c-d)/3;return {r:radius,p,a:2*b,b,c,d,arc};
  });
  const corner=(v,i)=>{if(!v.r)return '';const {a,b,c,d,arc,r}=v,ab=a+b,abc=ab+c,cb=c+b,cba=cb+a;
   return [
    `c ${a} 0 ${ab} 0 ${abc} ${d} a ${r} ${r} 0 0 1 ${arc} ${arc} c ${d} ${c} ${d} ${cb} ${d} ${cba}`,
    `c 0 ${a} 0 ${ab} ${-d} ${abc} a ${r} ${r} 0 0 1 ${-arc} ${arc} c ${-c} ${d} ${-cb} ${d} ${-cba} ${d}`,
    `c ${-a} 0 ${-ab} 0 ${-abc} ${-d} a ${r} ${r} 0 0 1 ${-arc} ${-arc} c ${-d} ${-c} ${-d} ${-cb} ${-d} ${-cba}`,
    `c 0 ${-a} 0 ${-ab} ${d} ${-abc} a ${r} ${r} 0 0 1 ${arc} ${-arc} c ${c} ${-d} ${cb} ${-d} ${cba} ${-d}`][i];};
  const [tl,tr,br,bl]=params;
  return `M ${tl.p} 0 L ${w-tr.p} 0 ${corner(tr,0)} L ${w} ${h-br.p} ${corner(br,1)} L ${bl.p} ${h} ${corner(bl,2)} L 0 ${tl.p} ${corner(tl,3)} Z`;
 }
 function surface(spec){
  const {radii,smoothing,fill,stroke}=spec;
  if(!Array.isArray(radii)||radii.length!==4||!radii.every(v=>Number.isFinite(v)&&v>=0&&v<=120)||!Number.isFinite(smoothing)||smoothing<0||smoothing>1)throw Error('Invalid smooth corner geometry');
  const paint=p=>{if(!p||!/^#[0-9a-f]{6}$/i.test(p.color)||!Number.isFinite(p.opacity)||p.opacity<0||p.opacity>1)throw Error('Invalid corner paint');return p};paint(fill);if(stroke){paint(stroke);if(!Number.isFinite(stroke.width)||stroke.width<0||stroke.width>120)throw Error('Invalid corner stroke');}
  const ext=radii.map(v=>Math.ceil(Math.max(v*(1+smoothing),stroke?.width||0))+1),[tl,tr,br,bl]=ext;
  const w=Math.max(tl,bl)+Math.max(tr,br)+2,h=Math.max(tl,tr)+Math.max(bl,br)+2;
  let svg=`<svg xmlns="http://www.w3.org/2000/svg" width="${w*2}" height="${h*2}" viewBox="0 0 ${w} ${h}">`;
  const outer=path(w,h,radii,smoothing);
  svg+=`<path d="${outer}" fill="${fill.color}" fill-opacity="${fill.opacity}"/>`;
  if(stroke){const t=stroke.width;if(!Number.isFinite(t)||t<0||t>Math.min(w,h)/2)throw Error('Invalid corner stroke');
   const inner=path(w-2*t,h-2*t,radii.map(v=>Math.max(0,v-t)),smoothing);
   svg+=`<defs><mask id="ring"><path d="${outer}" fill="white"/><path d="${inner}" transform="translate(${t} ${t})" fill="black"/></mask></defs><path d="${outer}" fill="${stroke.color}" fill-opacity="${stroke.opacity}" mask="url(#ring)"/>`;
  }
  return {svg:svg+'</svg>',width:w,height:h,slice:[Math.max(tl,bl)*2,Math.max(tl,tr)*2,(w-Math.max(tr,br))*2,(h-Math.max(bl,br))*2]};
 }
 return {path,surface};
})();

/* Preserve source token definitions and bindings; resolve aliases without executing expressions. */
globalThis.P2RTokens=(()=>{
 const plain=v=>v==null?null:JSON.parse(JSON.stringify(v));
 function exportCatalog(catalog,warnings=[]){
  const sets=(catalog.sets||[]).map(s=>({id:s.id,name:s.name,active:!!s.active,tokens:(s.tokens||[]).map(t=>({id:t.id,name:t.name,type:t.type,value:plain(t.value),resolved:plain(t.resolvedValue??t.resolvedValueString)}))}));
  if(sets.length>64||sets.reduce((n,s)=>n+s.tokens.length,0)>2000)throw Error('Token catalog exceeds 64 sets or 2000 tokens.');
  const themes=(catalog.themes||[]).map(t=>({id:t.id,name:t.name,group:t.group||'',active:!!t.active,sets:(t.activeSets||[]).map(s=>s.id)}));
  if(themes.length>32)throw Error('Token catalog exceeds 32 themes.');
  const palette=active=>{
   const raw=new Map();for(const s of sets)if(active.has(s.id))for(const t of s.tokens)raw.set(t.name,t);
   const cache=Object.create(null),visiting=new Set();
   const resolve=name=>{if(Object.hasOwn(cache,name))return cache[name];const t=raw.get(name);if(!t||visiting.has(name))return undefined;visiting.add(name);let value=t.value;
    const alias=typeof value==='string'&&value.trim().match(/^\{([^{}]+)\}$/);if(alias)value=resolve(alias[1])?.value;
    visiting.delete(name);const type=t.type;
    if(typeof value==='string'&&/^(?:dimension|sizing|spacing|borderRadius|borderWidth|fontSizes|fontWeights|opacity|rotation|number)$/.test(type)){const m=value.trim().match(/^(-?(?:\d+\.?\d*|\.\d+))(?:px)?$/);value=m?Number(m[1]):undefined;}
    if(type==='color'&&typeof value==='string'&&!/^#[\da-f]{6}$/i.test(value))value=undefined;
    if(type==='fontFamilies'&&typeof value!=='string')value=undefined;
    if(typeof value!=='number'&&typeof value!=='string')value=undefined;
    if(typeof value==='number'&&(!Number.isFinite(value)||Math.abs(value)>100000))value=undefined;
    return cache[name]=value===undefined?null:{type,value};
   };
   for(const name of raw.keys())resolve(name);return cache;
  };
  const active=new Set(sets.filter(s=>s.active).map(s=>s.id)),palettes=Object.create(null);palettes.Default=palette(active);
  for(const theme of themes){const selected=new Set(active);const sameGroup=themes.filter(t=>t.group===theme.group);for(const t of sameGroup)for(const id of t.sets)selected.delete(id);for(const t of themes)if(t.active&&t.group!==theme.group)for(const id of t.sets)selected.add(id);for(const id of theme.sets)selected.add(id);palettes[theme.id]=palette(selected);}
  const unresolved=Object.entries(palettes.Default).filter(([,v])=>!v).map(([k])=>k);if(unresolved.length)warnings.push('Theme export: unresolved aliases/expressions/types retained as definitions and skipped at runtime: '+unresolved.join(', '));
  const bindingNames=Object.create(null);for(const set of sets)for(const token of set.tokens)if(typeof token.id==='string')bindingNames[token.id]=token.name;
  return {sets,themes,palettes,bindingNames};
 }
 return {exportCatalog};
})();

/* Shared between the companion plugin and the connected Penpot test harness. */
globalThis.P2R = (() => {
  const version = 4;
  // Text-mode policy and underscore tag grammar adapted from figrbx; see THIRD-PARTY-NOTICES.md.
  function parseName(raw, enabled) {
    if(!enabled)return {name:raw,button:/\[button\]/i.test(raw)};
    const tags=[];
    let name=raw.replace(/\[(button|scroll|panel|closed|open|close)(?::([A-Za-z0-9_.-]{1,64}))?\]/gi,(_,kind,target)=>{tags.push({kind:kind.toLowerCase(),target});return ' '});
    name=name.replace(/_(button|scroll|panel|closed|close)(?![a-z0-9])|_(open):([A-Za-z0-9_.-]{1,64})/gi,(_,simple,targeted,target)=>{tags.push({kind:(simple||targeted).toLowerCase(),target});return ' '}).replace(/\s+/g,' ').trim()||'Layer';
    if(/\[(?:button|scroll|panel|closed|open|close)(?::|\])/i.test(name))throw Error(raw+': malformed tag. Use a target without spaces, for example [open:Shop].');
    if(tags.some(t=>t.target&&['button','scroll','closed'].includes(t.kind)))throw Error(raw+': this tag does not accept a target.');
    if(tags.filter(t=>t.kind==='panel').length>1)throw Error(raw+': use only one panel tag.');
    const actions=tags.filter(t=>t.kind==='open'||t.kind==='close');
    if(actions.length>1)throw Error(raw+': use only one open or close action.');
    const panel=tags.find(t=>t.kind==='panel');
    const action=actions[0];if(action?.kind==='open'&&!action.target)throw Error(raw+': open needs a panel name, for example [open:Shop].');
    if(panel&&action)throw Error(raw+': put panel actions on a separate button.');
    const scroll=tags.some(t=>t.kind==='scroll');if(scroll&&(action||tags.some(t=>t.kind==='button')))throw Error(raw+': a scrolling container cannot also be a button.');
    return {name,button:!!action||tags.some(t=>t.kind==='button'),scroll,panel:panel?(panel.target||name):'',closed:tags.some(t=>t.kind==='closed'),action:action?.kind||'',target:action?.target||''};
  }
  function fontMatch(family) {
    const key=String(family||'').toLowerCase().replace(/[\s_-]+/g,'');
    const native={arial:'Arial',sourcesanspro:'SourceSans',roboto:'Roboto',robotocondensed:'RobotoCondensed',robotomono:'RobotoMono',ubuntu:'Ubuntu',buildersans:'BuilderSans',gotham:'Gotham',fredokaone:'FredokaOne',nunito:'Nunito'};
    if(native[key])return {family:native[key],known:true,exact:true};
    const substitutions={inter:'BuilderSans',interdisplay:'BuilderSans',montserrat:'Gotham',poppins:'Gotham',nunitosans:'Nunito',opensans:'SourceSans',sourcesans3:'SourceSans',helvetica:'Arial',helveticaneue:'Arial',consolas:'RobotoMono',jetbrainsmono:'RobotoMono',fredoka:'FredokaOne'};
    return {family:substitutions[key]||'Arial',known:!!substitutions[key],exact:false};
  }
  function shouldBakeText(mode,match){if(mode==='live')return false;if(mode==='exact')return !match.exact;return !match.known;}
  function textRuns(shape){
    if(typeof shape.getRange!=='function'||!shape.characters)return null;
    const out=[];let reads=0;
    const visit=(start,end)=>{
      if(++reads>8192)throw Error('Text exceeds 8192 style-range reads. Split it into smaller text layers.');
      const r=shape.getRange(start,end),keys=['fontFamily','fontSize','fontWeight','fontStyle','textDecoration','textTransform','direction','align','lineHeight','letterSpacing'];
      const mixed=keys.some(k=>r[k]==='mixed')||r.fills==='mixed';
      if(mixed&&end-start>1){let mid=Math.floor((start+end)/2);if(/[\uDC00-\uDFFF]/.test(shape.characters[mid]))mid++;if(mid<end){visit(start,mid);visit(mid,end);return;}}
      if(mixed)throw Error('Unresolved mixed text range.');
      const fills=r.fills||shape.fills,fill=Array.isArray(fills)&&fills.length===1?fills[0]:null;
      if(!fill?.fillColor||fill.fillImage||fill.fillColorGradient||Number(r.letterSpacing||0)!==0||r.direction==='rtl')throw Error('Unsupported text-range paint, spacing or direction.');
      const family=r.fontFamily||shape.fontFamily,match=fontMatch(family);
      const run={value:shape.characters.slice(start,end),family,robloxFamily:match.family,fontSubstituted:!match.exact,size:Number(r.fontSize||shape.fontSize),weight:Math.max(100,Math.min(900,Math.round(Number(r.fontWeight||shape.fontWeight||400)/100)*100)),italic:(r.fontStyle||shape.fontStyle)==='italic',color:fill.fillColor,alpha:fill.fillOpacity??1,decoration:r.textDecoration||'none',transform:r.textTransform||'none',lineHeight:r.lineHeight||shape.lineHeight,align:r.align||shape.align};
      if(!Number.isFinite(run.size)||run.size<1||run.size>1000||!Number.isFinite(run.weight)||!['none','underline','line-through'].includes(run.decoration)||!['none','uppercase','lowercase','capitalize'].includes(run.transform))throw Error('Unsupported range typography.');
      const style=JSON.stringify({...run,value:''}),last=out[out.length-1];if(last?.style===style)last.run.value+=run.value;else out.push({style,run});
    };
    visit(0,shape.characters.length);if(out.length>2048)throw Error('Text exceeds 2048 runs.');
    const runs=out.map(v=>v.run);if(new Set(runs.map(v=>v.align)).size>1||new Set(runs.map(v=>v.lineHeight)).size>1)throw Error('Mixed paragraph alignment or line height.');
    return runs;
  }
  function exportSelection(api, selection = [...api.selection], options = {}) {
    const rules=options.layerRules||{};if(!rules||typeof rules!=='object'||Array.isArray(rules))throw Error('Invalid layer rules.');
    const excludedIds=[],references=new Set();let custom=false;
    const textMode=options.textMode||'auto';if(!['auto','live','exact'].includes(textMode))throw Error('Invalid text mode.');
    const behaviors=options.behaviors===true,preferNativeGroups=options.nativeGroups!==false;
    if(options.runtimeThemes&&options.tokens===false)throw Error('Enable token bindings to generate a theme module.');
    const smoothing=options.smoothing==null?0:Number(options.smoothing);if(!Number.isFinite(smoothing)||smoothing<0||smoothing>1)throw Error('Invalid corner smoothing.');
    if (selection.length !== 1) throw Error('Select exactly one layer, group, or board.');
    const root = selection[0];
    if (!['board','group','rectangle','text','ellipse','path','boolean','svg-raw','image'].includes(root.type)) throw Error('Select a supported design layer, group, or board.');
    const warnings = [], assets = [], shapes = new Map();
    const markupCache=new Map(),markupFor=typeof api.generateMarkup==='function'?shape=>{if(!markupCache.has(shape.id))markupCache.set(shape.id,api.generateMarkup([shape],{type:'svg'}));return markupCache.get(shape.id)}:null;
    const warn = (s, text) => warnings.push(`${s.name} (${s.id}): ${text}`);
    const copy = o => JSON.parse(JSON.stringify(o));
    const num = (v, fallback = 0) => v != null && Number.isFinite(Number(v)) ? Number(v) : fallback;
    let count = 0;
    function visit(s, parent, depth, suppressed=false) {
      if (++count > 5000 || depth > 64) throw Error('Selection exceeds 5000 shapes or 64 levels.');
      shapes.set(s.id, s);
      const rule=rules[api.currentFile.id+':'+s.id]||{},mode=rule.mode||'auto';
      if(!['auto','native','image','layout','skip','template'].includes(mode))throw Error(s.name+': invalid layer import mode.');
      const ref=String(rule.ref||'').trim(),template=String(rule.template||'').trim();
      if(ref&&!/^[A-Za-z_][A-Za-z0-9_]{0,63}$/.test(ref))throw Error(s.name+': gameplay reference must be an identifier of 1–64 characters.');
      if(ref&&references.has(ref))throw Error('Duplicate gameplay reference: '+ref);
      if(mode==='template'&&!/^[A-Za-z_][A-Za-z0-9_]{0,63}$/.test(template))throw Error(s.name+': choose a template key of 1–64 identifier characters.');
      if(mode!=='auto'||ref)custom=true;
      if(mode==='skip'){
        if(!parent)throw Error('The root selection cannot be skipped. Select its parent to skip this layer.');
        const omit=(n,level)=>{if(excludedIds.length>=5000||level>64)throw Error('Selection exceeds 5000 shapes or 64 levels.');excludedIds.push(n.id);for(const c of n.children||[])omit(c,level+1)};omit(s,depth);return null;
      }
      if(ref)references.add(ref);
      const parsed=parseName(s.name,behaviors);
      const rot = num(parent?.rotation) * Math.PI / 180;
      const dx = s.center.x - (parent?.center.x || 0), dy = s.center.y - (parent?.center.y || 0);
      const x = parent ? dx * Math.cos(rot) + dy * Math.sin(rot) + parent.width / 2 - s.width / 2 : 0;
      const y = parent ? -dx * Math.sin(rot) + dy * Math.cos(rot) + parent.height / 2 - s.height / 2 : 0;
      let fills = Array.isArray(s.fills) ? copy(s.fills.map(f => ({
        fillColor:f.fillColor, fillOpacity:f.fillOpacity, fillColorGradient:f.fillColorGradient,
        imageId:f.fillImage?.id
      }))) : [];
      const vector = ['path','boolean','svg-raw','image'].includes(s.type) || (s.type === 'ellipse' && Math.abs(s.width-s.height) > 0.1);
      const image = fills.some(f => f.imageId);
      const radii = [s.borderRadiusTopLeft,s.borderRadiusTopRight,s.borderRadiusBottomRight,s.borderRadiusBottomLeft].map(v=>num(v,num(s.borderRadius)));
      const shadows=copy((s.shadows||[]).filter(v=>!v.hidden));
      const nativeShadows=shadows.length>0&&s.type!=='text'&&fills.some(f=>(f.fillColor||f.fillColorGradient)&&num(f.fillOpacity,1)>0)&&shadows.every(v=>v.color?.color&&!v.color.gradient&&!v.color.image&&['drop-shadow','inner-shadow'].includes(v.style||'drop-shadow'));
      const reasons=[];
      if(markupFor&&!vector&&!image&&s.type!=='text'&&!s.children?.length&&fills.length===0){
        const markup=markupFor(s),paint=markup.match(/<g\b[^>]*\bclass="fills"[^>]*>([\s\S]*?)<\/g>/)?.[1]||'';
        if(/\bfill\s*=\s*["']\s*(?!none\b|transparent\b)[^"']+["']|\bfill\s*:\s*(?!none\b|transparent\b)[^;"']+/i.test(paint))reasons.push('SVG paint not exposed by Penpot');
      }
      if(fills.length>1)reasons.push('multiple fills');
      if(shadows.length)reasons.push('shadows');
      if(s.blur||s.backgroundBlur)reasons.push('blur');
      if(s.blendMode&&s.blendMode!=='normal')reasons.push('blend mode');
      if(s.flipX||s.flipY)reasons.push('mirroring');
      if(new Set(radii).size>1)reasons.push('individual corner radii');
      if((s.strokes||[]).length>1||(s.strokes||[]).some(v=>v.strokeColorGradient||(v.strokeStyle&&!['solid','none'].includes(v.strokeStyle))))reasons.push('complex strokes');
      for(const f of fills){const g=f.fillColorGradient;if(g&&(g.type!=='linear'||!((g.startX===0&&g.endX===1&&g.startY===.5&&g.endY===.5)||(g.startY===0&&g.endY===1&&g.startX===.5&&g.endX===.5))))reasons.push('gradient geometry')}
      let match,runs;
      if(s.type==='text'){
        try{runs=textRuns(s)}catch(e){warn(s,'RichText fallback: '+e.message)}
        match=fontMatch(s.fontFamily);
        if(runs?.length)match=fontMatch(runs[0].family);
        const typography=[];
        if(!runs&&(s.fills==='mixed'||[s.fontFamily,s.fontSize,s.fontWeight,s.align,s.fontStyle].includes('mixed')))typography.push('mixed text styling');
        if(num(s.letterSpacing)||(!runs&&s.textDecoration&&s.textDecoration!=='none')||s.direction==='rtl')typography.push('text typography');
        if(mode!=='native'&&(runs?runs.some(r=>shouldBakeText(textMode,fontMatch(r.family))):shouldBakeText(textMode,match)))typography.push('font fidelity');
        if(!runs&&(s.characters.includes('\n')||s.textBounds.height>num(s.fontSize,16)*1.8))typography.push('multiline typography');
        if(runs&&(s.characters.includes('\n')||runs.length>1))warn(s,'Editable RichText: review wrapping and font metrics in Studio.');
        if(textMode==='live'){if(typography.length||!match.exact)warn(s,'Editable text: typography/font may differ from Penpot.');}
        else reasons.push(...typography);
        if(!match.exact&&(mode==='native'||!shouldBakeText(textMode,match)))warn(s,'Editable font substitution: '+s.fontFamily+' → '+match.family+'.');
      }
      if(mode==='native'&&(vector||image||reasons.length))throw Error(s.name+': Native mode cannot preserve '+(vector?'vector geometry':image?'image fill':reasons.join(', '))+'. Use Auto or Image instead.');
      const ownLayout=mode==='layout'||mode==='template';
      const nativeGroup=!ownLayout&&mode!=='image'&&preferNativeGroups&&!suppressed&&!!s.children?.length&&num(s.opacity,1)<1&&s.clipContent===true&&reasons.length===0&&!vector&&!image&&!parsed.button&&!parsed.scroll;
      const subtree=!ownLayout&&!!s.children?.length&&(mode==='image'||(num(s.opacity,1)<1&&!nativeGroup)||(s.clipContent&&(reasons.length||new Set(radii).size>1))||(s.blendMode&&s.blendMode!=='normal')||(shadows.length>0&&!nativeShadows));
      if(subtree)reasons.push('composited subtree');
      const raster=!ownLayout&&!suppressed&&(mode==='image'||vector||image||reasons.length>0);
      const nativeVisual=mode!=='image'&&!ownLayout&&!suppressed&&raster&&!subtree&&!vector&&!image&&['board','group','rectangle'].includes(s.type)&&reasons.every(v=>v==='individual corner radii'||v==='shadows')&&(!shadows.length||(nativeShadows&&num(s.opacity,1)===1))&&!parsed.scroll;
      const solid=fills.length===1&&fills[0].fillColor&&!fills[0].fillColorGradient;
      const strokes=s.strokes||[];
      const canSmooth=!ownLayout&&mode!=='image'&&smoothing>0&&!suppressed&&!vector&&!image&&s.type!=='text'&&s.type!=='ellipse'&&solid&&radii.some(v=>v>0)&&radii.every(v=>v<=120)&&!shadows.length&&!s.blur&&!s.backgroundBlur&&(!s.blendMode||s.blendMode==='normal')&&!s.flipX&&!s.flipY&&!(s.clipContent&&s.children?.length)&&!parsed.scroll&&num(s.opacity,1)===1&&strokes.length<=1&&strokes.every(v=>v.strokeAlignment==='inner'&&(!v.strokeStyle||v.strokeStyle==='solid')&&!v.strokeColorGradient&&num(v.strokeWidth,1)<=Math.min(120,s.width/2,s.height/2));
      let smooth;
      if(canSmooth){const normalized=radii.map(v=>Math.min(v,Math.min(s.width,s.height)/2));const spec={radii:normalized,smoothing,fill:{color:fills[0].fillColor,opacity:num(fills[0].fillOpacity,1)},...(strokes.length?{stroke:{color:strokes[0].strokeColor||'#000000',opacity:num(strokes[0].strokeOpacity,1),width:num(strokes[0].strokeWidth,1)}}:{})};
       const geometry=P2RCorners.surface(spec);smooth={key:`${api.currentFile.id}:${s.id}:smooth`,slice:geometry.slice};assets.push({key:smooth.key,shapeId:s.id,name:s.name+' smooth corners',kind:'smooth',spec});}
      else if(smoothing>0&&radii.some(v=>v>0)&&!suppressed)warn(s,'Smooth corners skipped: use a solid surface, no shadows/blur, no clipped children, opacity 100%, radii ≤120px and at most one inner stroke.');
      if(parsed.scroll&&(raster||subtree))throw Error(s.name+': scrolling needs a native container. Remove its composited effects or opacity before exporting.');
      if((parsed.scroll||parsed.panel)&&s.type==='text')throw Error(s.name+': scroll/panel tags belong on a container.');
      if (raster) {
        const key = `${api.currentFile.id}:${s.id}`;
        if(!smooth)assets.push({key, shapeId:s.id, name:s.name, reason:[vector?'vector':image?'image-fill':null,...reasons].filter(Boolean).join(', '), format:'png', scale:2,skipChildren:!subtree,fallback:!!nativeVisual});
        if(reasons.length&&!smooth)warn(s,`${nativeVisual?'Compatibility image fallback':'Automatic image surface'}: ${reasons.join(', ')}. Native source objects are retained${subtree?'; descendant visuals are included in this effect surface':''}.`);
      }
      const n = {
        id:s.id, name:behaviors?parsed.name:s.name, type:s.type, x, y, width:s.width, height:s.height,
        rotation:parent ? num(s.rotation)-num(parent.rotation) : 0,
        opacity:ownLayout?1:num(s.opacity,1), visible:!s.hidden,
        clip:!!s.clipContent, radius:radii[0],radii,shadows:nativeShadows?shadows:[],nativeVisual:!!nativeVisual&&!smooth,smooth, fills,
        strokes:copy(s.strokes || []),
        constraints:{horizontal:s.constraintsHorizontal || 'left',vertical:s.constraintsVertical || 'top'},
        assetKey:raster&&!smooth ? `${api.currentFile.id}:${s.id}` : undefined,
        rasterSurface:raster&&!vector&&!image,rasterSubtree:subtree,
        visualSuppressed:suppressed||ownLayout,rasterOpacityBaked:raster,
        ...(mode!=='auto'?{importMode:mode}:{}),...(ref?{ref}:{}),...(mode==='template'?{template}:{}),
        button:parsed.button,nativeGroup,
        ...(behaviors?{behavior:{panel:parsed.panel||'',action:parsed.action||'',target:parsed.target||''},scroll:!!parsed.scroll,initiallyClosed:!!parsed.closed}:{}),
        children:[]
      };
      if (s.type === 'text') {
        n.text={value:s.characters,size:runs?.[0]?.size||num(s.fontSize,16),family:runs?.[0]?.family||s.fontFamily,robloxFamily:match.family,fontSubstituted:runs?runs.some(r=>r.fontSubstituted):!match.exact,weight:runs?.[0]?.weight||num(s.fontWeight,400),
          italic:s.fontStyle === 'italic',align:s.align,verticalAlign:s.verticalAlign,
          lineHeight:num(s.lineHeight,1.2),letterSpacing:num(s.letterSpacing),transform:s.textTransform,
          measuredWidth:s.textBounds.width,measuredHeight:s.textBounds.height,...(runs&&(runs.length>1||runs[0].decoration!=='none')?{runs}:{} )};
      }
      if(options.tokens!==false&&s.tokens){n.tokens={};for(const [key,value]of Object.entries(s.tokens))if(typeof value==='string'&&value)n.tokens[key]=value;}
      if (s.flex) {
        const f=s.flex;
        n.layout={dir:f.dir,wrap:f.wrap,gap:f.dir.startsWith('row')?f.columnGap:f.rowGap,
          align:f.alignItems,justify:f.justifyContent,
          padding:[f.topPadding,f.rightPadding,f.bottomPadding,f.leftPadding]};
        const supported=['row','column'].includes(f.dir) &&
          ['start','center','end'].includes(f.alignItems || 'start') && ['start','center','end','space-between','space-around','space-evenly'].includes(f.justifyContent || 'start') &&
          (f.wrap!=='wrap'||((f.justifyContent||'start')==='start'&&(f.alignContent||'start')==='start'&&num(f.rowGap)===num(f.columnGap)))&&
          (s.children || []).every(c=>!c.layoutChild?.absolute &&
            !['auto'].includes(c.layoutChild?.horizontalSizing) && !['auto','fill'].includes(f.dir==='row'?c.layoutChild?.verticalSizing:c.layoutChild?.horizontalSizing) &&
            !(f.wrap==='wrap'&&['fill'].includes(f.dir==='row'?c.layoutChild?.horizontalSizing:c.layoutChild?.verticalSizing))&&
            [null,undefined,'auto'].includes(c.layoutChild?.alignSelf)&&
            !['maxWidth','maxHeight','minWidth','minHeight'].some(k=>c.layoutChild?.[k]!=null)&&
            !['topMargin','rightMargin','bottomMargin','leftMargin'].some(k=>num(c.layoutChild?.[k])!==0));
        n.layout.native= supported&&(!raster||nativeVisual||smooth);
        if (!supported) warn(s, 'Complex flex is baked to measured desktop positions; resize constraints remain available.');
      }
      if (s.grid) {
        const g=s.grid;
        const unsupported=(s.children||[]).some(c=>{
          const cell=c.layoutCell||{},l=c.layoutChild||{};
          return (cell.rowSpan||1)!==1||(cell.columnSpan||1)!==1||l.absolute===true||
            ['auto','fill'].includes(l.horizontalSizing)||['auto','fill'].includes(l.verticalSizing)||
            ![null,undefined,'auto','start'].includes(l.alignSelf)||
            ['topMargin','rightMargin','bottomMargin','leftMargin'].some(k=>num(l[k])!==0)||
            ['maxWidth','maxHeight','minWidth','minHeight'].some(k=>l[k]!=null);
        });
        n.grid={dir:g.dir||'row',padding:[num(g.topPadding),num(g.rightPadding),num(g.bottomPadding),num(g.leftPadding)],
          columnGap:num(g.columnGap),rowGap:num(g.rowGap),columns:g.columns?.length||0,rows:g.rows?.length||0,unsupportedCells:unsupported};
        warn(s,'Grid uses measured positions by default. Enable Use native uniform grids in Studio Options to convert compatible cells.');
      }
      if(s.layoutChild)n.layoutChild={horizontalSizing:s.layoutChild.horizontalSizing,verticalSizing:s.layoutChild.verticalSizing};
      n.children=mode==='template'?[]:(s.children || []).map(c=>visit(c,s,depth+1,suppressed||subtree)).filter(Boolean);
      return n;
    }
    const document={format:'penpot-roblox',version,source:{fileId:api.currentFile.id,pageId:api.currentPage.id,rootId:root.id},
      design:visit(root,null,0),warnings,assets,assetMap:{},fontMap:{},options:{textMode,behaviors,nativeGroups:preferNativeGroups,smoothing,runtimeThemes:options.runtimeThemes===true,autoTint:options.autoTint!==false},capabilities:['text-modes','native-groups','behavior-tags','native-effects','flex-layouts','quality-report','smooth-corners','rich-text','tokens','image-controls']};
    if(custom){document.version=5;document.excludedIds=excludedIds;document.capabilities.push('layer-modes','gameplay-references','templates');}
    if(options.tokens!==false){
      try{const catalog=api.library?.local?.tokens;if(catalog)document.tokens=P2RTokens.exportCatalog(catalog,warnings);}
      catch(error){
        if(!/Permission library:read is not granted/i.test(String(error?.message||error)))throw error;
        warnings.push('Design token definitions were skipped because library read permission is missing. Update or reinstall Penpot to Roblox from the helper manifest and approve library read access to export tokens. Current visual values are still exported.');
      }
    }
    if(options.runtimeThemes&&!document.tokens)warnings.push('No token catalog is exposed by this Penpot file; no runtime theme module will be generated.');
    if(behaviors){
      const panels=new Set();const collect=n=>{if(n.behavior.panel){if(panels.has(n.behavior.panel))throw Error('Duplicate panel name: '+n.behavior.panel);panels.add(n.behavior.panel);}n.children.forEach(collect)};collect(document.design);
      const resolve=(n,nearest)=>{const b=n.behavior;nearest=b.panel||nearest;if(n.initiallyClosed&&!b.panel)throw Error(n.name+': [closed] needs a [panel] tag.');if(b.action){if(!b.target)b.target=nearest||'';if(!panels.has(b.target))throw Error(n.name+': action has no matching panel: '+b.target);}n.children.forEach(c=>resolve(c,nearest))};resolve(document.design,'');
    }
    return {document,shapes,generateMarkup:markupFor};
  }
  async function exportAssets(bundle,{timeoutMs=30000,onProgress=()=>{}}={}) {
    const result=[];
    for(const a of bundle.document.assets) {
      if(a.kind==='smooth'){result.push({...a});continue;}
      const shape=bundle.shapes.get(a.shapeId);
      const exportLayer=async options=>{
        let timer;onProgress(`Exporting ${result.length+1} of ${bundle.document.assets.length}: ${a.name} (${options.type.toUpperCase()})`);
        try{return await Promise.race([
          Promise.resolve().then(()=>shape.export(options)),
          new Promise((_,reject)=>{timer=setTimeout(()=>reject(Error('Penpot export did not respond within '+Math.ceil(timeoutMs/1000)+' seconds')),timeoutMs)})
        ])}
        catch(error){throw Error(`Cannot export "${a.name}" (${a.shapeId}) as ${options.type.toUpperCase()}: ${error?.message||error}. Check that this layer's images and fonts have loaded in Penpot, then prepare again.`)}
        finally{clearTimeout(timer)}
      };
      let svg,localMarkup=false;
      if(bundle.generateMarkup&&shape.type!=='text'&&(!a.skipChildren||!shape.children?.length)){
        try{
          const markup=bundle.generateMarkup(shape);
          if(typeof markup==='string'&&/<svg\b[^>]*\bviewBox="[^"]+"/.test(markup)){
            svg=[];for(const char of markup){let cp=char.codePointAt(0);if(cp>=0xD800&&cp<=0xDFFF)cp=0xFFFD;if(cp<128)svg.push(cp);else if(cp<2048)svg.push(192|(cp>>6),128|(cp&63));else if(cp<65536)svg.push(224|(cp>>12),128|((cp>>6)&63),128|(cp&63));else svg.push(240|(cp>>18),128|((cp>>12)&63),128|((cp>>6)&63),128|(cp&63));}
            localMarkup=true;onProgress(`Reading SVG ${result.length+1} of ${bundle.document.assets.length}: ${a.name}`);
          }
        }catch{/* Older Penpot builds can use the regular export API below. */}
      }
      if(!svg)svg=await exportLayer({type:'svg',skipChildren:a.skipChildren});
      const header=Array.from(svg.slice(0,1500),v=>String.fromCharCode(v)).join('');
      const match=header.match(/viewBox="([^"]+)"/);if(!match)throw Error('Export has no raster bounds: '+a.name);
      const viewBox=match[1].trim().split(/\s+/).map(Number),scale=Math.min(2,1024/viewBox[2],1024/viewBox[3]);
      if(viewBox.length!==4||!viewBox.every(Number.isFinite)||viewBox[2]<=0||viewBox[3]<=0)throw Error('Invalid SVG bounds: '+a.name);
      if(localMarkup){viewBox[0]-=shape.x;viewBox[1]-=shape.y;}
      const surface={...a,viewBox,shapeWidth:shape.width,shapeHeight:shape.height,rotation:shape.rotation||0};
      // Self-contained vectors can be rasterized in the companion without a second remote render.
      // Only inspect ASCII markup here; preserve the original UTF-8 bytes for the UI renderer.
      // Penpot's plugin sandbox does not expose browser TextDecoder constructors.
      const svgText=Array.from(svg,byte=>String.fromCharCode(byte)).join(''),localVector=shape.type!=='text'&&!/<(?:[\w-]+:)?(?:text|tspan|textPath|image|foreignObject)\b/i.test(svgText)&&!/@import|(?:https?:|\/\/)/i.test(svgText.replace(/\sxmlns(?::[\w-]+)?\s*=\s*(['"])[\s\S]*?\1/g,''));
      if(localVector){result.push({...surface,svgBytes:Array.from(svg),renderWarning:a.name+': vector rendered locally from its SVG.'});continue;}
      try{const bytes=await exportLayer({type:'png',scale,skipChildren:a.skipChildren});result.push({...surface,bytes:Array.from(bytes)});}
      catch(error){onProgress('Using SVG fallback: '+a.name);result.push({...surface,svgBytes:Array.from(svg),renderWarning:a.name+': Penpot PNG export failed; trying the self-contained SVG locally.',pngError:error.message});}
    }
    return result;
  }
  function describeSelection(api){
   const selection=[...api.selection];if(selection.length!==1)throw Error('Select exactly one layer, group, or board.');
   const layers=[];const visit=(n,depth)=>{if(depth>64||layers.length>=5000)throw Error('Selection exceeds 5000 layers or 64 levels.');layers.push({id:n.id,name:n.name,type:n.type,depth});for(const c of n.children||[])visit(c,depth+1)};visit(selection[0],0);
   return {fileId:api.currentFile.id,layers};
  }
  return {exportSelection,exportAssets,parseName,fontMatch,shouldBakeText,textRuns,describeSelection};
})();

penpot.ui.open('Penpot Bridge', 'http://127.0.0.1:43129/ui.html', {width:440,height:610});
let lastBundle,lastRequestId;
penpot.ui.onMessage(async message => {
  const requestId=message?.requestId;
  const send=value=>penpot.ui.sendMessage({...value,requestId});
  try {
    if(message?.type==='layers') {
      send({type:'layer-list',...P2R.describeSelection(penpot)});
    } else if(message?.type === 'export') {
      lastBundle=undefined;lastRequestId=requestId;
      lastBundle=P2R.exportSelection(penpot,[...penpot.selection],message.options||{});
      send({type:'document',document:lastBundle.document});
    } else if(message?.type === 'assets') {
      if(!lastBundle) throw Error('Export the selection first.');
      if(requestId!==lastRequestId)throw Error('Selection changed. Prepare the selection again.');
      const assets=await P2R.exportAssets(lastBundle,{onProgress:message=>send({type:'progress',message})});
      send({type:'assets',assets});
    }
  } catch(e) { send({type:'error',message:String(e.message || e)}); }
});
