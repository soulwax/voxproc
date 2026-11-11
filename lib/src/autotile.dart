import 'dart:typed_data';

/// 2D tile autotiling bitmask calculator for automatic tileset edge and corner selection.
abstract final class AutoTiler {
  /// Evaluates 4-directional cardinal bitmask:
  /// - North = 1
  /// - West = 2
  /// - East = 4
  /// - South = 8
  /// Returns a mask in `[0..15]`.
  static int cardinalMask(bool Function(int x, int y) isSolid, int x, int y) {
    var mask = 0;
    if (isSolid(x, y - 1)) mask |= 1; // North
    if (isSolid(x - 1, y)) mask |= 2; // West
    if (isSolid(x + 1, y)) mask |= 4; // East
    if (isSolid(x, y + 1)) mask |= 8; // South
    return mask;
  }

  /// Evaluates 8-directional autotiling bitmask with corner dependencies:
  /// - North = 1
  /// - West = 2
  /// - East = 4
  /// - South = 8
  /// - NW = 16 (only if North and West)
  /// - NE = 32 (only if North and East)
  /// - SW = 64 (only if South and West)
  /// - SE = 128 (only if South and East)
  static int blob8Mask(bool Function(int x, int y) isSolid, int x, int y) {
    final n = isSolid(x, y - 1);
    final w = isSolid(x - 1, y);
    final e = isSolid(x + 1, y);
    final s = isSolid(x, y + 1);

    var mask = 0;
    if (n) mask |= 1;
    if (w) mask |= 2;
    if (e) mask |= 4;
    if (s) mask |= 8;

    if (n && w && isSolid(x - 1, y - 1)) mask |= 16;
    if (n && e && isSolid(x + 1, y - 1)) mask |= 32;
    if (s && w && isSolid(x - 1, y + 1)) mask |= 64;
    if (s && e && isSolid(x + 1, y + 1)) mask |= 128;

    return mask;
  }

  /// Computes a full autotiled tile ID array from a binary solid map (0 = empty, 1 = solid).
  static Uint16List autotileCardinal(
    Uint8List solidMap,
    int width,
    int height, {
    int solidVal = 1,
  }) {
    final result = Uint16List(width * height);

    bool isSolid(int x, int y) {
      if (x < 0 || x >= width || y < 0 || y >= height) return false;
      return solidMap[y * width + x] == solidVal;
    }

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (!isSolid(x, y)) {
          result[y * width + x] = 0;
          continue;
        }
        result[y * width + x] = cardinalMask(isSolid, x, y);
      }
    }

    return result;
  }
}
