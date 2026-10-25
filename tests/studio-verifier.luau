-- Run outside the MCP undo recording; only this isolated sandbox is mutated.
return function(Importer,fixture)
 local Http=game:GetService('HttpService')
 local d=Http:JSONDecode(Http:JSONEncode(fixture));local results={}
 local target=Instance.new('ScreenGui');target.Name='P2R Verifier Regression';target.Parent=game.StarterGui
 local wrapper
 local function check(name,fn)local ok,err=pcall(fn);table.insert(results,{name=name,passed=ok,error=not ok and tostring(err)or nil})end
 local function find(id)for _,i in wrapper:GetDescendants()do if i:GetAttribute('P2R_Id')==id then return i end end end
 local function has(r,code,level,property)for _,i in r.issues do if i.code==code and(not level or i.level==level)and(not property or i.property==property)then return true end end;return false end
 local function audit()return Importer.verify(d,target,{})end
 local ok,err=pcall(function()
  wrapper=Importer.apply(Importer.prepare(d,target,{}));task.wait(.3)
  check('clean import has no property errors; declared substitution is a note',function()local r=audit();assert(r.errors==0,Http:JSONEncode(r.errors));assert(has(r,'font-substitution','note'))end)
  check('selected wrapper is accepted directly',function()assert(Importer.verify(d,wrapper,{}).errors==0)end)
  check('wrong imported font with matching baseline is an error',function()
   local i=find('title');local old=i.FontFace;local baseline=i:GetAttribute('P2R_Last')
   i.FontFace=Font.fromName('Arial');local last=Http:JSONDecode(baseline);last.FontFace=i.FontFace.Family..':'..i.FontFace.Weight.Name..':'..i.FontFace.Style.Name;i:SetAttribute('P2R_Last',Http:JSONEncode(last))
   local r=audit();i.FontFace=old;i:SetAttribute('P2R_Last',baseline);assert(has(r,'design-difference','error','FontFace'))
  end)
  check('local font edit is informational',function()local i=find('title');local old=i.FontFace;i.FontFace=Font.fromName('Arial');local r=audit();i.FontFace=old;assert(has(r,'local-edit','note'));assert(not has(r,'design-difference','error','FontFace'))end)
  check('explicit locks are informational even with no baseline',function()local i=find('left');local old=i.BackgroundColor3;local last=i:GetAttribute('P2R_Last');i:SetAttribute('P2R_Last',nil);i:SetAttribute('P2R_Locks','BackgroundColor3');i.BackgroundColor3=Color3.new(1,0,0);local r=audit();i.BackgroundColor3=old;i:SetAttribute('P2R_Last',last);i:SetAttribute('P2R_Locks',nil);assert(has(r,'local-edit','note'));assert(not has(r,'design-difference','error','BackgroundColor3'))end)
  check('deleted object reports missing and links its parent',function()local i=find('left');local parent=i.Parent;i.Parent=nil;local r=audit();i.Parent=parent;assert(has(r,'missing-object','error'))end)
  check('duplicate IDs are reported',function()local copy=find('left'):Clone();copy.Parent=find('left').Parent;local r=audit();copy:Destroy();assert(has(r,'duplicate-id','error'))end)
  check('wrong classes are reported',function()local i=find('left');local parent=i.Parent;i.Parent=nil;local f=Instance.new('TextLabel');f:SetAttribute('P2R_Id','left');f:SetAttribute('P2R_Source',i:GetAttribute('P2R_Source'));f.Parent=parent;local r=audit();f:Destroy();i.Parent=parent;assert(has(r,'wrong-class','error'))end)
  check('moved object is a warning',function()local i=find('left');local parent=i.Parent;i.Parent=wrapper;local r=audit();i.Parent=parent;assert(has(r,'moved-object','warning'))end)
  check('empty image reference is an error even if locally cleared',function()local i=find('icon::surface');local old=i.Image;i.Image='';local r=audit();i.Image=old;assert(has(r,'missing-image','error'))end)
  check('unresolved mapping is an error, not a clean import',function()local map=d.assetMap;d.assetMap={};local r=audit();d.assetMap=map;assert(has(r,'missing-image','error'))end)
  check('intentional design overlaps are ignored',function()assert(not has(audit(),'new-overlap'))end)
  check('new overlap from a local move is flagged',function()local i=find('right');local old=i.Position;i.Position=find('left').Position;task.wait(.1);local r=audit();i.Position=old;task.wait(.1);assert(has(r,'new-overlap','warning'))end)
  check('unrelated user objects are retained and not flagged',function()local i=Instance.new('Frame');i.Name='User decoration';i.Parent=wrapper;local r=audit();assert(i.Parent==wrapper);i:Destroy();assert(r.errors==0)end)
  check('verification is read-only',function()local values={};for _,i in wrapper:GetDescendants()do values[i]={parent=i.Parent,attrs=Http:JSONEncode(i:GetAttributes()),name=i.Name};if i:IsA('GuiObject')then values[i].position=i.Position;values[i].size=i.Size end end;local count=#wrapper:GetDescendants();audit();assert(#wrapper:GetDescendants()==count);for i,v in values do assert(i.Parent==v.parent and i.Name==v.name and Http:JSONEncode(i:GetAttributes())==v.attrs);if v.position then assert(i.Position==v.position and i.Size==v.size)end end end)
  check('missing import returns a selectable finding',function()local folder=Instance.new('Folder');local r=Importer.verify(d,folder,{});folder:Destroy();assert(has(r,'missing-import','error'))end)
  check('duplicate design wrappers are reported',function()local copy=Instance.new('Frame');copy:SetAttribute('P2R_Design',wrapper:GetAttribute('P2R_Design'));copy.Parent=target;local r=audit();copy:Destroy();assert(has(r,'duplicate-import','error'))end)
  check('rendered text overflow is reported but hidden text is skipped',function()local i=find('title');local old=i.Text;i.Text=string.rep('Overflow ',100);task.wait(.2);local r=audit();i.Visible=false;local hidden=audit();i.Visible=true;i.Text=old;assert(has(r,'text-overflow','warning'));assert(not has(hidden,'text-overflow'))end)
 end)
 target:Destroy();if not ok then error(err)end
 return results
end
