-- No network, plugin globals, or game logic. All source-driven writes are explicit.
local Http = game:GetService('HttpService')
local Behaviors=require(script.Parent.Behaviors)
local RichText=require(script.Parent.RichText)
local Themes=require(script.Parent.Themes)
local References=require(script.Parent.References)
local Templates=require(script.Parent.Templates)
local Gradient=require(script.Parent.Gradient)
local Importer = {}
Importer.getTemplates=Templates.read
Importer.mapTemplate=Templates.register
local measurementCache={}
local function nativeVisual(n,capabilities)
 if not n.nativeVisual then return false end
 if n.radii and (n.radii[1]~=n.radii[2] or n.radii[1]~=n.radii[3] or n.radii[1]~=n.radii[4]) and not capabilities.corners then return false end
 if #(n.shadows or {})>0 and not capabilities.shadows then return false end
 return true
end
function Importer.capabilities()
 local c=Instance.new('UICorner');local corners=pcall(function()c.TopLeftRadius=UDim.new(0,1)end);c:Destroy()
 local shadows,s=pcall(Instance.new,'UIShadow');if shadows then s:Destroy()end
 return {corners=corners,shadows=shadows}
end
function Importer.assetNeeded(d,asset)
 return Importer.assetFilter(d)(asset)
end
function Importer.assetFilter(d)
 local nodes={};local function walk(n)nodes[n.id]=n;for _,c in ipairs(n.children)do walk(c)end end;walk(d.design)
 local capabilities=Importer.capabilities()
 return function(asset)return not asset.fallback or not nodes[asset.shapeId] or not nativeVisual(nodes[asset.shapeId],capabilities)end
