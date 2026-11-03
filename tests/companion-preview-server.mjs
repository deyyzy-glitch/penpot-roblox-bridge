// Isolated preview: real companion and bridge, synthetic Penpot parent, no keys.
import http from 'node:http';
import {readFile} from 'node:fs/promises';
import {createBridge} from '../bridge/server.mjs';
import {encodePNG} from '../bridge/png.mjs';
const bridge=createBridge();await new Promise(resolve=>bridge.server.listen(0,'127.0.0.1',resolve));
const pixels=Buffer.alloc(192*128*4);for(let y=0;y<128;y++)for(let x=0;x<192;x++){const i=(y*192+x)*4;pixels.set([40+Math.round(x/5),115+Math.round(y/3),142,255],i)}
const png=encodePNG({width:192,height:128,pixels});
const server=http.createServer(async(req,res)=>{
 if(req.url==='/'){res.setHeader('Content-Type','text/html');res.end(await readFile(new URL('./companion-preview.html',import.meta.url)));return}
 if(req.url==='/fixture.png'){res.setHeader('Content-Type','image/png');res.end(png);return}
 const proxy=http.request({hostname:'127.0.0.1',port:bridge.server.address().port,path:req.url,method:req.method,headers:req.headers},upstream=>{res.writeHead(upstream.statusCode,upstream.headers);upstream.pipe(res)});proxy.on('error',e=>{res.statusCode=500;res.end(e.message)});req.pipe(proxy);
});
server.listen(43136,'127.0.0.1',()=>console.log('Companion preview: http://127.0.0.1:43136/'));
process.on('SIGINT',()=>{server.close();bridge.server.close();process.exit(0)});
