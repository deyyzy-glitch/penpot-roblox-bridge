// Reduce an already-exported real Penpot design to a standalone, shareable fixture.
// Never include uploaded IDs, binary artwork, caches, creator IDs or credentials.
import {readFile,writeFile,mkdir} from 'node:fs/promises';
import path from 'node:path';
const [input,name,output,slug]=process.argv.slice(2);
if(!input||!name||!output||!slug)throw Error('Usage: node scripts/capture-regression.mjs input.json "Layer name" output.json slug');
const original=JSON.parse(await readFile(input,'utf8'));
function find(n){if(n.name===name)return n;for(const c of n.children){const hit=find(c);if(hit)return hit}}
const node=structuredClone(find(original.design));if(!node)throw Error('Layer not found');
const ids=new Map(),keys=new Map();let count=0;
function remap(n){const old=n.id;n.id=slug+'-'+count++;ids.set(old,n.id);if(n.assetKey){const next='fixture:'+n.id;keys.set(n.assetKey,next);n.assetKey=next}delete n.tokens;delete n.behavior;for(const s of n.strokes||[])for(const k of Object.keys(s))if(/RefFile|RefId|Image/.test(k))delete s[k];for(const c of n.children)remap(c)}
remap(node);node.x=0;node.y=0;node.rotation=0;
const assets=(original.assets||[]).filter(a=>ids.has(a.shapeId)&&keys.has(a.key)).map(a=>({key:keys.get(a.key),shapeId:ids.get(a.shapeId),name:a.name,reason:a.reason,format:a.format||'png',scale:a.scale||2,skipChildren:!!a.skipChildren,fallback:!!a.fallback}));
const assetMap=Object.fromEntries(assets.map(a=>[a.key,'rbxassetid://0']));
const fixture={format:original.format,version:original.version,source:{fileId:'real-regression',pageId:'captured-demo',rootId:node.id},design:node,warnings:[],assets,assetMap,fontMap:{},options:{...original.options,behaviors:false,runtimeThemes:false}};
await mkdir(path.dirname(output),{recursive:true});await writeFile(output,JSON.stringify(fixture,null,2)+'\n');
console.log(`${path.basename(output)}: ${count} captured nodes, ${assets.length} image descriptors; IDs anonymized and image payloads excluded.`);
