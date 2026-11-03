import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {zstdDecompressSync} from 'node:zlib';

test('generated plugins retain literal Luau patterns and inline their support modules',async()=>{
 const standalone=await readFile(new URL('../PenpotRoblox.plugin.lua',import.meta.url),'utf8');
 const xml=await readFile(new URL('../PenpotRoblox.rbxmx',import.meta.url),'utf8');
 assert.match(xml, /^<roblox version="4"><Item class="Script"><Properties>[\s\S]*?<bool name="Disabled">false<\/bool><\/Properties>/, 'plugin entry script must start enabled');
 const unescape=s=>s.replaceAll('&lt;','<').replaceAll('&gt;','>').replaceAll('&quot;','"').replaceAll('&amp;','&');
 for(const code of [standalone,unescape(xml)]){
  for(const file of ['References','Templates','Gradient']){
   const source=await readFile(new URL('../studio/'+file+'.luau',import.meta.url),'utf8');
   assert.ok(code.includes(source),file+' source must survive packaging byte for byte');
   assert.ok(!code.includes('require(script.Parent.'+file+')'));
  }
  assert.ok(code.includes("key:match('^[A-Za-z_][A-Za-z0-9_]*$')"));
 }
 assert.ok(Buffer.byteLength(standalone)<200000,'standalone plugin must fit Studio Source limits');
 for(const name of ['View','ViewData'])assert.ok(xml.includes('<string name="Name">'+name+'</string>'),'packaged '+name+' module is required');
 const view=await readFile(new URL('../studio/View.luau',import.meta.url),'utf8'),data=await readFile(new URL('../studio/ViewData.luau',import.meta.url),'utf8');
 assert.ok(standalone.includes(view.replace('local Data=require(script.Parent.ViewData)',()=>`local Data=(function()\n${data}\nend)()`)));
 const encoded=data.match(/buffer\.fromstring\('([A-Za-z0-9+/=]+)'\)/)[1];
 assert.deepEqual(JSON.parse(zstdDecompressSync(Buffer.from(encoded,'base64'))),JSON.parse(await readFile(new URL('../studio/view-data.json',import.meta.url),'utf8')));
});
