-- Native publishing where supported; official Open Cloud uploads through the local helper otherwise.
local Http=game:GetService('HttpService')
local AssetService=game:GetService('AssetService')
local Assets={}
local endpoint='http://127.0.0.1:43129'
local nativeUnavailable=false
local function request(token,path)
 local response=Http:RequestAsync({Url=endpoint..path,Method='GET',Headers={Authorization='Bearer '..token}})
 assert(response.Success,'Companion: '..response.StatusCode..' '..response.Body)
 return response.Body
end
function Assets.connect()
 local ok,response=pcall(function()return Http:RequestAsync({Url=endpoint..'/session',Method='GET'})end)
 assert(ok and response.Success,'Cannot reach the local helper. Open Setup for startup and connection instructions.')
 return Http:JSONDecode(response.Body).token
end
function Assets.status(token)
 return Http:JSONDecode(request(token,'/upload-status'))
end
function Assets.pending(document,plugin,Importer)
 local owner=(game.CreatorType==Enum.CreatorType.Group and game.CreatorId>0) and 'group:'..game.CreatorId or 'user:'..game:GetService('StudioService'):GetUserId()
 local registry=plugin:GetSetting('ImageRegistry_v2') or {}
 document.assetMap=document.assetMap or {}
 local pending,seen={},{}
 local needed=Importer and Importer.assetFilter(document)
 for _,asset in ipairs(document.assets or {}) do
  if needed and not needed(asset) then continue end
  if asset.contentHash then
   local id=registry[owner..':'..asset.contentHash]
   if id then document.assetMap[asset.key]=id end
   if not document.assetMap[asset.key] and not seen[asset.contentHash] then table.insert(pending,asset);seen[asset.contentHash]=true end
  elseif not document.assetMap[asset.key] then table.insert(pending,asset) end
 end
 return pending
end
function Assets.upload(document,plugin,token,onProgress,Importer)
 local userId=game:GetService('StudioService'):GetUserId()
 local isGroup=game.CreatorType==Enum.CreatorType.Group and game.CreatorId>0
 local owner=isGroup and 'group:'..game.CreatorId or 'user:'..userId
 local registry=plugin:GetSetting('ImageRegistry_v2') or {}
 local pending=Assets.pending(document,plugin,Importer)
 for index,asset in ipairs(pending) do
  assert(type(asset.contentHash)=='string' and asset.contentHash:match('^%x+$') and #asset.contentHash==64,'This older JSON has no embedded image data. Send the selection again from the updated Penpot companion.')
  if onProgress then onProgress(index,#pending,asset.name) end
  local payload=(document.assetPayloads or {})[asset.contentHash]
  local pixels
  if payload then
   assert(type(payload.pixels)=='string' and #payload.pixels<=5600000,'Invalid embedded image')
   pixels=game:GetService('EncodingService'):Base64Decode(buffer.fromstring(payload.pixels))
  else
   assert(token,'Connect to the companion to receive image pixels')
   payload=Http:JSONDecode(request(token,'/assets/'..asset.contentHash))
   pixels=buffer.fromstring(request(token,'/assets/'..asset.contentHash..'/pixels'))
  end
  local w,h=payload.width,payload.height
  assert(type(w)=='number' and type(h)=='number' and w%1==0 and h%1==0 and w>=1 and h>=1 and w<=1024 and h<=1024 and buffer.len(pixels)==w*h*4,'Invalid image dimensions or pixel data')
  local ok,result,id=false,'Native upload unavailable',nil
  if not nativeUnavailable then
   local image=AssetService:CreateEditableImage({Size=Vector2.new(w,h)})
   assert(image,'Roblox image memory budget is exhausted. Retry after closing other previews.')
   ok,result,id=pcall(function()
    image:WritePixelsBuffer(Vector2.zero,Vector2.new(w,h),pixels)
    return AssetService:CreateAssetAsync(image,Enum.AssetType.Image,{Name=('Penpot '..asset.name):sub(1,90),Description='Imported design surface from Penpot. Content hash '..asset.contentHash,CreatorId=isGroup and game.CreatorId or userId,CreatorType=isGroup and Enum.AssetCreatorType.Group or Enum.AssetCreatorType.User})
   end)
   image:Destroy()
   if not ok and (tostring(result):find('not available yet',1,true) or tostring(result):find('locally loaded',1,true)) then nativeUnavailable=true end
  end
  if nativeUnavailable then
   token=token or Assets.connect()
   local payload=(document.assetPayloads or {})[asset.contentHash]
   local creator=isGroup and {groupId=tostring(game.CreatorId)} or {userId=tostring(userId)}
   for attempt=1,60 do
    local response=Http:RequestAsync({Url=endpoint..'/uploads',Method='POST',Headers={Authorization='Bearer '..token,['Content-Type']='application/json'},Body=Http:JSONEncode({hash=asset.contentHash,name=asset.name,creator=creator,requestedBy=tostring(userId),payload=payload})})
    local info=Http:JSONDecode(response.Body);assert(response.Success,info.error or 'Roblox upload failed')
    if info.assetId then id=info.assetId;ok=true;result=Enum.CreateAssetResult.Success;break end
    if onProgress then onProgress(index,#pending,'Waiting for Roblox: '..asset.name) end
    task.wait(1)
   end
  end
  assert(ok,'Image upload: '..tostring(result))
  assert(result==Enum.CreateAssetResult.Success and id,'Roblox did not finish this upload. Retry to resume it safely: '..tostring(result))
  registry[owner..':'..asset.contentHash]='rbxassetid://'..tostring(id)
  -- Persist each success immediately so a later failure/retry never duplicates an earlier upload.
  plugin:SetSetting('ImageRegistry_v2',registry)
 end
 Assets.pending(document,plugin,Importer)
 return #pending
end
return Assets
