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
/// after it. Any gap contributed by an earlier `OffsetMiddleware` is preserved
/// across the chosen side: the offset is re-projected onto each candidate so a
/// re-placed element keeps the same distance from the anchor.
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
    final cands = candidates ?? _defaultCandidates(state.placement.align);

    // Nothing to choose from — leave the position untouched.
    if (cands.isEmpty) {
      return MiddlewareResult(
        offset: state.offset,
        placement: state.placement,
        data: {
          'autoPlacement': {'side': state.placement.side.name, 'changed': false}
        },
      );
    }

    // Whatever earlier middleware (typically OffsetMiddleware) added on top of
    // the base placement. Re-projecting this onto each candidate keeps the gap
    // consistent instead of snapping candidates back to the bare base offset.
    final priorDelta = state.offset - state.recompute(state.placement);

    Offset offsetFor(Placement p) =>
        state.recompute(p) +
        _reprojectDelta(priorDelta, state.placement.side, p.side);

    // Keep the current placement only if it is actually one of the candidates
    // and already fits — don't move it needlessly, but never preserve a side
    // the caller excluded from [candidates].
    if (cands.contains(state.placement) &&
        _fullyInside(state.offset & state.floating, vp)) {
      return MiddlewareResult(
        offset: state.offset,
        placement: state.placement,
        data: {
          'autoPlacement': {'side': state.placement.side.name, 'changed': false}
        },
      );
    }

    var bestPlacement = cands.first;
    var bestOffset = offsetFor(cands.first);
    var bestOverflow = double.infinity;

    for (final p in cands) {
      final off = offsetFor(p);
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

  /// Re-expresses an offset delta (contributed by earlier middleware for the
  /// `from` side) in terms of the `to` side, so an away-from-anchor gap stays a
  /// gap after a side change. Mirrors [OffsetMiddleware]'s axis convention:
  /// `main` is distance away from the anchor, `cross` is the perpendicular nudge
  /// (+x for vertical sides, +y for horizontal sides).
  Offset _reprojectDelta(Offset delta, PlacementSide from, PlacementSide to) {
    if (from == to || delta == Offset.zero) return delta;
    final (main, cross) = _toAxes(delta, from);
    return _fromAxes(main, cross, to);
  }

  (double, double) _toAxes(Offset d, PlacementSide side) => switch (side) {
        PlacementSide.top => (-d.dy, d.dx),
        PlacementSide.bottom => (d.dy, d.dx),
        PlacementSide.left => (-d.dx, d.dy),
        PlacementSide.right => (d.dx, d.dy),
      };

  Offset _fromAxes(double main, double cross, PlacementSide side) =>
      switch (side) {
        PlacementSide.top => Offset(cross, -main),
        PlacementSide.bottom => Offset(cross, main),
        PlacementSide.left => Offset(-main, cross),
        PlacementSide.right => Offset(main, cross),
      };

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
