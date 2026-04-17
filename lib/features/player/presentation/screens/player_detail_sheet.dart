// player_detail_sheet.dart - Toutes les confirmations et détails
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app_core_ui/domain/models/app_models.dart';
import '../providers/player_provider.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../schedule/domain/models/schedule.dart'; // Import Schedule model

class PlayerDetailSheet extends ConsumerWidget {
  final Player player;

  const PlayerDetailSheet({super.key, required this.player});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerProvider = ref.watch(playerProviderRef);
    final schedules = ref
        .watch(scheduleProviderRef)
        .schedules; // Assuming scheduleProviderRef exists

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.25,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              _buildDragHandle(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      player.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      player.description ?? 'Aucune description',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Divider(),
                    _buildInfoRow(
                      context,
                      Icons.network_check,
                      'IP',
                      player.ipAddress,
                    ),
                    _buildInfoRow(
                      context,
                      Icons.settings_ethernet,
                      'Port',
                      player.port.toString(),
                    ),
                    _buildInfoRow(
                      context,
                      Icons.power_settings_new,
                      'Statut',
                      player.status.toString().split('.').last,
                    ),
                    _buildInfoRow(
                      context,
                      Icons.update,
                      'Dernière vue',
                      player.lastSeen.toLocal().toString().split('.').first,
                    ),
                    const Divider(),
                    _buildActions(context, ref, player, schedules),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDragHandle() {
    return Container(
      width: 40,
      height: 5,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).iconTheme.color),
          const SizedBox(width: 16),
          Text('$label: ', style: Theme.of(context).textTheme.titleMedium),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    WidgetRef ref,
    Player player,
    List<Schedule> schedules,
  ) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.refresh),
          title: const Text('Redémarrer le Player'),
          onTap: () async {
            Navigator.pop(context);
            await ref.read(playerProviderRef).rebootPlayer(player);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Player ${player.name} redémarré')),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.sync),
          title: const Text('Synchroniser la planification'),
          onTap: () {
            Navigator.pop(context);
            _showSyncScheduleDialog(context, ref, player, schedules);
          },
        ),
        ListTile(
          leading: const Icon(Icons.delete, color: Colors.red),
          title: const Text('Supprimer le Player'),
          onTap: () {
            Navigator.pop(context);
            _showDeleteConfirmationDialog(context, ref, player);
          },
        ),
      ],
    );
  }

  void _showSyncScheduleDialog(
    BuildContext context,
    WidgetRef ref,
    Player player,
    List<Schedule> schedules,
  ) {
    Schedule? selectedSchedule;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Synchroniser la planification'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Schedule>(
                  decoration: const InputDecoration(
                    labelText: 'Sélectionner une planification',
                  ),
                  initialValue: selectedSchedule,
                  items: schedules.map((schedule) {
                    return DropdownMenuItem(
                      value: schedule,
                      child: Text(schedule.name),
                    );
                  }).toList(),
                  onChanged: (schedule) {
                    setState(() {
                      selectedSchedule = schedule;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: selectedSchedule == null
                    ? null
                    : () async {
                        Navigator.pop(context);
                        await ref.read(playerProviderRef).syncPlayer(player, [
                          selectedSchedule!,
                        ]);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Planification ${selectedSchedule!.name} synchronisée avec ${player.name}',
                            ),
                          ),
                        );
                      },
                child: const Text('Synchroniser'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteConfirmationDialog(
    BuildContext context,
    WidgetRef ref,
    Player player,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le Player ?'),
        content: Text('Voulez-vous vraiment supprimer "${player.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(playerProviderRef).deletePlayer(player.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Player "${player.name}" supprimé')),
              );
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
