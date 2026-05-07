class Task {
  final String taskerId;
  final String taskName;
  final String taskDescription;
  final String taskType;
  final dynamic userPayoutNgn;
  final int? slotsLeft;
  final int priorityScore;
  final String? taskUrl;
  final bool hasParticipationBonus;

  const Task({
    required this.taskerId,
    required this.taskName,
    required this.taskDescription,
    required this.taskType,
    this.userPayoutNgn,
    this.slotsLeft,
    required this.priorityScore,
    this.taskUrl,
    required this.hasParticipationBonus,
  });

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      taskerId: map['id']?.toString() ?? '',
      taskName: map['app_name'] as String? ?? '',
      taskDescription: map['title'] as String? ?? '',
      taskType: map['task_type'] as String? ?? '',
      userPayoutNgn: map['user_payout_ngn'],
      slotsLeft: map['slots_left'] as int?,
      priorityScore: map['priority_score'] as int? ?? 0,
      taskUrl: map['task_url'] as String?,
      hasParticipationBonus: map['has_participation_bonus'] as bool? ?? false,
    );
  }
}
