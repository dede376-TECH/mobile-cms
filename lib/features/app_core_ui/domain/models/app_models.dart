import 'package:cms_local/features/player/domain/models/player.dart';

export '../../../../../features/player/domain/models/player.dart';
export '../../../media/domain/models/media_item.dart';
export '../../../schedule/domain/models/schedule.dart';

class PlayerDiscoveryInfo {
  final String id;
  final String? name;
  final String ipAddress;
  final int port;
  final String? version;

  PlayerDiscoveryInfo({
    required this.id,
    this.name,
    required this.ipAddress,
    required this.port,
    this.version,
  });
}

class PlayerStatusUpdate {
  final String playerId;
  final PlayerStatus status;
  final DateTime timestamp;
  final String? currentMedia;

  PlayerStatusUpdate({
    required this.playerId,
    required this.status,
    required this.timestamp,
    this.currentMedia,
  });
}
