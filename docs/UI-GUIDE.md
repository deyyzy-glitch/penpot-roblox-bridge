# Interface guide

[Setup](../README.md) · [Features](FEATURES.md) · [Troubleshooting](TROUBLESHOOTING.md)

## Install the GitHub Studio plugin

Download **PenpotRoblox.rbxmx** from the same 3.0.0 release as your helper. In Studio, open **Plugins → Plugins Folder**, then copy only that file into the folder. Disable an older Creator Store copy in Manage Plugins, replace an older local file if present, and restart Studio. Open **Plugins → Penpot Bridge**. Do not copy the whole repository or helper folder into Plugins Folder.

For the usual installation, use the [Creator Store plugin](https://create.roblox.com/store/asset/129957195606923). Keep one enabled copy so an old interface cannot compete with the new plugin.

## Penpot companion

| Page | Use it for |
| --- | --- |
| **Transfer** | Prepare the selected layer/group/board, send it to Studio or download a portable bundle. Progress and preparation errors appear here. |
| **Layers** | Read selection layers, search for a layer and edit its conversion mode, native font weight, reference or template key. One layer editor appears at a time. |
| **Images** | After preparation, choose an eligible surface, adjust its slice guides or optional styling, then apply changes. Each surface keeps its own draft. |
| **Settings** | Shared export choices and appearance. Prepare again after changing export settings. |
| **Local helper** | Connection status, optional image-upload setup and troubleshooting. |

Preparing alone does not send the design. Apply every pending image change before **Send to Studio**; changing layers, export settings or the design can require preparation again. The Images page only offers controls for eligible surfaces, so some baked compatibility images will not have editors.

## Roblox Studio

| Page | Use it for |
| --- | --- |
| **Import** | Receive the prepared design, review it and import. Progress reflects the current operation; completion counts come from the import result. |
| **Review** | Inspect planned changes and import quality before applying them. |
| **Verify** | Run the read-only checks against imported objects. Verification is manual and does not compare screenshots. |
| **Templates** | Select an archivable UI object in Explorer, enter a key and choose **Map selected component**. Use the same key on a reusable-template layer in Penpot. |
| **Settings** | Import behavior, appearance and advanced JSON/mappings. |
| **Local helper** | Check the local connection and open helper status. |

Templates clone your selected component, including its children and scripts; they do not create gameplay logic. Map again after editing the original. Refreshing existing template clones requires reviewed replacement.

Both interfaces keep desktop proportions instead of stretching text to fill a huge window. Shorter windows scroll; Studio also offers horizontal scrolling if its host is narrower than the design canvas. Choose light or dark appearance in Settings.

## Updating from 2.7 or a preview

Close the old helper, extract and start the new download, then close and reopen the Penpot companion. Replace the Studio plugin and restart Studio. An already-running helper continues serving its own files even after you download a newer ZIP. Check the helper version on its status page and keep both components at 3.0.0 for version 6 exports.

The helper is still required while transferring. An Assets Read/Write key is only needed for new image uploads; the interface redesign does not make it mandatory for native UI. Keys clear when the helper stops, so keep your own secure copy for reuse.
