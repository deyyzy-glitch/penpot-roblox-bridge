// Content-addressed registry: upload each distinct PNG once per Roblox owner.
import {readFile,writeFile,mkdir,copyFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import path from 'node:path';
const [command,...args]=process.argv.slice(2);
const json=async p=>JSON.parse(await readFile(p,'utf8'));
const save=(p,v)=>writeFile(p,JSON.stringify(v,null,2)+'\n');
async function registry(p){try{return await json(p)}catch(e){if(e.code==='ENOENT')return {};throw e}}
if(command==='register'){
 const [file,hash,id]=args;if(!file || !/^[a-f0-9]{64}$/.test(hash || '') || !/^rbxassetid:\/\/\d+$/.test(id || ''))throw Error('Usage: node assets.mjs register registry.json SHA256 rbxassetid://123');
 const r=await registry(file);r[hash]=id;await save(file,r);console.log('Registered asset content hash.');
}else if(command==='prepare'){
 const [source,folder,registryPath]=args;if(!registryPath)throw Error('Usage: node assets.mjs prepare design.json PNG_FOLDER registry.json');
 const d=await json(source),r=await registry(registryPath),pending=new Map();
 const out=path.join(path.dirname(source),'prepared-assets');await mkdir(out,{recursive:true});
 d.assetMap ||= {};
 for(const a of d.assets || []){
  if(!/^[\w-]+$/.test(a.shapeId) || (a.contentHash && !/^[a-f0-9]{64}$/.test(a.contentHash)))throw Error('Invalid asset filename');
  const file=path.join(folder,(a.contentHash || a.shapeId)+'.png');const bytes=await readFile(file);
  const hash=createHash('sha256').update(bytes).digest('hex');a.contentHash=hash;
  if(r[hash])d.assetMap[a.key]=r[hash];
  else{delete d.assetMap[a.key];const entry=pending.get(hash) || {hash,file:hash+'.png',sourceKeys:[]};entry.sourceKeys.push(a.key);pending.set(hash,entry);await copyFile(file,path.join(out,hash+'.png'));}
 }
 const dest=source.replace(/\.json$/i,'')+'.mapped.json';await save(dest,d);await save(path.join(out,'pending-uploads.json'),[...pending.values()]);
 console.log(`${dest}\n${pending.size} distinct images require upload. Re-run with the original JSON after registering the uploaded IDs.`);
}else throw Error('Commands: prepare, register');
