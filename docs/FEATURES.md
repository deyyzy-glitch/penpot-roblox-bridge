# Feature guide

[Back to setup](../README.md) · [Troubleshooting](TROUBLESHOOTING.md)

## Layer controls, references and templates

In Penpot, open **Layers** and click **Read selection layers**. Search for a layer, then choose Auto, Native, Image, Layout only, Skip subtree, or Reusable template. Choices are saved in browser storage per Penpot file and source layer ID; changing a choice requires preparing again. They do not modify the design or automatically transfer to another person's browser.

Text layers also have **Font weight**. **From Penpot** is the default; choose a weight such as **ExtraBold (800)** to adjust native text while keeping it editable. The choice applies to all styled runs in that text layer. Choose **From Penpot** to restore the source weights. Weight overrides do not alter Penpot or image exports, and are disabled in Image/Layout/Skip/Template modes. Available weights depend on the Roblox font family. An explicit weight takes precedence over that layer's font-weight token binding; its other token bindings remain available.

In **Layers**, clear button names such as `UpgradeButton`, `Buy_btn` and `BtnBuy` can show **Button suggested**, with the naming reason. Nothing changes unless you click **Accept button**. Acceptance is saved per file/source layer ID, keeps the source design untouched, and requires preparing again. The existing Studio importer creates the appropriate TextButton or ImageButton; add your gameplay logic separately. **Use default control** removes the accepted choice. **Dismiss** hides a suggestion locally for that file/layer/name without invalidating a prepared design. Suggestions skip text/decorative labels, explicit behavior tags, explicit conversion modes, and children flattened or excluded by a parent. Saved choices remain inactive in Image/Layout/Skip/Template conversions or inside flattened parents.

- **Auto** keeps the normal fidelity policy. **Native** requests editable conversion and rejects geometry/effects that cannot be preserved; font substitutions remain reported. **Image** flattens that layer's visual subtree, retaining covered descendant geometry and controls.
- **Layout only** omits the layer's own appearance and retains child content. **Skip subtree** omits the layer and descendants; previous imported instances are hidden and retained even with Hide removed disabled.
- **Reusable template** replaces the source subtree with a clone of a mapped Roblox GuiObject. It takes placement, size, visibility, rotation and ordering from the design; appearance, children and scripts come from the template.

An optional gameplay reference such as `UpgradeButton` generates **Penpot References** under the imported wrapper. Alternatively enable **Settings → Gameplay references** for source-ID lookup without named aliases. Use a LocalScript in your game:

```luau
local wrapper = script.Parent
local references = require(wrapper:WaitForChild("Penpot References"))
local button = references.Get(wrapper, "UpgradeButton")
button.Activated:Connect(function()
    -- Your gameplay code goes here.
end)
-- references.Bind(wrapper) returns ById, Named, and Missing tables.
```

References use source IDs and survive renames and moves inside the wrapper. Rebind after an approved class/template replacement to obtain the new instance. Missing or duplicate identities produce explicit results/errors; this module does not write gameplay logic.

In Studio, select your existing template GuiObject in Explorer, open **Templates**, enter a key such as `PrimaryButton`, and click **Map selected component**. Use the same key in Penpot. Mappings are stored in this place's ServerStorage registry, not on GitHub or in your helper. Clones preserve your template children and scripts and remove copied importer ownership attributes. Only use templates whose scripts you intend to run in the finished game. Mapping again refreshes its revision; existing clones are replaced only after reviewing and enabling **Allow object replacement**. Previous instances remain retained, with retired template scripts disabled to avoid duplicate execution. Ordinary reimports preserve clone identity and local edits.

## Verify import

The Studio plugin's **Verify** page includes **Verify import**. Receive the same design or open its uploaded bundle first, select an imported container if there are several copies, then click Verify import. The received design stays available for the current plugin session; receive it again after restarting Studio. Verification compares that export, not unsent edits still in Penpot.

Findings check imported identities, classes, parenting, engine-normalized properties (including fonts and image references), visible text fitting, image loading, and new overlaps between previously separate siblings. Click a finding to select the affected object or the nearest available imported parent. Verification does not change or repair the imported UI. Local changes and locks are informational; missing image references remain errors. Declared font substitutions are notes, not proof of identical glyph appearance.

