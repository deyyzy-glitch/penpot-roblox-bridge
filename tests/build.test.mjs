import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';

test('generated plugins retain literal Luau patterns and inline their support modules',async()=>{
 const standalone=await readFile(new URL('../PenpotRoblox.plugin.lua',import.meta.url),'utf8');
 const xml=await readFile(new URL('../PenpotRoblox.rbxmx',import.meta.url),'utf8');
 const unescape=s=>s.replaceAll('&lt;','<').replaceAll('&gt;','>').replaceAll('&quot;','"').replaceAll('&amp;','&');
 for(const code of [standalone,unescape(xml)]){
  for(const file of ['References','Templates','Gradient']){
   const source=await readFile(new URL('../studio/'+file+'.luau',import.meta.url),'utf8');
   assert.ok(code.includes(source),file+' source must survive packaging byte for byte');
   assert.ok(!code.includes('require(script.Parent.'+file+')'));
  }
  assert.ok(code.includes("key:match('^[A-Za-z_][A-Za-z0-9_]*$')"));
 }
});
