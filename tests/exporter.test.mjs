import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import vm from 'node:vm';
const sandbox={setTimeout,clearTimeout,TextDecoder:{}};vm.createContext(sandbox);for(const f of ['corners.js','tokens.js','exporter.js'])vm.runInContext(await readFile(new URL('../penpot/'+f,import.meta.url),'utf8'),sandbox);
function shape(id,type='rectangle',extra={}){return {id,type,name:id,width:100,height:50,center:{x:50,y:25},opacity:null,fills:[],strokes:[],children:[],...extra}}
const api=root=>({selection:[root],currentFile:{id:'file'},currentPage:{id:'page'}});

test('individual layers export without a temporary group and retain their identity',()=>{
 for(const type of ['rectangle','text','ellipse','path','boolean','svg-raw','image']){
  const root=shape('slot-'+type,type,{x:320,y:480,center:{x:370,y:505},fills:[{fillColor:'#123456'}],characters:'Sword',fontFamily:'Arial',fontSize:16,textBounds:{width:45,height:18}});
  const bundle=sandbox.P2R.exportSelection(api(root)),d=bundle.document;
  assert.equal(d.source.rootId,root.id);assert.equal(d.design.id,root.id);
  assert.equal(d.design.type,type);assert.equal(d.design.x,0);assert.equal(d.design.y,0);
  assert.equal(d.design.width,100);assert.equal(d.design.height,50);
  assert.equal(root.x,320);assert.equal(root.y,480);
  if(['path','boolean','svg-raw','image'].includes(type))assert.equal(d.assets[0].shapeId,root.id);
 }
 const root=shape('slot');assert.throws(()=>sandbox.P2R.exportSelection(api(root),[]),/exactly one layer/);
 assert.throws(()=>sandbox.P2R.exportSelection(api(root),[root,root]),/exactly one layer/);
 assert.throws(()=>sandbox.P2R.exportSelection(api(shape('page','root'))),/supported design layer/);
});

test('SVG leaf paints omitted by the Penpot fills API become image surfaces',()=>{
 const rect=shape('imported-bar','rectangle'),blank=shape('blank','rectangle'),root=shape('root','board',{children:[rect,blank]}),source=api(root);
 source.generateMarkup=s=>'<svg viewBox="0 0 100 50"><g class="fills"><rect fill="'+(s[0].id==='blank'?'none':'url(#gradient)')+'"/></g></svg>';
 const d=sandbox.P2R.exportSelection(source).document;assert.equal(d.assets.length,1);assert.equal(d.assets[0].shapeId,rect.id);assert.match(d.assets[0].reason,/SVG paint not exposed/);
});

test('local markup bypasses remote SVG export and converts page bounds without browser codecs',async()=>{
 const vector=shape('crystal','path',{x:104,y:88,export:()=>{throw Error('remote renderer stalled')}}),root=shape('root','board',{children:[vector]});
 const source=api(root),svg='<svg xmlns="http://www.w3.org/2000/svg" viewBox="100 84 32 24"><title>épée 😀</title><path d="M104 88h8v8z"/></svg>';
 source.generateMarkup=()=>svg;const [asset]=await sandbox.P2R.exportAssets(sandbox.P2R.exportSelection(source));
 assert.equal(asset.viewBox[0],-4);assert.equal(asset.viewBox[1],-4);assert.equal(new TextDecoder().decode(new Uint8Array(asset.svgBytes)),svg);
});

test('local markup does not accidentally include children in an own-surface export',async()=>{
 let calls=0;const surface=shape('panel','board',{children:[shape('child')],export:async()=>{calls++;return new TextEncoder().encode('<svg viewBox="0 0 100 50"><rect width="100" height="50"/></svg>')}});
 await sandbox.P2R.exportAssets({document:{assets:[{shapeId:'panel',name:'Panel',skipChildren:true}]},shapes:new Map([['panel',surface]]),generateMarkup:()=>{throw Error('must not use subtree markup')}});
 assert.equal(calls,1);
});

