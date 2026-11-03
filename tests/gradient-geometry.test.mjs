import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import vm from 'node:vm';
const context={};vm.createContext(context);
for(const file of ['corners.js','tokens.js','exporter.js'])vm.runInContext(await readFile(new URL('../penpot/'+file,import.meta.url),'utf8'),context);
const stops=[{offset:0,color:'#FF0000',opacity:.25},{offset:1,color:'#0000FF',opacity:1}];
const linear={type:'linear',startX:.2,startY:.2,endX:.8,endY:.8,width:1,stops};
const radial={type:'radial',startX:.5,startY:.5,endX:1,endY:.5,width:1,stops};
const near=(a,b)=>assert.ok(Math.abs(a-b)<1e-6,`${a} != ${b}`);
function document(g,options={}){
 const shape={id:'gradient',name:'Gradient',type:'rectangle',width:192,height:160,center:{x:96,y:80},fills:[{fillColorGradient:g,fillOpacity:1}],strokes:[],children:[]};
 return context.P2R.exportSelection({currentFile:{id:'fixture'},currentPage:{id:'page'},selection:[shape]},[shape],{tokens:false,...options}).document;
}
test('linear geometry maps normalized SVG coordinates into pixel-space normals and clipped spans',()=>{
 const p=context.P2R.gradientGeometry(linear,192,160);assert.equal(p.type,'Linear');near(p.rotation,Math.atan2(.6/160,.6/192)*180/Math.PI);near(p.scale,.7081967213114755);
 const reverse=context.P2R.gradientGeometry({...linear,startX:.8,startY:.7,endX:.15,endY:.3},192,160);assert.ok(reverse.rotation<0);near(reverse.offset[0],-.025);near(reverse.offset[1],0);
 const vertical=context.P2R.gradientGeometry({...linear,startX:.3,startY:.1,endX:.3,endY:.9},192,160);near(vertical.scale,.8);near(vertical.rotation,90);near(vertical.offset[0],-.2);
 const outside=context.P2R.gradientGeometry({...linear,startX:-1,startY:.5,endX:2,endY:.5},192,160);near(outside.scale,3);
});
test('radial geometry distinguishes bounding-box ellipses, physical circles and unsupported proportions',()=>{
 const p=context.P2R.gradientGeometry(radial,192,160);assert.equal(p.type,'Elliptical');near(p.scale,1);near(p.rotation,0);
 const circle=context.P2R.gradientGeometry({...radial,width:1.2},192,160);assert.equal(circle.type,'Radial');near(circle.scale,96/88);
 const shifted=context.P2R.gradientGeometry({...radial,startX:.3,startY:.4,endX:.65,endY:.7},192,160);assert.equal(shifted.type,'Elliptical');near(shifted.offset[0],-.2);near(shifted.offset[1],-.1);
 const tall=context.P2R.gradientGeometry(radial,160,192);assert.equal(tall.type,'Elliptical');near(tall.rotation,0);
 assert.equal(context.P2R.gradientGeometry({...radial,width:.5},192,160),null);
});
test('degenerate geometry and unrepresentable stop budgets choose images without mutating the design',()=>{
 for(const g of [{...linear,endX:.2,endY:.2},{...radial,width:0},{...radial,width:-1},{...radial,width:NaN},{...linear,endX:.20000001,endY:.20000001},{...linear,stops:Array.from({length:20},(_,i)=>({offset:(i+1)/21,color:'#FFFFFF'}))}]){
  assert.equal(document(g).assets.length,1);
 }
 const before=JSON.stringify(radial);const d=document(radial);assert.equal(d.version,6);assert.equal(d.assets.length,0);assert.equal(d.design.upgradedGradient,true);assert.equal(JSON.stringify(radial),before);
 const image=document(radial,{layerRules:{'fixture:gradient':{mode:'image'}}});assert.equal(image.assets.length,1);assert.equal(image.design.upgradedGradient,undefined);
});
test('new gradient routing coexists with layer controls and does not upgrade unrelated exports',()=>{
 const d=document(radial,{layerRules:{'fixture:gradient':{mode:'native',ref:'Panel'}}});assert.equal(d.version,6);assert.equal(d.design.ref,'Panel');assert.deepEqual([...d.excludedIds],[]);
 assert.equal(document({...radial,width:.5}).version,4);
});
test('hard stops and more than twenty authored stops retain image conversion',()=>{
 for(const custom of [[{offset:0,color:'#FF0000'},{offset:.5,color:'#FF0000'},{offset:.5,color:'#0000FF'},{offset:1,color:'#0000FF'}],Array.from({length:25},(_,i)=>({offset:i/24,color:'#FF0000'}))]){
  const d=document({...linear,stops:custom});assert.equal(d.assets.length,1);assert.equal(d.design.upgradedGradient,undefined);assert.equal(d.design.fills[0].fillColorGradient.stops.length,custom.length);
 }
});
