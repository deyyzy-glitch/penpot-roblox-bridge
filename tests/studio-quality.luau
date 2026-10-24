return function(Importer,fixture,Assets)
 local Http=game:GetService('HttpService');local results={}
 local function clone(v)return Http:JSONDecode(Http:JSONEncode(v))end
 local function check(name,fn)local ok,e=pcall(fn);table.insert(results,{name=name,passed=ok,error=not ok and tostring(e)or nil})end
 local target=Instance.new('ScreenGui');target.Name='P2R Quality Sandbox';target.Parent=game.StarterGui
 local d=clone(fixture);local root
 local function byId(id)for _,i in root:GetDescendants()do if i:GetAttribute('P2R_Id')==id and not i:GetAttribute('P2R_Retired')then return i end end end
 check('Native corners and shadow retain editable appearance',function()
  local p=Importer.prepare(d,target,{});root=Importer.apply(p)
  assert(byId('effects::shadow1'):IsA('UIShadow'));assert(byId('effects::corner').TopLeftRadius.Offset==0 and byId('effects::corner').TopRightRadius.Offset==24)
  assert(not byId('effects::surface'));assert(byId('effects').BackgroundTransparency==0)
 end)
 check('Quality report agrees with generated appearance and typography',function()
  local q=Importer.prepare(d,target,{}).quality;assert(q.images==1 and q.smoothed==1 and q.native==13 and q.fonts==1 and q.layouts==3,Http:JSONEncode(q))
 end)
 check('Fallback assets do not upload on capable Studio',function()
  local a=d.assets[1];for _,v in d.assets do if v.fallback then a=v end end
  assert(a.fallback and not Importer.assetNeeded(d,a));local p={GetSetting=function()return {}end};local pending=Assets.pending(d,p,Importer);assert(#pending==2)
 end)
 check('Older engine capability set uses image fallback',function()
  local p=Importer.prepare(d,target,{capabilities={corners=false,shadows=false}});local found=false
  for _,i in p.items do assert(i.class~='UIShadow');if i.id=='effects::surface'then found=true end end
  assert(found and p.quality.images==2)
 end)
 check('Wrapped items keep row order and layout positions',function()
  task.wait(.2);assert(byId('wrap::layout').Wraps);assert(byId('w3').AbsolutePosition.Y>byId('w1').AbsolutePosition.Y+30);assert(byId('w2').AbsolutePosition.X>byId('w1').AbsolutePosition.X+80)
 end)
 check('Space-between distributes remaining desktop width',function()
  assert(byId('row::layout').HorizontalFlex==Enum.UIFlexAlignment.SpaceBetween)
  assert(math.abs(byId('b').AbsolutePosition.X-byId('a').AbsolutePosition.X-300)<2)
 end)
 check('Fill child grows through native UIFlexItem',function()
  assert(byId('grow::flex'):IsA('UIFlexItem'));assert(math.abs(byId('grow').AbsoluteSize.X-190)<2,tostring(byId('grow').AbsoluteSize))
  byId('fill').Size=UDim2.fromOffset(400,80);task.wait(.2);assert(math.abs(byId('grow').AbsoluteSize.X-290)<2,tostring(byId('grow').AbsoluteSize))
 end)
 check('Smoothed surface uses a scalable image without runtime scripts',function()
  local s=byId('smooth::smooth');assert(s:IsA('ImageLabel') and s.ScaleType==Enum.ScaleType.Slice and s.SliceScale==.5);assert(byId('smooth').BackgroundTransparency==1)
  assert(not byId('smooth::corner'));for _,i in root:GetDescendants()do assert(not i:IsA('LuaSourceContainer'))end
 end)
 check('Reimport preserves user scripts and native object references',function()
  local effects=byId('effects');local user=Instance.new('LocalScript');user.Name='UserScript';user.Parent=effects
  local p=Importer.prepare(d,target,{});Importer.apply(p);assert(byId('effects')==effects and user.Parent==effects)
 end)
 check('Switching appearance modes retires old visuals without duplicates',function()
  local oldShadow=byId('effects::shadow1');local oldCorner=byId('effects::corner')
  Importer.apply(Importer.prepare(d,target,{capabilities={corners=false,shadows=false}}));local surface=byId('effects::surface');assert(surface.Visible and not oldShadow.Enabled and oldCorner.Parent:IsA('Folder'))
  Importer.apply(Importer.prepare(d,target,{}));assert(not surface.Visible and oldShadow.Enabled and oldCorner.Parent==byId('effects'))
  local copy=clone(d);for _,n in copy.design.children do if n.id=='smooth'then n.smooth=nil;n.radius=24 end end
  local oldSmooth=byId('smooth::smooth');Importer.apply(Importer.prepare(copy,target,{}));assert(not oldSmooth.Visible and byId('smooth::corner'))
  Importer.apply(Importer.prepare(d,target,{}));assert(oldSmooth.Visible and byId('smooth::corner').Parent:IsA('Folder'))
 end)
 check('Malformed modern metadata is rejected before mutation',function()
  local bad=clone(d);bad.design.children[1].radii={1,2};local count=#target:GetDescendants();assert(not pcall(Importer.prepare,bad,target,{}));assert(#target:GetDescendants()==count)
  bad=clone(d);for _,n in bad.design.children do if n.smooth then n.smooth.slice={50,50,1,1}end end;assert(not pcall(Importer.prepare,bad,target,{}))
 end)
 target:Destroy();return results
end
