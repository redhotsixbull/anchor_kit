import 'dart:ui';

import '../middleware.dart';

class Shift extends Middleware {
  Shift({this.padding = 0});

  final double padding;

  @override
  String get name => 'shift';

  @override
  MiddlewareResult apply(MiddlewareState state) {
    final viewport = state.viewport.deflate(padding);
    var dx = state.offset.dx;
    var dy = state.offset.dy;

    final width = state.floating.width;
    final height = state.floating.height;

    if (dx < viewport.left) dx = viewport.left;
    if (dx + width > viewport.right) dx = viewport.right - width;
    if (dy < viewport.top) dy = viewport.top;
    if (dy + height > viewport.bottom) dy = viewport.bottom - height;

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
}
