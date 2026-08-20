import 'dart:ui';

import 'package:anchor_kit/anchor_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const viewport = Rect.fromLTWH(0, 0, 400, 800);

  group('computePosition base placement', () {
    test('bottom-center centers floating under the anchor', () {
      final anchor = const Rect.fromLTWH(100, 100, 40, 40);
      final result = computePosition(
        anchor: anchor,
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
  });

  group('middleware', () {
    test('Offset4 pushes floating away from anchor', () {
      final result = computePosition(
        anchor: const Rect.fromLTWH(100, 100, 40, 40),
        floating: const Size(60, 30),
        viewport: viewport,
        placement: Placement.bottom,
        middleware: [Offset4(10)],
      );
      expect(result.offset, const Offset(90, 150));
    });

    test('Flip flips top → bottom when anchor is at the top of viewport', () {
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

    test('Shift clamps floating inside the viewport', () {
      final result = computePosition(
        anchor: const Rect.fromLTWH(380, 100, 40, 40),
        floating: const Size(100, 30),
        viewport: viewport,
        placement: Placement.bottomStart,
        middleware: [Shift(padding: 8)],
      );
      expect(result.offset.dx + 100, lessThanOrEqualTo(400 - 8 + 0.001));
    });

    test('Arrow computes clamped x for vertical placement', () {
      final result = computePosition(
        anchor: const Rect.fromLTWH(100, 100, 40, 40),
        floating: const Size(60, 30),
        viewport: viewport,
        placement: Placement.bottom,
        middleware: [Arrow(arrowSize: 8, padding: 4)],
      );
      final arrow = result.middlewareData['arrow'] as Map<String, Object?>;
      expect(arrow['x'], isNotNull);
      expect(arrow['y'], isNull);
    });
  });
}
