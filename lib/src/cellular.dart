import 'dart:math' as math;
import 'dart:typed_data';

/// Organic cave and cavern generator using cellular automata simulation.
class CellularAutomata {
  final double initialFillRatio;
  final int birthLimit;
  final int deathLimit;
  final int iterations;

  const CellularAutomata({
    this.initialFillRatio = 0.45,
    this.birthLimit = 5,
    this.deathLimit = 4,
    this.iterations = 4,
  });

  /// Generates organic caverns of dimensions [width] x [height].
  /// Returns `Uint8List` where 1 = floor (open space) and 0 = wall.
  Uint8List generate({
    required int width,
    required int height,
    int? seed,
  }) {
    final rng = math.Random(seed);
    var map = Uint8List(width * height);

    // Initialize with noise
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (x == 0 || x == width - 1 || y == 0 || y == height - 1) {
          map[y * width + x] = 0; // Boundary walls
        } else {
          // 0 = wall, 1 = floor
          map[y * width + x] = rng.nextDouble() < initialFillRatio ? 0 : 1;
        }
      }
    }

    // Run simulation steps
    for (var iter = 0; iter < iterations; iter++) {
      final nextMap = Uint8List(width * height);

      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          if (x == 0 || x == width - 1 || y == 0 || y == height - 1) {
            nextMap[y * width + x] = 0;
            continue;
          }

          final wallCount = _countNeighborWalls(map, width, height, x, y);
          if (wallCount >= birthLimit) {
            nextMap[y * width + x] = 0; // becomes wall
          } else if (wallCount < deathLimit) {
            nextMap[y * width + x] = 1; // becomes floor
          } else {
            nextMap[y * width + x] = map[y * width + x];
          }
        }
      }

      map = nextMap;
    }

    return map;
  }

  int _countNeighborWalls(Uint8List map, int width, int height, int cx, int cy) {
    var count = 0;
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        if (dx == 0 && dy == 0) continue;
        final nx = cx + dx;
        final ny = cy + dy;
        if (nx < 0 || nx >= width || ny < 0 || ny >= height) {
          count++;
        } else if (map[ny * width + nx] == 0) {
          count++;
        }
      }
    }
    return count;
  }
}
