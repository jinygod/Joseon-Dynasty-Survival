enum RunChoiceType { weapon, augment }

class RunChoiceRecord {
  const RunChoiceRecord({
    required this.type,
    required this.contentId,
    required this.selectedAtSeconds,
    required this.selectedLevel,
  });

  final RunChoiceType type;
  final String contentId;
  final int selectedAtSeconds;
  final int selectedLevel;

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'contentId': contentId,
    'selectedAtSeconds': selectedAtSeconds,
    'selectedLevel': selectedLevel,
  };

  factory RunChoiceRecord.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'];
    final type = RunChoiceType.values.where((value) => value.name == typeName);
    if (type.length != 1) {
      throw FormatException('Unknown run choice type: $typeName');
    }

    try {
      return RunChoiceRecord(
        type: type.single,
        contentId: json['contentId'] as String,
        selectedAtSeconds: json['selectedAtSeconds'] as int,
        selectedLevel: json['selectedLevel'] as int,
      );
    } on Object catch (error) {
      throw FormatException('Invalid run choice payload', error);
    }
  }

  @override
  bool operator ==(Object other) =>
      other is RunChoiceRecord &&
      other.type == type &&
      other.contentId == contentId &&
      other.selectedAtSeconds == selectedAtSeconds &&
      other.selectedLevel == selectedLevel;

  @override
  int get hashCode =>
      Object.hash(type, contentId, selectedAtSeconds, selectedLevel);
}
