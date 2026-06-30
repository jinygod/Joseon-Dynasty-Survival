class PlayerSlot {
  const PlayerSlot({
    required this.index,
    required this.characterId,
    this.isActive = true,
  });

  final int index;
  final String characterId;
  final bool isActive;
}
