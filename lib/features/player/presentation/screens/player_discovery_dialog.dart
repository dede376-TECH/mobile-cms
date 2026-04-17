// player_discovery_dialog.dart - Scan LAN
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app_core_ui/domain/interfaces/icommunication_interfaces.dart';
import '../../../app_core_ui/domain/models/app_models.dart';
import '../providers/player_provider.dart';

class PlayerDiscoveryDialog extends ConsumerStatefulWidget {
  const PlayerDiscoveryDialog({super.key});

  @override
  ConsumerState<PlayerDiscoveryDialog> createState() =>
      _PlayerDiscoveryDialogState();
}

class _PlayerDiscoveryDialogState extends ConsumerState<PlayerDiscoveryDialog> {
  bool _isScanning = false;
  List<PlayerDiscoveryInfo> _discoveredPlayers = [];

  @override
  void initState() {
    super.initState();
    _startDiscovery();
  }

  Future<void> _startDiscovery() async {
    setState(() {
      _isScanning = true;
      _discoveredPlayers = [];
    });

    final discovered = await ref.read(playerProviderRef).discoverPlayers();

    setState(() {
      _discoveredPlayers = discovered;
      _isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Text('Découverte des Players'),
          const Spacer(),
          if (_isScanning)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _discoveredPlayers.isEmpty
            ? Center(
                child: _isScanning
                    ? const Text('Recherche des players sur le réseau...')
                    : const Text(
                        'Aucun player trouvé\nVérifiez que les players sont sur le même réseau',
                        textAlign: TextAlign.center,
                      ),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: _discoveredPlayers.length,
                itemBuilder: (context, index) {
                  final info = _discoveredPlayers[index];
                  return ListTile(
                    leading: const Icon(Icons.tv, color: Colors.green),
                    title: Text(info.name ?? 'Player inconnu'),
                    subtitle: Text('${info.ipAddress}:${info.port}'),
                    trailing: ElevatedButton(
                      onPressed: () => _addDiscoveredPlayer(info),
                      child: const Text('Ajouter'),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
        if (!_isScanning)
          ElevatedButton(
            onPressed: _startDiscovery,
            child: const Text('Relancer'),
          ),
      ],
    );
  }

  void _addDiscoveredPlayer(PlayerDiscoveryInfo info) {
    ref
        .read(playerProviderRef)
        .addPlayer(
          name: info.name ?? 'Player inconnu',
          ipAddress: info.ipAddress,
          port: info.port,
        );
    Navigator.pop(context); // Ferme le dialog après l'ajout
  }
}
