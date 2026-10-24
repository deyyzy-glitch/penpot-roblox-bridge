$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'Penpot Bridge — keep this window open while importing'
Write-Host 'Penpot Bridge connects Penpot to Roblox Studio on this PC.'
Write-Host 'Keep this window open while transferring designs or uploading new images.'
Write-Host 'Status and image setup: http://127.0.0.1:43129/setup'
Write-Host 'If Studio asks to contact 127.0.0.1, that address is this PC.'
$taskNodeCommand = Get-Command node -ErrorAction SilentlyContinue
$taskNodePath = if ($taskNodeCommand) { $taskNodeCommand.Source } else { Join-Path $env:USERPROFILE '.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' }
if (-not (Test-Path -LiteralPath $taskNodePath)) { throw 'Install Node.js 22 or newer, then run this script again.' }
& $taskNodePath (Join-Path $PSScriptRoot 'build.mjs')
if ($LASTEXITCODE -ne 0) { throw 'Build failed.' }
& $taskNodePath (Join-Path $PSScriptRoot 'bridge\server.mjs')
