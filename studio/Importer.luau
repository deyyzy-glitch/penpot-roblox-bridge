-- No network, plugin globals, or game logic. All source-driven writes are explicit.
local Http = game:GetService('HttpService')
local Behaviors=require(script.Parent.Behaviors)
local Importer = {}
local measurementCache={}
local function color(s)
 assert(type(s)=='string' and s:match('^#%x%x%x%x%x%x$'), 'Expected #RRGGBB color')
 return Color3.fromHex(s)
end
local function finite(n) return type(n)=='number' and n==n and math.abs(n)<10000000 end
local function number(n, lo, hi, label)
 assert(finite(n) and n>=lo and n<=hi, 'Invalid '..label)
end
local function signature(v)
 if type(v)=='number' then return string.format('%.5f',v) end
 if typeof(v)=='Font' then return v.Family..':'..v.Weight.Name..':'..v.Style.Name end
 return tostring(v)
end
local function decode(s)
 local ok,v=pcall(function() return Http:JSONDecode(s or '') end)
 return ok and type(v)=='table' and v or {}
end
local function locked(i,p)
 for field in string.gmatch(i:GetAttribute('P2R_Locks') or '', '[^,%s]+') do
  if field==p or field=='*' then return true end
 end
 return false
end
function Importer.validate(d)
 assert(type(d)=='table' and d.format=='penpot-roblox' and (d.version==1 or d.version==2),'Unsupported document format/version. Update the Studio plugin for newer exports.')
 assert(type(d.source)=='table','Missing source')
 for _,k in {'fileId','pageId','rootId'} do assert(type(d.source[k])=='string' and #d.source[k]>0 and #d.source[k]<200,'Invalid source '..k) end
 assert(type(d.design)=='table' and d.design.id==d.source.rootId,'Root identity mismatch')
 assert(d.options==nil or type(d.options)=='table','Invalid document options')
 if d.options then assert(d.options.behaviors==nil or type(d.options.behaviors)=='boolean','Invalid behavior opt-in')end
 assert(type(d.assetMap or {})=='table' and type(d.fontMap or {})=='table','Invalid mapping tables')
 for k,v in pairs(d.assetMap or {}) do assert(type(k)=='string' and type(v)=='string' and v:match('^rbxassetid://%d+$'),'Asset map values must be rbxassetid://NUMBER') end
 for k,v in pairs(d.fontMap or {}) do assert(type(k)=='string' and type(v)=='string' and (v:match('^rbxasset://fonts/families/[%w_-]+%.json$') or v:match('^rbxassetid://%d+$')),'Invalid font family URI') end
 local ids,count,panels,actions={},0,{},{}
 local types={board=true,group=true,rectangle=true,text=true,ellipse=true,path=true,boolean=true,['svg-raw']=true,image=true}
 local function walk(n,depth)
  count+=1; assert(count<=5000 and depth<=64,'Document exceeds shape/depth limit')
  assert(type(n)=='table' and type(n.id)=='string' and #n.id>0 and #n.id<200 and not n.id:find('::',1,true) and not ids[n.id],'Duplicate/invalid ID')
  ids[n.id]=true; assert(types[n.type],'Unsupported shape type: '..tostring(n.type))
  assert(type(n.name)=='string' and #n.name<=1000,'Invalid shape name')
  for _,k in {'x','y','rotation'} do number(n[k],-1000000,1000000,k) end
  for _,k in {'width','height'} do number(n[k],0,100000,k) end
  number(n.opacity or 1,0,1,'opacity'); number(n.radius or 0,0,100000,'radius')
  assert(type(n.children)=='table' and type(n.fills or {})=='table' and type(n.strokes or {})=='table','Invalid children/style arrays')
  if n.assetKey then assert(type(n.assetKey)=='string','Invalid asset key') end
  for _,field in {'nativeGroup','scroll','initiallyClosed'} do assert(n[field]==nil or type(n[field])=='boolean','Invalid '..field) end
  assert(not n.nativeGroup or (not n.assetKey and n.clip==true and not n.button and not n.scroll and n.type~='text'),'Native group requires a clipped native container')
  assert(not n.scroll or (not n.assetKey and not n.button and n.type~='text'),'Scrolling requires a native container')
  if n.behavior then
   assert(type(n.behavior)=='table','Invalid behavior metadata')
   for _,field in {'panel','action','target'} do assert(type(n.behavior[field])=='string' and #n.behavior[field]<=128,'Invalid behavior '..field) end
   local b=n.behavior;assert(b.action=='' or b.action=='open' or b.action=='close','Unsupported action')
   if b.panel~='' then assert(not panels[b.panel],'Duplicate panel name');panels[b.panel]=true end
   if b.action~='' then assert(n.button,'Panel action must be a button');table.insert(actions,b.target) end
   assert(not n.initiallyClosed or b.panel~='','Closed state requires a panel')
  end
  if n.rasterBounds then for _,k in {'x','y'} do number(n.rasterBounds[k],-1000000,1000000,'raster '..k) end;for _,k in {'width','height'} do number(n.rasterBounds[k],0,1000000,'raster '..k) end end
  for _,f in ipairs(n.fills or {}) do
   if f.fillColor then color(f.fillColor) end
   number(f.fillOpacity or 1,0,1,'fill opacity')
   local g=f.fillColorGradient
   if g then
    assert(g.type=='linear' or g.type=='radial','Invalid gradient type')
    for _,k in {'startX','startY','endX','endY'} do number(g[k],-10000,10000,'gradient coordinate') end
    assert(type(g.stops)=='table' and #g.stops>=2 and #g.stops<=20,'Gradient must have 2–20 stops')
    local previous=-1
    for _,s in ipairs(g.stops) do color(s.color);number(s.offset,0,1,'stop');number(s.opacity or 1,0,1,'stop opacity');assert(s.offset>previous,'Gradient stops must strictly increase');previous=s.offset end
   end
  end
  for _,s in ipairs(n.strokes or {}) do if s.strokeColor then color(s.strokeColor) end;number(s.strokeWidth or 1,0,1000,'stroke width');number(s.strokeOpacity or 1,0,1,'stroke opacity') end
  if n.type=='text' then
   local t=n.text;assert(type(t)=='table' and type(t.value)=='string' and #t.value<=100000,'Invalid text')
   number(t.size,1,1000,'font size');number(t.weight or 400,100,1000,'font weight');number(t.lineHeight or 1.2,0,100,'line height')
   if t.measuredWidth then number(t.measuredWidth,0,1000000,'measured text width');number(t.measuredHeight,0,1000000,'measured text height') end
  end
  if n.layout and n.layout.native then
   assert(n.layout.dir=='row' or n.layout.dir=='column','Invalid native layout direction')
   number(n.layout.gap or 0,0,100000,'layout gap')
   assert(type(n.layout.padding)=='table' and #n.layout.padding==4,'Invalid padding')
   for _,v in ipairs(n.layout.padding) do number(v,0,100000,'padding') end
  end
  for _,c in ipairs(n.children) do walk(c,depth+1) end
 end
 walk(d.design,0)
 for _,target in actions do assert(panels[target],'Panel action target does not exist: '..target) end
 return count
end
local function axis(pos,size,parentSize,constraint)
 if constraint=='right' or constraint=='bottom' then return 1,pos-parentSize,0,size end
 if constraint=='center' then return .5,pos-parentSize/2,0,size end
 if constraint=='leftright' or constraint=='topbottom' then return 0,pos,1,size-parentSize end
 if constraint=='scale' and parentSize>0 then return pos/parentSize,0,size/parentSize,0 end
 return 0,pos,0,size
end
local function descriptors(d,options)
 local result,warnings={},table.clone(d.warnings or {})
 local function warn(n,s) table.insert(warnings,n.name..': '..s) end
 local function add(id,parent,class,props,attributes)
  local item={id=id,parent=parent,class=class,props=props,attributes=attributes}
  -- Validate every engine property on detached instances before any scene mutation.
  local probe=Instance.new(class)
  local ok,e=pcall(function()
   for k,v in pairs(props) do probe[k]=v end
   -- Engine properties may quantize (notably TextSize). Compare against stored values.
   for k in pairs(props) do props[k]=probe[k] end
  end)
  probe:Destroy();assert(ok,'Conversion validation: '..tostring(e));table.insert(result,item)
  if #result%100==0 then task.wait() end
 end
 local z=0
 local hasActions=false
 local function walk(n,parent,parentNode,inheritedOpacity)
  z+=1
  local nativeGroup=n.nativeGroup==true
  local scroll=n.scroll==true and d.options and d.options.behaviors==true
  local opacity=nativeGroup and 1 or inheritedOpacity*(n.opacity or 1)
  local text=n.type=='text'
  local raster=n.assetKey~=nil
  local image=raster and not n.rasterSurface
  local class=scroll and 'ScrollingFrame' or nativeGroup and 'CanvasGroup' or text and (n.button and 'TextButton' or 'TextLabel') or (image and (n.button and 'ImageButton' or 'ImageLabel') or (n.button and 'TextButton' or 'Frame'))
  local f=(n.fills or {})[1]
  local psx,px,ssx,sx=axis(n.x,n.width,parentNode and parentNode.width or n.width,options.responsive and n.constraints and n.constraints.horizontal)
  local psy,py,ssy,sy=axis(n.y,n.height,parentNode and parentNode.height or n.height,options.responsive and n.constraints and n.constraints.vertical)
  if not parent then
   psx,px,psy,py=0,0,0,0
   ssx,sx,ssy,sy=options.responsive and 1 or 0,options.responsive and 0 or n.width,options.responsive and 1 or 0,options.responsive and 0 or n.height
  end
  local layoutOrder=z
  if parentNode and parentNode.layout and parentNode.layout.native then
   local axisName=parentNode.layout.dir=='row' and 'x' or 'y'
   layoutOrder=0
   for _,sibling in ipairs(parentNode.children) do
    if sibling[axisName]<n[axisName] or (sibling[axisName]==n[axisName] and sibling.id<n.id) then layoutOrder+=1 end
   end
  end
  local p={Name=n.name,Position=UDim2.new(psx,px,psy,py),Size=UDim2.new(ssx,sx,ssy,sy),AnchorPoint=Vector2.zero,
   Rotation=n.rotation,Visible=n.visible~=false,BorderSizePixel=0,ZIndex=z,LayoutOrder=layoutOrder,
   BackgroundColor3=f and f.fillColor and color(f.fillColor) or Color3.new(1,1,1),
   BackgroundTransparency=(text or raster or n.visualSuppressed or not f) and 1 or 1-opacity*(f.fillOpacity or 1),
   ClipsDescendants=n.clip==true and not raster,AutomaticSize=Enum.AutomaticSize.None}
  if n.clip and n.rotation~=0 then warn(n,'Roblox clipping with rotated objects may differ.') end
  if n.opacity and n.opacity<1 and #n.children>0 and not nativeGroup and not raster then warn(n,'Container opacity is multiplied into descendants; overlapping children may composite differently.') end
  if nativeGroup then p.GroupTransparency=1-inheritedOpacity*(n.opacity or 1);p.GroupColor3=Color3.new(1,1,1) end
  if scroll then p.ClipsDescendants=true;p.ScrollingDirection=Enum.ScrollingDirection.Y;p.AutomaticCanvasSize=Enum.AutomaticSize.Y;p.CanvasSize=UDim2.new();p.ScrollBarThickness=6 end
  local behavior=d.options and d.options.behaviors and n.behavior or nil
  if behavior and n.initiallyClosed then p.Visible=false end
  if class=='TextButton' or class=='ImageButton' then p.AutoButtonColor=false end
  if class=='TextButton' then p.Text='' end
  if text then
   local t=n.text
   p.Text=t.value
   if t.transform=='uppercase' then p.Text=string.upper(p.Text) elseif t.transform=='lowercase' then p.Text=string.lower(p.Text) elseif t.transform=='capitalize' then warn(n,'Capitalization requires manual review.') end
   p.RichText=false;p.TextScaled=false;p.TextWrapped=true;p.TextSize=t.size
   p.TextColor3=f and f.fillColor and color(f.fillColor) or Color3.new(0,0,0)
   p.TextTransparency=1-opacity*(f and f.fillOpacity or 1)
   p.TextStrokeTransparency=1
   p.TextXAlignment=({left=Enum.TextXAlignment.Left,center=Enum.TextXAlignment.Center,right=Enum.TextXAlignment.Right})[t.align] or Enum.TextXAlignment.Left
   p.TextYAlignment=({top=Enum.TextYAlignment.Top,center=Enum.TextYAlignment.Center,bottom=Enum.TextYAlignment.Bottom})[t.verticalAlign] or Enum.TextYAlignment.Top
   p.LineHeight=math.clamp(t.lineHeight or 1.2,1,3)
   local family=(d.fontMap or {})[t.family or '']
   local known={Arial=Enum.Font.Arial,arial=Enum.Font.Arial,sourcesanspro=Enum.Font.SourceSans,['Source Sans Pro']=Enum.Font.SourceSans,['Roboto']=Enum.Font.Roboto,roboto=Enum.Font.Roboto,['Ubuntu']=Enum.Font.Ubuntu,ubuntu=Enum.Font.Ubuntu,['Gotham']=Enum.Font.Gotham,SourceSans=Enum.Font.SourceSans,BuilderSans=Enum.Font.BuilderSans,RobotoMono=Enum.Font.RobotoMono,RobotoCondensed=Enum.Font.RobotoCondensed}
   if not family then
    local mapped=known[t.robloxFamily or ''] or known[t.family]
    family=Font.fromEnum(mapped or Enum.Font.Arial).Family
    if not mapped and not raster then warn(n,'Font '..tostring(t.family)..' substituted with Arial; map a Roblox font family URI for a closer match.') end
   end
   local weights={Enum.FontWeight.Thin,Enum.FontWeight.ExtraLight,Enum.FontWeight.Light,Enum.FontWeight.Regular,Enum.FontWeight.Medium,Enum.FontWeight.SemiBold,Enum.FontWeight.Bold,Enum.FontWeight.ExtraBold,Enum.FontWeight.Heavy}
   p.FontFace=Font.new(family,weights[math.clamp(math.floor((t.weight or 400)/100+.5),1,9)],t.italic and Enum.FontStyle.Italic or Enum.FontStyle.Normal)
   -- Roblox TextSize denotes line height, while CSS/Penpot uses font em size.
   -- Match a measured single line, avoiding a guessed universal size multiplier.
   if not raster and t.measuredWidth and t.measuredWidth>0 and t.measuredWidth<=n.width+.1 and t.measuredHeight<=t.size*1.8 and not t.value:find('\n',1,true) and (t.letterSpacing or 0)==0 then
    local cacheKey=signature(p.FontFace)..'/'..t.size..'/'..p.Text..'/'..t.measuredWidth
    if measurementCache[cacheKey] then p.TextSize=measurementCache[cacheKey]
    else
     local params=Instance.new('GetTextBoundsParams');params.Font=p.FontFace;params.Text=p.Text;params.Size=t.size;params.Width=1000000
     local ok,bounds=pcall(function() return game:GetService('TextService'):GetTextBoundsAsync(params) end)
     if ok and bounds.X>0 then
      local estimate=math.clamp(t.size*t.measuredWidth/bounds.X,1,1000)
      local best,errorWidth=math.floor(estimate+.5),math.huge
      for candidate=math.max(1,math.floor(estimate)-1),math.min(1000,math.ceil(estimate)+1) do
       params.Size=candidate
       local measuredOk,measured=pcall(function() return game:GetService('TextService'):GetTextBoundsAsync(params) end)
       if measuredOk and math.abs(measured.X-t.measuredWidth)<errorWidth then best=candidate;errorWidth=math.abs(measured.X-t.measuredWidth) end
      end
      p.TextSize=best;measurementCache[cacheKey]=p.TextSize
     else warn(n,'Font measurement failed; nominal font size retained.') end
     params:Destroy()
    end
   elseif not raster and t.value~='' then warn(n,'Wrapped/multiline text uses nominal font size; review line breaks and font metrics.') end
   if raster or n.visualSuppressed then p.TextTransparency=1 end
  end
  if image then
   p.Image='';p.ImageColor3=Color3.new(1,1,1);p.ImageTransparency=1;p.ScaleType=Enum.ScaleType.Stretch
  end
  if behavior and behavior.action~='' then hasActions=true end
  add(n.id,parent,class,p,{P2R_Panel=behavior and behavior.panel or '',P2R_Action=behavior and behavior.action or '',P2R_Target=behavior and behavior.target or ''})
  if raster then
   local asset=(d.assetMap or {})[n.assetKey]
   local b=n.rasterBounds or {x=0,y=0,width=n.width,height=n.height}
   add(n.id..'::surface',n.id,'ImageLabel',{Name='Penpot Visual Surface',BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(b.x,b.y),Size=UDim2.fromOffset(b.width,b.height),Image=asset or '',ImageColor3=Color3.new(1,1,1),ImageTransparency=1-inheritedOpacity,ScaleType=Enum.ScaleType.Stretch,ZIndex=z,Visible=not n.visualSuppressed})
   if not asset then warn(n,'Missing Roblox image asset: '..n.assetKey..'. Upload pending images before importing.') end
  end
  if not raster and not n.visualSuppressed then
   if (n.radius or 0)>0 or n.type=='ellipse' then add(n.id..'::corner',n.id,'UICorner',{Name='Penpot Corner',CornerRadius=n.type=='ellipse' and UDim.new(.5,0) or UDim.new(0,n.radius)}) end
   for index,s in ipairs(n.strokes or {}) do
    if index>1 then warn(n,'Additional strokes omitted.');break end
    if s.strokeStyle~='none' then
     if s.strokeStyle and s.strokeStyle~='solid' then warn(n,'Dashed/vector stroke converted to solid.') end
     if s.strokeColorGradient then warn(n,'Stroke gradient omitted.') end
     local align=({inner=Enum.BorderStrokePosition.Inner,outer=Enum.BorderStrokePosition.Outer,center=Enum.BorderStrokePosition.Center})[s.strokeAlignment] or Enum.BorderStrokePosition.Center
     add(n.id..'::stroke',n.id,'UIStroke',{Name='Penpot Stroke',Color=s.strokeColor and color(s.strokeColor) or Color3.new(0,0,0),Thickness=s.strokeWidth or 1,Transparency=1-opacity*(s.strokeOpacity or 1),ApplyStrokeMode=Enum.ApplyStrokeMode.Border,BorderStrokePosition=align,Enabled=true})
    end
   end
   local g=f and f.fillColorGradient
   if g then
    if g.type~='linear' then warn(n,'Radial gradient needs a raster asset; first fill color retained.')
    else
     local colors,alpha={},{}
     local stops=table.clone(g.stops)
     if stops[1].offset>0 then local s=table.clone(stops[1]);s.offset=0;table.insert(stops,1,s) end
     if stops[#stops].offset<1 then local s=table.clone(stops[#stops]);s.offset=1;table.insert(stops,s) end
     for _,s in ipairs(stops) do table.insert(colors,ColorSequenceKeypoint.new(s.offset,color(s.color)));table.insert(alpha,NumberSequenceKeypoint.new(s.offset,1-(s.opacity or 1))) end
     local dx=(g.endX-g.startX)*n.width;local dy=(g.endY-g.startY)*n.height
     if math.abs(g.startX)+math.abs(g.startY)+math.abs(g.endX)+math.abs(g.endY)>4 then warn(n,'Gradient coordinates are outside normalized bounds; review angle.') end
     if text then p.TextColor3=Color3.new(1,1,1) else p.BackgroundColor3=Color3.new(1,1,1) end
     -- The descriptor references p, so this update is included in the plan.
     add(n.id..'::gradient',n.id,'UIGradient',{Name='Penpot Gradient',Color=ColorSequence.new(colors),Transparency=NumberSequence.new(alpha),Rotation=math.deg(math.atan2(dy,dx)),Offset=Vector2.new((g.startX+g.endX)/2-.5,(g.startY+g.endY)/2-.5),Enabled=true})
     if math.abs(math.sqrt(dx*dx+dy*dy)-(math.abs(math.cos(math.atan2(dy,dx)))*n.width+math.abs(math.sin(math.atan2(dy,dx)))*n.height))>.1 then warn(n,'Gradient span differs from Roblox edge-to-edge interpolation; review or rasterize.') end
    end
   end
  end
  if n.layout and n.layout.native then
   local l=n.layout;local pad=l.padding;local horizontal=l.dir=='row'
   local h=horizontal and Enum.HorizontalAlignment.Left or (({start=Enum.HorizontalAlignment.Left,center=Enum.HorizontalAlignment.Center,['end']=Enum.HorizontalAlignment.Right})[l.align] or Enum.HorizontalAlignment.Left)
   local v=horizontal and (({start=Enum.VerticalAlignment.Top,center=Enum.VerticalAlignment.Center,['end']=Enum.VerticalAlignment.Bottom})[l.align] or Enum.VerticalAlignment.Top) or Enum.VerticalAlignment.Top
   add(n.id..'::padding',n.id,'UIPadding',{Name='Penpot Padding',PaddingTop=UDim.new(0,pad[1]),PaddingRight=UDim.new(0,pad[2]),PaddingBottom=UDim.new(0,pad[3]),PaddingLeft=UDim.new(0,pad[4])})
   add(n.id..'::layout',n.id,'UIListLayout',{Name='Penpot Layout',FillDirection=horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,Padding=UDim.new(0,l.gap or 0),SortOrder=Enum.SortOrder.LayoutOrder,HorizontalAlignment=h,VerticalAlignment=v})
  end
  for _,c in ipairs(n.children) do walk(c,n.id,n,opacity) end
 end
 walk(d.design,nil,nil,1)
 if hasActions then
  add(d.design.id..'::controller',nil,'LocalScript',{Name='Penpot Bridge Controller',Source=Behaviors.source(),Disabled=false})
  table.insert(warnings,'Optional panel actions generate one LocalScript. Existing gameplay scripts remain untouched.')
 end
 return result,warnings
end
function Importer.prepare(d,target,options)
 options=options or {}
 Importer.validate(d)
 assert(target==game:GetService('StarterGui') or target:IsA('ScreenGui') or target:IsA('GuiObject'),'Choose StarterGui, ScreenGui, or a GuiObject')
 local key=d.source.fileId..'/'..d.source.rootId
 local wrapper
 for _,i in target:GetChildren() do
  if i:GetAttribute('P2R_Design')==key then assert(not wrapper,'Duplicate imported design containers; resolve manually');wrapper=i end
 end
 local items,warnings=descriptors(d,options)
 local nativeGroups=false
 for _,item in items do if item.class=='CanvasGroup' then nativeGroups=true end end
 if nativeGroups and target~=game:GetService('StarterGui') then
  local screen=target:IsA('ScreenGui') and target or target:FindFirstAncestorWhichIsA('ScreenGui')
  assert(not screen or screen.ZIndexBehavior==Enum.ZIndexBehavior.Sibling,'Native opacity groups need a ScreenGui with ZIndexBehavior Sibling. Import into StarterGui or disable native groups in Penpot and re-export.')
 end
 if nativeGroups then table.insert(warnings,'Native opacity groups use CanvasGroup and sibling Z ordering. New group classes need confirmation when updating an older import.') end
 local index={}
 if wrapper then
  for _,i in wrapper:GetDescendants() do
   local id=i:GetAttribute('P2R_Id')
   if id and i:GetAttribute('P2R_Source')==key and not i:GetAttribute('P2R_Retired') then assert(not index[id],'Duplicate imported ID '..id);index[id]=i end
  end
 end
 local wanted={};local stats={added=0,updated=0,unchanged=0,removed=0,classChanges=0,conflicts=0,reparented=0}
 local changes={}
 for _,item in items do
  wanted[item.id]=true
  local old=index[item.id];item.existing=old
  local kind=not old and 'add' or old.ClassName~=item.class and 'class' or 'update'
  item.kind=kind
  local action=kind
  if kind=='add' then stats.added+=1 elseif kind=='class' then stats.classChanges+=1 else
   local last=decode(old:GetAttribute('P2R_Last'));local modified=false
   for attribute,value in pairs(item.attributes or {}) do if old:GetAttribute(attribute)~=value then modified=true end end
   for prop,value in pairs(item.props) do
    if signature(old[prop])~=signature(value) then
     if locked(old,prop) or (last[prop] and signature(old[prop])~=last[prop] and not options.force) then
      stats.conflicts+=1;table.insert(warnings,item.id..'.'..prop..': local override retained; use P2R_Locks or Force design values.');
     else modified=true end
    end
   end
   local desiredParent=item.parent and index[item.parent] or wrapper
   if old.Parent~=desiredParent then modified=true;stats.reparented+=1 end
   if modified then stats.updated+=1 else stats.unchanged+=1;action='unchanged' end
  end
  if action~='unchanged' then table.insert(changes,{id=item.id,name=item.props.Name,action=action}) end
 end
 for id,old in pairs(index) do
  if not wanted[id] and not old:GetAttribute('P2R_Stale') then stats.removed+=1;table.insert(changes,{id=id,name=old.Name,action='retain stale'}) end
 end
 return {document=d,target=target,options=options,key=key,wrapper=wrapper,index=index,items=items,wanted=wanted,stats=stats,warnings=warnings,changes=changes,nativeGroups=nativeGroups}
end
function Importer.apply(plan,onProgress)
 assert(plan.stats.classChanges==0 or plan.options.allowClassChanges,'Class changes require confirmation; old objects will be retained')
 local history=game:GetService('ChangeHistoryService')
 local recording=history:TryBeginRecording('PenpotImport','Import '..plan.document.design.name)
 assert(recording,'Cannot begin undo recording. Finish the current Studio operation first.')
 local ok,result=pcall(function()
  local wrapper=plan.wrapper
  if not wrapper then
   wrapper=Instance.new(plan.target==game:GetService('StarterGui') and 'ScreenGui' or 'Frame')
   wrapper.Name=plan.document.design.name..' • Penpot'
   if wrapper:IsA('ScreenGui') then wrapper.ResetOnSpawn=false;wrapper.IgnoreGuiInset=true;wrapper.ZIndexBehavior=Enum.ZIndexBehavior.Global
   else wrapper.BackgroundTransparency=1;wrapper.BorderSizePixel=0;wrapper.Size=UDim2.fromScale(1,1) end
   wrapper:SetAttribute('P2R_Design',plan.key);wrapper.Parent=plan.target
  end
  if plan.nativeGroups and wrapper:IsA('ScreenGui') then wrapper.ZIndexBehavior=Enum.ZIndexBehavior.Sibling end
  local resolved={}
  for ix,item in ipairs(plan.items) do
   local i=item.existing
   if item.kind=='class' then
    i:SetAttribute('P2R_Retired',true)
    if i:IsA('GuiObject') then i.Visible=false elseif i:IsA('UIComponent') and i:IsA('UIListLayout') then i.Parent=nil end
    -- Preserve the old instance and every user child/reference. New ID owner is separate.
    if i:IsA('UIListLayout') or i:IsA('UIPadding') then error('Layout class replacement requires manual resolution') end
    i=nil
   end
   local fresh=not i
   if fresh then i=Instance.new(item.class);i:SetAttribute('P2R_Id',item.id) end
   i:SetAttribute('P2R_Source',plan.key)
   local last=decode(i:GetAttribute('P2R_Last'))
   if i:IsA('LocalScript') and i:GetAttribute('P2R_DisabledByImporter') then
    i.Disabled=i:GetAttribute('P2R_PreStaleDisabled')==true;i:SetAttribute('P2R_DisabledByImporter',nil);i:SetAttribute('P2R_PreStaleDisabled',nil)
   end
   if i:GetAttribute('P2R_HiddenByImporter') then
    if i:IsA('GuiObject') then i.Visible=i:GetAttribute('P2R_PreStaleVisible')~=false end
    if i:IsA('UIGradient') or i:IsA('UIStroke') then i.Enabled=true end
    i:SetAttribute('P2R_HiddenByImporter',nil);i:SetAttribute('P2R_PreStaleVisible',nil)
   end
   for prop,value in pairs(item.props) do
    if fresh or (not locked(i,prop) and (plan.options.force or not last[prop] or signature(i[prop])==last[prop])) then
     i[prop]=value;last[prop]=signature(i[prop])
    end
   end
   for attribute,value in pairs(item.attributes or {}) do i:SetAttribute(attribute,value) end
   i:SetAttribute('P2R_Last',Http:JSONEncode(last));i:SetAttribute('P2R_Stale',nil)
   i.Parent=item.parent and resolved[item.parent] or wrapper
   resolved[item.id]=i
   if onProgress and ix%25==0 then onProgress(ix,#plan.items) end
   if ix%100==0 then task.wait() end
  end
  for id,i in pairs(plan.index) do
   if not plan.wanted[id] then
    i:SetAttribute('P2R_Stale',true)
    if i:IsA('LocalScript') and not i:GetAttribute('P2R_DisabledByImporter') then
     i:SetAttribute('P2R_PreStaleDisabled',i.Disabled);i:SetAttribute('P2R_DisabledByImporter',true);i.Disabled=true
    end
    if plan.options.hideRemoved then
     if i:IsA('GuiObject') and not i:GetAttribute('P2R_HiddenByImporter') then
      i:SetAttribute('P2R_PreStaleVisible',i.Visible);i:SetAttribute('P2R_HiddenByImporter',true);i.Visible=false
     elseif i:IsA('UIGradient') or i:IsA('UIStroke') then i:SetAttribute('P2R_HiddenByImporter',true);i.Enabled=false
     elseif i:IsA('UIListLayout') or i:IsA('UIPadding') or i:IsA('UICorner') then
      -- Components have no Enabled flag: retain them outside the rendered hierarchy.
      local retained=wrapper:FindFirstChild('P2R Retained Components')
      if not retained then retained=Instance.new('Folder');retained.Name='P2R Retained Components';retained.Parent=wrapper end
      i.Parent=retained
     end
    end
   end
  end
  wrapper:SetAttribute('P2R_Version',plan.document.version)
  return wrapper
 end)
 history:FinishRecording(recording,ok and Enum.FinishRecordingOperation.Commit or Enum.FinishRecordingOperation.Cancel)
 assert(ok,result)
 return result
end
return Importer
