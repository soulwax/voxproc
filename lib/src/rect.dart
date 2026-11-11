/// A 2D integer rectangle used in procedural map generation.
final class ProcRect {
  final int x;
  final int y;
  final int width;
  final int height;

  const ProcRect(this.x, this.y, this.width, this.height);

  int get left => x;
  int get top => y;
  int get right => x + width;
  int get bottom => y + height;

  ({int x, int y}) get center => (
        x: x + (width ~/ 2),
        y: y + (height ~/ 2),
      );

  /// Returns `true` if this rectangle overlaps with [other].
  bool intersects(ProcRect other) {
    return x < other.right &&
        right > other.x &&
        y < other.bottom &&
        bottom > other.y;
  }

  /// Returns `true` if point `(px, py)` is inside this rectangle.
  bool contains(int px, int py) {
    return px >= x && px < right && py >= y && py < bottom;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProcRect &&
          other.x == x &&
          other.y == y &&
          other.width == width &&
          other.height == height;

  @override
  int get hashCode => Object.hash(x, y, width, height);

  @override
  String toString() => 'ProcRect(x: $x, y: $y, w: $width, h: $height)';
}
