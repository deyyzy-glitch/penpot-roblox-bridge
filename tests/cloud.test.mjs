import{test}from'node:test';import assert from'node:assert/strict';import{cloudUploader}from'../bridge/cloud.mjs';import{encodePNG,decodePNG,normalizeRaster}from'../bridge/png.mjs';
test('PNG encoding preserves transparent RGBA and normalizes exported padding',()=>{
 const image={width:2,height:1,pixels:Buffer.from([100,20,30,0,40,50,60,200])};const decoded=decodePNG(encodePNG(image));assert.deepEqual(decoded,image);
 const normalized=normalizeRaster(image,[-1,0,2,1],2,1,0);assert.deepEqual(normalized.bounds,{x:-1,y:0,width:2,height:1});assert.deepEqual(normalized.pixels,image.pixels);
});
test('cloud upload uses official Image API, polls an operation, and reuses its ID',async()=>{
 let creates=0,polls=0;
 const api=cloudUploader({fetchImpl:async(url,options)=>{
  if(url.endsWith('/introspect'))return Response.json({enabled:true,expired:false,authorizedUserId:42,scopes:[{name:'asset',operations:['read','write']}]});
  assert.equal(options.headers['x-api-key'],'synthetic-test-key-123456');
  if(url.endsWith('/assets/v1/assets')){creates++;const meta=JSON.parse(options.body.get('request'));assert.equal(meta.assetType,'Image');assert.deepEqual(meta.creationContext.creator,{userId:'42'});assert.equal(options.body.get('fileContent').type,'image/png');return Response.json({path:'operations/test-operation'})}
  polls++;return Response.json({done:polls>1,response:polls>1?{assetId:'123456'}:undefined});
 }});
 await api.configure('synthetic-test-key-123456');const a={hash:'a'.repeat(64),name:'Test',creator:{userId:'42'},requestedBy:'42'},image={width:1,height:1,pixels:Buffer.from([1,2,3,255])};
 assert.equal((await api.upload(a,image)).state,'pending');assert.equal((await api.upload(a,image)).assetId,'123456');assert.equal((await api.upload(a,image)).assetId,'123456');assert.equal(creates,1);
 await assert.rejects(api.upload({...a,requestedBy:'43'},image),/different Roblox account/);
});
test('uncertain network outcome is retained and does not issue a duplicate create',async()=>{
 let creates=0;const api=cloudUploader({fetchImpl:async url=>{if(url.endsWith('/introspect'))return Response.json({enabled:true,expired:false,authorizedUserId:42,scopes:[{name:'asset',operations:['read','write']}]});creates++;throw Error('network failed')}});
 await api.configure('synthetic-test-key-123456');const a={hash:'b'.repeat(64),name:'Test',creator:{userId:'42'},requestedBy:'42'},image={width:1,height:1,pixels:Buffer.from([1,2,3,255])};
 await assert.rejects(api.upload(a,image),/unknown/);await assert.rejects(api.upload(a,image),/unknown/);assert.equal(creates,1);
});
