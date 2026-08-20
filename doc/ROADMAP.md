# Roadmap

## v0.0.1 — Scaffold (shipped)

- 12 `Placement`s (top/bottom/left/right × start/center/end)
- Pure `computePosition({anchor, floating, viewport, placement, middleware})`
- Middleware: `Offset4`, `Flip`, `Shift`, `Arrow`
- `FloatingOverlay` widget with two-pass measurement, scroll-aware repositioning

## v0.1 — Positioning completeness

- **`Size` middleware** — constrain floating to available space (menus that get scrollable when they'd otherwise overflow)
- **`Hide` middleware** — detach when the anchor scrolls off-screen (avoid orphaned tooltips)
- **`AutoPlacement`** — try N placements, pick the one that fits best
- **Anchor tracking through transforms** — respect `Transform.rotate` / `Transform.scale` on ancestors
- **Logical placements** — `PlacementLogical.start` / `end` that respect RTL

## v0.2 — Rendering flexibility

- **Portal target** — render into a specific ancestor instead of the root Overlay
- **`FloatingArrow` widget** — pre-built arrow that reads `middlewareData['arrow']` and paints itself
- **Configurable close-on-outside-tap** — currently users have to wire this themselves
- **Transition adapter** — plug in an animator (fade / slide / spring) for open/close

## v0.5 — Higher-level widgets built on anchor_kit

- **`AnchorTooltip`** — replacement for `Tooltip` with placement middleware
- **`AnchorMenu`** — dropdown / context menu primitives
- **`AnchorSelect`** — headless select input for form UIs

Each shipped as a separate package that depends on `anchor_kit` — this
package stays a low-level primitive.

## v1.0 — Stability

- API frozen
- Tested against Radix's positioning test suite (adapted)
- Documented cross-platform quirks (iOS split-view, macOS window offsets, web zoom)

## Explicit non-goals

- **A full component library** — that's `shadcn_ui` / `shadcn_flutter`'s job. anchor_kit is the *primitive* those libraries can build on.
- **Absolute-positioned overlays outside Overlay** — always renders through Flutter's `Overlay`.
