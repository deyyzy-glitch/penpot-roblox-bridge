import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import vm from 'node:vm';
const sandbox={};vm.createContext(sandbox);for(const f of ['corners.js','tokens.js','exporter.js'])vm.runInContext(await readFile(new URL('../penpot/'+f,import.meta.url),'utf8'),sandbox);
function shape(id,type='rectangle',extra={}){return {id,type,name:id,width:100,height:50,center:{x:50,y:25},opacity:null,fills:[],strokes:[],children:[],...extra}}
const api=root=>({selection:[root],currentFile:{id:'file'},currentPage:{id:'page'}});

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
