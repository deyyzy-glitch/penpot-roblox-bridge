import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import vm from 'node:vm';
const source=await readFile(new URL('../penpot/ui.js',import.meta.url),'utf8');
async function companion(){
 const elements=new Map(),timers=new Map(),sent=[];let nextTimer=0,onMessage;
 const get=id=>{if(!elements.has(id))elements.set(id,{disabled:false,checked:true,value:id==='text-mode'?'auto':'0',textContent:'',querySelectorAll:()=>[]});return elements.get(id)};
 const parent={postMessage:m=>sent.push(m)},origin='https://design.penpot.app';
 const context={URL,AbortController,console,document:{referrer:origin+'/',getElementById:get},parent,
  localStorage:{getItem:()=>null,setItem(){}},window:{addEventListener:(type,handler)=>{if(type==='message')onMessage=handler}},
  setTimeout:(fn,delay)=>{timers.set(++nextTimer,{fn,delay});return nextTimer},clearTimeout:id=>timers.delete(id),
  fetch:async path=>({ok:true,json:async()=>path==='/session'?{token:'test-token'}:{configured:false}})};
 vm.createContext(context);vm.runInContext(source,context);
 await new Promise(resolve=>setImmediate(resolve));
 return {get,sent,timers,
  message:async data=>onMessage({source:parent,origin,data}),
  expire:delay=>{const entry=[...timers].find(([,t])=>t.delay===delay);assert.ok(entry,'expected timer '+delay);timers.delete(entry[0]);entry[1].fn()}};
}
const design={design:{name:'Test',width:100,height:100,children:[]},assets:[],warnings:[]};
test('missing plugin response unlocks Prepare and ignores late replies; retry succeeds',async()=>{
 const c=await companion();c.get('export').onclick();const oldId=c.sent.at(-1).requestId;
 assert.equal(c.get('export').disabled,true);c.expire(15000);
 assert.equal(c.get('export').disabled,false);assert.match(c.get('status').textContent,/No response while Reading/);
 await c.message({type:'document',requestId:oldId,document:design});assert.equal(c.get('send').disabled,true);
 c.get('export').onclick();const newId=c.sent.at(-1).requestId;assert.notEqual(oldId,newId);
 await c.message({type:'document',requestId:newId,document:design});assert.equal(c.get('send').disabled,false);
 await c.message({type:'error',requestId:oldId,message:'Old export failed'});assert.equal(c.get('send').disabled,false);
 assert.equal(c.timers.size,0);
});
test('95-surface export shows the active layer and stops if progress ceases',async()=>{
 const c=await companion();c.get('export').onclick();const requestId=c.sent.at(-1).requestId;
 await c.message({type:'document',requestId,document:{...design,assets:Array.from({length:95},()=>({}))}});
 assert.match(c.get('status').textContent,/Rendering 95/);
 await c.message({type:'progress',requestId,message:'Exporting 18 of 95: Badge (PNG)'});
 assert.equal(c.get('status').textContent,'Exporting 18 of 95: Badge (PNG)');
 c.expire(45000);assert.equal(c.get('export').disabled,false);assert.equal(c.get('send').disabled,true);
 assert.match(c.get('status').textContent,/No response while Exporting 18 of 95: Badge \(PNG\)/);
});
