local RichText={}
local function escape(s)return (s:gsub('&','&amp;'):gsub('<','&lt;'):gsub('>','&gt;'):gsub('"','&quot;'):gsub("'",'&apos;'))end
function RichText.render(runs,fontMap)
 local out={}
 for _,r in runs do
  local value=r.value;if r.transform=='uppercase'then value=string.upper(value)elseif r.transform=='lowercase'then value=string.lower(value)end
  value=escape(value)
  if r.italic then value='<i>'..value..'</i>'end
  if r.decoration=='underline'then value='<u>'..value..'</u>'elseif r.decoration=='line-through'then value='<s>'..value..'</s>'end
  local family=fontMap and fontMap[r.family]
  local face=family and ('family="'..escape(family)..'"')or('face="'..escape(r.robloxFamily)..'"')
  table.insert(out,string.format('<font %s size="%d" weight="%d" color="%s" transparency="%.5f">%s</font>',face,math.floor(r.size+.5),r.weight,r.color,1-r.alpha,value))
 end
 return table.concat(out)
end
return RichText
