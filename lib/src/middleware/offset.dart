import 'dart:ui';

import '../middleware.dart';
import '../placement.dart';

/// Pushes the floating element away from the anchor along the placement's main
/// axis by [distance], and optionally along the cross axis by [crossAxis].
///
/// Axis convention:
///   * `distance` always moves the floating element *away* from the anchor
///     (up for `top`, down for `bottom`, left for `left`, right for `right`).
///   * `crossAxis` shifts along the perpendicular axis: for vertical placements
///     (`top`/`bottom`) positive moves right; for horizontal placements
///     (`left`/`right`) positive moves down.
class OffsetMiddleware extends Middleware {
  OffsetMiddleware(this.distance, {this.crossAxis = 0});

  final double distance;
  final double crossAxis;

  @override
  String get name => 'offset';

  @override
  MiddlewareResult apply(MiddlewareState state) {
    final placement = state.placement;
    var offset = state.offset;
    switch (placement.side) {
      case PlacementSide.top:
        offset = Offset(offset.dx + crossAxis, offset.dy - distance);
      case PlacementSide.bottom:
        offset = Offset(offset.dx + crossAxis, offset.dy + distance);
      case PlacementSide.left:
        offset = Offset(offset.dx - distance, offset.dy + crossAxis);
      case PlacementSide.right:
        offset = Offset(offset.dx + distance, offset.dy + crossAxis);
    }
    return MiddlewareResult(offset: offset, placement: placement);
  }
}

/// Deprecated alias for [OffsetMiddleware]. The old name was ambiguous with
/// `dart:ui`'s `Offset`.
@Deprecated('Renamed to OffsetMiddleware. Offset4 will be removed in v0.1.0.')
class Offset4 extends OffsetMiddleware {
  Offset4(super.distance, {super.crossAxis});
}
