class RunFeedback {
  RunFeedback({
    required this.funRating,
    required this.difficultyRating,
    required this.retryIntent,
    required String comment,
  }) : comment = comment.trim() {
    if (funRating < 1 || funRating > 5) {
      throw ArgumentError.value(funRating, 'funRating', 'must be 1 through 5');
    }
    if (difficultyRating < 1 || difficultyRating > 5) {
      throw ArgumentError.value(
        difficultyRating,
        'difficultyRating',
        'must be 1 through 5',
      );
    }
    if (this.comment.length > 200) {
      throw ArgumentError.value(
        comment,
        'comment',
        'must be 200 characters or fewer',
      );
    }
  }

  final int funRating;
  final int difficultyRating;
  final bool retryIntent;
  final String comment;

  Map<String, dynamic> toJson() => {
    'funRating': funRating,
    'difficultyRating': difficultyRating,
    'retryIntent': retryIntent,
    'comment': comment,
  };

  factory RunFeedback.fromJson(Map<String, dynamic> json) {
    try {
      return RunFeedback(
        funRating: json['funRating'] as int,
        difficultyRating: json['difficultyRating'] as int,
        retryIntent: json['retryIntent'] as bool,
        comment: json['comment'] as String,
      );
    } on Object catch (error) {
      throw FormatException('Invalid run feedback payload', error);
    }
  }

  @override
  bool operator ==(Object other) =>
      other is RunFeedback &&
      other.funRating == funRating &&
      other.difficultyRating == difficultyRating &&
      other.retryIntent == retryIntent &&
      other.comment == comment;

  @override
  int get hashCode =>
      Object.hash(funRating, difficultyRating, retryIntent, comment);
}
