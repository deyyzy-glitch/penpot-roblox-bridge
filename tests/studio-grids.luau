-- Run outside MCP recording. All mutations stay in a disposable test container.
return function(Importer,horizontal,vertical,realFixtures)
 local Http=game:GetService('HttpService');local results={}
 local function copy(d)return Http:JSONDecode(Http:JSONEncode(d))end
 local target=Instance.new('ScreenGui');target.Name='P2R Native Grid Regression';target.Parent=game.StarterGui
 local function check(name,fn)local ok,e=pcall(fn);table.insert(results,{name=name,passed=ok,error=not ok and tostring(e)or nil})end
 local function byId(root,id)for _,i in root:GetDescendants()do if i:GetAttribute('P2R_Id')==id then return i end end end
 local d=copy(horizontal);local wrapper,layout,slot
 local ok,err=pcall(function()
  check('native grids are off by default',function()wrapper=Importer.apply(Importer.prepare(d,target,{}));assert(not wrapper:FindFirstChildWhichIsA('UIGridLayout',true));slot=byId(wrapper,'slot-0')end)
  check('opt-in creates a padded uniform grid',function()wrapper=Importer.apply(Importer.prepare(d,target,{nativeGrids=true}));task.wait(.2);layout=wrapper:FindFirstChildWhichIsA('UIGridLayout',true);assert(layout and layout.CellSize==UDim2.fromOffset(64,48));assert(layout.CellPadding==UDim2.fromOffset(8,10)and layout.FillDirectionMaxCells==3);assert(byId(wrapper,'slot-0')==slot)end)
  check('row grid preserves measured desktop positions and spatial order',function()local root=byId(wrapper,'inventory');for i=0,4 do local s=byId(wrapper,'slot-'..i);local pos=s.AbsolutePosition-root.AbsolutePosition;assert(math.abs(pos.X-(12+(i%3)*72))<1 and math.abs(pos.Y-(12+math.floor(i/3)*58))<1,'slot '..i..' rendered at '..tostring(pos));assert(s.LayoutOrder==i+1);assert(s.AbsoluteSize==Vector2.new(64,48))end end)
  check('same grid reimport is idempotent',function()local p=Importer.prepare(d,target,{nativeGrids=true});assert(p.stats.updated==0 and p.stats.added==0 and p.stats.conflicts==0,Http:JSONEncode(p.stats))end)
  check('grid import passes verifier',function()local r=Importer.verify(d,wrapper,{nativeGrids=true});assert(r.errors==0,'Verifier errors '..r.errors)end)
  check('turning off restores measured placement and retains grid component',function()Importer.apply(Importer.prepare(d,target,{nativeGrids=false}));task.wait(.15);assert(layout.Parent:IsA('Folder'));assert(byId(wrapper,'slot-0')==slot);assert(slot.Position==UDim2.fromOffset(12,12));local r=Importer.verify(d,wrapper,{});assert(r.errors==0)end)
  check('turning back on reuses the layout and cell identities',function()Importer.apply(Importer.prepare(d,target,{nativeGrids=true}));assert(layout.Parent==byId(wrapper,'inventory'));assert(byId(wrapper,'slot-0')==slot)end)
  check('column-major grids preserve positions and order',function()local v=copy(vertical);v.source.fileId='vertical-grid';local w=Importer.apply(Importer.prepare(v,target,{nativeGrids=true}));task.wait(.15);local l=w:FindFirstChildWhichIsA('UIGridLayout',true);assert(l.FillDirection==Enum.FillDirection.Vertical and l.FillDirectionMaxCells==2);local root=byId(w,'inventory');for i=0,4 do local p=byId(w,'slot-'..i).AbsolutePosition-root.AbsolutePosition;assert(math.abs(p.X-(12+math.floor(i/2)*72))<1 and math.abs(p.Y-(12+(i%2)*58))<1)end end)
  for _,kind in {'unequal','hole','hidden','rotated','span','raster','smooth'}do
   check('unsafe '..kind..' grid falls back to measured positions',function()
    local bad=copy(d);bad.source.fileId='bad-'..kind
    if kind=='unequal'then bad.design.children[1].width=99
    elseif kind=='hole'then bad.design.children[1].x+=3
    elseif kind=='hidden'then bad.design.children[1].visible=false
    elseif kind=='rotated'then bad.design.children[1].rotation=10
    elseif kind=='span'then bad.design.grid.unsupportedCells=true
    elseif kind=='raster'then bad.design.assetKey='fixture:raster';bad.design.rasterSurface=true;bad.assetMap['fixture:raster']='rbxassetid://0'
    elseif kind=='smooth'then bad.design.smooth={key='smooth',slice={1,1,3,3}}end
    local p=Importer.prepare(bad,target,{nativeGrids=true});for _,item in p.items do assert(item.class~='UIGridLayout')end
    assert(table.concat(p.warnings,' '):find('Native grid skipped',1,true))
   end)
  end
  check('invalid grid metadata is rejected',function()local bad=copy(d);bad.design.grid.columns=-1;assert(not pcall(Importer.prepare,bad,target,{nativeGrids=true}))end)
  check('retired grid no longer positions local additions',function()Importer.apply(Importer.prepare(d,target,{nativeGrids=false}));local root=byId(wrapper,'inventory');local user=Instance.new('Frame');user.Position=UDim2.fromOffset(40,30);user.Parent=root;task.wait(.1);assert(user.Position==UDim2.fromOffset(40,30));user:Destroy()end)
  for name,fixture in realFixtures do
   check('captured '..name..' imports and remains idempotent',function()local doc=copy(fixture);local w=Importer.apply(Importer.prepare(doc,target,{}));task.wait(.1);local p=Importer.prepare(doc,target,{});assert(p.stats.added==0 and p.stats.updated==0 and p.stats.conflicts==0,Http:JSONEncode(p.stats));assert(Importer.verify(doc,w,{}).errors==0);if name=='svg-chart'then local n=byId(w,'chart-3::surface');assert(n and n.Image=='rbxassetid://0');assert(n.Position==UDim2.fromOffset(-2,-2));assert(not byId(w,'chart-2::surface'),'Definition-only SVG must not create an image')end end)
  end
 end)
 target:Destroy();if not ok then error(err)end;return results
end
