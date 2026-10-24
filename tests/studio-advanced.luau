return function(Importer,fixture)
 local Http=game:GetService('HttpService');local target=Instance.new('ScreenGui');target.Name='P2R Advanced Sandbox';target.Parent=game.StarterGui
 local d=Http:JSONDecode(Http:JSONEncode(fixture));local results={};local root,theme
 local function check(name,fn)local ok,e=pcall(fn);table.insert(results,{name=name,passed=ok,error=not ok and tostring(e)or nil})end
 local function find(id)for _,i in root:GetDescendants()do if i:GetAttribute('P2R_Id')==id and not i:GetAttribute('P2R_Retired')then return i end end end
 check('RichText imports as one escaped editable label',function()
  root=Importer.apply(Importer.prepare(d,target,{}));local label=find('rich');assert(label:IsA('TextLabel')and label.RichText);assert(label.Text:find('&lt;Value&gt;',1,true)and label.Text:find('&amp;',1,true)and label.Text:find('<u>',1,true));assert(not find('rich::surface'));assert(label.ContentText==d.design.children[1].text.value,label.ContentText)
 end)
 check('Tint, silhouette glow and explicit slice descriptors are independent',function()
  local image=find('icon::surface');local glow=find('icon::glow');assert(image.ImageColor3==Color3.fromHex('#85B5FF'));assert(image.ScaleType==Enum.ScaleType.Slice and image.SliceScale==.5);assert(glow.Position.X.Offset==-20 and glow.ZIndex<image.ZIndex);assert(find('icon'):GetAttribute('P2R_TokenBindings'):find('accent',1,true))
 end)
 check('Runtime theme module is opt-in and does not execute on import',function()
  local m=find('advanced::theme');assert(m:IsA('ModuleScript'));assert(find('panel').BackgroundColor3==Color3.new(1,1,1));theme=require(m);assert(#theme.List()==3)
 end)
 check('Theme switching resolves aliases and changes bound native colors',function()
  local r=theme.Apply(root,'Dark');assert(r.applied>=2);assert(find('panel').BackgroundColor3==Color3.fromHex('#182030'));assert(find('icon::surface').ImageColor3==Color3.fromHex('#FFAA44'))
  theme.Apply(root,'Light');assert(find('panel').BackgroundColor3==Color3.new(1,1,1));assert(find('icon::surface').ImageColor3==Color3.fromHex('#85B5FF'));assert(theme.Data.sets[2].tokens[2].value=='{brand}')
 end)
 check('Theme application respects locks and excludes nested imports',function()
  local panel=find('panel');panel:SetAttribute('P2R_Locks','BackgroundColor3');local before=panel.BackgroundColor3;theme.Apply(root,'Dark');assert(panel.BackgroundColor3==before);panel:SetAttribute('P2R_Locks',nil)
  local nested=Instance.new('Frame');nested:SetAttribute('P2R_Design','other');nested.Parent=root;local child=Instance.new('Frame');child.BackgroundColor3=Color3.new(1,1,1);child:SetAttribute('P2R_Source',root:GetAttribute('P2R_Design'));child:SetAttribute('P2R_ThemeTargets','[{"property":"BackgroundColor3","token":"surface"}]');child.Parent=nested;theme.Apply(root,'Dark');assert(child.BackgroundColor3==Color3.new(1,1,1));nested:Destroy()
 end)
 check('Theme switching keeps geometry and existing user scripts',function()
  local label=find('rich');local user=Instance.new('LocalScript');user.Name='User Logic';user.Parent=label;local reference=Instance.new('ObjectValue');reference.Value=label;reference.Parent=root
  theme.Apply(root,'Default');Importer.apply(Importer.prepare(d,target,{}));assert(find('rich')==label and reference.Value==label and user.Parent==label)
 end)
 check('Untrusted run markup and bad image geometry are rejected or escaped',function()
  local bad=Http:JSONDecode(Http:JSONEncode(d));bad.design.children[1].text.runs[1].robloxFamily='Arial" size="500';local count=#target:GetDescendants();assert(not pcall(Importer.prepare,bad,target,{}));assert(#target:GetDescendants()==count)
  bad=Http:JSONDecode(Http:JSONEncode(d));bad.design.children[3].slice.rect={90,90,10,10};assert(not pcall(Importer.prepare,bad,target,{}))
 end)
 check('Legacy text remains non-RichText and theme generation can be omitted',function()
  local copy=Http:JSONDecode(Http:JSONEncode(d));copy.options.runtimeThemes=false;copy.design.children[1].text.runs=nil;copy.source.fileId='plain';local plan=Importer.prepare(copy,target,{});for _,item in plan.items do assert(item.id~='advanced::theme');if item.id=='rich'then assert(not item.props.RichText)end end
 end)
 target:Destroy();return results
end
