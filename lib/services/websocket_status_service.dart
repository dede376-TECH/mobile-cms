import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:cms_local/core/network/interfaces/communication_interfaces.dart';
import 'package:cms_local/features/player/domain/models/player.dart';

/// Service WebSocket pour le statut temps réel des players
/// Remplace le polling HTTP toutes les 30 secondes par une connexion persistante
/// - Push instantané des changements de statut
/// - Moins de consommation réseau
/// - Détection immédiate des déconnexions
class WebSocketStatusService implements IRealtimeStatusListener {
  WebSocketChannel? _channel;
  final _statusController = StreamController<PlayerStatusUpdate>.broadcast();
  Player? _connectedPlayer;
  bool _isConnected = false;

  @override
  Stream<PlayerStatusUpdate> get statusStream => _statusController.stream;

  @override
  bool get isConnected => _isConnected;

  @override
  Future<void> connectToPlayer(Player player) async {
    // Déconnecte d'abord si déjà connecté
    await disconnect();

    _connectedPlayer = player;

    try {
      final wsUrl = 'ws://${player.ipAddress}:${player.port}/api/ws';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _isConnected = true;

      // Écoute les messages entrants
      _channel!.stream.listen(
        (message) => _handleMessage(message, player),
        onError: (error) {
          _isConnected = false;
          _statusController.add(
            PlayerStatusUpdate(
              playerId: player.id,
              status: PlayerStatus.offline,
              timestamp: DateTime.now(),
            ),
          );
        },
        onDone: () {
          _isConnected = false;
          _statusController.add(
            PlayerStatusUpdate(
              playerId: player.id,
              status: PlayerStatus.offline,
              timestamp: DateTime.now(),
            ),
          );
        },
      );

      // Envoie un message d'identification
      _channel!.sink.add(
        jsonEncode({
          'type': 'register',
          'role': 'controller',
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      _isConnected = false;
      // Fallback sur HTTP si WebSocket échoue
    }
  }

  void _handleMessage(dynamic message, Player player) {
    try {
      final data = jsonDecode(message as String);
      final msgType = data['type'] as String?;

      switch (msgType) {
        case 'status':
          _statusController.add(
            PlayerStatusUpdate(
              playerId: player.id,
              status: PlayerStatus.values.byName(data['status'] as String),
              currentMedia: data['currentMedia'] as String?,
              timestamp: DateTime.now(),
            ),
          );
          break;

        case 'heartbeat':
          // Répond au heartbeat pour garder la connexion active
          _channel?.sink.add(
            jsonEncode({
              'type': 'heartbeat_ack',
              'timestamp': DateTime.now().toIso8601String(),
            }),
          );
          break;

        case 'error':
          _statusController.add(
            PlayerStatusUpdate(
              playerId: player.id,
              status: PlayerStatus.error,
              currentMedia: data['message'] as String?,
              timestamp: DateTime.now(),
            ),
          );
          break;
      }
    } catch (e) {
      // Ignore les messages malformés
    }
  }

  /// Envoie une commande au player via WebSocket
  Future<void> sendCommand(String command, Map<String, dynamic> payload) async {
    if (!isConnected || _channel == null) return;

    _channel!.sink.add(
      jsonEncode({
        'type': 'command',
        'command': command,
        'payload': payload,
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );
  }

  @override
  Future<void> disconnect() async {
    _isConnected = false;

    if (_channel != null) {
      try {
        _channel!.sink.add(
          jsonEncode({
            'type': 'unregister',
            'timestamp': DateTime.now().toIso8601String(),
          }),
        );
        await _channel!.sink.close(status.normalClosure);
      } catch (e) {
        // Ignore les erreurs de fermeture
      }
      _channel = null;
    }

    _connectedPlayer = null;
  }

  void dispose() {
    disconnect();
    _statusController.close();
  }
}

/// Factory pour créer le bon service de status selon la disponibilité
class StatusServiceFactory {
  /// Crée le service de statut approprié
  /// Essaie d'abord WebSocket, sinon retourne null (le caller utilisera HTTP polling)
  static IRealtimeStatusListener? createStatusService() {
    try {
      return WebSocketStatusService();
    } catch (e) {
      return null;
    }
  }
}