test('own-surface backgrounds never trust PNG skipChildren to exclude editable descendants',async()=>{
 const calls=[],text=shape('machine-name','text',{characters:'Spawner',fontFamily:'Nunito',fontWeight:900}),icon=shape('icon','group',{children:[shape('icon-path','path')]}),svg='<svg viewBox="0 0 288 48"><g id="shape-panel"><rect width="288" height="48"/><g id="shape-machine-name"><text>Spawner</text></g><g id="shape-icon"><path/></g></g></svg>';
 const panel=shape('panel','board',{children:[text,icon],export:async options=>{calls.push(options.type);return new TextEncoder().encode(options.type==='svg'?svg:'PNG containing duplicate text')}});
 const [asset]=await sandbox.P2R.exportAssets({document:{assets:[{shapeId:'panel',name:'Spawner upgrade',skipChildren:true}]},shapes:new Map([['panel',panel]])});
 assert.deepEqual(calls,['svg']);assert.equal(asset.bytes,undefined);assert.equal(asset.surfaceShapeId,'panel');assert.deepEqual(Array.from(asset.omitShapeIds),['machine-name','icon','icon-path']);assert.equal(new TextDecoder().decode(new Uint8Array(asset.svgBytes)),svg);
});

test('intentional subtree images retain their children instead of isolating the background',async()=>{
 const calls=[],panel=shape('panel','board',{children:[shape('text','text')],export:async options=>{calls.push(options.type);return new TextEncoder().encode(options.type==='svg'?'<svg viewBox="0 0 100 50"><text>Whole group</text></svg>':'whole group PNG')}});
 const [asset]=await sandbox.P2R.exportAssets({document:{assets:[{shapeId:'panel',name:'Whole group',skipChildren:false}]},shapes:new Map([['panel',panel]])});
 assert.deepEqual(calls,['svg','png']);assert.ok(asset.bytes);assert.equal(asset.omitShapeIds,undefined);
});

test('unresponsive image exports stop with layer context and progress',async()=>{
 const vector=shape('stuck','path',{name:'Stuck icon',export:()=>new Promise(()=>{})});
 const bundle=sandbox.P2R.exportSelection(api(shape('root','board',{children:[vector]}))),progress=[];
 await assert.rejects(()=>sandbox.P2R.exportAssets(bundle,{timeoutMs:5,onProgress:s=>progress.push(s)}),/Stuck icon.*SVG.*did not respond/);
 assert.match(progress[0],/1 of 1: Stuck icon \(SVG\)/);
 vector.export=async({type})=>new TextEncoder().encode(type==='svg'?'<svg viewBox="0 0 100 50"></svg>':'png');
 assert.equal((await sandbox.P2R.exportAssets(bundle)).length,1,'retry succeeds after a timeout');
});

test('older installations without library permission still export visual values',()=>{
 const root=shape('root','board',{fills:[{fillColor:'#123456'}]}),source=api(root);
 Object.defineProperty(source,'library',{get(){throw Error('Permission library:read is not granted')}});
 const d=sandbox.P2R.exportSelection(source).document;
 assert.equal(d.design.fills[0].fillColor,'#123456');assert.equal(d.tokens,undefined);
 assert.match(d.warnings.join(' '),/library read permission is missing/);
 assert.equal(sandbox.P2R.exportSelection(source,[root],{tokens:false}).document.warnings.length,0);
 assert.match(sandbox.P2R.exportSelection(source,[root],{runtimeThemes:true}).document.warnings.join(' '),/no runtime theme module/);
 const unexpected=api(root);Object.defineProperty(unexpected,'library',{get(){throw Error('Unexpected library error')}});
 assert.throws(()=>sandbox.P2R.exportSelection(unexpected),/Unexpected library error/);
});

test('SVG export errors identify the layer and failed format',async()=>{
 const vector=shape('icon-id','path',{name:'Upgrade icon',export:async()=>{throw Error('http error')}});
 const bundle=sandbox.P2R.exportSelection(api(shape('root','board',{children:[vector]})));
 await assert.rejects(()=>sandbox.P2R.exportAssets(bundle),/Upgrade icon.*icon-id.*SVG: http error/);
});

