# voxproc

Procedural content generation (BSP dungeons, cellular caves, autotiling, and Poisson disk sampling) for Dart games.

## Features

- **BSP Dungeon Generation (`BspDungeonGenerator`)**: Recursive binary space partitioning with rooms, corridors, player spawns, and room centers.
- **Cellular Automata Caves (`CellularAutomata`)**: Organic cavern generation with 4-5 simulation rules.
- **Poisson Disk Sampling (`PoissonDiskSampler2D`)**: Bridson's blue-noise distribution with minimum distance radius $r$.
- **Autotiling Bitmasks (`AutoTiler`)**: Cardinal 4-bit (16-tile) and blob 8-bit autotiling bitmasks for automatic tileset edge and corner selection.

## Quick Start

```dart
import 'package:voxproc/voxproc.dart';

void main() {
  // BSP Dungeon
  final bsp = BspDungeonGenerator(minRoomSize: 5, maxRoomSize: 12);
  final dungeon = bsp.generate(width: 40, height: 30, seed: 42);
  print('Generated ${dungeon.rooms.length} rooms. Player spawn: ${dungeon.playerSpawn}');

  // Poisson Disk Sampling
  final points = PoissonDiskSampler2D.sample(
    width: 100.0,
    height: 100.0,
    minDistance: 10.0,
  );
  print('Generated ${points.length} non-overlapping points.');
}
```

## License

MIT
