import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/player_provider.dart';
import '../widgets/player_card.dart';
import 'add_player_dialog.dart';
import 'player_discovery_dialog.dart';

class PlayersScreen extends ConsumerWidget {
  const PlayersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerProvider = ref.watch(playerProviderRef);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Players'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => playerProvider.checkAllPlayersStatus(),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showDiscoveryDialog(context),
          ),
        ],
      ),
      body: playerProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : playerProvider.error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    playerProvider.error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => playerProvider.clearError(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            )
          : playerProvider.players.isEmpty
          ? const Center(
              child: Text(
                'Aucun player enregistré\nAppuyez sur + pour ajouter un player',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: playerProvider.players.length,
              itemBuilder: (context, index) {
                final player = playerProvider.players[index];
                return PlayerCard(player: player);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPlayerDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddPlayerDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const AddPlayerDialog());
  }

  void _showDiscoveryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const PlayerDiscoveryDialog(),
    );
  }
}
