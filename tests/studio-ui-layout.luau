-- Desktop dock/float size checks. No monitor, Studio DPI, or beta settings change.
return function(createUI,plugin,Importer)
 local results={}
 local function check(name,fn)local ok,e=pcall(fn);table.insert(results,{name=name,passed=ok,error=not ok and tostring(e)or nil})end
 for _,size in {{360,420},{440,520},{680,740},{940,760}}do
  local ui=createUI(plugin,Importer,nil,{preview=true,width=size[1],height=size[2]});ui.widget.Enabled=true;task.wait(.15)
  local root=ui.widget.PenpotBridge;local body=root.Content
  local function visible(i)while i and i~=ui.widget do if i:IsA('GuiObject')and not i.Visible then return false end;i=i.Parent end return true end
  local label=tostring(size[1])..' × '..tostring(size[2])
  check(label..': no fixed footer reserves content space',function()assert(not root:FindFirstChild('Action bar'));assert(not ui.controls.status.Visible);assert(body.AbsolutePosition.Y+body.AbsoluteSize.Y>=root.AbsoluteSize.Y-16)end)
  check(label..': cards keep their complete horizontal rounded borders',function()
   ui.navigate('Options');task.wait(.1);local left=body.AbsolutePosition.X;local right=left+body.AbsoluteSize.X
   for _,i in body.Options:GetChildren()do if i:IsA('Frame')and i.Name=='Card'then assert(i.AbsolutePosition.X>=left+2,'left border clipped');assert(i.AbsolutePosition.X+i.AbsoluteSize.X<=right-5,'right border clipped')end end
  end)
  check(label..': all page text fits after wrapping',function()
   for _,page in {'Setup','Design','Review','Verify','Options','Templates'}do
    ui.navigate(page);task.wait(.08)
    -- TextFits can stay false on auto-height labels even after their bounds fit.
    -- Inspect the engine's actual rendered bounds against the available box.
    for _,i in root:GetDescendants()do if i:IsA('TextLabel')and visible(i)and i.TextTruncate==Enum.TextTruncate.None then assert(i.TextBounds.X<=i.AbsoluteSize.X+1 and i.TextBounds.Y<=i.AbsoluteSize.Y+1,i.Text..' | '..tostring(i.AbsoluteSize)..' | '..tostring(i.TextBounds))end end
   end
  end)
  check(label..': sidebar groups do not collide',function()
   local side=root.Sidebar;local nav=side.Navigation;local bottom=0;for _,b in nav:GetChildren()do if b:IsA('GuiButton')then bottom=math.max(bottom,b.AbsolutePosition.Y+b.AbsoluteSize.Y)end end
   local second;for _,f in side:GetChildren()do if f:IsA('Frame')and f~=nav and f:FindFirstChild('Options')then second=f end end;assert(second and bottom+8<=second.AbsolutePosition.Y)
  end)
  ui.destroy()
 end
 return results
end
