import 'package:anchor_kit/anchor_kit.dart';
import 'package:flutter/material.dart';

/// A speech-bubble style container that draws a little arrow pointing back at
/// the anchor, using the `arrow` middleware data from a [PositionResult].
///
/// Pass the [position] you receive in `FloatingOverlay.floating` and include an
/// `Arrow()` middleware so `position.middlewareData['arrow']` is populated.
class ArrowBubble extends StatelessWidget {
  const ArrowBubble({
    super.key,
    required this.position,
    required this.child,
    this.color = const Color(0xFF263238),
    this.arrowSize = 9,
  });

  final PositionResult position;
  final Widget child;
  final Color color;
  final double arrowSize;

  @override
  Widget build(BuildContext context) {
    final bubble = Material(
      color: color,
      elevation: 6,
      borderRadius: BorderRadius.circular(8),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: child,
        ),
      ),
    );

    final arrow = position.middlewareData['arrow'] as Map<String, Object?>?;
    if (arrow == null) return bubble;

    // A rotated square makes a clean triangle where it pokes out of the bubble.
    final diamond = Transform.rotate(
      angle: 0.7853981633974483, // 45°
      child: Container(width: arrowSize, height: arrowSize, color: color),
    );

    final x = arrow['x'] as double?;
    final y = arrow['y'] as double?;
    final half = arrowSize / 2;

    Widget positionedArrow;
    switch (position.placement.side) {
      case PlacementSide.top: // bubble above anchor → arrow on the bottom edge
        positionedArrow = Positioned(bottom: -half, left: x, child: diamond);
      case PlacementSide.bottom: // arrow on the top edge
        positionedArrow = Positioned(top: -half, left: x, child: diamond);
      case PlacementSide.left: // arrow on the right edge
        positionedArrow = Positioned(right: -half, top: y, child: diamond);
      case PlacementSide.right: // arrow on the left edge
        positionedArrow = Positioned(left: -half, top: y, child: diamond);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [bubble, positionedArrow],
    );
  }
}
