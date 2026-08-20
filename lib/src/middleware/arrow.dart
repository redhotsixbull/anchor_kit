import '../middleware.dart';

/// Computes where an arrow should sit on the floating element to visually
/// point at the anchor's centre. Result is stored in
/// `data['arrow']` as `{'x': double?, 'y': double?}`.
class Arrow extends Middleware {
  Arrow({this.padding = 4, this.arrowSize = 8});

  final double padding;
  final double arrowSize;

  @override
  String get name => 'arrow';

  @override
  MiddlewareResult apply(MiddlewareState state) {
    final anchorCenter = state.anchor.center;
    final floatingOffset = state.offset;
    double? x;
    double? y;

    if (state.placement.isVertical) {
      final desired = anchorCenter.dx - floatingOffset.dx - arrowSize / 2;
      final min = padding;
      final max = state.floating.width - arrowSize - padding;
      x = desired.clamp(min, max).toDouble();
    } else {
      final desired = anchorCenter.dy - floatingOffset.dy - arrowSize / 2;
      final min = padding;
      final max = state.floating.height - arrowSize - padding;
      y = desired.clamp(min, max).toDouble();
    }

    return MiddlewareResult(
      offset: state.offset,
      placement: state.placement,
      data: {
        'arrow': {'x': x, 'y': y}
      },
    );
  }
}
