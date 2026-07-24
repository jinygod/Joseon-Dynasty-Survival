import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

enum WorldActivityTier { visible, active, sleeping, recycle }

@immutable
class WorldActivityZones {
  const WorldActivityZones._({
    required this.visibleRect,
    required this.activeRect,
    required this.sleepingRect,
    required this.worldBounds,
    required this.hysteresis,
  });

  factory WorldActivityZones.fromVisibleRect(
    Rect visibleRect, {
    required Rect worldBounds,
    required double hysteresis,
  }) {
    if (!hysteresis.isFinite || hysteresis < 0) {
      throw ArgumentError.value(hysteresis, 'hysteresis');
    }
    final visible = visibleRect.intersect(worldBounds);
    final active = _expand(
      visible,
      visible.width * .75,
      visible.height * .75,
    ).intersect(worldBounds);
    final sleeping = _expand(
      active,
      visible.width * 1.5,
      visible.height * 1.5,
    ).intersect(worldBounds);
    return WorldActivityZones._(
      visibleRect: visible,
      activeRect: active,
      sleepingRect: sleeping,
      worldBounds: worldBounds,
      hysteresis: hysteresis,
    );
  }

  final Rect visibleRect;
  final Rect activeRect;
  final Rect sleepingRect;
  final Rect worldBounds;
  final double hysteresis;

  WorldActivityTier classify(Vector2 position, {WorldActivityTier? previous}) {
    final point = position.toOffset();
    if (previous != null) {
      switch (previous) {
        case WorldActivityTier.visible:
          if (visibleRect.inflate(hysteresis).contains(point)) return previous;
          break;
        case WorldActivityTier.active:
          if (_deflateSafe(visibleRect, hysteresis).contains(point)) {
            return WorldActivityTier.visible;
          }
          if (activeRect.inflate(hysteresis).contains(point)) return previous;
          break;
        case WorldActivityTier.sleeping:
          if (_deflateSafe(activeRect, hysteresis).contains(point)) {
            return visibleRect.contains(point)
                ? WorldActivityTier.visible
                : WorldActivityTier.active;
          }
          if (sleepingRect.inflate(hysteresis).contains(point)) return previous;
          break;
        case WorldActivityTier.recycle:
          if (!_deflateSafe(sleepingRect, hysteresis).contains(point)) {
            return previous;
          }
          break;
      }
    }
    if (visibleRect.contains(point)) return WorldActivityTier.visible;
    if (activeRect.contains(point)) return WorldActivityTier.active;
    if (sleepingRect.contains(point)) return WorldActivityTier.sleeping;
    return WorldActivityTier.recycle;
  }
}

Rect _expand(Rect rect, double horizontal, double vertical) {
  return Rect.fromLTRB(
    rect.left - horizontal,
    rect.top - vertical,
    rect.right + horizontal,
    rect.bottom + vertical,
  );
}

Rect _deflateSafe(Rect rect, double amount) {
  if (rect.width <= amount * 2 || rect.height <= amount * 2) {
    return Rect.fromCenter(center: rect.center, width: 0, height: 0);
  }
  return rect.deflate(amount);
}
