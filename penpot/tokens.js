/* Preserve source token definitions and bindings; resolve aliases without executing expressions. */
globalThis.P2RTokens=(()=>{
 const plain=v=>v==null?null:JSON.parse(JSON.stringify(v));
 function exportCatalog(catalog,warnings=[]){
  const sets=(catalog.sets||[]).map(s=>({id:s.id,name:s.name,active:!!s.active,tokens:(s.tokens||[]).map(t=>({id:t.id,name:t.name,type:t.type,value:plain(t.value),resolved:plain(t.resolvedValue??t.resolvedValueString)}))}));
  if(sets.length>64||sets.reduce((n,s)=>n+s.tokens.length,0)>2000)throw Error('Token catalog exceeds 64 sets or 2000 tokens.');
  const themes=(catalog.themes||[]).map(t=>({id:t.id,name:t.name,group:t.group||'',active:!!t.active,sets:(t.activeSets||[]).map(s=>s.id)}));
  if(themes.length>32)throw Error('Token catalog exceeds 32 themes.');
  const palette=active=>{
   const raw=new Map();for(const s of sets)if(active.has(s.id))for(const t of s.tokens)raw.set(t.name,t);
   const cache=Object.create(null),visiting=new Set();
   const resolve=name=>{if(Object.hasOwn(cache,name))return cache[name];const t=raw.get(name);if(!t||visiting.has(name))return undefined;visiting.add(name);let value=t.value;
    const alias=typeof value==='string'&&value.trim().match(/^\{([^{}]+)\}$/);if(alias)value=resolve(alias[1])?.value;
    visiting.delete(name);const type=t.type;
    if(typeof value==='string'&&/^(?:dimension|sizing|spacing|borderRadius|borderWidth|fontSizes|fontWeights|opacity|rotation|number)$/.test(type)){const m=value.trim().match(/^(-?(?:\d+\.?\d*|\.\d+))(?:px)?$/);value=m?Number(m[1]):undefined;}
    if(type==='color'&&typeof value==='string'&&!/^#[\da-f]{6}$/i.test(value))value=undefined;
    if(type==='fontFamilies'&&typeof value!=='string')value=undefined;
    if(typeof value!=='number'&&typeof value!=='string')value=undefined;
    if(typeof value==='number'&&(!Number.isFinite(value)||Math.abs(value)>100000))value=undefined;
    return cache[name]=value===undefined?null:{type,value};
   };
   for(const name of raw.keys())resolve(name);return cache;
  };
  const active=new Set(sets.filter(s=>s.active).map(s=>s.id)),palettes=Object.create(null);palettes.Default=palette(active);
  for(const theme of themes){const selected=new Set(active);const sameGroup=themes.filter(t=>t.group===theme.group);for(const t of sameGroup)for(const id of t.sets)selected.delete(id);for(const t of themes)if(t.active&&t.group!==theme.group)for(const id of t.sets)selected.add(id);for(const id of theme.sets)selected.add(id);palettes[theme.id]=palette(selected);}
  const unresolved=Object.entries(palettes.Default).filter(([,v])=>!v).map(([k])=>k);if(unresolved.length)warnings.push('Theme export: unresolved aliases/expressions/types retained as definitions and skipped at runtime: '+unresolved.join(', '));
  const bindingNames=Object.create(null);for(const set of sets)for(const token of set.tokens)if(typeof token.id==='string')bindingNames[token.id]=token.name;
  return {sets,themes,palettes,bindingNames};
 }
 return {exportCatalog};
})();
