import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import vm from 'node:vm';
const sandbox={};vm.createContext(sandbox);vm.runInContext(await readFile(new URL('../penpot/exporter.js',import.meta.url),'utf8'),sandbox);
function shape(id,type='rectangle',extra={}){return {id,type,name:id,width:100,height:50,center:{x:50,y:25},opacity:null,fills:[],strokes:[],children:[],...extra}}
const api=root=>({selection:[root],currentFile:{id:'file'},currentPage:{id:'page'}});
test('default opacity, persistent IDs, measured text and button semantics survive export',()=>{
 const root=shape('root','board',{children:[shape('text','text',{characters:'Hello',fontSize:'20',fontFamily:'Inter',fontWeight:'400',textBounds:{width:44,height:25}}),shape('cta','rectangle',{name:'Play [button]'})]});
 const {document:d}=sandbox.P2R.exportSelection(api(root));assert.equal(d.design.opacity,1);assert.equal(d.design.children[0].text.measuredWidth,44);assert.equal(d.design.children[1].button,true);assert.equal(d.source.rootId,'root');assert.equal(d.version,1);
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
