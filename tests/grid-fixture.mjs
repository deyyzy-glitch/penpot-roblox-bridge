import vm from 'node:vm';
import {readFile} from 'node:fs/promises';
const context={};vm.createContext(context);
for(const f of ['corners.js','tokens.js','exporter.js'])vm.runInContext(await readFile(new URL('../penpot/'+f,import.meta.url),'utf8'),context);
const shape=(id,x,y,width,height,extra={})=>({id,name:id,type:'rectangle',width,height,center:{x:x+width/2,y:y+height/2},opacity:1,fills:[{fillColor:'#85B5FF'}],strokes:[],children:[],...extra});
export function makeGrid(dir='row'){
 const cells=Array.from({length:5},(_,i)=>shape('slot-'+i,12+(dir==='row'?i%3:Math.floor(i/2))*72,12+(dir==='row'?Math.floor(i/3):i%2)*58,64,48));
 // Paint order deliberately differs from grid flow order.
 const root=shape('inventory',0,0,232,130,{type:'board',grid:{dir,columns:[{},{},{}],rows:[{},{}],columnGap:8,rowGap:10,topPadding:12,rightPadding:12,bottomPadding:12,leftPadding:12},children:[cells[4],cells[2],cells[0],cells[3],cells[1]]});
 const api={currentFile:{id:'grid-regression'},currentPage:{id:'page'},selection:[root]};
 return {root,export:()=>context.P2R.exportSelection(api,[root],{tokens:false}).document};
}
export const document=makeGrid().export();
