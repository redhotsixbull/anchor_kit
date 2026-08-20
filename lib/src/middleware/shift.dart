import 'dart:ui';

import '../middleware.dart';

/// Slides the floating element along the viewport so it stays visible, without
/// changing which side it is placed on (mirrors Floating UI's `shift`).
///
/// When the floating element is *larger* than the viewport on an axis, the
/// start edge (left / top) is kept visible rather than pinning the far edge,
/// so the element never appears shoved off the opposite side.
class Shift extends Middleware {
  Shift({this.padding = 0});

  final double padding;

  @override
  String get name => 'shift';

  @override
  MiddlewareResult apply(MiddlewareState state) {
    final viewport = state.viewport.deflate(padding);
    final width = state.floating.width;
    final height = state.floating.height;

    final dx = _clampAxis(state.offset.dx, width, viewport.left, viewport.right);
    final dy = _clampAxis(state.offset.dy, height, viewport.top, viewport.bottom);

    return MiddlewareResult(
      offset: Offset(dx, dy),
      placement: state.placement,
      data: {
        'shift': {
          'dx': dx - state.offset.dx,
          'dy': dy - state.offset.dy,
        }
      },
    );
  }

  double _clampAxis(double value, double size, double min, double max) {
    if (size > max - min) {
      // Larger than the available space: keep the start edge visible.
      return min;
    }
    if (value < min) return min;
    if (value + size > max) return max - size;
    return value;
  }
}
