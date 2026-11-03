return function(plugin,Importer,Assets,presentation)
 local View=require(script.Parent.View)
 local Http=game:GetService('HttpService');local Selection=game:GetService('Selection');local TextService=game:GetService('TextService')
 presentation=presentation or {};local hostMode=presentation.preview and presentation.host~=nil
 local function rgb(r,g,b)return Color3.fromRGB(r,g,b)end
 local palettes={
  dark={bg=rgb(17,18,19),sidebar=rgb(13,14,15),card=rgb(25,27,29),line=rgb(42,45,47),text=rgb(243,245,244),muted=rgb(160,166,163),dim=rgb(116,124,119),accent=rgb(236,239,237),ink=rgb(22,25,23),green=rgb(142,230,161),greenDark=rgb(24,46,32),amber=rgb(239,190,115),button=rgb(35,38,40),hover=rgb(45,49,51),accentHover=rgb(255,255,255),selected=rgb(35,38,40),disabled=rgb(37,40,42),toggle=rgb(58,63,60),thumb=rgb(190,196,192)},
  light={bg=rgb(247,248,247),sidebar=rgb(238,241,239),card=rgb(255,255,255),line=rgb(213,220,216),text=rgb(27,34,29),muted=rgb(89,102,94),dim=rgb(111,124,116),accent=rgb(35,47,39),ink=rgb(248,251,249),green=rgb(26,121,62),greenDark=rgb(220,240,226),amber=rgb(143,88,17),button=rgb(232,237,234),hover=rgb(218,226,221),accentHover=rgb(51,67,56),selected=rgb(222,230,225),disabled=rgb(231,235,232),toggle=rgb(196,205,199),thumb=rgb(255,255,255)}
 }

 local theme='dark';pcall(function()if plugin:GetSetting('BridgeAppearance')=='light'then theme='light'end end);local C=palettes[theme]
 local toolbar,toggle,widget
 if presentation.preview then local event=Instance.new('BindableEvent');toolbar={Destroy=function()event:Destroy()end};toggle={Click=event.Event}
 else toolbar=plugin:CreateToolbar('Penpot Bridge');toggle=toolbar:CreateButton('Penpot Bridge','Open Penpot Bridge','','Penpot Bridge')end
 if hostMode then widget=presentation.host else
  widget=plugin:CreateDockWidgetPluginGuiAsync(presentation.preview and'PenpotBridge.SourcePreview.'..tostring(presentation.width or 626)or'PenpotRobloxImporter.v2',DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float,false,false,presentation.width or 626,presentation.height or 860,626,502));widget.Title=presentation.preview and'Penpot Bridge · Preview'or'Penpot Bridge'
 end
 local backdrop=Instance.new('Frame');backdrop.Name='Desktop backdrop';backdrop.Size=UDim2.fromScale(1,1);backdrop.BorderSizePixel=0;backdrop.BackgroundColor3=C.sidebar;backdrop.Parent=widget
 local model=View.create(widget,C);local root,body,pages=model.root,model.body,model.pages
 local function get(scene,name,index)return model:get(scene,name,index)end
 local function style(i,props)model:style(i,props)end
 local function create(class,parent,props)local i=Instance.new(class);for k,v in props or{}do i[k]=v end;i.Parent=parent;return i end
 local function order(i,n)i.LayoutOrder=n;return i end
 local function round(i,r)create('UICorner',i,{CornerRadius=UDim.new(0,r or 8)})end
 local function border(i,role)local s=create('UIStroke',i,{Thickness=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border});style(s,{Color=role or'line'});return s end
 local function paragraph(parent,value,size,role,weight)
  local prototype=get('Design',size and size>=18 and'Page title'or size and size>=13 and'Option / Hide removed layers'or'Source hint')
  local nominal=size and size>=18 and 25 or size and size>=13 and 13 or 11
  local i=model:clone(prototype,parent);i.Name=value;i.LayoutOrder=0;i.ZIndex=2;i.Position=UDim2.new();i.Size=UDim2.new(1,0,0,0);i.AutomaticSize=Enum.AutomaticSize.Y;i.Text=value;i.TextSize=math.round(prototype.TextSize*(size or 12)/nominal);i.TextWrapped=true;i.TextTruncate=Enum.TextTruncate.None;i.TextYAlignment=Enum.TextYAlignment.Top;style(i,{TextColor3=role or'text'});return i
 end
 local function label(parent,value,y,h,size,color)local i=paragraph(parent,value,size,'muted');i.AutomaticSize=Enum.AutomaticSize.None;i.Position=UDim2.fromOffset(0,y);i.Size=UDim2.new(1,0,0,h);if color then i.TextColor3=color end;return i end
 local function stack(parent,name,gap,padding)
  local f=create('Frame',parent,{Name=name,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1})
  create('UIListLayout',f,{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,gap or 12)})
  if padding then create('UIPadding',f,{PaddingTop=UDim.new(0,padding),PaddingBottom=UDim.new(0,padding),PaddingLeft=UDim.new(0,padding),PaddingRight=UDim.new(0,padding)})end;return f
 end
 local function card(parent,name,padding,gap)
  local f=model:clone(get('Design','Design source'),parent);f.Name='Card';f.LayoutOrder=0;f.ZIndex=1;f.Position=UDim2.new();f.Size=UDim2.new(1,0,0,0);f.AutomaticSize=Enum.AutomaticSize.Y
  create('UIListLayout',f,{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,gap or 8)});local pad=padding or 16;create('UIPadding',f,{PaddingTop=UDim.new(0,pad),PaddingBottom=UDim.new(0,pad),PaddingLeft=UDim.new(0,pad),PaddingRight=UDim.new(0,pad)});return f
 end
 local interactive=setmetatable({},{__mode='k'});local genericButtons=setmetatable({},{__mode='k'});local layoutHooks={}
 local function register(b)interactive[b]=true;return b end
 local function button(parent,value,y,h,primary)
  local b=create('TextButton',parent,{Name=value,Text=value,TextTransparency=1,AutoButtonColor=false,BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(0,y or 0),Size=UDim2.new(1,0,0,h or 38),ZIndex=10000})
  local box=model:clone(get('Design',primary and'Button / Receive from Penpot'or'Button / Open JSON bundle'),b);box.Position=UDim2.new();box.Size=UDim2.fromScale(1,1)
  local text=model:clone(get('Design','Label / Open JSON bundle'),b);text.Position=UDim2.fromOffset(8,0);text.Size=UDim2.new(1,-16,1,0);text.Text=value;text.TextWrapped=true
  local function paint()style(box,{BackgroundColor3=not b.Interactable and'disabled'or primary and'accent'or'button'});style(text,{TextColor3=not b.Interactable and'dim'or primary and'ink'or'text'})end
  b:GetPropertyChangedSignal('Text'):Connect(function()text.Text=b.Text end);b:GetPropertyChangedSignal('Interactable'):Connect(paint);genericButtons[b]={paint=paint,label=text,box=box};register(b);paint();return b
 end
 local options={responsive=false,hideRemoved=false,force=false,allowClassChanges=false,nativeGrids=false,generateRefs=false}
 local previewPlan,document,token,target=nil,nil,nil,game.StarterGui
 local lastImported,lastVerification,primary,refreshTemplates;local pendingImages=0;local busy=false;local currentTab='Design';local destroyed=false
 local showTab,refreshAction,requestLayout,setTheme,verifyClick,previewClick,applyClick;local controls={}
 local function customPage(name,title,sub)
  local p=stack(body,name,18);p.Position=UDim2.fromOffset(24,29);p.Size=UDim2.new(0,440,0,0);p.Visible=false;pages[name]=p;model.named[name]={}
  order(paragraph(p,title,25,'text','bold'),-2);order(paragraph(p,sub,12,'muted'),-1);return p
 end
 local importPage=pages.Design;local progressPage=pages.Progress;local completePage=pages.Complete
 local reviewPage=customPage('Review','Review your import','Check the changes before they reach your place.')
 local verifyPage=customPage('Verify','Verify your import','Compare imported objects with the received design.')
 local settingsPage=customPage('Options','Preferences','Choose your appearance and import behavior.')
 local setupPage=customPage('Setup','Connect your tools','The local helper links Penpot and this Studio session.')
 local templateOverlay=customPage('Templates','Reusable templates','Map Penpot layers to your own Studio components.')
 local sourceTitle=get('Design','Source title');local sourceMeta=get('Design','Source hint');sourceTitle.TextWrapped=false;sourceTitle.TextTruncate=Enum.TextTruncate.AtEnd
 local receive=register(model:button('Design','Receive from Penpot',true));local open=register(model:button('Design','Open JSON bundle'));local paste=register(model:button('Design','Paste JSON'));local targetButton=register(model:button('Design','Use selection'));local targetLabel=get('Design','Destination value');targetLabel.TextWrapped=false;targetLabel.TextTruncate=Enum.TextTruncate.AtEnd
 local advanced=register(model:hit(importPage,'Advanced JSON & mappings',get('Design','Advanced settings')))
 local hint=get('Design','Review prerequisite');local designPrimary=register(model:button('Design','Review import',true));primary=designPrimary
 local sourceRowTop={};local optionDefinitions={{'hideRemoved','Hide removed layers'},{'nativeGrids','Native uniform grids'},{'generateRefs','Gameplay references'},{'force','Use design values'},{'allowClassChanges','Allow object replacement'}}
 local switchPainters={};local optionControls={}
 local function bindToggle(parent,track,thumb,key)
  local b=register(model:hit(parent,'Toggle '..key,track));local original=thumb.Position
  local function paint()style(track,{BackgroundColor3=options[key]and'accent'or'toggle'});style(thumb,{BackgroundColor3=options[key]and'ink'or'thumb'});thumb.Position=original+UDim2.fromOffset(options[key]and 14 or 0,0)end
  b.MouseButton1Click:Connect(function()if busy then return end;options[key]=not options[key];previewPlan=nil;for _,fn in switchPainters do fn()end;refreshAction()end);table.insert(switchPainters,paint);optionControls[key]=optionControls[key]or{};table.insert(optionControls[key],b);paint();return b
 end
 local tracks=model:list('Design','Toggle / Off');local thumbs=model:list('Design','Toggle thumb')
 for i,d in optionDefinitions do bindToggle(importPage,tracks[i],thumbs[i],d[1])end
 local setupIntro=order(card(setupPage,'Helper instructions'),1);order(paragraph(setupIntro,'One local helper. Two connected tools.',16,'text'),1);order(paragraph(setupIntro,'Start the helper on this computer, then prepare and send a selection from the Penpot companion. Your finished game works without the helper.',12,'muted'),2)
 local setupSteps=order(card(setupPage,'Setup steps'),2);paragraph(setupSteps,'1. Extract the helper ZIP and run Start-Penpot-Bridge.cmd.\n\n2. Allow 127.0.0.1 if Studio asks. That address is your own computer.\n\n3. Prepare a selection in Penpot and send it to Studio.',12,'muted')
 local checkHelper=order(button(setupPage,'Check local connection',0,40,true),3);local helperState=order(paragraph(setupPage,'Not checked yet. Start the helper, then check the connection.',12,'muted'),4)
 local function urlField(parent,name,value)local b=create('TextBox',parent,{Name=name,Text=value,TextEditable=false,ClearTextOnFocus=false,TextWrapped=true,FontFace=Font.fromEnum(Enum.Font.RobotoMono),TextSize=12,Size=UDim2.new(1,0,0,58),BorderSizePixel=0});style(b,{BackgroundColor3='card',TextColor3='text'});round(b,8);border(b);create('UIPadding',b,{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12)});return b end
 order(paragraph(setupPage,'HELPER STATUS & OPTIONAL IMAGE UPLOADS',10,'dim'),5);local helperURL=order(urlField(setupPage,'Helper address','http://127.0.0.1:43129/setup'),6)
 order(paragraph(setupPage,'The helper is required for the local connection. A Roblox upload key is optional until you need new image uploads.',12,'muted'),7)
 local downloadURL=order(urlField(setupPage,'Public helper download','https://github.com/deyyzy-glitch/penpot-roblox-bridge/releases/latest'),8)
 local reviewSummary=order(paragraph(reviewPage,'No changes reviewed yet',18,'text'),1)
 local reviewCounts=create('Frame',reviewPage,{Name='Change counts',LayoutOrder=2,Size=UDim2.new(1,0,0,91),BackgroundTransparency=1});local metrics={}
 for i,d in {{'added','New'},{'updated','Changed'},{'unchanged','Same'},{'removed','Removed'}}do
  local box=model:clone(get('Complete','Metric / Created'),reviewCounts);box.Position=UDim2.new((i-1)/4,0,0,0);box.Size=UDim2.new(.25,-6,0,91)
  local v=model:clone(get('Complete','Metric value / Created'),box);v.Position=UDim2.fromOffset(6,10);v.Size=UDim2.new(1,-12,0,37);v.Text='—';v.TextXAlignment=Enum.TextXAlignment.Center;metrics[d[1]]=v
  local caption=model:clone(get('Complete','Metric label / Created'),box);caption.Position=UDim2.fromOffset(4,55);caption.Size=UDim2.new(1,-8,0,22);caption.Text=d[2];caption.TextXAlignment=Enum.TextXAlignment.Center
 end
 local reviewPrimary=order(button(reviewPage,'Import design',0,42,true),3);local primaryByPage={Design=designPrimary,Review=reviewPrimary}
 order(paragraph(reviewPage,'CONVERSION DETAILS',10,'dim'),4);local changeList=order(paragraph(reviewPage,'Receive a design and choose Review import to see what will change.',13,'muted'),5);changeList.LineHeight=1.25
 local verifyIntro=order(card(verifyPage,'Verification explanation'),1);order(paragraph(verifyIntro,'Check the imported result',16,'text'),1);order(paragraph(verifyIntro,'Checks objects, fonts, images and layout against the received design. Select an imported container if this place has several copies. Verification changes nothing; visual review is still useful.',12,'muted'),2)
 local verifyButton=order(button(verifyPage,'Verify import',0,40,true),2);local verifySummary=order(paragraph(verifyPage,'Receive a design to check its imported objects.',14,'muted'),3);local verifyList=order(stack(verifyPage,'Verification findings',10),4)
 local function layoutFindings()if requestLayout then requestLayout()end end
 local function clearVerification()for _,i in verifyList:GetChildren()do if i:IsA('GuiObject')then i:Destroy()end end;lastVerification=nil;verifySummary.Text=document and'Ready to check the matching imported design.'or'Receive a design to check its imported objects.';style(verifySummary,{TextColor3='muted'});layoutHooks={}end
 local appearance=order(card(settingsPage,'Appearance'),1);order(paragraph(appearance,'Appearance',16,'text'),1);order(paragraph(appearance,'Choose the background you prefer.',12,'muted'),2)
 local appearanceRow=create('Frame',appearance,{Name='Appearance choices',LayoutOrder=3,BackgroundTransparency=1,Size=UDim2.new(1,0,0,38)})
 local darkButton=button(appearanceRow,'Dark',0,38,false);darkButton.Size=UDim2.new(.5,-5,0,38);local lightButton=button(appearanceRow,'Light',0,38,false);lightButton.Position=UDim2.new(.5,5,0,0);lightButton.Size=UDim2.new(.5,-5,0,38)
 darkButton.MouseButton1Click:Connect(function()if not busy then setTheme('dark')end end);lightButton.MouseButton1Click:Connect(function()if not busy then setTheme('light')end end)
 order(paragraph(settingsPage,'SYNC & EDITABILITY',10,'dim'),2);local settingsRows=order(stack(settingsPage,'Import preferences',0),3)
 for index,d in optionDefinitions do
  local title=get('Design','Option / '..d[2]);local top=title.Position.Y.Offset-1;local row=create('Frame',settingsRows,{Name=d[1],LayoutOrder=index,Size=UDim2.new(1,0,0,54),BackgroundTransparency=1});local track,thumb
  for _,item in importPage:GetChildren()do if item:IsA('GuiObject')and item.Position.Y.Offset>=top and item.Position.Y.Offset<top+54 and not item:IsA('GuiButton')then local c=model:clone(item,row);c.Position-=UDim2.fromOffset(24,top);if c.Name=='Toggle / Off'then track=c elseif c.Name=='Toggle thumb'then thumb=c end end end
  assert(track and thumb,'Missing imported settings row');bindToggle(row,track,thumb,d[1])
 end
 local settingsAdvanced=order(button(settingsPage,'Advanced JSON & mappings',0,42,false),4);local templateButton=order(button(settingsPage,'Manage reusable templates',0,42,false),5)
 local templateModal=order(card(templateOverlay,'Template mapping'),1);order(paragraph(templateModal,'Map a Studio component',16,'text'),1);order(paragraph(templateModal,'Select a UI object in Explorer, give it a key, then use that key on a Reusable template layer in Penpot.',12,'muted'),2)
 local templateKey=create('TextBox',templateModal,{Name='Template key',LayoutOrder=3,ZIndex=2,Size=UDim2.new(1,0,0,38),BorderSizePixel=0,Text='',PlaceholderText='Template key, e.g. PrimaryButton',ClearTextOnFocus=false,FontFace=get('Design','Source hint').FontFace,TextSize=get('Design','Source hint').TextSize});style(templateKey,{BackgroundColor3='sidebar',TextColor3='text',PlaceholderColor3='dim'});round(templateKey,7);border(templateKey);register(templateKey)
 local mapTemplate=order(button(templateModal,'Map selected component',0,40,true),4);order(paragraph(templateOverlay,'Clones retain your component’s appearance, children and scripts. Map again after editing a template; refreshing existing clones requires reviewed replacement.',12,'muted'),2);order(paragraph(templateOverlay,'MAPPED IN THIS PLACE',10,'dim'),3);local templateMappings=order(paragraph(templateOverlay,'No templates mapped yet.',13,'text'),4)
 local progressDesign=get('Progress','Design name');local progressTarget=get('Progress','Design destination');progressDesign.TextWrapped=false;progressDesign.TextTruncate=Enum.TextTruncate.AtEnd
 local progressCaption=get('Progress','Progress description');local progressValue=get('Progress','Progress value');local progressFill=get('Progress','Progress fill');local progressQuality=get('Progress','Summary values')
 local stepNames={'Validating design','Preparing images','Building native UI','Finalizing import'};local stepDetails=model:list('Progress','Step detail');local badges={};for _,name in {'Completed step','Step / active','Step / pending'}do for _,i in model:list('Progress',name)do table.insert(badges,i)end end;table.sort(badges,function(a,b)return a.Position.Y.Offset<b.Position.Y.Offset end)
 local progressTicks=model:list('Progress','Icon / check');local activeDots={get('Progress','Active step center')}
 for i=3,4 do progressTicks[i]=model:clone(progressTicks[1],progressPage);progressTicks[i].Position=progressTicks[1].Position+UDim2.fromOffset(0,(i-1)*73)end
 for i=2,4 do activeDots[i]=model:clone(activeDots[1],progressPage)end
 local successDescription=get('Complete','Success description');successDescription.TextWrapped=false;successDescription.TextTruncate=Enum.TextTruncate.AtEnd
 local resultMetrics={added=get('Complete','Metric value / Created'),updated=get('Complete','Metric value / Updated'),images=get('Complete','Metric value / Image surfaces'),conflicts=get('Complete','Metric value / Local edits kept')};get('Complete','Metric label / Local edits kept').Text='Local properties kept'
 local successDetailLabels=model:list('Complete','Summary detail');local successTitles={get('Complete','Summary / Editable UI created'),get('Complete','Summary / Images assigned'),get('Complete','Summary / Local edits preserved')}
 local backToImport=register(model:button('Complete','Back to import'));local completeVerify=register(model:button('Complete','Verify import',true))
 local connection=get('Shared','Connection status');local helperDot=get('Shared','Connected indicator');local connectionButton=register(model:hit(root,'Connection',get('Shared','Connection label')));connectionButton.Position=UDim2.new(0,10,1,-87);connectionButton.Size=UDim2.fromOffset(116,64)
 local tabs={};local activeNav=get('Shared','Active navigation');local marker=get('Shared','Active marker');local navNames={Design='Import',Review='Review',Verify='Verify',Templates='Templates',Options='Settings'}
 for name,value in navNames do local caption=get('Shared','Navigation / '..value);local b=register(model:hit(root,name,caption));b.Position=UDim2.fromOffset(10,caption.Position.Y.Offset-4);b.Size=UDim2.fromOffset(116,38);tabs[name]=b;b.MouseButton1Click:Connect(function()if not busy then showTab(name)end end)end
 tabs.Setup=connectionButton;connectionButton.MouseButton1Click:Connect(function()if not busy then showTab('Setup')end end)
 local overlay=create('Frame',root,{Name='Advanced',Size=UDim2.fromScale(1,1),Visible=false,BorderSizePixel=0,ZIndex=20000});style(overlay,{BackgroundColor3='bg'})
 local modal=create('Frame',overlay,{Name='JSON editor',Position=UDim2.fromOffset(24,24),Size=UDim2.new(1,-48,1,-48),BackgroundTransparency=1})
 local modalTitle=label(modal,'Advanced JSON',0,34,20,C.text)
 local json=create('TextBox',modal,{Name='JSON',Position=UDim2.fromOffset(0,48),Size=UDim2.new(1,0,1,-116),BorderSizePixel=0,FontFace=Font.fromEnum(Enum.Font.RobotoMono),TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,MultiLine=true,ClearTextOnFocus=false,TextWrapped=true,Text=''});style(json,{BackgroundColor3='card',TextColor3='text'});round(json,8)
 local saveJSON=button(modal,'Use this JSON',0,42,true);saveJSON.Position=UDim2.new(0,0,1,-44);local close=button(modal,'×',0,32,false);close.Position=UDim2.new(1,-34,0,0);close.Size=UDim2.fromOffset(34,32);close.MouseButton1Click:Connect(function()overlay.Visible=false end)
 local errorNotice=create('Frame',root,{Name='Error details',Position=UDim2.new(0,160,1,-194),Size=UDim2.new(0,440,0,180),Visible=false,BorderSizePixel=0,ZIndex=30000});style(errorNotice,{BackgroundColor3='card'});round(errorNotice,8);border(errorNotice)
 local errorTitle=label(errorNotice,'Something needs attention',10,26,13,C.amber);errorTitle.Position=UDim2.fromOffset(14,10);errorTitle.Size=UDim2.new(1,-64,0,26)
 local errorScroll=create('ScrollingFrame',errorNotice,{Position=UDim2.fromOffset(14,43),Size=UDim2.new(1,-28,1,-55),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new()});style(errorScroll,{ScrollBarImageColor3='line'});local errorText=paragraph(errorScroll,'',13,'text');errorText.Size=UDim2.new(1,-8,0,0)
 local dismissError=button(errorNotice,'×',10,28,false);dismissError.Position=UDim2.new(1,-36,0,9);dismissError.Size=UDim2.fromOffset(28,28);dismissError.MouseButton1Click:Connect(function()errorNotice.Visible=false end)
 for _,i in overlay:GetDescendants()do if i:IsA('GuiObject')then i.ZIndex=20001 end end;for _,i in errorNotice:GetDescendants()do if i:IsA('GuiObject')then i.ZIndex=30001 end end
 local status=paragraph(root,'',12,'muted');status.Name='Progress';status.Visible=false
 local function setConnection(value,role)connection.Text=value;style(connection,{TextColor3=role});style(helperDot,{BackgroundColor3=role})end
 setConnection('Not checked','dim')
 local function show(value,errorState)status.Text=value;errorNotice.Visible=errorState==true;if errorState then errorText.Text=value end;if requestLayout then requestLayout()end end
 refreshAction=function()
  primary=primaryByPage[currentTab]or designPrimary;controls.primary=primary
  designPrimary.Interactable=not busy and document~=nil;reviewPrimary.Interactable=not busy and previewPlan~=nil
  reviewPrimary.Text=previewPlan and(pendingImages>0 and'Upload images & import'or'Import design')or'Review the design first'
  local active=(currentTab=='Progress'or currentTab=='Complete')and'Design'or currentTab
  for name,label in navNames do local caption=get('Shared','Navigation / '..label);style(caption,{TextColor3=name==active and'text'or'muted'})end
  if navNames[active]then local y=get('Shared','Navigation / '..navNames[active]).Position.Y.Offset-4;activeNav.Position=UDim2.fromOffset(10,y);marker.Position=UDim2.fromOffset(10,y+10);activeNav.Visible=true;marker.Visible=true else activeNav.Visible=false;marker.Visible=false end
  if requestLayout then requestLayout()end
 end
 showTab=function(name)assert(pages[name],'Unknown page');currentTab=name;model:show(name);if name=='Templates'and refreshTemplates then refreshTemplates()end;refreshAction()end
 local function setProgress(step,fraction,detail)
  if currentTab~='Progress'then showTab('Progress')end
  progressCaption.Text=stepNames[step];progressValue.Text=fraction and string.format('%d%%',math.floor(fraction*100+.5))or'';progressFill.Size=UDim2.fromOffset(440*math.clamp(fraction or 0,0,1),progressFill.Size.Y.Offset)
  for i=1,4 do local done=i<step;local active=i==step;badges[i].BackgroundTransparency=done and 0 or 1;style(badges[i],{BackgroundColor3='green'});local stroke=badges[i]:FindFirstChildWhichIsA('UIStroke')or border(badges[i]);style(stroke,{Color=done and'green'or active and'accent'or'line'});progressTicks[i].Visible=done;activeDots[i].Visible=active;activeDots[i].Position=badges[i].Position+UDim2.fromOffset(6,6);local caption=get('Progress','Step / '..stepNames[i]);style(caption,{TextColor3=i<=step and'text'or'dim'});stepDetails[i].Text=active and(detail or stepNames[i])or done and'Completed.'or'Pending';style(stepDetails[i],{TextColor3=i<=step and'muted'or'dim'})end
 end
 local function showCompletion(plan)
  local s,q=plan.stats,plan.quality;successDescription.Text=plan.document.design.name..' is ready in '..target.Name..'.'
  for key,i in resultMetrics do i.Text=tostring(key=='images'and q.images or s[key]or 0)end
  successTitles[1].Text='Editable UI imported';successDetailLabels[1].Text=string.format('%d created · %d updated · %d unchanged.',s.added,s.updated,s.unchanged)
  successTitles[2].Text=q.images>0 and'Images assigned'or'No image surfaces needed';successDetailLabels[2].Text=q.images>0 and string.format('%d image surfaces linked.',q.images)or'This import uses native editable UI.'
  successTitles[3].Text=s.conflicts>0 and'Local edits preserved'or'Import settings applied';successDetailLabels[3].Text=s.conflicts>0 and string.format('%d local property overrides retained.',s.conflicts)or'Your reviewed options were applied.';showTab('Complete')
 end
 local function guard(fn)
  if busy then return end;busy=true;for b in interactive do if b.Parent then b.Interactable=false end end
  local ok,e=pcall(fn);busy=false;status.Visible=false;for b in interactive do if b.Parent then b.Interactable=true end end;refreshAction();for _,paint in switchPainters do paint()end
  if not ok then if currentTab=='Progress'then showTab(previewPlan and'Review'or'Design')end;show(tostring(e):gsub('^.-:%d+: ',''),true);warn('[Penpot Bridge] '..tostring(e))end
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
   token=nil;setConnection('Offline','amber')
   helperState.Text='Cannot reach the helper. Run Start-Penpot-Bridge.cmd, then check again. If Roblox denied access, check this plugin’s HTTP permission.';style(helperState,{TextColor3='amber'})
   show('Connection failed. Follow the Setup steps.',true);return false
  end
  setConnection('Connected','green')
  helperState.Text=value.configured and 'Helper running · image uploads ready. Continue to Import.' or 'Helper running · image uploads need setup at the address below.';style(helperState,{TextColor3=value.configured and'green'or'amber'})
  plugin:SetSetting('SetupSeen_v2',true);show(value.configured and 'Connected. In Penpot, prepare and send your design.' or 'Design transfer is ready. Configure image uploads only when you need new image assets.')
  return true
 end
 checkHelper.MouseButton1Click:Connect(function()guard(checkConnection)end)
 local function loadDocument(value)
  local d=type(value)=='string' and Http:JSONDecode(value) or value
  Importer.validate(d);document=d;previewPlan=nil;lastImported=nil;clearVerification()
  if Assets then Assets.pending(d,plugin,Importer)end
  local count=0;local function walk(n)count+=1;for _,c in ipairs(n.children)do walk(c)end end;walk(d.design)
  sourceTitle.Text=d.design.name;sourceMeta.Text=string.format('%d elements  ·  %d image surfaces\n%d × %d design pixels',count,#(d.assets or {}),d.design.width,d.design.height)
  hint.Text='Reimport the same selection to sync changes. Local edits are preserved unless you choose otherwise.';show('Design received. Ready to review.');showTab('Design');primary.Text='Review import'
 end
 previewClick=function()
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
 applyClick=function()
  assert(document and previewPlan,'Review the import first.')
  progressDesign.Text=document.design.name;progressTarget.Text='Penpot selection / '..target:GetFullName()
  local q=previewPlan.quality;progressQuality.Text=string.format('%d native layers · %d image surfaces',q.native,q.images)
  setProgress(1,nil,'Checking the source and your reviewed changes.');task.wait()
  local latest=Importer.prepare(document,target,table.clone(options));for k,v in latest.stats do assert(v==previewPlan.stats[k],'The scene changed. Review the import again.')end
  setProgress(2,nil,pendingImages>0 and'Resolving image assets for this import.'or'No new uploads needed.');task.wait()
  if Assets then Assets.upload(document,plugin,token,function(index,total,name)
   setProgress(2,total>0 and(index-1)/total or nil,string.format('Image %d of %d: %s',index,total,name))
  end,Importer)end
  latest=Importer.prepare(document,target,table.clone(options));setProgress(3,0,'Creating frames, text and controls.');task.wait()
  local imported=Importer.apply(latest,function(done,total)setProgress(3,total>0 and done/total or nil,string.format('%d of %d objects processed.',done,total))end)
  setProgress(4,nil,'Finishing the Studio undo operation.');task.wait()
  lastImported=imported;clearVerification();verifySummary.Text='Import complete. Click Verify import to check it.'
  Selection:Set({imported});previewPlan=nil;showCompletion(latest);show('Imported successfully. Re-export this design to sync changes.');setConnection(token and'Connected'or'Bundle loaded','green')
  return imported
 end
 local function selectFinding(finding)
  local i=finding and finding.instance
  if i and i.Parent then Selection:Set({i});show('Selected '..i:GetFullName())else show('The object is no longer available. Verify again.',true)end
 end
 verifyClick=function()
  assert(document,'Receive the same design from Penpot or open its bundle before verifying.')
  show('Checking imported objects…');clearVerification()
  local key=document.source.fileId..'/'..document.source.rootId
  local selected=Selection:Get()[1];local auditTarget
  while selected do if selected:GetAttribute('P2R_Design')==key then auditTarget=selected;break end;selected=selected.Parent end
  if not auditTarget then auditTarget=lastImported and lastImported.Parent and lastImported or target end
  local report=Importer.verify(document,auditTarget,table.clone(options));lastVerification=report
  verifySummary.Text=string.format('%d issues · %d warnings · %d notes\n%d checks. Visual review is still needed.',report.errors,report.warnings,report.notes,report.checks)
  style(verifySummary,{TextColor3=(report.errors>0 or report.warnings>0)and'amber'or'green'})
  local colors={error=C.amber,warning=C.amber,note=C.muted}
  for ix,finding in report.issues do
   if ix>150 then break end
   local row=card(verifyList,'Finding',12,8);row.LayoutOrder=ix
   local pick=order(button(row,string.upper(finding.level)..' · '..finding.name,0,44,false),1);pick.Name='Finding title';style(pick,{TextColor3=finding.level=='note'and'muted'or'amber'})
   local detail=order(paragraph(row,finding.message,12,'muted'),2);detail.Name='Finding detail'
   table.insert(layoutHooks,function(width)if pick.Parent then pick.Size=UDim2.new(1,0,0,math.max(44,TextService:GetTextSize(pick.Text,genericButtons[pick].label.TextSize,Enum.Font.BuilderSans,Vector2.new(math.max(40,width-40),100000)).Y+12))end end)
   pick.MouseButton1Click:Connect(function()selectFinding(finding)end)
  end
  if #report.issues>150 or report.omitted>0 then
   order(paragraph(verifyList,'Showing the first 150 findings. Resolve these and verify again for remaining findings.',12,'muted'),151)
  end
  showTab('Verify');layoutFindings();show('Verification finished. Click a finding to select its object. Nothing was modified.')
  return report
 end
 verifyButton.MouseButton1Click:Connect(function()guard(verifyClick)end)
 receive.MouseButton1Click:Connect(function()guard(function()
  assert(Assets,'Assets module is missing');show('Connecting to this PC. Allow 127.0.0.1 if Roblox asks.');token=Assets.connect();setConnection('Connected','green')
  local response=Http:RequestAsync({Url='http://127.0.0.1:43129/document',Method='GET',Headers={Authorization='Bearer '..token}})
  assert(response.Success,'Send a design from the Penpot companion first.');loadDocument(response.Body)
 end)end)
 open.MouseButton1Click:Connect(function()guard(function()local file=game:GetService('StudioService'):PromptImportFileAsync({'json'});if file then local data=file:GetBinaryContents();assert(#data<=64000000,'Bundle exceeds 64 MB');loadDocument(data)end end)end)
 targetButton.MouseButton1Click:Connect(function()guard(function()local selected=Selection:Get()[1];assert(not selected or selected==game.StarterGui or selected:IsA('ScreenGui')or selected:IsA('GuiObject'),'Select StarterGui, a ScreenGui, or a UI container.');target=selected or game.StarterGui;targetLabel.Text=target:GetFullName();previewPlan=nil end)end)
 local function editJSON()json.Text=document and Http:JSONEncode(document)or '';overlay.Visible=true end
 paste.MouseButton1Click:Connect(editJSON);advanced.MouseButton1Click:Connect(editJSON)
 saveJSON.MouseButton1Click:Connect(function()guard(function()loadDocument(json.Text);overlay.Visible=false end)end)
 for _,action in primaryByPage do action.MouseButton1Click:Connect(function()guard(function()if currentTab=='Review'and previewPlan then applyClick()else previewClick()end end)end)end


 settingsAdvanced.MouseButton1Click:Connect(function()if not busy then json.Text=document and Http:JSONEncode(document)or'';overlay.Visible=true end end)
 backToImport.MouseButton1Click:Connect(function()if not busy then showTab('Design')end end)
 completeVerify.MouseButton1Click:Connect(function()guard(verifyClick)end)
 local customNames={Review=true,Verify=true,Options=true,Setup=true,Templates=true}
 local function layout()
  if destroyed or not root.Parent then return end
  model:layout();backdrop.BackgroundColor3=C.sidebar
  if customNames[currentTab]then body.CanvasSize=UDim2.fromOffset(488,math.ceil(pages[currentTab].Position.Y.Offset+pages[currentTab].AbsoluteSize.Y+24))else body.CanvasSize=UDim2.fromOffset(488,820)end
  for _,hook in layoutHooks do hook(440)end
 end
 local queued=false
 requestLayout=function()if queued or destroyed then return end;queued=true;task.defer(function()queued=false;layout()end)end
 root:GetPropertyChangedSignal('AbsoluteSize'):Connect(requestLayout)
 for name in customNames do pages[name]:GetPropertyChangedSignal('AbsoluteSize'):Connect(requestLayout)end
 local function paintAppearance()
  darkButton.Text=theme=='dark'and'Dark ✓'or'Dark';lightButton.Text=theme=='light'and'Light ✓'or'Light';for _,paint in switchPainters do paint()end
 end
 setTheme=function(value)
  if not palettes[value]then return end;C=palettes[value];theme=value;model:theme(C)
  for b,data in genericButtons do if b.Parent then data.paint()end end;paintAppearance();refreshAction();pcall(function()plugin:SetSetting('BridgeAppearance',value)end)
 end
 local function destroy()if destroyed then return end;destroyed=true;model:destroy();backdrop:Destroy();toolbar:Destroy();if not hostMode then widget:Destroy()end end
 toggle.Click:Connect(function()if hostMode then root.Visible=not root.Visible else widget.Enabled=not widget.Enabled end end)
 plugin.Unloading:Connect(destroy)
 paintAppearance();showTab(plugin:GetSetting('SetupSeen_v2')and'Design'or'Setup')
 controls.status=status;controls.primary=primary;controls.document=json;controls.helperState=helperState;controls.connection=connection;controls.verify=verifyButton;controls.verifySummary=verifySummary;controls.verifyList=verifyList;controls.receive=receive;controls.open=open;controls.paste=paste;controls.target=targetButton;controls.advanced=advanced;controls.dark=darkButton;controls.light=lightButton;controls.completeVerify=completeVerify;controls.backToImport=backToImport;controls.progressFill=progressFill;controls.progressValue=progressValue;controls.progressCaption=progressCaption;controls.results=resultMetrics;controls.optionButtons=optionControls
 return {setTheme=setTheme,getTheme=function()return theme end,widget=widget,root=root,destroy=destroy,loadDocument=loadDocument,checkConnection=checkConnection,
  preview=function()guard(previewClick)end,verify=function()local report;guard(function()report=verifyClick()end);return report end,getVerification=function()return lastVerification end,selectFinding=function(index)selectFinding(lastVerification and lastVerification.issues[index])end,
  apply=function()local imported;guard(function()imported=applyClick()end);return imported end,receive=function()token=Assets.connect();return token end,
  controls=controls,navigate=showTab,getCurrentTab=function()return currentTab end,getOptions=function()return table.clone(options)end,getTarget=function()return target end,getDocument=function()return document end}
end
