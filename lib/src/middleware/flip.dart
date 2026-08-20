import 'dart:ui';

import '../middleware.dart';

class Flip extends Middleware {
  Flip({this.padding = 0});

  final double padding;

  @override
  String get name => 'flip';

  @override
  MiddlewareResult apply(MiddlewareState state) {
    final floatingRect = state.offset & state.floating;
    final viewport = state.viewport.deflate(padding);
    if (viewport.overlaps(floatingRect) &&
        _fullyInside(floatingRect, viewport)) {
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
        data: {'flipped': true},
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
}
