-- The three approved screens are compiled importer output, not hand-drawn UI.
local Data=require(script.Parent.ViewData)
local View={}
local allowed={Frame=true,TextLabel=true,ImageLabel=true,UICorner=true,UIStroke=true}
local roleColors={['111213']='bg',['0d0e0f']='sidebar',['191b1d']='card',['232628']='button',['2a2d2f']='line',['f3f5f4']='text',['a0a6a3']='muted',['747c77']='dim',['8ee6a1']='green',['182e20']='greenDark',['ecefed']='accent',['161917']='ink',['25282a']='disabled',['7e8681']='dim',['3a3f3c']='toggle',['bec4c0']='thumb',['d8e3da']='accent',['202a22']='ink',['202325']='line',['d4dad6']='accent',['dde4df']='accent',['15291b']='ink'}
local function decode(v)
 if type(v)~='table'then return v end
 local p=v.v
 if v.t=='Color3'then return Color3.new(p[1],p[2],p[3])elseif v.t=='UDim2'then return UDim2.new(p[1],p[2],p[3],p[4])elseif v.t=='UDim'then return UDim.new(p[1],p[2])elseif v.t=='Vector2'then return Vector2.new(p[1],p[2])elseif v.t=='EnumItem'then return Enum[p[1]][p[2]]elseif v.t=='Font'then return Font.new(p[1],Enum.FontWeight[p[2]],Enum.FontStyle[p[3]])end
 error('Unknown compiled UI property type')
