(()=>{
 const appearance=document.getElementById('appearance');let theme='dark';try{if(localStorage.getItem('penpot-bridge-appearance')==='light')theme='light'}catch{}
 const applyTheme=value=>{document.documentElement.dataset.theme=value;appearance.value=value};applyTheme(theme);
 appearance.onchange=()=>{applyTheme(appearance.value);try{localStorage.setItem('penpot-bridge-appearance',appearance.value)}catch{}};

 const pages={transfer:['WORKSPACE / TRANSFER','Your design, ready to build.','Prepare a selection and send it to Roblox Studio.'],layers:['WORKSPACE / LAYERS','Make each layer count.','Control conversion without changing your design.'],images:['WORKSPACE / IMAGES','Finish your image surfaces.','Fine-tune the artwork your design needs.'],settings:['PREFERENCES','Make it work your way.','Choose how your selection becomes Roblox UI.'],connection:['LOCAL CONNECTION','Keep your tools in sync.','One helper on your PC connects Penpot and Studio.']};
 const buttons=[...document.querySelectorAll('[data-page]')],views=[...document.querySelectorAll('[data-view]')];
 for(const button of buttons){const key=button.dataset.page;button.title=button.textContent.trim();button.setAttribute('aria-label',key==='transfer'?'Transfer':key[0].toUpperCase()+key.slice(1));button.onclick=()=>{
  for(const b of buttons){const active=b===button;b.classList.toggle('active',active);if(active)b.setAttribute('aria-current','page');else b.removeAttribute('aria-current')}
  for(const view of views)view.hidden=view.dataset.view!==key;
  const [category,title,description]=pages[key];document.getElementById('page-category').textContent=category;document.getElementById('page-title').textContent=title;document.getElementById('page-description').textContent=description;document.querySelector('main').scrollTop=0;
 }}
})();
