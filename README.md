# anchor_kit

Headless anchor-positioning primitives for popovers, tooltips, dropdowns, context menus and select inputs. Inspired by [Floating UI](https://floating-ui.com/).

Flutter has excellent tooltip and menu widgets, but no reusable engine that composes positioning strategy from small pieces (flip, shift, offset, arrow). `anchor_kit` gives you the primitive so higher-level UI kits don't have to reinvent it.

> **Status:** v0.0.1 — early alpha. API surfaces may change.

## Features (v0.0.1)

- 12 `Placement`s (top/bottom/left/right × start/center/end)
- Pure `computePosition({anchor, floating, viewport, placement, middleware})` function — no widgets, testable
- Composable middleware: `OffsetMiddleware`, `Flip`, `Shift`, `Arrow`
- `FloatingOverlay` widget: measures floating child, positions it in the app overlay, re-positions on scroll

## Not yet

- `size` middleware (constrain floating to available space)
- `hide` middleware (detach when reference is off-screen)
- `autoPlacement` (choose best of several placements)
- Virtual reference elements (positioning relative to an arbitrary rect)

## Quick example

```dart
FloatingOverlay(
  isOpen: open,
  placement: Placement.bottomStart,
  middleware: [
    OffsetMiddleware(8),
    Flip(padding: 4),
    Shift(padding: 8),
  ],
  floating: (context, position) => Material(
    elevation: 8,
    child: Padding(
      padding: EdgeInsets.all(12),
      child: Text('Placement chose ${position.placement.side}'),
    ),
  ),
  child: ElevatedButton(
    onPressed: () => setState(() => open = !open),
    child: Text('Open'),
  ),
)
```

Pure positioning (no widget):

```dart
final result = computePosition(
  anchor: Rect.fromLTWH(100, 200, 40, 40),
  floating: Size(180, 60),
  viewport: Rect.fromLTWH(0, 0, 400, 800),
  placement: Placement.top,
  middleware: [Flip(), Shift()],
);
// result.offset, result.placement, result.middlewareData['flipped']
```

## License

MIT
