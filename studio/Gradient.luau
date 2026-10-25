-- Preserve authored RGB stops, adding a bounded number of RGB-linear samples.
-- The tested legacy UI renderer brightens between distant keypoints. Extra
-- samples reduce that error and remain neutral in an RGB-linear renderer.
local Gradient={}
function Gradient.sequences(source)
 local points,alpha={},{}
 for _,s in ipairs(source)do
  table.insert(points,{time=s.offset,color=Color3.fromHex(s.color)})
  table.insert(alpha,NumberSequenceKeypoint.new(s.offset,1-(s.opacity or 1)))
 end
 if points[1].time>0 then table.insert(points,1,{time=0,color=points[1].color});table.insert(alpha,1,NumberSequenceKeypoint.new(0,alpha[1].Value))end
 if points[#points].time<1 then table.insert(points,{time=1,color=points[#points].color});table.insert(alpha,NumberSequenceKeypoint.new(1,alpha[#alpha].Value))end
 assert(#points<=20,'Gradient exceeds Roblox\'s 20-keypoint limit after extending its endpoints; use Image mode.')
 -- Six is Roblox's recommended performance budget. Never discard original stops.
 while #points<6 do
  local bestError,bestIndex,bestT=1/255,nil,nil
  for i=1,#points-1 do
   local a,b=points[i],points[i+1]
   if b.time-a.time>0.00001 then
    for k=1,15 do
     local t=k/16;local desired=a.color:Lerp(b.color,t)
     local predicted=Vector3.new(
      math.sqrt(a.color.R^2*(1-t)+b.color.R^2*t),
      math.sqrt(a.color.G^2*(1-t)+b.color.G^2*t),
      math.sqrt(a.color.B^2*(1-t)+b.color.B^2*t))
     local err=math.max(math.abs(predicted.X-desired.R),math.abs(predicted.Y-desired.G),math.abs(predicted.Z-desired.B))
     if err>bestError then bestError,bestIndex,bestT=err,i,t end
    end
   end
  end
  if not bestIndex then break end
  local a,b=points[bestIndex],points[bestIndex+1]
  table.insert(points,bestIndex+1,{time=a.time+(b.time-a.time)*bestT,color=a.color:Lerp(b.color,bestT)})
 end
 local colors={};for _,p in ipairs(points)do table.insert(colors,ColorSequenceKeypoint.new(p.time,p.color))end
 return ColorSequence.new(colors),NumberSequence.new(alpha)
end
return Gradient
