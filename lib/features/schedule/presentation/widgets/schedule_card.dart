// schedule_card.dart - Carte expandable + menu popup
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app_core_ui/domain/models/app_models.dart';
import '../providers/schedule_provider.dart';
import '../../../player/presentation/providers/player_provider.dart';
import 'schedule_media_item.dart';

class ScheduleCard extends ConsumerWidget {
  final Schedule schedule;

  const ScheduleCard({super.key, required this.schedule});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = schedule.isCurrentlyActive();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: isActive ? 4 : 1,
        color: isActive ? Colors.green.shade50 : null,
        child: ExpansionTile(
          leading: _buildStatusBadge(isActive),
          title: Text(
            schedule.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${_formatDateTime(schedule.startDate)} - ${_formatDateTime(schedule.endDate)}',
            style: const TextStyle(fontSize: 12),
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, ref, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Modifier'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'toggle',
                child: Row(
                  children: [
                    Icon(schedule.isActive ? Icons.pause : Icons.play_arrow),
                    const SizedBox(width: 8),
                    Text(schedule.isActive ? 'Désactiver' : 'Activer'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'duplicate',
                child: Row(
                  children: [
                    Icon(Icons.copy),
                    SizedBox(width: 8),
                    Text('Dupliquer'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Supprimer', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Player:', _getPlayerName(ref)),
                  _buildInfoRow('Récurrence:', _getRecurrenceText()),
                  _buildInfoRow(
                    'Médias:',
                    '${schedule.mediaItems.length} fichier(s)',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Médias programmés:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...schedule.mediaItems.map(
                    (media) => ScheduleMediaItem(scheduledMedia: media),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green : Colors.grey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'ACTIF' : 'INACTIF',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  String _getPlayerName(WidgetRef ref) {
    final player = ref
        .read(playerProviderRef)
        .players
        .firstWhere(
          (p) => p.id == schedule.playerId,
          orElse: () => Player(
            id: schedule.playerId,
            name: 'Player inconnu',
            ipAddress: '',
            lastSeen: DateTime.now(),
            createdAt: DateTime.now(),
          ),
        );
    return player.name;
  }

  String _getRecurrenceText() {
    switch (schedule.recurrence) {
      case RecurrencePattern.none:
        return 'Une fois';
      case RecurrencePattern.daily:
        return 'Tous les jours';
      case RecurrencePattern.weekdays:
        return 'Lun-Ven';
      case RecurrencePattern.weekends:
        return 'Sam-Dim';
      case RecurrencePattern.weekly:
        return 'Toutes les semaines';
    }
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'edit':
        // TODO: Navigate to edit schedule
        break;
      case 'toggle':
        final updated = schedule.copyWith(isActive: !schedule.isActive);
        ref.read(scheduleProviderRef).addSchedule(updated);
        break;
      case 'duplicate':
        _duplicateSchedule(context, ref);
        break;
      case 'delete':
        _showDeleteConfirmation(context, ref);
        break;
    }
  }

  void _duplicateSchedule(BuildContext context, WidgetRef ref) {
    final newSchedule = Schedule(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '${schedule.name} (copie)',
      playerId: schedule.playerId,
      startDate: schedule.startDate,
      endDate: schedule.endDate,
      recurrence: schedule.recurrence,
      mediaItems: schedule.mediaItems,
      isActive: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    ref.read(scheduleProviderRef).addSchedule(newSchedule);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Planification dupliquée')));
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer "${schedule.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(scheduleProviderRef).deleteSchedule(schedule.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
