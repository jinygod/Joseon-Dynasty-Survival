import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../content/combat_effect_atlas.dart';
import '../world/experience_gem_coordinator.dart';
import 'player_component.dart';

enum ExperienceGemState { idle, magnet, orbit, consume, released }

typedef ExperienceTargetProvider = Vector2 Function();
typedef ExperiencePickupCompleted = void Function(ExperiencePickupToken token);

class ExperienceGemComponent extends PositionComponent {
  static const _maximumVisualScale = 1.65;
  static const pickupDurationSeconds = .24;
  static const orbitSweepRadians = pi * .75;
  static const _magnetEnd = .08;
  static const _orbitEnd = .18;

  ExperienceGemComponent({
    required this.experienceValue,
    this.ledgerRecordId,
    Image? atlasImage,
    Vector2? position,
    this.pickupRadius = 28,
    Vector2? size,
  }) : super(
         position: position ?? Vector2.zero(),
         size: size ?? Vector2.all(20),
         anchor: Anchor.center,
       ) {
    _buildCachedGeometry();
    if (atlasImage != null) _setAtlas(atlasImage);
  }

  int experienceValue;
  int? ledgerRecordId;
  final double pickupRadius;
  double _age = 0;
  double _pickupElapsed = 0;
  Image? _atlasImage;
  List<Sprite> _atlasSprites = const [];
  ExperienceTargetProvider? _targetPosition;
  ExperiencePickupCompleted? _onComplete;
  ExperiencePickupToken? _pickupToken;
  final Vector2 _pickupOrigin = Vector2.zero();
  final Vector2 _magnetEndPosition = Vector2.zero();
  double _orbitStartAngle = 0;

  late final Path _diamond;
  final Paint _haloPaint = Paint();
  final Paint _innerPaint = Paint();
  final Paint _corePaint = Paint();
  final Paint _outlinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  final Paint _sparkPaint = Paint();
  final Paint _atlasPaint = Paint();
  final Vector2 _atlasPosition = Vector2.zero();
  final Vector2 _atlasSize = Vector2.zero();

  ExperienceGemState state = ExperienceGemState.idle;
  double presentationOpacity = 1;
  double presentationScale = 1;

  double get visualScale => visualScaleForValue(experienceValue);
  double get haloOpacity => haloOpacityForValue(experienceValue);
  bool get isIdle => state == ExperienceGemState.idle;
  bool get isBeingPickedUp =>
      state == ExperienceGemState.magnet ||
      state == ExperienceGemState.orbit ||
      state == ExperienceGemState.consume;

  static double visualScaleForValue(int value) {
    final normalizedValue = max(1, value);
    return (1 + (sqrt(normalizedValue) - 1) * .08)
        .clamp(1, _maximumVisualScale)
        .toDouble();
  }

  static double haloOpacityForValue(int value) {
    final scaleProgress =
        (visualScaleForValue(value) - 1) / (_maximumVisualScale - 1);
    return (.16 + scaleProgress * .24).clamp(.16, .40).toDouble();
  }

  void absorbExperience(int amount) {
    if (amount > 0) experienceValue += amount;
  }

  bool beginPickup({
    required ExperienceTargetProvider targetPosition,
    required ExperiencePickupToken token,
    required ExperiencePickupCompleted onComplete,
  }) {
    if (!isIdle || token.value != experienceValue) return false;
    _targetPosition = targetPosition;
    _pickupToken = token;
    _onComplete = onComplete;
    _pickupElapsed = 0;
    _pickupOrigin.setFrom(position);
    final target = targetPosition();
    final away = position - target;
    if (away.length2 == 0) {
      away.setValues(1, 0);
    } else {
      away.normalize();
    }
    _magnetEndPosition.setFrom(target + away * 18);
    _orbitStartAngle = atan2(
      _magnetEndPosition.y - target.y,
      _magnetEndPosition.x - target.x,
    );
    state = ExperienceGemState.magnet;
    return true;
  }

  ExperiencePickupToken? cancelPickup() {
    final token = _pickupToken;
    if (!isBeingPickedUp || token == null) return null;
    state = ExperienceGemState.idle;
    _pickupElapsed = 0;
    presentationOpacity = 1;
    presentationScale = 1;
    _pickupToken = null;
    _targetPosition = null;
    _onComplete = null;
    return token;
  }

  void resetForReuse({
    required int experienceValue,
    required Vector2 position,
    required int ledgerRecordId,
  }) {
    this.experienceValue = experienceValue;
    this.ledgerRecordId = ledgerRecordId;
    this.position.setFrom(position);
    state = ExperienceGemState.idle;
    _age = 0;
    _pickupElapsed = 0;
    presentationOpacity = 1;
    presentationScale = 1;
    _pickupToken = null;
    _targetPosition = null;
    _onComplete = null;
  }

  @override
  void onLoad() {
    super.onLoad();
    unawaited(_loadAtlas());
  }

  Future<void> _loadAtlas() async {
    if (_atlasImage != null) return;
    final image = await CombatEffectAtlas.load(this);
    if (image == null) return;
    _setAtlas(image);
  }

