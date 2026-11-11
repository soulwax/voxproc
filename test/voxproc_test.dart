import 'package:test/test.dart';
import 'package:voxproc/voxproc.dart';

void main() {
  group('voxproc ProcRect', () {
    test('center, bounds, and intersections', () {
      const r1 = ProcRect(10, 10, 20, 30);
      expect(r1.left, equals(10));
      expect(r1.right, equals(30));
      expect(r1.top, equals(10));
      expect(r1.bottom, equals(40));
      expect(r1.center, equals((x: 20, y: 25)));

      const r2 = ProcRect(25, 25, 10, 10);
      expect(r1.intersects(r2), isTrue);

      const r3 = ProcRect(50, 50, 10, 10);
      expect(r1.intersects(r3), isFalse);
    });
  });

  group('voxproc BspDungeonGenerator', () {
    test('generates connected rooms and corridors within bounds', () {
      const gen = BspDungeonGenerator(
        minRoomSize: 4,
        maxRoomSize: 10,
        minPartitionSize: 8,
      );

      final dungeon = gen.generate(width: 40, height: 40, seed: 12345);

      expect(dungeon.width, equals(40));
      expect(dungeon.height, equals(40));
      expect(dungeon.rooms, isNotEmpty);
      expect(dungeon.roomCenters, hasLength(dungeon.rooms.length));

      // Floors exist
      var floorCount = 0;
      for (final t in dungeon.tiles) {
        if (t == 1) floorCount++;
      }
      expect(floorCount, greaterThan(50));

      // Player spawn is on a floor tile
      final spawn = dungeon.playerSpawn;
      expect(dungeon.isFloor(spawn.x, spawn.y), isTrue);
    });
  });

  group('voxproc CellularAutomata', () {
    test('generates cave map with enclosed perimeter walls', () {
      const ca = CellularAutomata(
        initialFillRatio: 0.45,
        iterations: 4,
      );

      final cave = ca.generate(width: 30, height: 30, seed: 42);
      expect(cave.length, equals(30 * 30));

      // Perimeter must be all solid walls (0)
      for (var x = 0; x < 30; x++) {
        expect(cave[0 * 30 + x], equals(0)); // top
        expect(cave[29 * 30 + x], equals(0)); // bottom
      }
      for (var y = 0; y < 30; y++) {
        expect(cave[y * 30 + 0], equals(0)); // left
        expect(cave[y * 30 + 29], equals(0)); // right
      }

      // Interior has open floor tiles (1)
      expect(cave.contains(1), isTrue);
    });
  });

  group('voxproc PoissonDiskSampler2D', () {
    test('samples points where all pairwise distances exceed minDistance', () {
      final points = PoissonDiskSampler2D.sample(
        width: 100.0,
        height: 100.0,
        minDistance: 10.0,
        seed: 777,
      );

      expect(points, isNotEmpty);

      // Verify no two points are closer than minDistance
      for (var i = 0; i < points.length; i++) {
        for (var j = i + 1; j < points.length; j++) {
          final dx = points[i].x - points[j].x;
          final dy = points[i].y - points[j].y;
          final dist = dx * dx + dy * dy;
          expect(dist, greaterThanOrEqualTo(9.99 * 9.99));
        }
      }
    });
  });

  group('voxproc AutoTiler', () {
    test('calculates cardinal bitmask based on adjacent solid neighbors', () {
      final solidGrid = [
        [0, 1, 0],
        [1, 1, 0],
        [0, 1, 0],
      ];

      bool isSolid(int x, int y) {
        if (x < 0 || x >= 3 || y < 0 || y >= 3) return false;
        return solidGrid[y][x] == 1;
      }

      // Center tile at (1, 1): has North (1), West (2), South (8). East is 0.
      // Expected mask: 1 + 2 + 8 = 11.
      final mask = AutoTiler.cardinalMask(isSolid, 1, 1);
      expect(mask, equals(11));
    });
  });
}
