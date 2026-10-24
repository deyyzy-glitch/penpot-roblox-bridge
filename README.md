# Penpot Bridge

Import Penpot boards into Roblox Studio UI, review changes, and synchronize updates while preserving local edits and native object references. Open source under the MIT license.

## Get started on Windows

1. Install [Penpot Bridge in Roblox Studio](https://create.roblox.com/store/asset/129957195606923).
2. [Download the desktop helper](https://github.com/deyyzy-glitch/penpot-roblox-bridge/releases/latest/download/PenpotBridge-Windows-x64.zip). Extract the entire ZIP, then double-click **Start-Penpot-Bridge.cmd**. Node.js is bundled; no separate installation is needed.
3. Keep its **Penpot Bridge** window open while importing. The setup page opens in your browser and shows whether image uploads are ready.
4. In Penpot's Plugin Manager, add `http://127.0.0.1:43129/manifest.json` and open **Penpot to Roblox**.
5. Select one board or group. Click **Prepare selected design**, then **Send to Studio**.
6. In Studio, open **Plugins → Penpot Bridge**, choose **Receive from Penpot**, **Review import**, then **Import design**.

If Roblox asks to contact **127.0.0.1**, it is asking to contact the helper on your own PC. Allow that connection to transfer designs. Your finished game does not need the helper.

The Windows download is a portable application, not an installer or a tray app. It does not automatically start at login. Run its launcher again after restarting your computer. Each person runs their own helper and uses their own Roblox credentials. No developer key is bundled.

## Automatic images

This Studio build does not support native image asset creation. The helper uses Roblox's official Open Cloud Assets API as a fallback. Open `http://127.0.0.1:43129/setup` and enter your own **Assets Read/Write** key for the account signed into Studio. The key stays in helper memory and is sent only to Roblox. Closing the helper clears it. Never put keys in GitHub issues or source files.

The helper caches image hashes and completed upload IDs per creator. Unchanged images reuse their IDs. Pending operations resume rather than creating duplicate uploads. Roblox still controls moderation, upload quotas and asset permissions. Group-owned games require permission to upload for the group.

## What imports

Native frames, labels, buttons, uniform corners, solid strokes, compatible linear gradients, measured desktop positions and simple row/column layouts. Name an element with `[button]` to create a button.

Vectors, image fills and effects that Roblox cannot reproduce use transparent image surfaces. Complex typography and composited group effects can also use surfaces while keeping native controls and geometry. Baked visuals are changed in Penpot and re-exported; they are not editable native effects. Images use up to 2× resolution capped at 1024 pixels per dimension. Complex flex/grid uses measured positions. Desktop workflow only; automatic mobile redesign is outside scope.

Reimport the same source board to update compatible instances. Local managed-property edits are preserved and reported. `P2R_Locks` accepts comma-separated property names or `*`. Removed objects are retained. Force and class-change options are explicit; changing classes retains the old instance and may require reconnecting references. Each apply uses Studio undo recording.

## Troubleshooting

- **Helper unreachable:** launch Start-Penpot-Bridge.cmd and keep its window open; check the plugin's HTTP permission if you denied the address.
- **Address already in use:** a helper may already be running. Open the setup page and check its status before starting another.
- **No design received:** prepare and send a selection from the Penpot companion first.
- **Images need setup:** enter your own key on the setup page. Do this again after restarting the helper.
- **Old plugin interface:** update the inventory plugin and restart Studio. Install one plugin copy; do not put the whole GitHub source folder into Studio's Plugins folder.

## Run from source (Windows, macOS, Linux)

Install Node.js 22 or newer. There are no npm dependencies.

```sh
node build.mjs
node bridge/server.mjs
```

Follow the Penpot/Studio steps above. A generated PenpotRoblox.rbxmx is also available as a release asset for manual local plugin installation.

## Develop and release

```sh
node build.mjs
node --test --test-isolation=none tests/bridge.test.mjs tests/exporter.test.mjs tests/cloud.test.mjs
python scripts/release.py
```

`python scripts/release.py --windows` also downloads an official Node.js 24 Windows x64 runtime, verifies its SHA-256 against Node's published checksum list, and includes its license. The workflow builds and publishes release assets when package.json gains a new version on main. Source archives and releases exclude credentials, local caches and game files.

See [contribution guidance](CONTRIBUTING.md) and [release notes](RELEASE-NOTES.md). This project is independent of Roblox and Penpot.
