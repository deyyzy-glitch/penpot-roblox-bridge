globalThis.P2RLayerEditor=(()=>{
 const modes={auto:'Auto',native:'Native',image:'Image',layout:'Layout only',skip:'Skip subtree',template:'Reusable template'};
 const weights={100:'Thin',200:'Extra Light',300:'Light',400:'Regular',500:'Medium',600:'SemiBold',700:'Bold',800:'ExtraBold',900:'Heavy'};
 const storageKey='penpot-bridge-layer-rules-v1';
 const dismissedKey='penpot-bridge-dismissed-controls-v1';
 function buttonSuggestion(layer){
  if(!['board','frame','group','rectangle','ellipse','path','boolean','svg-raw','image'].includes(layer.type))return '';
  const name=layer.name.trim();
  if(/(?:[\s_-](?:icon|label|text|background|border|shadow|image))$/i.test(name)||/(?:Icon|Label|Text|Background|Border|Shadow|Image)$/.test(name))return '';
  if(/\[(?:button|scroll|panel|closed|open|close)(?::|\])|_(?:button|scroll|panel|closed|close)(?![a-z0-9])|_open:/i.test(name))return '';
  if(/(?:^|[\s_-])(?:button|btn)$/i.test(name)||/(?:[a-z0-9])(?:Button|Btn)$/.test(name))return 'The layer name ends in “Button” or “btn”.';
  if(/^(?:button|btn)[\s_-]+\S/i.test(name)||/^Btn[A-Z]/.test(name))return 'The layer name starts with a button prefix.';
  return '';
 }
 function create({post,invalidate,status}){
  const el=id=>document.getElementById(id);let rules={},dismissed={},layers=[],fileId='',request=0,activeRequest,busy=false;
  try{const saved=JSON.parse(localStorage.getItem(storageKey)||'{}');if(saved&&typeof saved==='object'&&!Array.isArray(saved))rules=saved}catch{}
  try{const saved=JSON.parse(localStorage.getItem(dismissedKey)||'{}');if(saved&&typeof saved==='object'&&!Array.isArray(saved))dismissed=saved}catch{}
  const make=(tag,props={})=>Object.assign(document.createElement(tag),props);
  function save(key,rule){
   if(rule.mode==='auto'&&!rule.ref&&!rule.fontWeight&&!rule.button)delete rules[key];else rules[key]=rule;
   try{localStorage.setItem(storageKey,JSON.stringify(rules))}catch{status('Layer choices could not be saved locally. They still apply for this session.')}
   invalidate();
  }
  function render(){
   const root=el('layer-list');root.replaceChildren();const query=el('layers-search').value.toLowerCase();
   const covered=new Set(),ancestors=[];
   for(const layer of layers){while(ancestors.length&&ancestors.at(-1).depth>=layer.depth)ancestors.pop();if(ancestors.some(n=>['image','skip','template'].includes(rules[fileId+':'+n.id]?.mode)))covered.add(layer.id);ancestors.push(layer)}
   const matches=layers.filter(n=>n.name.toLowerCase().includes(query));
   for(const layer of matches.slice(0,100)){
    const key=fileId+':'+layer.id,rule={mode:'auto',...rules[key]};
    const row=make('div',{className:'layer-rule'});row.style.marginLeft=Math.min(layer.depth,4)*8+'px';
    row.appendChild(make('strong',{textContent:layer.name}));row.appendChild(make('small',{textContent:layer.type}));
    const label=make('label',{textContent:'Import as '});const mode=make('select',{ariaLabel:'Import mode for '+layer.name});
    for(const [value,text]of Object.entries(modes))mode.appendChild(make('option',{value,textContent:text}));mode.value=rule.mode;mode.disabled=busy;label.appendChild(mode);row.appendChild(label);
    const ref=make('input',{value:rule.ref||'',placeholder:'Gameplay reference, e.g. UpgradeButton',maxLength:64,disabled:busy,ariaLabel:'Gameplay reference for '+layer.name});row.appendChild(ref);
    const template=make('input',{value:rule.template||'',placeholder:'Template key mapped in Studio',maxLength:64,disabled:busy,ariaLabel:'Reusable template for '+layer.name});template.hidden=rule.mode!=='template';row.appendChild(template);
    let weight;
    if(layer.type==='text'){
     const label=make('label',{textContent:'Font weight '});weight=make('select',{ariaLabel:'Font weight for '+layer.name});
     const sourceLabel='From Penpot'+(Number.isFinite(layer.sourceWeight)?' ('+layer.sourceWeight+')':'')+' — default';
     weight.appendChild(make('option',{value:'',textContent:sourceLabel}));
     for(const [value,name]of Object.entries(weights))weight.appendChild(make('option',{value,textContent:name+' ('+value+')'}));
     weight.value=rule.fontWeight?String(rule.fontWeight):'';label.appendChild(weight);row.appendChild(label);
     row.appendChild(make('small',{className:'weight-help',textContent:'Overrides native text, including all styled runs. Image mode keeps the Penpot appearance. Available weights vary by Roblox font.'}));
    }
    const refreshWeight=()=>{if(weight){weight.p2rUnavailable=!['auto','native'].includes(mode.value);weight.disabled=busy||weight.p2rUnavailable}};
    const update=()=>{const next={mode:mode.value,ref:ref.value.trim()};if(next.mode==='template')next.template=template.value.trim();if(weight?.value)next.fontWeight=Number(weight.value);if(rules[key]?.button===true)next.button=true;template.hidden=next.mode!=='template';refreshWeight();save(key,next)};
    if(weight)weight.onchange=update;refreshWeight();
    mode.onchange=()=>{update();render()};ref.oninput=update;ref.onchange=update;template.oninput=update;template.onchange=update;
    const reason=buttonSuggestion(layer),fingerprint=layer.type+':'+layer.name;
    if(rule.button===true){
     const box=make('div',{className:'control-suggestion'});box.appendChild(make('p',{textContent:!covered.has(layer.id)&&['auto','native'].includes(rule.mode)?'Button control accepted. No gameplay logic is added.':'Saved button choice is inactive for this conversion mode or its parent.'}));
     const reset=make('button',{type:'button',textContent:'Use default control',disabled:busy});reset.onclick=()=>{if(busy)return;const next={mode:'auto',...rules[key]};delete next.button;save(key,next);render()};box.appendChild(reset);row.appendChild(box);
    }else if(reason&&rule.mode==='auto'&&!covered.has(layer.id)&&dismissed[key]!==fingerprint){
     const box=make('div',{className:'control-suggestion'});box.appendChild(make('strong',{textContent:'Button suggested'}));box.appendChild(make('p',{textContent:reason+' Accept to import this layer as a clickable control. No gameplay logic is added.'}));
     const accept=make('button',{type:'button',textContent:'Accept button',disabled:busy});accept.onclick=()=>{if(busy)return;save(key,{mode:'auto',...rules[key],button:true});render()};box.appendChild(accept);
     const dismiss=make('button',{type:'button',textContent:'Dismiss',disabled:busy});dismiss.onclick=()=>{if(busy)return;dismissed[key]=fingerprint;try{localStorage.setItem(dismissedKey,JSON.stringify(dismissed))}catch{status('Dismissed for this session; browser storage is unavailable.')}render()};box.appendChild(dismiss);row.appendChild(box);
    }
    root.appendChild(row);
   }
   if(matches.length>100)root.appendChild(make('p',{textContent:'Showing 100 of '+matches.length+' layers. Search to narrow the list.'}));
   if(!layers.length)root.appendChild(make('p',{textContent:'Read the selected design to choose individual layer modes.'}));
  }
  el('layers-load').onclick=()=>{activeRequest='layers:'+ ++request;post('layers',{},activeRequest);status('Reading layer controls…')};
  el('layers-search').oninput=render;
  return {
   options:()=>({layerRules:structuredClone(rules)}),
   setBusy(value){busy=value;el('layers-load').disabled=value;el('layers-search').disabled=value;for(const i of el('layer-list').querySelectorAll('input,select,button'))i.disabled=value||i.p2rUnavailable===true},
   onMessage(m){
    if(m.requestId!==activeRequest||!activeRequest)return false;
    if(m.type==='error'){status('Cannot read layers: '+m.message);activeRequest=null;return true}
    if(m.type!=='layer-list')return false;
    fileId=m.fileId;layers=m.layers;activeRequest=null;render();status('Read '+layers.length+' layers. Choices are saved locally per design file; prepare again after changes.');return true;
   }
  };
 }
 return {create,buttonSuggestion};
})();
