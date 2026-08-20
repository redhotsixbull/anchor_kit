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
