import '../middleware.dart';

/// Computes where an arrow should sit on the floating element to visually
/// point at the anchor's centre. Result is stored in
/// `data['arrow']` as `{'x': double?, 'y': double?}`.
///
/// The arrow position is clamped so the arrow always stays [padding] away from
/// the floating element's corners. If the floating element is too small to
/// honour [padding] on both sides, the arrow is centred instead of throwing.
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
      x = _clampArrow(desired, state.floating.width);
    } else {
      final desired = anchorCenter.dy - floatingOffset.dy - arrowSize / 2;
      y = _clampArrow(desired, state.floating.height);
    }

    return MiddlewareResult(
      offset: state.offset,
      placement: state.placement,
      data: {
        'arrow': {'x': x, 'y': y}
      },
    );
  }

  double _clampArrow(double desired, double floatingSize) {
    final min = padding;
    final max = floatingSize - arrowSize - padding;
    if (max < min) {
      // Too small to respect padding on both sides — centre the arrow.
      return (floatingSize - arrowSize) / 2;
    }
    return desired.clamp(min, max).toDouble();
  }
}