This is programmed verification and needs no AI account. It does not compare screenshots, prove pixel-perfect fidelity, or establish whether a not-yet-loaded image is permanently unavailable. Hidden text is skipped. New-overlap checks exclude intentional design overlaps, rotated groups and scrolling regions, and stop after 10,000 sibling pairs. The panel shows the first 150 findings; resolve those and verify again for further findings.

## Native uniform grids

**Settings → Native uniform grids** is off by default. Prepare the design using the updated Penpot companion so its native grid metadata is included, then enable this option in Studio and review the import. Compatible Penpot grids become `UIGridLayout` plus `UIPadding`, with fixed pixel cell sizes, gaps, row/column flow and spatial ordering. The toggle does not guess grids from arbitrary groups of rectangles. Re-exporting is unnecessary when toggling an already-received design that includes grid metadata.

Only equal-size, visible, unrotated, fixed-size cells in a contiguous top-left grid are eligible. Spans, empty intermediate cells, offsets, absolute children, dynamic sizing, margins, complex container effects and irregular placement keep measured positions, with an explanation in Review. Cell content can still contain text, icons and image surfaces. Native layout controls direct child sizes and positions, including slots added locally; it is an editing convenience rather than a promise of better visual fidelity. Narrower containers can wrap cells differently.

Turning the option off and reimporting restores measured placement. Removed grid components are retained outside the rendered hierarchy, preserving slot instances and references. The verifier uses the same option as import. Existing bundles without grid metadata continue importing with measured positions.

## What imports

### Text and native opacity

The Penpot companion offers **Auto**, **Editable**, and **Exact** text modes. Auto keeps known fonts or deliberate substitutions editable and reports substitutions. Editable keeps typography native where possible, with warnings for differences. Exact uses image surfaces for unsupported font families or complex typography. Visual effects and complex fills can require images in any mode.

**Keep suitable opacity groups native** uses CanvasGroup for clipped containers with no unsupported effects. Other containers retain the image fallback. Importing these groups into StarterGui configures the imported ScreenGui with sibling Z ordering. An existing destination ScreenGui must already use Sibling, or turn the option off and re-export. Existing Frame-to-CanvasGroup changes still require the class-change option in Studio.

### Optional scrolling and panel actions

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

### Editable mixed text

Supported mixed-style text ranges become one native RichText label. The exporter preserves range order and merges adjacent matching styles without splitting surrogate pairs. Markup characters are escaped. Supported range formatting includes mapped font families, sizes, weights, italics, solid colors/alpha, underline and strikethrough. Wrapping and font metrics still require review in Studio.

Mixed paragraph alignment/line height, nonzero letter spacing, RTL, image/gradient text fills and unknown fonts can still need an image, depending on the text mode. RichText is not an exact replacement for every Penpot typography feature. Very long/fragmented text is bounded to 8192 range reads and 2048 runs; unsupported extraction falls back with a warning.

### Design tokens and optional runtime themes

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

### Tintable icons, glows and image slicing

After preparing a design, eligible independent images get an image-settings card. Monochrome vector/icon images are automatically checked for white-mask reuse when **Reuse monochrome icons as tintable masks** is enabled. Multicolor images retain their source colors. Alpha is unchanged, and different colors of identical mask pixels share one upload. Studio applies the original tint through ImageColor3.

Optional controls:

- **Silhouette glow:** generate a separate blurred alpha image, with radius 1–32 design pixels, color and opacity controls. It follows the prepared image's alpha, including any source effects already baked into that image. Use a shadow-free source icon for a clean new glow. The glow is baked and must be re-exported after silhouette changes.
- **RGB edge dilation:** experimental, off by default. Extends nearby RGB into transparent pixels without changing alpha. Roblox may rewrite transparent RGB during upload, so this does not guarantee fringe removal.
- **Nine-slice scaling:** enable slicing, then drag the four blue guides over the source image or enter left/top/right/bottom insets in source-image pixels. The three stretch previews update as you adjust the guides. Arrow keys move a focused guide by one source pixel; Shift moves ten. Dragging stops before guides cross; invalid numeric insets block applying. A source-corner suggestion is available only when uniform corners and image bounds support it. Click **Apply image settings** to save the changes before sending; arbitrary illustrations may distort when sliced.

