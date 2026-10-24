penpot.ui.open('Penpot Bridge', 'http://127.0.0.1:43129/ui.html', {width:440,height:610});
let lastBundle;
penpot.ui.onMessage(async message => {
  try {
    if(message?.type === 'export') {
      lastBundle=P2R.exportSelection(penpot);
      penpot.ui.sendMessage({type:'document',document:lastBundle.document});
    } else if(message?.type === 'assets') {
      if(!lastBundle) throw Error('Export the selection first.');
      const assets=await P2R.exportAssets(lastBundle);
      penpot.ui.sendMessage({type:'assets',assets});
    }
  } catch(e) { penpot.ui.sendMessage({type:'error',message:String(e.message || e)}); }
});
