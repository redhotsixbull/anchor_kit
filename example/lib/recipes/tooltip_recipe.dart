import 'package:anchor_kit/anchor_kit.dart';
import 'package:flutter/material.dart';

import '../widgets/arrow_bubble.dart';

/// Recipe: a hover / long-press tooltip built on `FloatingOverlay`.
///
/// Shows how a single anchored primitive replaces a bespoke tooltip: it follows
/// the anchor, flips when there is no room above, shifts to stay on-screen, and
/// draws an arrow pointing back at the trigger.
class TooltipRecipe extends StatefulWidget {
  const TooltipRecipe({super.key});

  @override
  State<TooltipRecipe> createState() => _TooltipRecipeState();
}

class _TooltipRecipeState extends State<TooltipRecipe> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tooltip')),
      body: Center(
        child: MouseRegion(
          onEnter: (_) => setState(() => _open = true),
          onExit: (_) => setState(() => _open = false),
          child: FloatingOverlay(
            isOpen: _open,
            placement: Placement.top,
            middleware: [
              OffsetMiddleware(10),
              Flip(padding: 8),
              Shift(padding: 8),
              Arrow(),
            ],
            floating: (context, position) => ArrowBubble(
              position: position,
              child: const SizedBox(
                width: 200,
                child: Text(
                  'I follow the anchor, flip when there is no room, '
                  'and point back with an arrow.',
                ),
              ),
            ),
            child: GestureDetector(
              onLongPress: () => setState(() => _open = !_open),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: FilledButton.tonalIcon(
                  onPressed: () {},
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Hover or long-press me'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
