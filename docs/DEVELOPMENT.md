# Development and source installation

[Back to setup](../README.md) · [Contributing](../CONTRIBUTING.md) · [Test fixtures](https://github.com/deyyzy-glitch/penpot-roblox-bridge/blob/main/tests/README.md)

## Run from source

Install Node.js 22 or newer. There are no npm dependencies. Source installation supports Windows, macOS and Linux; the bundled portable download is Windows x64.

```sh
node build.mjs
node bridge/server.mjs
```

Follow the Penpot/Studio setup in the README. The generated `PenpotRoblox.rbxmx` is also supplied as a release asset for manual local plugin installation. Do not put the entire repository in Studio's Plugins folder.

## Build and test

```sh
node build.mjs
node --test --test-isolation=none tests/*.test.mjs
```

Edit `studio/` and `penpot/` sources, then regenerate the plugin files with the build script. The [test guide](https://github.com/deyyzy-glitch/penpot-roblox-bridge/blob/main/tests/README.md) explains the browser fixtures and live Studio checks. Test Studio-specific changes in a separate unpublished place.

## Package releases

```sh
python scripts/release.py
python scripts/release.py --windows
```

The Windows option downloads an official Node.js 24 x64 runtime, verifies its SHA-256 against Node's published checksum list and includes its license. Source and Windows archives include these documentation guides. Credentials, caches and game files are excluded.

The GitHub workflow builds, tests and publishes release assets when `package.json` gains a new version on `main`. Existing release tags are kept unchanged. A helper-only release does not require a new Studio plugin version.
