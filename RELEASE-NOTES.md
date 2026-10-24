# Penpot Bridge 2.4.0

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
