import 'package:anchor_kit/anchor_kit.dart';
import 'package:flutter/material.dart';

import '../widgets/arrow_bubble.dart';

/// Recipe: a rich popover card with an arrow, and a placement selector so you
/// can watch flip / shift / arrow react to every side.
class PopoverRecipe extends StatefulWidget {
  const PopoverRecipe({super.key});

  @override
  State<PopoverRecipe> createState() => _PopoverRecipeState();
}

class _PopoverRecipeState extends State<PopoverRecipe> {
  bool _open = false;
  Placement _placement = Placement.top;

  static const _placements = [
    ('top', Placement.top),
    ('bottom', Placement.bottom),
    ('left', Placement.left),
    ('right', Placement.right),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Popover card')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<Placement>(
              segments: [
                for (final (label, p) in _placements)
                  ButtonSegment(value: p, label: Text(label)),
              ],
              selected: {_placement},
              onSelectionChanged: (s) => setState(() => _placement = s.first),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Center(
              child: FloatingOverlay(
                isOpen: _open,
                placement: _placement,
                middleware: [
                  OffsetMiddleware(12),
                  Flip(padding: 12),
                  Shift(padding: 12),
                  Arrow(),
                ],
                barrierDismissible: true,
                onDismiss: () => setState(() => _open = false),
                floating: (context, position) => ArrowBubble(
                  position: position,
                  color: Theme.of(context).colorScheme.inverseSurface,
                  child: SizedBox(
                    width: 220,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Placed on ${position.placement.side.name}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text(
                          'Offset → Flip → Shift → Arrow ran in order to land here. '
                          'Try a placement with no room and watch it flip.',
                        ),
                      ],
                    ),
                  ),
                ),
                child: FilledButton(
                  onPressed: () => setState(() => _open = !_open),
                  child: const Text('Toggle popover'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
