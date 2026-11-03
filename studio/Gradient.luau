-- Preserve authored RGB stops, adding a bounded number of RGB-linear samples.
-- The tested legacy UI renderer brightens between distant keypoints. Extra
-- samples reduce that error and remain neutral in an RGB-linear renderer.
local Gradient={}
function Gradient.geometry(g,w,h)
 if w<=0 or h<=0 then return nil end
 local dx,dy=g.endX-g.startX,g.endY-g.startY;local r=math.sqrt(dx*dx+dy*dy)
 if r<1e-8 then return nil end
 local kind,scale,rotation,offset=nil,nil,0,nil
 if g.type=='linear'then
  local qx,qy=dx/w,dy/h;local q=math.sqrt(qx*qx+qy*qy);local cx,cy=qx/q,qy/q
  kind=Enum.GradientType.Linear;rotation=math.deg(math.atan2(cy,cx))
  local span=math.min(math.abs(cx)>1e-10 and w/math.abs(cx)or math.huge,math.abs(cy)>1e-10 and h/math.abs(cy)or math.huge)
  scale=(r*r/q)/span
  offset=Vector2.new((g.startX+g.endX)/2-.5,(g.startY+g.endY)/2-.5)
 elseif g.type=='radial'then
  local width=g.width or 1;if width<.000001 or width>10000 then return nil end
  local ux,uy,vx,vy=dx*w,dy*h,-dy*width*w,dx*width*h
  local a,b,c=ux*ux+vx*vx,ux*uy+vx*vy,uy*uy+vy*vy
  local gap=math.sqrt((a-c)^2+4*b*b);local major,minor=math.sqrt((a+c+gap)/2),math.sqrt(math.max(0,(a+c-gap)/2))
  if minor<1e-8 then return nil end
  offset=Vector2.new(g.startX-.5,g.startY-.5)
  if math.abs(major-minor)<=major*1e-6 then kind=Enum.GradientType.Radial;scale=major/((w+h)/4)
  elseif math.abs(major/minor-math.max(w,h)/math.min(w,h))<=1e-6 then
   kind=Enum.GradientType.Elliptical;scale=major/(math.max(w,h)/2);rotation=math.deg(math.atan2(2*b,a-c))/2-(w<h and 90 or 0)
  else return nil end
 else return nil end
 if scale~=scale or scale<.001 or scale>10000 or math.abs(offset.X)>10000 or math.abs(offset.Y)>10000 then return nil end
 return {Type=kind,Scale=scale,Rotation=rotation,Offset=offset,TileMode=Enum.GradientTileMode.Clamp}
end
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
