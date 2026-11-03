-- Pass a real exported board containing the seven named release-test samples.
-- Run outside an MCP undo recording; the test removes its own target.
return function(Importer,Gradient,fixture)
 local Http=game:GetService('HttpService');local results={}
 local function check(name,fn)local ok,e=pcall(fn);table.insert(results,{name=name,passed=ok,error=not ok and tostring(e)or nil})end
 local d=Http:JSONDecode(Http:JSONEncode(fixture));for _,asset in d.assets do d.assetMap[asset.key]='rbxassetid://0'end
 local target=Instance.new('ScreenGui');target.Name='P2R Upgraded Gradient Regression';target.Parent=game.StarterGui
 local ok,e=pcall(function()
  local plan=Importer.prepare(d,target,{});local wrapper=Importer.apply(plan)
  local function frame(name)return assert(wrapper:FindFirstChild(name,true),name)end
  local function gradient(name)return assert(frame(name):FindFirstChildWhichIsA('UIGradient'),name)end
  check('actual Penpot board creates six native gradients',function()local count=0;for _,v in wrapper:GetDescendants()do if v:IsA('UIGradient')then count+=1 end end;assert(count==6)end)
  check('normalized radial maps to a bounds-proportional ellipse',function()assert(gradient('Radial').Type==Enum.GradientType.Elliptical and gradient('Radial').Scale==1)end)
  check('physical circle uses radial extent',function()assert(gradient('Pixel circle').Type==Enum.GradientType.Radial);assert(math.abs(gradient('Pixel circle').Scale-96/88)<1e-6)end)
  check('short diagonal uses SVG normal and released scale',function()local g=gradient('Short diagonal');assert(math.abs(g.Scale-.7081967213114755)<1e-6 and math.abs(g.Rotation-50.1944289)<1e-5)end)
  check('shifted ellipse retains its center',function()local p=gradient('Offset ellipse').Offset;assert(math.abs(p.X+.2)<1e-6 and math.abs(p.Y+.1)<1e-6)end)
  check('unsupported ellipse stays an image surface',function()assert(not frame('Narrow radial'):FindFirstChildWhichIsA('UIGradient'));assert(wrapper:FindFirstChildWhichIsA('ImageLabel',true))end)
  check('new descriptors agree with post-import verifier',function()assert(Importer.verify(d,target,{}).errors==0)end)
  local g=gradient('Radial');Importer.apply(Importer.prepare(d,target,{}))
  check('reimport retains gradient identity',function()assert(gradient('Radial')==g)end)
  g.Scale=.75;g.Type=Enum.GradientType.Radial;g.TileMode=Enum.GradientTileMode.Mirror
  Importer.apply(Importer.prepare(d,target,{}))
  check('local type scale and tile edits are protected',function()assert(g.Scale==.75 and g.Type==Enum.GradientType.Radial and g.TileMode==Enum.GradientTileMode.Mirror)end)
  Importer.apply(Importer.prepare(d,target,{force=true}))
  check('explicit design values restore native gradient properties',function()assert(g.Type==Enum.GradientType.Elliptical and g.Scale==1 and g.TileMode==Enum.GradientTileMode.Clamp)end)
  check('malformed unsupported native geometry fails before mutation',function()local bad=Http:JSONDecode(Http:JSONEncode(d));bad.design.children[2].fills[1].fillColorGradient.width=.5;local before=#target:GetDescendants();assert(not pcall(Importer.prepare,bad,target,{}));assert(#target:GetDescendants()==before)end)
  check('image fallback accepts complex and hard-edge stops without creating a native sequence',function()
   local baked=Http:JSONDecode(Http:JSONEncode(d));local n=baked.design.children[3];local stops={};for i=0,24 do table.insert(stops,{offset=i/24,color='#FF0000'})end
   n.fills[1].fillColorGradient.stops=stops;assert(Importer.validate(baked));stops[13].offset=stops[12].offset;assert(Importer.validate(baked));Importer.prepare(baked,target,{})
  end)
  check('source type changes reuse the same editable gradient',function()
   local changed=Http:JSONDecode(Http:JSONEncode(d));changed.design.children[2].fills[1].fillColorGradient.width=1.2
   Importer.apply(Importer.prepare(changed,target,{}));assert(gradient('Radial')==g and g.Type==Enum.GradientType.Radial)
   Importer.apply(Importer.prepare(d,target,{}));assert(gradient('Radial')==g and g.Type==Enum.GradientType.Elliptical)
  end)
  check('legacy documents still validate',function()local old=Http:JSONDecode(Http:JSONEncode(d));old.version=4;for _,n in old.design.children do n.upgradedGradient=nil end;assert(Importer.validate(old))end)
  check('geometry parity for tall ellipses and degenerate vectors',function()local source=d.design.children[2].fills[1].fillColorGradient;local p=Gradient.geometry(source,160,192);assert(p.Type==Enum.GradientType.Elliptical and math.abs(p.Rotation)<1e-6);local zero=table.clone(source);zero.endX=zero.startX;zero.endY=zero.startY;assert(not Gradient.geometry(zero,192,160))end)
 end)
 target:Destroy();if not ok then table.insert(results,{name='integration setup',passed=false,error=tostring(e)})end
 return results
end
