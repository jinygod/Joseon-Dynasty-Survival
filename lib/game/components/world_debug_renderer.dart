import 'dart:ui';

import 'package:flame/components.dart';

import '../world/world_debug_snapshot.dart';

class WorldDebugRenderer extends Component {
  WorldDebugRenderer({required this.source}) : super(priority: 1000000);

  final WorldDebugSource source;
  final Paint _worldPaint = Paint()
    ..color = const Color(0xffffc857)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4;
  final Paint _cameraPaint = Paint()
    ..color = const Color(0xffffffff)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  final Paint _visiblePaint = Paint()
    ..color = const Color(0xff48e5c2)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  final Paint _activePaint = Paint()
    ..color = const Color(0xff58c7ff)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  final Paint _sleepingPaint = Paint()
    ..color = const Color(0xffb388ff)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  final Paint _chunkPaint = Paint()
    ..color = const Color(0x55ffffff)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  @override
  void render(Canvas canvas) {
    if (!source.worldDebugVisible) return;
    final snapshot = source.debugSnapshot;
    canvas.drawRect(snapshot.worldBounds, _worldPaint);
    canvas.drawRect(snapshot.sleepingRect, _sleepingPaint);
    canvas.drawRect(snapshot.activeRect, _activePaint);
    canvas.drawRect(snapshot.visibleRect, _visiblePaint);
    canvas.drawRect(snapshot.cameraRect.deflate(3), _cameraPaint);

    for (
      var x = snapshot.worldBounds.left + snapshot.chunkSize;
      x < snapshot.worldBounds.right;
      x += snapshot.chunkSize
    ) {
      canvas.drawLine(
        Offset(x, snapshot.worldBounds.top),
        Offset(x, snapshot.worldBounds.bottom),
        _chunkPaint,
      );
    }
    for (
      var y = snapshot.worldBounds.top + snapshot.chunkSize;
      y < snapshot.worldBounds.bottom;
      y += snapshot.chunkSize
    ) {
      canvas.drawLine(
        Offset(snapshot.worldBounds.left, y),
        Offset(snapshot.worldBounds.right, y),
        _chunkPaint,
      );
    }
  }
}
