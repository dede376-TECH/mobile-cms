import '../../../media/domain/models/media_item.dart';

class Schedule {
  final String id;
  final String name;
  final String playerId;
  final DateTime startDate;
  final DateTime endDate;
  final RecurrencePattern recurrence;
  final List<ScheduledMedia> mediaItems;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Schedule({
    required this.id,
    required this.name,
    required this.playerId,
    required this.startDate,
    required this.endDate,
    this.recurrence = RecurrencePattern.none,
    required this.mediaItems,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'] as String,
      name: json['name'] as String,
      playerId: json['playerId'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      recurrence: RecurrencePattern.values.byName(
        json['recurrence'] as String? ?? 'none',
      ),
      mediaItems: (json['mediaItems'] as List<dynamic>)
          .map((e) => ScheduledMedia.fromJson(e as Map<String, dynamic>))
          .toList(),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'playerId': playerId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'recurrence': recurrence.name,
      'mediaItems': mediaItems.map((e) => e.toJson()).toList(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Schedule copyWith({
    String? id,
    String? name,
    String? playerId,
    DateTime? startDate,
    DateTime? endDate,
    RecurrencePattern? recurrence,
    List<ScheduledMedia>? mediaItems,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Schedule(
      id: id ?? this.id,
      name: name ?? this.name,
      playerId: playerId ?? this.playerId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      recurrence: recurrence ?? this.recurrence,
      mediaItems: mediaItems ?? this.mediaItems,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool isCurrentlyActive() {
    final now = DateTime.now();
    if (!isActive) return false;
    if (now.isBefore(startDate) || now.isAfter(endDate)) return false;

    if (recurrence == RecurrencePattern.none) {
      return now.isAfter(startDate) && now.isBefore(endDate);
    }

    return _matchesRecurrence(now);
  }

  bool _matchesRecurrence(DateTime dateTime) {
    switch (recurrence) {
      case RecurrencePattern.daily:
        return true;
      case RecurrencePattern.weekdays:
        final weekday = dateTime.weekday;
        return weekday >= 1 && weekday <= 5;
      case RecurrencePattern.weekends:
        final weekday = dateTime.weekday;
        return weekday == 6 || weekday == 7;
      case RecurrencePattern.weekly:
        return dateTime.weekday == startDate.weekday;
      case RecurrencePattern.none:
        return true;
    }
  }
}

class ScheduledMedia {
  final String mediaId;
  final int order;
  final int duration;
  final TransitionType transition;
  final int transitionDuration;

  ScheduledMedia({
    required this.mediaId,
    required this.order,
    this.duration = 10,
    this.transition = TransitionType.fade,
    this.transitionDuration = 500,
  });

  factory ScheduledMedia.fromJson(Map<String, dynamic> json) {
    return ScheduledMedia(
      mediaId: json['mediaId'] as String,
      order: json['order'] as int,
      duration: json['duration'] as int? ?? 10,
      transition: TransitionType.values.byName(
        json['transition'] as String? ?? 'fade',
      ),
      transitionDuration: json['transitionDuration'] as int? ?? 500,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mediaId': mediaId,
      'order': order,
      'duration': duration,
      'transition': transition.name,
      'transitionDuration': transitionDuration,
    };
  }

  ScheduledMedia copyWith({
    String? mediaId,
    int? order,
    int? duration,
    TransitionType? transition,
    int? transitionDuration,
  }) {
    return ScheduledMedia(
      mediaId: mediaId ?? this.mediaId,
      order: order ?? this.order,
      duration: duration ?? this.duration,
      transition: transition ?? this.transition,
      transitionDuration: transitionDuration ?? this.transitionDuration,
    );
  }
}

enum RecurrencePattern { none, daily, weekdays, weekends, weekly }
