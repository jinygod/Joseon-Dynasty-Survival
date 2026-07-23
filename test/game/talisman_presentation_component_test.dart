import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/enemy_component.dart';
import 'package:pixel_survivor/game/components/talisman_presentation_component.dart';
import 'package:pixel_survivor/game/systems/talisman_executor.dart';
import 'package:pixel_survivor/game/content/combat_visual_factory.dart';

void main() {
  test('attached talisman mark stays anchored above its target', () {
    final enemy = EnemyComponent(
      enemyId: 'marked',
      maxHealth: 10,
      moveSpeed: 0,
      damage: 0,
      position: Vector2(20, 30),
    );
    final component = TalismanAttachmentComponent(
      seal: AttachedTalisman(
        target: enemy,
        attachedAtSeconds: 0,
        explodeAtSeconds: 1,
        transferDepth: 0,
        isCritical: false,
      ),
    );

    component.update(0);
    expect(component.position, Vector2(20, 30 - enemy.size.y / 2 - 7));
    expect(component.priority, greaterThan(AttackPresentationPriority.attack));

    enemy.position.setValues(45, 55);
    component.update(0);
    expect(component.position, Vector2(45, 55 - enemy.size.y / 2 - 7));
  });

  test('transfer cue is a short bounded visual with no attack instance', () {
    var expirations = 0;
    final component = TalismanTransferCueComponent(
      cue: TalismanTransferCue(
        source: Vector2(10, 20),
        target: Vector2(30, 40),
      ),
      onExpired: () => expirations += 1,
    );

    expect(component.source, Vector2(10, 20));
    expect(component.target, Vector2(30, 40));
    expect(component.lifetime, lessThanOrEqualTo(.25));
    component.update(component.lifetime);
    component.update(1);
    expect(expirations, 1);
  });

  test(
    'talisman delegates use cached registry visuals without owning damage',
    () {
      final target = EnemyComponent(
        enemyId: 'marked',
        maxHealth: 10,
        moveSpeed: 0,
        damage: 0,
        position: Vector2.zero(),
      );
      final attachment = TalismanAttachmentComponent(
        seal: AttachedTalisman(
          target: target,
          attachedAtSeconds: 0,
          explodeAtSeconds: 1,
          transferDepth: 0,
          isCritical: false,
        ),
        visualFactory: const CombatVisualFactory(images: {}),
      );
      final cue = TalismanTransferCueComponent(
        cue: TalismanTransferCue(
          source: Vector2.zero(),
          target: Vector2(10, 0),
        ),
        visualFactory: const CombatVisualFactory(images: {}),
      );

      expect(attachment.visualEffectId, 'talisman_attachment');
      expect(attachment.usesRegistryVisual, isTrue);
      expect(attachment.startsImageLoadOnMount, isFalse);
      expect(attachment.ownsDamageResolution, isFalse);
      expect(cue.visualEffectId, 'talisman_transfer');
      expect(cue.usesRegistryVisual, isTrue);
      expect(cue.startsImageLoadOnMount, isFalse);
      expect(cue.ownsDamageResolution, isFalse);
      final attachmentVisual = attachment.children.single;
      attachmentVisual.update(.01);
      expect(attachmentVisual.isRemoving, isFalse);
    },
  );
}
