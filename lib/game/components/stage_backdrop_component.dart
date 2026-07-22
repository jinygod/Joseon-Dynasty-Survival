import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

/// Shared warm-earth fallback for the Joseon combat field and empty canvas.
const Color warmHanjiBeige = Color(0xfff1d7ab);

/// A static, low-cost Joseon folk-fantasy combat ground.
///
/// The backdrop deliberately owns neither collision nor simulation. Its
/// decoration layout is rebuilt only when the game viewport changes and uses
/// an isolated fixed seed, so combat randomness cannot alter the stage.
class StageBackdropComponent extends PositionComponent {
  StageBackdropComponent({Vector2? viewportSize})
    : super(
        position: Vector2.zero(),
        size: viewportSize?.clone() ?? Vector2.zero(),
        anchor: Anchor.topLeft,
        priority: -100,
      ) {
    _rebuildDecorations();
  }

  static const maxDecorationCount = 40;
  static const _decorationSeed = 0x0BA7D0C;
  static const Color _baseColor = warmHanjiBeige;
  static const Color _jadePatchColor = Color(0xffb6d4b4);
  static const Color _stoneLineColor = Color(0xff92a99d);
  static const Color _tileColor = Color(0xffb97c65);

  final Paint _basePaint = Paint()..color = _baseColor;
  final Paint _jadePatchPaint = Paint()
    ..color = _jadePatchColor.withValues(alpha: .32);
  final Paint _stoneLinePaint = Paint()
    ..color = _stoneLineColor.withValues(alpha: .32);
  final Paint _tilePaint = Paint()..color = _tileColor.withValues(alpha: .42);

  /// Documents that the stage is presentation-only; it never owns hitboxes.
  bool get ownsCollision => false;

  Color get baseColor => _baseColor;

  Color get jadePatchColor => _jadePatchColor;

  /// The full render-time paint cache; no decoration allocates a [Paint].
  int get cachedPaintCount => 4;

  final List<StageDecoration> _decorations = [];

  List<StageDecoration> get decorations => List.unmodifiable(_decorations);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size.clone();
    _rebuildDecorations();
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(Offset.zero & size.toSize(), _basePaint);

    for (final decoration in _decorations) {
      final center = Offset(
        decoration.xFraction * size.x,
        decoration.yFraction * size.y,
      );
      final width = decoration.widthFraction * size.x;
      final height = decoration.heightFraction * size.y;
      switch (decoration.kind) {
        case StageDecorationKind.jadePatch:
          canvas.drawOval(
            Rect.fromCenter(center: center, width: width, height: height),
            _jadePatchPaint,
          );
        case StageDecorationKind.stoneLine:
          _stoneLinePaint.strokeWidth = math.max(1, math.min(2.5, height));
          canvas.drawLine(
            Offset(center.dx - width / 2, center.dy - height / 2),
            Offset(center.dx + width / 2, center.dy + height / 2),
            _stoneLinePaint,
          );
        case StageDecorationKind.tileFragment:
          final tile = Rect.fromCenter(
            center: center,
            width: width,
            height: math.max(2, height),
          );
          canvas.save();
          canvas.translate(center.dx, center.dy);
          canvas.rotate(decoration.rotation);
          canvas.translate(-center.dx, -center.dy);
          canvas.drawRRect(
            RRect.fromRectAndRadius(tile, const Radius.circular(1.5)),
            _tilePaint,
          );
          canvas.restore();
      }
    }
  }

  void _rebuildDecorations() {
    _decorations.clear();
    if (size.x <= 0 || size.y <= 0) return;

    final area = size.x * size.y;
    final count = (area / 22000).round().clamp(14, maxDecorationCount);
    final random = math.Random(_decorationSeed);
    for (var index = 0; index < count; index += 1) {
      final roll = random.nextInt(10);
      _decorations.add(
        StageDecoration(
          kind: roll < 4
              ? StageDecorationKind.jadePatch
              : roll < 8
              ? StageDecorationKind.stoneLine
              : StageDecorationKind.tileFragment,
          xFraction: .03 + random.nextDouble() * .94,
          yFraction: .04 + random.nextDouble() * .92,
          widthFraction: .025 + random.nextDouble() * .11,
          heightFraction: .004 + random.nextDouble() * .035,
          rotation: (random.nextDouble() - .5) * .8,
        ),
      );
    }
  }
}

enum StageDecorationKind { jadePatch, stoneLine, tileFragment }

/// Immutable, viewport-normalized render data for one low-cost stage detail.
class StageDecoration {
  const StageDecoration({
    required this.kind,
    required this.xFraction,
    required this.yFraction,
    required this.widthFraction,
    required this.heightFraction,
    required this.rotation,
  });

  final StageDecorationKind kind;
  final double xFraction;
  final double yFraction;
  final double widthFraction;
  final double heightFraction;
  final double rotation;

  @override
  bool operator ==(Object other) =>
      other is StageDecoration &&
      other.kind == kind &&
      other.xFraction == xFraction &&
      other.yFraction == yFraction &&
      other.widthFraction == widthFraction &&
      other.heightFraction == heightFraction &&
      other.rotation == rotation;

  @override
  int get hashCode => Object.hash(
    kind,
    xFraction,
    yFraction,
    widthFraction,
    heightFraction,
    rotation,
  );
}
