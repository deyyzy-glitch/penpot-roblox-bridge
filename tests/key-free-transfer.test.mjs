import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import vm from 'node:vm';
import {createBridge} from '../bridge/server.mjs';

test('session, native design transfer and bundle download work without configuring an upload key',async()=>{
 let cloudCalls=0;
 const {server}=createBridge({cloudFetch:async()=>{cloudCalls++;throw Error('Cloud authorization is not part of design transfer')}});
 await new Promise(r=>server.listen(0,'127.0.0.1',r));
 const base=`http://127.0.0.1:${server.address().port}`;
 try{
  const session=await(await fetch(base+'/session')).json();
  const headers={Authorization:'Bearer '+session.token,'Content-Type':'application/json'};
  const state=await(await fetch(base+'/upload-status',{headers})).json();assert.equal(state.configured,false);
  assert.equal((await fetch(base+'/manifest.json')).status,200);
  const design={format:'penpot-roblox',version:5,source:{rootId:'native-board'},design:{id:'native-board',children:[]},assets:[]};
  assert.equal((await fetch(base+'/document',{method:'POST',headers,body:JSON.stringify(design)})).status,200);
  assert.deepEqual(await(await fetch(base+'/document',{headers})).json(),design);
  const bundle=await(await fetch(base+'/bundle',{headers})).json();assert.equal(bundle.design.id,'native-board');assert.deepEqual(bundle.assetPayloads,{});
  assert.equal(cloudCalls,0);
 }finally{server.closeAllConnections();await new Promise(r=>server.close(r))}
});

const html=await readFile(new URL('../bridge/setup.html',import.meta.url),'utf8');
async function setup(uploadStatusOK){
 const nodes=new Map();const get=id=>{if(!nodes.has(id))nodes.set(id,{textContent:'',hidden:false,value:'',disabled:false});return nodes.get(id)};
 vm.runInNewContext(html.match(/<script>([\s\S]*?)<\/script>/)[1],{
  document:{getElementById:get},fetch:async path=>({ok:path==='/session'||uploadStatusOK,json:async()=>path==='/session'?{token:'session-token'}:{configured:false}})
 });
 await new Promise(r=>setImmediate(r));return get;
}
test('unconfigured upload credentials appear optional while transfer remains ready',async()=>{
 const get=await setup(true);assert.match(get('transfer-status').textContent,/Ready.*no key required/);assert.match(get('status').textContent,/Not configured.*transfer still works/);
 assert.match(html,/<details id="upload-setup">/);assert.doesNotMatch(html,/<details id="upload-setup"[^>]*\bopen\b/);
});
test('upload status failure does not falsely mark a successful local session as disconnected',async()=>{
 const get=await setup(false);assert.match(get('transfer-status').textContent,/Ready.*no key required/);assert.match(get('status').textContent,/Upload status unavailable.*transfer is connected/);
});
