local Templates={}
local function valid(key)return type(key)=='string'and #key<=64 and key:match('^[A-Za-z_][A-Za-z0-9_]*$')end
function Templates.read()
 local result={};local folder=game.ServerStorage:FindFirstChild('Penpot Bridge Templates')
 if not folder or not folder:GetAttribute('P2R_TemplateRegistry')then return result end
 for _,entry in folder:GetChildren()do
  if entry:IsA('ObjectValue')and valid(entry.Name)and entry.Value and entry.Value:IsA('GuiObject')then
   result[entry.Name]={instance=entry.Value,revision=tostring(entry:GetAttribute('Revision')or 'legacy')}
  end
 end
 return result
end
function Templates.resolve(options,key)
 assert(valid(key),'Invalid template key')
 local value=(options.templates or Templates.read())[key]
 local instance=typeof(value)=='Instance'and value or type(value)=='table'and value.instance
 assert(instance and instance:IsA('GuiObject')and instance.Archivable,'Map template '..key..' to an archivable UI object in Options → Reusable UI templates.')
 return instance,type(value)=='table'and tostring(value.revision or key)or key
end
function Templates.clone(template)
 local root=template:Clone();assert(root,'Template could not be cloned')
 local function clean(i)for key in i:GetAttributes()do if key:sub(1,4)=='P2R_'then i:SetAttribute(key,nil)end end end
 clean(root);for _,i in root:GetDescendants()do clean(i)end
 return root
end
function Templates.register(key,instance)
 assert(valid(key),'Template key must be a 1–64 character identifier')
 assert(instance and instance:IsA('GuiObject')and instance.Archivable,'Select an archivable UI object to use as a template')
 local folder=game.ServerStorage:FindFirstChild('Penpot Bridge Templates')
 assert(not folder or(folder:IsA('Folder')and folder:GetAttribute('P2R_TemplateRegistry')),'An unrelated object already uses the template registry name')
 local entry=folder and folder:FindFirstChild(key)
 assert(not entry or entry:IsA('ObjectValue'),'An unrelated object already uses this template key')
 local history=game:GetService('ChangeHistoryService');local recording=history:TryBeginRecording('PenpotTemplate','Map Penpot UI template');assert(recording,'Finish the current Studio operation first')
 local ok,err=pcall(function()
  if not folder then folder=Instance.new('Folder');folder.Name='Penpot Bridge Templates';folder:SetAttribute('P2R_TemplateRegistry',true);folder.Parent=game.ServerStorage end
  if not entry then entry=Instance.new('ObjectValue');entry.Name=key;entry.Parent=folder end
  entry.Value=instance;entry:SetAttribute('Revision',game:GetService('HttpService'):GenerateGUID(false))
 end)
 history:FinishRecording(recording,ok and Enum.FinishRecordingOperation.Commit or Enum.FinishRecordingOperation.Cancel);assert(ok,err)
end
return Templates
