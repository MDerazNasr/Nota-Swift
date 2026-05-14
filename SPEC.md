# Nota Swift Rebuild Spec

This repo follows the rebuild spec in:

`/.context/attachments/pasted_text_2026-05-14_01-56-28.txt`

That attachment is the primary product and behavior contract for this rebuild.

## Local Rules

1. Keep source files under 500 lines.
2. Split by responsibility.
3. Test each feature slice before moving on.
4. Commit each major verified slice separately.
5. Match the shipped nota behavior and UI, not generic SwiftUI defaults.

## Architecture

- `Sources/NotaCore`
  Models, defaults, persistence, normalization, reducers, sorting, tags, themes.
- `Sources/NotaApp`
  App shell, window controller, global hotkey, AppKit editor bridge, SwiftUI views.
- `Tests/NotaCoreTests`
  Deterministic tests for storage, normalization, sorting, key handling, and reducers.

## Current Rebuild Order

1. Scaffolding and persistence foundation.
2. State stores and reducers.
3. Window shell and geometry.
4. Tabs and item list UI.
5. Editor, Vim engine, slash menu, tags, links.
6. Settings overlay and shortcut capture.
7. Final parity verification and packaging.
