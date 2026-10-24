import vm from 'node:vm';
import {readFile} from 'node:fs/promises';
const context={};vm.createContext(context);vm.runInContext(await readFile(new URL('../penpot/exporter.js',import.meta.url),'utf8'),context);
function shape(id,type,name,x,y,width,height,extra={}){return {id,type,name,width,height,center:{x:x+width/2,y:y+height/2},fills:[{fillColor:'#273C75',fillOpacity:1}],strokes:[],children:[],...extra}}
const close=shape('close','rectangle','Close [close]',270,116,80,40);
const panel=shape('shop','board','Shop [panel] [closed]',30,100,340,240,{clipContent:true,opacity:.6,children:[close]});
const scroll=shape('inventory','board','Inventory [scroll]',430,100,300,200,{clipContent:true,children:[0,1,2,3].map(i=>shape('item'+i,'rectangle','Item '+i,442,112+i*80,260,68))});
const root=shape('features','board','Penpot Bridge Feature Tests',0,0,800,560,{clipContent:true,children:[shape('open','rectangle','Open shop [open:Shop]',30,30,180,48),panel,scroll,shape('label','text','Editable heading',30,390,360,40,{characters:'Editable Inter heading',fontSize:'24',fontFamily:'Inter',fontWeight:400,textBounds:{width:240,height:30}})]});
const api={selection:[root],currentFile:{id:'feature-test'},currentPage:{id:'page'}};
export const document=context.P2R.exportSelection(api,[root],{textMode:'auto',behaviors:true,nativeGroups:true}).document;
