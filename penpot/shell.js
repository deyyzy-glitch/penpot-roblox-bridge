(()=>{
 const appearance=document.getElementById('appearance');let theme='dark';try{if(localStorage.getItem('penpot-bridge-appearance')==='light')theme='light'}catch{}
 const applyTheme=value=>{document.documentElement.dataset.theme=value;appearance.value=value};applyTheme(theme);
 appearance.onchange=()=>{applyTheme(appearance.value);try{localStorage.setItem('penpot-bridge-appearance',appearance.value)}catch{}};

 const pages={transfer:['WORKSPACE / TRANSFER','Prepare for Roblox','Select a design, prepare it, then send it to Studio.'],layers:['WORKSPACE / LAYERS','Layer controls','Choose how each layer becomes Roblox UI.'],images:['WORKSPACE / IMAGES','Image finishing','Adjust prepared surfaces before sending them.'],settings:['PREFERENCES','Preferences','Choose your appearance and export behavior.'],connection:['LOCAL CONNECTION','Connect your tools','The helper links Penpot and Studio on this computer.']};
 const buttons=[...document.querySelectorAll('[data-page]')],views=[...document.querySelectorAll('[data-view]')];
 for(const button of buttons){const key=button.dataset.page;button.title=key==='connection'?'Local helper connection':button.textContent.trim();button.setAttribute('aria-label',key==='transfer'?'Transfer':key[0].toUpperCase()+key.slice(1));button.onclick=()=>{
  for(const b of buttons){const active=b===button;b.classList.toggle('active',active);if(active)b.setAttribute('aria-current','page');else b.removeAttribute('aria-current')}
  for(const view of views)view.hidden=view.dataset.view!==key;
  const [category,title,description]=pages[key];document.getElementById('page-category').textContent=category;document.getElementById('page-title').textContent=title;document.getElementById('page-description').textContent=description;document.getElementById('notice').hidden=true;document.querySelector('.workspace').scrollTop=0;
 }}
 globalThis.P2RShell={
  status(message){const notice=document.getElementById('notice');notice.hidden=message.startsWith('Select a layer, group, or board, then prepare');notice.dataset.kind=/failed|cannot|unavailable|error|did not respond|no response/i.test(message)?'error':'info';},
  connection(connected){const state=document.getElementById('helper-state');state.dataset.state=connected?'connected':'offline';state.textContent=connected?'Connected':'Not connected';}
 };
})();