test('self-contained vectors bypass the stalled remote PNG renderer',async()=>{
 const calls=[],svg='<svg xmlns="http://www.w3.org/2000/svg" xmlns:penpot="https://penpot.app/xmlns" viewBox="-10 -5 40 20"><title>Enchanted épée 😀</title><path fill="#55AA11" d="M0 0h10v10H0z"/></svg>';
 const vector=shape('svg-path','path',{export:async({type})=>{calls.push(type);if(type==='png')return new Promise(()=>{});return new TextEncoder().encode(svg)}});
 const bundle=sandbox.P2R.exportSelection(api(shape('root','board',{children:[vector]}))),[asset]=await sandbox.P2R.exportAssets(bundle,{timeoutMs:5});
 assert.deepEqual(calls,['svg']);assert.equal(new TextDecoder().decode(new Uint8Array(asset.svgBytes)),svg);assert.equal(asset.viewBox[0],-10);
});

test('PNG timeout retains its SVG as a fallback and records the original error',async()=>{
 const surface=shape('panel','rectangle',{blur:{value:2},export:async({type})=>type==='png'?new Promise(()=>{}):new TextEncoder().encode('<svg viewBox="0 0 100 50"><image href="data:image/png;base64,AA=="/></svg>')});
 const bundle=sandbox.P2R.exportSelection(api(shape('root','board',{children:[surface]}))),[asset]=await sandbox.P2R.exportAssets(bundle,{timeoutMs:5});
 assert.ok(asset.svgBytes.length>0);assert.match(asset.pngError,/panel.*PNG.*did not respond/);
});

test('a transient PNG http error retries once with identical bounds and export options',async()=>{
 const calls=[],progress=[];const svg='<svg viewBox="0 0 288 48"><style>@font-face{font-family:Nunito;src:url(https://example.invalid/font.woff2)}</style></svg>';
 const surface=shape('upgrade','board',{name:'Spawner upgrade',width:288,height:48,blur:{value:2},export:async options=>{calls.push({...options});if(options.type==='svg')return new TextEncoder().encode(svg);if(calls.filter(c=>c.type==='png').length===1)throw Error('http error');return new Uint8Array([137,80,78,71])}});
 const [asset]=await sandbox.P2R.exportAssets(sandbox.P2R.exportSelection(api(surface)),{retryDelayMs:0,onProgress:s=>progress.push(s)});
 const pngs=calls.filter(c=>c.type==='png');assert.equal(pngs.length,2);assert.deepEqual(pngs[0],pngs[1]);assert.deepEqual(Array.from(asset.bytes),[137,80,78,71]);assert.equal(asset.svgBytes,undefined);assert.equal(progress.filter(s=>s.startsWith('Retrying PNG')).length,1);
});

test('repeated PNG http errors remain bounded and preserve SVG fallback context',async()=>{
 let attempts=0;const surface=shape('upgrade','board',{blur:{value:2},export:async({type})=>{if(type==='svg')return new TextEncoder().encode('<svg viewBox="0 0 100 50"><text>Test</text></svg>');attempts++;throw Error('http error')}});
 const [asset]=await sandbox.P2R.exportAssets(sandbox.P2R.exportSelection(api(surface)),{retryDelayMs:0});
 assert.equal(attempts,2);assert.ok(asset.svgBytes.length);assert.match(asset.pngError,/upgrade.*PNG.*http error/);
});

test('a timed-out PNG job is not submitted a second time',async()=>{
 let attempts=0;const surface=shape('upgrade','board',{blur:{value:2},export:async({type})=>{if(type==='svg')return new TextEncoder().encode('<svg viewBox="0 0 100 50"><text>Test</text></svg>');attempts++;return new Promise(()=>{})}});
 const [asset]=await sandbox.P2R.exportAssets(sandbox.P2R.exportSelection(api(surface)),{timeoutMs:5,retryDelayMs:0});
 assert.equal(attempts,1);assert.match(asset.pngError,/did not respond/);
});