Click **Apply image settings** after edits. Sending remains disabled while any image has unapplied settings. Compatibility fallback images, composited subtrees and generated smooth-corner tiles do not get these manual controls. The existing smooth-corner option supplies its own slice geometry. New glow assets and edited image pixels are embedded in portable bundles.

In the slice editor, **Link Left / Right** or **Link Top / Bottom** keeps opposite insets equal while dragging, typing, or using arrow keys. Enabling a link matches Right to Left or Bottom to Top. **Reset slice guides** returns all four insets to zero while keeping slicing enabled, retaining the link choices, and leaving tint, glow and other image settings alone. Reset changes remain pending until applied.

### Native effects, layouts and import quality

Simple unequal corner radii and supported solid-color drop/inner shadows use native UICorner/UIShadow properties when Studio supports them. Compatibility PNGs are prepared alongside the design but are uploaded only when needed. Complex effects and clipped composited containers retain their image fallback. Native shadow softness can differ from Penpot; review it visually. Text shadows remain image-based.

Native row/column layouts now support center/end alignment, space-between/around/evenly, equal-gap wrapping and main-axis fill children. Wrapping requires start justification, start line alignment and equal row/column gaps. Auto-sized children, cross-axis fill, margins, min/max constraints, reversed directions, irregular grids and other unsupported combinations keep measured desktop geometry and report the limitation.

The Studio **Review** page includes an **Import quality** report with totals and per-layer explanations: editable native appearance, image appearance, appearance covered by a parent image, smoothed surfaces, substituted fonts and native versus measured layouts. The on-screen layer list is limited to 150 entries; export a smaller selection to inspect every layer.

### Optional smoothed corners

Choose **Smooth — 60%** or **Smooth — 100%** in the Penpot companion. This is an intentional styling change, rather than an exact reproduction of Penpot's circular corners. It applies to eligible solid surfaces with radii up to 120px, opacity 100%, no shadow/blur and at most one solid inner stroke up to 120px. Containers that clip children and scrolling containers retain their original corners. Ineligible layers are reported instead of silently changed.

Smoothed surfaces are rendered once into compact transparent 2× images, uploaded through the existing image pipeline and displayed with 9-slice scaling. Their colors and corner shape are baked; edit those in Penpot and re-export. Native children and controls stay editable. No runtime Supercorner/EditableImage library is added to the game. Corner smoothing does not introduce rounded child clipping.

Native frames, labels, buttons, supported corners/shadows, solid strokes, compatible linear gradients, measured desktop positions and supported row/column layouts. Name an element with `[button]` to create a button.

Vectors, image fills and effects that Roblox cannot reproduce use transparent image surfaces. Complex typography and composited group effects can also use surfaces while keeping native controls and geometry. Baked visuals are changed in Penpot and re-exported; they are not editable native effects. Images use up to 2× resolution capped at 1024 pixels per dimension. Complex flex/grid uses measured positions. Desktop workflow only; automatic mobile redesign is outside scope.

Reimport the same source board to update compatible instances. Local managed-property edits are preserved and reported. `P2R_Locks` accepts comma-separated property names or `*`. Removed objects are retained. Force and class-change options are explicit; changing classes retains the old instance and may require reconnecting references. Each apply uses Studio undo recording.

## Native linear-gradient colors

The importer adds RGB-linear intermediate color samples to reduce the bright midpoint produced by the tested legacy Roblox UI renderer. Original authored stops and transparency are preserved, with a target of at most six color stops; existing sequences already above six keep their original stops. No additional UI objects or image uploads are needed. Colors remain an approximation, and complex geometry still uses images.

Five Penpot-export comparisons in a Studio-hosted running client showed lower average channel error for red/blue, black/white, pastel, three-stop and varying-alpha gradients. This does not establish pixel-perfect output on every platform. Advanced gradient shapes continue using PNG fallback; the importer does not require users to enable a Studio beta.
