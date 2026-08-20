import 'package:anchor_kit/anchor_kit.dart';
import 'package:flutter/material.dart';

/// Recipe: a dropdown menu that dismisses on an outside tap
/// (`barrierDismissible`).
class DropdownRecipe extends StatefulWidget {
  const DropdownRecipe({super.key});

  @override
  State<DropdownRecipe> createState() => _DropdownRecipeState();
}

class _DropdownRecipeState extends State<DropdownRecipe> {
  bool _open = false;
  String _last = 'Actions';

  static const _items = [
    ('Rename', Icons.edit_outlined),
    ('Duplicate', Icons.copy_outlined),
    ('Move to…', Icons.drive_file_move_outlined),
    ('Delete', Icons.delete_outline),
  ];

  void _select(String label) => setState(() {
        _last = label;
        _open = false;
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dropdown menu')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingOverlay(
              isOpen: _open,
              placement: Placement.bottomStart,
              middleware: [OffsetMiddleware(6), Flip(padding: 8), Shift(padding: 8)],
              barrierDismissible: true,
              onDismiss: () => setState(() => _open = false),
              floating: (context, position) => Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(10),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: 200,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final (label, icon) in _items)
                        ListTile(
                          dense: true,
                          leading: Icon(icon, size: 20),
                          title: Text(label),
                          onTap: () => _select(label),
                        ),
                    ],
                  ),
                ),
              ),
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _open = !_open),
                icon: const Icon(Icons.arrow_drop_down),
                label: Text(_last),
              ),
            ),
            const SizedBox(height: 16),
            Text('Tap outside the menu to dismiss it.',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
