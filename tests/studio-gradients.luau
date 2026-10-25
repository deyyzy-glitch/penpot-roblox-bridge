-- Execute outside the MCP undo recording with built Importer and source Gradient.
return function(Importer,Gradient,fixture)
 local Http=game:GetService('HttpService');local results={}
 local function check(name,fn)local ok,e=pcall(fn);table.insert(results,{name=name,passed=ok,error=not ok and tostring(e)or nil})end
 local stops={{offset=0,color='#ff0000',opacity=.2},{offset=1,color='#0000ff',opacity=1}}
 local before=Http:JSONEncode(stops);local colors,alpha=Gradient.sequences(stops)
 check('color correction keeps bounded editable keypoints and source stops',function()
  assert(#colors.Keypoints==6);assert(colors.Keypoints[1].Value==Color3.new(1,0,0));assert(colors.Keypoints[6].Value==Color3.new(0,0,1));assert(Http:JSONEncode(stops)==before)
  local last=-1;for _,p in colors.Keypoints do assert(p.Time>last);last=p.Time;assert(math.abs(p.Value.R-(1-p.Time))<.00001 and math.abs(p.Value.B-p.Time)<.00001)end
 end)
 check('transparency sequence retains authored interpolation',function()assert(#alpha.Keypoints==2);assert(math.abs(alpha.Keypoints[1].Value-.8)<.00001 and alpha.Keypoints[2].Value==0)end)
 check('constant colors avoid unnecessary sampling',function()local c=Gradient.sequences({{offset=0,color='#85b5ff'},{offset=1,color='#85b5ff'}});assert(#c.Keypoints==2)end)
 check('interior endpoints clamp without mutating source or transparency',function()
  local s={{offset=.2,color='#ff0000',opacity=.3},{offset=.8,color='#0000ff',opacity=.9}};local c,a=Gradient.sequences(s)
  assert(c.Keypoints[1].Time==0 and c.Keypoints[#c.Keypoints].Time==1);assert(#a.Keypoints==4 and s[1].offset==.2 and s[2].offset==.8)
  local found={};for _,p in c.Keypoints do if math.abs(p.Time-.2)<.00001 then found[1]=p.Value end;if math.abs(p.Time-.8)<.00001 then found[2]=p.Value end end;assert(found[1]==Color3.new(1,0,0)and found[2]==Color3.new(0,0,1))
 end)
 check('authored sequences above six stops are preserved',function()local s={};for i=0,9 do table.insert(s,{offset=i/9,color=i%2==0 and '#ffffff'or'#000000'})end;local c=Gradient.sequences(s);assert(#c.Keypoints==10);for i,p in c.Keypoints do assert(math.abs(p.Time-s[i].offset)<.00001)end end)
 check('twenty authored stops preserve engine limit',function()local s={};for i=0,19 do table.insert(s,{offset=i/19,color='#ffffff'})end;assert(#Gradient.sequences(s).Keypoints==20)end)
 check('unrepresentable padded endpoints fail before creating instances',function()local s={};for i=1,20 do table.insert(s,{offset=i/21,color='#ffffff'})end;local ok,e=pcall(Gradient.sequences,s);assert(not ok and tostring(e):find('20%-keypoint'))end)
 local target=Instance.new('ScreenGui');target.Name='P2R Gradient Regression';target.Parent=game.StarterGui
 local ok,e=pcall(function()
  local d=Http:JSONDecode(Http:JSONEncode(fixture));d.design.children={};d.design.fills={{fillOpacity=1,fillColorGradient={type='linear',startX=0,startY=.5,endX=1,endY=.5,stops=stops}}};d.assets={};d.assetMap={}
  local wrapper=Importer.apply(Importer.prepare(d,target,{}));local g=wrapper:FindFirstChildWhichIsA('UIGradient',true)
  check('built importer uses corrected color sequence',function()assert(g and #g.Color.Keypoints==6 and #g.Transparency.Keypoints==2)end)
  check('verification accepts corrected expected values',function()assert(Importer.verify(d,target,{}).errors==0)end)
  check('reimport retains existing native gradient identity',function()Importer.apply(Importer.prepare(d,target,{}));assert(wrapper:FindFirstChildWhichIsA('UIGradient',true)==g)end)
  check('local color edits remain protected on reimport',function()g.Color=ColorSequence.new(Color3.new(0,1,0));Importer.apply(Importer.prepare(d,target,{}));assert(g.Color.Keypoints[1].Value==Color3.new(0,1,0))end)
 end)
 target:Destroy();if not ok then table.insert(results,{name='integration setup',passed=false,error=tostring(e)})end
 return results
end
