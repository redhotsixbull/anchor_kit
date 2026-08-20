import 'package:flutter/scheduler.dart';
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
/// The overlay is inserted while [isOpen] is true and removed otherwise. While
/// open, the anchor's global rectangle is tracked once per frame: any change —
/// ancestor scrolling, window resize/rotation, or the anchor itself moving —
/// re-positions the floating element. The floating element is also re-measured
/// each frame, so content that changes size stays correctly positioned.
///
/// Set [barrierDismissible] with an [onDismiss] callback to have a tap anywhere
/// outside the floating element request a close (useful for dropdowns / selects
/// / popovers). The barrier is fully transparent and does not block the anchor
/// from re-opening.
class FloatingOverlay extends StatefulWidget {
  const FloatingOverlay({
    super.key,
    required this.isOpen,
    required this.floating,
    required this.child,
    this.placement = Placement.bottom,
    this.middleware = const [],
    this.barrierDismissible = false,
    this.onDismiss,
  });

  final bool isOpen;
  final FloatingBuilder floating;
  final Widget child;
  final Placement placement;
  final List<Middleware> middleware;

  /// If true (and [onDismiss] is provided), a transparent full-screen barrier
  /// is placed behind the floating element; tapping it calls [onDismiss].
  final bool barrierDismissible;

  /// Called when the barrier is tapped. Typically flips your `isOpen` state.
  final VoidCallback? onDismiss;

  @override
  State<FloatingOverlay> createState() => _FloatingOverlayState();
}

class _FloatingOverlayState extends State<FloatingOverlay> {
  OverlayEntry? _entry;
  final _anchorKey = GlobalKey();
  Rect? _lastAnchorRect;

  @override
  void initState() {
    super.initState();
    if (widget.isOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _open());
    }
  }

  @override
  void didUpdateWidget(covariant FloatingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      widget.isOpen ? _open() : _close();
    } else if (widget.isOpen) {
      _entry?.markNeedsBuild();
    }
  }

  void _open() {
    if (_entry != null || !mounted) return;
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    _entry = OverlayEntry(builder: _buildOverlay);
    overlay.insert(_entry!);
    _lastAnchorRect = null;
    _trackAnchor();
  }

  void _close() {
    _entry?.remove();
    _entry = null;
    _lastAnchorRect = null;
  }

  /// Re-arms itself every frame while the overlay is open, re-positioning only
  /// when the anchor's global rect actually changes (cheap: one localToGlobal
  /// per frame).
  void _trackAnchor() {
    if (_entry == null) return;
    final box = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize && box.attached) {
      final rect = box.localToGlobal(Offset.zero) & box.size;
      if (rect != _lastAnchorRect) {
        _lastAnchorRect = rect;
        _entry!.markNeedsBuild();
      }
    }
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) _trackAnchor();
    });
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
    final mediaSize = MediaQuery.of(overlayContext).size;
    final viewport = Rect.fromLTWH(0, 0, mediaSize.width, mediaSize.height);

    final positioned = _MeasureAndPosition(
      anchor: anchorRect,
      viewport: viewport,
      placement: widget.placement,
      middleware: widget.middleware,
      builder: widget.floating,
    );

    if (!widget.barrierDismissible || widget.onDismiss == null) {
      return positioned;
    }
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onDismiss,
            child: const SizedBox.expand(),
          ),
        ),
        positioned,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: _anchorKey, child: widget.child);
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

  void _scheduleMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = _measureKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      // Re-measure every frame so content that changes size stays positioned.
      if (_measuredSize != box.size) {
        setState(() => _measuredSize = box.size);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _scheduleMeasure();
    final size = _measuredSize;

    if (size == null) {
      // First pass: lay the child out invisibly so we can measure it, then
      // rebuild once its size is known.
      return Positioned(
        left: 0,
        top: 0,
        child: Offstage(
          child: KeyedSubtree(
            key: _measureKey,
            child: Builder(
              builder: (ctx) => widget.builder(
                ctx,
                PositionResult(
                  offset: Offset.zero,
                  placement: widget.placement,
                  middlewareData: const {},
                ),
              ),
            ),
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
      child: KeyedSubtree(
        key: _measureKey,
        child: widget.builder(context, result),
      ),
    );
  }
}
