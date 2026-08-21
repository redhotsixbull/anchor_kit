# anchor_kit — Feature Specification

Behavioral contract for the positioning engine. Guarantees are pinned by
`test/anchor_kit_test.dart`.

## 1. Placement

- 12 placements: `{top,right,bottom,left} × {start,center,end}`.
- `flipSide()` returns the opposite **side**, keeping **alignment**
  (`bottomStart.flipSide() == topStart`).
- Base offset (`computePosition` with no middleware):
  - side positions the floating box adjacent to the anchor edge;
  - alignment distributes along the cross axis: `start` aligns leading edges,
    `center` centers, `end` aligns trailing edges.

## 2. `computePosition` — pure function

```dart
PositionResult computePosition({anchor, floating, viewport, placement, middleware})
```

- Deterministic, widget-free, side-effect-free. Given identical inputs it MUST
  return identical output.
- Middleware run **in list order**, each receiving the running
  `(offset, placement, data)` and a `recompute(placement)` to get the base
  offset for any placement.
- `PositionResult` exposes final `offset`, resolved `placement`, and the merged
  `middlewareData` map.

## 3. Middleware — `OffsetMiddleware`

- Moves the floating box `distance` **away** from the anchor along the main
  axis (up/down/left/right by side).
- `crossAxis` shifts along the perpendicular axis: for vertical placements
  positive = right; for horizontal placements positive = down.
- `Offset4` is a **deprecated** alias, kept until v0.1.0.

## 4. Middleware — `Flip`

- If the current placement is **fully inside** the padded viewport, it is kept
  unchanged. (Touching an edge while fully inside is NOT an overflow — it MUST
  NOT flip.)
- Else the opposite side is tried; if it fully fits, flip to it and set
  `data['flipped'] = true`.
- If **neither** side fully fits, keep whichever side overflows the viewport by
  the **least total amount** (never blindly keep the original).

## 5. Middleware — `Shift`

- Slides the floating box to keep it within the padded viewport, **without**
  changing the side.
- Clamps the **main axis** (parallel to the anchor edge) by default: horizontal
  for `top`/`bottom`, vertical for `left`/`right`. `crossAxis: true` also clamps
  the perpendicular axis (can detach from the anchor); off by default.
- If the floating box is **larger** than the available space on an axis, the
  logical **start** edge is kept visible (left/top; or right when `rtl: true`)
  rather than pinning the far edge.
- Records the applied delta in `data['shift'] = {dx, dy}`.

## 5b. Middleware — `AutoPlacement`

- If the current placement fully fits, it is kept (`changed: false`).
- Otherwise, among the candidate placements (default: the four sides with the
  current alignment) it picks the one that overflows the (padded) viewport the
  least. Records `data['autoPlacement'] = {side, changed}`. Use instead of
  `Flip`.

## 5c. Middleware — `SizeMiddleware`

- Reports the space available on the resolved side against the padded viewport
  in `data['size'] = {availableWidth, availableHeight}` (never negative). The
  consumer caps the floating element (e.g. `maxHeight`) and scrolls. Runs in one
  pass; a floating element that shrinks to fit settles over one extra frame
  because `FloatingOverlay` re-measures each frame.

## 5d. Middleware — `Hide`

- Sets `data['hide'] = {referenceHidden: bool}`; `referenceHidden` is true once
  the anchor no longer overlaps the padded viewport, so the consumer can hide
  the floating element.

## 6. Middleware — `Arrow`

- Computes the arrow position along the floating box's main-axis edge so it
  points at the anchor centre, stored in `data['arrow'] = {x?, y?}` (only the
  main-axis coordinate is set).
- The position is clamped to `[padding, size - arrowSize - padding]`.
- If the floating box is too small to honour `padding` on both sides, the arrow
  is **centred** instead of throwing.

## 7. `FloatingOverlay` widget

- Renders `floating` into the app `Overlay` while `isOpen`, removes it
  otherwise.
- **Follows the anchor**: while open, the anchor's global rect is sampled once
  per frame; any change — **ancestor scrolling**, window resize/rotation, or
  the anchor moving — re-positions the floating element. (This is the headline
  guarantee; see the "re-positions when an ancestor scrolls" test.)
- **Re-measures** the floating child each frame, so content that changes size
  stays correctly positioned (no stale cached size).
- **Dismiss barrier**: when `barrierDismissible` is true and `onDismiss` is set,
  a transparent full-screen barrier is placed *behind* the floating element; a
  tap on it calls `onDismiss`. Taps on the floating element itself do NOT
  dismiss. Off by default (fully backward compatible).
- Lifecycle safety: `_open` no-ops if unmounted or if no `Overlay` is present;
  all post-frame `setState`/measurement is `mounted`-guarded; the overlay entry
  and per-frame tracker are torn down on close/dispose.

## Recommended middleware order

`OffsetMiddleware → Flip → Shift → Arrow` — offset first so flip/shift see the
gap; arrow last so it points at the final resting position.

## Not yet
Virtual/rect reference elements; interaction/a11y layer (focus trap, keyboard
nav, enter/exit animation) on `FloatingOverlay`. (`SizeMiddleware`, `Hide`,
`AutoPlacement` shipped in 0.2.0.)
