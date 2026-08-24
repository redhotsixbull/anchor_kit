import 'dart:math' as math;

import '../middleware.dart';
import '../placement.dart';

/// Reports how much space the floating element has on its resolved placement
/// side, so it can constrain itself (e.g. a dropdown that caps its height to
/// the viewport and scrolls internally). Mirrors Floating UI's `size`.
///
/// Writes `data['size'] = {'availableWidth': double, 'availableHeight': double}`.
/// Read it in your `floating` builder and wrap the content in a
/// `ConstrainedBox(constraints: BoxConstraints(maxHeight: availableHeight, …))`
/// plus a scroll view.
///
/// Put it **after** `Offset`/`Flip`/`Shift` so it measures the final side. The
/// available space is computed from the floating element's current rect against
/// the (padded) viewport; because `FloatingOverlay` re-measures every frame, a
/// floating element that shrinks to fit settles in one extra frame.
class SizeMiddleware extends Middleware {
  SizeMiddleware({this.padding = 0});

  final double padding;

  @override
  String get name => 'size';

  @override
  MiddlewareResult apply(MiddlewareState state) {
    final vp = state.viewport.deflate(padding);
    final fr = state.offset & state.floating;

    final double availableWidth;
    final double availableHeight;
    switch (state.placement.side) {
      case PlacementSide.bottom:
        availableHeight = vp.bottom - state.offset.dy;
        availableWidth = vp.width;
      case PlacementSide.top:
        availableHeight = fr.bottom - vp.top;
        availableWidth = vp.width;
      case PlacementSide.right:
        availableWidth = vp.right - state.offset.dx;
        availableHeight = vp.height;
      case PlacementSide.left:
        availableWidth = fr.right - vp.left;
        availableHeight = vp.height;
    }

    return MiddlewareResult(
      offset: state.offset,
      placement: state.placement,
      data: {
        'size': {
          'availableWidth': math.max(0.0, availableWidth),
          'availableHeight': math.max(0.0, availableHeight),
        }
      },
    );
  }
}
