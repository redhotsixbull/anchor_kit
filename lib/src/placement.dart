enum PlacementSide { top, right, bottom, left }

enum PlacementAlign { start, center, end }

class Placement {
  const Placement(this.side, [this.align = PlacementAlign.center]);

  final PlacementSide side;
  final PlacementAlign align;

  static const top = Placement(PlacementSide.top);
  static const topStart = Placement(PlacementSide.top, PlacementAlign.start);
  static const topEnd = Placement(PlacementSide.top, PlacementAlign.end);
  static const right = Placement(PlacementSide.right);
  static const rightStart = Placement(PlacementSide.right, PlacementAlign.start);
  static const rightEnd = Placement(PlacementSide.right, PlacementAlign.end);
  static const bottom = Placement(PlacementSide.bottom);
  static const bottomStart = Placement(PlacementSide.bottom, PlacementAlign.start);
  static const bottomEnd = Placement(PlacementSide.bottom, PlacementAlign.end);
  static const left = Placement(PlacementSide.left);
  static const leftStart = Placement(PlacementSide.left, PlacementAlign.start);
  static const leftEnd = Placement(PlacementSide.left, PlacementAlign.end);

  Placement flipSide() {
    return Placement(
      switch (side) {
        PlacementSide.top => PlacementSide.bottom,
        PlacementSide.bottom => PlacementSide.top,
        PlacementSide.left => PlacementSide.right,
        PlacementSide.right => PlacementSide.left,
      },
      align,
    );
  }

  bool get isVertical => side == PlacementSide.top || side == PlacementSide.bottom;
  bool get isHorizontal => !isVertical;

  @override
  String toString() => 'Placement($side, $align)';

  @override
  bool operator ==(Object other) =>
      other is Placement && other.side == side && other.align == align;

  @override
  int get hashCode => Object.hash(side, align);
}
