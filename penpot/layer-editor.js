globalThis.P2RLayerEditor=(()=>{
 const modes={auto:'Auto',native:'Native',image:'Image',layout:'Layout only',skip:'Skip subtree',template:'Reusable template'};
 const storageKey='penpot-bridge-layer-rules-v1';
 function create({post,invalidate,status}){
  const el=id=>document.getElementById(id);let rules={},layers=[],fileId='',request=0,activeRequest,busy=false;
  try{const saved=JSON.parse(localStorage.getItem(storageKey)||'{}');if(saved&&typeof saved==='object'&&!Array.isArray(saved))rules=saved}catch{}
  const make=(tag,props={})=>Object.assign(document.createElement(tag),props);
  function save(key,rule){
   if(rule.mode==='auto'&&!rule.ref)delete rules[key];else rules[key]=rule;
   try{localStorage.setItem(storageKey,JSON.stringify(rules))}catch{status('Layer choices could not be saved locally. They still apply for this session.')}
   invalidate();
  }
  function render(){
   const root=el('layer-list');root.replaceChildren();const query=el('layers-search').value.toLowerCase();
   const matches=layers.filter(n=>n.name.toLowerCase().includes(query));
   for(const layer of matches.slice(0,100)){
    const key=fileId+':'+layer.id,rule={mode:'auto',...rules[key]};
    const row=make('div',{className:'layer-rule'});row.style.marginLeft=Math.min(layer.depth,4)*8+'px';
    row.appendChild(make('strong',{textContent:layer.name}));row.appendChild(make('small',{textContent:layer.type}));
    const label=make('label',{textContent:'Import as '});const mode=make('select',{ariaLabel:'Import mode for '+layer.name});
    for(const [value,text]of Object.entries(modes))mode.appendChild(make('option',{value,textContent:text}));mode.value=rule.mode;mode.disabled=busy;label.appendChild(mode);row.appendChild(label);
    const ref=make('input',{value:rule.ref||'',placeholder:'Gameplay reference, e.g. UpgradeButton',maxLength:64,disabled:busy,ariaLabel:'Gameplay reference for '+layer.name});row.appendChild(ref);
    const template=make('input',{value:rule.template||'',placeholder:'Template key mapped in Studio',maxLength:64,disabled:busy,ariaLabel:'Reusable template for '+layer.name});template.hidden=rule.mode!=='template';row.appendChild(template);
    const update=()=>{const next={mode:mode.value,ref:ref.value.trim()};if(next.mode==='template')next.template=template.value.trim();template.hidden=next.mode!=='template';save(key,next)};
    mode.onchange=update;ref.onchange=update;template.onchange=update;root.appendChild(row);
   }
   if(matches.length>100)root.appendChild(make('p',{textContent:'Showing 100 of '+matches.length+' layers. Search to narrow the list.'}));
   if(!layers.length)root.appendChild(make('p',{textContent:'Read the selected design to choose individual layer modes.'}));
  }
  el('layers-load').onclick=()=>{activeRequest='layers:'+ ++request;post('layers',{},activeRequest);status('Reading layer controls…')};
  el('layers-search').oninput=render;
  return {
   options:()=>({layerRules:structuredClone(rules)}),
   setBusy(value){busy=value;el('layers-load').disabled=value;el('layers-search').disabled=value;for(const i of el('layer-list').querySelectorAll('input,select'))i.disabled=value},
   onMessage(m){
    if(m.requestId!==activeRequest||!activeRequest)return false;
    if(m.type==='error'){status('Cannot read layers: '+m.message);activeRequest=null;return true}
    if(m.type!=='layer-list')return false;
    fileId=m.fileId;layers=m.layers;activeRequest=null;render();status('Read '+layers.length+' layers. Choices are saved locally per design file; prepare again after changes.');return true;
   }
  };
 }
 return {create};
})();
