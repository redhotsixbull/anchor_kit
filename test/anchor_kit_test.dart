import 'package:anchor_kit/anchor_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const viewport = Rect.fromLTWH(0, 0, 400, 800);

  group('Placement', () {
    test('flipSide flips to the opposite side, keeping alignment', () {
      expect(Placement.top.flipSide(), Placement.bottom);
      expect(Placement.bottomStart.flipSide(), Placement.topStart);
      expect(Placement.left.flipSide(), Placement.right);
      expect(Placement.rightEnd.flipSide(), Placement.leftEnd);
    });

    test('equality and hashCode', () {
      expect(const Placement(PlacementSide.top), Placement.top);
      expect(Placement.top == Placement.topStart, isFalse);
      expect(Placement.top.hashCode, Placement.top.hashCode);
    });
  });

  group('computePosition base placement', () {
    test('bottom-center centers floating under the anchor', () {
      final result = computePosition(
        anchor: const Rect.fromLTWH(100, 100, 40, 40),
        floating: const Size(60, 30),
        viewport: viewport,
        placement: Placement.bottom,
      );
      expect(result.offset, const Offset(90, 140));
      expect(result.placement, Placement.bottom);
    });

    test('top-start aligns left edges', () {
      final result = computePosition(
        anchor: const Rect.fromLTWH(50, 200, 100, 40),
        floating: const Size(80, 30),
        viewport: viewport,
        placement: Placement.topStart,
      );
      expect(result.offset, const Offset(50, 170));
    });

    test('right-end aligns bottom edges', () {
      final result = computePosition(
        anchor: const Rect.fromLTWH(50, 50, 40, 40),
        floating: const Size(80, 30),
        viewport: viewport,
        placement: Placement.rightEnd,
      );
      expect(result.offset, const Offset(90, 60));
    });

    test('left places floating to the left, vertically centered', () {
      final result = computePosition(
        anchor: const Rect.fromLTWH(200, 100, 40, 40),
        floating: const Size(50, 20),
        viewport: viewport,
        placement: Placement.left,
      );
      expect(result.offset, const Offset(150, 110));
    });

    test('bottom-end aligns right edges', () {
      final result = computePosition(
        anchor: const Rect.fromLTWH(100, 100, 100, 40),
        floating: const Size(40, 30),
        viewport: viewport,
        placement: Placement.bottomEnd,
      );
      expect(result.offset, const Offset(160, 140));
    });
  });

  group('OffsetMiddleware', () {
    test('pushes floating away from anchor along the main axis', () {
      final result = computePosition(
        anchor: const Rect.fromLTWH(100, 100, 40, 40),
        floating: const Size(60, 30),
        viewport: viewport,
        placement: Placement.bottom,
        middleware: [OffsetMiddleware(10)],
      );
      expect(result.offset, const Offset(90, 150));
    });

    test('crossAxis shifts along the perpendicular axis', () {
      final result = computePosition(
        anchor: const Rect.fromLTWH(100, 100, 40, 40),
        floating: const Size(60, 30),
        viewport: viewport,
        placement: Placement.bottom,
        middleware: [OffsetMiddleware(0, crossAxis: 5)],
      );
      expect(result.offset, const Offset(95, 140));
    });

    test('deprecated Offset4 alias still behaves the same', () {
      final result = computePosition(
        anchor: const Rect.fromLTWH(100, 100, 40, 40),
        floating: const Size(60, 30),
        viewport: viewport,
        placement: Placement.bottom,
        // ignore: deprecated_member_use_from_same_package
        middleware: [Offset4(10)],
      );
      expect(result.offset, const Offset(90, 150));
    });
  });

  group('Flip', () {
    test('flips top → bottom when anchor is at the top edge', () {
      final result = computePosition(
        anchor: const Rect.fromLTWH(100, 0, 40, 40),
        floating: const Size(60, 60),
        viewport: viewport,
        placement: Placement.top,
        middleware: [Flip()],
      );
      expect(result.placement, Placement.bottom);
      expect(result.middlewareData['flipped'], true);
    });

    test('does NOT flip a placement that already fits (edge-flush)', () {
      // Floating sits flush against the viewport top but fully inside — the old
      // `overlaps` gate would wrongly flip this.
      final result = computePosition(
        anchor: const Rect.fromLTWH(100, 60, 40, 40),
        floating: const Size(60, 60),
        viewport: viewport,
        placement: Placement.top,
        middleware: [Flip()],
      );
      expect(result.placement, Placement.top);
      expect(result.middlewareData['flipped'], isNull);
    });

    test('when neither side fits, keeps the side that overflows least', () {
      // Tall floating in a short viewport. Anchor near the top: bottom has more
      // room than top, so flip should pick bottom even though neither fully fits.
      const shortViewport = Rect.fromLTWH(0, 0, 400, 100);
      final result = computePosition(
        anchor: const Rect.fromLTWH(100, 30, 40, 20),
        floating: const Size(60, 90),
        viewport: shortViewport,
        placement: Placement.top,
        middleware: [Flip()],
      );
      expect(result.placement, Placement.bottom,
          reason: 'bottom overflows less than top here');
      expect(result.middlewareData['flipped'], true);
    });
  });

  group('Shift', () {
    test('clamps floating inside the viewport', () {
      final result = computePosition(
        anchor: const Rect.fromLTWH(380, 100, 40, 40),
        floating: const Size(100, 30),
        viewport: viewport,
        placement: Placement.bottomStart,
        middleware: [Shift(padding: 8)],
      );
      expect(result.offset.dx + 100, lessThanOrEqualTo(400 - 8 + 0.001));
      expect(result.offset.dx, greaterThanOrEqualTo(8 - 0.001));
    });

    test('floating wider than viewport keeps the start edge visible', () {
      const narrow = Rect.fromLTWH(0, 0, 100, 800);
      final result = computePosition(
        anchor: const Rect.fromLTWH(20, 100, 40, 40),
        floating: const Size(200, 30), // wider than the 100-wide viewport
        viewport: narrow,
        placement: Placement.bottomStart,
        middleware: [Shift(padding: 8)],
      );
      // Start edge pinned to the padded viewport left, not shoved off-screen.
      expect(result.offset.dx, closeTo(8, 0.001));
    });
  });

  group('Arrow', () {
    test('computes a clamped x for vertical placement', () {
      final result = computePosition(
        anchor: const Rect.fromLTWH(100, 100, 40, 40),
        floating: const Size(60, 30),
        viewport: viewport,
        placement: Placement.bottom,
        middleware: [Arrow(arrowSize: 8, padding: 4)],
      );
      final arrow = result.middlewareData['arrow']! as Map<String, Object?>;
      final x = arrow['x']! as double;
      expect(arrow['y'], isNull);
      // Clamped within [padding, width - arrowSize - padding] = [4, 48].
      expect(x, greaterThanOrEqualTo(4));
      expect(x, lessThanOrEqualTo(48));
    });

    test('does not throw when floating is too small; centers the arrow', () {
      final result = computePosition(
        anchor: const Rect.fromLTWH(100, 100, 40, 40),
        floating: const Size(10, 30), // width < arrowSize + 2*padding
        viewport: viewport,
        placement: Placement.bottom,
        middleware: [Arrow(arrowSize: 8, padding: 4)],
      );
      final arrow = result.middlewareData['arrow']! as Map<String, Object?>;
      expect(arrow['x'], closeTo((10 - 8) / 2, 0.001)); // centered
    });
  });

  group('middleware pipeline', () {
    test('offset → flip → shift compose in order', () {
      final result = computePosition(
        anchor: const Rect.fromLTWH(360, 0, 40, 40),
        floating: const Size(120, 60),
        viewport: viewport,
        placement: Placement.top,
        middleware: [OffsetMiddleware(8), Flip(padding: 8), Shift(padding: 8)],
      );
      // Anchor at top → flips to bottom; near right edge → shifts left in-bounds.
      expect(result.placement, Placement.bottom);
      expect(result.offset.dx + 120, lessThanOrEqualTo(400 - 8 + 0.001));
    });
  });

  group('SizeMiddleware', () {
    Map<String, Object?> sizeData(Placement p, Rect anchor, Size floating) {
      final r = computePosition(
        anchor: anchor,
        floating: floating,
        viewport: viewport,
        placement: p,
        middleware: [SizeMiddleware()],
      );
      return r.middlewareData['size']! as Map<String, Object?>;
    }

    test('reports space below for a bottom placement', () {
      final s = sizeData(
          Placement.bottom, const Rect.fromLTWH(100, 100, 40, 40), const Size(60, 30));
      expect(s['availableHeight'], 800 - 140); // viewport.bottom - anchor.bottom
      expect(s['availableWidth'], 400);
    });

    test('reports space above for a top placement', () {
      final s = sizeData(
          Placement.top, const Rect.fromLTWH(100, 700, 40, 40), const Size(60, 30));
      expect(s['availableHeight'], 700); // anchor.top - viewport.top
    });

    test('reports space to the right for a right placement', () {
      final s = sizeData(
          Placement.right, const Rect.fromLTWH(100, 100, 40, 40), const Size(60, 30));
      expect(s['availableWidth'], 400 - 140); // viewport.right - anchor.right
      expect(s['availableHeight'], 800);
    });

    test('never reports negative space', () {
      final s = sizeData(Placement.bottom,
          const Rect.fromLTWH(100, 780, 40, 40), const Size(60, 30));
      expect((s['availableHeight'] as double) >= 0, isTrue);
    });
  });

  group('Shift axes & RTL', () {
    test('default clamps the main axis only (does not detach on cross axis)', () {
      // Anchor near the top; a top-placed floating overflows the top edge.
      final result = computePosition(
        anchor: const Rect.fromLTWH(100, 20, 40, 40),
        floating: const Size(60, 60),
        viewport: viewport,
        placement: Placement.top,
        middleware: [Shift()],
      );
      // Cross axis (dy) is NOT clamped by default → stays overflowing (-40).
      expect(result.offset.dy, -40);
    });

    test('crossAxis: true clamps toward the anchor', () {
      final result = computePosition(
        anchor: const Rect.fromLTWH(100, 20, 40, 40),
        floating: const Size(60, 60),
        viewport: viewport,
        placement: Placement.top,
        middleware: [Shift(crossAxis: true)],
      );
      expect(result.offset.dy, 0); // clamped to viewport.top
    });

    test('rtl keeps the right edge visible for an oversized element', () {
      const narrow = Rect.fromLTWH(0, 0, 100, 800);
      final result = computePosition(
        anchor: const Rect.fromLTWH(20, 100, 40, 40),
        floating: const Size(200, 30), // wider than the 100 viewport
        viewport: narrow,
        placement: Placement.bottomStart,
        middleware: [Shift(rtl: true)],
      );
      // Right edge pinned to the viewport right: dx = right - width = 100 - 200.
      expect(result.offset.dx, closeTo(-100, 0.001));
    });
  });

  group('AutoPlacement', () {
    test('picks the side with the most room', () {
      final result = computePosition(
        anchor: const Rect.fromLTWH(100, 0, 40, 40), // at the top edge
        floating: const Size(60, 60),
        viewport: viewport,
        placement: Placement.top, // would overflow
        middleware: [AutoPlacement()],
      );
      expect(result.placement.side, PlacementSide.bottom);
      final data = result.middlewareData['autoPlacement']! as Map<String, Object?>;
      expect(data['side'], 'bottom');
      expect(data['changed'], true);
    });

    test('keeps a placement that already fits', () {
      final result = computePosition(
        anchor: const Rect.fromLTWH(180, 380, 40, 40), // middle
        floating: const Size(60, 40),
        viewport: viewport,
        placement: Placement.bottom,
        middleware: [AutoPlacement()],
      );
      expect(result.placement.side, PlacementSide.bottom);
    });

    test('preserves an earlier OffsetMiddleware gap after it re-places', () {
      final result = computePosition(
        anchor: const Rect.fromLTWH(180, 0, 40, 40), // at the top edge
        floating: const Size(60, 60),
        viewport: viewport,
        placement: Placement.top, // would overflow → re-places to bottom
        middleware: [OffsetMiddleware(8), AutoPlacement()],
      );
      expect(result.placement.side, PlacementSide.bottom);
      // The 8px gap survives the side change instead of snapping to the anchor.
      expect(result.offset.dy, 48); // anchor.bottom (40) + gap (8)
    });

    test('does not keep the current placement when it is not a candidate', () {
      final result = computePosition(
        anchor: const Rect.fromLTWH(180, 380, 40, 40), // middle; right fits fine
        floating: const Size(60, 40),
        viewport: viewport,
        placement: Placement.right,
        // right fits, but the caller restricted the candidate set to top.
        middleware: [AutoPlacement(candidates: [Placement.top])],
      );
      expect(result.placement, Placement.top);
      final data = result.middlewareData['autoPlacement']! as Map<String, Object?>;
      expect(data['changed'], true);
    });
  });

  group('Hide', () {
    test('referenceHidden is false while the anchor is on-screen', () {
      final result = computePosition(
        anchor: const Rect.fromLTWH(100, 100, 40, 40),
        floating: const Size(60, 30),
        viewport: viewport,
        placement: Placement.bottom,
        middleware: [Hide()],
      );
      final data = result.middlewareData['hide']! as Map<String, Object?>;
      expect(data['referenceHidden'], false);
    });

    test('referenceHidden is true when the anchor is off-screen', () {
      final result = computePosition(
        anchor: const Rect.fromLTWH(500, 900, 40, 40), // outside 400x800
        floating: const Size(60, 30),
        viewport: viewport,
        placement: Placement.bottom,
        middleware: [Hide()],
      );
      final data = result.middlewareData['hide']! as Map<String, Object?>;
      expect(data['referenceHidden'], true);
    });
  });

  group('FloatingOverlay widget', () {
    testWidgets('renders the floating child near the anchor when open',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FloatingOverlay(
                isOpen: true,
                placement: Placement.bottom,
                middleware: [OffsetMiddleware(8)],
                floating: _pop,
                child: const SizedBox(
                    width: 100,
                    height: 40,
                    child: ColoredBox(color: Color(0xFF0000FF))),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('pop'), findsOneWidget);
    });

    testWidgets('re-positions when an ancestor scrolls', (tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              controller: controller,
              children: const [
                SizedBox(height: 200),
                FloatingOverlay(
                  isOpen: true,
                  placement: Placement.bottom,
                  floating: _pop,
                  child: SizedBox(
                      width: 100,
                      height: 40,
                      child: ColoredBox(color: Color(0xFF00FF00))),
                ),
                SizedBox(height: 1200),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final before = tester.getTopLeft(find.text('pop'));

      controller.jumpTo(150);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));

      final after = tester.getTopLeft(find.text('pop'));
      expect(after.dy, lessThan(before.dy - 50),
          reason: 'floating element follows the anchor as the page scrolls');

      controller.dispose();
    });

    testWidgets('barrierDismissible calls onDismiss on an outside tap',
        (tester) async {
      var dismissed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FloatingOverlay(
                isOpen: true,
                placement: Placement.bottom,
                barrierDismissible: true,
                onDismiss: () => dismissed++,
                floating: _pop,
                child: const SizedBox(
                    width: 100,
                    height: 40,
                    child: ColoredBox(color: Color(0xFFFF00FF))),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('pop'), findsOneWidget);

      // Tap a corner far from the floating element → barrier catches it.
      await tester.tapAt(const Offset(5, 5));
      await tester.pump();
      expect(dismissed, 1);

      // Tapping the floating element itself must NOT dismiss.
      await tester.tap(find.text('pop'));
      await tester.pump();
      expect(dismissed, 1);
    });

    testWidgets('does not throw when rebuilt during layout (under LayoutBuilder)',
        (tester) async {
      // Regression: an open FloatingOverlay nested under a LayoutBuilder gets
      // rebuilt *during* the layout pass when constraints change. Mutating the
      // Overlay synchronously from didUpdateWidget then threw "setState() called
      // during build". The mutation must be deferred to post-frame.
      final width = ValueNotifier<double>(300);
      addTearDown(width.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<double>(
              valueListenable: width,
              builder: (_, w, __) => SizedBox(
                width: w,
                child: LayoutBuilder(
                  builder: (context, _) => Center(
                    child: FloatingOverlay(
                      isOpen: true,
                      placement: Placement.bottom,
                      floating: _pop,
                      child: const SizedBox(width: 50, height: 20),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.takeException(), isNull);

      // Force a relayout → LayoutBuilder rebuilds the FloatingOverlay mid-layout.
      width.value = 200;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.takeException(), isNull);
      expect(find.text('pop'), findsOneWidget);
    });
  });
}

Widget _pop(BuildContext context, PositionResult position) => const Material(
      child: Padding(
        padding: EdgeInsets.all(6),
        child: Text('pop', textDirection: TextDirection.ltr),
      ),
    );
