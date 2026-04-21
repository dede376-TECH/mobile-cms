import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cms_local/features/player/domain/models/player.dart';
import 'package:cms_local/features/media/domain/models/media_item.dart';
import 'package:cms_local/features/schedule/domain/models/schedule.dart';
import 'package:cms_local/core/network/interfaces/communication_interfaces.dart';

class LanCommunicationService {
  static final LanCommunicationService _instance =
      LanCommunicationService._internal();
  factory LanCommunicationService() => _instance;
  LanCommunicationService._internal();

  final _playerStatusController =
      StreamController<PlayerStatusUpdate>.broadcast();
  Stream<PlayerStatusUpdate> get playerStatusStream =>
      _playerStatusController.stream;

  final Map<String, HttpClient> _clients = {};
  final Duration _timeout = const Duration(seconds: 5);

  Future<bool> checkPlayerAvailability(Player player) async {
    try {
      final response = await http
          .get(Uri.parse('${player.baseUrl}/api/health'))
          .timeout(_timeout);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<PlayerStatusUpdate?> getPlayerStatus(Player player) async {
    try {
      final response = await http
          .get(Uri.parse('${player.baseUrl}/api/status'))
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

  Future<bool> sendSchedule(Player player, Schedule schedule) async {
    try {
      final response = await http
          .post(
            Uri.parse('${player.baseUrl}/api/schedule'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(schedule.toJson()),
          )
          .timeout(_timeout);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> sendMedia(
    Player player,
    MediaItem media,
    List<int> fileBytes,
  ) async {
    try {
      final uri = Uri.parse('${player.baseUrl}/api/media');
      final request = http.MultipartRequest('POST', uri);

      request.files.add(
        http.MultipartFile.fromBytes('file', fileBytes, filename: media.name),
      );

      request.fields['mediaData'] = jsonEncode(media.toJson());

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteMediaFromPlayer(Player player, String mediaId) async {
    try {
      final response = await http
          .delete(Uri.parse('${player.baseUrl}/api/media/$mediaId'))
          .timeout(_timeout);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> syncPlayer(Player player) async {
    try {
      final response = await http
          .post(Uri.parse('${player.baseUrl}/api/sync'))
          .timeout(_timeout);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> playMedia(Player player, String mediaId) async {
    try {
      final response = await http
          .post(
            Uri.parse('${player.baseUrl}/api/play'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'mediaId': mediaId}),
          )
          .timeout(_timeout);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> stopPlayer(Player player) async {
    try {
      final response = await http
          .post(Uri.parse('${player.baseUrl}/api/stop'))
          .timeout(_timeout);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> rebootPlayer(Player player) async {
    try {
      final response = await http
          .post(Uri.parse('${player.baseUrl}/api/reboot'))
          .timeout(_timeout);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<PlayerDiscoveryInfo>> discoverPlayersOnNetwork() async {
    List<PlayerDiscoveryInfo> discoveredPlayers = [];

    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          final subnet = _getSubnet(addr.address);
          if (subnet != null) {
            final results = await _scanSubnet(subnet);
            discoveredPlayers.addAll(results);
          }
        }
      }
    } catch (e) {
      // Handle network interface listing error
    }

    return discoveredPlayers;
  }

  String? _getSubnet(String ipAddress) {
    try {
      final parts = ipAddress.split('.');
      if (parts.length == 4) {
        return '${parts[0]}.${parts[1]}.${parts[2]}';
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<List<PlayerDiscoveryInfo>> _scanSubnet(String subnet) async {
    final List<PlayerDiscoveryInfo> results = [];
    final List<Future<void>> futures = [];

    for (int i = 1; i < 255; i++) {
      final ip = '$subnet.$i';
      futures.add(
        _checkPlayerAtIp(ip).then((info) {
          if (info != null) {
            results.add(info);
          }
        }),
      );
    }

    await Future.wait(futures, eagerError: false);
    return results;
  }

  Future<PlayerDiscoveryInfo?> _checkPlayerAtIp(String ip) async {
    try {
      final response = await http
          .get(Uri.parse('http://$ip:8080/api/info'))
          .timeout(const Duration(milliseconds: 500));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PlayerDiscoveryInfo(
          id: data['id'] as String,
          name: data['name'] as String,
          ipAddress: ip,
          port: data['port'] as int? ?? 8080,
          version: data['version'] as String?,
        );
      }
    } catch (e) {
      // No player at this IP
    }
    return null;
  }

  void dispose() {
    _playerStatusController.close();
    for (final client in _clients.values) {
      client.close();
    }
    _clients.clear();
  }
}
