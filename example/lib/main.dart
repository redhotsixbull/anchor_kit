import 'package:flutter/material.dart';
import 'package:anchor_kit/anchor_kit.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'anchor_kit example',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  Placement _placement = Placement.bottom;
  bool _flipEnabled = true;
  bool _shiftEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('anchor_kit')),
      body: Column(
        children: [
          _ControlBar(
            placement: _placement,
            flipEnabled: _flipEnabled,
            shiftEnabled: _shiftEnabled,
            onPlacementChanged: (p) => setState(() => _placement = p),
            onFlipChanged: (v) => setState(() => _flipEnabled = v),
            onShiftChanged: (v) => setState(() => _shiftEnabled = v),
          ),
          const Divider(height: 1),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => Stack(
                children: [
                  for (final pos in _anchorPositions(constraints.biggest))
                    Positioned(
                      left: pos.dx,
                      top: pos.dy,
                      child: _AnchorButton(
                        label: pos.label,
                        placement: _placement,
                        middleware: [
                          OffsetMiddleware(8),
                          if (_flipEnabled) Flip(padding: 8),
                          if (_shiftEnabled) Shift(padding: 8),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_AnchorPos> _anchorPositions(Size size) {
    const margin = 24.0;
    return [
      _AnchorPos(margin, margin, 'top-left'),
      _AnchorPos(size.width / 2 - 60, margin, 'top-center'),
      _AnchorPos(size.width - 120 - margin, margin, 'top-right'),
      _AnchorPos(margin, size.height / 2 - 20, 'center-left'),
      _AnchorPos(size.width / 2 - 60, size.height / 2 - 20, 'center'),
      _AnchorPos(size.width - 120 - margin, size.height / 2 - 20, 'center-right'),
      _AnchorPos(margin, size.height - 60 - margin, 'bottom-left'),
      _AnchorPos(size.width / 2 - 60, size.height - 60 - margin, 'bottom-center'),
      _AnchorPos(size.width - 120 - margin, size.height - 60 - margin, 'bottom-right'),
    ];
  }
}

class _AnchorPos {
  const _AnchorPos(this.dx, this.dy, this.label);
  final double dx;
  final double dy;
  final String label;
}

class _AnchorButton extends StatefulWidget {
  const _AnchorButton({
    required this.label,
    required this.placement,
    required this.middleware,
  });

  final String label;
  final Placement placement;
  final List<Middleware> middleware;

  @override
  State<_AnchorButton> createState() => _AnchorButtonState();
}

class _AnchorButtonState extends State<_AnchorButton> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return FloatingOverlay(
      isOpen: _open,
      placement: widget.placement,
      middleware: widget.middleware,
      floating: (context, position) => _Popover(
        text: 'Placed at ${position.placement.side.name}',
      ),
      child: SizedBox(
        width: 120,
        height: 40,
        child: FilledButton.tonal(
          onPressed: () => setState(() => _open = !_open),
          child: Text(widget.label, style: const TextStyle(fontSize: 11)),
        ),
      ),
    );
  }
}

class _Popover extends StatelessWidget {
  const _Popover({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      color: Colors.black87,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ),
    );
  }
}

class _ControlBar extends StatelessWidget {
  const _ControlBar({
    required this.placement,
    required this.flipEnabled,
    required this.shiftEnabled,
    required this.onPlacementChanged,
    required this.onFlipChanged,
    required this.onShiftChanged,
  });

  final Placement placement;
  final bool flipEnabled;
  final bool shiftEnabled;
  final ValueChanged<Placement> onPlacementChanged;
  final ValueChanged<bool> onFlipChanged;
  final ValueChanged<bool> onShiftChanged;

  static const _options = [
    Placement.top, Placement.bottom, Placement.left, Placement.right,
    Placement.topStart, Placement.topEnd,
    Placement.bottomStart, Placement.bottomEnd,
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('Placement:'),
          DropdownButton<Placement>(
            value: placement,
            onChanged: (p) => p != null ? onPlacementChanged(p) : null,
            items: [
              for (final p in _options)
                DropdownMenuItem(
                  value: p,
                  child: Text('${p.side.name}${p.align.name == 'center' ? '' : '-${p.align.name}'}'),
                ),
            ],
          ),
          const SizedBox(width: 12),
          FilterChip(
            label: const Text('flip'),
            selected: flipEnabled,
            onSelected: onFlipChanged,
          ),
          FilterChip(
            label: const Text('shift'),
            selected: shiftEnabled,
            onSelected: onShiftChanged,
          ),
        ],
      ),
    );
  }
}
