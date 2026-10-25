# Verification

`studio-gradients.luau` takes the built Importer, source Gradient module and verifier fixture. Eleven checks cover sample limits, authored stops, endpoint extension, transparency, source immutability, constant colors, native import integration, verification, idempotence and local edits. `studio-layer-controls.luau` takes Importer, the verifier fixture and horizontal grid fixture; its thirteen checks cover unresolved mappings, clone ownership/content, Layout mode, stable references, revision confirmation, retirement, skip/restore, metadata verification and grid templates. Run outside MCP undo recordings in a disposable sandbox.

`layer-modes.test.mjs` exercises export semantics and unsafe override rejection; `layer-editor.test.mjs` checks persistence, file scoping, stale selection responses, busy state and literal layer names. `build.test.mjs` verifies support modules survive packaging, including Luau dollar patterns.

`grid-fixture.mjs` and `studio-grids.luau` cover the opt-in native grid path. The 19 Studio checks cover default-off behavior, padded row/column placement, spatial ordering despite paint order, idempotence, verifier compatibility, on/off/on identity preservation, safe rejection of irregular/effected cells, invalid metadata, local additions after disabling layout, and both captured real exports. `real-fixtures.test.mjs` runs four Node regressions against the reduced real captures under `fixtures/real`; the fixture README documents provenance and exclusions.

`verifier-fixture.mjs` and `studio-verifier.luau` exercise the read-only post-import verifier. Pass the fixture's document and Importer to the test function outside an MCP recording. Its 18 Studio checks cover clean imports, known font substitutions, old imported fonts, local edits and locks, missing/duplicate/wrong-class objects, parenting, empty and unresolved image references, expected versus new overlaps, user objects, unchanged instance state, duplicate wrappers, and visible versus hidden text overflow. The sandbox is removed after testing. A Studio UI-host smoke check additionally exercises loading the document, verifying the selected import, and rendering finding rows.

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
