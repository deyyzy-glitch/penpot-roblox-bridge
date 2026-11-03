import {readFile} from 'node:fs/promises';
import vm from 'node:vm';
const context={};vm.createContext(context);
for(const name of ['corners.js','tokens.js','exporter.js'])vm.runInContext(await readFile(new URL('../penpot/'+name,import.meta.url),'utf8'),context);
const stops=[{offset:0,color:'#FF0000',opacity:1},{offset:1,color:'#0000FF',opacity:1}];
const specs=[
 ['Linear','linear',0,.5,1,.5,1],['Radial','radial',.5,.5,1,.5,1],['Narrow radial','radial',.5,.5,1,.5,.5],
 ['Short diagonal','linear',.2,.2,.8,.8,1],['Shifted reversed','linear',.8,.7,.15,.3,1],['Offset ellipse','radial',.3,.4,.65,.7,1],['Pixel circle','radial',.5,.5,1,.5,1.2]
];
const children=specs.map(([name,type,startX,startY,endX,endY,width],i)=>{
 const col=i<3?i:i-3,y=i<3?60:250,x=12+col*204;
 return {id:'gradient-'+i,name,type:'rectangle',width:192,height:160,center:{x:x+96,y:y+80},fills:[{fillOpacity:1,fillColorGradient:{type,startX,startY,endX,endY,width,stops}}],strokes:[],children:[]};
});
const root={id:'gradient-fixture',name:'Gradient release fixture',type:'board',width:820,height:640,center:{x:410,y:320},fills:[{fillColor:'#1E1E1E'}],strokes:[],children};
export const document=context.P2R.exportSelection({currentFile:{id:'gradient-tests'},currentPage:{id:'page'},selection:[root]},[root],{tokens:false}).document;
