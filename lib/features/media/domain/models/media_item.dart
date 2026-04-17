class MediaItem {
  final String id;
  final String name;
  final String filePath;
  final MediaType type;
  final int duration; // in seconds
  final TransitionType transition;
  final int transitionDuration; // in milliseconds
  final DateTime createdAt;

  MediaItem({
    required this.id,
    required this.name,
    required this.filePath,
    required this.type,
    this.duration = 10,
    this.transition = TransitionType.fade,
    this.transitionDuration = 500,
    required this.createdAt,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'] as String,
      name: json['name'] as String,
      filePath: json['filePath'] as String,
      type: MediaType.values.byName(json['type'] as String),
      duration: json['duration'] as int? ?? 10,
      transition: TransitionType.values.byName(
        json['transition'] as String? ?? 'fade',
      ),
      transitionDuration: json['transitionDuration'] as int? ?? 500,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'filePath': filePath,
      'type': type.name,
      'duration': duration,
      'transition': transition.name,
      'transitionDuration': transitionDuration,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  MediaItem copyWith({
    String? id,
    String? name,
    String? filePath,
    MediaType? type,
    int? duration,
    TransitionType? transition,
    int? transitionDuration,
    DateTime? createdAt,
  }) {
    return MediaItem(
      id: id ?? this.id,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      transition: transition ?? this.transition,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum MediaType { image, video }

enum TransitionType { none, fade, slide, zoom }
