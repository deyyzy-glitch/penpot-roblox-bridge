# Troubleshooting

**First check:** open [helper status](http://127.0.0.1:43129/setup) on the same PC as Penpot and Studio. If the page cannot open, run **Start-Penpot-Bridge.cmd** from the extracted Windows helper folder and keep its window open. An image-upload key is not required just to install the Penpot plugin or transfer designs without new images.

| What you see | What to do |
| --- | --- |
| Penpot: “The plugin doesn't exist or the URL is not correct” | Start the helper first. Confirm the status page opens, then install using `http://127.0.0.1:43129/manifest.json`. This local URL only works while the helper runs on that PC. |
| It worked yesterday, but fails after restarting the PC | Run the helper launcher again. The portable helper does not automatically start at login. |
| Launcher says “The bundled runtime is missing” | Extract the **entire** Windows helper ZIP. Run the launcher from the extracted folder, not from inside the ZIP or copied out on its own. |
| Launcher says the address is already in use | A helper may already be running, including a background copy. In current helpers, another launch identifies it and opens its status page instead of crashing. Close the duplicate window and continue with the running helper. To update, close the original helper before running the new download. |
| Studio says the helper is offline, but its status page opens | Use **Connection → Check local connection** in Studio. If you denied the request to contact `127.0.0.1`, review Penpot Bridge's HTTP permission in Manage Plugins and allow it. This address means your own PC. |
| Studio has nothing to receive | In Penpot, select the layer, group, or board, click **Prepare selection**, then **Send to Studio**. In Studio, click **Receive from Penpot**. Preparing alone does not send it. |
| Images need setup, or uploads stopped after restarting the helper | Open the setup page and configure your own Roblox Assets Read/Write key locally. Keys are kept in helper memory and cleared when it stops. Check account/group and asset permissions if Roblox rejects an upload. |
| Preparation stops on a named layer | Read the full layer/error message. Check its images and fonts are loaded and that the layer exports from Penpot itself. Reopen the companion and retry; include the full error and helper/plugin versions in a bug report if it repeats. |
| Penpot says `library:read` permission is not granted | Update or reinstall the Penpot plugin from the manifest URL and approve its requested library-read permission. |
| You still see the old interface | Update the installed Studio plugin **and** download the latest helper. Close the old helper, launch the new extracted copy, and reopen the Penpot companion. Restart Studio if necessary. A GitHub release does not replace an already-running portable helper. |
| Duplicate Studio plugin buttons | Keep one installed plugin copy. Do not put the whole GitHub folder in Studio's Plugins folder. Check for an old manually installed local copy alongside the inventory plugin. |

Installing the Roblox plugin does **not** install the Windows helper or the Penpot plugin. Each person sets up those parts on their own PC. The helper is needed while importing; the finished Roblox game runs without it. Keep keys out of screenshots and GitHub issues.

[Back to setup](../README.md) · [Feature guide](FEATURES.md)
