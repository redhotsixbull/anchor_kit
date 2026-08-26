# Roadmap

## v0.0.1 — Scaffold (shipped)

- 12 `Placement`s (top/bottom/left/right × start/center/end)
- Pure `computePosition({anchor, floating, viewport, placement, middleware})`
- Middleware: `Offset4`, `Flip`, `Shift`, `Arrow`
- `FloatingOverlay` widget with two-pass measurement, scroll-aware repositioning

## v0.2.0 — Positioning completeness (shipped)

- **`SizeMiddleware`** — reports available space so menus can cap height + scroll ✅
- **`Hide`** — flags when the anchor scrolls off-screen ✅
- **`AutoPlacement`** — pick the side with the most room ✅
- **`Shift` main/cross axis + RTL** — main-axis-only by default (no detaching) ✅

## v0.2.1 — Docs that can't rot (shipped)

- **API reference caught up with 0.2.0** — `AutoPlacement` / `SizeMiddleware` /
  `Hide` / `PlacementSide` / `PlacementAlign` documented ✅
- **README carries no version numbers**; `docs_freshness_test.dart` +
  `readme_snippets_test.dart` fail the suite if the docs drift ✅
- **`Offset4` removal rescheduled to `0.3.0`** (its deprecation message named a
  version that had already shipped) ✅

## Next — positioning + interaction

- **Anchor tracking through transforms** — respect `Transform.rotate` / `Transform.scale` on ancestors
- **Logical placements** — `PlacementLogical.start` / `end` that respect RTL
- **Interaction/a11y layer** — focus trap, keyboard navigation, enter/exit animation on `FloatingOverlay`
- **Remove `Offset4`** — the deprecated alias for `OffsetMiddleware` (scheduled for `0.3.0`)
- **Virtual/rect reference** — anchor to an arbitrary rect, not just a widget

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
