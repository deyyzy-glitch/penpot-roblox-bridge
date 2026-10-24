# Contributing

Open an issue describing the expected and actual result, or submit a pull request. Include a minimal synthetic Penpot example when possible. Do not attach API keys, personal designs without permission, or local upload caches.

Use Node.js 22+ and run `node build.mjs` followed by `node --test --test-isolation=none tests/bridge.test.mjs tests/exporter.test.mjs tests/cloud.test.mjs`.

Edit studio/ and penpot/ sources; regenerate the plugin files with the build script. Validate Studio-specific changes in a separate unpublished test place. Preserve source ownership, local overrides, references and undo behavior. Keep HTTP endpoints loopback-only and never put credentials into design documents.

Contributions are provided under the repository's MIT license.
