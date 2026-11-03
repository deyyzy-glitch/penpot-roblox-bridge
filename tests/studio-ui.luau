-- Run outside the MCP recording with an isolated UI host and synthetic fixture.
return function(ui,fixture)
 local Http=game:GetService('HttpService');local selection=game:GetService('Selection');local previous=selection:Get();local results={};local imported
 local function check(name,fn)local ok,e=pcall(fn);table.insert(results,{name=name,passed=ok,error=not ok and tostring(e)or nil})end
 local root=ui.root or ui.widget.PenpotBridge;local body=root.Content
 check('empty import cannot review and verifier errors remain readable',function()
  ui.navigate('Design');assert(not ui.controls.primary.Interactable);assert(ui.verify()==nil);assert(root['Error details'].Visible);local text=root['Error details']:FindFirstChildWhichIsA('ScrollingFrame'):FindFirstChildWhichIsA('TextLabel');assert(text.Text:find('Receive the same design'))
 end)
 check('sidebar routes isolate all six workflow pages',function()
  for _,name in {'Setup','Design','Review','Verify','Options','Templates'}do ui.navigate(name);assert(ui.getCurrentTab()==name);local n=0;for _,p in body:GetChildren()do if p:IsA('Frame')and p.Visible then n+=1;assert(p.Name==name)end end;assert(n==1)end
 end)
 check('settings and templates leave the import action on its own hidden page',function()ui.navigate('Options');assert(not body.Design.Visible and not body.Review.Visible);ui.navigate('Templates');assert(not body.Design.Visible and not body.Review.Visible)end)
 check('connection test gives explicit connected state',function()assert(ui.checkConnection());assert(ui.controls.connection.Text:find('Connected'))end)
 local d=Http:JSONDecode(Http:JSONEncode(fixture));d.source.fileId='ui-overhaul-regression';d.design.name='UI workflow fixture';d.assets={};d.assetMap={};local keep={};for _,n in d.design.children do if n.type~='path'then table.insert(keep,n)end end;d.design.children=keep
 check('loading a design enables review and clears the error notice',function()ui.loadDocument(d);assert(ui.getDocument()==d and ui.getCurrentTab()=='Design'and ui.controls.primary.Interactable and not root['Error details'].Visible)end)
 check('review navigation shows counts and the import action',function()ui.preview();assert(ui.getCurrentTab()=='Review'and ui.controls.primary.Text=='Import design');local numbers=0;for _,i in body.Review:GetDescendants()do if i:IsA('TextLabel')and tonumber(i.Text)then numbers+=1 end end;assert(numbers==4)end)
 check('reviewed UI imports through the approved completion screen',function()imported=ui.apply();assert(imported and imported.Parent and ui.getCurrentTab()=='Complete');assert(tonumber(ui.controls.results.added.Text)>0 and ui.controls.results.updated.Text=='0'and ui.controls.results.images.Text=='0');assert(ui.getVerification()==nil)end)
 check('verification opens its own page and renders findings',function()local r=ui.verify();assert(r and r.errors==0 and ui.getCurrentTab()=='Verify');assert(ui.controls.verifySummary.Text:find('checks'));assert(ui.getVerification()==r)end)
 check('finding selection still selects the affected object',function()local r=ui.getVerification();assert(#r.issues>0);ui.selectFinding(1);assert(selection:Get()[1]==r.issues[1].instance)end)
 check('leaving verification does not clear results or disable reimport',function()local r=ui.getVerification();ui.navigate('Templates');ui.navigate('Verify');assert(ui.getVerification()==r);ui.navigate('Design');assert(ui.controls.primary.Interactable)end)
 check('unchanged reimport reports real zero creation rather than example counts',function()ui.preview();assert(ui.apply()==imported);assert(ui.controls.results.added.Text=='0'and ui.controls.results.updated.Text=='0')end)
 check('light and dark retain imported typography and geometry',function()
  local title=body.Design:FindFirstChild('Page title');local size,font,position=title.TextSize,title.FontFace,title.Position
  ui.setTheme('light');assert(ui.getTheme()=='light'and root.BackgroundColor3==Color3.fromRGB(247,248,247));assert(title.TextSize==size and title.FontFace==font and title.Position==position)
  ui.setTheme('dark');assert(ui.getTheme()=='dark'and root.BackgroundColor3==Color3.fromRGB(17,18,19))
 end)
 check('approved import page retains authored coordinates',function()ui.navigate('Design');body.CanvasPosition=Vector2.zero;task.wait();local title=body.Design:FindFirstChild('Page title');local delta=title.AbsolutePosition-root.AbsolutePosition;assert(math.abs(delta.X-160)<1 and math.abs(delta.Y-69)<1);assert(root.AbsoluteSize.X==624)end)
 if imported then imported:Destroy()end;selection:Set(previous);return results
end
