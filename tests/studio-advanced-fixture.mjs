import vm from 'node:vm';
import {readFile} from 'node:fs/promises';
const context={};vm.createContext(context);for(const f of ['corners.js','tokens.js','exporter.js'])vm.runInContext(await readFile(new URL('../penpot/'+f,import.meta.url),'utf8'),context);
const token=(id,name,type,value)=>({id,name,type,value,resolvedValue:value});
export const catalog={sets:[{id:'base',name:'Base',active:true,tokens:[token('b','brand','color','#85B5FF'),token('s','space','spacing','12'),token('r','radius','borderRadius','14')]},{id:'light',name:'Light',active:true,tokens:[token('bg','surface','color','#FFFFFF'),token('accent','accent','color','{brand}')]},{id:'dark',name:'Dark',active:false,tokens:[token('bg2','surface','color','#182030'),token('accent2','accent','color','#FFAA44')]}],themes:[{id:'light-theme',name:'Light',group:'Color',active:true,activeSets:[{id:'light'}]},{id:'dark-theme',name:'Dark',group:'Color',active:false,activeSets:[{id:'dark'}]}]};
const shape=(id,type,x,y,w,h,extra={})=>({id,name:id,type,width:w,height:h,center:{x:x+w/2,y:y+h/2},opacity:1,children:[],fills:[{fillColor:'#FFFFFF',fillOpacity:1}],strokes:[],...extra});
export function mixedText(){
 const value='Sword <Value> & 😀: $125,000 (+25%)',split=value.indexOf('$');
 const style=index=>({fontFamily:'Arial',fontSize:index<split?'20':'26',fontWeight:index<split?'400':'700',fontStyle:'normal',textDecoration:index<split?'none':'underline',textTransform:'none',direction:'ltr',align:'left',lineHeight:'1.2',letterSpacing:'0',fills:[{fillColor:index<split?'#29334D':'#22AA66',fillOpacity:1}]});
 return shape('rich','text',20,20,580,80,{characters:value,fontFamily:'mixed',fontSize:'mixed',fontWeight:'mixed',fontStyle:'mixed',fills:'mixed',textBounds:{width:500,height:40},getRange(start,end){const styles=Array.from({length:end-start},(_,i)=>style(start+i));if(!styles.length)return style(start);return styles.every(s=>JSON.stringify(s)===JSON.stringify(styles[0]))?styles[0]:{...styles[0],fontSize:'mixed',fontWeight:'mixed',fills:'mixed'}}});
}
export function makeAdvanced(){
 const root=shape('advanced','board',0,0,800,560,{children:[mixedText(),shape('panel','rectangle',20,140,300,160,{fills:[{fillColor:'#FFFFFF',fillOpacity:1}],borderRadius:14,tokens:{fill:'surface',borderRadiusTopLeft:'radius',borderRadiusTopRight:'radius',borderRadiusBottomRight:'radius',borderRadiusBottomLeft:'radius'}}),shape('icon','path',360,140,100,100,{tokens:{fill:'accent'}})]});
 const api={selection:[root],currentFile:{id:'advanced-test'},currentPage:{id:'page'},library:{local:{tokens:catalog}}};const bundle=context.P2R.exportSelection(api,[root],{runtimeThemes:true});return bundle;
}
export const document=makeAdvanced().document;
const icon=document.design.children[2];icon.tintColor='#85B5FF';icon.rasterBounds={x:0,y:0,width:100,height:100};icon.slice={rect:[10,10,190,190],scale:.5};icon.glow={key:'advanced-test:icon:glow',color:'#85B5FF',opacity:.7,bounds:{x:-20,y:-20,width:140,height:140}};document.assets.push({key:icon.glow.key,shapeId:'icon',name:'Icon glow'});
