import test from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import {readFile} from 'node:fs/promises';
const source=await readFile(new URL('../penpot/layer-editor.js',import.meta.url),'utf8');
function editor(saved=null,dismissed=null){
 const nodes=new Map(),sent=[],stored=new Map(saved?[['penpot-bridge-layer-rules-v1',saved]]:[]);if(dismissed)stored.set('penpot-bridge-dismissed-controls-v1',dismissed);let dirty=0;
 const make=tag=>({tag,style:{},children:[],value:'',appendChild(c){this.children.push(c);return c},replaceChildren(){this.children=[]},querySelectorAll(){const all=[];const visit=n=>{for(const c of n.children){if(['input','select','button'].includes(c.tag))all.push(c);visit(c)}};visit(this);return all}});
 const get=id=>{if(!nodes.has(id))nodes.set(id,make('div'));return nodes.get(id)};
 const context={structuredClone,document:{getElementById:get,createElement:make},localStorage:{getItem:k=>stored.get(k)||null,setItem:(k,v)=>stored.set(k,v)}};
 vm.createContext(context);vm.runInContext(source,context);
 const api=context.P2RLayerEditor.create({post:(type,options,requestId)=>sent.push({type,requestId}),invalidate:()=>dirty++,status(){}});
 return {api,get,sent,stored,suggest:context.P2RLayerEditor.buttonSuggestion,dirty:()=>dirty,loadMany(layers,fileId='file'){get('layers-load').onclick();return api.onMessage({type:'layer-list',requestId:sent.at(-1).requestId,fileId,layers})},load(fileId='file',name='Upgrade <button>',type='rectangle'){get('layers-load').onclick();return api.onMessage({type:'layer-list',requestId:sent.at(-1).requestId,fileId,layers:[{id:'button',name,type,depth:1,...(type==='text'?{sourceWeight:700}:{})}]})}};
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
 const e=editor();e.load('file','Stats','text');let row=e.get('layer-list').children[0],mode=row.children[2].children[0],weight=weightControl(e);
 weight.value='800';weight.onchange();mode.value='image';mode.onchange();assert.equal(weight.disabled,true);
 e.api.setBusy(true);e.api.setBusy(false);assert.equal(weight.disabled,true);assert.equal(e.api.options().layerRules['file:button'].fontWeight,800);
 row=e.get('layer-list').children[0];mode=row.children[2].children[0];mode.value='native';mode.onchange();weight=weightControl(e);assert.equal(weight.disabled,false);assert.equal(weight.value,'800');e.api.setBusy(true);assert.equal(weight.disabled,true);e.api.setBusy(false);assert.equal(weight.disabled,false);
});

const action=(e,text)=>e.get('layer-list').querySelectorAll().find(n=>n.tag==='button'&&n.textContent===text);
test('button suggestions are conservative, explainable and do not change import options',()=>{
 const e=editor();for(const name of ['UpgradeButton','Buy_btn','BtnBuy','button Save','Button'])assert.ok(e.suggest({name,type:'rectangle'}),name);
 for(const name of ['Buttons','ButtonLabel','button_icon','Close','Buy','buttonhole','Upgrade [button]','Buy_scroll','Shop_panel','Buy_button'])assert.equal(e.suggest({name,type:'rectangle'}),'',name);
 assert.equal(e.suggest({name:'UpgradeButton',type:'text'}),'');e.load('file','UpgradeButton');assert.ok(action(e,'Accept button'));assert.equal(Object.keys(e.api.options().layerRules).length,0);assert.equal(e.dirty(),0);
});
test('accepting a suggested button persists, invalidates once and resets to default',()=>{
 const e=editor();e.load('file','UpgradeButton');action(e,'Accept button').onclick();assert.equal(e.api.options().layerRules['file:button'].button,true);assert.equal(e.dirty(),1);assert.equal(action(e,'Accept button'),undefined);
 const reloaded=editor(e.stored.get('penpot-bridge-layer-rules-v1'));reloaded.load('file','UpgradeButton');assert.ok(action(reloaded,'Use default control'));reloaded.load('other','UpgradeButton');assert.ok(action(reloaded,'Accept button'));
 const ref=e.get('layer-list').children[0].children[3];ref.value='Upgrade';ref.oninput();assert.equal(e.api.options().layerRules['file:button'].button,true);action(e,'Use default control').onclick();assert.equal(e.api.options().layerRules['file:button'].button,undefined);assert.equal(e.api.options().layerRules['file:button'].ref,'Upgrade');assert.ok(action(e,'Accept button'));
});
test('dismissal persists per file, identity and name without changing a prepared import',()=>{
 const e=editor();e.load('file','UpgradeButton');action(e,'Dismiss').onclick();assert.equal(e.dirty(),0);assert.equal(action(e,'Accept button'),undefined);
 const reloaded=editor(null,e.stored.get('penpot-bridge-dismissed-controls-v1'));reloaded.load('file','UpgradeButton');assert.equal(action(reloaded,'Accept button'),undefined);reloaded.load('file','Buy_btn');assert.ok(action(reloaded,'Accept button'));reloaded.load('other','UpgradeButton');assert.ok(action(reloaded,'Accept button'));
});
test('explicit layer modes and covered subtrees suppress suggestions; busy actions cannot apply',()=>{
 const e=editor(JSON.stringify({'file:button':{mode:'native'}}));e.load('file','UpgradeButton');assert.equal(action(e,'Accept button'),undefined);
 e.loadMany([{id:'parent',name:'Panel',type:'group',depth:0},{id:'button',name:'Buy_btn',type:'rectangle',depth:1}]);const mode=e.get('layer-list').children[0].children[2].children[0];mode.value='image';mode.onchange();assert.equal(action(e,'Accept button'),undefined);
 const fresh=editor();fresh.load('file','UpgradeButton');fresh.api.setBusy(true);const accept=action(fresh,'Accept button');assert.equal(accept.disabled,true);accept.onclick();assert.equal(fresh.dirty(),0);fresh.api.setBusy(false);assert.equal(accept.disabled,false);accept.onclick();assert.equal(fresh.dirty(),1);
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
