import '../middleware.dart';

/// Flags when the anchor has scrolled (mostly) out of the viewport, so you can
/// hide the floating element instead of leaving it pointing at nothing. Mirrors
/// Floating UI's `hide`.
///
/// Writes `data['hide'] = {'referenceHidden': bool}`. `referenceHidden` is true
/// once the anchor no longer overlaps the (padded) viewport.
class Hide extends Middleware {
  Hide({this.padding = 0});

  final double padding;

  @override
  String get name => 'hide';

  @override
  MiddlewareResult apply(MiddlewareState state) {
    final vp = state.viewport.deflate(padding);
    final referenceHidden = !vp.overlaps(state.anchor);
    return MiddlewareResult(
      offset: state.offset,
      placement: state.placement,
      data: {
        'hide': {'referenceHidden': referenceHidden}
      },
    );
  }
}
