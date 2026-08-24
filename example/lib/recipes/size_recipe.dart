import 'package:anchor_kit/anchor_kit.dart';
import 'package:flutter/material.dart';

/// Recipe: a long dropdown that uses the `SizeMiddleware` to cap its height to
/// the space available on the chosen side and scroll internally — so it never
/// runs off-screen no matter how many items it has.
class SizeRecipe extends StatefulWidget {
  const SizeRecipe({super.key});

  @override
  State<SizeRecipe> createState() => _SizeRecipeState();
}

class _SizeRecipeState extends State<SizeRecipe> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Size — constrained dropdown')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'A 40-item menu near the bottom. `SizeMiddleware` caps its height '
              'to the room available and it scrolls inside.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            FloatingOverlay(
              isOpen: _open,
              placement: Placement.bottomStart,
              middleware: [
                OffsetMiddleware(6),
                Flip(padding: 12),
                Shift(padding: 12),
                SizeMiddleware(padding: 12),
              ],
              barrierDismissible: true,
              onDismiss: () => setState(() => _open = false),
              floating: (context, position) {
                final size =
                    position.middlewareData['size'] as Map<String, Object?>?;
                final maxHeight =
                    (size?['availableHeight'] as double?) ?? double.infinity;
                return Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(10),
                  clipBehavior: Clip.antiAlias,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxHeight: maxHeight, minWidth: 240, maxWidth: 240),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: 40,
                      itemBuilder: (context, i) => ListTile(
                        dense: true,
                        title: Text('Option ${i + 1}'),
                        onTap: () => setState(() => _open = false),
                      ),
                    ),
                  ),
                );
              },
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _open = !_open),
                icon: const Icon(Icons.arrow_drop_down),
                label: const Text('Open 40-item menu'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
