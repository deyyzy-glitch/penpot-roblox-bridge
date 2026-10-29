import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import vm from 'node:vm';
const context={};vm.createContext(context);for(const f of ['corners.js','tokens.js','exporter.js'])vm.runInContext(await readFile(new URL('../penpot/'+f,import.meta.url),'utf8'),context);
const shape=(id,type='rectangle',extra={})=>({id,name:id,type,width:100,height:50,center:{x:50,y:25},opacity:1,children:[],fills:[{fillColor:'#85B5FF'}],strokes:[],...extra});
const api=root=>({currentFile:{id:'file'},currentPage:{id:'page'},selection:[root]});
const exportDoc=(root,rules={},options={})=>context.P2R.exportSelection(api(root),[root],{tokens:false,layerRules:Object.fromEntries(Object.entries(rules).map(([id,r])=>['file:'+id,r])),...options}).document;

const textLayer=()=>shape('stats','text',{characters:'0.58s | Luck 2.5',fontFamily:'Nunito',fontSize:9,fontWeight:700,textBounds:{width:65.03125,height:12}});
test('button names remain unchanged until an explicit choice, which uses the existing button contract',()=>{
 const s=shape('buy','rectangle',{name:'BuyButton'}),before=JSON.stringify(s);assert.equal(exportDoc(s).design.button,false);
 const d=exportDoc(s,{buy:{button:true,ref:'Buy'}});assert.equal(d.design.button,true);assert.equal(d.design.name,'BuyButton');assert.equal(d.design.ref,'Buy');assert.equal(d.version,5);assert.equal(JSON.stringify(s),before);assert.equal(exportDoc(s).design.button,false);
 assert.equal(exportDoc(s,{}, {layerRules:{'other:buy':{button:true}}}).design.button,false);assert.throws(()=>exportDoc(s,{buy:{button:'true'}}),/must be a boolean/);
});
test('button choices respect conversion modes, ancestor artwork and explicit scrolling',()=>{
 for(const mode of ['image','layout']){const d=exportDoc(shape('buy'),{buy:{mode,button:true}});assert.equal(d.design.button,false);assert.match(d.warnings.join(' '),/button control choice is inactive/)}
 const root=shape('root','group',{children:[shape('buy')]});const d=exportDoc(root,{root:{mode:'image'},buy:{button:true}});assert.equal(d.design.children[0].button,false);
 const scroll=exportDoc(shape('buy','group',{name:'Buy [scroll]'}),{buy:{button:true}},{behaviors:true});assert.equal(scroll.design.scroll,true);assert.equal(scroll.design.button,false);
 const button=exportDoc(shape('buy','rectangle',{name:'Buy [button]'}),{buy:{button:true}},{behaviors:true});assert.equal(button.design.button,true);
});
test('explicit native font weights preserve the Penpot source and clear back to its original weight',()=>{
 const s=textLayer(),before=JSON.stringify(s);const original=exportDoc(s);assert.equal(original.design.text.weight,700);assert.equal(original.design.text.weightOverride,undefined);
 const d=exportDoc(s,{stats:{fontWeight:800}});assert.equal(d.design.text.weight,800);assert.equal(d.design.text.sourceWeight,700);assert.equal(d.assets.length,0);assert.equal(d.version,5);assert.match(d.warnings.join(' '),/Explicit native font weight/);
 assert.equal(JSON.stringify(s),before);assert.equal(exportDoc(s).design.text.weight,700);
 assert.equal(exportDoc(s,{}, {layerRules:{'other:stats':{fontWeight:900}}}).design.text.weight,700);
 assert.equal(context.P2R.describeSelection(api(s)).layers[0].sourceWeight,700);
});

test('weight choices cover RichText runs and take precedence over font-weight tokens',async()=>{
 const {mixedText}=await import('./studio-advanced-fixture.mjs');const s=mixedText();s.id='stats';s.tokens={fontWeight:'weight.body',fill:'text.color'};
 const before=JSON.stringify(s),source=exportDoc(s),d=exportDoc(s,{stats:{fontWeight:800}},{tokens:true});
 assert.ok(d.design.text.runs.length>1);for(let i=0;i<d.design.text.runs.length;i++){assert.equal(d.design.text.runs[i].weight,800);assert.equal(d.design.text.runs[i].sourceWeight,source.design.text.runs[i].weight)}
 assert.equal(d.design.tokens.fontWeight,undefined);assert.equal(d.design.tokens.fill,'text.color');assert.match(d.warnings.join(' '),/token binding skipped/);assert.equal(JSON.stringify(s),before);
});

test('image and covered text retain their original appearance despite a saved weight choice',()=>{
 const d=exportDoc(textLayer(),{stats:{mode:'image',fontWeight:800}});assert.equal(d.design.text.weight,700);assert.equal(d.design.text.weightOverride,undefined);assert.equal(d.assets.length,1);assert.match(d.warnings.join(' '),/override is inactive/);
 const root=shape('root','group',{children:[textLayer()]});const covered=exportDoc(root,{root:{mode:'image'},stats:{fontWeight:800}});assert.equal(covered.design.children[0].text.weight,700);assert.equal(covered.design.children[0].visualSuppressed,true);
});

