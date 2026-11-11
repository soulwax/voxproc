import 'dart:math' as math;

/// Fast blue-noise point distribution using Bridson's Poisson Disk algorithm.
abstract final class PoissonDiskSampler2D {
  /// Samples points uniformly distributed across `[0..width]` x `[0..height]`
  /// with no two points closer than [minDistance].
  static List<({double x, double y})> sample({
    required double width,
    required double height,
    required double minDistance,
    int maxCandidates = 30,
    int? seed,
  }) {
    if (width <= 0 || height <= 0 || minDistance <= 0) return const [];

    final rng = math.Random(seed);
    final cellSize = minDistance / math.sqrt(2.0);
    final gridWidth = (width / cellSize).ceil();
    final gridHeight = (height / cellSize).ceil();

    final grid = List<int>.filled(gridWidth * gridHeight, -1);
    final points = <({double x, double y})>[];
    final activeList = <int>[];

    // Seed initial point
    final initial = (
      x: rng.nextDouble() * width,
      y: rng.nextDouble() * height,
    );
    points.add(initial);
    activeList.add(0);

    final initGx = (initial.x / cellSize).floor();
    final initGy = (initial.y / cellSize).floor();
    if (initGx >= 0 && initGx < gridWidth && initGy >= 0 && initGy < gridHeight) {
      grid[initGy * gridWidth + initGx] = 0;
    }

    final minDistSq = minDistance * minDistance;

    while (activeList.isNotEmpty) {
      final activeIndex = rng.nextInt(activeList.length);
      final pointIndex = activeList[activeIndex];
      final current = points[pointIndex];
      var foundCandidate = false;

      for (var i = 0; i < maxCandidates; i++) {
        final angle = rng.nextDouble() * 2.0 * math.pi;
        final radius = minDistance * (1.0 + rng.nextDouble());
        final candidateX = current.x + radius * math.cos(angle);
        final candidateY = current.y + radius * math.sin(angle);

        if (candidateX < 0 || candidateX >= width || candidateY < 0 || candidateY >= height) {
          continue;
        }

        final gx = (candidateX / cellSize).floor();
        final gy = (candidateY / cellSize).floor();

        var isTooClose = false;
        final minX = math.max(0, gx - 2);
        final maxX = math.min(gridWidth - 1, gx + 2);
        final minY = math.max(0, gy - 2);
        final maxY = math.min(gridHeight - 1, gy + 2);

        for (var checkY = minY; checkY <= maxY && !isTooClose; checkY++) {
          for (var checkX = minX; checkX <= maxX && !isTooClose; checkX++) {
            final neighborIndex = grid[checkY * gridWidth + checkX];
            if (neighborIndex != -1) {
              final neighbor = points[neighborIndex];
              final dx = candidateX - neighbor.x;
              final dy = candidateY - neighbor.y;
              if (dx * dx + dy * dy < minDistSq) {
                isTooClose = true;
              }
            }
          }
        }

        if (!isTooClose) {
          final newIdx = points.length;
          final cand = (x: candidateX, y: candidateY);
          points.add(cand);
          activeList.add(newIdx);
          grid[gy * gridWidth + gx] = newIdx;
          foundCandidate = true;
          break;
        }
      }

      if (!foundCandidate) {
        activeList.removeAt(activeIndex);
      }
    }

    return points;
  }
}
