# Verification

Run Node tests with `node --test --test-isolation=none tests/bridge.test.mjs tests/exporter.test.mjs tests/cloud.test.mjs`.
Include `tests/image-tools.test.mjs` for mask deduplication, alpha-preserving dilation, bounded silhouette blur, processed previews and portable glow payloads.

`studio-advanced-fixture.mjs` creates mixed text, aliases, themes and image-control metadata. Pass Importer and its document to `studio-advanced.luau`. Its eight checks cover RichText escaping/content, tint/glow/slice descriptors, opt-in module generation, aliases, locks, nested import isolation, retained user scripts and invalid metadata. The sandbox is removed afterward.

Runtime verification: import that fixture into a separate blank place, start Play, require its Penpot Theme module from the client and apply Dark. Check the panel color and the RichText label's ContentText. No uploaded test image is required for the text/theme check.

`studio-regression.luau` accepts the Importer module and a dashboard export with the names created by create-penpot-fixture.js. It covers native creation, idempotence, references, scripts, overrides, locks, removal/restoration, class confirmation, separate sources, missing images, invalid data, resize constraints, nested imports and rollback. Its sandbox is removed after the run.

`feature-fixture.mjs` exports a synthetic version-2 document with an editable heading, native opacity group, scrolling container and open/close panel actions. Pass that JSON document and Importer to `studio-features.luau`. The seven checks create and remove their own ScreenGui sandbox. Importer requires its sibling Behaviors ModuleScript.

When running through a Studio connector that owns an undo recording, schedule the test function with task.delay(1, ...), then read its result in a later command. Run tests in a separate unpublished place.

`quality-fixture.mjs` creates a version-3 document. Pass Importer, that document and Assets to `studio-quality.luau`. Its 11 checks cover native effects, capability fallback, unused-upload filtering, report accuracy, wrapping order, space distribution, fill resizing, smooth image descriptors, mode switching, user references and invalid metadata. The test removes its sandbox.

Browser verification should render circular/smoothed/unequal/inner-stroked corner images, decode their PNG pixels through the helper, then prepare and send a fixture through the actual companion UI. Confirm the portable bundle contains smooth pixel payloads and slice metadata. This requires no Roblox asset upload.

For runtime verification, import the feature fixture into StarterGui, start Play, click the Open and Close buttons, and scroll Inventory. Expected: panel starts hidden, opens and closes on activation, and the scroll canvas extends beyond its viewport. The runtime controller uses only imported source-owned metadata.
