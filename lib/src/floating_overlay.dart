import 'package:flutter/widgets.dart';

import 'compute_position.dart';
import 'middleware.dart';
import 'placement.dart';

typedef FloatingBuilder = Widget Function(
  BuildContext context,
  PositionResult position,
);

/// Renders [floating] into an [Overlay] positioned relative to the child
/// widget, according to [placement] + [middleware].
///
/// The overlay is inserted while [isOpen] is true and removed otherwise.
/// Positioning is re-computed on every frame the floating child rebuilds and
/// on scroll notifications from ancestors.
class FloatingOverlay extends StatefulWidget {
  const FloatingOverlay({
    super.key,
    required this.isOpen,
    required this.floating,
    required this.child,
    this.placement = Placement.bottom,
    this.middleware = const [],
  });

  final bool isOpen;
  final FloatingBuilder floating;
  final Widget child;
  final Placement placement;
  final List<Middleware> middleware;

  @override
  State<FloatingOverlay> createState() => _FloatingOverlayState();
}

class _FloatingOverlayState extends State<FloatingOverlay> {
  OverlayEntry? _entry;
  final _anchorKey = GlobalKey();

  @override
  void didUpdateWidget(covariant FloatingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      widget.isOpen ? _open() : _close();
    } else if (widget.isOpen) {
      _entry?.markNeedsBuild();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.isOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _open());
    }
  }

  void _open() {
    if (_entry != null) return;
    _entry = OverlayEntry(builder: _buildOverlay);
    Overlay.of(context).insert(_entry!);
  }

  void _close() {
    _entry?.remove();
    _entry = null;
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  Widget _buildOverlay(BuildContext overlayContext) {
    final anchorBox =
        _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (anchorBox == null || !anchorBox.hasSize) {
      return const SizedBox.shrink();
    }

    final anchorTopLeft = anchorBox.localToGlobal(Offset.zero);
    final anchorRect = anchorTopLeft & anchorBox.size;
    final viewport = Rect.fromLTWH(
      0,
      0,
      MediaQuery.of(overlayContext).size.width,
      MediaQuery.of(overlayContext).size.height,
    );

    return _MeasureAndPosition(
      anchor: anchorRect,
      viewport: viewport,
      placement: widget.placement,
      middleware: widget.middleware,
      builder: widget.floating,
    );
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (_) {
        _entry?.markNeedsBuild();
        return false;
      },
      child: KeyedSubtree(key: _anchorKey, child: widget.child),
    );
  }
}

class _MeasureAndPosition extends StatefulWidget {
  const _MeasureAndPosition({
    required this.anchor,
    required this.viewport,
    required this.placement,
    required this.middleware,
    required this.builder,
  });

  final Rect anchor;
  final Rect viewport;
  final Placement placement;
  final List<Middleware> middleware;
  final FloatingBuilder builder;

  @override
  State<_MeasureAndPosition> createState() => _MeasureAndPositionState();
}

class _MeasureAndPositionState extends State<_MeasureAndPosition> {
  Size? _measuredSize;
  final _measureKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final size = _measuredSize;

    if (size == null) {
      // First pass: render off-screen at (0,0) with visibility hidden,
      // measure, then rebuild.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final box = _measureKey.currentContext?.findRenderObject() as RenderBox?;
        if (box == null || !box.hasSize) return;
        setState(() => _measuredSize = box.size);
      });
      return Positioned(
        left: -9999,
        top: -9999,
        child: Offstage(
          child: KeyedSubtree(
            key: _measureKey,
            child: Builder(builder: (ctx) => widget.builder(
                  ctx,
                  PositionResult(
                    offset: Offset.zero,
                    placement: widget.placement,
                    middlewareData: const {},
                  ),
                )),
          ),
        ),
      );
    }

    final result = computePosition(
      anchor: widget.anchor,
      floating: size,
      viewport: widget.viewport,
      placement: widget.placement,
      middleware: widget.middleware,
    );

    return Positioned(
      left: result.offset.dx,
      top: result.offset.dy,
      child: widget.builder(context, result),
    );
  }
}
