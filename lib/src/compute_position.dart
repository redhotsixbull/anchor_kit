import 'dart:ui';

import 'middleware.dart';
import 'placement.dart';

class PositionResult {
  const PositionResult({
    required this.offset,
    required this.placement,
    required this.middlewareData,
  });

  final Offset offset;
  final Placement placement;
  final Map<String, Object?> middlewareData;
}

Offset _baseOffset({
  required Rect anchor,
  required Size floating,
  required Placement placement,
}) {
  final double x;
  final double y;

  switch (placement.side) {
    case PlacementSide.top:
      y = anchor.top - floating.height;
      x = _mainAxisAlign(
        anchorStart: anchor.left,
        anchorEnd: anchor.right,
        floatingSize: floating.width,
        align: placement.align,
      );
      break;
    case PlacementSide.bottom:
      y = anchor.bottom;
      x = _mainAxisAlign(
        anchorStart: anchor.left,
        anchorEnd: anchor.right,
        floatingSize: floating.width,
        align: placement.align,
      );
      break;
    case PlacementSide.left:
      x = anchor.left - floating.width;
      y = _mainAxisAlign(
        anchorStart: anchor.top,
        anchorEnd: anchor.bottom,
        floatingSize: floating.height,
        align: placement.align,
      );
      break;
    case PlacementSide.right:
      x = anchor.right;
      y = _mainAxisAlign(
        anchorStart: anchor.top,
        anchorEnd: anchor.bottom,
        floatingSize: floating.height,
        align: placement.align,
      );
      break;
  }

  return Offset(x, y);
}

double _mainAxisAlign({
  required double anchorStart,
  required double anchorEnd,
  required double floatingSize,
  required PlacementAlign align,
}) {
  switch (align) {
    case PlacementAlign.start:
      return anchorStart;
    case PlacementAlign.center:
      return anchorStart + (anchorEnd - anchorStart) / 2 - floatingSize / 2;
    case PlacementAlign.end:
      return anchorEnd - floatingSize;
  }
}

PositionResult computePosition({
  required Rect anchor,
  required Size floating,
  required Rect viewport,
  required Placement placement,
  List<Middleware> middleware = const [],
}) {
  var currentPlacement = placement;
  var currentOffset = _baseOffset(
    anchor: anchor,
    floating: floating,
    placement: currentPlacement,
  );
  final data = <String, Object?>{};

  for (final mw in middleware) {
    final result = mw.apply(MiddlewareState(
      anchor: anchor,
      floating: floating,
      viewport: viewport,
      placement: currentPlacement,
      offset: currentOffset,
      data: data,
      recompute: (nextPlacement) => _baseOffset(
        anchor: anchor,
        floating: floating,
        placement: nextPlacement,
      ),
    ));
    currentOffset = result.offset;
    currentPlacement = result.placement;
    if (result.data != null) data.addAll(result.data!);
  }

  return PositionResult(
    offset: currentOffset,
    placement: currentPlacement,
    middlewareData: data,
  );
}
