import 'dart:ui';

import '../middleware.dart';

/// Flips the placement to the opposite side when the floating element would
/// overflow the viewport on its current side.
///
/// Behaviour (mirrors Floating UI's `flip`):
///   * If the current placement fully fits inside the (padded) viewport, it is
///     kept unchanged.
///   * Otherwise the opposite side is tried; if it fully fits, we flip to it.
///   * If *neither* side fully fits, we keep whichever side overflows the
///     viewport by the least amount (rather than blindly keeping the original).
class Flip extends Middleware {
  Flip({this.padding = 0});

  final double padding;

  @override
  String get name => 'flip';

  @override
  MiddlewareResult apply(MiddlewareState state) {
    final viewport = state.viewport.deflate(padding);
    final originalRect = state.offset & state.floating;

    if (_fullyInside(originalRect, viewport)) {
      return MiddlewareResult(
        offset: state.offset,
        placement: state.placement,
      );
    }

    final flipped = state.placement.flipSide();
    final flippedOffset = state.recompute(flipped);
    final flippedRect = flippedOffset & state.floating;

    if (_fullyInside(flippedRect, viewport)) {
      return MiddlewareResult(
        offset: flippedOffset,
        placement: flipped,
        data: const {'flipped': true},
      );
    }

    // Neither side fully fits — choose the lesser evil.
    if (_overflow(flippedRect, viewport) < _overflow(originalRect, viewport)) {
      return MiddlewareResult(
        offset: flippedOffset,
        placement: flipped,
        data: const {'flipped': true},
      );
    }
    return MiddlewareResult(offset: state.offset, placement: state.placement);
  }

  bool _fullyInside(Rect inner, Rect outer) {
    return inner.left >= outer.left &&
        inner.top >= outer.top &&
        inner.right <= outer.right &&
        inner.bottom <= outer.bottom;
  }

  /// Total distance [inner] pokes outside [outer] across all four edges.
  double _overflow(Rect inner, Rect outer) {
    double over(double d) => d > 0 ? d : 0.0;
    return over(outer.left - inner.left) +
        over(outer.top - inner.top) +
        over(inner.right - outer.right) +
        over(inner.bottom - outer.bottom);
  }
}
