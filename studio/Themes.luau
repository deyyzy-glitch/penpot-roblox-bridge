local Themes={}
local TEMPLATE=[=[
-- Generated token definitions and palettes. No design text is executed.
local Theme={Data=data}
function Theme.List()
 local list={{id='Default',name='Default'}}
 for _,t in data.themes do table.insert(list,{id=t.id,name=t.group~='' and t.group..'/'..t.name or t.name})end
 return list
end
local function palette(name)
 if not name or name=='Default'then return data.palettes.Default end
 if data.palettes[name]then return data.palettes[name]end
 local found
 for _,t in data.themes do if name==t.name or name==(t.group~='' and t.group..'/'..t.name or t.name)then assert(not found,'Ambiguous theme name; use its ID');found=data.palettes[t.id]end end
 assert(found,'Unknown theme: '..tostring(name));return found
end
local colors={BackgroundColor3=true,TextColor3=true,ImageColor3=true,Color=true}
local numbers={TextSize={1,1000},Thickness={0,1000},Rotation={-36000,36000}}
local dims={CornerRadius=true,TopLeftRadius=true,TopRightRadius=true,BottomLeftRadius=true,BottomRightRadius=true,Padding=true,PaddingTop=true,PaddingBottom=true,PaddingLeft=true,PaddingRight=true}
local function convert(i,prop,value,kind)
 if colors[prop] and kind=='color' and type(value)=='string' and value:match('^#%x%x%x%x%x%x$')then return Color3.fromHex(value)end
 if type(value)=='number'then
  if numbers[prop]then return math.clamp(value,numbers[prop][1],numbers[prop][2])end
  if dims[prop]then return UDim.new(0,math.clamp(value,0,100000))end
  if prop=='SizeX'then return UDim2.new(0,math.max(0,value),i.Size.Y.Scale,i.Size.Y.Offset)end
  if prop=='SizeY'then return UDim2.new(i.Size.X.Scale,i.Size.X.Offset,0,math.max(0,value))end
  if prop=='Opacity'then return math.clamp(value,0,1)end
  if prop=='FontWeight'then local weights={Enum.FontWeight.Thin,Enum.FontWeight.ExtraLight,Enum.FontWeight.Light,Enum.FontWeight.Regular,Enum.FontWeight.Medium,Enum.FontWeight.SemiBold,Enum.FontWeight.Bold,Enum.FontWeight.ExtraBold,Enum.FontWeight.Heavy};return Font.new(i.FontFace.Family,weights[math.clamp(math.floor(value/100+.5),1,9)],i.FontFace.Style)end
 end
 if prop=='FontFamily' and kind=='fontFamilies' and type(value)=='string'then
  local names={Arial='Arial',Roboto='Roboto',RobotoMono='RobotoMono',RobotoCondensed='RobotoCondensed',Ubuntu='Ubuntu',Gotham='Gotham',BuilderSans='BuilderSans',Inter='BuilderSans',['Source Sans Pro']='SourceSans'}
  local family=value:match('^rbxasset://fonts/families/[%w_-]+%.json$') and value or value:match('^rbxassetid://%d+$') and value
  if not family and names[value]then family=Font.fromEnum(Enum.Font[names[value]]).Family end
  if family then return Font.new(family,i.FontFace.Weight,i.FontFace.Style)end
 end
 return nil
end
function Theme.Apply(root,name)
 assert(typeof(root)=='Instance' and root:GetAttribute('P2R_Design')==source,'Choose this import’s wrapper')
 local values=palette(name);local result={applied=0,skipped=0,details={}}
 for _,i in root:GetDescendants()do
  local eligible=i:GetAttribute('P2R_Source')==source;local ancestor=i
  while eligible and ancestor and ancestor~=root do if ancestor:GetAttribute('P2R_Stale')or ancestor:GetAttribute('P2R_Retired')or (ancestor~=i and ancestor:GetAttribute('P2R_Design'))then eligible=false end;ancestor=ancestor.Parent end
  local encoded=i:GetAttribute('P2R_ThemeTargets')
  if eligible and encoded then
   local ok,bindings=pcall(Http.JSONDecode,Http,encoded)
   if ok then for _,b in bindings do
    local token=values[b.token]or values[data.bindingNames and data.bindingNames[b.token]];local prop=b.property
    local actual=({SizeX='Size',SizeY='Size',FontFamily='FontFace',FontWeight='FontFace',Opacity=b.target})[prop]or prop
    local locks=i:GetAttribute('P2R_Locks')or '';local locked=false;for key in locks:gmatch('[^,%s]+')do if key=='*'or key==actual then locked=true end end
    local success=false
    if token and not locked then success=pcall(function()
     local value=convert(i,prop,token.value,token.type);assert(value~=nil,'Unsupported token value')
     if prop=='Opacity'then value=1-value*(b.factor or 1)end
     i[actual]=value
    end)end
    if success then result.applied+=1 else result.skipped+=1;table.insert(result.details,i.Name..': '..b.token)end
   end end
  end
 end
 return result
end
return Theme
]=]
function Themes.source(data,source)
 local Http=game:GetService('HttpService')
 return 'local Http=game:GetService("HttpService")\nlocal data=Http:JSONDecode('..string.format('%q',Http:JSONEncode(data))..')\nlocal source='..string.format('%q',source)..'\n'..TEMPLATE
end
return Themes
