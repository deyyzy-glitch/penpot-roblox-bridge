import test from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import {readFile} from 'node:fs/promises';
const source=await readFile(new URL('../penpot/layer-editor.js',import.meta.url),'utf8');
function editor(saved=null){
 const nodes=new Map(),sent=[],stored=new Map(saved?[['penpot-bridge-layer-rules-v1',saved]]:[]);let dirty=0;
 const make=tag=>({tag,style:{},children:[],value:'',appendChild(c){this.children.push(c);return c},replaceChildren(){this.children=[]},querySelectorAll(){const all=[];const visit=n=>{for(const c of n.children){if(['input','select'].includes(c.tag))all.push(c);visit(c)}};visit(this);return all}});
 const get=id=>{if(!nodes.has(id))nodes.set(id,make('div'));return nodes.get(id)};
 const context={structuredClone,document:{getElementById:get,createElement:make},localStorage:{getItem:k=>stored.get(k)||null,setItem:(k,v)=>stored.set(k,v)}};
 vm.createContext(context);vm.runInContext(source,context);
 const api=context.P2RLayerEditor.create({post:(type,options,requestId)=>sent.push({type,requestId}),invalidate:()=>dirty++,status(){}});
 return {api,get,sent,stored,dirty:()=>dirty,load(fileId='file',name='Upgrade <button>',type='rectangle'){get('layers-load').onclick();return api.onMessage({type:'layer-list',requestId:sent.at(-1).requestId,fileId,layers:[{id:'button',name,type,depth:1,...(type==='text'?{sourceWeight:700}:{})}]})}};
}

const weightControl=e=>e.get('layer-list').querySelectorAll().find(n=>n.ariaLabel?.startsWith('Font weight for '));
test('text weights persist per file and reset to the untouched source default',()=>{
 const e=editor();e.load('file','Stats','text');const weight=weightControl(e);
 assert.equal(weight.value,'');assert.match(weight.children[0].textContent,/From Penpot \(700\).*default/);assert.equal(weight.children.length,10);
 weight.value='800';weight.onchange();assert.equal(e.api.options().layerRules['file:button'].fontWeight,800);assert.equal(e.dirty(),1);
 const reload=editor(e.stored.get('penpot-bridge-layer-rules-v1'));reload.load('file','Stats','text');assert.equal(weightControl(reload).value,'800');
 reload.load('other','Stats','text');assert.equal(weightControl(reload).value,'');
 weight.value='';weight.onchange();assert.equal(e.api.options().layerRules['file:button'],undefined);assert.equal(e.dirty(),2);
});

test('inactive image weights stay disabled after busy work and retain the native choice',()=>{
 const e=editor();e.load('file','Stats','text');const row=e.get('layer-list').children[0],mode=row.children[2].children[0],weight=weightControl(e);
 weight.value='800';weight.onchange();mode.value='image';mode.onchange();assert.equal(weight.disabled,true);
 e.api.setBusy(true);e.api.setBusy(false);assert.equal(weight.disabled,true);assert.equal(e.api.options().layerRules['file:button'].fontWeight,800);
 mode.value='native';mode.onchange();assert.equal(weight.disabled,false);assert.equal(weight.value,'800');e.api.setBusy(true);assert.equal(weight.disabled,true);e.api.setBusy(false);assert.equal(weight.disabled,false);
});

test('non-text layers do not offer a font weight override',()=>{
 const e=editor();e.load();assert.equal(weightControl(e),undefined);
});
test('layer choices persist per file, use literal names and reset cleanly to Auto',()=>{
 const e=editor();e.load();const row=e.get('layer-list').children[0];assert.equal(row.children[0].textContent,'Upgrade <button>');
 const mode=row.children[2].children[0],ref=row.children[3],template=row.children[4];mode.value='template';mode.onchange();template.value='PrimaryButton';ref.value='UpgradeButton';ref.oninput();
 assert.equal(e.dirty(),2);assert.equal(e.api.options().layerRules['file:button'].template,'PrimaryButton');
 const reload=editor(e.stored.get('penpot-bridge-layer-rules-v1'));reload.load();assert.equal(reload.get('layer-list').children[0].children[3].value,'UpgradeButton');
 reload.load('other-file');assert.equal(reload.get('layer-list').children[0].children[3].value,'');
 mode.value='auto';ref.value='';mode.onchange();assert.equal(e.api.options().layerRules['file:button'],undefined);
});
test('late layer responses cannot replace a newer selection and busy controls disable editing',()=>{
 const e=editor();e.get('layers-load').onclick();const old=e.sent.at(-1).requestId;e.load('current');
 assert.equal(e.api.onMessage({type:'layer-list',requestId:old,fileId:'old',layers:[]}),false);assert.equal(e.get('layer-list').children[0].children[0].textContent,'Upgrade <button>');
 e.api.setBusy(true);assert.equal(e.get('layers-load').disabled,true);for(const input of e.get('layer-list').querySelectorAll())assert.equal(input.disabled,true);
 e.api.setBusy(false);assert.equal(e.get('layers-load').disabled,false);for(const input of e.get('layer-list').querySelectorAll())assert.equal(input.disabled,false);
});
