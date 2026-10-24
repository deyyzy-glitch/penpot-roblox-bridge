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

### Text and native opacity (2.2)

The Penpot companion offers **Auto**, **Editable**, and **Exact** text modes. Auto keeps known fonts or deliberate substitutions editable and reports substitutions. Editable keeps typography native where possible, with warnings for differences. Exact uses image surfaces for unsupported font families or complex typography. Visual effects and complex fills can require images in any mode.

**Keep suitable opacity groups native** uses CanvasGroup for clipped containers with no unsupported effects. Other containers retain the image fallback. Importing these groups into StarterGui configures the imported ScreenGui with sibling Z ordering. An existing destination ScreenGui must already use Sibling, or turn the option off and re-export. Existing Frame-to-CanvasGroup changes still require the class-change option in Studio.

### Optional scrolling and panel actions (2.2)

Enable **scrolling and panel tags** in the Penpot companion before preparing a selection. Tags are removed from displayed instance names, while source IDs stay unchanged.

| Layer name | Result |
| --- | --- |
| `Inventory [scroll]` | Vertical ScrollingFrame with automatic canvas extent |
| `Shop [panel] [closed]` | Named Shop panel, initially hidden |
| `Window [panel:Shop]` | Explicit panel name independent of displayed name |
| `Open shop [open:Shop]` | Button showing Shop |
| `Close [close]` | Button hiding its nearest tagged parent panel |
| `Close [close:Shop]` | Button hiding the named Shop panel |

Aliases `_scroll`, `_panel`, `_closed`, `_button`, `_open:Shop`, and `_close` are also accepted. Bracket tags are preferred when names already contain underscores. Panel names must be unique in a design. A missing or ambiguous target stops export; it is not guessed.

Panel actions generate one readable LocalScript owned by the importer. It reads fixed attributes and does not execute text supplied by the design. User gameplay scripts and references remain separate. Removing panel actions disables and retains the generated controller. Scrolling does not generate a script. Composited image containers cannot become scrolling containers; simplify the container effects first.

New exports require both the **2.4+ Studio plugin and helper** and use document version 4 so older plugins reject unsupported features. Legacy versions 1–3 remain supported. Extract the latest helper into a new folder, close the old helper, and run the new launcher. Re-enter your own image key locally after restarting if needed.

### Editable mixed text (2.4)

Supported mixed-style text ranges become one native RichText label. The exporter preserves range order and merges adjacent matching styles without splitting surrogate pairs. Markup characters are escaped. Supported range formatting includes mapped font families, sizes, weights, italics, solid colors/alpha, underline and strikethrough. Wrapping and font metrics still require review in Studio.

Mixed paragraph alignment/line height, nonzero letter spacing, RTL, image/gradient text fills and unknown fonts can still need an image, depending on the text mode. RichText is not an exact replacement for every Penpot typography feature. Very long/fragmented text is bounded to 8192 range reads and 2048 runs; unsupported extraction falls back with a warning.

### Design tokens and optional runtime themes (2.4)

**Preserve design-token bindings** is enabled by default. Local-file token sets, theme definitions, raw values/aliases and shape-property references travel with the document. Native design values continue to synchronize through normal reimports.

Enable **Generate a runtime theme module** to add a ModuleScript named **Penpot Theme** under the imported wrapper. It does not execute automatically. A LocalScript under that wrapper can use:

```luau
local wrapper = script.Parent
local theme = require(wrapper:WaitForChild("Penpot Theme"))
print(theme.List()) -- IDs and group/name labels
local result = theme.Apply(wrapper, "Color/Dark") -- or a theme ID
print(result.applied, result.skipped)
```

`theme.Data` retains the exported definitions, aliases and resolved palettes. A selected theme replaces its own theme group while keeping base sets and other active groups. Runtime application respects P2R_Locks and excludes retired objects and nested imports. It never executes token expressions as code.

