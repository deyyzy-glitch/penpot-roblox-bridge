import {readFile,writeFile,mkdir}from'node:fs/promises';
import path from'node:path';
import {encodePNG}from'./png.mjs';
export function cloudUploader({storageDir=null,fetchImpl=fetch}={}){
 let key=process.env.ROBLOX_OPEN_CLOUD_API_KEY||'',authorizedUserId=null,loaded=false,records={};const flights=new Map();
 async function load(){if(loaded)return;loaded=true;if(storageDir){try{records=JSON.parse(await readFile(path.join(storageDir,'uploads.json'),'utf8'))}catch(e){if(e.code!=='ENOENT')throw e}}}
 async function save(){if(storageDir){await mkdir(storageDir,{recursive:true});const file=path.join(storageDir,'uploads.json');await writeFile(file,JSON.stringify(records,null,2))}}
 const status=()=>({configured:!!key&&!!authorizedUserId,userId:authorizedUserId});
 async function configure(apiKey){
  if(typeof apiKey!=='string'||apiKey.length<16||apiKey.length>10000)throw Error('Enter a Roblox Open Cloud API key.');
  const response=await fetchImpl('https://apis.roblox.com/api-keys/v1/introspect',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({apiKey}),signal:AbortSignal.timeout(20000)});
  if(!response.ok)throw Error('Roblox key validation failed (HTTP '+response.status+'). Check its permissions and IP restrictions.');
  const info=await response.json();if(!info.enabled||info.expired)throw Error('This API key is disabled or expired.');
  const scopes=info.scopes||[];if(!scopes.some(s=>s.name==='asset'&&s.operations?.includes('write'))||!scopes.some(s=>s.name==='asset'&&s.operations?.includes('read')))throw Error('The key needs Assets Read and Write operations.');
  key=apiKey;authorizedUserId=String(info.authorizedUserId);return status();
 }
 async function ensure(){if(!authorizedUserId&&key)await configure(key);if(!key||!authorizedUserId)throw Error('Set up image uploads at http://127.0.0.1:43129/setup, then retry.');}
 function identity(creator,hash){const type=creator.groupId?'group':'user',id=String(creator.groupId||creator.userId||'');if(!/^\d+$/.test(id)||!/^[a-f0-9]{64}$/.test(hash))throw Error('Invalid asset owner or hash');return `${type}:${id}:${hash}`}
 async function poll(record){
  if(record.assetId||!record.operation)return record;
  const response=await fetchImpl('https://apis.roblox.com/assets/v1/'+record.operation,{headers:{'x-api-key':key},signal:AbortSignal.timeout(20000)});
  if(!response.ok)throw Error('Roblox upload status failed (HTTP '+response.status+').');
  const info=await response.json();if(info.error){record.error='Roblox rejected this upload: '+String(info.error.message||info.error.code);await save();throw Error(record.error)}
  if(info.done){const id=String(info.response?.assetId||'');if(!/^\d+$/.test(id))throw Error('Roblox completed the operation without an image ID');record.assetId=id;record.state='done';await save()}
  return record;
 }
 async function upload({hash,name,creator,requestedBy},image){
  await load();await ensure();if(String(requestedBy)!==authorizedUserId)throw Error('The upload key belongs to a different Roblox account than Studio.');
  const id=identity(creator,hash);if(flights.has(id))return flights.get(id);
  const run=(async()=>{
   if(records[id]){const record=records[id];if(record.state==='starting')throw Error('A previous upload has an unknown outcome. Check Creator Dashboard before retrying to avoid a duplicate.');if(record.error)throw Error(record.error);return await poll(record)}
   const record={state:'starting',hash,creator,name};records[id]=record;await save();
   const form=new FormData();form.append('request',JSON.stringify({assetType:'Image',displayName:('Penpot '+name).slice(0,80),description:'Penpot design surface '+hash,creationContext:{creator}}));form.append('fileContent',new Blob([encodePNG(image)],{type:'image/png'}),hash+'.png');
   let response;try{response=await fetchImpl('https://apis.roblox.com/assets/v1/assets',{method:'POST',headers:{'x-api-key':key},body:form,signal:AbortSignal.timeout(30000)})}catch{throw Error('Upload connection interrupted. Its outcome is unknown; check Creator Dashboard before retrying.')}
   if(!response.ok){if(response.status>=400&&response.status<500&&response.status!==408){delete records[id];await save()}throw Error('Roblox image upload failed (HTTP '+response.status+'). Check the key permissions, owner and quota.')}
   const info=await response.json();if(!/^operations\/[\w-]+$/.test(info.path||''))throw Error('Unexpected Roblox upload operation response');record.operation=info.path;record.state='pending';await save();return await poll(record);
  })();flights.set(id,run);try{return await run}finally{flights.delete(id)}
 }
 return {configure,status,upload};
}
