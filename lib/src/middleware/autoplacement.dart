import 'dart:ui';

import '../middleware.dart';
import '../placement.dart';

/// Chooses the placement with the most room, among [candidates] (default: the
/// four sides keeping the current alignment). Mirrors Floating UI's
/// `autoPlacement`.
///
/// The first candidate that fully fits the (padded) viewport wins; otherwise the
/// one that overflows the least is chosen. Records the pick in
/// `data['autoPlacement'] = {'side': ..., 'changed': bool}`.
///
/// Use this *instead of* `Flip` (both resolve the side). Put `Shift`/`Size`
/// after it.
class AutoPlacement extends Middleware {
  AutoPlacement({this.padding = 0, this.candidates});

  final double padding;

  /// Placements to consider. When null, the four sides with the current
  /// alignment are used.
  final List<Placement>? candidates;

  @override
  String get name => 'autoPlacement';

  @override
  MiddlewareResult apply(MiddlewareState state) {
    final vp = state.viewport.deflate(padding);

    // Keep the current placement if it already fits — don't move it needlessly.
    if (_fullyInside(state.offset & state.floating, vp)) {
      return MiddlewareResult(
        offset: state.offset,
        placement: state.placement,
        data: {
          'autoPlacement': {'side': state.placement.side.name, 'changed': false}
        },
      );
    }

    final cands = candidates ?? _defaultCandidates(state.placement.align);

    var bestPlacement = state.placement;
    var bestOffset = state.offset;
    var bestOverflow = double.infinity;

    for (final p in cands) {
      final off = state.recompute(p);
      final rect = off & state.floating;
      if (_fullyInside(rect, vp)) {
        bestPlacement = p;
        bestOffset = off;
        bestOverflow = 0;
        break;
      }
      final ov = _overflow(rect, vp);
      if (ov < bestOverflow) {
        bestOverflow = ov;
        bestPlacement = p;
        bestOffset = off;
      }
    }

    return MiddlewareResult(
      offset: bestOffset,
      placement: bestPlacement,
      data: {
        'autoPlacement': {
          'side': bestPlacement.side.name,
          'changed': bestPlacement != state.placement,
        }
      },
    );
  }

  List<Placement> _defaultCandidates(PlacementAlign align) => [
        Placement(PlacementSide.top, align),
        Placement(PlacementSide.right, align),
        Placement(PlacementSide.bottom, align),
        Placement(PlacementSide.left, align),
      ];

  bool _fullyInside(Rect inner, Rect outer) =>
      inner.left >= outer.left &&
      inner.top >= outer.top &&
      inner.right <= outer.right &&
      inner.bottom <= outer.bottom;

  double _overflow(Rect inner, Rect outer) {
    double over(double d) => d > 0 ? d : 0.0;
    return over(outer.left - inner.left) +
        over(outer.top - inner.top) +
        over(inner.right - outer.right) +
        over(inner.bottom - outer.bottom);
  }
}
