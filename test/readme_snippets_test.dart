// Compile-check for the Dart snippets in README.md / doc/API.md.
// Nothing here asserts positioning behaviour — that's `anchor_kit_test.dart`.
// The point is that every API the docs show actually exists with the shown
// name, arity and types. If a snippet is edited, edit it here too.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anchor_kit/anchor_kit.dart';

/// The README's Quick start, verbatim apart from the `open` / `setState`
/// scaffolding a snippet can't show.
class _QuickStart extends StatefulWidget {
  const _QuickStart();
  @override
  State<_QuickStart> createState() => _QuickStartState();
}

class _QuickStartState extends State<_QuickStart> {
  bool open = false;

  @override
  Widget build(BuildContext context) => FloatingOverlay(
        isOpen: open,
        placement: Placement.bottomStart,
        middleware: [
          OffsetMiddleware(8), // gap from the anchor
          Flip(padding: 8), // flip to the other side if there's no room
          Shift(padding: 8), // slide back on-screen if it overflows
        ],
        barrierDismissible: true, // tap outside to close
        onDismiss: () => setState(() => open = false),
        floating: (context, position) => Material(
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text('Placed on ${position.placement.side.name}'),
          ),
        ),
        child: ElevatedButton(
          onPressed: () => setState(() => open = !open),
          child: const Text('Open'),
        ),
      );
}

void main() {
  test('README snippets compile — the pure function', () {
    final result = computePosition(
      anchor: Rect.fromLTWH(100, 200, 40, 40),
      floating: const Size(180, 60),
      viewport: Rect.fromLTWH(0, 0, 400, 800),
      placement: Placement.top,
      middleware: [Flip(), Shift()],
    );
    // result.offset, result.placement, result.middlewareData['flipped']
    expect(result.offset, isA<Offset>());
    expect(result.placement, isA<Placement>());
    expect(result.middlewareData, isA<Map<String, Object?>>());
  });

  test('README/API.md snippets compile — placements and middleware', () {
    // `Placement` section of doc/API.md.
    const built = Placement(PlacementSide.top, PlacementAlign.start);
    expect(built.side, PlacementSide.top);
    expect(built.align, PlacementAlign.start);
    expect(Placement.bottomEnd.flipSide().side, PlacementSide.top);
    expect(Placement.top.isVertical, isTrue);
    expect(Placement.left.isHorizontal, isTrue);

    // Every documented middleware constructor, with its documented arguments.
    final chain = <Middleware>[
      OffsetMiddleware(8, crossAxis: 2),
      Flip(padding: 8),
      Shift(padding: 8, mainAxis: true, crossAxis: false, rtl: false),
      AutoPlacement(padding: 8, candidates: const [Placement.top, Placement.bottom]),
      SizeMiddleware(padding: 8),
      Hide(padding: 8),
      Arrow(padding: 4, arrowSize: 8),
    ];

    final result = computePosition(
      anchor: Rect.fromLTWH(100, 200, 40, 40),
      floating: const Size(180, 60),
      viewport: Rect.fromLTWH(0, 0, 400, 800),
      placement: Placement.top,
      middleware: chain,
    );

    // The data keys each middleware documents writing.
    expect(result.middlewareData['autoPlacement'], isA<Map<String, Object?>>());
    expect(result.middlewareData['size'], isA<Map<String, Object?>>());
    expect(result.middlewareData['hide'], isA<Map<String, Object?>>());
    expect(result.middlewareData['arrow'], isA<Map<String, Object?>>());
  });

  test('doc/API.md "Writing your own middleware" compiles', () {
    final mw = _MyMiddleware();
    final out = mw.apply(MiddlewareState(
      anchor: Rect.fromLTWH(0, 0, 10, 10),
      floating: const Size(10, 10),
      viewport: Rect.fromLTWH(0, 0, 100, 100),
      placement: Placement.top,
      offset: Offset.zero,
      data: const {},
      recompute: (p) => Offset.zero,
    ));
    expect(out, isA<MiddlewareResult>());
  });

  testWidgets('README Quick start compiles and mounts', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: _QuickStart())));
    expect(find.text('Open'), findsOneWidget);
  });
}

class _MyMiddleware extends Middleware {
  @override
  String get name => 'my_middleware';

  @override
  MiddlewareResult apply(MiddlewareState state) =>
      MiddlewareResult(offset: state.offset, placement: state.placement);
}