test('Fredoka remains editable with a declared Fredoka One substitution',()=>{
 const text=shape('title','text',{characters:'Stats',fontFamily:'Fredoka',fontWeight:700,fontSize:24,textBounds:{width:70,height:30}}),root=shape('root','board',{children:[text]});
 const d=sandbox.P2R.exportSelection(api(root)).document;assert.equal(d.assets.length,0);assert.equal(d.design.children[0].text.robloxFamily,'FredokaOne');assert.equal(d.design.children[0].text.fontSubstituted,true);
 assert.equal(sandbox.P2R.exportSelection(api(root),[root],{textMode:'exact'}).document.assets.length,1);
});

test('mixed styles export native runs without splitting Unicode or losing markup characters',async()=>{
 const {mixedText}=await import('./studio-advanced-fixture.mjs');const text=mixedText(),root=shape('root','board',{children:[text]});const d=sandbox.P2R.exportSelection(api(root)).document;
 assert.equal(d.assets.length,0);assert.equal(d.design.children[0].text.runs.length,2);assert.equal(d.design.children[0].text.runs.map(r=>r.value).join(''),text.characters);assert.ok(d.design.children[0].text.runs[0].value.includes('😀'));
 text.getRange=()=>({fontFamily:'Arial',fontSize:'20',fontWeight:'400',letterSpacing:'2',fills:[{fillColor:'#FFFFFF'}]});text.letterSpacing='2';assert.ok(sandbox.P2R.exportSelection(api(root)).document.assets.length>0);
});
test('token catalogs preserve bindings, aliases, theme sets and unresolved definitions',async()=>{
 const {makeAdvanced,catalog}=await import('./studio-advanced-fixture.mjs');const d=makeAdvanced().document;
 assert.equal(d.tokens.sets[1].tokens[1].value,'{brand}');assert.equal(d.tokens.palettes.Default.accent.value,'#85B5FF');assert.equal(d.tokens.palettes['dark-theme'].accent.value,'#FFAA44');assert.equal(d.design.children[1].tokens.fill,'surface');
 const c=structuredClone(catalog);c.sets[0].tokens.push({id:'loop',name:'loop',type:'color',value:'{loop}'});const warnings=[];const out=sandbox.P2RTokens.exportCatalog(c,warnings);assert.equal(out.palettes.Default.loop,null);assert.match(warnings.join(' '),/unresolved/);
});

test('modern effects retain a compatibility image, complex effects stay rasterized',()=>{
 const effect=shape('effect','rectangle',{fills:[{fillColor:'#FFFFFF'}],borderRadiusTopRight:20,shadows:[{style:'drop-shadow',color:{color:'#000000',opacity:.4},blur:8}]});
 const root=shape('root','board',{children:[effect]});let d=sandbox.P2R.exportSelection(api(root)).document;
 assert.equal(d.design.children[0].nativeVisual,true);assert.equal(d.assets[0].fallback,true);
 effect.blur={value:5};d=sandbox.P2R.exportSelection(api(root)).document;assert.equal(d.design.children[0].nativeVisual,false);assert.equal(d.assets[0].fallback,false);
});

test('optional smoothing creates compact slice surfaces and leaves clipped containers intact',()=>{
 const item=shape('item','rectangle',{borderRadius:24,fills:[{fillColor:'#85B5FF'}]});const root=shape('root','board',{children:[item]});
 assert.equal(sandbox.P2R.exportSelection(api(root)).document.design.children[0].smooth,undefined);
 let d=sandbox.P2R.exportSelection(api(root),[root],{smoothing:.6}).document;assert.equal(d.assets[0].kind,'smooth');assert.ok(d.design.children[0].smooth.slice[2]>d.design.children[0].smooth.slice[0]);
 item.clipContent=true;item.children=[shape('child')];d=sandbox.P2R.exportSelection(api(root),[root],{smoothing:.6}).document;assert.equal(d.design.children[0].smooth,undefined);assert.match(d.warnings.join(' '),/Smooth corners skipped/);
 assert.throws(()=>sandbox.P2R.exportSelection(api(root),[root],{smoothing:2}),/smoothing/);
 for(const radii of [[0,0,0,0],[0,120,3,25],[24,24,24,24]])for(const smoothing of [0,.6,1]){const g=sandbox.P2RCorners.surface({radii,smoothing,fill:{color:'#FFFFFF',opacity:1}});assert.ok(g.width*2<=1024&&g.height*2<=1024);assert.doesNotMatch(g.svg,/NaN|Infinity/);assert.ok(g.slice[2]>g.slice[0]&&g.slice[3]>g.slice[1]);}
});

