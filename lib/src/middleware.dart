import 'dart:ui';

import 'placement.dart';

typedef RecomputeBase = Offset Function(Placement placement);

class MiddlewareState {
  const MiddlewareState({
    required this.anchor,
    required this.floating,
    required this.viewport,
    required this.placement,
    required this.offset,
    required this.data,
    required this.recompute,
  });

  final Rect anchor;
  final Size floating;
  final Rect viewport;
  final Placement placement;
  final Offset offset;
  final Map<String, Object?> data;
  final RecomputeBase recompute;
}

class MiddlewareResult {
  const MiddlewareResult({
    required this.offset,
    required this.placement,
    this.data,
  });

  final Offset offset;
  final Placement placement;
  final Map<String, Object?>? data;
}

abstract class Middleware {
  String get name;
  MiddlewareResult apply(MiddlewareState state);
}
