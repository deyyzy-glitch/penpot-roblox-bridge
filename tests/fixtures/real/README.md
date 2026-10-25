# Captured Penpot export regressions

These are reduced **normalized importer documents from actual Penpot exports**, captured while testing the generated Stats demo. They are not hand-written examples and are not raw Penpot Plugin API objects.

- `mine-panel.json`: the Forgotten Mine panel from the colorful Stats window. Captured on 2026-10-24; 17 nodes, eight Fredoka labels with the declared FredokaOne mapping, and three independent image surfaces. Native text values are also replayed through the current exporter in Node tests.
- `svg-chart.json`: the three beveled header bars from the detailed Stats reference study, captured on 2026-10-24. Eight nodes and five image surfaces cover definition-only SVG omission, local negative raster padding, imported fills exposed only through SVG paint, thin stroked paths and tint metadata.

Project/page/shape IDs are anonymized. Uploaded asset IDs are replaced by `rbxassetid://0`; image bytes, hashes, caches, credentials and original files are excluded. These fixtures exercise conversion/import structure and reimport behavior, **not rendered-pixel accuracy** or Roblox upload/moderation. Synthetic fixtures still cover grids, spans, RichText, tokens and other cases absent from these captures.

To reduce another approved real export, use `node scripts/capture-regression.mjs input.json "Layer name" output.json short-id`, inspect the result, and add assertions for the actual regression. Keep image rendering tests separate.
