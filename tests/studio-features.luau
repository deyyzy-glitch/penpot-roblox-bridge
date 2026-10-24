return function(Importer,fixture)
 local Http=game:GetService('HttpService')
 local function clone(v)return Http:JSONDecode(Http:JSONEncode(v))end
 local results={}
 local function check(name,fn)local ok,e=pcall(fn);table.insert(results,{name=name,passed=ok,error=not ok and tostring(e)or nil})end
 local target=Instance.new('ScreenGui');target.Name='P2R Feature Sandbox';target.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;target.Parent=game.StarterGui
 local d=clone(fixture);local root,group,controller,scroll,userScript,reference
 local function byId(id)for _,i in root:GetDescendants()do if i:GetAttribute('P2R_Id')==id and not i:GetAttribute('P2R_Retired')then return i end end end
 check('Native group composites once and keeps controls editable',function()
  root=Importer.apply(Importer.prepare(d,target,{}));group=byId('shop')
  assert(group:IsA('CanvasGroup'));assert(math.abs(group.GroupTransparency-.4)<.001);assert(group.BackgroundTransparency==0);assert(byId('close').BackgroundTransparency==0);assert(group.Visible==false)
 end)
 check('Scrolling container and generated panel controller are native',function()
  scroll=byId('inventory');assert(scroll:IsA('ScrollingFrame'));assert(scroll.AutomaticCanvasSize==Enum.AutomaticSize.Y)
  controller=byId('features::controller');assert(controller:IsA('LocalScript') and not controller.Disabled);assert(controller.Source:find('Activated:Connect',1,true));assert(byId('open'):GetAttribute('P2R_Target')=='Shop');assert(byId('close'):GetAttribute('P2R_Action')=='close')
  userScript=Instance.new('LocalScript');userScript.Name='User Gameplay';userScript.Source='-- user-owned';userScript.Parent=group
  reference=Instance.new('ObjectValue');reference.Value=group;reference.Parent=target
 end)
 check('Feature reimport is idempotent and preserves references and scripts',function()
  local plan=Importer.prepare(d,target,{});assert(plan.stats.added==0 and plan.stats.updated==0 and plan.stats.conflicts==0,Http:JSONEncode(plan.stats));Importer.apply(plan)
  assert(byId('shop')==group and byId('features::controller')==controller and reference.Value==group and userScript.Parent==group)
 end)
 check('Turning behaviors off disables retained controller and clears actions',function()
  d.options.behaviors=false;local plan=Importer.prepare(d,target,{allowClassChanges=true});Importer.apply(plan)
  assert(controller.Disabled and controller:GetAttribute('P2R_Stale'));assert(byId('open'):GetAttribute('P2R_Action')=='');assert(not userScript.Disabled)
 end)
 check('Turning behaviors back on reuses and enables its controller',function()
  d.options.behaviors=true;Importer.apply(Importer.prepare(d,target,{allowClassChanges=true}));assert(byId('features::controller')==controller and not controller.Disabled and not controller:GetAttribute('P2R_Stale'))
 end)
 check('Action target validation rejects malformed input without mutation',function()
  local bad=clone(d);bad.design.children[1].behavior.target='Missing';local count=#target:GetDescendants();assert(not pcall(function()Importer.prepare(bad,target,{})end));assert(count==#target:GetDescendants())
 end)
 check('CanvasGroup refuses incompatible existing ScreenGui ordering',function()
  local other=Instance.new('ScreenGui');other.ZIndexBehavior=Enum.ZIndexBehavior.Global;other.Parent=game.StarterGui;local ok=pcall(function()Importer.prepare(d,other,{})end);assert(not ok and #other:GetChildren()==0);other:Destroy()
 end)
 target:Destroy();return results
end
