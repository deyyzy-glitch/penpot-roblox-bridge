return function(Importer,fixture,gridFixture)
 local Http=game:GetService('HttpService');local results={}
 local function copy(v)return Http:JSONDecode(Http:JSONEncode(v))end
 local function check(name,fn)local ok,e=pcall(fn);table.insert(results,{name=name,passed=ok,error=not ok and tostring(e)or nil})end
 local target=Instance.new('ScreenGui');target.Name='P2R Layer Controls Regression';target.Parent=game.StarterGui
 local template=Instance.new('TextButton');template.Name='Template definition';template.Text='Authored button';template.BackgroundColor3=Color3.fromRGB(40,180,80);template:SetAttribute('UserData','kept');template:SetAttribute('P2R_Id','unrelated-owner')
 local label=Instance.new('TextLabel');label.Name='Authored child';label:SetAttribute('P2R_Id','unrelated-child');label.Parent=template
 local script=Instance.new('LocalScript');script.Name='Authored controller';script.Source='-- Template gameplay code';script.Parent=template
 local options={templates={PrimaryButton={instance=template,revision='1'}}}
 local d=copy(fixture);d.version=5;d.assets={};d.assetMap={};d.design.children={d.design.children[1],d.design.children[2]}
 local layout=d.design.children[1];layout.importMode='layout';layout.visualSuppressed=true;layout.ref='Layout';layout.children={}
 local slot=d.design.children[2];slot.importMode='template';slot.template='PrimaryButton';slot.ref='UpgradeButton';slot.children={}
 local wrapper,button,refs
 local function find(id)for _,i in wrapper:GetDescendants()do if i:GetAttribute('P2R_Id')==id and not i:GetAttribute('P2R_Retired')then return i end end end
 local ok,e=pcall(function()
  check('unmapped templates fail without modifying destination',function()local success=pcall(Importer.prepare,d,target,{templates={}});assert(not success and #target:GetChildren()==0)end)
  wrapper=Importer.apply(Importer.prepare(d,target,options));button=find(slot.id);refs=require(wrapper['Penpot References'])
  check('template clones preserve authored appearance, children and scripts',function()assert(button~=template and button:IsA('TextButton')and button.Text=='Authored button');assert(button:FindFirstChild('Authored child')and button:FindFirstChild('Authored controller'));assert(button:GetAttribute('UserData')=='kept')end)
  check('cloned children do not retain unrelated importer ownership',function()assert(button['Authored child']:GetAttribute('P2R_Id')==nil);assert(button:GetAttribute('P2R_Id')==slot.id and template:GetAttribute('P2R_Id')=='unrelated-owner')end)
  check('Layout only converts text to an invisible visual container',function()local i=find(layout.id);assert(i:IsA('Frame')and i.BackgroundTransparency==1)end)
  check('named and source-ID references bind to imported instances',function()local b=refs.Bind(wrapper);assert(b.Named.UpgradeButton==button and b.ById[slot.id]==button and #b.Missing==0)end)
  check('references survive local renames and reparenting',function()local parent=button.Parent;button.Name='Renamed';button.Parent=find(layout.id);assert(refs.Get(wrapper,'UpgradeButton')==button);button.Parent=parent end)
  check('ordinary reimport retains template clone and local descendants',function()local child=Instance.new('Frame');child.Name='User child';child.Parent=button;Importer.apply(Importer.prepare(d,target,options));assert(find(slot.id)==button and child.Parent==button)end)
  check('template revision changes require reviewed replacement',function()options.templates.PrimaryButton.revision='2';local p=Importer.prepare(d,target,options);assert(p.stats.classChanges==1);assert(not pcall(Importer.apply,p));assert(find(slot.id)==button)end)
  check('approved replacement retains old instance, disables retired template scripts and rebinds aliases',function()options.allowClassChanges=true;local old=button;Importer.apply(Importer.prepare(d,target,options));button=find(slot.id);assert(button~=old and old.Parent and old:GetAttribute('P2R_Retired')and not old.Visible);assert(old['Authored controller'].Disabled and not button['Authored controller'].Disabled);assert(refs.Get(wrapper,'UpgradeButton')==button)end)
  check('template metadata changes are visible to verification',function()local old=button:GetAttribute('P2R_TemplateRevision');button:SetAttribute('P2R_TemplateRevision','wrong');local r=Importer.verify(d,target,options);button:SetAttribute('P2R_TemplateRevision',old);local found=false;for _,issue in r.issues do if issue.code=='metadata-difference'then found=true end end;assert(found)end)
  check('explicit Skip hides and retains objects with hideRemoved disabled',function()local removed=copy(d);removed.design.children={removed.design.children[1]};removed.excludedIds={slot.id};Importer.apply(Importer.prepare(removed,target,options));assert(button.Parent and button:GetAttribute('P2R_Stale')and not button.Visible);assert(#refs.Bind(wrapper).Missing==1)end)
  check('restoring a skipped template retains its instance and reference',function()Importer.apply(Importer.prepare(d,target,options));assert(find(slot.id)==button and button.Visible and refs.Get(wrapper,'UpgradeButton')==button)end)
  check('native-grid template cells follow spatial order',function()local grid=copy(gridFixture);grid.version=5;for _,n in grid.design.children do n.importMode='template';n.template='PrimaryButton';n.children={}end;local opt={nativeGrids=true,templates=options.templates};local w=Importer.apply(Importer.prepare(grid,target,opt));task.wait(.2);for _,i in w:GetDescendants()do if i:GetAttribute('P2R_Template')then assert(i.LayoutOrder>=1 and i.LayoutOrder<=5)end end;assert(w:FindFirstChildWhichIsA('UIGridLayout',true))end)
 end)
 target:Destroy();template:Destroy();if not ok then table.insert(results,{name='integration setup',passed=false,error=tostring(e)})end
 return results
end
