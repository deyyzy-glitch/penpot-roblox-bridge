import vm from 'node:vm';
import {readFile} from 'node:fs/promises';
const context={};vm.createContext(context);for(const f of ['corners.js','exporter.js'])vm.runInContext(await readFile(new URL('../penpot/'+f,import.meta.url),'utf8'),context);
export function shape(id,type='rectangle',x=0,y=0,w=100,h=50,extra={}){return {id,type,name:id,width:w,height:h,center:{x:x+w/2,y:y+h/2},opacity:1,fills:[{fillColor:'#85B5FF',fillOpacity:1}],strokes:[],children:[],...extra}}
export const flex=(extra={})=>({dir:'row',wrap:'nowrap',alignItems:'start',justifyContent:'start',rowGap:10,columnGap:10,topPadding:10,rightPadding:10,bottomPadding:10,leftPadding:10,...extra});
export function makeFixture(smoothing=0){
 const row=shape('row','board',20,140,400,80,{flex:flex({justifyContent:'space-between'}),children:[shape('a','rectangle',30,150,80,40),shape('b','rectangle',330,150,80,40)]});
 const wrap=shape('wrap','board',20,240,220,140,{flex:flex({wrap:'wrap'}),children:[shape('w1','rectangle',30,250,90,40),shape('w2','rectangle',130,250,90,40),shape('w3','rectangle',30,300,90,40)]});
 const fill=shape('fill','board',260,240,300,80,{flex:flex(),children:[shape('fixed','rectangle',270,250,80,40),shape('grow','rectangle',360,250,190,40,{layoutChild:{horizontalSizing:'fill',verticalSizing:'fix'}})]});
 const root=shape('quality','board',0,0,800,600,{children:[shape('effects','rectangle',20,20,240,90,{borderRadiusTopLeft:0,borderRadiusTopRight:24,borderRadiusBottomRight:12,borderRadiusBottomLeft:6,shadows:[{style:'drop-shadow',offsetX:4,offsetY:6,blur:10,spread:2,color:{color:'#000000',opacity:.4}}]}),row,wrap,fill,shape('smooth','rectangle',300,20,200,90,{borderRadius:24}),shape('font','text',20,420,200,40,{characters:'Hello',fontFamily:'Inter',fontWeight:400,fontSize:20,textBounds:{width:44,height:25}}),shape('art','path',520,20,50,50)]});
 const api={selection:[root],currentFile:{id:'quality-test'},currentPage:{id:'page'}};
 return context.P2R.exportSelection(api,[root],{smoothing});
}
export const document=makeFixture(.6).document;
