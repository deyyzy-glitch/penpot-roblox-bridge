# Penpot Bridge 2.2.0

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
