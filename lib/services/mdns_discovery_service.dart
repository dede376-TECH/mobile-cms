import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:cms_local/core/network/interfaces/communication_interfaces.dart';

/// Service de découverte de players via mDNS (multicast DNS)
/// Avantages par rapport au scan subnet :
/// - Plus rapide (pas besoin de scanner 254 IPs)
/// - Plus fiable (découverte par service, pas par port ouvert)
/// - Fonctionne sur des réseaux segmentés
/// - Respecte le principe ISP : séparation de la découverte du reste
class MdnsDiscoveryService implements IPlayerDiscovery {
  static const String _serviceType = '_cms-player._tcp';

  final MDnsClient _client = MDnsClient();
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _client.start();
    _initialized = true;
  }

  @override
  Future<List<PlayerDiscoveryInfo>> discoverPlayers() async {
    await _ensureInitialized();

    final List<PlayerDiscoveryInfo> discoveredPlayers = [];

    try {
      // Recherche des instances de service CMS Player
      await for (final PtrResourceRecord ptr
          in _client.lookup<PtrResourceRecord>(
            ResourceRecordQuery.serverPointer(_serviceType),
          )) {
        // Pour chaque service trouvé, récupère les détails (SRV et TXT)
        final serviceName = ptr.domainName;

        // Récupère l'enregistrement SRV (hostname et port)
        // Note: ResourceRecordQuery.serviceTarget n'existe pas dans multicast_dns
        // On utilise une requête brute avec le type SRV (33)
        String? hostName;
        int port = 8080; // Port par défaut

        try {
          await for (final SrvResourceRecord srv
              in _client.lookup<SrvResourceRecord>(
                ResourceRecordQuery.serverPointer(serviceName),
              )) {
            hostName = srv.target;
            port = srv.port;
            break; // Prend le premier SRV
          }
        } catch (e) {
          // Si SRV échoue, essaie d'utiliser le serviceName comme hostname
          hostName = serviceName.replaceAll('.local', '');
        }

        if (hostName == null) continue;

        // Résout l'IP à partir du hostname
        final ipAddress = await _resolveIpAddress(hostName);

        if (ipAddress != null) {
          // Récupère les métadonnées TXT (nom, version, ID)
          String? playerName;
          String? playerId;
          String? version;

          try {
            await for (final TxtResourceRecord txt
                in _client.lookup<TxtResourceRecord>(
                  ResourceRecordQuery.text(serviceName),
                )) {
              final text = txt.text;
              // Parse les champs TXT (format: key=value)
              for (final entry in text.split(',')) {
                final parts = entry.split('=');
                if (parts.length == 2) {
                  final key = parts[0].trim();
                  final value = parts[1].trim();
                  switch (key) {
                    case 'name':
                      playerName = value;
                      break;
                    case 'id':
                      playerId = value;
                      break;
                    case 'version':
                      version = value;
                      break;
                  }
                }
              }
              break; // On prend le premier enregistrement TXT
            }
          } catch (e) {
            // Ignore erreur TXT
          }

          // Si pas de nom dans TXT, utilise le hostname
          playerName ??= hostName;
          playerId ??= '${ipAddress}_$port';

          discoveredPlayers.add(
            PlayerDiscoveryInfo(
              id: playerId,
              name: playerName,
              ipAddress: ipAddress,
              port: port,
              version: version,
            ),
          );
        }
      }
    } catch (e) {
      // En cas d'erreur mDNS, retourne liste vide
      // Le caller peut fallback sur scan subnet si nécessaire
    }

    return discoveredPlayers;
  }

  /// Résout une adresse IP à partir d'un hostname via mDNS
  Future<String?> _resolveIpAddress(String hostName) async {
    try {
      await for (final IPAddressResourceRecord ip
          in _client.lookup<IPAddressResourceRecord>(
            ResourceRecordQuery.addressIPv4(hostName),
          )) {
        return ip.address.address;
      }
    } catch (e) {
      // Si échec IPv4, essaye IPv6
      try {
        await for (final IPAddressResourceRecord ip
            in _client.lookup<IPAddressResourceRecord>(
              ResourceRecordQuery.addressIPv6(hostName),
            )) {
          return ip.address.address;
        }
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Arrête le client mDNS
  Future<void> dispose() async {
    _client.stop();
    _initialized = false;
  }
}

/// Service de fallback utilisant le scan subnet (ancienne méthode)
/// Utilisé si mDNS n'est pas disponible ou ne trouve rien
class SubnetDiscoveryService implements IPlayerDiscovery {
  final int _port;
  final Duration _timeout;

  SubnetDiscoveryService({int? port, Duration? timeout})
    : _port = port ?? 8080,
      _timeout = timeout ?? const Duration(milliseconds: 500);

  @override
  Future<List<PlayerDiscoveryInfo>> discoverPlayers() async {
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
      final client = HttpClient();
      client.connectionTimeout = _timeout;

      final request = await client.getUrl(
        Uri.parse('http://$ip:$_port/api/info'),
      );
      final response = await request.close().timeout(_timeout);

      if (response.statusCode == 200) {
        final body = await response.transform(const Utf8Decoder()).join();
        final data = jsonDecode(body);

        client.close();

        return PlayerDiscoveryInfo(
          id: data['id'] as String,
          name: data['name'] as String?,
          ipAddress: ip,
          port: data['port'] as int? ?? _port,
          version: data['version'] as String?,
        );
      }

      client.close();
    } catch (e) {
      // No player at this IP
    }
    return null;
  }
}