end
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
 assert(type(d)=='table' and d.format=='penpot-roblox' and table.find({1,2,3,4,5},d.version),'Unsupported document format/version. Update the Studio plugin for newer exports.')
 assert(type(d.source)=='table','Missing source')
 for _,k in {'fileId','pageId','rootId'} do assert(type(d.source[k])=='string' and #d.source[k]>0 and #d.source[k]<200,'Invalid source '..k) end
 assert(type(d.design)=='table' and d.design.id==d.source.rootId,'Root identity mismatch')
 assert(d.options==nil or type(d.options)=='table','Invalid document options')
 if d.options then for _,key in {'behaviors','runtimeThemes','autoTint'}do assert(d.options[key]==nil or type(d.options[key])=='boolean','Invalid '..key..' opt-in')end end
 if d.tokens then
  assert(type(d.tokens)=='table' and type(d.tokens.palettes)=='table' and type(d.tokens.themes)=='table' and type(d.tokens.sets)=='table','Invalid token catalog')
  assert(#d.tokens.sets<=64 and #d.tokens.themes<=32 and #Http:JSONEncode(d.tokens)<=2000000,'Token catalog too large')
  if d.tokens.bindingNames then assert(type(d.tokens.bindingNames)=='table','Invalid token identities');local count=0;for id,name in d.tokens.bindingNames do count+=1;assert(count<=2000 and type(id)=='string' and type(name)=='string' and #id<=200 and #name<=200,'Invalid token identity')end end
  local palettes=0;for name,p in d.tokens.palettes do palettes+=1;assert(type(name)=='string' and #name<=200 and type(p)=='table','Invalid palette');local count=0;for key,t in p do count+=1;assert(count<=2000 and type(key)=='string' and #key<=200,'Invalid token name');assert(type(t)=='table' and type(t.type)=='string' and (type(t.value)=='string' or finite(t.value)),'Invalid resolved token') end end;assert(palettes<=33,'Too many palettes')
  for _,t in d.tokens.themes do assert(type(t.id)=='string' and type(t.name)=='string' and type(t.group)=='string' and d.tokens.palettes[t.id],'Invalid theme')end
 end
 assert(type(d.assetMap or {})=='table' and type(d.fontMap or {})=='table','Invalid mapping tables')
 for k,v in pairs(d.assetMap or {}) do assert(type(k)=='string' and type(v)=='string' and v:match('^rbxassetid://%d+$'),'Asset map values must be rbxassetid://NUMBER') end
 for k,v in pairs(d.fontMap or {}) do assert(type(k)=='string' and type(v)=='string' and (v:match('^rbxasset://fonts/families/[%w_-]+%.json$') or v:match('^rbxassetid://%d+$')),'Invalid font family URI') end
 local ids,count,panels,actions,aliases={},0,{},{},{}
 if d.excludedIds then assert(d.version>=5 and type(d.excludedIds)=='table'and #d.excludedIds<=5000,'Invalid excluded IDs');for _,id in d.excludedIds do assert(type(id)=='string'and #id>0 and #id<200 and not id:find('::',1,true),'Invalid excluded ID')end end
 local types={board=true,group=true,rectangle=true,text=true,ellipse=true,path=true,boolean=true,['svg-raw']=true,image=true}
 local function walk(n,depth)
  count+=1; assert(count<=5000 and depth<=64,'Document exceeds shape/depth limit')
  assert(type(n)=='table' and type(n.id)=='string' and #n.id>0 and #n.id<200 and not n.id:find('::',1,true) and not ids[n.id],'Duplicate/invalid ID')
  ids[n.id]=true; assert(types[n.type],'Unsupported shape type: '..tostring(n.type))
  if n.importMode then assert(d.version>=5 and table.find({'native','image','layout','template'},n.importMode),'Invalid layer import mode')end
  if n.ref then assert(d.version>=5 and type(n.ref)=='string'and #n.ref<=64 and n.ref:match('^[A-Za-z_][A-Za-z0-9_]*$')and not aliases[n.ref],'Invalid/duplicate gameplay reference');aliases[n.ref]=true end
  if n.importMode=='template'then assert(type(n.template)=='string'and #n.template<=64 and n.template:match('^[A-Za-z_][A-Za-z0-9_]*$')and #n.children==0,'Invalid template layer')end
  assert(type(n.name)=='string' and #n.name<=1000,'Invalid shape name')
  for _,k in {'x','y','rotation'} do number(n[k],-1000000,1000000,k) end
  for _,k in {'width','height'} do number(n[k],0,100000,k) end
  number(n.opacity or 1,0,1,'opacity'); number(n.radius or 0,0,100000,'radius')
  if n.radii then assert(type(n.radii)=='table' and #n.radii==4,'Invalid corner radii');for _,v in n.radii do number(v,0,100000,'corner radius')end end
  assert(n.nativeVisual==nil or type(n.nativeVisual)=='boolean','Invalid native visual')
  if n.nativeVisual then assert(n.assetKey and not n.rasterSubtree and not n.visualSuppressed and n.type~='text' and (n.type=='rectangle' or n.type=='board' or n.type=='group'),'Invalid native effect fallback')end
  if n.shadows then assert(type(n.shadows)=='table' and #n.shadows<=16,'Too many shadows');for _,s in n.shadows do
   assert(s.style==nil or s.style=='drop-shadow' or s.style=='inner-shadow','Invalid shadow style');assert(type(s.color)=='table','Missing shadow color');color(s.color.color);number(s.color.opacity or 1,0,1,'shadow opacity')
   number(s.offsetX or 0,-100000,100000,'shadow x');number(s.offsetY or 0,-100000,100000,'shadow y');number(s.blur or 0,0,100000,'shadow blur');number(s.spread or 0,-100000,100000,'shadow spread')
  end end
  if n.smooth then assert(type(n.smooth)=='table' and type(n.smooth.key)=='string' and not n.assetKey and type(n.smooth.slice)=='table' and #n.smooth.slice==4,'Invalid smooth surface');for _,v in n.smooth.slice do number(v,0,1024,'slice')end;assert(n.smooth.slice[3]>n.smooth.slice[1] and n.smooth.slice[4]>n.smooth.slice[2],'Empty slice center')end
  assert(type(n.children)=='table' and type(n.fills or {})=='table' and type(n.strokes or {})=='table','Invalid children/style arrays')
  if n.assetKey then assert(type(n.assetKey)=='string','Invalid asset key') end
  if n.tokens then local count=0;assert(type(n.tokens)=='table','Invalid token bindings');for k,v in n.tokens do count+=1;assert(count<=64 and type(k)=='string' and type(v)=='string' and #v<=200,'Invalid token binding')end end
  if n.tintColor then color(n.tintColor);assert(n.assetKey and not n.rasterSubtree,'Tint requires an independent image')end
  if n.slice then assert(n.assetKey and not n.rasterSubtree and type(n.slice.rect)=='table' and #n.slice.rect==4,'Invalid image slice');for _,v in n.slice.rect do number(v,0,1024,'slice edge')end;assert(n.slice.rect[3]>n.slice.rect[1] and n.slice.rect[4]>n.slice.rect[2],'Empty slice center');number(n.slice.scale,.001,1000,'slice scale')end
  if n.glow then assert(n.assetKey and not n.rasterSubtree and type(n.glow.key)=='string','Glow requires an independent image');color(n.glow.color);number(n.glow.opacity,0,1,'glow opacity');for _,k in {'x','y','width','height'}do number(n.glow.bounds[k],-100000,100000,'glow bounds')end;assert(n.glow.bounds.width>0 and n.glow.bounds.height>0,'Empty glow')end
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
   if t.runs then
    assert(type(t.runs)=='table' and #t.runs>0 and #t.runs<=2048,'Invalid text runs');local joined={}
    for _,r in t.runs do assert(type(r.value)=='string' and type(r.family)=='string' and type(r.robloxFamily)=='string' and r.robloxFamily:match('^[%w]+$'),'Invalid text run');number(r.size,1,1000,'run size');number(r.weight,100,900,'run weight');assert(r.weight%100==0,'Run weight must be a multiple of 100');color(r.color);number(r.alpha,0,1,'run alpha');assert(table.find({'none','underline','line-through'},r.decoration) and table.find({'none','uppercase','lowercase','capitalize'},r.transform),'Invalid run formatting');table.insert(joined,r.value)end
    assert(table.concat(joined)==t.value,'Text runs do not match source text')
   end
   if t.measuredWidth then number(t.measuredWidth,0,1000000,'measured text width');number(t.measuredHeight,0,1000000,'measured text height') end
  end
  if n.layout and n.layout.native then
   assert(n.layout.dir=='row' or n.layout.dir=='column','Invalid native layout direction')
   number(n.layout.gap or 0,0,100000,'layout gap')
   assert(type(n.layout.padding)=='table' and #n.layout.padding==4,'Invalid padding')
   for _,v in ipairs(n.layout.padding) do number(v,0,100000,'padding') end
   assert(n.layout.wrap==nil or n.layout.wrap=='wrap' or n.layout.wrap=='nowrap','Invalid wrapping')
   assert(n.layout.justify==nil or table.find({'start','center','end','space-between','space-around','space-evenly'},n.layout.justify),'Invalid justify')
   assert(n.layout.align==nil or table.find({'start','center','end'},n.layout.align),'Invalid alignment')
  end
  if n.grid then
   local g=n.grid;assert(type(g)=='table' and (g.dir=='row'or g.dir=='column'),'Invalid grid direction')
   assert(type(g.padding)=='table'and #g.padding==4,'Invalid grid padding');for _,v in g.padding do number(v,0,100000,'grid padding')end
   for _,k in {'columnGap','rowGap'}do number(g[k],0,100000,'grid gap')end
   for _,k in {'columns','rows'}do number(g[k],0,5000,'grid tracks');assert(g[k]%1==0,'Grid track counts must be integers')end
   assert(type(g.unsupportedCells)=='boolean','Invalid grid cell metadata')
  end
  if n.layoutChild then for _,key in {'horizontalSizing','verticalSizing'} do assert(n.layoutChild[key]==nil or table.find({'fix','auto','fill'},n.layoutChild[key]),'Invalid child sizing')end end
  for _,c in ipairs(n.children) do walk(c,depth+1) end
 end
 walk(d.design,0)
 for _,id in d.excludedIds or {}do assert(not ids[id],'Excluded ID is also included in the design')end
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
local function uniformGrid(n)
 local g=n.grid;if not g then return nil,'no grid metadata' end
 if g.unsupportedCells then return nil,'cell spans, absolute positioning or child sizing constraints' end
 if n.layout or #n.children==0 then return nil,'empty grid or mixed layout systems' end
 if n.smooth or n.rasterSubtree or n.visualSuppressed then return nil,'composited or image-based container' end
 local sorted=table.clone(n.children);local row=g.dir=='row';local first=sorted[1]
 local width,height=first.width,first.height
 if width<=0 or height<=0 then return nil,'zero-size cells' end
 for _,c in sorted do
  if c.visible==false or c.visualSuppressed or c.rotation~=0 then return nil,'hidden, covered or rotated cells' end
  if math.abs(c.width-width)>.1 or math.abs(c.height-height)>.1 then return nil,'unequal cell sizes' end
  if c.layoutChild and (c.layoutChild.horizontalSizing=='auto'or c.layoutChild.horizontalSizing=='fill'or c.layoutChild.verticalSizing=='auto'or c.layoutChild.verticalSizing=='fill')then return nil,'automatic cell sizing' end
 end
 table.sort(sorted,function(a,b)
  local primary=row and 'y'or 'x';local secondary=row and 'x'or 'y'
  local ap,bp=math.floor(a[primary]*10+.5),math.floor(b[primary]*10+.5)
  if ap~=bp then return ap<bp end
  local av,bv=math.floor(a[secondary]*10+.5),math.floor(b[secondary]*10+.5)
  if av~=bv then return av<bv end
  return a.id<b.id
 end)
 local pad=g.padding;local contentWidth=n.width-pad[2]-pad[4];local contentHeight=n.height-pad[1]-pad[3]
 local maxCells=row and g.columns or g.rows
 if maxCells==0 then
  maxCells=0;local primary=row and 'y'or 'x'
  for _,c in sorted do if math.abs(c[primary]-sorted[1][primary])<=.1 then maxCells+=1 end end
 end
 if maxCells<1 then return nil,'no regular tracks' end
 local usedColumns=row and math.min(maxCells,#sorted)or math.ceil(#sorted/maxCells)
 local usedRows=row and math.ceil(#sorted/maxCells)or math.min(maxCells,#sorted)
 if usedColumns*width+(usedColumns-1)*g.columnGap>contentWidth+.1 or usedRows*height+(usedRows-1)*g.rowGap>contentHeight+.1 then return nil,'cells exceed the padded content box' end
 local order={}
 for ix,c in sorted do
  local col=row and (ix-1)%maxCells or math.floor((ix-1)/maxCells)
  local line=row and math.floor((ix-1)/maxCells)or (ix-1)%maxCells
  if math.abs(c.x-(pad[4]+col*(width+g.columnGap)))>.1 or math.abs(c.y-(pad[1]+line*(height+g.rowGap)))>.1 then return nil,'holes, offsets, distributed spacing or irregular placement' end
  order[c.id]=ix
 end
 return {width=width,height=height,maxCells=maxCells,order=order}
end
local function descriptors(d,options)
 local result,warnings={},table.clone(d.warnings or {})
 local capabilities=options.capabilities or Importer.capabilities()
 local quality={native=0,images=0,covered=0,smoothed=0,fonts=0,layouts=0,items={}}
 local grids={}
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
  z+=2
  local nativeGroup=n.nativeGroup==true
  local scroll=n.scroll==true and d.options and d.options.behaviors==true
  if n.importMode=='template'then
   local template,revision=Templates.resolve(options,n.template)
   local props={Name=n.name,Position=UDim2.fromOffset(parent and n.x or 0,parent and n.y or 0),Size=UDim2.fromOffset(n.width,n.height),AnchorPoint=Vector2.zero,Rotation=n.rotation,Visible=n.visible~=false,ZIndex=z,LayoutOrder=z}
   if parent and grids[parent]then props.LayoutOrder=grids[parent].order[n.id]end
   if parentNode and parentNode.layout and parentNode.layout.native and (not parentNode.assetKey or nativeVisual(parentNode,capabilities))then
    local axisName=parentNode.layout.dir=='row'and'x'or'y';props.LayoutOrder=0
    for _,sibling in parentNode.children do
     local cross=axisName=='x'and'y'or'x';local wrap=parentNode.layout.wrap=='wrap'
     if(wrap and sibling[cross]<n[cross]-.1)or((not wrap or math.abs(sibling[cross]-n[cross])<.1)and(sibling[axisName]<n[axisName]or(sibling[axisName]==n[axisName]and sibling.id<n.id)))then props.LayoutOrder+=1 end
    end
   end
   local behavior=d.options and d.options.behaviors and n.behavior
   if behavior and behavior.action~=''then assert(template:IsA('GuiButton'),'Template actions require a button template');hasActions=true end
   add(n.id,parent,template.ClassName,props,{P2R_Template=n.template,P2R_TemplateRevision=revision,P2R_Panel=behavior and behavior.panel or '',P2R_Action=behavior and behavior.action or '',P2R_Target=behavior and behavior.target or ''})
   result[#result].template=template;quality.native+=1;table.insert(quality.items,{name=n.name,id=n.id,mode='native',detail='Reusable template: '..n.template..'; authored children and scripts retained'})
   return
  end
  local opacity=nativeGroup and 1 or inheritedOpacity*(n.opacity or 1)
  local text=n.type=='text'and n.importMode~='layout'
  local modern=nativeVisual(n,capabilities)
  local raster=n.assetKey~=nil and not modern
  local grid
  if n.grid and options.nativeGrids then
   local reason
   if raster then reason='container requires an image surface'else grid,reason=uniformGrid(n)end
   if grid then grids[n.id]=grid else warn(n,'Native grid skipped: '..reason..'; measured positions retained.')end
  end
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
  if parent and grids[parent]then layoutOrder=grids[parent].order[n.id]end
  if parentNode and parentNode.layout and parentNode.layout.native and (not parentNode.assetKey or nativeVisual(parentNode,capabilities))then
   local axisName=parentNode.layout.dir=='row' and 'x' or 'y'
   layoutOrder=0
   for _,sibling in ipairs(parentNode.children) do
    local cross=axisName=='x' and 'y' or 'x'
    local wrap=parentNode.layout.wrap=='wrap'
    if (wrap and sibling[cross]<n[cross]-.1) or ((not wrap or math.abs(sibling[cross]-n[cross])<.1) and (sibling[axisName]<n[axisName] or (sibling[axisName]==n[axisName] and sibling.id<n.id)))then layoutOrder+=1 end
   end
  end
  local p={Name=n.name,Position=UDim2.new(psx,px,psy,py),Size=UDim2.new(ssx,sx,ssy,sy),AnchorPoint=Vector2.zero,
   Rotation=n.rotation,Visible=n.visible~=false,BorderSizePixel=0,ZIndex=z,LayoutOrder=layoutOrder,
   BackgroundColor3=f and f.fillColor and color(f.fillColor) or Color3.new(1,1,1),
   BackgroundTransparency=(text or raster or n.smooth or n.visualSuppressed or not f) and 1 or 1-opacity*(f.fillOpacity or 1),
   ClipsDescendants=n.clip==true and not raster,AutomaticSize=Enum.AutomaticSize.None}
  if n.clip and n.rotation~=0 then warn(n,'Roblox clipping with rotated objects may differ.') end
  if modern then warn(n,'Native corners/shadows selected; fallback image is unused. Shadow softness may differ from Penpot.')end
  if n.nativeVisual and not modern then warn(n,'This Studio lacks the required native effects; using the compatibility image.')end
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
   p.RichText=t.runs~=nil and not raster;p.TextScaled=false;p.TextWrapped=true;p.TextSize=t.size
   if p.RichText then p.Text=RichText.render(t.runs,d.fontMap);p.TextColor3=Color3.new(1,1,1)end
   p.TextColor3=p.RichText and Color3.new(1,1,1)or(f and f.fillColor and color(f.fillColor) or Color3.new(0,0,0))
   p.TextTransparency=1-opacity*(p.RichText and 1 or (f and f.fillOpacity or 1))
   p.TextStrokeTransparency=1
   p.TextXAlignment=({left=Enum.TextXAlignment.Left,center=Enum.TextXAlignment.Center,right=Enum.TextXAlignment.Right})[t.align] or Enum.TextXAlignment.Left
   p.TextYAlignment=({top=Enum.TextYAlignment.Top,center=Enum.TextYAlignment.Center,bottom=Enum.TextYAlignment.Bottom})[t.verticalAlign] or Enum.TextYAlignment.Top
   p.LineHeight=math.clamp(t.lineHeight or 1.2,1,3)
   local family=(d.fontMap or {})[t.family or '']
   local known={Arial=Enum.Font.Arial,arial=Enum.Font.Arial,sourcesanspro=Enum.Font.SourceSans,['Source Sans Pro']=Enum.Font.SourceSans,['Roboto']=Enum.Font.Roboto,roboto=Enum.Font.Roboto,['Ubuntu']=Enum.Font.Ubuntu,ubuntu=Enum.Font.Ubuntu,['Gotham']=Enum.Font.Gotham,SourceSans=Enum.Font.SourceSans,BuilderSans=Enum.Font.BuilderSans,RobotoMono=Enum.Font.RobotoMono,RobotoCondensed=Enum.Font.RobotoCondensed,FredokaOne=Enum.Font.FredokaOne,Nunito=Enum.Font.Nunito}
   if not family then
    local mapped=known[t.robloxFamily or ''] or known[t.family]
    family=Font.fromEnum(mapped or Enum.Font.Arial).Family
    if not mapped and not raster then warn(n,'Font '..tostring(t.family)..' substituted with Arial; map a Roblox font family URI for a closer match.') end
   end
   local weights={Enum.FontWeight.Thin,Enum.FontWeight.ExtraLight,Enum.FontWeight.Light,Enum.FontWeight.Regular,Enum.FontWeight.Medium,Enum.FontWeight.SemiBold,Enum.FontWeight.Bold,Enum.FontWeight.ExtraBold,Enum.FontWeight.Heavy}
   p.FontFace=Font.new(family,weights[math.clamp(math.floor((t.weight or 400)/100+.5),1,9)],t.italic and Enum.FontStyle.Italic or Enum.FontStyle.Normal)
   -- Roblox TextSize denotes line height, while CSS/Penpot uses font em size.
   -- Match a measured single line, avoiding a guessed universal size multiplier.
   if not raster and not t.runs and t.measuredWidth and t.measuredWidth>0 and t.measuredWidth<=n.width+.1 and t.measuredHeight<=t.size*1.8 and not t.value:find('\n',1,true) and (t.letterSpacing or 0)==0 then
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
   local sp={Name='Penpot Visual Surface',BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(b.x,b.y),Size=UDim2.new(1,b.width-n.width,1,b.height-n.height),Image=asset or '',ImageColor3=n.tintColor and color(n.tintColor)or Color3.new(1,1,1),ImageTransparency=1-inheritedOpacity,ScaleType=Enum.ScaleType.Stretch,ZIndex=z,Visible=not n.visualSuppressed}
   if n.slice then local s=n.slice.rect;sp.ScaleType=Enum.ScaleType.Slice;sp.SliceCenter=Rect.new(s[1],s[2],s[3],s[4]);sp.SliceScale=n.slice.scale end
   add(n.id..'::surface',n.id,'ImageLabel',sp)
   if n.glow then local g=n.glow;local b=g.bounds;add(n.id..'::glow',n.id,'ImageLabel',{Name='Penpot Silhouette Glow',BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(b.x,b.y),Size=UDim2.new(1,b.width-n.width,1,b.height-n.height),Image=(d.assetMap or {})[g.key]or '',ImageColor3=color(g.color),ImageTransparency=1-inheritedOpacity*g.opacity,ScaleType=Enum.ScaleType.Stretch,ZIndex=z-1,Visible=not n.visualSuppressed})end
   if not asset then warn(n,'Missing Roblox image asset: '..n.assetKey..'. Upload pending images before importing.') end
  end
  if n.smooth and not n.visualSuppressed then
   local asset=(d.assetMap or {})[n.smooth.key];local s=n.smooth.slice
   add(n.id..'::smooth',n.id,'ImageLabel',{Name='Penpot Smooth Surface',BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.new(),Size=UDim2.fromScale(1,1),Image=asset or '',ImageTransparency=1-opacity,ImageColor3=Color3.new(1,1,1),ScaleType=Enum.ScaleType.Slice,SliceCenter=Rect.new(s[1],s[2],s[3],s[4]),SliceScale=.5,ZIndex=z,Visible=true})
   if not asset then warn(n,'Missing smooth corner image: '..n.smooth.key)end
  end
  if not raster and not n.smooth and not n.visualSuppressed then
   local cornerTokens=n.tokens and (n.tokens.borderRadiusTopLeft or n.tokens.borderRadiusTopRight or n.tokens.borderRadiusBottomRight or n.tokens.borderRadiusBottomLeft)
   if (n.radius or 0)>0 or n.type=='ellipse' or (modern and n.radii)or cornerTokens then
    local cp={Name='Penpot Corner'}
    if (modern or cornerTokens)and capabilities.corners and n.radii then for index,key in {'TopLeftRadius','TopRightRadius','BottomRightRadius','BottomLeftRadius'}do cp[key]=UDim.new(0,n.radii[index])end
    else cp.CornerRadius=n.type=='ellipse' and UDim.new(.5,0) or UDim.new(0,n.radius)end
    add(n.id..'::corner',n.id,'UICorner',cp)
   end
   if modern then for ix,s in n.shadows or {}do add(n.id..'::shadow'..ix,n.id,'UIShadow',{Name='Penpot Shadow',Color=color(s.color.color),Transparency=1-opacity*(s.color.opacity or 1),BlurRadius=UDim.new(0,s.blur or 0),Offset=UDim2.fromOffset(s.offsetX or 0,s.offsetY or 0),Spread=UDim2.fromOffset(2*(s.spread or 0),2*(s.spread or 0)),Inset=s.style=='inner-shadow',Mode=Enum.ApplyShadowMode.Shape,ShowBehindParent=false,ZIndex=-ix,Enabled=true})end end
   for index,s in ipairs(n.strokes or {}) do
    if index>1 then warn(n,'Additional strokes omitted.');break end
    if s.strokeStyle~='none' then
     if s.strokeStyle and s.strokeStyle~='solid' then warn(n,'Dashed/vector stroke converted to solid.') end
     if s.strokeColorGradient then warn(n,'Stroke gradient omitted.') end
     local align=({inner=Enum.BorderStrokePosition.Inner,outer=Enum.BorderStrokePosition.Outer,center=Enum.BorderStrokePosition.Center})[s.strokeAlignment] or Enum.BorderStrokePosition.Center
     add(n.id..'::stroke',n.id,'UIStroke',{Name='Penpot Stroke',Color=s.strokeColor and color(s.strokeColor) or Color3.new(0,0,0),Thickness=s.strokeWidth or 1,Transparency=1-opacity*(s.strokeOpacity or 1),ApplyStrokeMode=text and Enum.ApplyStrokeMode.Contextual or Enum.ApplyStrokeMode.Border,BorderStrokePosition=align,Enabled=true})
    end
   end
   local g=f and f.fillColorGradient
   if g then
    if g.type~='linear' then warn(n,'Radial gradient needs a raster asset; first fill color retained.')
    else
     local colors,alpha=Gradient.sequences(g.stops)
     local dx=(g.endX-g.startX)*n.width;local dy=(g.endY-g.startY)*n.height
     if math.abs(g.startX)+math.abs(g.startY)+math.abs(g.endX)+math.abs(g.endY)>4 then warn(n,'Gradient coordinates are outside normalized bounds; review angle.') end
     if text then p.TextColor3=Color3.new(1,1,1) else p.BackgroundColor3=Color3.new(1,1,1) end
     -- The descriptor references p, so this update is included in the plan.
     add(n.id..'::gradient',n.id,'UIGradient',{Name='Penpot Gradient',Color=colors,Transparency=alpha,Rotation=math.deg(math.atan2(dy,dx)),Offset=Vector2.new((g.startX+g.endX)/2-.5,(g.startY+g.endY)/2-.5),Enabled=true})
     if math.abs(math.sqrt(dx*dx+dy*dy)-(math.abs(math.cos(math.atan2(dy,dx)))*n.width+math.abs(math.sin(math.atan2(dy,dx)))*n.height))>.1 then warn(n,'Gradient span differs from Roblox edge-to-edge interpolation; review or rasterize.') end
    end
   end
  end
  if parentNode and parentNode.layout and parentNode.layout.native and (not parentNode.assetKey or nativeVisual(parentNode,capabilities))then
   local main=parentNode.layout.dir=='row' and 'horizontalSizing' or 'verticalSizing'
   if n.layoutChild and n.layoutChild[main]=='fill' then add(n.id..'::flex',n.id,'UIFlexItem',{Name='Penpot Flex',FlexMode=Enum.UIFlexMode.Fill});if main=='horizontalSizing' then p.Size=UDim2.new(0,0,p.Size.Y.Scale,p.Size.Y.Offset)else p.Size=UDim2.new(p.Size.X.Scale,p.Size.X.Offset,0,0)end end
  end
  if grid then
   local g=n.grid;local pad=g.padding
   add(n.id..'::grid-padding',n.id,'UIPadding',{Name='Penpot Grid Padding',PaddingTop=UDim.new(0,pad[1]),PaddingRight=UDim.new(0,pad[2]),PaddingBottom=UDim.new(0,pad[3]),PaddingLeft=UDim.new(0,pad[4])})
   add(n.id..'::grid',n.id,'UIGridLayout',{Name='Penpot Grid',CellSize=UDim2.fromOffset(grid.width,grid.height),CellPadding=UDim2.fromOffset(g.columnGap,g.rowGap),FillDirection=g.dir=='row'and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,FillDirectionMaxCells=grid.maxCells,StartCorner=Enum.StartCorner.TopLeft,SortOrder=Enum.SortOrder.LayoutOrder,HorizontalAlignment=Enum.HorizontalAlignment.Left,VerticalAlignment=Enum.VerticalAlignment.Top})
   quality.layouts+=1;warn(n,'Native grid enabled: UIGridLayout controls direct child sizes and positions, including slots you add locally.')
  end
  if n.layout and n.layout.native and not raster then
   local l=n.layout;local pad=l.padding;local horizontal=l.dir=='row'
   local h=horizontal and Enum.HorizontalAlignment.Left or (({start=Enum.HorizontalAlignment.Left,center=Enum.HorizontalAlignment.Center,['end']=Enum.HorizontalAlignment.Right})[l.align] or Enum.HorizontalAlignment.Left)
   local v=horizontal and (({start=Enum.VerticalAlignment.Top,center=Enum.VerticalAlignment.Center,['end']=Enum.VerticalAlignment.Bottom})[l.align] or Enum.VerticalAlignment.Top) or Enum.VerticalAlignment.Top
   add(n.id..'::padding',n.id,'UIPadding',{Name='Penpot Padding',PaddingTop=UDim.new(0,pad[1]),PaddingRight=UDim.new(0,pad[2]),PaddingBottom=UDim.new(0,pad[3]),PaddingLeft=UDim.new(0,pad[4])})
   local justify=l.justify or 'start';local alignMap=horizontal and {start=Enum.HorizontalAlignment.Left,center=Enum.HorizontalAlignment.Center,['end']=Enum.HorizontalAlignment.Right}or{start=Enum.VerticalAlignment.Top,center=Enum.VerticalAlignment.Center,['end']=Enum.VerticalAlignment.Bottom}
   if alignMap[justify]then if horizontal then h=alignMap[justify]else v=alignMap[justify]end end
   local flex=({['space-between']=Enum.UIFlexAlignment.SpaceBetween,['space-around']=Enum.UIFlexAlignment.SpaceAround,['space-evenly']=Enum.UIFlexAlignment.SpaceEvenly})[justify] or Enum.UIFlexAlignment.None
   add(n.id..'::layout',n.id,'UIListLayout',{Name='Penpot Layout',FillDirection=horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,Padding=UDim.new(0,l.gap or 0),SortOrder=Enum.SortOrder.LayoutOrder,HorizontalAlignment=h,VerticalAlignment=v,Wraps=l.wrap=='wrap',HorizontalFlex=horizontal and flex or Enum.UIFlexAlignment.None,VerticalFlex=horizontal and Enum.UIFlexAlignment.None or flex})
  end
  local mode=n.visualSuppressed and n.importMode~='layout'and 'covered' or raster and 'images' or n.smooth and 'smoothed' or 'native';quality[mode]+=1
  local substituted=text and not raster and not n.visualSuppressed and n.text.fontSubstituted==true and not (d.fontMap or {})[n.text.family]
  if substituted then quality.fonts+=1 end
  if n.layout and n.layout.native and not raster then quality.layouts+=1 end
  table.insert(quality.items,{name=n.name,id=n.id,mode=mode,detail=(substituted and ('Font: '..n.text.family..' → '..n.text.robloxFamily)or modern and 'Native effects; compatibility image unused' or n.smooth and 'Smoothed 9-slice image; native children' or raster and 'Image appearance; source geometry retained' or n.visualSuppressed and 'Appearance included in ancestor image' or 'Editable native appearance')..(n.layout and (n.layout.native and not raster and '; native layout' or '; measured positions')or '')})
  local detail=quality.items[#quality.items];if n.importMode=='layout'then detail.detail='Layout-only container; child visuals retained'end;if grid then detail.detail..='; native uniform grid'end;if text and n.text.runs and not raster then detail.detail..='; RichText runs' end;if n.tintColor then detail.detail..='; tintable mask'end;if n.glow then detail.detail..='; baked silhouette glow'end;if n.slice then detail.detail..='; explicit nine-slice'end;if n.tokens and next(n.tokens)then detail.detail..='; token bindings retained'end
  for _,c in ipairs(n.children) do walk(c,n.id,n,opacity) end
 end
 walk(d.design,nil,nil,1)
 local usedBindings={}
 local nodes={};local function collect(n)nodes[n.id]=n;for _,c in n.children do collect(c)end end;collect(d.design)
 for _,item in result do
  local n=nodes[item.id]or nodes[item.id:match('^(.-)::')];if n then
   item.attributes=item.attributes or {};local bindings=n.tokens or {};local targets={}
   if item.id==n.id then item.attributes.P2R_TokenBindings=Http:JSONEncode(bindings)end
   local function bind(property,key,kind,extra)if bindings[key]then usedBindings[n.id]=usedBindings[n.id]or {};usedBindings[n.id][key]=true; local b={property=property,token=bindings[key],kind=kind};for k,v in extra or {}do b[k]=v end;table.insert(targets,b)end end
   local raster=n.assetKey and not nativeVisual(n,capabilities)
   if item.id==n.id then
    if not raster and not n.smooth and not n.visualSuppressed then
     if n.type=='text'then if not n.text.runs then bind('TextColor3','fill','color');bind('TextSize','fontSize','fontSizes');bind('FontFamily','fontFamilies','fontFamilies');bind('FontWeight','fontWeight','fontWeights')elseif next(bindings)then warn(n,'RichText span styling is preserved; whole-label color/font token switching is skipped.')end
     elseif not ((n.fills or {})[1]or {}).fillColorGradient then bind('BackgroundColor3','fill','color')end
     bind('Rotation','rotation','rotation')
    elseif next(bindings)then warn(n,'Baked visual tokens remain recorded; re-export for appearance changes except tintable image colors.')end
    if not (n.layoutChild and (n.layoutChild.horizontalSizing=='fill'or n.layoutChild.verticalSizing=='fill'))then bind('SizeX','width','sizing');bind('SizeY','height','sizing')end
   elseif item.id==n.id..'::surface' and n.tintColor then bind('ImageColor3','fill','color')
   elseif item.class=='UICorner'then for _,key in {'borderRadiusTopLeft','borderRadiusTopRight','borderRadiusBottomRight','borderRadiusBottomLeft'}do local prop=key:gsub('borderRadius','')..'Radius';if item.props[prop]then bind(prop,key,'borderRadius')elseif item.props.CornerRadius and bindings[key]then warn(n,'Per-corner theme switching needs a native individual-corner descriptor.')end end
   elseif item.class=='UIStroke'then bind('Color','strokeColor','color');bind('Thickness','strokeWidth','borderWidth')
   elseif item.class=='UIPadding'then for _,side in {'Top','Bottom','Left','Right'}do bind('Padding'..side,'padding'..side,'spacing')end
   elseif item.class=='UIListLayout'then bind('Padding',n.layout.dir=='row'and 'columnGap'or 'rowGap','spacing')end
   item.attributes.P2R_ThemeTargets=Http:JSONEncode(targets)
  end
 end
 for id,n in nodes do for key in n.tokens or {}do if not (usedBindings[id]or {})[key]then warn(n,'Token binding retained without a runtime mapping: '..key)end end end
 local references=options.generateRefs==true;for _,n in nodes do if n.ref then references=true end end
 if references then add(d.design.id..'::refs',nil,'ModuleScript',{Name='Penpot References',Source=References.source(d)});table.insert(warnings,'Generated Penpot References module. Bind it to the imported wrapper from your own gameplay code.')end
 if d.tokens and d.options and d.options.runtimeThemes then add(d.design.id..'::theme',nil,'ModuleScript',{Name='Penpot Theme',Source=Themes.source(d.tokens,d.source.fileId..'/'..d.source.rootId)});table.insert(warnings,'Generated Penpot Theme module: require it and call Apply(wrapper, themeId). No theme changes run automatically.')end
 if hasActions then
  add(d.design.id..'::controller',nil,'LocalScript',{Name='Penpot Bridge Controller',Source=Behaviors.source(),Disabled=false})
  table.insert(warnings,'Optional panel actions generate one LocalScript. Existing gameplay scripts remain untouched.')
 end
 return result,warnings,quality
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
  local items,warnings,quality=descriptors(d,options)
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
  if old and ((item.template and(old:GetAttribute('P2R_Template')~=(item.attributes or {}).P2R_Template or old:GetAttribute('P2R_TemplateRevision')~=(item.attributes or {}).P2R_TemplateRevision))or(not item.template and old:GetAttribute('P2R_Template')))then kind='class' end
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
 return {document=d,target=target,options=options,key=key,wrapper=wrapper,index=index,items=items,wanted=wanted,stats=stats,warnings=warnings,changes=changes,nativeGroups=nativeGroups,quality=quality}
end
-- Read-only audit against the received design, using the same engine-normalized
-- conversion as import. P2R_Last distinguishes local edits from unapplied values.
function Importer.verify(d,target,options)
 Importer.validate(d);options=table.clone(options or {});options.force=false
 local key=d.source.fileId..'/'..d.source.rootId
 local report={issues={},errors=0,warnings=0,notes=0,checks=0,omitted=0}
 local function issue(level,code,name,message,instance,property)
  local counter=level=='error' and 'errors' or level=='warning' and 'warnings' or 'notes'
  report[counter]+=1
  if #report.issues<500 then table.insert(report.issues,{level=level,code=code,name=name,message=message,instance=instance,property=property})else report.omitted+=1 end
 end
 local wrapper
 if target and target:GetAttribute('P2R_Design')==key then wrapper=target
 elseif target then
  for _,i in target:GetChildren()do if i:GetAttribute('P2R_Design')==key then
   if wrapper then issue('error','duplicate-import',i.Name,'Multiple imports of this design exist here.',i)else wrapper=i end
  end end
 end
 if not wrapper then issue('error','missing-import',d.design.name,'No matching import found here. Import this design or select its imported container.',target);return report end
 report.wrapper=wrapper
 local items,_,quality=descriptors(d,options)
 local index,duplicates,wanted={},{},{}
 local names={};local function namesFor(n)names[n.id]=n.name;for _,c in n.children do namesFor(c)end end;namesFor(d.design)
 for _,i in wrapper:GetDescendants()do
  local id=i:GetAttribute('P2R_Id')
  if id and i:GetAttribute('P2R_Source')==key and not i:GetAttribute('P2R_Retired')then
   if index[id]then duplicates[id]=true;issue('error','duplicate-id',i.Name,'Multiple objects own the same imported ID.',i)else index[id]=i end
  end
 end
 local function visible(i)
  while i and i~=wrapper.Parent do
   if i:IsA('GuiObject')and not i.Visible then return false end
   if i:IsA('CanvasGroup')and i.GroupTransparency>=1 then return false end
   if i:IsA('ScreenGui')and not i.Enabled then return false end
   i=i.Parent
  end
  return true
 end
 for ix,item in items do
  wanted[item.id]=true;report.checks+=1
  local i=index[item.id];local name=item.props.Name or item.id
  local base=item.id:match('^(.-)::');if base and names[base]then name=names[base]..' / '..name end
  if not i then issue('error','missing-object',name,'Expected '..item.class..' is missing.',item.parent and index[item.parent]or wrapper)
  elseif not duplicates[item.id]then
   if i.ClassName~=item.class then issue('error','wrong-class',name,'Expected '..item.class..', found '..i.ClassName..'.',i)
   else
    local last=decode(i:GetAttribute('P2R_Last'));local edits={};local checkedImage=false
    for attribute,value in item.attributes or {}do report.checks+=1;if i:GetAttribute(attribute)~=value then issue('error','metadata-difference',name,'Imported '..attribute..' differs from the received design or template mapping. Review and reimport.',i)end end
    for prop,value in item.props do
     report.checks+=1
     local actual=i[prop];local differs=signature(actual)~=signature(value)
     if prop=='Image' and item.props.ImageTransparency~=1 and (value==''or actual=='')then
      checkedImage=true;issue('error','missing-image',name,value==''and 'The design has no resolved image asset. Receive the uploaded bundle or import images before checking again.'or 'The imported image reference is empty.',i,prop)
     elseif differs then
      if locked(i,prop)or(last[prop]and signature(actual)~=last[prop])then table.insert(edits,prop)
      else issue('error','design-difference',name,prop..' differs from the received design. Review and reimport to apply the design value.',i,prop)end
     end
    end
    if #edits>0 then table.sort(edits);issue('note','local-edit',name,'Local changes or locks: '..table.concat(edits,', ')..'. Kept as informational findings; they may be intentional.',i)end
    local parent=item.parent and index[item.parent]or wrapper
    if i.Parent~=parent then issue('warning','moved-object',name,'Object is outside its expected parent. This may be an intentional local move.',i)end
    if (i:IsA('TextLabel')or i:IsA('TextButton'))and i.Text~=''and i.TextTransparency<1 and visible(i)then
     if i.AbsoluteSize.X>0 and i.AbsoluteSize.Y>0 then
      report.checks+=1;if not i.TextFits then issue('warning','text-overflow',name,'Text does not fit its current box. Review the text, font and available space.',i)end
     else issue('note','unmeasured-text',name,'Text fitting could not be checked because this object has no rendered size.',i)end
    end
    if (i:IsA('ImageLabel')or i:IsA('ImageButton'))and not checkedImage and i.Image~=''and i.ImageTransparency<1 and visible(i)then
     report.checks+=1;if not i.IsLoaded then issue('warning','image-not-loaded',name,'Image is not loaded in this viewport yet. This can be temporary; check moderation/access and verify again.',i)end
    end
   end
  end
  if ix%100==0 then task.wait()end
 end
 for id,i in index do if not wanted[id]and not i:GetAttribute('P2R_Stale')then issue('note','extra-owned-object',i.Name,'Imported object is absent from the received design. Review removal on the next import.',i)end end
 -- Report declared substitutions separately; matching a mapped font is not proof
 -- that its glyphs are identical to the original Penpot family.
 for _,q in quality.items do if q.detail:sub(1,6)=='Font: 'then issue('note','font-substitution',q.name,q.detail..'. This declared substitution needs visual review for exact glyph appearance.',index[q.id])end end
 -- Only new overlaps count: intentional design overlaps, rotations, scrolling
 -- regions and hidden nodes are excluded. Bound pair work for large boards.
 local pairsChecked=0;local limited=false
 local function intersects(ax,ay,aw,ah,bx,by,bw,bh,slack)
  return math.min(ax+aw,bx+bw)-math.max(ax,bx)>slack and math.min(ay+ah,by+bh)-math.max(ay,by)>slack
 end
 local function overlaps(n,rotated)
  rotated=rotated or n.rotation~=0
  local parent=index[n.id]
  if not rotated and parent and not parent:IsA('ScrollingFrame')and not n.rasterSubtree then
   local candidates={}
   for _,c in n.children do local i=index[c.id];if c.visible~=false and not c.visualSuppressed and c.rotation==0 and i and i:IsA('GuiObject')and i.Parent==parent and i.AbsoluteSize.X>0 and visible(i)then table.insert(candidates,{node=c,instance=i})end end
   for a=1,#candidates do for b=a+1,#candidates do
    if pairsChecked>=10000 then limited=true;break end;pairsChecked+=1
    local x,y=candidates[a],candidates[b];local nx,ny=x.node,y.node
    if not intersects(nx.x,nx.y,nx.width,nx.height,ny.x,ny.y,ny.width,ny.height,1)then
     local px,sx,py,sy=x.instance.AbsolutePosition,x.instance.AbsoluteSize,y.instance.AbsolutePosition,y.instance.AbsoluteSize
     report.checks+=1;if intersects(px.X,px.Y,sx.X,sx.Y,py.X,py.Y,sy.X,sy.Y,2)then issue('warning','new-overlap',nx.name,'Overlaps '..ny.name..' here, although they are apart in the design. Review local edits and layout.',x.instance)end
    end
   end;if limited then break end end
  end
  for _,c in n.children do if not limited then overlaps(c,rotated)end end
 end;overlaps(d.design,false)
 if limited then issue('note','overlap-limit',d.design.name,'Overlap scan stopped after 10,000 sibling pairs. Verify a smaller design for complete overlap coverage.',wrapper)end
 table.sort(report.issues,function(a,b)local rank={error=1,warning=2,note=3};if a.level~=b.level then return rank[a.level]<rank[b.level]end;if a.name~=b.name then return a.name<b.name end;return a.code..(a.property or '')<b.code..(b.property or '')end)
 return report
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
    if i:GetAttribute('P2R_Template')then
     for _,child in i:GetDescendants()do if child:IsA('BaseScript')then child:SetAttribute('P2R_PreRetiredDisabled',child.Disabled);child.Disabled=true end end
    end
    if i:IsA('GuiObject') then i.Visible=false elseif i:IsA('UIComponent') and i:IsA('UIListLayout') then i.Parent=nil end
    -- Preserve the old instance and every user child/reference. New ID owner is separate.
    if i:IsA('UIListLayout') or i:IsA('UIPadding') then error('Layout class replacement requires manual resolution') end
    i=nil
   end
   local fresh=not i
   if fresh then i=item.template and Templates.clone(item.template)or Instance.new(item.class);i:SetAttribute('P2R_Id',item.id) end
   i:SetAttribute('P2R_Source',plan.key)
   local last=decode(i:GetAttribute('P2R_Last'))
   if i:IsA('LocalScript') and i:GetAttribute('P2R_DisabledByImporter') then
    i.Disabled=i:GetAttribute('P2R_PreStaleDisabled')==true;i:SetAttribute('P2R_DisabledByImporter',nil);i:SetAttribute('P2R_PreStaleDisabled',nil)
   end
   if i:GetAttribute('P2R_HiddenByImporter') then
    if i:IsA('GuiObject') then i.Visible=i:GetAttribute('P2R_PreStaleVisible')~=false end
    if i:IsA('UIGradient') or i:IsA('UIStroke') or i:IsA('UIShadow') then i.Enabled=i:GetAttribute('P2R_PreStaleEnabled')~=false end
    i:SetAttribute('P2R_HiddenByImporter',nil);i:SetAttribute('P2R_PreStaleVisible',nil);i:SetAttribute('P2R_PreStaleEnabled',nil)
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
  local excluded={};for _,id in plan.document.excludedIds or {}do excluded[id]=true end
  for id,i in pairs(plan.index) do
   if not plan.wanted[id] then
    i:SetAttribute('P2R_Stale',true)
    if i:IsA('LocalScript') and not i:GetAttribute('P2R_DisabledByImporter') then
     i:SetAttribute('P2R_PreStaleDisabled',i.Disabled);i:SetAttribute('P2R_DisabledByImporter',true);i.Disabled=true
    end
    -- Replaced source-owned decorations must stop rendering even when removed layers are retained visibly.
    local baseId=id:match('^(.-)::')
    if plan.options.hideRemoved or excluded[id]or(baseId and excluded[baseId])or (baseId and plan.wanted[baseId])then
     if i:IsA('GuiObject') and not i:GetAttribute('P2R_HiddenByImporter') then
      i:SetAttribute('P2R_PreStaleVisible',i.Visible);i:SetAttribute('P2R_HiddenByImporter',true);i.Visible=false
     elseif i:IsA('UIGradient') or i:IsA('UIStroke') or i:IsA('UIShadow') then if not i:GetAttribute('P2R_HiddenByImporter')then i:SetAttribute('P2R_PreStaleEnabled',i.Enabled)end;i:SetAttribute('P2R_HiddenByImporter',true);i.Enabled=false
     elseif i:IsA('UIListLayout') or i:IsA('UIGridLayout') or i:IsA('UIPadding') or i:IsA('UICorner') or i:IsA('UIFlexItem')then
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
