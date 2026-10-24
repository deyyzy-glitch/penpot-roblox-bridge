# Penpot Bridge 2.1.0

First public open-source release, under the MIT license.

- Studio importer and Penpot companion with a guided connection screen.
- Portable Windows x64 helper download, including Node.js. Extract the ZIP and run Start-Penpot-Bridge.cmd.
- Official Open Cloud image uploads with per-creator content deduplication.
- Automatic image surfaces for unsupported effects and typography.
- Stable source IDs, local override preservation, class-change controls and Studio undo.

The helper runs on each user's PC. It requires that user's own Roblox Assets Read/Write key for new image uploads. It is a portable console application, not a signed installer or tray application. Mobile adaptation is outside scope. Some visual effects are baked, and Roblox permissions/moderation still apply.

Validation: 9 automated Node tests; the importer previously passed 12 Studio regression scenarios. The guided setup was checked in Studio with connected and unavailable helper states. Windows release packaging is built and verified by the release workflow.
