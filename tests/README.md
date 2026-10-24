# Verification

Run Node tests with `node --test --test-isolation=none tests/bridge.test.mjs tests/exporter.test.mjs tests/cloud.test.mjs`.

`studio-regression.luau` accepts the Importer module and a dashboard export with the names created by create-penpot-fixture.js. It covers native creation, idempotence, references, scripts, overrides, locks, removal/restoration, class confirmation, separate sources, missing images, invalid data, resize constraints, nested imports and rollback. Its sandbox is removed after the run.

`feature-fixture.mjs` exports a synthetic version-2 document with an editable heading, native opacity group, scrolling container and open/close panel actions. Pass that JSON document and Importer to `studio-features.luau`. The seven checks create and remove their own ScreenGui sandbox. Importer requires its sibling Behaviors ModuleScript.

When running through a Studio connector that owns an undo recording, schedule the test function with task.delay(1, ...), then read its result in a later command. Run tests in a separate unpublished place.

For runtime verification, import the feature fixture into StarterGui, start Play, click the Open and Close buttons, and scroll Inventory. Expected: panel starts hidden, opens and closes on activation, and the scroll canvas extends beyond its viewport. The runtime controller uses only imported source-owned metadata.
