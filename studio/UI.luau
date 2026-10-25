return function(plugin,Importer,Assets,presentation)
 local Http=game:GetService('HttpService')
 local Selection=game:GetService('Selection')
 local function rgb(r,g,b)return Color3.fromRGB(r,g,b)end
 local palettes={
 dark={bg=rgb(13,21,29),sidebar=rgb(15,24,33),card=rgb(23,35,47),line=rgb(42,65,85),text=rgb(241,246,255),muted=rgb(179,199,219),accent=rgb(0,132,255),ink=rgb(255,255,255),green=rgb(62,191,159),amber=rgb(247,185,99),button=rgb(29,44,59),hover=rgb(39,59,79),accentHover=rgb(35,153,255),selected=rgb(15,57,98)},
 light={bg=rgb(249,251,255),sidebar=rgb(234,244,255),card=rgb(255,255,255),line=rgb(193,215,242),text=rgb(15,25,42),muted=rgb(71,94,125),accent=rgb(0,112,235),ink=rgb(254,254,254),green=rgb(16,119,94),amber=rgb(147,87,15),button=rgb(234,242,253),hover=rgb(220,234,251),accentHover=rgb(0,95,210),selected=rgb(207,229,255)}
 }
 local theme='dark';pcall(function()if plugin:GetSetting('BridgeAppearance')=='light'then theme='light'end end)
 local C=palettes[theme];local setTheme;local switchPainters={}
 presentation=presentation or {}
 local toolbar,toggle
 if presentation.preview then local event=Instance.new('BindableEvent');toolbar={Destroy=function()event:Destroy()end};toggle={Click=event.Event}
 else toolbar=plugin:CreateToolbar('Penpot Bridge');toggle=toolbar:CreateButton('Penpot Bridge','Open Penpot Bridge','','Penpot Bridge')end
 local widget=plugin:CreateDockWidgetPluginGuiAsync(presentation.preview and'PenpotBridge.preview.'..tostring(presentation.width or 680)or'PenpotRobloxImporter.v2',DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float,false,false,presentation.width or 680,presentation.height or 740,360,420));widget.Title=presentation.preview and'Penpot Bridge · Preview'or'Penpot Bridge'
 local flowBase=setmetatable({},{__mode='k'});local cards={};local requestLayout
 local interactive={}
 local function create(class,parent,props)local i=Instance.new(class);for k,v in pairs(props or {})do i[k]=v end;i.Parent=parent;return i end
 local function round(i,r)create('UICorner',i,{CornerRadius=UDim.new(0,r or 8)})end
 local function border(i,color)create('UIStroke',i,{Color=color or C.line,Thickness=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})end
 local function label(parent,text,y,h,size,color)
  return create('TextLabel',parent,{BackgroundTransparency=1,Position=UDim2.fromOffset(0,y),Size=UDim2.new(1,0,0,h),Text=text,FontFace=Font.fromEnum(Enum.Font.BuilderSans),TextSize=size or 14,TextColor3=color or C.text,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,TextWrapped=true})
 end
 local function button(parent,text,y,h,primary)
  local b=create('TextButton',parent,{Name=text,Position=UDim2.fromOffset(0,y),Size=UDim2.new(1,0,0,h or 36),BackgroundColor3=primary and C.accent or C.button,BorderSizePixel=0,Text=text,TextColor3=primary and C.ink or C.text,FontFace=Font.fromEnum(Enum.Font.BuilderSansMedium),TextSize=13,TextWrapped=true,AutoButtonColor=false});round(b,7);if not primary then border(b)end;table.insert(interactive,b)
  b.MouseEnter:Connect(function()if b.Interactable then b.BackgroundColor3=primary and C.accentHover or C.hover end end)
  b.MouseLeave:Connect(function()b.BackgroundColor3=primary and C.accent or C.button end)
  return b
 end
 local options={responsive=false,hideRemoved=false,force=false,allowClassChanges=false,nativeGrids=false,generateRefs=false}
 local previewPlan,document,token,target=nil,nil,nil,game.StarterGui
 local lastImported,lastVerification,primary,refreshTemplates
 local pendingImages=0
 local busy=false
 local root=create('Frame',widget,{Name='PenpotBridge',Size=UDim2.fromScale(1,1),BackgroundColor3=C.bg,BorderSizePixel=0})
 local sidebar=create('Frame',root,{Name='Sidebar',Size=UDim2.new(0,132,1,0),BackgroundColor3=C.sidebar,BorderSizePixel=0})
 create('Frame',sidebar,{Position=UDim2.new(1,-1,0,0),Size=UDim2.new(0,1,1,0),BackgroundColor3=C.line,BorderSizePixel=0})
 local brandTiles={};for i=0,1 do local tile=create('Frame',sidebar,{Position=UDim2.fromOffset(19+i*6,24+i*8),Size=UDim2.fromOffset(12,16),BackgroundColor3=C.sidebar,BorderSizePixel=0});round(tile,3);border(tile,C.accent);table.insert(brandTiles,tile)end
 local brand=label(sidebar,'Penpot',20,20,14);brand.Position=UDim2.fromOffset(44,20);brand.Size=UDim2.new(1,-50,0,20);brand.FontFace=Font.fromEnum(Enum.Font.BuilderSansBold)
 local brandSub=label(sidebar,'BRIDGE',40,16,9,C.accent);brandSub.Position=UDim2.fromOffset(44,40);brandSub.Size=UDim2.new(1,-50,0,16)
 local section=label(sidebar,'WORKSPACE',84,18,10,C.muted);section.Position=UDim2.fromOffset(18,84)
 local nav=create('Frame',sidebar,{Name='Navigation',Position=UDim2.fromOffset(10,112),Size=UDim2.new(1,-20,0,208),BackgroundTransparency=1})
 local secondaryNav=create('Frame',sidebar,{Position=UDim2.new(0,10,1,-178),Size=UDim2.new(1,-20,0,82),BackgroundTransparency=1})
 local connection=label(sidebar,'○  Helper\nNot checked',0,46,11,C.muted);connection.Name='Connection status';connection.Position=UDim2.new(0,18,1,-73);connection.Size=UDim2.new(1,-32,0,46)
 local header=create('Frame',root,{Name='Page header',Position=UDim2.fromOffset(154,20),Size=UDim2.new(1,-176,0,90),BackgroundTransparency=1})
 local eyebrow=label(header,'WORKSPACE / IMPORT',0,16,10,C.accent)
 local title=label(header,'Import your design',24,29,23);title.FontFace=Font.fromEnum(Enum.Font.BuilderSansBold)
 local subtitle=label(header,'Bring a Penpot selection into this place.',60,28,12,C.muted)
 local headerLine=create('Frame',root,{Position=UDim2.fromOffset(132,122),Size=UDim2.new(1,-132,0,1),BackgroundColor3=C.line,BorderSizePixel=0})
 local body=create('ScrollingFrame',root,{Name='Content',Position=UDim2.fromOffset(154,143),Size=UDim2.new(1,-174,1,-247),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=C.line,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),ScrollingDirection=Enum.ScrollingDirection.Y})
 create('UIPadding',body,{PaddingBottom=UDim.new(0,14)})
 local pages,tabs={},{}
 local function page(name)local p=create('Frame',body,{Name=name,Position=UDim2.fromOffset(4,3),Size=UDim2.new(1,-14,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Visible=false});pages[name]=p;return p end
 local setupPage=page('Setup');local importPage=page('Design');local reviewPage=page('Review');local verifyPage=page('Verify');local settingsPage=page('Options');local templateOverlay=page('Templates')
 local views={Setup={'CONNECTION','Connect once. Create freely.','The local helper links Penpot with Studio.'},Design={'WORKSPACE / IMPORT','Import your design','Receive a selection, choose its destination, then review.'},Review={'WORKSPACE / REVIEW','Review changes','Check what will change before importing.'},Verify={'WORKSPACE / VERIFY','Check your import','Compare the received design with its imported objects.'},Templates={'LIBRARY / TEMPLATES','Reusable templates','Connect Penpot layers to your own Studio components.'},Options={'PREFERENCES','Import settings','Choose how updates affect your UI.'}}
 local currentTab='Design'
 local function refreshAction()
  if not primary then return end
  primary.Visible=currentTab=='Design'or currentTab=='Review'
  if primary.Visible then local y=currentTab=='Review'and 146 or 430;primary.Parent=pages[currentTab];primary.Position=UDim2.fromOffset(0,y);primary.Size=UDim2.new(1,0,0,36);flowBase[primary]={parent=primary.Parent,y=y,h=36}end
  primary.Interactable=not busy and(currentTab=='Setup'or document~=nil)
  primary.BackgroundTransparency=primary.Interactable and 0 or .65
  if currentTab=='Setup'then primary.Text='Check connection'
  elseif currentTab=='Verify'then primary.Text='Run verification'
  elseif currentTab=='Review'and previewPlan then primary.Text=pendingImages>0 and'Upload images & import'or'Import design'
  else primary.Text='Review import'end
  if requestLayout then requestLayout()end
 end
 local function showTab(name)
  currentTab=name
  for n,p in pages do p.Visible=n==name;tabs[n].BackgroundTransparency=n==name and 0 or 1;tabs[n].TextColor3=n==name and C.accent or C.muted end
  local v=views[name];eyebrow.Text=v[1];title.Text=v[2];subtitle.Text=v[3];body.CanvasPosition=Vector2.zero
  if name=='Templates'and refreshTemplates then refreshTemplates()end
  refreshAction()
 end
 for _,item in ipairs({{'Design','Import',0},{'Review','Review',44},{'Verify','Verify',88},{'Templates','Templates',150},{'Options','Settings',0,true},{'Setup','Connection',44,true}})do
  local name,text,y,secondary=table.unpack(item);local b=button(secondary and secondaryNav or nav,text,y,36,false);b.Name=name;b.BackgroundColor3=C.selected;b.TextXAlignment=Enum.TextXAlignment.Left;b.TextSize=13;create('UIPadding',b,{PaddingLeft=UDim.new(0,12)});for _,c in b:GetChildren()do if c:IsA('UIStroke')then c:Destroy()end end
  tabs[name]=b;b.MouseButton1Click:Connect(function()showTab(name)end)
  b.MouseLeave:Connect(function()b.BackgroundColor3=C.selected end)
 end
 local function card(parent,y,h)
  local f=create('Frame',parent,{Name='Card',Position=UDim2.fromOffset(0,y),Size=UDim2.new(1,0,0,h),BackgroundColor3=C.card,BorderSizePixel=0});round(f,9);border(f)
  local inner=create('Frame',f,{Position=UDim2.fromOffset(16,14),Size=UDim2.new(1,-32,1,-28),BackgroundTransparency=1});cards[f]={inner=inner,height=h};flowBase[f]={parent=parent,y=y,h=h};return inner
 end
 local setupIntro=card(setupPage,0,112);label(setupIntro,'YOUR DESIGN → THIS PC → STUDIO',0,18,10,C.accent);label(setupIntro,'A small bridge between your tools',26,24,17);label(setupIntro,'The helper transfers designs and uploads images. Your finished game works without it.',56,32,12,C.muted)
 local setupSteps=card(setupPage,126,190);label(setupSteps,'GET CONNECTED',0,18,10,C.accent);label(setupSteps,'1. Extract the helper ZIP and run its launcher.\n\n2. Check the connection below. Allow 127.0.0.1 if Studio asks; that is your own PC.\n\n3. Prepare and send a selection from Penpot.',30,130,13)
 local checkHelper=button(setupPage,'Check local connection',330,36,true)
 local helperState=label(setupPage,'Not checked yet. Start the helper, then check the connection.',382,58,13,C.muted)
 label(setupPage,'HELPER STATUS & IMAGE UPLOADS',462,18,10,C.muted)
 local helperURL=create('TextBox',setupPage,{Name='Helper address',Position=UDim2.fromOffset(0,490),Size=UDim2.new(1,0,0,40),BackgroundColor3=C.card,BorderSizePixel=0,Text='http://127.0.0.1:43129/setup',TextEditable=false,ClearTextOnFocus=false,FontFace=Font.fromEnum(Enum.Font.RobotoMono),TextSize=12,TextColor3=C.accent});round(helperURL,7);border(helperURL)
 label(setupPage,'DOWNLOAD THE WINDOWS HELPER',550,18,10,C.muted)
 local downloadURL=helperURL:Clone();downloadURL.Name='Public helper download';downloadURL.Text='https://github.com/deyyzy-glitch/penpot-roblox-bridge/releases/latest';downloadURL.TextWrapped=true;downloadURL.Size=UDim2.new(1,0,0,50);downloadURL.Position=UDim2.fromOffset(0,578);downloadURL.Parent=setupPage
 local source=card(importPage,0,164);label(source,'DESIGN SOURCE',0,18,10,C.accent)
 local sourceTitle=label(source,'Nothing received yet',25,28,18);sourceTitle.FontFace=Font.fromEnum(Enum.Font.BuilderSansMedium);sourceTitle.TextWrapped=false;sourceTitle.TextTruncate=Enum.TextTruncate.AtEnd
 local sourceMeta=label(source,'Prepare your selection in Penpot and send it to Studio.',60,35,12,C.muted)
 local receive=button(source,'Receive from Penpot',108,32,true)
 local open=button(importPage,'Open bundle',178,34,false);open.Size=UDim2.new(.5,-5,0,34)
 local paste=button(importPage,'Paste JSON',178,34,false);paste.Position=UDim2.new(.5,5,0,178);paste.Size=UDim2.new(.5,-5,0,34)
 local destination=card(importPage,228,116);label(destination,'IMPORT DESTINATION',0,18,10,C.muted)
 local targetLabel=label(destination,'StarterGui',24,23,15);targetLabel.TextWrapped=false;targetLabel.TextTruncate=Enum.TextTruncate.AtEnd
 local targetButton=button(destination,'Use selected container',59,29,false)
 local hint=label(importPage,'Reimport the same selection to sync changes. Local edits are preserved unless you choose otherwise.',365,52,12,C.muted)
 local verifyIntro=card(verifyPage,0,106);label(verifyIntro,'A SECOND PAIR OF EYES',0,18,10,C.accent);label(verifyIntro,'Checks objects, fonts, images and layout against the received design. Select an imported container if this place has several copies. Nothing is changed.',29,52,13,C.muted)
 local verifyButton=button(verifyPage,'Verify import',122,36,false)
 local verifySummary=label(verifyPage,'Receive a design to check its imported objects.',176,58,15,C.muted)
 local verifyList=create('Frame',verifyPage,{Name='Verification findings',Position=UDim2.fromOffset(0,250),Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1})
 create('UIListLayout',verifyList,{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,10)})
 local verifyWidth
 local function layoutFindings()
  local width=math.max(100,verifyList.AbsoluteSize.X-24)
  for _,row in verifyList:GetChildren()do local detail=row:FindFirstChild('Finding detail');if detail then local bounds=game:GetService('TextService'):GetTextSize(detail.Text,12,Enum.Font.BuilderSans,Vector2.new(width,100000));local height=math.ceil(bounds.Y)+6;detail.Size=UDim2.new(1,-24,0,height);row.Size=UDim2.new(1,0,0,64+height)end end
 end
 verifyList:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()local w=verifyList.AbsoluteSize.X;if w~=verifyWidth then verifyWidth=w;layoutFindings()end end)
 local reviewSummary=label(reviewPage,'No changes reviewed yet',0,48,19)
 local metrics={};for i,item in ipairs({{'added','New'},{'updated','Changed'},{'unchanged','Same'},{'removed','Removed'}})do local f=create('Frame',reviewPage,{Position=UDim2.new((i-1)/4,0,0,65),Size=UDim2.new(.25,-8,0,66),BackgroundColor3=C.card,BorderSizePixel=0});round(f,8);border(f);local value=label(f,'—',8,25,22,C.accent);value.TextXAlignment=Enum.TextXAlignment.Center;local caption=label(f,item[2],37,18,11,C.muted);caption.TextXAlignment=Enum.TextXAlignment.Center;metrics[item[1]]=value end
 label(reviewPage,'CONVERSION DETAILS',202,18,10,C.muted)
 local changeList=label(reviewPage,'Receive a design and choose Review import to see what will change.',235,10,13,C.muted);changeList.AutomaticSize=Enum.AutomaticSize.Y;changeList.TextYAlignment=Enum.TextYAlignment.Top;changeList.LineHeight=1.25
 local function clearVerification()for _,i in verifyList:GetChildren()do if i:IsA('Frame')then i:Destroy()end end;lastVerification=nil;verifySummary.Text=document and 'Ready to check the matching imported design.'or'Receive a design to check its imported objects.';verifySummary.TextColor3=C.muted end
 local appearance=card(settingsPage,0,100);label(appearance,'APPEARANCE',0,18,10,C.muted)
 local darkButton=button(appearance,'Dark',32,32,false);darkButton.Size=UDim2.new(.5,-5,0,32)
 local lightButton=button(appearance,'Light',32,32,false);lightButton.Position=UDim2.new(.5,5,0,32);lightButton.Size=UDim2.new(.5,-5,0,32)
 darkButton.MouseButton1Click:Connect(function()setTheme('dark')end);lightButton.MouseButton1Click:Connect(function()setTheme('light')end)
 label(settingsPage,'SYNC & EDITABILITY',120,18,10,C.muted)
 local optionY=150
 local function option(key,titleText,description)
  local inner=card(settingsPage,optionY,90);local heading=label(inner,titleText,0,22,14);heading.Size=UDim2.new(1,-60,0,22)
  label(inner,description,29,36,12,C.muted)
  local b=button(inner,'',0,24,false);b.Name=key;b.Position=UDim2.new(1,-42,0,0);b.Size=UDim2.fromOffset(42,24);round(b,12)
  local knob=create('Frame',b,{Position=UDim2.fromOffset(3,3),Size=UDim2.fromOffset(18,18),BackgroundColor3=C.muted,BorderSizePixel=0});round(knob,9)
  local function paint()knob.Position=UDim2.fromOffset(options[key]and 21 or 3,3);knob.BackgroundColor3=options[key]and C.ink or C.muted;b.BackgroundColor3=options[key]and C.accent or C.button end
  table.insert(switchPainters,paint);b.MouseLeave:Connect(paint)
  b.MouseButton1Click:Connect(function()if busy then return end;options[key]=not options[key];paint();previewPlan=nil;refreshAction()end)
  optionY+=100
 end
 option('hideRemoved','Hide removed layers','Retain old objects and references, but stop displaying removed layers.')
 option('nativeGrids','Native uniform grids','Use UIGridLayout for compatible grids. Irregular layouts keep their positions.')
 option('generateRefs','Gameplay references','Generate a module for finding imported UI by its source IDs.')
 option('force','Use design values','Replace unlocked local appearance edits with the received design values.')
 option('allowClassChanges','Allow object replacement','Retain the old object and create its new type or refreshed template.')
 local advanced=button(settingsPage,'Advanced JSON & mappings',optionY+6,36,false)
 local templateButton=button(settingsPage,'Manage reusable templates',optionY+54,36,false)
 local templateModal=card(templateOverlay,0,226);label(templateModal,'MAP A STUDIO COMPONENT',0,18,10,C.accent);label(templateModal,'Select a UI object in Explorer, give it a key, then use that key on a Reusable template layer in Penpot.',29,48,13,C.muted)
 local templateKey=create('TextBox',templateModal,{Name='Template key',Position=UDim2.fromOffset(0,95),Size=UDim2.new(1,0,0,36),BackgroundColor3=C.sidebar,BorderSizePixel=0,Text='',PlaceholderText='Template key, e.g. PrimaryButton',PlaceholderColor3=C.muted,ClearTextOnFocus=false,FontFace=Font.fromEnum(Enum.Font.BuilderSans),TextSize=13,TextColor3=C.text});round(templateKey,7);border(templateKey)
 local mapTemplate=button(templateModal,'Map selected component',149,35,true)
 label(templateOverlay,'Clones retain your component’s appearance, children and scripts. Map again after editing a template; refreshing existing clones requires reviewed replacement.',244,65,12,C.muted)
 label(templateOverlay,'MAPPED IN THIS PLACE',329,18,10,C.muted)
 local templateMappings=label(templateOverlay,'No templates mapped yet.',363,0,13,C.text);templateMappings.AutomaticSize=Enum.AutomaticSize.Y;templateMappings.TextYAlignment=Enum.TextYAlignment.Top;templateMappings.LineHeight=1.3
 local status=label(header,'',0,0,12,C.muted);status.Name='Progress';status.Visible=false
 primary=button(importPage,'Review import',430,36,true)
 local overlay=create('Frame',root,{Name='Advanced',Size=UDim2.fromScale(1,1),BackgroundColor3=C.bg,Visible=false,ZIndex=20})
 local modal=create('Frame',overlay,{Position=UDim2.fromOffset(24,24),Size=UDim2.new(1,-48,1,-48),BackgroundTransparency=1,ZIndex=21})
 local modalTitle=label(modal,'Advanced JSON',0,32,20);modalTitle.ZIndex=22
 local json=create('TextBox',modal,{Name='JSON',Position=UDim2.fromOffset(0,48),Size=UDim2.new(1,0,1,-116),BackgroundColor3=C.card,BorderSizePixel=0,TextColor3=C.text,FontFace=Font.fromEnum(Enum.Font.RobotoMono),TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,MultiLine=true,ClearTextOnFocus=false,TextWrapped=true,Text='',ZIndex=22});round(json,8)
 local saveJSON=button(modal,'Use this JSON',0,38,true);saveJSON.Position=UDim2.new(0,0,1,-44);saveJSON.ZIndex=22
 local close=button(modal,'×',0,30,false);close.Position=UDim2.new(1,-34,0,0);close.Size=UDim2.fromOffset(34,30);close.ZIndex=22;close.MouseButton1Click:Connect(function()overlay.Visible=false end)
 local errorNotice=create('Frame',root,{Name='Error details',Position=UDim2.new(0,154,1,-288),Size=UDim2.new(1,-180,0,180),BackgroundColor3=C.card,BorderSizePixel=0,Visible=false,ZIndex=10});round(errorNotice,8);border(errorNotice,C.amber)
 local errorHeading=label(errorNotice,'Unable to finish this step',10,25,14,C.amber);errorHeading.Position=UDim2.fromOffset(14,10);errorHeading.Size=UDim2.new(1,-58,0,25);errorHeading.ZIndex=11
 local errorScroll=create('ScrollingFrame',errorNotice,{Position=UDim2.fromOffset(14,46),Size=UDim2.new(1,-28,1,-58),BackgroundTransparency=1,BorderSizePixel=0,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),ScrollBarThickness=3,ZIndex=11})
 local errorText=label(errorScroll,'',0,0,13,C.text);errorText.AutomaticSize=Enum.AutomaticSize.Y;errorText.Size=UDim2.new(1,-8,0,0);errorText.TextYAlignment=Enum.TextYAlignment.Top;errorText.ZIndex=11
 local dismissError=button(errorNotice,'×',10,25,false);dismissError.Position=UDim2.new(1,-37,0,10);dismissError.Size=UDim2.fromOffset(25,25);dismissError.ZIndex=11;dismissError.MouseButton1Click:Connect(function()errorNotice.Visible=false end)

 local function show(s,errorState)status.Text=s;status.Visible=busy and not errorState;status.TextColor3=C.muted;errorNotice.Visible=errorState==true;if errorState then errorText.Text=s end;if requestLayout then requestLayout()end end
 local function guard(fn)
  if busy then return end;busy=true;for _,b in interactive do b.Interactable=false end
  local ok,e=pcall(fn);busy=false;status.Visible=false;for _,b in interactive do b.Interactable=true end;refreshAction()
  if not ok then show(tostring(e):gsub('^.-:%d+: ',''),true);warn('[Penpot Bridge] '..tostring(e))end
 end
 refreshTemplates=function()
  local lines={};for key,value in Importer.getTemplates()do table.insert(lines,key..' → '..value.instance:GetFullName())end;table.sort(lines)
  templateMappings.Text=#lines>0 and table.concat(lines,'\n\n')or 'No templates mapped yet.'
 end
 templateButton.MouseButton1Click:Connect(function()guard(function()refreshTemplates();showTab('Templates') end)end)
 mapTemplate.MouseButton1Click:Connect(function()guard(function()
  Importer.mapTemplate(templateKey.Text,Selection:Get()[1]);previewPlan=nil;refreshTemplates();show('Template mapping saved. Review the design before importing refreshed templates.')
 end)end)
 local function checkConnection()
  helperState.Text='Checking the helper on this PC…'
  local ok,value=pcall(function()token=Assets.connect();return Assets.status(token)end)
  if not ok then
   token=nil;connection.Text='○  Helper offline';connection.TextColor3=C.amber
   helperState.Text='Cannot reach the helper. Run Start-Penpot-Bridge.cmd, then check again. If Roblox denied access, check this plugin’s HTTP permission.';helperState.TextColor3=C.amber
   show('Connection failed. Follow the Setup steps.',true);return false
  end
  connection.Text='●  Helper online';connection.TextColor3=C.green
  helperState.Text=value.configured and 'Helper running · image uploads ready. Continue to Design.' or 'Helper running · image uploads need setup at the address below.';helperState.TextColor3=value.configured and C.green or C.amber
  plugin:SetSetting('SetupSeen_v2',true);show(value.configured and 'Connected. In Penpot, prepare and send your design.' or 'Design transfer is ready. Configure image uploads before importing new images.')
  return true
 end
 checkHelper.MouseButton1Click:Connect(function()guard(checkConnection)end)
 local function loadDocument(value)
  local d=type(value)=='string' and Http:JSONDecode(value) or value
  Importer.validate(d);document=d;previewPlan=nil;lastImported=nil;clearVerification()
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
  pendingImages=pending
  reviewSummary.Text='Changes for '..document.design.name;for key,value in metrics do value.Text=tostring(s[key])end
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
  lastImported=imported;clearVerification();verifySummary.Text='Import complete. Click Verify import to check it.'
  Selection:Set({imported});previewPlan=nil;primary.Text='Review import';showTab('Design');show('Imported successfully. Re-export this design to sync changes.');connection.Text=token and '●  Helper online' or '●  Bundle loaded';connection.TextColor3=C.green
  return imported
 end
 local function selectFinding(finding)
  local i=finding and finding.instance
  if i and i.Parent then Selection:Set({i});show('Selected '..i:GetFullName())else show('The object is no longer available. Verify again.',true)end
 end
 local function verifyClick()
  assert(document,'Receive the same design from Penpot or open its bundle before verifying.')
  show('Checking imported objects…');clearVerification()
  local key=document.source.fileId..'/'..document.source.rootId
  local selected=Selection:Get()[1];local auditTarget
  while selected do if selected:GetAttribute('P2R_Design')==key then auditTarget=selected;break end;selected=selected.Parent end
  if not auditTarget then auditTarget=lastImported and lastImported.Parent and lastImported or target end
  local report=Importer.verify(document,auditTarget,table.clone(options));lastVerification=report
  verifySummary.Text=string.format('%d issues · %d warnings · %d notes\n%d checks. Visual review is still needed.',report.errors,report.warnings,report.notes,report.checks)
  verifySummary.TextColor3=report.errors>0 and C.amber or report.warnings>0 and C.amber or C.green
  local colors={error=C.amber,warning=C.amber,note=C.muted}
  for ix,finding in report.issues do
   if ix>150 then break end
   local row=create('Frame',verifyList,{Name='Finding',LayoutOrder=ix,Size=UDim2.new(1,0,0,100),BackgroundColor3=C.card,BorderSizePixel=0});round(row,10)
   local pick=button(row,string.upper(finding.level)..' · '..finding.name,0,44,false);pick.TextColor3=colors[finding.level];pick.TextSize=12
   local detail=label(row,finding.message,52,40,12,C.muted);detail.Name='Finding detail';detail.Size=UDim2.new(1,-24,0,40);detail.Position=UDim2.fromOffset(12,52);detail.TextYAlignment=Enum.TextYAlignment.Top
   pick.MouseButton1Click:Connect(function()selectFinding(finding)end)
  end
  if #report.issues>150 or report.omitted>0 then
   local row=create('Frame',verifyList,{Name='More findings',LayoutOrder=151,Size=UDim2.new(1,0,0,54),BackgroundTransparency=1})
   label(row,'Showing the first 150 findings. Resolve these and verify again for remaining findings.',0,54,12,C.muted)
  end
  showTab('Verify');layoutFindings();show('Verification finished. Click a finding to select its object. Nothing was modified.')
  return report
 end
 verifyButton.MouseButton1Click:Connect(function()guard(verifyClick)end)
 receive.MouseButton1Click:Connect(function()guard(function()
  assert(Assets,'Assets module is missing');show('Connecting to this PC. Allow 127.0.0.1 if Roblox asks.');token=Assets.connect();connection.Text='●  Helper online';connection.TextColor3=C.green
  local response=Http:RequestAsync({Url='http://127.0.0.1:43129/document',Method='GET',Headers={Authorization='Bearer '..token}})
  assert(response.Success,'Send a design from the Penpot companion first.');loadDocument(response.Body)
 end)end)
 open.MouseButton1Click:Connect(function()guard(function()local file=game:GetService('StudioService'):PromptImportFileAsync({'json'});if file then local data=file:GetBinaryContents();assert(#data<=64000000,'Bundle exceeds 64 MB');loadDocument(data)end end)end)
 targetButton.MouseButton1Click:Connect(function()guard(function()local selected=Selection:Get()[1];assert(not selected or selected==game.StarterGui or selected:IsA('ScreenGui')or selected:IsA('GuiObject'),'Select StarterGui, a ScreenGui, or a UI container.');target=selected or game.StarterGui;targetLabel.Text=target:GetFullName();previewPlan=nil end)end)
 local function editJSON()json.Text=document and Http:JSONEncode(document)or '';overlay.Visible=true end
 paste.MouseButton1Click:Connect(editJSON);advanced.MouseButton1Click:Connect(editJSON)
 saveJSON.MouseButton1Click:Connect(function()guard(function()loadDocument(json.Text);overlay.Visible=false end)end)
 primary.MouseButton1Click:Connect(function()guard(function()if currentTab=='Setup' then if checkConnection()then showTab('Design')end elseif currentTab=='Verify'then verifyClick()elseif currentTab=='Review' and previewPlan then applyClick()else previewClick()end end)end)
 -- Reflow actual panel bounds rather than assuming a particular monitor or dock.
 -- Keep strokes inside the scroll viewport; wrapped text grows its own rows.
 local textService=game:GetService('TextService')
 local function textHeight(i,width,minimum)
  if not i:IsA('TextLabel')or not i.TextWrapped or i.Text==''then return minimum end
  local w=math.max(40,width*i.Size.X.Scale+i.Size.X.Offset)
  local bounds=textService:GetTextSize(i.Text,i.TextSize,Enum.Font.BuilderSans,Vector2.new(w,100000))
  return math.max(minimum,math.ceil(bounds.Y*i.LineHeight)+4)
 end
 local function flow(parent,width)
  local rows={}
  for _,i in parent:GetChildren()do
   if i:IsA('GuiObject')and i.Position.Y.Scale==0 then
    local b=flowBase[i];if not b or b.parent~=parent then b={parent=parent,y=i.Position.Y.Offset,h=i.Size.Y.Offset};flowBase[i]=b end
    table.insert(rows,{i=i,b=b})
   end
  end
  table.sort(rows,function(a,b)return a.b.y<b.b.y end)
  local shift,index=0,1
  while index<=#rows do
   local y=rows[index].b.y;local growth=0
   repeat
    local row=rows[index];local i,b=row.i,row.b
    local h=cards[i]and i.Size.Y.Offset or textHeight(i,width,b.h)
    i.Position=UDim2.new(i.Position.X.Scale,i.Position.X.Offset,0,b.y+shift)
    if i:IsA('TextLabel')then i.Size=UDim2.new(i.Size.X.Scale,i.Size.X.Offset,0,h)end
    growth=math.max(growth,h-b.h);index+=1
   until index>#rows or rows[index].b.y~=y
   shift+=growth
  end
  return shift
 end
 local compact=false
 local tooltip=label(root,'',0,30,12,C.text);tooltip.Name='Navigation tooltip';tooltip.BackgroundColor3=C.card;tooltip.Size=UDim2.fromOffset(118,30);tooltip.TextXAlignment=Enum.TextXAlignment.Center;tooltip.Visible=false;tooltip.ZIndex=50;round(tooltip,6);border(tooltip)
 local navLabels={Design={'Import','01'},Review={'Review','02'},Verify={'Verify','03'},Templates={'Templates','T'},Options={'Settings','S'},Setup={'Connection','C'}}
 for name,b in tabs do b.MouseEnter:Connect(function()if compact then tooltip.Text=navLabels[name][1];tooltip.Position=UDim2.fromOffset(64,b.AbsolutePosition.Y-root.AbsolutePosition.Y+3);tooltip.Visible=true end end);b.MouseLeave:Connect(function()tooltip.Visible=false end)end
 local helperDot=create('Frame',sidebar,{Name='Compact connection status',Size=UDim2.fromOffset(6,6),BackgroundColor3=C.muted,BorderSizePixel=0,Visible=false});round(helperDot,3)
 connection:GetPropertyChangedSignal('TextColor3'):Connect(function()helperDot.BackgroundColor3=connection.TextColor3 end)
 local function layout()
  local width,height=root.AbsoluteSize.X,root.AbsoluteSize.Y;if width<=0 or height<=0 then return end
  compact=width<580;local short=height<580;local rail=compact and 56 or 132;local pad=compact and 14 or 22;local content=math.max(100,width-rail-pad*2)
  sidebar.Size=UDim2.new(0,rail,1,0);brand.Visible=not compact;brandSub.Visible=not compact;section.Visible=not compact and not short;section.Size=UDim2.new(1,-24,0,18)
  for index,tile in brandTiles do tile.Position=UDim2.fromOffset(compact and(19+(index-1)*6)or(19+(index-1)*6),(short and 17 or 24)+(index-1)*8)end
  nav.Position=UDim2.fromOffset(8,short and 78 or 112);nav.Size=UDim2.new(1,-16,0,208)
  local positions=short and{Design=0,Review=40,Verify=80,Templates=126,Options=0,Setup=38}or{Design=0,Review=44,Verify=88,Templates=150,Options=0,Setup=44}
  secondaryNav.Position=UDim2.new(0,8,1,short and-126 or-178);secondaryNav.Size=UDim2.new(1,-16,0,82)
  for name,b in tabs do b.Position=UDim2.fromOffset(0,positions[name]);b.Size=UDim2.new(1,0,0,short and 32 or 36);b.Text=navLabels[name][compact and 2 or 1];b.TextXAlignment=compact and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left;local padding=b:FindFirstChildWhichIsA('UIPadding');if padding then padding.PaddingLeft=UDim.new(0,compact and 0 or 12)end end
  connection.Visible=not compact;connection.Position=UDim2.new(0,18,1,short and-48 or-73);connection.Size=UDim2.new(1,-32,0,short and 36 or 46);helperDot.Visible=compact;helperDot.Position=UDim2.new(.5,-3,1,-28)
  header.Position=UDim2.fromOffset(rail+pad,short and 14 or 20);header.Size=UDim2.new(1,-rail-pad*2,0,100)
  title.TextSize=compact and 21 or 23;local titleH=textHeight(title,content,29);title.Size=UDim2.new(1,0,0,titleH)
  subtitle.Position=UDim2.fromOffset(0,24+titleH+7);local subH=textHeight(subtitle,content,28);subtitle.Size=UDim2.new(1,0,0,subH)
  local headerH=subtitle.Position.Y.Offset+subH
  if status.Visible then local sh=math.min(56,textHeight(status,content,22));status.Position=UDim2.fromOffset(0,headerH+8);status.Size=UDim2.new(1,0,0,sh);headerH+=sh+8 end
  header.Size=UDim2.new(1,-rail-pad*2,0,headerH)
  local divider=(short and 14 or 20)+headerH+12;headerLine.Position=UDim2.fromOffset(rail,divider);headerLine.Size=UDim2.new(1,-rail,0,1)
  local top=divider+18;body.Position=UDim2.fromOffset(rail+pad,top);body.Size=UDim2.new(1,-rail-pad*2,1,-top-14)
  local pageWidth=content-14
  for frame,c in cards do frame.Size=UDim2.new(1,0,0,c.height+flow(c.inner,pageWidth-32))end
  for _,p in pages do flow(p,pageWidth)end
  errorNotice.Position=UDim2.new(0,rail+pad+4,1,-194);errorNotice.Size=UDim2.new(1,-rail-pad*2-14,0,180)
  tooltip.Visible=false;layoutFindings()
 end
 local layoutQueued=false
 requestLayout=function()if layoutQueued then return end;layoutQueued=true;task.defer(function()layoutQueued=false;if root.Parent then layout()end end)end
 root:GetPropertyChangedSignal('AbsoluteSize'):Connect(requestLayout)
 widget:GetPropertyChangedSignal('Enabled'):Connect(requestLayout)
 toggle.Click:Connect(function()widget.Enabled=not widget.Enabled end)
 plugin.Unloading:Connect(function()widget:Destroy();toolbar:Destroy()end)
 local function paintAppearance()
  darkButton.Text=theme=='dark'and'Dark ✓'or'Dark';lightButton.Text=theme=='light'and'Light ✓'or'Light'
  for _,paint in switchPainters do paint()end
 end
 setTheme=function(value)
  if not palettes[value]then return end
  local previous=C;local nextPalette=palettes[value]
  for _,i in widget:GetDescendants()do
   local props=i:IsA('UIStroke')and{'Color'}or i:IsA('GuiObject')and{'BackgroundColor3','BorderColor3'}or{}
   if i:IsA('TextLabel')or i:IsA('TextButton')or i:IsA('TextBox')then table.insert(props,'TextColor3')end
   if i:IsA('TextBox')then table.insert(props,'PlaceholderColor3')end
   if i:IsA('ScrollingFrame')then table.insert(props,'ScrollBarImageColor3')end
   for _,prop in props do for key,color in previous do if i[prop]==color then i[prop]=nextPalette[key];break end end end
  end
  C=nextPalette;theme=value;paintAppearance();showTab(currentTab);pcall(function()plugin:SetSetting('BridgeAppearance',value)end)
 end
 paintAppearance()
 local initialTab=plugin:GetSetting('SetupSeen_v2') and 'Design' or 'Setup'
 showTab(initialTab)
 return {setTheme=setTheme,getTheme=function()return theme end,widget=widget,destroy=function()widget:Destroy();toolbar:Destroy()end,loadDocument=loadDocument,checkConnection=checkConnection,preview=function()guard(previewClick)end,verify=function()local report;guard(function()report=verifyClick()end);return report end,getVerification=function()return lastVerification end,selectFinding=function(index)selectFinding(lastVerification and lastVerification.issues[index])end,apply=function()local imported;guard(function()imported=applyClick()end);return imported end,receive=function()token=Assets.connect();return token end,controls={status=status,primary=primary,document=json,helperState=helperState,connection=connection,verify=verifyButton,verifySummary=verifySummary,verifyList=verifyList},navigate=showTab,getCurrentTab=function()return currentTab end,getOptions=function()return table.clone(options)end,getTarget=function()return target end,getDocument=function()return document end}
end
