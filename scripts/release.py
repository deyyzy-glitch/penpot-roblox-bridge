"""Create allowlisted source/helper releases; never package local state."""
from pathlib import Path
import hashlib,io,json,re,sys,urllib.request,zipfile

ROOT=Path(__file__).resolve().parents[1]
DIST=ROOT/'dist'
VERSION=json.loads((ROOT/'package.json').read_text(encoding='utf-8-sig'))['version']
ROOT_FILES={'README.md','LICENSE','THIRD-PARTY-NOTICES.md','CONTRIBUTING.md','RELEASE-NOTES.md','package.json','build.mjs','assets.mjs','Start-Bridge.ps1','Start-Penpot-Bridge.cmd','.gitignore'}
FOLDERS={'studio','penpot','bridge','tests','scripts','.github'}

def files():
    for p in sorted(ROOT.rglob('*')):
        rel=p.relative_to(ROOT)
        if not p.is_file() or any(part in {'.git','.asset-cache','node_modules','__pycache__','dist','runtime'} for part in rel.parts):continue
        if len(rel.parts)==1 and rel.name in ROOT_FILES:yield p,rel
        elif rel.parts[0] in FOLDERS and p.suffix in {'.js','.mjs','.luau','.html','.py','.yml','.md','.json'}:yield p,rel

def checked_windows_runtime():
    base='https://nodejs.org/dist/latest-v24.x/'
    with urllib.request.urlopen(base+'SHASUMS256.txt',timeout=60) as r:checks=r.read().decode()
    match=re.search(r'^([a-f0-9]{64})\s+(node-v24\.[0-9]+\.[0-9]+-win-x64\.zip)$',checks,re.M)
    if not match:raise RuntimeError('No official Node 24 Windows x64 archive in checksum list')
    digest,name=match.groups()
    with urllib.request.urlopen(base+name,timeout=120) as r:data=r.read()
    if hashlib.sha256(data).hexdigest()!=digest:raise RuntimeError('Node runtime checksum mismatch')
    with zipfile.ZipFile(io.BytesIO(data)) as z:
        prefix=name[:-4]+'/'
        return {'runtime/node.exe':z.read(prefix+'node.exe'),'runtime/NODE-LICENSE.txt':z.read(prefix+'LICENSE')}

def build(windows=False):
    DIST.mkdir(exist_ok=True)
    source=DIST/f'PenpotBridge-{VERSION}-Source.zip'
    with zipfile.ZipFile(source,'w',zipfile.ZIP_DEFLATED) as z:
        for p,rel in files():z.write(p,'PenpotBridge/'+rel.as_posix())
    (DIST/'PenpotRoblox.rbxmx').write_bytes((ROOT/'PenpotRoblox.rbxmx').read_bytes())
    outputs=[source,DIST/'PenpotRoblox.rbxmx']
    if windows:
        target=DIST/'PenpotBridge-Windows-x64.zip'
        runtime=checked_windows_runtime()
        with zipfile.ZipFile(target,'w',zipfile.ZIP_DEFLATED) as z:
            for p,rel in files():
                if rel.parts[0] in {'bridge','penpot'} or rel.name in {'README.md','LICENSE','THIRD-PARTY-NOTICES.md','package.json','Start-Penpot-Bridge.cmd','RELEASE-NOTES.md'}:z.write(p,'PenpotBridge/'+rel.as_posix())
            for name,data in runtime.items():z.writestr('PenpotBridge/'+name,data)
        outputs.append(target)
    checks=DIST/'SHA256SUMS.txt'
    checks.write_text(''.join(hashlib.sha256(p.read_bytes()).hexdigest()+'  '+p.name+'\n' for p in outputs),encoding='utf-8')
    for p in outputs:
        if p.suffix=='.zip':
            with zipfile.ZipFile(p) as z:
                assert not any(any(part in {'.asset-cache','.git','.env'} for part in Path(n).parts) for n in z.namelist())
                assert z.testzip() is None
        print(f'{p.name}: {p.stat().st_size} bytes')

if __name__=='__main__':build('--windows' in sys.argv)
