import {test} from 'node:test';
import assert from 'node:assert/strict';
import {processImage,silhouetteGlow,dilateRGB} from '../bridge/image-tools.mjs';
import {createBridge} from '../bridge/server.mjs';
import {encodePNG,decodePNG} from '../bridge/png.mjs';
const image=()=>({width:5,height:5,bounds:{x:0,y:0,width:5,height:5},pixels:Buffer.from(Array.from({length:25},(_,i)=>[20,40,80,i===12?255:0]).flat())});
test('monochrome masks share pixels across color variants and preserve alpha',()=>{
 const original=image(),a=processImage(original,{tint:true});const red=image();for(let i=0;i<red.pixels.length;i+=4){red.pixels[i]=200;red.pixels[i+1]=20;red.pixels[i+2]=40}const b=processImage(red,{tint:true});
 assert.equal(a.tintColor,'#142850');assert.deepEqual(a.image.pixels,b.image.pixels);assert.equal(a.image.pixels[12*4+3],255);assert.equal(a.image.pixels[3],0);assert.equal(original.pixels[0],20);
 red.pixels[3]=255;red.pixels[0]=20;assert.equal(processImage(red,{tint:true}).tintColor,null);
});
test('RGB dilation fills transparent colors without changing any alpha',()=>{
 const a=image();for(let i=0;i<a.pixels.length;i+=4)if(i!==48)a.pixels[i]=a.pixels[i+1]=a.pixels[i+2]=0;
 const alpha=Array.from(a.pixels).filter((_,i)=>i%4===3);dilateRGB(a,8);assert.deepEqual(Array.from(a.pixels).filter((_,i)=>i%4===3),alpha);assert.deepEqual(Array.from(a.pixels.subarray(0,3)),[20,40,80]);
});
test('silhouette glow expands alpha shape with bounded dimensions',()=>{
 const source=image(),g=silhouetteGlow(source,4);assert.ok(g.width>source.width&&g.bounds.x<0);assert.equal(g.pixels[3],0);assert.ok(g.pixels.some((v,i)=>i%4===3&&v>0&&v<255));assert.equal(source.pixels[3],0);assert.throws(()=>silhouetteGlow(source,100),/radius/);
 const large={width:1024,height:1024,bounds:{x:0,y:0,width:512,height:512},pixels:Buffer.alloc(1024*1024*4,255)};const big=silhouetteGlow(large,32);assert.ok(big.width<=1024&&big.height<=1024);
});
test('bridge returns processed preview pixels, glow metadata and portable payloads',async()=>{
 const {server,token}=createBridge();await new Promise(ok=>server.listen(0,'127.0.0.1',ok));const base='http://127.0.0.1:'+server.address().port,headers={Authorization:'Bearer '+token,'Content-Type':'application/json'};
 try{const png=encodePNG(image());const r=await(await fetch(base+'/assets',{method:'POST',headers,body:JSON.stringify({png:png.toString('base64'),viewBox:[0,0,5,5],shapeWidth:5,shapeHeight:5,options:{tint:true,glow:{radius:4}}})})).json();assert.equal(r.tintColor,'#142850');assert.match(r.glow.hash,/^[a-f0-9]{64}$/);const preview=decodePNG(Buffer.from(await(await fetch(base+'/assets/'+r.hash+'/png',{headers})).arrayBuffer()));assert.equal(preview.pixels[48],255);
  const d={format:'penpot-roblox',version:4,source:{rootId:'root'},design:{id:'root'},assets:[{contentHash:r.hash},{contentHash:r.glow.hash}]};await fetch(base+'/document',{method:'POST',headers,body:JSON.stringify(d)});const bundle=await(await fetch(base+'/bundle',{headers})).json();assert.equal(Object.keys(bundle.assetPayloads).length,2);
 }finally{server.closeAllConnections();await new Promise(ok=>server.close(ok))}
});
