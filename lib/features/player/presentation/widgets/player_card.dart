// player_card.dart - Slidable + ListTile
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/player.dart';
import '../../../schedule/domain/models/schedule.dart';
import '../../../../core/providers/global_providers.dart';
import 'player_status_indicator.dart';
import '../screens/player_detail_sheet.dart';

class PlayerCard extends ConsumerWidget {
  final Player player;

  const PlayerCard({super.key, required this.player});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedules = ref.watch(scheduleProviderRef).schedules;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => _showPlayMediaDialog(context, ref, player),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              icon: Icons.play_arrow,
              label: 'Play',
            ),
            SlidableAction(
              onPressed: (_) =>
                  _showSyncScheduleDialog(context, ref, player, schedules),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: Icons.sync,
              label: 'Sync',
            ),
            SlidableAction(
              onPressed: (_) => _showRebootConfirmation(context, ref, player),
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              icon: Icons.restart_alt,
              label: 'Redémarrer',
            ),
            SlidableAction(
              onPressed: (_) => _showDeleteConfirmation(context, ref, player),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Supprimer',
            ),
          ],
        ),
        child: Card(
          elevation: 2,
          child: ListTile(
            leading: PlayerStatusIndicator(status: player.status),
            title: Text(
              player.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${player.ipAddress}:${player.port}'),
                if (player.description != null)
                  Text(
                    player.description!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  'Dernière connexion: ${_formatDate(player.lastSeen)}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => PlayerDetailSheet(player: player),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'à l\'instant';
    if (diff.inHours < 1) return 'il y a ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inDays}j';
  }

  void _showPlayMediaDialog(
    BuildContext context,
    WidgetRef ref,
    Player player,
  ) {
    final mediaItems = ref.watch(mediaProviderRef).mediaItems;
    String? selectedMediaId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Lire un média sur ${player.name}'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (mediaItems.isEmpty)
                    const Text('Aucun média disponible')
                  else
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Sélectionner un média',
                      ),
                      initialValue: selectedMediaId,
                      items: mediaItems.map((media) {
                        return DropdownMenuItem(
                          value: media.id,
                          child: Text(media.name),
                        );
                      }).toList(),
                      onChanged: (mediaId) {
                        setState(() {
                          selectedMediaId = mediaId;
                        });
                      },
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: selectedMediaId == null || mediaItems.isEmpty
                    ? null
                    : () async {
                        Navigator.pop(context);
                        await ref
                            .read(playerProviderRef)
                            .playMedia(player, selectedMediaId!);
                        final mediaName = mediaItems
                            .firstWhere((m) => m.id == selectedMediaId)
                            .name;
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Lecture de "$mediaName" sur ${player.name}',
                              ),
                            ),
                          );
                        }
                      },
                child: const Text('Lire'),
              ),
            ],
          );
        },
      ),
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
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Planification ${selectedSchedule!.name} synchronisée avec ${player.name}',
                              ),
                            ),
                          );
                        }
                      },
                child: const Text('Synchroniser'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRebootConfirmation(
    BuildContext context,
    WidgetRef ref,
    Player player,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Redémarrer le Player ?'),
        content: Text('Voulez-vous redémarrer "${player.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(playerProviderRef).rebootPlayer(player);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Player "${player.name}" redémarré')),
              );
            },
            child: const Text('Redémarrer'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
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
