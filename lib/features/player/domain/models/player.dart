class Player {
  final String id;
  final String name;
  final String ipAddress;
  final int port;
  final String? description;
  final PlayerStatus status;
  final DateTime lastSeen;
  final DateTime createdAt;

  Player({
    required this.id,
    required this.name,
    required this.ipAddress,
    this.port = 8080,
    this.description,
    this.status = PlayerStatus.offline,
    required this.lastSeen,
    required this.createdAt,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
      ipAddress: json['ipAddress'] as String,
      port: json['port'] as int? ?? 8080,
      description: json['description'] as String?,
      status: PlayerStatus.values.byName(
        json['status'] as String? ?? 'offline',
      ),
      lastSeen: DateTime.parse(json['lastSeen'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ipAddress': ipAddress,
      'port': port,
      'description': description,
      'status': status.name,
      'lastSeen': lastSeen.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Player copyWith({
    String? id,
    String? name,
    String? ipAddress,
    int? port,
    String? description,
    PlayerStatus? status,
    DateTime? lastSeen,
    DateTime? createdAt,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      description: description ?? this.description,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get baseUrl => 'http://$ipAddress:$port';
}

enum PlayerStatus { online, offline, playing, error }
