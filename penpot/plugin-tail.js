penpot.ui.open('Penpot Bridge', 'http://127.0.0.1:43129/ui.html', {width:440,height:610});
let lastBundle,lastRequestId;
penpot.ui.onMessage(async message => {
  const requestId=message?.requestId;
  const send=value=>penpot.ui.sendMessage({...value,requestId});
  try {
    if(message?.type === 'export') {
      lastBundle=undefined;lastRequestId=requestId;
      lastBundle=P2R.exportSelection(penpot,[...penpot.selection],message.options||{});
      send({type:'document',document:lastBundle.document});
    } else if(message?.type === 'assets') {
      if(!lastBundle) throw Error('Export the selection first.');
      if(requestId!==lastRequestId)throw Error('Selection changed. Prepare the selection again.');
      const assets=await P2R.exportAssets(lastBundle,{onProgress:message=>send({type:'progress',message})});
      send({type:'assets',assets});
    }
  } catch(e) { send({type:'error',message:String(e.message || e)}); }
});
