-- Fixed desktop layout checks; offscreen hosts avoid moving the user's windows.
return function(createUI,plugin,Importer)
 local results={};local screen=Instance.new('ScreenGui');screen.Name='P2R Source UI Layout QA';screen.IgnoreGuiInset=true;screen.Parent=game.CoreGui
 local function check(name,fn)local ok,e=pcall(fn);table.insert(results,{name=name,passed=ok,error=not ok and tostring(e)or nil})end
 for _,size in {{360,420},{626,420},{626,740},{900,900},{1400,1000}}do
  local host=Instance.new('Frame');host.Size=UDim2.fromOffset(size[1],size[2]);host.Position=UDim2.fromOffset(-10000,0);host.Parent=screen
  local ui=createUI(plugin,Importer,nil,{preview=true,host=host});task.wait(.12);local root,body=ui.root,ui.root.Content;local name=size[1]..' x '..size[2]
  check(name..': approved desktop width stays fixed',function()assert(root.AbsoluteSize.X==624);assert(root.AbsoluteSize.Y==math.clamp(size[2],500,860));assert(not root:FindFirstChildWhichIsA('UIScale',true));local title=body.Design:FindFirstChild('Page title');assert(title.Position==UDim2.fromOffset(24,29))end)
  check(name..': no empty footer masks content',function()assert(not root:FindFirstChild('Action bar'));assert(not ui.controls.status.Visible);assert(math.abs(body.AbsolutePosition.Y+body.AbsoluteSize.Y-(root.AbsolutePosition.Y+root.AbsoluteSize.Y))<1)end)
  check(name..': connection footer stays below navigation',function()local nav=root:FindFirstChild('Navigation / Settings');local connection=root:FindFirstChild('Connection label');assert(nav.AbsolutePosition.Y+nav.AbsoluteSize.Y+8<=connection.AbsolutePosition.Y);assert(connection.AbsolutePosition.Y+connection.AbsoluteSize.Y<=root.AbsolutePosition.Y+root.AbsoluteSize.Y)end)
  check(name..': short panels can reach the review action by scrolling',function()ui.navigate('Design');body.CanvasPosition=Vector2.new(0,10000);task.wait(.08);local b=ui.controls.primary;assert(b.AbsolutePosition.Y>=body.AbsolutePosition.Y-1);assert(b.AbsolutePosition.Y+b.AbsoluteSize.Y<=body.AbsolutePosition.Y+body.AbsoluteSize.Y+1);body.CanvasPosition=Vector2.zero end)
  check(name..': template card has ordered content, even spacing and a visible key field',function()
   ui.navigate('Templates');task.wait(.08);local card=body.Templates.Card;local items={};for _,i in card:GetChildren()do if i:IsA('GuiObject')then table.insert(items,i)end end;table.sort(items,function(a,b)return a.LayoutOrder<b.LayoutOrder end)
   assert(#items==4 and items[1].Text=='Map a Studio component'and items[2]:IsA('TextLabel')and items[3]:IsA('TextBox')and items[4].Name=='Map selected component','Template fields are out of order')
   assert(math.abs(items[1].AbsolutePosition.Y-card.AbsolutePosition.Y-16)<1,'Unexpected top gap')
   for i=2,4 do assert(math.abs(items[i].AbsolutePosition.Y-items[i-1].AbsolutePosition.Y-items[i-1].AbsoluteSize.Y-8)<1,'Uneven template spacing')end
   assert(math.abs(card.AbsolutePosition.Y+card.AbsoluteSize.Y-items[4].AbsolutePosition.Y-items[4].AbsoluteSize.Y-16)<1,'Unexpected bottom gap');assert(items[3].ZIndex>card.ZIndex and items[3].Visible and items[3].TextEditable,'Key field is behind the card')
  end)
  check(name..': light and dark text fit in every visible page',function()
   for _,theme in {'dark','light'}do ui.setTheme(theme)
    for _,page in {'Setup','Design','Review','Verify','Options','Templates','Progress','Complete'}do ui.navigate(page);task.wait(.08)
     for _,i in root:GetDescendants()do if i:IsA('TextLabel')and i.Text~=''and i.TextTransparency<1 and i.TextTruncate==Enum.TextTruncate.None then
      local visible=true;local p=i;while p and p~=root do if p:IsA('GuiObject')and not p.Visible then visible=false end;p=p.Parent end
      if visible then assert(i.TextBounds.X<=i.AbsoluteSize.X+1 and i.TextBounds.Y<=i.AbsoluteSize.Y+1,page..' | '..i.Text..' | '..tostring(i.AbsoluteSize)..' | '..tostring(i.TextBounds));if i:GetAttribute('UI_Color_TextColor3')=='text'then assert(i.TextColor3==(theme=='light'and Color3.fromRGB(27,34,29)or Color3.fromRGB(243,245,244)),'Theme contrast lost: '..i.Text)end end
     end end
    end
   end
  end)
  ui.destroy();host:Destroy()
 end
 screen:Destroy();return results
end
