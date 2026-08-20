import 'dart:ui';

import '../middleware.dart';
import '../placement.dart';

class Offset4 extends Middleware {
  Offset4(this.distance, {this.crossAxis = 0});

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
