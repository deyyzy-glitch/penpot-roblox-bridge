-- Run on the exact container selected for publication, then on a fresh LoadAsset result.
return function(root,version)
 assert(root:IsA('Script'),'Plugin entry point must be a Script')
 assert(root.Enabled and not root.Disabled,'Plugin entry script is disabled; enabling the package will not start it')
 assert(root:GetAttribute('Version')==version,'Unexpected plugin package version')
 for _,name in {'UI','Importer','Assets','Behaviors','RichText','Themes'}do
  local m=root:FindFirstChild(name)
  assert(m and m:IsA('ModuleScript')and #m.Source>0,'Missing packaged module: '..name)
 end
 return true
end
