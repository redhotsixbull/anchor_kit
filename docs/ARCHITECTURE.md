# Architecture

## Two layers

anchor_kit is deliberately split into a **pure computation layer** and a
**widget integration layer**. The former has no dependency on `dart:ui`
beyond `Rect`, `Size`, `Offset`, and can be tested with plain unit tests.

```
┌───────────────────────────────────────────────┐
│  FloatingOverlay  (Widget)                    │
│    - tracks anchor's RenderBox                 │
│    - measures floating child's Size            │
│    - inserts an OverlayEntry                   │
│    - re-computes on scroll / rebuild           │
└──────────────────┬────────────────────────────┘
                   │ computePosition(anchor, floating, viewport, placement, middleware)
                   ▼
┌───────────────────────────────────────────────┐
│  Pure positioning engine  (no widgets)        │
│  - _baseOffset()  →  initial Offset            │
│  - middleware pipeline (offset / flip / …)     │
│  - Returns PositionResult{offset, placement,   │
│           middlewareData}                      │
└───────────────────────────────────────────────┘
```

## `computePosition` pipeline

1. `_baseOffset(anchor, floating, placement)` computes the naive placement
   assuming no viewport constraints. E.g. `Placement.bottom` puts the floating
   at `(anchor.centerX - floating.width/2, anchor.bottom)`.

2. Middleware run in order. Each receives a `MiddlewareState` snapshot:
   ```dart
   MiddlewareState {
     Rect anchor;
     Size floating;
     Rect viewport;
     Placement placement;      // current, may have been changed by earlier mw
     Offset offset;            // current, may have been mutated
     Map<String, Object?> data;
     RecomputeBase recompute;  // recompute base offset for a different placement
   }
   ```
   and returns a `MiddlewareResult { offset, placement, data? }`.

3. Middleware data is merged into the final `PositionResult.middlewareData`
   so widgets can read out e.g. `{'flipped': true}` or `{'arrow': {'x': 32}}`.

## Middleware conventions

- **Idempotent**: running a middleware on its own output should be a no-op.
- **Pure**: no I/O, no time reads. Same inputs → same outputs.
- **Composable**: order matters (`Flip` before `Shift` gives different
  results than `Shift` before `Flip`). The order rule of thumb from
  Floating UI applies: `offset → flip → shift → arrow`.

Bundled middleware:

- **`Offset4(distance, {crossAxis})`** — pushes the floating away from the
  anchor along the placement's main axis, optionally offsets along the cross.
- **`Flip({padding})`** — if the current placement's floating rectangle
  extends outside the padded viewport, try the opposite side. Falls back to
  the original placement if the flip also overflows.
- **`Shift({padding})`** — clamps the offset so the floating rectangle stays
  inside the padded viewport. Reports `{'shift': {'dx': …, 'dy': …}}` so an
  arrow middleware could compensate.
- **`Arrow({padding, arrowSize})`** — computes the `x` (or `y`, depending on
  placement) where an arrow should sit on the floating element to point at
  the anchor's centre, clamped to `[padding, floatingSize - arrowSize - padding]`.

## `FloatingOverlay` widget

Two-pass measurement dance:

1. **First pass** (`_measuredSize == null`) — the widget renders the floating
   child at `(-9999, -9999)` inside an `Offstage`, so we can measure its
   `RenderBox.size` without flashing on screen. A post-frame callback stores
   the size and calls `setState`.

2. **Second pass** — with the size known, run `computePosition` and place the
   floating child at the correct offset via `Positioned`.

Re-positioning triggers:
- Anchor rebuilds → `didUpdateWidget` → `_entry?.markNeedsBuild()`
- Ancestor scroll → `NotificationListener<ScrollNotification>` → same
- `isOpen` toggles → `_open()` / `_close()` insert/remove the `OverlayEntry`

## Trade-offs

- **Global-coordinate positioning**: we compute in screen coordinates
  (`localToGlobal`). Simple, but not aware of transformed ancestors like
  a rotated Card. For v0.1 that's fine — Radix / Floating UI on the web
  have the same limitation.
- **Overlay-only rendering**: `FloatingOverlay` always inserts into the
  nearest `Overlay`. It doesn't support a "portal to a specific ancestor"
  pattern yet — planned for v0.2.
- **No RTL awareness in placements**: `Placement.leftStart` means literal
  left, not "inline-start". This matches Flutter's `Positioned.left` semantics
  and diverges from Floating UI's logical placements. Configurable RTL
  planned for v0.2.
