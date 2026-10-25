import http from 'node:http';
import crypto from 'node:crypto';
import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
import {decodePNG,normalizeRaster,encodePNG} from './png.mjs';
import {processImage} from './image-tools.mjs';
import {cloudUploader} from './cloud.mjs';
import {execFile} from 'node:child_process';
const project=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..'),root=path.join(project,'penpot');
const helperVersion=JSON.parse(await readFile(path.join(project,'package.json'),'utf8')).version;
export function createBridge({token=crypto.randomBytes(24).toString('hex'),storageDir=null,cloudFetch=fetch}={}){
 let document=null;const assets=new Map();
 const cloud=cloudUploader({storageDir:storageDir&&path.join(storageDir,'cloud'),fetchImpl:cloudFetch});
 const saveAsset=async image=>{const hash=crypto.createHash('sha256').update(JSON.stringify([image.width,image.height])).update(image.pixels).digest('hex');const asset={...image,hash};assets.set(hash,asset);if(storageDir){await mkdir(storageDir,{recursive:true});await writeFile(path.join(storageDir,hash+'.json'),JSON.stringify({...asset,pixels:asset.pixels.toString('base64')}))}return asset};
 const server=http.createServer(async(req,res)=>{
  const reply=(status,value,type='application/json')=>{res.writeHead(status,{'Content-Type':type});res.end(type==='application/json'&&!Buffer.isBuffer(value)?JSON.stringify(value):value)};
  const host=req.headers.host||'',origin=req.headers.origin;
  if(!/^(127\.0\.0\.1|localhost):\d+$/.test(host))return reply(403,{error:'Loopback hosts only'});
  const sameOrigin=!origin||origin==='http://'+host||origin==='http://127.0.0.1:'+server.address().port;
  res.setHeader('Vary','Origin');res.setHeader('X-Content-Type-Options','nosniff');res.setHeader('Cache-Control','no-store');
  if(sameOrigin&&origin)res.setHeader('Access-Control-Allow-Origin',origin);
  res.setHeader('Access-Control-Allow-Methods','GET,POST,OPTIONS');res.setHeader('Access-Control-Allow-Headers','Authorization,Content-Type');res.setHeader('Access-Control-Allow-Private-Network','true');
  if(req.method==='OPTIONS')return reply(sameOrigin?204:403,'','text/plain');
  const url=new URL(req.url,'http://localhost');
  const body=async(limit=12000000)=>{let size=0,chunks=[];for await(const c of req){size+=c.length;if(size>limit)throw Error('Request too large');chunks.push(c)}return JSON.parse(Buffer.concat(chunks).toString())};
  const getAsset=async hash=>{if(assets.has(hash))return assets.get(hash);if(storageDir){try{const a=JSON.parse(await readFile(path.join(storageDir,hash+'.json'),'utf8'));a.pixels=Buffer.from(a.pixels,'base64');assets.set(hash,a);return a}catch(e){if(e.code!=='ENOENT')throw e}}return null};
  try{
   // Same-origin browser isolation + loopback Host validation; no credentials are sent to Penpot's parent frame.
   if(url.pathname==='/health'){if(!sameOrigin)return reply(403,{error:'Origin rejected'});return reply(200,{app:'penpot-roblox-bridge',version:helperVersion})}
   if(url.pathname==='/session'){if(!sameOrigin)return reply(403,{error:'Origin rejected'});return reply(200,{token,version:2})}
   if(url.pathname==='/setup'&&req.method==='GET'){res.setHeader('Content-Security-Policy',"frame-ancestors 'none'");return reply(200,await readFile(path.join(project,'bridge','setup.html')),'text/html')}
   const staticFiles={'/manifest.json':['manifest.json','application/json'],'/plugin.js':['plugin.js','text/javascript'],'/ui.html':['ui.html','text/html'],'/ui.js':['ui.js','text/javascript'],'/ui.css':['ui.css','text/css'],'/shell.js':['shell.js','text/javascript'],'/corners.js':['corners.js','text/javascript'],'/image-editor.js':['image-editor.js','text/javascript'],'/layer-editor.js':['layer-editor.js','text/javascript']};
   if(staticFiles[url.pathname]&&req.method==='GET'){
    const [file,type]=staticFiles[url.pathname];res.setHeader('Access-Control-Allow-Origin','*');
    return reply(200,await readFile(path.join(root,file)),type);
   }
   if(!sameOrigin)return reply(403,{error:'Origin rejected'});
   const provided=Buffer.from(req.headers.authorization||''),expected=Buffer.from('Bearer '+token);
   if(provided.length!==expected.length||!crypto.timingSafeEqual(provided,expected))return reply(401,{error:'Connect to the local companion first'});
   if(url.pathname==='/configure'&&req.method==='POST'){const value=await body(20000);return reply(200,await cloud.configure(value.key))}
   if(url.pathname==='/upload-status'&&req.method==='GET')return reply(200,cloud.status());
   if(url.pathname==='/uploads'&&req.method==='POST'){
    const value=await body();if(!/^[a-f0-9]{64}$/.test(value.hash||''))throw Error('Invalid upload hash');
    let image=await getAsset(value.hash);
    if(!image&&value.payload){const p=value.payload;if(!Number.isInteger(p.width)||!Number.isInteger(p.height)||p.width<1||p.height<1||p.width>1024||p.height>1024||typeof p.pixels!=='string'||p.pixels.length>5600000)throw Error('Invalid embedded upload pixels');image={width:p.width,height:p.height,pixels:Buffer.from(p.pixels,'base64')};if(image.pixels.length!==p.width*p.height*4)throw Error('Pixel length mismatch');const computed=crypto.createHash('sha256').update(JSON.stringify([p.width,p.height])).update(image.pixels).digest('hex');if(computed!==value.hash)throw Error('Pixel hash mismatch');assets.set(value.hash,image)}
    if(!image)throw Error('Send the design again to restore its image pixels.');
    const result=await cloud.upload(value,image);return reply(200,{state:result.state,assetId:result.assetId||null});
   }
   if(url.pathname==='/document'){
    if(req.method==='GET')return reply(document?200:404,document||{error:'Send a design from Penpot first'});
    if(req.method==='POST'){const d=await body(64000000);if(d.format!=='penpot-roblox'||![1,2,3,4,5].includes(d.version)||!d.source?.rootId||d.source.rootId!==d.design?.id)throw Error('Invalid document envelope. Update both the helper and Studio plugin for newer exports.');document=d;return reply(200,{ok:true})}
   }
   if(url.pathname==='/assets'&&req.method==='POST'){
    const a=await body(),png=Buffer.from(a.png||'','base64');
    const original=normalizeRaster(decodePNG(png),a.viewBox,a.shapeWidth,a.shapeHeight,a.rotation||0);
    const processed=processImage(original,a.options||{}),asset=await saveAsset(processed.image),glow=processed.glow&&await saveAsset(processed.glow);
    const metadata=v=>({hash:v.hash,width:v.width,height:v.height,bounds:v.bounds});
    return reply(200,{...metadata(asset),tintColor:processed.tintColor,glow:glow?metadata(glow):null});
   }
   const match=url.pathname.match(/^\/assets\/([a-f0-9]{64})(\/(?:pixels|png))?$/);
   if(match&&req.method==='GET'){
    const asset=await getAsset(match[1]);if(!asset)return reply(404,{error:'Asset pixels are unavailable; send the design again'});
    return match[2]==='/png'?reply(200,encodePNG(asset),'image/png'):match[2]?reply(200,asset.pixels,'application/octet-stream'):reply(200,{hash:asset.hash,width:asset.width,height:asset.height,bounds:asset.bounds});
   }
   if(url.pathname==='/bundle'&&req.method==='GET'){
    if(!document)return reply(404,{error:'Send a design first'});
    const bundle=structuredClone(document);bundle.assetPayloads={};let bytes=0;
    for(const a of document.assets||[]){if(!a.contentHash||bundle.assetPayloads[a.contentHash])continue;const data=await getAsset(a.contentHash);if(!data)throw Error('Missing asset pixels');const payload={width:data.width,height:data.height,pixels:data.pixels.toString('base64')};bytes+=payload.pixels.length;if(bytes>60000000)throw Error('Bundle exceeds 60 MB; use the direct bridge for this design');bundle.assetPayloads[a.contentHash]=payload}
    return reply(200,bundle);
   }
   return reply(404,{error:'Unknown route'});
  }catch(e){return reply(400,{error:e.message})}
 });
 return {server,token};
}
export async function startBridge({port=43129,storageDir=null,log=console.log,openPage=()=>{}}={}){
 const {server}=createBridge({storageDir});
 const base=()=>`http://127.0.0.1:${server.address()?.port||port}`;
 try{
  await new Promise((resolve,reject)=>{
   const fail=e=>{server.off('listening',ready);reject(e)};
   const ready=()=>{server.off('error',fail);resolve()};
   server.once('error',fail);server.once('listening',ready);server.listen(port,'127.0.0.1');
  });
 }catch(error){
  if(error.code!=='EADDRINUSE'){
   log('Penpot Bridge could not start: '+error.message);return {server,exitCode:1};
  }
  let existing;
  try{
   const r=await fetch(base()+'/health',{signal:AbortSignal.timeout(2500)});
   if(r.ok){const state=await r.json();if(state.app==='penpot-roblox-bridge'&&typeof state.version==='string')existing=state.version}
  }catch{}
  // Older releases have no health route. Identify their public manifest without requesting a session or key.
  if(!existing)try{
   const r=await fetch(base()+'/manifest.json',{signal:AbortSignal.timeout(2500)});
   if(r.ok){const m=await r.json();if(m.name==='Penpot to Roblox'&&m.code==='plugin.js'&&m.description==='Export native editable Roblox UI with persistent source IDs')existing='older version'}
  }catch{}
  if(existing){
   log(`Penpot Bridge is already running (${existing}). No second helper was started.\nOpening the running helper: ${base()}/setup\nYou can close this duplicate window; the original helper keeps running.\nTo switch to this download (${helperVersion}), close the original helper first, then run this launcher again.`);
   openPage(base()+'/setup');return {server,exitCode:10,existingVersion:existing};
  }
  log(`Cannot start Penpot Bridge: another application is using 127.0.0.1:${port}.\nIt was not identified as Penpot Bridge. Close that application or free this port, then retry. No process was stopped.`);
  return {server,exitCode:1};
 }
 log(`Penpot Bridge ${helperVersion} is running on this PC.\nStatus and image setup: ${base()}/setup\nPenpot companion: ${base()}/manifest.json\nKeep this window open for transfers. No Roblox upload key is required to connect.\nIn Studio: Receive from Penpot. Allow 127.0.0.1 if asked; it means this PC.\nCtrl+C stops this helper.`);
 openPage(base()+'/setup');return {server,exitCode:0};
}
if(process.argv[1]===fileURLToPath(import.meta.url)){
 const result=await startBridge({storageDir:path.join(project,'.asset-cache'),openPage:url=>{
  if(process.argv.includes('--open')&&process.platform==='win32')execFile('rundll32.exe',['url.dll,FileProtocolHandler',url],{windowsHide:true},()=>{});
 }});
 process.exitCode=result.exitCode;
}