Initial runtime mappings cover solid native fill colors, tintable icon colors, plain-text font families/sizes/weights, dimensions, rotation, supported corner radii, solid stroke colors/widths, padding and list gaps. Simple aliases and literal numeric/px values resolve per exported theme. Complex expressions, composite typography/shadows, unsupported color formats and unmapped bindings remain recorded with warnings. They are not evaluated at runtime. Connected-library catalogs are not exported in this version. RichText span formatting and colors baked into artwork need re-exporting; a whole-label theme does not replace their runs.

### Tintable icons, glows and image slicing (2.4)

After preparing a design, eligible independent images get an image-settings card. Monochrome vector/icon images are automatically checked for white-mask reuse when **Reuse monochrome icons as tintable masks** is enabled. Multicolor images retain their source colors. Alpha is unchanged, and different colors of identical mask pixels share one upload. Studio applies the original tint through ImageColor3.

Optional controls:

- **Silhouette glow:** generate a separate blurred alpha image, with radius 1–32 design pixels, color and opacity controls. It follows the prepared image's alpha, including any source effects already baked into that image. Use a shadow-free source icon for a clean new glow. The glow is baked and must be re-exported after silhouette changes.
- **RGB edge dilation:** experimental, off by default. Extends nearby RGB into transparent pixels without changing alpha. Roblox may rewrite transparent RGB during upload, so this does not guarantee fringe removal.
- **Nine-slice scaling:** enter left/top/right/bottom insets in source-image pixels. Overlapping/out-of-bounds insets block sending. A source-corner suggestion is available only when uniform corners and image bounds support it. Review three size previews before sending; arbitrary illustrations may distort when sliced.

Click **Apply image settings** after edits. Sending remains disabled while any image has unapplied settings. Compatibility fallback images, composited subtrees and generated smooth-corner tiles do not get these manual controls. The existing smooth-corner option supplies its own slice geometry. New glow assets and edited image pixels are embedded in portable bundles.

### Native effects, layouts and import quality (2.3)

Simple unequal corner radii and supported solid-color drop/inner shadows use native UICorner/UIShadow properties when Studio supports them. Compatibility PNGs are prepared alongside the design but are uploaded only when needed. Complex effects and clipped composited containers retain their image fallback. Native shadow softness can differ from Penpot; review it visually. Text shadows remain image-based.

Native row/column layouts now support center/end alignment, space-between/around/evenly, equal-gap wrapping and main-axis fill children. Wrapping requires start justification, start line alignment and equal row/column gaps. Auto-sized children, cross-axis fill, margins, min/max constraints, reversed directions, grids and other unsupported combinations keep measured desktop geometry and report the limitation.

The Studio **Review** page includes an **Import quality** report with totals and per-layer explanations: editable native appearance, image appearance, appearance covered by a parent image, smoothed surfaces, substituted fonts and native versus measured layouts. The on-screen layer list is limited to 150 entries; export a smaller selection to inspect every layer.

### Optional smoothed corners (2.3)

Choose **Smooth — 60%** or **Smooth — 100%** in the Penpot companion. This is an intentional styling change, rather than an exact reproduction of Penpot's circular corners. It applies to eligible solid surfaces with radii up to 120px, opacity 100%, no shadow/blur and at most one solid inner stroke up to 120px. Containers that clip children and scrolling containers retain their original corners. Ineligible layers are reported instead of silently changed.

Smoothed surfaces are rendered once into compact transparent 2× images, uploaded through the existing image pipeline and displayed with 9-slice scaling. Their colors and corner shape are baked; edit those in Penpot and re-export. Native children and controls stay editable. No runtime Supercorner/EditableImage library is added to the game. Corner smoothing does not introduce rounded child clipping.

Native frames, labels, buttons, supported corners/shadows, solid strokes, compatible linear gradients, measured desktop positions and supported row/column layouts. Name an element with `[button]` to create a button.

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

See [contribution guidance](CONTRIBUTING.md), [release notes](RELEASE-NOTES.md), and [third-party credits](THIRD-PARTY-NOTICES.md). Text modes/tag parsing adapt parts of figrbx; optional corner geometry adapts Supercorner/figma-squircle, with MIT notices retained. This project is independent of Roblox and Penpot.
