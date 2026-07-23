import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/content/attack_visual_registry.dart';
import '../game/vfx_gallery_game.dart';

class VfxGalleryScreen extends StatefulWidget {
  const VfxGalleryScreen({this.game, super.key});
  final VfxGalleryGame? game;

  @override
  State<VfxGalleryScreen> createState() => _VfxGalleryScreenState();
}

class _VfxGalleryScreenState extends State<VfxGalleryScreen> {
  late final VfxGalleryGame _game = widget.game ?? VfxGalleryGame();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('VFX Gallery')),
    body: LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: constraints.maxWidth < 960 ? 936 : constraints.maxWidth,
            child: ValueListenableBuilder<VfxGalleryStatus>(
              valueListenable: _game.status,
              builder: (context, status, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 300,
                    child: GameWidget<VfxGalleryGame>(game: _game),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      DropdownButton<String>(
                        key: const Key('vfx-effect-selector'),
                        value: status.selectedEffectId,
                        items: AttackVisualRegistry.effectIds
                            .map(
                              (id) =>
                                  DropdownMenuItem(value: id, child: Text(id)),
                            )
                            .toList(),
                        onChanged: (id) {
                          if (id != null) _game.selectEffect(id);
                        },
                      ),
                      for (final speed in const [.25, .5, 1.0])
                        ChoiceChip(
                          key: Key(
                            'vfx-speed-${(speed * 100).toInt().toString().padLeft(3, '0')}',
                          ),
                          label: Text('${speed}x'),
                          selected: status.speed == speed,
                          onSelected: (_) => _game.setSpeed(speed),
                        ),
                      FilterChip(
                        key: const Key('vfx-loop-toggle'),
                        label: const Text('Loop'),
                        selected: status.looping,
                        onSelected: _game.setLooping,
                      ),
                      ChoiceChip(
                        key: const Key('vfx-background-moonlit'),
                        label: const Text('Moonlit'),
                        selected:
                            status.background == VfxGalleryBackground.moonlit,
                        onSelected: (_) =>
                            _game.setBackground(VfxGalleryBackground.moonlit),
                      ),
                      ChoiceChip(
                        key: const Key('vfx-background-plague'),
                        label: const Text('Plague'),
                        selected:
                            status.background == VfxGalleryBackground.plague,
                        onSelected: (_) =>
                            _game.setBackground(VfxGalleryBackground.plague),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var index = 0; index < 8; index += 1)
                        ChoiceChip(
                          key: Key('vfx-direction-$index'),
                          label: Text('Dir $index'),
                          selected: status.directionIndex == index,
                          onSelected: (_) => _game.setDirectionIndex(index),
                        ),
                      FilterChip(
                        key: const Key('vfx-actor-toggle'),
                        label: const Text('Actor'),
                        selected: status.showActorReference,
                        onSelected: _game.setShowActorReference,
                      ),
                      FilterChip(
                        key: const Key('vfx-hitbox-toggle'),
                        label: const Text('Hitbox'),
                        selected: status.showHitbox,
                        onSelected: _game.setShowHitbox,
                      ),
                      FilterChip(
                        key: const Key('vfx-anchor-toggle'),
                        label: const Text('Anchor'),
                        selected: status.showAnchor,
                        onSelected: _game.setShowAnchor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Effect: ${status.selectedEffectId}'),
                  Text(
                    'Frame: ${status.currentFrame}',
                    key: const Key('vfx-current-frame'),
                  ),
                  Text(
                    'Active components: ${status.activeProductionComponentCount}',
                    key: const Key('vfx-active-component-count'),
                  ),
                  Text(
                    'Direction: ${status.directionIndex}  Speed: ${status.speed}x',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
