import vm from 'node:vm';
import {readFile} from 'node:fs/promises';
const context={};vm.createContext(context);
for(const f of ['corners.js','tokens.js','exporter.js'])vm.runInContext(await readFile(new URL('../penpot/'+f,import.meta.url),'utf8'),context);
const shape=(id,type,x,y,width,height,extra={})=>({id,name:id,type,width,height,center:{x:x+width/2,y:y+height/2},opacity:1,fills:[{fillColor:'#85B5FF'}],strokes:[],children:[],...extra});
const root=shape('verify-board','board',0,0,600,400,{children:[
 shape('title','text',20,20,240,40,{characters:'Verification example',fontFamily:'Fredoka',fontSize:20,fontWeight:400,textBounds:{width:190,height:26}}),
 shape('left','rectangle',20,100,100,80),shape('right','rectangle',180,100,100,80),
 shape('overlay','rectangle',30,110,60,50),
 shape('icon','path',350,100,32,32)
]});
export const document=context.P2R.exportSelection({currentFile:{id:'verifier-fixture'},currentPage:{id:'page'},selection:[root]},[root],{tokens:false}).document;
document.assetMap[document.assets[0].key]='rbxassetid://0';
