-- Pass the captured machine-icon fixture; run outside an MCP undo recording.
return function(Importer,fixture)
 local Http=game:GetService('HttpService');local results={}
 local target=Instance.new('ScreenGui');target.Name='P2R Fractional Geometry Regression';target.Parent=game.StarterGui
 local root
 local function check(name,fn)local ok,e=pcall(fn);table.insert(results,{name=name,passed=ok,error=not ok and tostring(e)or nil})end
 local function near(a,b)assert(math.abs(a-b)<.002,tostring(a)..' differs from '..tostring(b))end
 local function index()local t={}for _,i in root:GetDescendants()do local id=i:GetAttribute('P2R_Id');if id then t[id]=i end end return t end
 local ok,e=pcall(function()
  root=Importer.apply(Importer.prepare(fixture,target,{}));task.wait(.1)
  local nodes=index()
  check('captured icon, circle, badge and every nested path preserve authored geometry',function()
   local count=0
   local function walk(n,parent,x,y)
    local i=nodes[n.id];assert(i,n.name..' missing')
    if parent then
     near(i.AbsolutePosition.X-root.AbsolutePosition.X,x+n.x);near(i.AbsolutePosition.Y-root.AbsolutePosition.Y,y+n.y)
     near(i.AbsoluteSize.X,n.width);near(i.AbsoluteSize.Y,n.height);count+=1
    end
    for _,c in n.children do walk(c,n,parent and x+n.x or 0,parent and y+n.y or 0)end
   end
   walk(fixture.design,nil,0,0);assert(count>=12)
  end)
  check('padded raster surfaces retain their own fractional bounds',function()
   local function walk(n)local b=n.rasterBounds;local surface=nodes[n.id..'::surface'];if b and surface then local p=nodes[n.id];near(surface.AbsolutePosition.X-p.AbsolutePosition.X,b.x);near(surface.AbsolutePosition.Y-p.AbsolutePosition.Y,b.y);near(surface.AbsoluteSize.X,b.width);near(surface.AbsoluteSize.Y,b.height)end;for _,c in n.children do walk(c)end end
   walk(fixture.design)
  end)
  check('reimport preserves instance identity and verifier agreement',function()
   local before=index();Importer.apply(Importer.prepare(fixture,target,{}));for id,i in index()do assert(before[id]==i,'instance replaced: '..id)end
   local report=Importer.verify(fixture,target,{});for _,issue in report.issues do assert(issue.code~='design-difference',issue.message)end
  end)
 end)
 if not ok then table.insert(results,{name='fixture setup',passed=false,error=tostring(e)})end
 target:Destroy();return results
end
