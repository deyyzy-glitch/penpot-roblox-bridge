# Penpot Bridge

Bring Penpot layers, groups and boards into Roblox Studio as editable UI. Review imports, synchronize updates and preserve local edits. Free and open source under the MIT license.

[Download Windows helper](https://github.com/deyyzy-glitch/penpot-roblox-bridge/releases/latest/download/PenpotBridge-Windows-x64.zip) · [Studio plugin](https://create.roblox.com/store/asset/129957195606923) · [Release notes](RELEASE-NOTES.md)

**Latest: helper 2.7.6 · Studio plugin 2.7.4.** This update adds visual nine-slice guides, linked borders, slice reset and optional button suggestions. Update the helper for these features; the Studio plugin is unchanged.

## Get started

You need Penpot, Roblox Studio and the local helper on the same computer. The portable download includes Node.js and runs on Windows x64. For macOS/Linux or development, see [running from source](docs/DEVELOPMENT.md#run-from-source).

1. Install [Penpot Bridge in Roblox Studio](https://create.roblox.com/store/asset/129957195606923).
2. Download and extract the **entire Windows helper ZIP**, then run **Start-Penpot-Bridge.cmd**. Keep that window open while importing.
3. Open [helper status](http://127.0.0.1:43129/setup). If it cannot open, start the helper before continuing. **You can leave image-upload setup closed and continue without a key.**
4. In Penpot's Plugin Manager, install `http://127.0.0.1:43129/manifest.json`, approve its requested permissions, and open **Penpot to Roblox**.
5. Select a layer, group or board. Click **Prepare selection**, then **Send to Studio**.
6. In Studio, open **Plugins → Penpot Bridge**, then **Receive from Penpot → Review import → Import design**.

If Studio asks to contact **127.0.0.1**, allow it: that address is the helper on your own computer. Installing the Studio plugin alone does not install the helper or Penpot companion.

## Helper and image-upload key

| Part | When it is needed |
| --- | --- |
| **Local helper** | Always during installation/opening of the Penpot companion and design transfers, even for designs without images. |
| **Your Roblox Assets Read/Write key** | When new image assets need the helper's upload fallback. It is not required to install, connect, prepare or transfer native UI. |

Image assets include photos and PNG fallbacks for vectors, typography or effects that cannot stay native. Previously uploaded images can be reused. If a transfer needs new uploads, open [helper setup](http://127.0.0.1:43129/setup) and enter your own key locally for the Studio account or authorized group. The previously tested Studio build rejected native publishing, so the helper provides an Open Cloud fallback.

The key stays in helper memory, is sent only to Roblox, and clears when the helper stops. **Save it securely, such as in a password manager, so you can reuse it after a restart while it remains valid.** Never post it in issues, source code or screenshots. Roblox controls asset moderation, permissions and upload quotas.

The helper is portable: it is not a tray app and does not start automatically at login. Closing its browser status tab is fine; keep the helper's command window running. Your finished game needs neither the helper nor the key.

## Everyday workflow

**Prepare → adjust optional settings → send → receive → review → import.**

- In Penpot, use **Layers** for individual conversion modes, font weights, references and optional button suggestions. After preparing, use **Images** for eligible image settings. Apply image changes before sending.
- In Studio, **Review** explains changes and import quality. **Verify** checks the received design against its imported objects without changing them.
- Reimport the same source selection to update compatible instances. Local managed-property edits and locks are preserved and reported. Removed objects are retained; replacing object classes requires explicit review and keeps the old instance.

## Features and guides

| Feature | What it does |
| --- | --- |
| [Layer controls, references and templates](docs/FEATURES.md#layer-controls-references-and-templates) | Choose native UI, image, layout-only, skipped or template layers; connect your own gameplay code through stable references. |
| [Text and font choices](docs/FEATURES.md#text-and-native-opacity) | Editable text where supported, mixed-style RichText and optional per-layer native weights. |
| [Image settings and visual slicing](docs/FEATURES.md#tintable-icons-glows-and-image-slicing) | Tintable icons, silhouette glows, optional RGB edge dilation and draggable nine-slice guides with linked borders and reset. |
| [Layouts and native grids](docs/FEATURES.md#native-uniform-grids) | Supported native layouts; an optional grid mode for compatible uniform cells. |
| [Scrolling and panel actions](docs/FEATURES.md#optional-scrolling-and-panel-actions) | Explicit layer tags for scrolling containers and open/close panels. Button suggestions never invent gameplay logic. |
| [Design tokens and runtime themes](docs/FEATURES.md#design-tokens-and-optional-runtime-themes) | Preserve supported bindings and optionally generate a theme module. |
| [Import verification](docs/FEATURES.md#verify-import) | Check identities, properties, text fitting, image loading and unexpected overlaps. No AI account required. |

See the [full feature guide](docs/FEATURES.md) for settings, code examples and exact limitations.

## Fidelity and limitations

Simple frames, text, buttons, supported layouts, strokes, corners and linear gradients remain native. Complex visuals use transparent image surfaces, up to 2× resolution and capped at 1024 pixels per dimension. Baked artwork is edited in Penpot and re-exported.

Font metrics, shadows and gradients may differ from Penpot. The verifier checks object state; it does not compare screenshots or guarantee identical appearance. Review important imports visually. Desktop design workflow is the focus; automatic mobile redesign is outside scope.

## Updating

1. Download and extract the latest helper into a new folder.
2. Close the old helper's command window before starting the new launcher. Another launch cannot replace an already-running copy; only one helper can use the local port.
3. Close and reopen the Penpot companion. Re-enter your locally saved upload key if new images need it.
4. Prepare and send again, then receive and import in Studio.

Update the Studio plugin when the release notes call for it. **Helper 2.7.6 works with Studio plugin 2.7.4.** Do not install a second local plugin alongside the inventory version.

## Need help?

Start with [helper status](http://127.0.0.1:43129/setup), then the [troubleshooting guide](docs/TROUBLESHOOTING.md). It covers Penpot installation errors, offline connections, duplicate helpers, upload setup and old plugin copies.

[Report a bug](https://github.com/deyyzy-glitch/penpot-roblox-bridge/issues) with the full error, helper/Studio plugin versions and a small reproducible example. Keep credentials and private designs out of public reports.

## Contributing and license

See [development and testing](docs/DEVELOPMENT.md), [contribution guidance](CONTRIBUTING.md), [release history](RELEASE-NOTES.md) and [third-party notices](THIRD-PARTY-NOTICES.md).

Penpot Bridge is [MIT-licensed](LICENSE) and independent of Roblox and Penpot. Adapted figrbx and Supercorner/figma-squircle code retains its credits and license notices.
