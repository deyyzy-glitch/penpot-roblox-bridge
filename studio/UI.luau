return function(plugin,Importer,Assets)
 local Http=game:GetService('HttpService')
 local Selection=game:GetService('Selection')
 local C={bg=Color3.fromRGB(18,21,28),card=Color3.fromRGB(28,33,43),line=Color3.fromRGB(47,55,70),text=Color3.fromRGB(239,243,250),muted=Color3.fromRGB(151,165,187),accent=Color3.fromRGB(133,181,255),ink=Color3.fromRGB(15,30,52),green=Color3.fromRGB(127,222,184),amber=Color3.fromRGB(255,201,126)}
 local toolbar=plugin:CreateToolbar('Penpot Bridge')
 local toggle=toolbar:CreateButton('Penpot Bridge','Bring your Penpot designs into Studio','','Penpot Bridge')
 local widget=plugin:CreateDockWidgetPluginGuiAsync('PenpotRobloxImporter.v2',DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float,false,false,440,760,360,540));widget.Title='Penpot Bridge'
 local function create(class,parent,props)
  local i=Instance.new(class);for k,v in pairs(props or {}) do i[k]=v end;i.Parent=parent;return i
 end
 local function round(i,r)create('UICorner',i,{CornerRadius=UDim.new(0,r or 12)})end
 local function label(parent,text,y,h,size,color)
  return create('TextLabel',parent,{BackgroundTransparency=1,Position=UDim2.new(0,0,0,y),Size=UDim2.new(1,0,0,h),Text=text,FontFace=Font.fromEnum(Enum.Font.BuilderSans),TextSize=size or 14,TextColor3=color or C.text,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,TextWrapped=true})
 end
 local function button(parent,text,y,h,primary)
  local b=create('TextButton',parent,{Name=text,Position=UDim2.new(0,0,0,y),Size=UDim2.new(1,0,0,h or 42),BackgroundColor3=primary and C.accent or C.line,BorderSizePixel=0,Text=text,TextColor3=primary and C.ink or C.text,FontFace=Font.fromEnum(Enum.Font.BuilderSansMedium),TextSize=14,TextWrapped=true,AutoButtonColor=false});round(b,10)
  b.MouseEnter:Connect(function() b.BackgroundColor3=primary and Color3.fromRGB(158,198,255) or Color3.fromRGB(59,69,87) end)
  b.MouseLeave:Connect(function() b.BackgroundColor3=primary and C.accent or C.line end)
  return b
 end
 local root=create('Frame',widget,{Name='PenpotBridge',Size=UDim2.fromScale(1,1),BackgroundColor3=C.bg,BorderSizePixel=0})
 local header=create('Frame',root,{Position=UDim2.fromOffset(22,18),Size=UDim2.new(1,-44,0,84),BackgroundTransparency=1})
 local mark=create('Frame',header,{Size=UDim2.fromOffset(34,34),Position=UDim2.fromOffset(0,5),BackgroundColor3=C.accent,BorderSizePixel=0});round(mark,10)
 local logo=label(mark,'↗',0,34,23,C.ink);logo.TextXAlignment=Enum.TextXAlignment.Center
 local title=label(header,'Penpot Bridge',1,30,23);title.Position=UDim2.fromOffset(46,0);title.Size=UDim2.new(1,-46,0,30)
 local subtitle=label(header,'Your design. Ready for Studio.',34,22,13,C.muted);subtitle.Position=UDim2.fromOffset(46,31);subtitle.Size=UDim2.new(1,-46,0,22)
 local connection=label(header,'○  Local helper · connection not checked',64,18,12,C.muted)
 local nav=create('Frame',root,{Position=UDim2.fromOffset(22,112),Size=UDim2.new(1,-44,0,36),BackgroundColor3=C.card,BorderSizePixel=0});round(nav,10)
 local body=create('ScrollingFrame',root,{Name='Content',Position=UDim2.fromOffset(22,164),Size=UDim2.new(1,-44,1,-282),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=C.line,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new()})
 local pages,tabs={},{}
 local function page(name)
  local f=create('Frame',body,{Name=name,Size=UDim2.new(1,-8,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Visible=false});pages[name]=f;return f
 end
 local setupPage=page('Setup');local importPage=page('Design');local reviewPage=page('Review');local settingsPage=page('Options')
 local currentTab='Design'
 local primary
 local function showTab(name)
  currentTab=name
  for n,p in pairs(pages) do p.Visible=n==name;tabs[n].BackgroundTransparency=n==name and 0 or 1;tabs[n].TextColor3=n==name and C.text or C.muted end
  body.CanvasPosition=Vector2.zero
  if primary then
   if name=='Setup' then primary.Text='Check connection & continue'
   elseif primary.Text=='Check connection & continue' then primary.Text='Review import' end
  end
 end
 for index,name in ipairs({'Setup','Design','Review','Options'}) do
  local tab=create('TextButton',nav,{Position=UDim2.new((index-1)/4,4,0,4),Size=UDim2.new(1/4,-8,1,-8),BackgroundColor3=C.line,BorderSizePixel=0,Text=name,TextColor3=C.muted,FontFace=Font.fromEnum(Enum.Font.BuilderSansMedium),TextSize=13});round(tab,7);tabs[name]=tab;tab.MouseButton1Click:Connect(function()showTab(name)end)
 end
 local function card(parent,y,h)
  local f=create('Frame',parent,{Position=UDim2.fromOffset(0,y),Size=UDim2.new(1,0,0,h),BackgroundColor3=C.card,BorderSizePixel=0});round(f,14)
  return create('Frame',f,{Position=UDim2.fromOffset(16,12),Size=UDim2.new(1,-32,1,-24),BackgroundTransparency=1})
 end
 local setupIntro=card(setupPage,0,112)
 label(setupIntro,'PENPOT → YOUR PC → STUDIO',0,20,11,C.accent)
 label(setupIntro,'Why a local helper?',27,28,18)
 label(setupIntro,'It passes designs between the two apps and uploads new images. Your finished game does not need it.',59,40,13,C.muted)
 local setupSteps=card(setupPage,126,224)
 label(setupSteps,'FIRST CONNECTION',0,20,11,C.accent)
 label(setupSteps,'1. Download the Windows helper from GitHub Releases (address below). Extract the ZIP and run Start-Penpot-Bridge.cmd.\n\n2. Click Check connection below. Allow 127.0.0.1 if Roblox asks; that address is this PC.\n\n3. In Penpot, prepare your selection and send it. Then use Design here.',28,168,13,C.text)
 local helperState=label(setupPage,'Connection not checked. Click below when the helper is running.',362,82,14,C.muted)
 local checkHelper=button(setupPage,'Check local connection',454,40,true)
 label(setupPage,'Image upload setup and helper status (copy this address):',508,34,12,C.muted)
 local helperURL=create('TextBox',setupPage,{Name='Helper address',Position=UDim2.fromOffset(0,548),Size=UDim2.new(1,0,0,38),BackgroundColor3=C.card,BorderSizePixel=0,Text='http://127.0.0.1:43129/setup',TextEditable=false,ClearTextOnFocus=false,FontFace=Font.fromEnum(Enum.Font.RobotoMono),TextSize=13,TextColor3=C.accent});round(helperURL,10)
 label(setupPage,'The Studio plugin cannot start programs on your PC. If the helper was launched by Codex, it may have no visible window; Check connection still verifies it.',600,66,12,C.muted)
 label(setupPage,'Download the desktop helper — select and copy this address:',682,38,12,C.muted)
 local downloadURL=helperURL:Clone();downloadURL.Name='Public helper download';downloadURL.Text='https://github.com/deyyzy-glitch/penpot-roblox-bridge/releases/latest';downloadURL.Position=UDim2.fromOffset(0,728);downloadURL.Parent=setupPage
 local source=card(importPage,0,166)
 label(source,'01  /  CHOOSE A DESIGN',0,20,11,C.accent)
 local sourceTitle=label(source,'Start with a Penpot selection',28,30,18)
 local sourceMeta=label(source,'In Penpot: Prepare selected design → Send to Studio. Then receive it here.',64,38,13,C.muted)
 local receive=button(source,'Receive from Penpot',110,32,false)
 local open=button(importPage,'Open a design bundle…',180,40,false)
 local paste=button(importPage,'Paste design JSON',230,34,false)
 local destination=card(importPage,284,124)
 label(destination,'02  /  PLACE IT IN STUDIO',0,20,11,C.accent)
 local targetLabel=label(destination,'StarterGui',28,28,16)
 local targetButton=button(destination,'Use selected UI container',64,32,false)
 local hint=label(importPage,'Native UI stays editable. Reimport the same selection to sync changes.',430,50,13,C.muted)
 local reviewSummary=label(reviewPage,'Load a design to see its changes.',0,58,19)
 local changeList=label(reviewPage,'',74,10,13,C.text);changeList.AutomaticSize=Enum.AutomaticSize.Y;changeList.TextYAlignment=Enum.TextYAlignment.Top
 local options={responsive=false,hideRemoved=false,force=false,allowClassChanges=false}
 local previewPlan,document,token,target=nil,nil,nil,game:GetService('StarterGui')
 local optionY=0
 local function option(key,titleText,description)
  local inner=card(settingsPage,optionY,104);local b=button(inner,titleText,0,32,false);local desc=label(inner,description,42,40,12,C.muted)
  b.Text='○  '..titleText;b.TextXAlignment=Enum.TextXAlignment.Left
  b.MouseButton1Click:Connect(function()options[key]=not options[key];b.Text=(options[key] and '●  ' or '○  ')..titleText;previewPlan=nil end)
  optionY+=116
 end
 option('hideRemoved','Hide removed elements','Removed objects are retained so references and scripts stay intact.')
 option('force','Use design values','Overwrite local appearance changes. Explicit P2R_Locks still win.')
 option('allowClassChanges','Allow object type changes','Keep the old object and create its new type. Review references afterward.')
 local advanced=button(settingsPage,'Advanced JSON & mappings',optionY,38,false)
 local status=label(root,'Start with Setup to check the local connection.',0,44,12,C.muted);status.Position=UDim2.new(0,22,1,-108);status.Size=UDim2.new(1,-44,0,44)
 primary=button(root,'Review import',0,44,true);primary.Position=UDim2.new(0,22,1,-58);primary.Size=UDim2.new(1,-44,0,44)
 local overlay=create('Frame',root,{Name='Advanced',Size=UDim2.fromScale(1,1),BackgroundColor3=C.bg,Visible=false,ZIndex=20})
 local modal=create('Frame',overlay,{Position=UDim2.fromOffset(22,22),Size=UDim2.new(1,-44,1,-44),BackgroundTransparency=1,ZIndex=21})
 local modalTitle=label(modal,'Advanced JSON',0,32,20);modalTitle.ZIndex=22
 local json=create('TextBox',modal,{Name='JSON',Position=UDim2.fromOffset(0,48),Size=UDim2.new(1,0,1,-116),BackgroundColor3=C.card,BorderSizePixel=0,TextColor3=C.text,FontFace=Font.fromEnum(Enum.Font.RobotoMono),TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,MultiLine=true,ClearTextOnFocus=false,TextWrapped=true,Text='',ZIndex=22});round(json,12)
 local saveJSON=button(modal,'Use this JSON',0,44,true);saveJSON.Position=UDim2.new(0,0,1,-54);saveJSON.ZIndex=22
 local close=button(modal,'×',0,30,false);close.Position=UDim2.new(1,-34,0,0);close.Size=UDim2.fromOffset(34,30);close.ZIndex=22
 close.MouseButton1Click:Connect(function()overlay.Visible=false end)
 local busy=false
 local function show(s,errorState)status.Text=s;status.TextColor3=errorState and C.amber or C.muted end
 local function guard(fn)
  if busy then return end;busy=true;primary.Active=false
  local ok,e=pcall(fn);busy=false;primary.Active=true
  if not ok then show(tostring(e):gsub('^.-:%d+: ',''),true);warn('[Penpot Bridge] '..tostring(e))end
 end
 local function checkConnection()
  helperState.Text='Checking the helper on this PC…'
  local ok,value=pcall(function()token=Assets.connect();return Assets.status(token)end)
  if not ok then
   token=nil;connection.Text='○  Local helper · unreachable';connection.TextColor3=C.amber
   helperState.Text='Cannot reach the helper. Run Start-Penpot-Bridge.cmd, then check again. If Roblox denied access, check this plugin’s HTTP permission.';helperState.TextColor3=C.amber
   show('Connection failed. Follow the Setup steps.',true);return false
  end
  connection.Text='●  Local helper · running';connection.TextColor3=C.green
  helperState.Text=value.configured and 'Helper running · image uploads ready. Continue to Design.' or 'Helper running · image uploads need setup at the address below.';helperState.TextColor3=value.configured and C.green or C.amber
  plugin:SetSetting('SetupSeen_v2',true);show(value.configured and 'Connected. In Penpot, prepare and send your design.' or 'Design transfer is ready. Configure image uploads before importing new images.')
  return true
 end
 checkHelper.MouseButton1Click:Connect(function()guard(checkConnection)end)
 local function loadDocument(value)
  local d=type(value)=='string' and Http:JSONDecode(value) or value
  Importer.validate(d);document=d;previewPlan=nil
  if Assets then Assets.pending(d,plugin,Importer)end
  local count=0;local function walk(n)count+=1;for _,c in ipairs(n.children)do walk(c)end end;walk(d.design)
  sourceTitle.Text=d.design.name;sourceMeta.Text=string.format('%d elements  ·  %d image surfaces\n%d × %d design pixels',count,#(d.assets or {}),d.design.width,d.design.height)
  show('Design received. Ready to review.');showTab('Design');primary.Text='Review import'
 end
 local function previewClick()
  assert(document,'Choose a design first.')
  if Assets then Assets.pending(document,plugin,Importer)end
  previewPlan=Importer.prepare(document,target,table.clone(options));local s=previewPlan.stats
  local pending=Assets and #Assets.pending(document,plugin,Importer) or 0
  reviewSummary.Text=string.format('%d new  ·  %d changed\n%d unchanged  ·  %d removed',s.added,s.updated,s.unchanged,s.removed)
  local lines={pending>0 and string.format('%d unique images will upload to your Roblox account.',pending) or 'No new image uploads needed.'}
  if document.options then
   table.insert(lines,'Text mode: '..tostring(document.options.textMode or 'legacy')..'.')
   table.insert(lines,document.options.behaviors and 'Scrolling/panel tags enabled. Panel actions add a generated controller.' or 'Optional behavior tags are off.')
  end
  if previewPlan.nativeGroups then table.insert(lines,'Suitable opacity groups remain native and editable.') end
  if document.tokens then table.insert(lines,string.format('%d token sets and %d themes retained.',#document.tokens.sets,#document.tokens.themes));if document.options and document.options.runtimeThemes then table.insert(lines,'An optional Penpot Theme ModuleScript will be generated. Your game must call Apply explicitly.')end end
  local q=previewPlan.quality
  table.insert(lines,string.format('\nIMPORT QUALITY\n%d native · %d image surfaces · %d smoothed surfaces\n%d covered by an ancestor image · %d substituted fonts\n%d native layouts',q.native,q.images,q.smoothed,q.covered,q.fonts,q.layouts))
  table.insert(lines,'')
  for index,item in q.items do if index<=150 then table.insert(lines,item.name..' — '..item.detail)end end
  if #q.items>150 then table.insert(lines,string.format('… %d more layers. Export a smaller selection for a complete on-screen report.',#q.items-150))end
  if s.conflicts>0 then table.insert(lines,string.format('%d local overrides will be preserved.',s.conflicts))end
  if s.classChanges>0 then table.insert(lines,string.format('%d object type changes require the option to be enabled.',s.classChanges))end
  if options.force then table.insert(lines,'Design values will overwrite unlocked local appearance changes.')end
  if options.hideRemoved then table.insert(lines,'Removed elements will be hidden and retained.')end
  table.insert(lines,'')
  for ix,c in ipairs(previewPlan.changes)do if ix<=100 then table.insert(lines,({add='+',update='↻',class='◇',['retain stale']='−'})[c.action]..'  '..c.name)end end
  if #previewPlan.warnings>0 then table.insert(lines,'\nDETAILS');for _,w in ipairs(previewPlan.warnings)do table.insert(lines,'• '..w);warn('[Penpot Bridge] '..w)end end
  changeList.Text=table.concat(lines,'\n');showTab('Review');primary.Text=pending>0 and 'Upload images & import' or 'Import design';show('Review the changes, then import.')
 end
 local function applyClick()
  assert(document and previewPlan,'Review the import first.')
  local latest=Importer.prepare(document,target,table.clone(options));for k,v in pairs(latest.stats)do assert(v==previewPlan.stats[k],'The scene changed. Review the import again.')end
  if Assets then Assets.upload(document,plugin,token,function(index,total,name)show(string.format('Uploading image %d of %d: %s',index,total,name))end,Importer)end
  latest=Importer.prepare(document,target,table.clone(options))
  local imported=Importer.apply(latest,function(done,total)show(string.format('Building native UI… %d / %d',done,total))end)
  Selection:Set({imported});previewPlan=nil;primary.Text='Review import';showTab('Design');show('Imported successfully. Re-export this design to sync changes.');connection.Text=token and '●  Local helper · used for this import' or '●  Bundle imported';connection.TextColor3=C.green
  return imported
 end
 receive.MouseButton1Click:Connect(function()guard(function()
  assert(Assets,'Assets module is missing');show('Connecting to this PC. Allow 127.0.0.1 if Roblox asks.');token=Assets.connect();connection.Text='●  Local helper · running';connection.TextColor3=C.green
  local response=Http:RequestAsync({Url='http://127.0.0.1:43129/document',Method='GET',Headers={Authorization='Bearer '..token}})
  assert(response.Success,'Send a design from the Penpot companion first.');loadDocument(response.Body)
 end)end)
 open.MouseButton1Click:Connect(function()guard(function()local file=game:GetService('StudioService'):PromptImportFileAsync({'json'});if file then local data=file:GetBinaryContents();assert(#data<=64000000,'Bundle exceeds 64 MB');loadDocument(data)end end)end)
 targetButton.MouseButton1Click:Connect(function()guard(function()local selected=Selection:Get()[1];assert(not selected or selected==game.StarterGui or selected:IsA('ScreenGui')or selected:IsA('GuiObject'),'Select StarterGui, a ScreenGui, or a UI container.');target=selected or game.StarterGui;targetLabel.Text=target:GetFullName();previewPlan=nil end)end)
 local function editJSON()json.Text=document and Http:JSONEncode(document)or '';overlay.Visible=true end
 paste.MouseButton1Click:Connect(editJSON);advanced.MouseButton1Click:Connect(editJSON)
 saveJSON.MouseButton1Click:Connect(function()guard(function()loadDocument(json.Text);overlay.Visible=false end)end)
 primary.MouseButton1Click:Connect(function()guard(function()if currentTab=='Setup' then if checkConnection()then showTab('Design')end elseif currentTab=='Review' and previewPlan then applyClick()else previewClick()end end)end)
 toggle.Click:Connect(function()widget.Enabled=not widget.Enabled end)
 plugin.Unloading:Connect(function()widget:Destroy();toolbar:Destroy()end)
 local initialTab=plugin:GetSetting('SetupSeen_v2') and 'Design' or 'Setup'
 showTab(initialTab)
 if initialTab=='Setup' then primary.Text='Check connection & continue' end
 return {widget=widget,loadDocument=loadDocument,checkConnection=checkConnection,preview=function()guard(previewClick)end,apply=function()local imported;guard(function()imported=applyClick()end);return imported end,receive=function()token=Assets.connect();return token end,controls={status=status,primary=primary,document=json,helperState=helperState,connection=connection},getTarget=function()return target end,getDocument=function()return document end}
end
