return function(Importer,fixtures)
 local results={};local target=Instance.new('ScreenGui');target.Name='P2R Text Weight Regression';target.Parent=game.StarterGui;local root
 local function check(name,fn)local ok,e=pcall(fn);table.insert(results,{name=name,passed=ok,error=not ok and tostring(e)or nil})end
 local function find(id)for _,i in root:GetDescendants()do if i:GetAttribute('P2R_Id')==id and not i:GetAttribute('P2R_Retired')then return i end end end
 local ok,e=pcall(function()
  root=Importer.apply(Importer.prepare(fixtures.original,target,{}));local stats=find('stats');local rich=find('rich')
  check('source weight stays native Bold by default',function()assert(stats:IsA('TextLabel')and stats.FontFace.Weight==Enum.FontWeight.Bold);assert(not find('stats::surface'))end)
  Importer.apply(Importer.prepare(fixtures.heavier,target,{}))
  check('explicit ExtraBold is editable and retains object identity',function()assert(find('stats')==stats and stats.FontFace.Weight==Enum.FontWeight.ExtraBold);assert(stats.Text=='0.58s | Luck 2.5'and stats.TextTransparency==0);assert(not find('stats::surface'))end)
  check('all mixed RichText runs receive the selected weight',function()assert(find('rich')==rich and rich.RichText);local count=0;for value in rich.Text:gmatch('weight="(%d+)"')do assert(value=='800');count+=1 end;assert(count==#fixtures.heavier.design.children[2].text.runs)end)
  check('verifier agrees with an explicit chosen weight',function()local report=Importer.verify(fixtures.heavier,target,{});for _,issue in report.issues do assert(issue.code~='design-difference',issue.message)end end)
  Importer.apply(Importer.prepare(fixtures.original,target,{}))
  check('From Penpot restores the source weight on the same object',function()assert(find('stats')==stats and stats.FontFace.Weight==Enum.FontWeight.Bold)end)
  stats.FontFace=Font.new(stats.FontFace.Family,Enum.FontWeight.Heavy,stats.FontFace.Style)
  Importer.apply(Importer.prepare(fixtures.heavier,target,{}))
  check('local Studio font edits remain protected',function()assert(stats.FontFace.Weight==Enum.FontWeight.Heavy)end)
  Importer.apply(Importer.prepare(fixtures.image,target,{force=true}))
  check('image conversion uses original artwork and hides its retained native text',function()assert(find('stats')==stats and stats.TextTransparency==1);assert(find('stats::surface'));assert(fixtures.image.design.children[1].text.weight==700)end)
 end)
 if not ok then table.insert(results,{name='fixture setup',passed=false,error=tostring(e)})end
 target:Destroy();return results
end
