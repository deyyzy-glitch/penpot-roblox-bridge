import test from 'node:test';
import assert from 'node:assert/strict';
import http from 'node:http';
import {createBridge,startBridge} from '../bridge/server.mjs';

const listen=server=>new Promise(r=>server.listen(0,'127.0.0.1',r));
async function close(server){server.closeAllConnections();await new Promise(r=>server.close(r))}
test('duplicate launch leaves the existing helper and its prepared design running',async()=>{
 const {server,token}=createBridge();await listen(server);const port=server.address().port;
 const design={format:'penpot-roblox',version:5,source:{rootId:'retained'},design:{id:'retained'},assets:[]};
 const headers={Authorization:'Bearer '+token,'Content-Type':'application/json'};
 try{
  await fetch(`http://127.0.0.1:${port}/document`,{method:'POST',headers,body:JSON.stringify(design)});
  const logs=[],pages=[];const result=await startBridge({port,log:s=>logs.push(s),openPage:u=>pages.push(u)});
  assert.equal(result.exitCode,10);assert.ok(result.existingVersion);assert.match(logs.join(''),/already running/);assert.equal(pages[0],`http://127.0.0.1:${port}/setup`);
  assert.deepEqual(await(await fetch(`http://127.0.0.1:${port}/document`,{headers})).json(),design);
 }finally{await close(server)}
});
test('older helper is recognized by its manifest without requesting credentials',async()=>{
 const paths=[];const server=http.createServer((req,res)=>{paths.push(req.url);if(req.url==='/manifest.json'){res.end(JSON.stringify({name:'Penpot to Roblox',code:'plugin.js',description:'Export native editable Roblox UI with persistent source IDs'}))}else{res.statusCode=404;res.end()}});
 await listen(server);try{const result=await startBridge({port:server.address().port,log:()=>{}});assert.equal(result.exitCode,10);assert.equal(result.existingVersion,'older version');assert.deepEqual(paths,['/health','/manifest.json'])}finally{await close(server)}
});
test('an unrelated service is reported without opening its page or stopping it',async()=>{
 const server=http.createServer((req,res)=>res.end('Different application'));await listen(server);
 try{const logs=[];let opened=false;const result=await startBridge({port:server.address().port,log:s=>logs.push(s),openPage:()=>{opened=true}});assert.equal(result.exitCode,1);assert.equal(opened,false);assert.match(logs.join(''),/another application/);assert.equal((await fetch(`http://127.0.0.1:${server.address().port}`)).status,200)}finally{await close(server)}
});
test('normal startup reports its version and serves a minimal credential-free health response',async()=>{
 const pages=[];const result=await startBridge({port:0,log:()=>{},openPage:u=>pages.push(u)});
 try{assert.equal(result.exitCode,0);const base=`http://127.0.0.1:${result.server.address().port}`;assert.equal(pages[0],base+'/setup');const state=await(await fetch(base+'/health')).json();assert.deepEqual(Object.keys(state).sort(),['app','version']);assert.equal(state.app,'penpot-roblox-bridge')}finally{await close(result.server)}
});
