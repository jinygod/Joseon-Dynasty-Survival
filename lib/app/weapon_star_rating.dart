import 'package:flutter/material.dart';

class WeaponStarRating extends StatelessWidget {
  const WeaponStarRating({
    super.key,
    required this.level,
    this.compact = false,
  });

  static const _masteryLevel = 6;
  static const _starSlots = 5;
  static const _masteryColor = Color(0xff159a9c);

  final int level;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final displayedLevel = level.clamp(1, _masteryLevel);
    final isMastered = displayedLevel == _masteryLevel;
    final filledStars = isMastered ? _starSlots : displayedLevel;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < filledStars; index++)
          Icon(
            Icons.star,
            key: Key('filled-star-$index'),
            color: isMastered ? _masteryColor : Colors.amber,
            size: compact ? 14 : 18,
          ),
        if (!compact)
          for (var index = filledStars; index < _starSlots; index++)
            Icon(
              Icons.star_border,
              key: Key('empty-star-$index'),
              color: Colors.grey,
              size: 18,
            ),
        if (isMastered) ...[const SizedBox(width: 4), const Text('통달')],
      ],
    );
  }
}
