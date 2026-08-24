import 'dart:math' as math;

import 'package:anchor_kit/anchor_kit.dart';
import 'package:flutter/material.dart';

import '../stress/frame_stats.dart';

/// A "harsh" performance harness for anchor_kit that end users can run
/// themselves.
///
/// Two independent stressors:
///  1. **Compute micro-benchmark** — hammers the synchronous [computePosition]
///     hot path through a deep middleware chain and reports µs/op + ops/sec.
///  2. **Live widget stress** — opens N real [FloatingOverlay]s whose anchors
///     orbit every frame, forcing a full re-measure + recompute per overlay per
///     frame while [FrameStatsPanel] reports FPS / build / raster / jank.
class StressTestRecipe extends StatefulWidget {
  const StressTestRecipe({super.key});

  @override
  State<StressTestRecipe> createState() => _StressTestRecipeState();
}

class _StressTestRecipeState extends State<StressTestRecipe>
    with SingleTickerProviderStateMixin {
  final FrameStatsController _stats = FrameStatsController();
  late final AnimationController _orbit;

  // Live widget-stress params.
  double _anchorCount = 30;
  bool _animate = true;
  bool _deepChain = true;

  // Micro-benchmark params/results.
  int _iterations = 100000;
  String? _benchResult;
  bool _benchRunning = false;

  // A deep, realistic middleware pipeline — the worst case a consumer wires up.
  List<Middleware> get _chain => _deepChain
      ? [
          OffsetMiddleware(8, crossAxis: 2),
          Flip(padding: 4),
          Shift(padding: 4, crossAxis: true),
          SizeMiddleware(padding: 8),
          Hide(padding: 0),
          Arrow(),
        ]
      : const [];

  @override
  void initState() {
    super.initState();
    _orbit = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _stats.start();
  }

  @override
  void dispose() {
    _stats.stop();
    _orbit.dispose();
    super.dispose();
  }

  Future<void> _runBenchmark() async {
    setState(() {
      _benchRunning = true;
      _benchResult = null;
    });
    // Yield a frame so the spinner paints before we block the UI thread.
    await Future<void>.delayed(const Duration(milliseconds: 16));

    const anchor = Rect.fromLTWH(300, 400, 80, 40);
    const floating = Size(220, 120);
    const viewport = Rect.fromLTWH(0, 0, 800, 900);
    final chain = _chain;

    // Prevent the loop being optimised away by accumulating a real value.
    var sink = 0.0;
    final sw = Stopwatch()..start();
    for (var i = 0; i < _iterations; i++) {
      final r = computePosition(
        anchor: anchor,
        floating: floating,
        viewport: viewport,
        placement: Placement.top,
        middleware: chain,
      );
      sink += r.offset.dx;
    }
    sw.stop();

    final usPerOp = sw.elapsedMicroseconds / _iterations;
    final opsPerSec = _iterations / (sw.elapsedMicroseconds / 1e6);
    setState(() {
      _benchRunning = false;
      _benchResult = '$_iterations calls '
          '(${_deepChain ? '6-stage chain' : 'no middleware'})\n'
          '${usPerOp.toStringAsFixed(3)} µs/op · '
          '${_fmtOps(opsPerSec)} ops/sec\n'
          'total ${sw.elapsedMilliseconds} ms  (sink=${sink.toStringAsFixed(0)})';
    });
  }

  static String _fmtOps(double ops) {
    if (ops >= 1e6) return '${(ops / 1e6).toStringAsFixed(2)}M';
    if (ops >= 1e3) return '${(ops / 1e3).toStringAsFixed(1)}K';
    return ops.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final n = _anchorCount.round();
    return Scaffold(
      appBar: AppBar(title: const Text('Stress test')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: FrameStatsPanel(controller: _stats),
          ),
          _controls(context, n),
          const Divider(height: 1),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => AnimatedBuilder(
                animation: _orbit,
                builder: (context, _) => Stack(
                  children: [
                    for (var i = 0; i < n; i++)
                      _orbitingAnchor(i, n, constraints.biggest),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controls(BuildContext context, int n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Anchors'),
              Expanded(
                child: Slider(
                  value: _anchorCount,
                  min: 0,
                  max: 150,
                  divisions: 30,
                  label: '$n',
                  onChanged: (v) => setState(() => _anchorCount = v),
                ),
              ),
              SizedBox(width: 40, child: Text('$n', textAlign: TextAlign.end)),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Animate anchors'),
                  subtitle: const Text('recompute every frame'),
                  value: _animate,
                  onChanged: (v) => setState(() {
                    _animate = v;
                    v ? _orbit.repeat() : _orbit.stop();
                  }),
                ),
              ),
              Expanded(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Deep chain'),
                  subtitle: const Text('6 middleware'),
                  value: _deepChain,
                  onChanged: (v) => setState(() => _deepChain = v),
                ),
              ),
            ],
          ),
          const Divider(height: 8),
          Row(
            children: [
              const Text('Micro-benchmark'),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: _iterations,
                items: const [
                  DropdownMenuItem(value: 10000, child: Text('10K')),
                  DropdownMenuItem(value: 100000, child: Text('100K')),
                  DropdownMenuItem(value: 500000, child: Text('500K')),
                ],
                onChanged: _benchRunning
                    ? null
                    : (v) => setState(() => _iterations = v ?? 100000),
              ),
              const SizedBox(width: 12),
              FilledButton.tonal(
                onPressed: _benchRunning ? null : _runBenchmark,
                child: _benchRunning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Run'),
              ),
            ],
          ),
          if (_benchResult != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_benchResult!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      )),
            ),
        ],
      ),
    );
  }

  /// One anchor + open floating overlay whose position orbits a circle. Moving
  /// the anchor changes its global rect, which drives a per-frame recompute
  /// inside [FloatingOverlay].
  Widget _orbitingAnchor(int i, int n, Size area) {
    final t = _animate ? _orbit.value : 0.0;
    final angle = 2 * math.pi * (i / n) + t * 2 * math.pi;
    final radius = math.min(area.width, area.height) * 0.35;
    final cx = area.width / 2;
    final cy = area.height / 2;
    final left = cx + radius * math.cos(angle) - 8;
    final top = cy + radius * math.sin(angle) - 8;

    return Positioned(
      left: left.clamp(0.0, math.max(0.0, area.width - 16)),
      top: top.clamp(0.0, math.max(0.0, area.height - 16)),
      child: FloatingOverlay(
        isOpen: true,
        placement: Placement.top,
        middleware: _chain,
        floating: (context, pos) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.teal.shade700,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text('#$i',
              style: const TextStyle(color: Colors.white, fontSize: 10)),
        ),
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.teal.shade200,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.teal.shade900),
          ),
        ),
      ),
    );
  }
}
