import 'package:anchor_kit/anchor_kit.dart';
import 'package:flutter/material.dart';

/// Recipe: a form "select" field. It is deliberately placed near the bottom of
/// the screen so the options list has to **flip** above the field, and the list
/// is scrollable to show a long set of options staying on-screen.
class SelectRecipe extends StatefulWidget {
  const SelectRecipe({super.key});

  @override
  State<SelectRecipe> createState() => _SelectRecipeState();
}

class _SelectRecipeState extends State<SelectRecipe> {
  static const double _width = 260;
  static const _options = [
    'Afghanistan', 'Albania', 'Algeria', 'Argentina', 'Australia',
    'Austria', 'Belgium', 'Brazil', 'Canada', 'Chile', 'China',
    'Denmark', 'Egypt', 'Finland', 'France', 'Germany', 'Greece',
  ];

  bool _open = false;
  String? _value;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select field')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'This field sits near the bottom, so the options flip upward.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            FloatingOverlay(
              isOpen: _open,
              placement: Placement.bottomStart,
              middleware: [OffsetMiddleware(4), Flip(padding: 12), Shift(padding: 12)],
              barrierDismissible: true,
              onDismiss: () => setState(() => _open = false),
              floating: (context, position) => Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(10),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: _width,
                  height: 240,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      for (final o in _options)
                        ListTile(
                          dense: true,
                          title: Text(o),
                          trailing: _value == o
                              ? const Icon(Icons.check, size: 18)
                              : null,
                          onTap: () => setState(() {
                            _value = o;
                            _open = false;
                          }),
                        ),
                    ],
                  ),
                ),
              ),
              child: InkWell(
                onTap: () => setState(() => _open = !_open),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: _width,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _value ?? 'Select a country',
                          style: TextStyle(
                            color: _value == null
                                ? Theme.of(context).hintColor
                                : null,
                          ),
                        ),
                      ),
                      Icon(_open
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
