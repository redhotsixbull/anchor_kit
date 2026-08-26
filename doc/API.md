# API reference

## `Placement`

12 predefined constants combining a side (top / right / bottom / left) and
alignment (start / center / end):

```dart
Placement.top          Placement.topStart          Placement.topEnd
Placement.right        Placement.rightStart        Placement.rightEnd
Placement.bottom       Placement.bottomStart       Placement.bottomEnd
Placement.left         Placement.leftStart         Placement.leftEnd
```

Each is a `Placement(PlacementSide, PlacementAlign)`:

- **`PlacementSide`** — `top` / `right` / `bottom` / `left`.
- **`PlacementAlign`** — `start` / `center` / `end`.

Read them back off a resolved placement with `placement.side` /
`placement.align` (e.g. `position.placement.side.name`), or build one directly:
`Placement(PlacementSide.top, PlacementAlign.start)`.

Helpers:
- `placement.flipSide()` — same alignment, opposite side.
- `placement.isVertical` / `.isHorizontal` — main axis check.

---

## `computePosition`

Pure positioning function.

```dart
PositionResult computePosition({
  required Rect anchor,
  required Size floating,
  required Rect viewport,
  required Placement placement,
  List<Middleware> middleware = const [],
});
```

Returns:

```dart
class PositionResult {
  final Offset offset;                        // top-left of the floating element
  final Placement placement;                  // may differ from input (Flip)
  final Map<String, Object?> middlewareData;  // per-middleware output
}
```

---

## Middleware

### `OffsetMiddleware(distance, {crossAxis = 0})`

Pushes the floating element away from the anchor by `distance` on the main
axis, optionally offset by `crossAxis` on the cross axis.

> `Offset4` is a deprecated alias for `OffsetMiddleware`, kept until v0.1.0.

Data: none.

### `Flip({padding = 0})`

If the current placement's floating rectangle spills outside the
`viewport.deflate(padding)`, try the opposite side. Falls back to the
original placement if the flip also overflows.

Data: `{'flipped': true}` when a flip actually happened.

### `Shift({padding = 0})`

Clamps the floating's top-left so the rectangle stays inside
`viewport.deflate(padding)`.

Data: `{'shift': {'dx': ..., 'dy': ...}}` — how much (may be zero) the
element was pushed on each axis.

### `AutoPlacement({padding = 0, candidates})`

Chooses the side with the most available room instead of only flipping to the
opposite one. Keeps the current side if it fits; otherwise picks the candidate
that overflows least. Use it *instead of* `Flip`, not with it. `candidates`
restricts the sides considered (defaults to all four, keeping the input
alignment).

Data: `{'autoPlacement': {'side': String, 'changed': bool}}`.

---

### `SizeMiddleware({padding = 0})`

Reports how much room the floating element has on the resolved side, so a long
menu can cap its height to the viewport and scroll internally rather than
overflowing. It only *reports* — applying the constraint is up to your
`floating` builder.

Data: `{'size': {'availableWidth': double, 'availableHeight': double}}`.

---

### `Hide({padding = 0})`

Flags when the anchor has been scrolled (or otherwise moved) out of view, so you
can hide the floating element instead of leaving it pointing at nothing.

Data: `{'hide': {'referenceHidden': bool}}`.

---

### `Arrow({padding = 4, arrowSize = 8})`

For vertical placements, computes the `x` coordinate (relative to the
floating element) where an arrow should sit to visually point at the
anchor's center, clamped to `[padding, floatingWidth - arrowSize - padding]`.
For horizontal placements, computes `y` similarly.

Data: `{'arrow': {'x': double?, 'y': double?}}`. The unused axis is `null`.

---

## `FloatingOverlay`

```dart
FloatingOverlay({
  Key? key,
  required bool isOpen,
  required Widget Function(BuildContext, PositionResult) floating,
  required Widget child,
  Placement placement = Placement.bottom,
  List<Middleware> middleware = const [],
  bool barrierDismissible = false,
  VoidCallback? onDismiss,
})
```

- `child` is the anchor. Whatever this widget's `RenderBox` bounds are becomes the anchor rect.
- `floating` receives the computed `PositionResult` — you can read
  `position.placement.side` or `position.middlewareData['arrow']` to
  reactively style the floating element.
- The overlay uses a two-pass measurement (first pass off-screen inside
  `Offstage`) so you can render arbitrarily-sized floating widgets without
  knowing their dimensions ahead of time.
- Re-positions automatically every frame while open: ancestor scrolling, window
  resize/rotation, or anchor movement.
- `barrierDismissible` + `onDismiss`: when both are set, a transparent
  full-screen barrier behind the floating element calls `onDismiss` on tap.
  Taps on the floating element itself do not dismiss.

---

## Deprecated

- **`Offset4(distance, {crossAxis})`** — the original name for
  `OffsetMiddleware`, ambiguous with `dart:ui`'s `Offset`. Still exported and
  still works; scheduled for removal in `0.3.0`. Replace with
  `OffsetMiddleware(distance, crossAxis: ...)`.

---

## Writing your own middleware

```dart
class MyMiddleware extends Middleware {
  @override
  String get name => 'my_middleware';

  @override
  MiddlewareResult apply(MiddlewareState state) {
    // read state.anchor, state.floating, state.viewport, state.placement, state.offset
    // return with (possibly new) offset / placement and optional data map
    return MiddlewareResult(
      offset: state.offset,
      placement: state.placement,
      data: {'my_middleware': 'ran'},
    );
  }
}
```

The `state.recompute(placement)` callback re-runs the base offset calculation
for a different placement — useful when your middleware wants to try
alternatives (Flip uses this).