end
local function make(class,parent,props)local i=Instance.new(class);for k,v in props or{}do i[k]=v end;i.Parent=parent;return i end
function View.create(parent,palette)
 local model={palette=palette,images={},named={},common={},pages={},bindings={}}
 function model:style(i,props)
  local b=self.bindings[i]or{};self.bindings[i]=b
  for prop,role in props do b[prop]=role;i:SetAttribute('UI_Color_'..prop,role);i[prop]=self.palette[role]end
 end
 function model:register(i)
  local b={};for k,v in i:GetAttributes()do local prop=k:match('^UI_Color_(.+)$');if prop then b[prop]=v end end
  if next(b)then self.bindings[i]=b end
  for _,child in i:GetChildren()do self:register(child)end
 end
 function model:theme(nextPalette)
  self.palette=nextPalette;for i,props in self.bindings do if i.Parent then for prop,role in props do i[prop]=nextPalette[role]end else self.bindings[i]=nil end end
 end
 function model:clone(i,parent)
  local copy=i:Clone();copy.Parent=parent;self:register(copy);return copy
 end
 local viewport=make('ScrollingFrame',parent,{Name='Desktop viewport',Size=UDim2.fromScale(1,1),CanvasSize=UDim2.fromOffset(624,860),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=0,ScrollingDirection=Enum.ScrollingDirection.XY});model.viewport=viewport;model:style(viewport,{ScrollBarImageColor3='line'})
 local root=make('Frame',viewport,{Name='PenpotBridge',Size=UDim2.new(0,624,1,0),BorderSizePixel=0,ClipsDescendants=true});model.root=root;model:style(root,{BackgroundColor3='bg'})
 make('UISizeConstraint',root,{MaxSize=Vector2.new(624,860)})
 local body=make('ScrollingFrame',root,{Name='Content',Position=UDim2.fromOffset(136,40),Size=UDim2.new(0,488,1,-40),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,CanvasSize=UDim2.fromOffset(488,820),ScrollingDirection=Enum.ScrollingDirection.Y});model.body=body;model:style(body,{ScrollBarImageColor3='line'})
 local cache={};local warned=false
 local function localImage(key)
  if cache[key]then return cache[key]end
  local data=Data.masks[key];assert(data,'Missing compiled icon')
  local ok,image=pcall(function()
   local result=game:GetService('AssetService'):CreateEditableImage({Size=Vector2.new(data.w,data.h)})
   assert(result,'Local icon memory is unavailable')
   local alpha=game:GetService('EncodingService'):Base64Decode(buffer.fromstring(data.alpha));local rgba=buffer.create(data.w*data.h*4)
   for i=0,data.w*data.h-1 do buffer.writeu8(rgba,i*4,255);buffer.writeu8(rgba,i*4+1,255);buffer.writeu8(rgba,i*4+2,255);buffer.writeu8(rgba,i*4+3,buffer.readu8(alpha,i))end
   result:WritePixelsBuffer(Vector2.zero,Vector2.new(data.w,data.h),rgba);return result
  end)
  if ok then cache[key]=image;table.insert(model.images,image);return image end
  if not warned then warned=true;warn('[Penpot Bridge] Local icon rendering unavailable: '..tostring(image))end
 end
 local rootId=Data.scenes[1].items[1].id
 for sceneIndex,scene in Data.scenes do
  local page=make('Frame',body,{Name=scene.name,Size=UDim2.fromOffset(488,820),BackgroundTransparency=1,Visible=sceneIndex==1});model.pages[scene.name]=page;model.named[scene.name]={}
  local instances,sharedById={},{}
  for _,item in scene.items do
   assert(allowed[item.class],'Compiled UI class is not allowed')
   if item.parent==0 then instances[item.id]=root
   else
    local position=item.props.Position and decode(item.props.Position);local top=item.parent==rootId
    local shared=sharedById[item.parent]or(top and(not position or position.X.Offset<136 or position.Y.Offset<40))
    sharedById[item.id]=shared
    if not shared or sceneIndex==1 then
     local target=top and(shared and root or page)or instances[item.parent]
     if target then
      local i=Instance.new(item.class)
      for prop,value in item.props do
       local v=decode(value);i[prop]=v
       if typeof(v)=='Color3'and roleColors[v:ToHex():lower()]then model:style(i,{[prop]=roleColors[v:ToHex():lower()]})end
      end
      if top and not shared then i.Position-=UDim2.fromOffset(136,40)end
      if item.mask then local image=localImage(item.mask);if image then i.ImageContent=Content.fromObject(image)end end
      i.Parent=target;instances[item.id]=i
      local names=shared and model.common or model.named[scene.name];names[i.Name]=names[i.Name]or{};table.insert(names[i.Name],i)
      if shared and top and i:IsA('GuiObject')then
       i:SetAttribute('UI_SourceY',i.Position.Y.Offset);i:SetAttribute('UI_SourceHeight',i.Size.Y.Offset)
       if position.Y.Offset>=760 then i:SetAttribute('UI_BottomAligned',true)end
       if i.Name=='Sidebar'or i.Name=='Sidebar divider'then i:SetAttribute('UI_FillHeight',true)end
      end
     end
    end
   end
  end
 end
 function model:get(scene,name,index)
  local list=(scene=='Shared'and self.common or self.named[scene])[name];assert(list and list[index or 1],'Missing design layer: '..scene..' / '..name);return list[index or 1]
 end
 function model:list(scene,name)
  local list=(scene=='Shared'and self.common or self.named[scene])[name]or{};local copy=table.clone(list);table.sort(copy,function(a,b)return a:IsA('GuiObject')and b:IsA('GuiObject')and a.Position.Y.Offset<b.Position.Y.Offset end);return copy
 end
 function model:hit(parent,name,box,textLayer,primary)
  local b=make('TextButton',parent,{Name=name,Position=box.Position,Size=box.Size,Text=textLayer and textLayer.Text or'',TextTransparency=1,BackgroundTransparency=1,BorderSizePixel=0,ZIndex=10000,AutoButtonColor=false})
  if textLayer then b:GetPropertyChangedSignal('Text'):Connect(function()textLayer.Text=b.Text end)end
  if primary then
   local function paint()self:style(box,{BackgroundColor3=b.Interactable and'accent'or'disabled'});if textLayer then self:style(textLayer,{TextColor3=b.Interactable and'ink'or'dim'})end end
   b:GetPropertyChangedSignal('Interactable'):Connect(paint);paint()
  end
  return b
 end
 function model:button(scene,label,primary)
  return self:hit(self.pages[scene],label,self:get(scene,'Button / '..label),self:get(scene,'Label / '..label),primary)
 end
 function model:show(name)
  for key,page in self.pages do page.Visible=key==name end
  self.body.CanvasPosition=Vector2.zero
  self.body.AutomaticCanvasSize=Enum.AutomaticSize.None;self.body.CanvasSize=UDim2.fromOffset(488,820)
 end
 function model:layout()
  local targetSize=UDim2.fromOffset(624,math.clamp(self.viewport.AbsoluteSize.Y,500,860));if self.root.Size~=targetSize then self.root.Size=targetSize end
  local width=self.viewport.AbsoluteSize.X;self.root.Position=UDim2.fromOffset(math.max(0,(width-624)/2),0);self.viewport.ScrollBarThickness=(width<624 or self.viewport.AbsoluteSize.Y<500)and 4 or 0;self.viewport.CanvasSize=UDim2.fromOffset(math.max(624,width),self.root.AbsoluteSize.Y)
  local height=self.root.AbsoluteSize.Y;for _,i in self.root:GetChildren()do if i:IsA('GuiObject')then
   if i:GetAttribute('UI_BottomAligned')then i.Position=UDim2.fromOffset(i.Position.X.Offset,i:GetAttribute('UI_SourceY')+height-860)end
   if i:GetAttribute('UI_FillHeight')then i.Size=UDim2.fromOffset(i.Size.X.Offset,height-40)end
  end end
 end
 local connection=root:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()model:layout()end)
 local viewportConnection=viewport:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()model:layout()end)
 function model:destroy()connection:Disconnect();viewportConnection:Disconnect();viewport:Destroy();for _,i in self.images do i:Destroy()end;table.clear(self.bindings)end
 model:layout();return model
end
return View
