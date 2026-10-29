// Local-only visual regression fixture; no helper, credentials or design file required.
import http from 'node:http';
import {readFile} from 'node:fs/promises';
import {encodePNG} from '../bridge/png.mjs';
const width=192,height=128,pixels=Buffer.alloc(width*height*4);
for(let y=0;y<height;y++)for(let x=0;x<width;x++){
 const p=(y*width+x)*4,edge=Math.min(x,y,width-1-x,height-1-y),corner=(x<24||x>=width-24)&&(y<24||y>=height-24);
 const rgb=corner?[255,195,74]:edge<8?[111,201,255]:edge<24?[20,107,179]:[23,49,77];
 pixels.set([...rgb,255],p);
}
const png=encodePNG({width,height,pixels});
const files={'/':['./slice-editor.html','text/html'],'/layers':['./layer-suggestions.html','text/html'],'/image-editor.js':['../penpot/image-editor.js','text/javascript'],'/layer-editor.js':['../penpot/layer-editor.js','text/javascript'],'/ui.css':['../penpot/ui.css','text/css']};
http.createServer(async(req,res)=>{
 try{
  if(req.url==='/assets/fixture/png'){res.writeHead(200,{'Content-Type':'image/png'});res.end(png);return;}
  const f=files[req.url];if(!f){res.writeHead(404);res.end();return;}
  res.writeHead(200,{'Content-Type':f[1],'Cache-Control':'no-store'});res.end(await readFile(new URL(f[0],import.meta.url)));
 }catch(e){res.writeHead(500);res.end(e.message);}
}).listen(43134,'127.0.0.1',()=>console.log('Slice editor checks: http://127.0.0.1:43134/'));
