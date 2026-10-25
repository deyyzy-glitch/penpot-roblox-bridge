# Penpot Bridge 2.6.0

- Added optional per-layer Auto, Native, Image, Layout only, Skip subtree and Reusable template controls in the Penpot companion. Choices persist locally per file/layer; preparing again applies them. Native mode rejects unsupported fidelity instead of silently discarding effects. Explicit skips hide and retain old imports.
- Added named gameplay references and optional source-ID reference modules. Reference lookup survives renames/reparenting and rebinds to new instances after reviewed replacements. Gameplay code stays in your own scripts.
- Added place-local reusable UI template mappings in Studio Options. Clones retain authored appearance, children and scripts while source geometry controls placement. Mapping revisions require reviewed replacement; retired template scripts are disabled. Unmapped keys fail before import mutation.
- Improved native linear-gradient color fidelity through bounded RGB-linear samples, preserving authored stops and opacity. Five actual Penpot PNG versus running-client comparisons improved mean channel error: red/blue 29.30→2.58, black/white 43.87→3.11, pastel 2.05→0.55, three stops 9.48→2.48, varying alpha 17.75→1.75 (0–255 channel scale, sampled horizontal center lines excluding edges). This is an approximation, not a cross-platform guarantee.
- Advanced gradients retain PNG fallback. Roblox's appearance guide identifies Type/Scale/TileMode as part of the Upgraded UIGradients Studio beta. The tested configuration rendered them as linear; no beta setting is changed by this plugin.
- Fixed generated-plugin packaging so literal Luau pattern characters survive support-module inlining.

Validation: 51 Node tests and 61 Studio checks (11 gradient, 13 layer/template/reference, 18 verifier and 19 grid/real-export). The running-client color investigation used known solid RGB swatches and five actual Penpot gradient exports. Temporary design/Studio test objects were removed afterward. Update both helper and Studio plugin for the new layer controls (document version 5); old version 1–4 bundles remain supported. No prototype-navigation expansion or framework-output backend is included.

# Penpot Bridge 2.5.0

- Added **Options → Use native uniform grids**, off by default. Updated Penpot exports retain grid metadata; compatible grids create native UIGridLayout and padding, while unsafe grids keep measured positions with a review warning. Toggling off retires layout components outside the rendered hierarchy and preserves slot instances.
- Added two reduced real Penpot export fixtures with anonymized source IDs and placeholder image mappings: the Fredoka Mine panel and padded SVG header chart. No image pixels, original uploaded IDs or credentials are included. These add structural/conversion regressions rather than visual screenshot assertions.

- The Design tab includes Verify import, using the received design or bundle as its reference. It checks imported identities, object classes, parenting, converted properties, fonts, missing image references, visible text overflow, image loading and newly overlapping siblings.
- Local edits and locks are informational. Declared font substitutions are notes; missing image references remain errors. Findings select affected objects without repairing or overwriting them.
- The verifier requires no AI or additional account. Receive the design again after restarting Studio. This is not a screenshot comparison; image-loading warnings can be temporary. Rotated/scrolling overlap checks are excluded and large overlap scans are bounded.

Validation: 40 Node tests, 37 Studio regression checks (18 verifier and 19 grid/real-export checks), a findings-panel and object-selection smoke check, and 2,071 checks against a saved real Stats export in a disposable Studio sandbox (zero property errors; 13 declared font substitution notes and 12 image-not-yet-loaded warnings). Update both the helper and Studio plugin, restart Studio and reopen the Penpot companion. Existing version 1–4 bundles remain supported.

# Penpot Bridge 2.4.2

- Individual rectangles, text, ellipses, paths, Boolean shapes, SVG artwork and image layers can now be prepared directly. Grouping them first is no longer required.
- Selection prompts now describe layers, groups and boards. Selecting multiple layers still requires grouping them first.
- Original layer identities and dimensions are retained, and standalone imports start at their own local origin.

Validation: 34 automated tests pass, including standalone layer types, identity, geometry and raster asset routing. The running helper served the corrected exporter. Live Penpot MCP inspection was unavailable.

Download the updated helper and reopen Penpot to Roblox. Studio plugin 2.4.1 remains compatible and requires no update for this fix. Credentials and local caches are excluded from downloads.

# Penpot Bridge 2.4.1

- Preparation reports the current layer and export format. Time limits release the Prepare button when Penpot or the helper stops responding, and late responses cannot replace a newer preparation.
- Eligible shapes use Penpot's local SVG markup and browser rasterization, avoiding stalled remote SVG/PNG renderers. Page bounds are converted to layer coordinates. SVGs needing external resources or text rendering retain the remote path or report an explicit limitation.
- Definition-only transparent SVG nodes no longer require empty image uploads. Imported SVG fills missing from Penpot's normal fill properties retain their appearance through image surfaces.
- Fredoka and Nunito Sans have explicit editable substitutions to Roblox Fredoka One and Nunito. Exact mode still preserves the image-fidelity policy.
- Native text strokes follow glyphs instead of drawing a rectangle around the label.
- The companion requests library read permission for tokens; older installations without that permission can still prepare current visual values with a warning.

