import 'dart:math' as math;
import 'dart:typed_data';
import 'rect.dart';

/// Result of procedural dungeon generation.
final class DungeonResult {
  final int width;
  final int height;
  final Uint8List tiles; // 0 = wall, 1 = floor
  final List<ProcRect> rooms;

  DungeonResult({
    required this.width,
    required this.height,
    required this.tiles,
    required this.rooms,
  });

  bool isFloor(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return false;
    return tiles[y * width + x] == 1;
  }

  List<({int x, int y})> get roomCenters =>
      rooms.map((r) => r.center).toList(growable: false);

  ({int x, int y}) get playerSpawn =>
      rooms.isNotEmpty ? rooms.first.center : (x: width ~/ 2, y: height ~/ 2);
}

final class _BspNode {
  final ProcRect bounds;
  _BspNode? left;
  _BspNode? right;
  ProcRect? room;

  _BspNode(this.bounds);

  bool get isLeaf => left == null && right == null;

  bool split(int minSize, math.Random rng) {
    if (!isLeaf) return false;

    // Determine split direction: if width > height by 25%, split vertically, else if height > width by 25% split horizontally, else random.
    bool splitH;
    if (bounds.width / bounds.height >= 1.25) {
      splitH = false;
    } else if (bounds.height / bounds.width >= 1.25) {
      splitH = true;
    } else {
      splitH = rng.nextBool();
    }

    final maxSplit = (splitH ? bounds.height : bounds.width) - minSize;
    if (maxSplit <= minSize) return false;

    final splitPos = minSize + rng.nextInt(maxSplit - minSize + 1);

    if (splitH) {
      left = _BspNode(ProcRect(bounds.x, bounds.y, bounds.width, splitPos));
      right = _BspNode(ProcRect(bounds.x, bounds.y + splitPos, bounds.width, bounds.height - splitPos));
    } else {
      left = _BspNode(ProcRect(bounds.x, bounds.y, splitPos, bounds.height));
      right = _BspNode(ProcRect(bounds.x + splitPos, bounds.y, bounds.width - splitPos, bounds.height));
    }

    return true;
  }

  void createRooms(int minRoomSize, int maxRoomSize, math.Random rng, List<ProcRect> outRooms) {
    if (!isLeaf) {
      left?.createRooms(minRoomSize, maxRoomSize, rng, outRooms);
      right?.createRooms(minRoomSize, maxRoomSize, rng, outRooms);
      return;
    }

    // Carve room inside this leaf bounds
    final roomW = math.max(minRoomSize, rng.nextInt(math.max(1, math.min(bounds.width - 2, maxRoomSize) - minRoomSize + 1)) + minRoomSize);
    final roomH = math.max(minRoomSize, rng.nextInt(math.max(1, math.min(bounds.height - 2, maxRoomSize) - minRoomSize + 1)) + minRoomSize);

    final roomX = bounds.x + 1 + (bounds.width - roomW - 2 > 0 ? rng.nextInt(bounds.width - roomW - 1) : 0);
    final roomY = bounds.y + 1 + (bounds.height - roomH - 2 > 0 ? rng.nextInt(bounds.height - roomH - 1) : 0);

    final r = ProcRect(roomX, roomY, roomW, roomH);
    room = r;
    outRooms.add(r);
  }

  ProcRect? getRoom() {
    if (room != null) return room;
    return left?.getRoom() ?? right?.getRoom();
  }
}

/// Binary Space Partitioning (BSP) dungeon generator.
class BspDungeonGenerator {
  final int minRoomSize;
  final int maxRoomSize;
  final int minPartitionSize;

  const BspDungeonGenerator({
    this.minRoomSize = 5,
    this.maxRoomSize = 12,
    this.minPartitionSize = 8,
  });

  /// Generates a randomized dungeon of dimensions [width] x [height].
  DungeonResult generate({
    required int width,
    required int height,
    int? seed,
  }) {
    final rng = math.Random(seed);
    final tiles = Uint8List(width * height); // 0 = wall, 1 = floor

    final root = _BspNode(ProcRect(0, 0, width, height));
    final nodes = <_BspNode>[root];

    // Split partitions recursively
    var didSplit = true;
    while (didSplit) {
      didSplit = false;
      final currentNodes = List<_BspNode>.of(nodes);
      for (final n in currentNodes) {
        if (n.isLeaf) {
          if (n.bounds.width > minPartitionSize * 2 || n.bounds.height > minPartitionSize * 2) {
            if (n.split(minPartitionSize, rng)) {
              nodes.add(n.left!);
              nodes.add(n.right!);
              didSplit = true;
            }
          }
        }
      }
    }

    final rooms = <ProcRect>[];
    root.createRooms(minRoomSize, maxRoomSize, rng, rooms);

    // Carve rooms into tiles
    for (final r in rooms) {
      for (var y = r.y; y < r.bottom; y++) {
        for (var x = r.x; x < r.right; x++) {
          if (x >= 0 && x < width && y >= 0 && y < height) {
            tiles[y * width + x] = 1;
          }
        }
      }
    }

    // Connect partitions with corridors
    _carveCorridors(root, tiles, width, height, rng);

    return DungeonResult(
      width: width,
      height: height,
      tiles: tiles,
      rooms: rooms,
    );
  }

  void _carveCorridors(_BspNode node, Uint8List tiles, int width, int height, math.Random rng) {
    if (node.isLeaf) return;

    final leftRoom = node.left?.getRoom();
    final rightRoom = node.right?.getRoom();

    if (leftRoom != null && rightRoom != null) {
      final p1 = leftRoom.center;
      final p2 = rightRoom.center;

      // Draw L-shaped corridor connecting centers
      if (rng.nextBool()) {
        _carveHLine(tiles, width, height, p1.x, p2.x, p1.y);
        _carveVLine(tiles, width, height, p1.y, p2.y, p2.x);
      } else {
        _carveVLine(tiles, width, height, p1.y, p2.y, p1.x);
        _carveHLine(tiles, width, height, p1.x, p2.x, p2.y);
      }
    }

    if (node.left != null) _carveCorridors(node.left!, tiles, width, height, rng);
    if (node.right != null) _carveCorridors(node.right!, tiles, width, height, rng);
  }

  void _carveHLine(Uint8List tiles, int width, int height, int x1, int x2, int y) {
    if (y < 1 || y >= height - 1) return;
    final minX = math.max(1, math.min(x1, x2));
    final maxX = math.min(width - 2, math.max(x1, x2));
    for (var x = minX; x <= maxX; x++) {
      tiles[y * width + x] = 1;
    }
  }

  void _carveVLine(Uint8List tiles, int width, int height, int y1, int y2, int x) {
    if (x < 1 || x >= width - 1) return;
    final minY = math.max(1, math.min(y1, y2));
    final maxY = math.min(height - 2, math.max(y1, y2));
    for (var y = minY; y <= maxY; y++) {
      tiles[y * width + x] = 1;
    }
  }
}
