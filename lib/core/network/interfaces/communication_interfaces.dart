import 'package:cms_local/features/player/domain/models/player.dart';
import 'package:cms_local/features/media/domain/models/media_item.dart';
import 'package:cms_local/features/schedule/domain/models/schedule.dart';

/// DTO pour la découverte de players sur le réseau
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

/// DTO pour les mises à jour de statut des players
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

/// Pour la découverte de players sur le réseau (mDNS ou scan subnet)
abstract class IPlayerDiscovery {
  /// Découvre les players disponibles sur le réseau local
  Future<List<PlayerDiscoveryInfo>> discoverPlayers();
}

/// Pour envoyer des planifications aux players
abstract class IScheduleSender {
  /// Envoie une planification à un player
  Future<bool> sendSchedule(Player player, Schedule schedule);
}

/// Pour envoyer des médias aux players
abstract class IMediaSender {
  /// Envoie un média à un player
  Future<bool> sendMedia(Player player, MediaItem media, List<int> fileBytes);

  /// Supprime un média d'un player
  Future<bool> deleteMedia(Player player, String mediaId);
}

/// Pour vérifier la disponibilité des players
abstract class IPlayerHealthChecker {
  /// Vérifie si un player est accessible
  Future<bool> checkAvailability(Player player);

  /// Récupère le statut détaillé d'un player
  Future<PlayerStatusUpdate?> getStatus(Player player);
}

/// Pour contrôler les players (play, stop, reboot)
abstract class IPlayerController {
  /// Démarre la lecture sur un player
  Future<bool> play(Player player, String mediaId);

  /// Arrête la lecture sur un player
  Future<bool> stop(Player player);

  /// Redémarre un player
  Future<bool> reboot(Player player);

  /// Synchronise un player avec les dernières planifications
  Future<bool> sync(Player player);
}

/// Pour le statut temps réel via WebSocket
abstract class IRealtimeStatusListener {
  /// Stream de mises à jour de statut en temps réel
  Stream<PlayerStatusUpdate> get statusStream;

  /// Connecte au WebSocket d'un player pour recevoir les mises à jour
  Future<void> connectToPlayer(Player player);

  /// Déconnecte du WebSocket
  Future<void> disconnect();

  /// Indique si la connexion WebSocket est active
  bool get isConnected;
}
