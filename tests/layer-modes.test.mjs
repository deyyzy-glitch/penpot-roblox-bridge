import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import vm from 'node:vm';
const context={};vm.createContext(context);for(const f of ['corners.js','tokens.js','exporter.js'])vm.runInContext(await readFile(new URL('../penpot/'+f,import.meta.url),'utf8'),context);
const shape=(id,type='rectangle',extra={})=>({id,name:id,type,width:100,height:50,center:{x:50,y:25},opacity:1,children:[],fills:[{fillColor:'#85B5FF'}],strokes:[],...extra});
const api=root=>({currentFile:{id:'file'},currentPage:{id:'page'},selection:[root]});
const exportDoc=(root,rules={},options={})=>context.P2R.exportSelection(api(root),[root],{tokens:false,layerRules:Object.fromEntries(Object.entries(rules).map(([id,r])=>['file:'+id,r])),...options}).document;
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
