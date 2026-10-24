-- Run this function outside an MCP recording, e.g. task.delay(1, function() ... end).
-- Uses isolated ScreenGuis in StarterGui, removes only the containers it creates.
return function(Importer, fixture)
 local Http=game:GetService('HttpService')
 local function clone(d) return Http:JSONDecode(Http:JSONEncode(d)) end
 local results={}
 local function check(label,fn)
  local ok,e=pcall(fn);table.insert(results,{name=label,passed=ok,error=not ok and tostring(e) or nil})
 end
 local target=Instance.new('ScreenGui');target.Name='P2R Regression Sandbox';target.Parent=game.StarterGui
 local d=clone(fixture)
 local function find(node,predicate) if predicate(node) then return node end;for _,c in ipairs(node.children) do local hit=find(c,predicate);if hit then return hit end end end
 local function byId(root,id) for _,i in root:GetDescendants() do if i:GetAttribute('P2R_Id')==id and not i:GetAttribute('P2R_Retired') then return i end end end
 local root,button,ref,scriptRef,connection,clicks= nil,nil,nil,nil,nil,0
 local sourceButton=find(d.design,function(n) return n.name=='Launch [button]' end)
 check('Initial import creates native instances',function()
  local plan=Importer.prepare(d,target,{});root=Importer.apply(plan);assert(plan.stats.added>20)
  button=byId(root,sourceButton.id);assert(button:IsA('TextButton'));assert(root:FindFirstChildWhichIsA('UIGradient',true));assert(root:FindFirstChildWhichIsA('UIListLayout',true))
  local row=find(d.design,function(n)return n.name=='Statistics Row'end)
  if row then
   local last=-math.huge;local children=table.clone(row.children);table.sort(children,function(a,b)return a.x<b.x end)
   for _,n in children do local actual=byId(root,n.id);assert(actual.LayoutOrder>last,'Native flex order must follow measured geometry');last=actual.LayoutOrder end
  end
  ref=Instance.new('ObjectValue');ref.Name='GameplayReference';ref.Value=button;ref.Parent=target
  scriptRef=Instance.new('LocalScript');scriptRef.Name='GameplayLogic';scriptRef.Source='-- User-owned logic';scriptRef.Parent=button
  connection=button.Activated:Connect(function() clicks+=1 end)
 end)
 check('Same design twice is idempotent',function()
  local count=#root:GetDescendants();local p=Importer.prepare(d,target,{});assert(p.stats.added==0 and p.stats.updated==0 and p.stats.conflicts==0,Http:JSONEncode(p.stats));Importer.apply(p);assert(#root:GetDescendants()==count);assert(byId(root,sourceButton.id)==button)
 end)
 check('Color dimension and rename updates preserve references and logic',function()
  sourceButton.name='Launch Updated [button]';sourceButton.width=190;sourceButton.fills[1].fillColor='#FFAA66'
  local p=Importer.prepare(d,target,{});assert(p.stats.updated>0);Importer.apply(p)
  assert(button.Name==sourceButton.name and button.Size.X.Offset==190);assert(button.BackgroundColor3==Color3.fromHex('#FFAA66'));assert(ref.Value==button and scriptRef.Parent==button and connection.Connected)
 end)
 check('Local overrides and explicit locks survive synchronization',function()
  button.BackgroundColor3=Color3.fromRGB(1,2,3);button:SetAttribute('P2R_Locks','Size')
  sourceButton.width=210;sourceButton.fills[1].fillColor='#FF0000'
  local p=Importer.prepare(d,target,{});assert(p.stats.conflicts>=2);Importer.apply(p)
  assert(button.BackgroundColor3==Color3.fromRGB(1,2,3) and button.Size.X.Offset==190)
  Importer.apply(Importer.prepare(d,target,{force=true}));assert(button.BackgroundColor3==Color3.fromHex('#FF0000') and button.Size.X.Offset==190)
  button:SetAttribute('P2R_Locks',nil)
 end)
 check('Add remove and restore retains instances and user children',function()
  local copy=clone(sourceButton);copy.id='regression-added';copy.name='Added';table.insert(d.design.children,copy)
  Importer.apply(Importer.prepare(d,target,{}));assert(byId(root,'regression-added'))
  local parent=find(d.design,function(n) for _,c in ipairs(n.children) do if c.id==sourceButton.id then return true end end return false end)
  local ix=table.find(parent.children,sourceButton);table.remove(parent.children,ix)
  local p=Importer.prepare(d,target,{hideRemoved=true});assert(p.stats.removed>0);Importer.apply(p)
  assert(button.Parent and button:GetAttribute('P2R_Stale') and not button.Visible and scriptRef.Parent==button and ref.Value==button)
  table.insert(parent.children,ix,sourceButton);Importer.apply(Importer.prepare(d,target,{}))
  assert(byId(root,sourceButton.id)==button and button.Visible and not button:GetAttribute('P2R_Stale'))
 end)
 check('Class changes require confirmation and preserve old instance',function()
  sourceButton.button=false;local p=Importer.prepare(d,target,{});assert(p.stats.classChanges==1)
  assert(not pcall(function() Importer.apply(p) end));p.options.allowClassChanges=true;Importer.apply(p)
  assert(byId(root,sourceButton.id):IsA('Frame'));assert(ref.Value==button and button.Parent and button:GetAttribute('P2R_Retired') and not button.Visible and scriptRef.Parent==button)
 end)
 check('Multiple separate source designs do not collide',function()
  local other=clone(d);other.source.fileId='another-file';local p=Importer.prepare(other,target,{});assert(p.stats.added>0)
  local second=Importer.apply(p);assert(second~=root);assert(Importer.prepare(d,target,{}).stats.added==0)
 end)
 check('Missing assets warn and remain native ImageLabels',function()
  local p=Importer.prepare(d,target,{});local missing=false;for _,w in ipairs(p.warnings) do if w:find('Missing Roblox image asset',1,true) then missing=true end end;assert(missing)
 end)
 check('Invalid data is rejected without scene mutations',function()
  local bad=clone(d);table.insert(bad.design.children,clone(bad.design.children[1]));local count=#target:GetDescendants()
  assert(not pcall(function() Importer.prepare(bad,target,{}) end));assert(#target:GetDescendants()==count)
  bad=clone(d);bad.design.width=-1;assert(not pcall(function() Importer.prepare(bad,target,{}) end))
 end)
 check('Constraints use mixed Scale and Offset',function()
  local responsive=clone(d);responsive.design.children[1].constraints={horizontal='right',vertical='center'}
  local p=Importer.prepare(responsive,target,{responsive=true});local item
  for _,v in ipairs(p.items) do if v.id==responsive.design.children[1].id then item=v end end
  assert(item.props.Position.X.Scale==1 and item.props.Position.Y.Scale==.5 and item.props.Size.X.Scale==0)
  assert(p.items[1].props.Size.X.Scale==1)
 end)
 check('Nested separate imports are excluded from parent synchronization',function()
  local nested=clone(d);nested.source.fileId='nested-source'
  local parent=byId(root,d.design.id)
  local nestedRoot=Importer.apply(Importer.prepare(nested,parent,{}));local count=#nestedRoot:GetDescendants()
  local p=Importer.prepare(d,target,{});assert(p.stats.removed==0);Importer.apply(p)
  assert(#nestedRoot:GetDescendants()==count and nestedRoot.Parent==parent)
 end)
 check('Apply failures cancel partially applied changes',function()
  local bad=clone(d);bad.source.fileId='rollback-source'
  local p=Importer.prepare(bad,target,{});local before=#target:GetDescendants()
  local ok=pcall(function() Importer.apply(p,function() error('Injected progress failure') end) end)
  assert(not ok);assert(#target:GetDescendants()==before,'Undo cancellation did not restore the sandbox')
 end)
 if connection then connection:Disconnect() end
 target:Destroy()
 return results
end
