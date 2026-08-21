import 'dart:ui';

import '../middleware.dart';

/// Slides the floating element so it stays visible, without changing which side
/// it is placed on (mirrors Floating UI's `shift`).
///
/// By default it only shifts along the **main axis** — the axis *parallel* to
/// the anchor edge (horizontal for `top`/`bottom`, vertical for `left`/`right`).
/// The cross axis (toward/away from the anchor) is left alone so the floating
/// element never detaches from its anchor; enable it with `crossAxis: true`.
///
/// When the floating element is *larger* than the available space on an axis,
/// the logical **start** edge is kept visible (left for LTR, right for RTL via
/// [rtl]; top for the vertical axis) rather than pinning the far edge.
class Shift extends Middleware {
  Shift({
    this.padding = 0,
    this.mainAxis = true,
    this.crossAxis = false,
    this.rtl = false,
  });

  final double padding;

  /// Clamp along the axis parallel to the anchor edge. On by default.
  final bool mainAxis;

  /// Clamp along the axis perpendicular to the anchor edge (can detach the
  /// floating element from the anchor). Off by default.
  final bool crossAxis;

  /// Right-to-left: keep the right edge visible for oversized elements on the
  /// horizontal axis.
  final bool rtl;

  @override
  String get name => 'shift';

  @override
  MiddlewareResult apply(MiddlewareState state) {
    final viewport = state.viewport.deflate(padding);
    final width = state.floating.width;
    final height = state.floating.height;
    final isVertical = state.placement.isVertical;

    var dx = state.offset.dx;
    var dy = state.offset.dy;

    // Main axis = the one parallel to the anchor edge (x for vertical placements,
    // y for horizontal placements).
    if (mainAxis) {
      if (isVertical) {
        dx = _clampAxis(dx, width, viewport.left, viewport.right, rtl: rtl);
      } else {
        dy = _clampAxis(dy, height, viewport.top, viewport.bottom);
      }
    }
    if (crossAxis) {
      if (isVertical) {
        dy = _clampAxis(dy, height, viewport.top, viewport.bottom);
      } else {
        dx = _clampAxis(dx, width, viewport.left, viewport.right, rtl: rtl);
      }
    }

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

  double _clampAxis(double value, double size, double min, double max,
      {bool rtl = false}) {
    if (size > max - min) {
      // Larger than the available space: keep the logical start edge visible.
      return rtl ? max - size : min;
    }
    if (value < min) return min;
    if (value + size > max) return max - size;
    return value;
  }
}
