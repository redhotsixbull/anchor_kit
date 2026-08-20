import 'package:anchor_kit/anchor_kit.dart';
import 'package:flutter/material.dart';

/// Recipe: an interactive playground. Nine anchors around the screen, a
/// placement selector, and flip/shift toggles — the fastest way to feel how
/// the middleware pipeline reacts near every edge.
class PlacementPlayground extends StatefulWidget {
  const PlacementPlayground({super.key});

  @override
  State<PlacementPlayground> createState() => _PlacementPlaygroundState();
}

class _PlacementPlaygroundState extends State<PlacementPlayground> {
  Placement _placement = Placement.bottom;
  bool _flip = true;
  bool _shift = true;

  static const _options = [
    Placement.top, Placement.bottom, Placement.left, Placement.right,
    Placement.topStart, Placement.topEnd,
    Placement.bottomStart, Placement.bottomEnd,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Placement playground')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Placement:'),
                DropdownButton<Placement>(
                  value: _placement,
                  onChanged: (p) => p != null ? setState(() => _placement = p) : null,
                  items: [
                    for (final p in _options)
                      DropdownMenuItem(
                        value: p,
                        child: Text(p.align == PlacementAlign.center
                            ? p.side.name
                            : '${p.side.name}-${p.align.name}'),
                      ),
                  ],
                ),
                FilterChip(
                  label: const Text('flip'),
                  selected: _flip,
                  onSelected: (v) => setState(() => _flip = v),
                ),
                FilterChip(
                  label: const Text('shift'),
                  selected: _shift,
                  onSelected: (v) => setState(() => _shift = v),
                ),
              ],
            ),
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
                          if (_flip) Flip(padding: 8),
                          if (_shift) Shift(padding: 8),
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
      floating: (context, position) => Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        color: Colors.black87,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text('Placed at ${position.placement.side.name}',
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
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
