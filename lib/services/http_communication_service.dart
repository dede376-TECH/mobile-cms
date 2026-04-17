import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../features/app_core_ui/domain/interfaces/icommunication_interfaces.dart';
import '../features/app_core_ui/domain/models/app_models.dart';

/// Service de communication HTTP implémentant les interfaces séparées
/// Respecte ISP (Interface Segregation Principle) : chaque interface a sa propre implémentation
class HttpCommunicationService
    implements
        IScheduleSender,
        IMediaSender,
        IPlayerHealthChecker,
        IPlayerController {
  final Duration _timeout;
  final Duration _mediaTimeout;

  HttpCommunicationService({Duration? timeout, Duration? mediaTimeout})
    : _timeout = timeout ?? const Duration(seconds: 6),
      _mediaTimeout = mediaTimeout ?? const Duration(seconds: 30);

  String _baseUrl(Player player) => 'http://${player.ipAddress}:${player.port}';

  // ==================== IPlayerHealthChecker ====================

  @override
  Future<bool> checkAvailability(Player player) async {
    try {
      final response = await http
          .get(Uri.parse('${_baseUrl(player)}/api/health'))
          .timeout(_timeout);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<PlayerStatusUpdate?> getStatus(Player player) async {
    try {
      final response = await http
          .get(Uri.parse('${_baseUrl(player)}/api/status'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PlayerStatusUpdate(
          playerId: player.id,
          status: PlayerStatus.values.byName(data['status'] as String),
          currentMedia: data['currentMedia'] as String?,
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      return PlayerStatusUpdate(
        playerId: player.id,
        status: PlayerStatus.offline,
        timestamp: DateTime.now(),
      );
    }
    return null;
  }

  // ==================== IScheduleSender ====================

  @override
  Future<bool> sendSchedule(Player player, Schedule schedule) async {
    try {
      final response = await http
          .post(
            Uri.parse('${_baseUrl(player)}/api/schedule'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(schedule.toJson()),
          )
          .timeout(_timeout);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // ==================== IMediaSender ====================

  @override
  Future<bool> sendMedia(
    Player player,
    MediaItem media,
    List<int> fileBytes,
  ) async {
    try {
      final uri = Uri.parse('${_baseUrl(player)}/api/media');
      final request = http.MultipartRequest('POST', uri);

      request.files.add(
        http.MultipartFile.fromBytes('file', fileBytes, filename: media.name),
      );

      request.fields['mediaData'] = jsonEncode(media.toJson());

      final streamedResponse = await request.send().timeout(_mediaTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> deleteMedia(Player player, String mediaId) async {
    try {
      final response = await http
          .delete(Uri.parse('${_baseUrl(player)}/api/media/$mediaId'))
          .timeout(_timeout);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ==================== IPlayerController ====================

  @override
  Future<bool> play(Player player, String mediaId) async {
    try {
      final response = await http
          .post(
            Uri.parse('${_baseUrl(player)}/api/play'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'mediaId': mediaId}),
          )
          .timeout(_timeout);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> stop(Player player) async {
    try {
      final response = await http
          .post(Uri.parse('${_baseUrl(player)}/api/stop'))
          .timeout(_timeout);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> reboot(Player player) async {
    try {
      final response = await http
          .post(Uri.parse('${_baseUrl(player)}/api/reboot'))
          .timeout(_timeout);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> sync(Player player) async {
    try {
      final response = await http
          .post(Uri.parse('${_baseUrl(player)}/api/sync'))
          .timeout(_timeout);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
