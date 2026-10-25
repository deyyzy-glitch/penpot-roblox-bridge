local References={}
local BODY=[=[
-- Generated references. Keep gameplay logic in your own scripts.
local References={Aliases=aliases}
function References.Bind(root)
 assert(root and root:GetAttribute('P2R_Design')==source,'Choose this design\'s imported wrapper')
 local ids={}
 for _,i in root:GetDescendants()do
  local id=i:GetAttribute('P2R_Id')
  if id and not id:find('::',1,true)and i:GetAttribute('P2R_Source')==source and not i:GetAttribute('P2R_Retired')and not i:GetAttribute('P2R_Stale')then
   assert(not ids[id],'Duplicate imported reference ID: '..id);ids[id]=i
  end
 end
 local named,missing={},{}
 for alias,id in aliases do if ids[id]then named[alias]=ids[id]else table.insert(missing,alias)end end
 table.sort(missing);return {ById=ids,Named=named,Missing=missing}
end
function References.Get(root,alias)
 assert(aliases[alias],'Unknown reference alias: '..tostring(alias))
 local i=References.Bind(root).Named[alias];assert(i,'Missing imported reference: '..alias);return i
end
function References.GetById(root,id)
 local i=References.Bind(root).ById[id];assert(i,'Missing imported source ID: '..tostring(id));return i
end
return References
]=]
function References.source(d)
 local pairs={};local seen={}
 local function walk(n)
  if n.ref then assert(not seen[n.ref],'Duplicate reference alias');seen[n.ref]=true;table.insert(pairs,'['..string.format('%q',n.ref)..']='..string.format('%q',n.id))end
  for _,c in n.children do walk(c)end
 end;walk(d.design);table.sort(pairs)
 return 'local source='..string.format('%q',d.source.fileId..'/'..d.source.rootId)..'\nlocal aliases={'..table.concat(pairs,',')..'}\n'..BODY
end
return References