Validation: 33 automated tests, browser SVG pixel/alpha/bounds checks, and a real detailed-board import in Studio. The board retained 26 editable labels and 66 image surfaces; repeat import reported zero changes or conflicts.

Update both the helper and Studio plugin. Stop the previous helper before launching the new download, restart Studio, and reopen the Penpot companion. Update or reinstall the Penpot companion from the helper manifest and approve library read access to enable token export. Re-enter your own upload key locally after restarting the helper if new images are needed. No credentials, local caches, test game or design files are included.

## 2.4.0

- Mixed-style text exports as editable RichText runs with escaped markup, Unicode-safe boundaries, font mapping, sizes, weights, colors, transparency and decorations. Unsupported typography retains image fallback.
- Local-file token sets, raw values, aliases, themes and shape bindings are retained. An optional Penpot Theme ModuleScript applies supported native properties only when your game calls it.
- Monochrome icon masks reuse uploaded pixels across color variants and keep ImageColor3 editable.
- Prepared-image controls add optional silhouette glows, experimental RGB edge dilation, explicit nine-slice insets, source-corner suggestions and three size previews.
- Invalid slice settings block sending. Processed images and separate glow pixels travel in portable bundles.
- Unfilled containers no longer receive a rectangular native shadow for a content silhouette; composited effects keep their image fallback.
- Document version 4; legacy versions 1–3 still import. Existing third-party notices remain included. New text/token/pixel integration code was independently implemented.

Validation: 22 Node tests, 38 Studio checks, a companion prepare/edit/send/bundle check, and a client Play-mode RichText/theme-switching check. Uploaded-image halo behavior is not guaranteed; RGB dilation is experimental and off by default.

Update both helper and Studio plugin, restart Studio and reopen the companion. New uploads still use your own key entered locally. Mobile layout and OAuth sign-in remain outside this release.

## 2.3.0

- Capability-aware native unequal corners and solid-color shape shadows, retaining compatibility images without unnecessary uploads.
- Broader native desktop flex layouts: alignment, space distribution, equal-gap wrapping and main-axis fill children.
- Import quality totals and per-layer explanations in Studio Review, including image use, covered descendants, typography substitutions and layout handling.
- Optional 60%/100% corner smoothing for eligible solid surfaces, baked into reusable 9-slice images. No game runtime library required.
- Switching rendering modes retires obsolete generated decorations while preserving instances, references and user scripts.
- Document version 3; legacy versions 1 and 2 still import. MIT notices for Supercorner/figma-squircle retained.

Validation: 16 Node tests and 30 Studio checks passed in a separate unpublished test place. Four browser-rendered corner samples passed PNG/alpha/bounds checks. The actual companion UI prepared a smoothed fixture, sent it through the bridge and produced a portable bundle with embedded pixels.

Update both the Studio plugin and helper, then restart Studio and reopen the Penpot companion. Extract the new helper to a new folder, close the previous helper, and run Start-Penpot-Bridge.cmd. Re-enter your own upload key locally if needed. Smoothing is off by default and intentionally changes eligible corners; native shadow softness can differ from Penpot. Automatic mobile layout and OAuth sign-in remain outside this release.

## 2.2.0

- Auto, Editable and Exact text modes in the Penpot companion, with reported substitutions and persistent preferences.
- Native CanvasGroup opacity for suitable clipped containers; image fallback remains for other effects.
- Opt-in scrolling and panel tags: [scroll], [panel:Shop], [closed], [open:Shop] and [close].
- One fixed generated controller for panel actions; source text is never executed as code.
- Reimport preserves user scripts and references. Removing actions disables the retained controller, and restoring actions reuses it.
- Document version 2 prevents older plugins silently dropping new features. Legacy version-1 bundles still import.
- MIT attribution retained for the text-mode policy and tag grammar adapted from figrbx.

Validation: all 13 Node tests, all 12 legacy Studio regression checks and 7 new Studio feature checks passed in a separate blank test place. Actual Play-mode input opened and closed the panel and scrolled its native container. OAuth sign-in is not included in this release.

Update BOTH the Studio plugin and desktop helper. Restarting the helper requires re-entering your own upload key when new images are needed. For an existing ScreenGui destination, native opacity requires sibling Z ordering; otherwise import into StarterGui or turn native groups off and re-export.

## 2.1.0

First public open-source release, under the MIT license.

- Studio importer and Penpot companion with a guided connection screen.
- Portable Windows x64 helper download, including Node.js. Extract the ZIP and run Start-Penpot-Bridge.cmd.
- Official Open Cloud image uploads with per-creator content deduplication.
- Automatic image surfaces for unsupported effects and typography.
- Stable source IDs, local override preservation, class-change controls and Studio undo.

The helper runs on each user's PC. It requires that user's own Roblox Assets Read/Write key for new image uploads. It is a portable console application, not a signed installer or tray application. Mobile adaptation is outside scope. Some visual effects are baked, and Roblox permissions/moderation still apply.

Validation: 9 automated Node tests; the importer previously passed 12 Studio regression scenarios. The guided setup was checked in Studio with connected and unavailable helper states. Windows release packaging is built and verified by the release workflow.