test('invalid weights and rules on non-text layers fail before export',()=>{
 for(const fontWeight of [0,99,150,1000,'800',NaN])assert.throws(()=>exportDoc(textLayer(),{stats:{fontWeight}}),/font weight override/);
 assert.throws(()=>exportDoc(shape('panel'),{panel:{fontWeight:800}}),/text layer/);
});
test('layer listing is read-only and export overrides are scoped to the source file',()=>{
 const root=shape('root','board',{children:[shape('child')]});const before=JSON.stringify(root);
 const list=context.P2R.describeSelection(api(root));assert.equal(list.layers[1].depth,1);assert.equal(list.fileId,'file');assert.equal(JSON.stringify(root),before);
 const d=exportDoc(root,{}, {layerRules:{'other:child':{mode:'skip'}}});assert.equal(d.version,4);assert.equal(d.design.children.length,1);
});
test('Image forces a composited surface and keeps covered source geometry',()=>{
 const root=shape('root','board',{children:[shape('child')]});const d=exportDoc(root,{root:{mode:'image'}});
 assert.equal(d.version,5);assert.equal(d.assets.length,1);assert.equal(d.design.rasterSubtree,true);assert.equal(d.design.nativeVisual,false);
 assert.equal(d.design.children[0].visualSuppressed,true);assert.equal(d.assets[0].skipChildren,false);
});
test('Layout only omits its own effects and retains visible children',()=>{
 const root=shape('root','board',{opacity:.3,shadows:[{style:'drop-shadow'}],children:[shape('child')]});const d=exportDoc(root,{root:{mode:'layout'}});
 assert.equal(d.design.visualSuppressed,true);assert.equal(d.design.opacity,1);assert.equal(d.design.children[0].visualSuppressed,false);assert.equal(d.assets.length,0);
});
test('Skip removes a subtree and records explicit IDs for safe retirement',()=>{
 const root=shape('root','board',{children:[shape('skip','group',{children:[shape('nested')]}),shape('keep')]});const d=exportDoc(root,{skip:{mode:'skip'}});
 assert.deepEqual([...d.excludedIds],['skip','nested']);assert.equal(d.design.children.length,1);assert.equal(d.design.children[0].id,'keep');
 assert.throws(()=>exportDoc(root,{root:{mode:'skip'}}),/root selection cannot be skipped/);
});
test('Native rejects unsupported geometry and reports editable font substitution',()=>{
 assert.throws(()=>exportDoc(shape('v','path'),{v:{mode:'native'}}),/Native mode cannot preserve vector/);
 assert.throws(()=>exportDoc(shape('v','rectangle',{blur:{value:3}}),{v:{mode:'native'}}),/cannot preserve blur/);
 const root=shape('text','text',{characters:'Test',fontFamily:'Unknown',fontSize:20,textBounds:{width:40,height:25}});
 const d=exportDoc(root,{text:{mode:'native'}});assert.equal(d.assets.length,0);assert.match(d.warnings.join(' '),/Editable font substitution/);
});
test('template layers carry a key, omit children and do not request image uploads',()=>{
 const root=shape('root','board',{children:[shape('slot','group',{children:[shape('vector','path')]})]});const d=exportDoc(root,{slot:{mode:'template',template:'PrimaryButton',ref:'UpgradeButton'}});
 assert.equal(d.design.children[0].template,'PrimaryButton');assert.equal(d.design.children[0].ref,'UpgradeButton');assert.equal(d.design.children[0].children.length,0);assert.equal(d.assets.length,0);assert.equal(d.version,5);
});
test('aliases and template keys reject malformed or ambiguous names before export',()=>{
 const root=shape('root','board',{children:[shape('a'),shape('b')]});
 assert.throws(()=>exportDoc(root,{a:{ref:'Same'},b:{ref:'Same'}}),/Duplicate gameplay reference/);
 assert.throws(()=>exportDoc(root,{a:{ref:'x; print(1)'}}),/identifier/);
 assert.throws(()=>exportDoc(root,{a:{mode:'template',template:'../Secret'}}),/template key/);
 assert.throws(()=>exportDoc(root,{a:{mode:'unknown'}}),/invalid layer import mode/);
});
test('advanced gradient shapes retain image fallbacks despite writable native type enums',()=>{
 const g={type:'radial',startX:.5,startY:.5,endX:1,endY:.5,stops:[{offset:0,color:'#FF0000'},{offset:1,color:'#0000FF'}]};
 const d=exportDoc(shape('radial','rectangle',{fills:[{fillColorGradient:g}]}));assert.equal(d.assets.length,1);assert.equal(d.design.nativeVisual,false);assert.equal(d.design.rasterSurface,true);
 assert.throws(()=>exportDoc(shape('radial','rectangle',{fills:[{fillColorGradient:g}]}),{radial:{mode:'native'}}),/gradient geometry/);
});
