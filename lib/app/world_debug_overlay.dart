import 'dart:async';

import 'package:flutter/material.dart';

import '../game/world/world_debug_snapshot.dart';

class WorldDebugOverlay extends StatefulWidget {
  const WorldDebugOverlay({required this.source, super.key});

  final WorldDebugSource source;

  @override
  State<WorldDebugOverlay> createState() => _WorldDebugOverlayState();
}

class _WorldDebugOverlayState extends State<WorldDebugOverlay> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (mounted && widget.source.worldDebugVisible) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.source.worldDebugVisible;
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (visible) _DebugPanel(snapshot: widget.source.debugSnapshot),
              const SizedBox(height: 6),
              SizedBox(
                key: const Key('world-debug-toggle'),
                width: 48,
                height: 32,
                child: Semantics(
                  button: true,
                  label: '월드 디버그 표시',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      widget.source.setWorldDebugVisible(!visible);
                      setState(() {});
                    },
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xcc101820),
                        border: Border.all(color: const Color(0xffffc857)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          visible ? 'OFF' : 'DBG',
                          style: const TextStyle(
                            color: Color(0xffffc857),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DebugPanel extends StatelessWidget {
  const _DebugPanel({required this.snapshot});

  final WorldDebugSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final text = [
      'FPS ${snapshot.fps.toStringAsFixed(1)}  '
          'p95 ${snapshot.frameTimeP95Ms.toStringAsFixed(1)}ms',
      '적 ${snapshot.activeEnemies} / sleep ${snapshot.sleepingEnemies}',
      'XP ${snapshot.activeExperienceGems} / 압축 ${snapshot.compressedExperience}',
      '투사체 ${snapshot.activeProjectiles}  VFX ${snapshot.activeVfx}',
      '컴포넌트 ${snapshot.mountedComponents}',
      '+${snapshot.componentCreatesPerSecond.toStringAsFixed(1)}/s  '
          '-${snapshot.componentRemovesPerSecond.toStringAsFixed(1)}/s',
      'zoom ${snapshot.cameraZoom.toStringAsFixed(2)}  '
          'chunk ${snapshot.chunkSize.toStringAsFixed(0)}',
    ].join('\n');
    return DecoratedBox(
      key: const Key('world-debug-panel'),
      decoration: BoxDecoration(
        color: const Color(0xe6101820),
        border: Border.all(color: const Color(0xfff4ead2)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xfff4ead2),
            fontSize: 10,
            height: 1.25,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