  void _setAtlas(Image image) {
    _atlasImage = image;
    _atlasSprites = List.generate(
      CombatEffectAtlas.framesPerEffect,
      (frame) => CombatEffectAtlas.sprite(
        image,
        kind: CombatEffectKind.experience,
        frame: frame,
      ),
      growable: false,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!dt.isFinite || dt <= 0) return;
    _age += dt;
    if (!isBeingPickedUp) return;
    _pickupElapsed = min(pickupDurationSeconds, _pickupElapsed + dt);
    final target = _targetPosition!();

    if (_pickupElapsed < _magnetEnd) {
      state = ExperienceGemState.magnet;
      final t = (_pickupElapsed / _magnetEnd).clamp(0, 1).toDouble();
      final accelerated = t * t * t;
      position.setFrom(
        _pickupOrigin + (_magnetEndPosition - _pickupOrigin) * accelerated,
      );
    } else if (_pickupElapsed < _orbitEnd) {
      state = ExperienceGemState.orbit;
      final t = ((_pickupElapsed - _magnetEnd) / (_orbitEnd - _magnetEnd))
          .clamp(0, 1)
          .toDouble();
      final angle = _orbitStartAngle + orbitSweepRadians * t;
      final radius = 18 * (1 - t * .55);
      position.setValues(
        target.x + cos(angle) * radius,
        target.y + sin(angle) * radius,
      );
      presentationScale = 1 + .16 * sin(pi * t);
    } else {
      state = ExperienceGemState.consume;
      final t =
          ((_pickupElapsed - _orbitEnd) / (pickupDurationSeconds - _orbitEnd))
              .clamp(0, 1)
              .toDouble();
      position.add((target - position) * min(1, t * .72 + .28));
      presentationScale = (1 + .24 * sin(pi * t)) * (1 - t);
      presentationOpacity = 1 - t;
    }

    if (_pickupElapsed < pickupDurationSeconds) return;
    state = ExperienceGemState.released;
    presentationOpacity = 0;
    presentationScale = 0;
    final token = _pickupToken;
    final onComplete = _onComplete;
    _pickupToken = null;
    _targetPosition = null;
    _onComplete = null;
    if (token != null && onComplete != null) onComplete(token);
  }

  bool canBePickedUpBy(PlayerComponent player, {double additionalRadius = 0}) {
    if (!isIdle) return false;
    final effectiveRadius = pickupRadius + additionalRadius;
    return position.distanceToSquared(player.position) <=
        effectiveRadius * effectiveRadius;
  }

  @override
  void render(Canvas canvas) {
    if (state == ExperienceGemState.released) return;
    super.render(canvas);

    final center = Offset(size.x / 2, size.y / 2);
    final pulse = 1 + sin(_age * 5.5) * .06;
    final renderScale = visualScale * pulse * presentationScale;
    final alpha = presentationOpacity;
    final floatOffset = state == ExperienceGemState.idle
        ? sin(_age * 2.8) * 1.2
        : 0.0;

    _haloPaint.color = const Color(
      0xff58c7ff,
    ).withValues(alpha: haloOpacity * alpha);
    _innerPaint.color = const Color(0xff1c7ec9).withValues(alpha: .28 * alpha);
    _corePaint.color = const Color(0xff45b9f5).withValues(alpha: alpha);
    _outlinePaint.color = const Color(
      0xffffffff,
    ).withValues(alpha: .94 * alpha);
    _sparkPaint.color = const Color(0xffffffff).withValues(alpha: .78 * alpha);
    _atlasPaint.color = Color.fromRGBO(255, 255, 255, alpha);

    canvas.save();
    canvas.translate(center.dx, center.dy + floatOffset);
    canvas.scale(renderScale);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawCircle(center, size.x * .56, _haloPaint);
    canvas.drawCircle(center, size.x * .42, _innerPaint);
    canvas.drawPath(_diamond, _corePaint);

    if (_atlasImage != null && _atlasSprites.isNotEmpty) {
      final accentExtent = size.x * .38;
      _atlasPosition.setValues(
        center.dx - accentExtent / 2,
        center.dy - accentExtent / 2,
      );
      _atlasSize.setValues(accentExtent, accentExtent);
      _atlasSprites[((_age / .10).floor()) % _atlasSprites.length].render(
        canvas,
        position: _atlasPosition,
        size: _atlasSize,
        overridePaint: _atlasPaint,
      );
    }

    canvas.drawPath(_diamond, _outlinePaint);
    for (var index = 0; index < 2; index++) {
      final angle = _age * 3.6 + index * pi;
      final orbitRadius = size.x * .47;
      canvas.drawCircle(
        Offset(
          center.dx + cos(angle) * orbitRadius,
          center.dy + sin(angle) * orbitRadius,
        ),
        1.1 + (visualScale - 1) * 1.2,
        _sparkPaint,
      );
    }
    canvas.restore();
  }

  void _buildCachedGeometry() {
    final center = Offset(size.x / 2, size.y / 2);
    final coreRadius = size.x * .31;
    _diamond = Path()
      ..moveTo(center.dx, center.dy - coreRadius)
      ..lineTo(center.dx + coreRadius, center.dy)
      ..lineTo(center.dx, center.dy + coreRadius)
      ..lineTo(center.dx - coreRadius, center.dy)
      ..close();
  }
}
