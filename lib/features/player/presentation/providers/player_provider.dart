import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app_core_ui/domain/interfaces/icommunication_interfaces.dart';
import '../../../app_core_ui/domain/models/app_models.dart';
import '../../domain/models/player.dart';
import '../../domain/interfaces/iplayer_repository.dart';
import '../../../schedule/domain/models/schedule.dart';
import '../../../../core/di/injection_container.dart';

/// Provider pour la gestion des players
/// Respecte SRP : ne gère QUE les players
/// DIP : dépend des interfaces, pas des implémentations concrètes
class PlayerProvider extends ChangeNotifier {
  // Dependencies (injected via constructor - DIP)
  final IPlayerRepository _repository;
  final IPlayerDiscovery _discovery;
  final IPlayerHealthChecker _healthChecker;
  final IPlayerController _controller;
  final IScheduleSender? _scheduleSender; // Optional for sync
  final IRealtimeStatusListener? _realtimeStatus;

  // State
  List<Player> _players = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<PlayerStatusUpdate>? _statusSubscription;

  // Getters
  List<Player> get players => _players;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Constructor avec injection de dépendances (DIP)
  PlayerProvider({
    required IPlayerRepository repository,
    required IPlayerDiscovery discovery,
    required IPlayerHealthChecker healthChecker,
    required IPlayerController controller,
    IScheduleSender? scheduleSender,
    IRealtimeStatusListener? realtimeStatus,
  }) : _repository = repository,
       _discovery = discovery,
       _healthChecker = healthChecker,
       _controller = controller,
       _scheduleSender = scheduleSender,
       _realtimeStatus = realtimeStatus {
    _initialize();
  }

  Future<void> _initialize() async {
    await loadPlayers();
    _setupRealtimeStatus();
  }

  void _setupRealtimeStatus() {
    if (_realtimeStatus == null) return;

    // Écoute les mises à jour temps réel
    _statusSubscription = _realtimeStatus.statusStream.listen((update) {
      _updatePlayerStatus(update.playerId, update.status);
    });
  }

  // ==================== CRUD Operations ====================

  Future<void> loadPlayers() async {
    _setLoading(true);
    try {
      _players = _repository.getAll();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur chargement players: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<List<PlayerDiscoveryInfo>> discoverPlayers() async {
    _setLoading(true);
    try {
      final discovered = await _discovery.discoverPlayers();
      _error = null;
      return discovered;
    } catch (e) {
      _error = 'Erreur découverte players: $e';
      return [];
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addPlayer({
    required String name,
    required String ipAddress,
    int port = 8080,
    String? description,
  }) async {
    _setLoading(true);
    try {
      final player = Player(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        ipAddress: ipAddress,
        port: port,
        description: description,
        lastSeen: DateTime.now(),
        createdAt: DateTime.now(),
      );

      // Vérifie la disponibilité
      final isAvailable = await _healthChecker.checkAvailability(player);
      final playerWithStatus = player.copyWith(
        status: isAvailable ? PlayerStatus.online : PlayerStatus.offline,
      );

      await _repository.save(playerWithStatus);
      _players = _repository.getAll();
      _error = null;
      notifyListeners();

      // Connecte WebSocket si disponible
      if (isAvailable && _realtimeStatus != null) {
        await _realtimeStatus.connectToPlayer(playerWithStatus);
      }
    } catch (e) {
      _error = 'Erreur ajout player: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deletePlayer(String playerId) async {
    _setLoading(true);
    try {
      await _repository.delete(playerId);
      _players.removeWhere((player) => player.id == playerId);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur suppression player: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> checkAllPlayersStatus() async {
    _setLoading(true);
    try {
      final updatedPlayers = <Player>[];
      for (final player in _players) {
        final statusUpdate = await _healthChecker.getStatus(player);
        if (statusUpdate != null) {
          updatedPlayers.add(
            player.copyWith(
              status: statusUpdate.status,
              lastSeen: statusUpdate.timestamp,
            ),
          );
        } else {
          updatedPlayers.add(
            player.copyWith(
              status: PlayerStatus.offline,
              lastSeen: DateTime.now(),
            ),
          );
        }
      }
      _players = updatedPlayers;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur vérification statut players: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> syncPlayer(Player player, List<Schedule> schedules) async {
    if (_scheduleSender == null) {
      _error = 'Service d\'envoi de planification non disponible.';
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      for (final schedule in schedules) {
        final success = await _scheduleSender.sendSchedule(player, schedule);
        if (!success) {
          throw Exception(
            'Échec de l\'envoi de la planification ${schedule.name}',
          );
        }
      }
      _error = null;
    } catch (e) {
      _error = 'Erreur synchronisation player: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> rebootPlayer(Player player) async {
    _setLoading(true);
    try {
      final success = await _controller.reboot(player);
      if (!success) {
        throw Exception('Échec du redémarrage du player.');
      }
      _error = null;
    } catch (e) {
      _error = 'Erreur redémarrage player: $e';
    } finally {
      _setLoading(false);
    }
  }

  void _updatePlayerStatus(String playerId, PlayerStatus status) {
    final index = _players.indexWhere((p) => p.id == playerId);
    if (index != -1) {
      _players[index] = _players[index].copyWith(
        status: status,
        lastSeen: DateTime.now(),
      );
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _realtimeStatus?.disconnect();
    super.dispose();
  }
}

final playerProviderRef = ChangeNotifierProvider((ref) {
  final repository = sl<IPlayerRepository>();
  final discovery = sl<IPlayerDiscovery>();
  final healthChecker = sl<IPlayerHealthChecker>();
  final controller = sl<IPlayerController>();
  final scheduleSender = sl<IScheduleSender>();
  final realtimeStatus = sl<IRealtimeStatusListener>();

  return PlayerProvider(
    repository: repository,
    discovery: discovery,
    healthChecker: healthChecker,
    controller: controller,
    scheduleSender: scheduleSender,
    realtimeStatus: realtimeStatus,
  );
});
