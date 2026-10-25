import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import vm from 'node:vm';
const load=async name=>JSON.parse(await readFile(new URL('./fixtures/real/'+name+'.json',import.meta.url),'utf8'));
const flatten=n=>[n,...n.children.flatMap(flatten)];
const sandbox={};vm.createContext(sandbox);
for(const f of ['corners.js','tokens.js','exporter.js'])vm.runInContext(await readFile(new URL('../penpot/'+f,import.meta.url),'utf8'),sandbox);
test('captured real panel retains Fredoka typography and mixed native/image routing',async()=>{
 const d=await load('mine-panel'),nodes=flatten(d.design),texts=nodes.filter(n=>n.text);
 assert.equal(nodes.length,17);assert.equal(texts.length,8);assert.equal(d.assets.length,3);
 assert.equal(d.design.width,660);assert.equal(d.design.height,150);
 for(const n of texts){assert.equal(n.text.family,'Fredoka');assert.equal(n.text.robloxFamily,'FredokaOne');assert.equal(n.assetKey,undefined)}
 assert.equal(texts.find(n=>n.name==='Runs started value').text.value,'11');
 assert.ok(nodes.some(n=>n.type==='path'&&n.assetKey));assert.ok(nodes.some(n=>n.type==='rectangle'&&n.assetKey));
});
test('captured native text values replay through the current exporter font policy',async()=>{
 const d=await load('mine-panel');
 for(const n of flatten(d.design).filter(n=>n.text)){
  const t=n.text,s={id:n.id,name:n.name,type:'text',width:n.width,height:n.height,center:{x:n.width/2,y:n.height/2},opacity:n.opacity,children:[],fills:n.fills,strokes:n.strokes,characters:t.value,fontFamily:t.family,fontSize:t.size,fontWeight:t.weight,fontStyle:t.italic?'italic':'normal',align:t.align,verticalAlign:t.verticalAlign,lineHeight:t.lineHeight,letterSpacing:t.letterSpacing,textBounds:{width:t.measuredWidth,height:t.measuredHeight}};
  const doc=sandbox.P2R.exportSelection({currentFile:{id:'replay'},currentPage:{id:'page'},selection:[s]},[s],{tokens:false}).document;
  assert.equal(doc.design.text.robloxFamily,'FredokaOne');assert.equal(doc.design.text.value,t.value);assert.equal(doc.design.width,n.width);assert.equal(doc.assets.length,0);
 }
});
test('captured SVG export preserves local raster padding, omitted definitions and tint',async()=>{
 const d=await load('svg-chart'),nodes=flatten(d.design);
 assert.equal(nodes.length,8);assert.equal(d.assets.length,5);
 assert.equal(nodes.find(n=>n.name==='svg-defs').assetKey,undefined);
 const bars=nodes.filter(n=>n.type==='rectangle'&&n.rasterSurface);
 assert.equal(bars.length,3);assert.deepEqual(bars[0].rasterBounds,{x:-2,y:-2,width:19,height:25});
 const thin=nodes.find(n=>n.height===.01);assert.ok(thin.rasterBounds.height>6);assert.equal(thin.tintColor,'#044895');
});
test('captured machine icon retains fractional nested geometry and stroke padding',async()=>{
 const d=await load('machine-icon'),nodes=flatten(d.design),icon=nodes.find(n=>n.name==='Molder cartoon machine icon'),circle=nodes.find(n=>n.name.includes('circular icon background'));
 assert.ok(Math.abs(icon.x-12.8)<1e-6);assert.ok(Math.abs(icon.width-26.4)<1e-6);assert.ok(Math.abs(circle.width-35.2)<1e-6);
 const group=icon.children.find(n=>n.name==='svg-g');assert.equal(group.x,4.125);assert.ok(group.children.every(n=>n.rasterBounds.x<0));
});

test('real fixtures are standalone and contain no original IDs, uploaded IDs or pixels',async()=>{
 for(const name of ['mine-panel','svg-chart','machine-icon']){
  const d=await load(name),nodes=flatten(d.design),ids=new Set(nodes.map(n=>n.id));
  assert.equal(ids.size,nodes.length);assert.equal(d.source.rootId,d.design.id);
  for(const a of d.assets){assert.ok(ids.has(a.shapeId));assert.ok(nodes.some(n=>n.assetKey===a.key));assert.equal(d.assetMap[a.key],'rbxassetid://0');assert.equal(a.bytes,undefined);assert.equal(a.contentHash,undefined)}
  assert.doesNotMatch(JSON.stringify(d),/[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}|rbxassetid:\/\/[1-9]|Bearer |api[-_]?key|base64|"pixels"/i);
 }
});