test('native layouts include justify, equal-gap wrapping and main-axis fill; unsafe cases keep measured geometry',()=>{
 const flex={dir:'row',wrap:'wrap',rowGap:10,columnGap:10,justifyContent:'start',alignContent:'start',alignItems:'start',topPadding:0,rightPadding:0,bottomPadding:0,leftPadding:0};
 const root=shape('root','board',{flex,children:[shape('child')]});const exp=()=>sandbox.P2R.exportSelection(api(root)).document.design;
 assert.equal(exp().layout.native,true);flex.rowGap=20;assert.equal(exp().layout.native,false);
 flex.wrap='nowrap';flex.justifyContent='space-between';assert.equal(exp().layout.native,true);
 root.children[0].layoutChild={horizontalSizing:'fill',verticalSizing:'fix'};assert.equal(exp().layout.native,true);
 root.children[0].layoutChild.verticalSizing='auto';assert.equal(exp().layout.native,false);
});
test('default opacity, persistent IDs, measured text and button semantics survive export',()=>{
 const root=shape('root','board',{children:[shape('text','text',{characters:'Hello',fontSize:'20',fontFamily:'Inter',fontWeight:'400',textBounds:{width:44,height:25}}),shape('cta','rectangle',{name:'Play [button]'})]});
 const {document:d}=sandbox.P2R.exportSelection(api(root));assert.equal(d.design.opacity,1);assert.equal(d.design.children[0].text.measuredWidth,44);assert.equal(d.design.children[1].button,true);assert.equal(d.source.rootId,'root');assert.equal(d.version,4);
});
test('text modes separate known substitutions, unknown fonts and complex typography',()=>{
 const text=shape('title','text',{characters:'Hello',fontSize:'20',fontFamily:'Inter',fontWeight:'400',textBounds:{width:44,height:25}});
 const root=shape('root','board',{children:[text]});
 const exportMode=textMode=>sandbox.P2R.exportSelection(api(root),[root],{textMode}).document;
 assert.equal(exportMode('auto').assets.length,0);assert.equal(exportMode('auto').design.children[0].text.robloxFamily,'BuilderSans');
 assert.equal(exportMode('exact').assets.length,1);assert.equal(exportMode('live').assets.length,0);
 text.fontFamily='Unknown Display';assert.equal(exportMode('auto').assets.length,1);assert.equal(exportMode('live').assets.length,0);
 text.letterSpacing=4;assert.equal(exportMode('live').assets.length,0);assert.match(exportMode('live').warnings.join(' '),/may differ/);
 text.shadows=[{hidden:false}];assert.equal(exportMode('live').assets.length,1,'visual effects still require a surface');
});
test('simple clipped opacity groups stay native but unsafe groups retain their surface',()=>{
 const group=shape('group','board',{opacity:.5,clipContent:true,children:[shape('child')]});const root=shape('root','board',{children:[group]});
 let d=sandbox.P2R.exportSelection(api(root)).document;assert.equal(d.assets.length,0);assert.equal(d.design.children[0].nativeGroup,true);assert.equal(d.design.children[0].children[0].visualSuppressed,false);
 d=sandbox.P2R.exportSelection(api(root),[root],{nativeGroups:false}).document;assert.equal(d.assets.length,1);
 group.clipContent=false;assert.equal(sandbox.P2R.exportSelection(api(root)).document.assets.length,1);
 group.clipContent=true;group.shadows=[{hidden:false}];assert.equal(sandbox.P2R.exportSelection(api(root)).document.assets.length,1);
});
test('behavior tags are opt-in, keep IDs, and resolve named/nearest panels',()=>{
 const close=shape('close','rectangle',{name:'Close [close]'}),panel=shape('panel','board',{name:'Shop [panel] [closed]',children:[close]});
 const root=shape('root','board',{children:[shape('open','rectangle',{name:'Open [open:Shop]'}),panel,shape('list','board',{name:'Items_scroll'})]});
 const off=sandbox.P2R.exportSelection(api(root)).document;assert.equal(off.design.children[0].button,false);assert.equal(off.design.children[1].name,'Shop [panel] [closed]');
 const d=sandbox.P2R.exportSelection(api(root),[root],{behaviors:true}).document;
 assert.equal(d.design.children[0].button,true);assert.equal(d.design.children[0].behavior.target,'Shop');assert.equal(d.design.children[1].initiallyClosed,true);assert.equal(d.design.children[1].children[0].behavior.target,'Shop');assert.equal(d.design.children[2].scroll,true);assert.equal(d.design.children[2].id,'list');
 root.children[0].name='Open [open:Missing]';assert.throws(()=>sandbox.P2R.exportSelection(api(root),[root],{behaviors:true}),/matching panel/);
});
test('ambiguous behaviors and rasterized scroll containers fail before import',()=>{
 const root=shape('root','board',{children:[shape('one','board',{name:'Shop [panel]'}),shape('two','board',{name:'Shop [panel]'})]});
 assert.throws(()=>sandbox.P2R.exportSelection(api(root),[root],{behaviors:true}),/Duplicate panel/);
 root.children=[shape('scroll','board',{name:'List [scroll]',shadows:[{hidden:false}]})];assert.throws(()=>sandbox.P2R.exportSelection(api(root),[root],{behaviors:true}),/native container/);
 root.children=[shape('orphan','rectangle',{name:'Close [close]'})];assert.throws(()=>sandbox.P2R.exportSelection(api(root),[root],{behaviors:true}),/matching panel/);
 root.children=[shape('bad','rectangle',{name:'Open [open:Shop Panel]'})];assert.throws(()=>sandbox.P2R.exportSelection(api(root),[root],{behaviors:true}),/malformed tag/);
});
test('rotated parent coordinates are inverted before local geometry is exported',()=>{
 const child=shape('child','rectangle',{width:10,height:10,center:{x:50,y:40},rotation:90});
 const root=shape('root','board',{width:100,height:100,center:{x:50,y:50},rotation:90,children:[child]});
 const n=sandbox.P2R.exportSelection(api(root)).document.design.children[0];assert.ok(Math.abs(n.x-35)<.001);assert.ok(Math.abs(n.y-45)<.001);assert.equal(n.rotation,0);
});
test('unsupported vector assets are identified and multiple selections are rejected',()=>{
 const root=shape('root','board',{children:[shape('vector','path')]});const d=sandbox.P2R.exportSelection(api(root)).document;assert.equal(d.assets.length,1);assert.equal(d.assets[0].key,'file:vector');assert.throws(()=>sandbox.P2R.exportSelection(api(root),[root,root]));
});
test('effects use individual image surfaces while preserving native button semantics',()=>{
 const root=shape('root','board',{children:[shape('cta','rectangle',{name:'Play [button]',shadows:[{hidden:false}],borderRadiusTopLeft:8,borderRadiusTopRight:16})]});
 const d=sandbox.P2R.exportSelection(api(root)).document,n=d.design.children[0];
 assert.equal(n.rasterSurface,true);assert.equal(n.button,true);assert.equal(d.assets[0].skipChildren,true);assert.match(d.assets[0].reason,/shadows/);
});
test('group opacity composites visuals and retains descendant geometry and controls',()=>{
 const root=shape('root','board',{children:[shape('group','group',{opacity:.5,children:[shape('cta','rectangle',{name:'Play [button]'})]})]});
 const d=sandbox.P2R.exportSelection(api(root)).document,n=d.design.children[0];
 assert.equal(n.rasterSubtree,true);assert.equal(d.assets[0].skipChildren,false);assert.equal(n.children[0].visualSuppressed,true);assert.equal(n.children[0].button,true);assert.equal(d.assets.length,1);
});
