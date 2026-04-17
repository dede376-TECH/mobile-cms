import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app_core_ui/domain/models/app_models.dart';
import '../providers/schedule_provider.dart';
import '../../../player/presentation/providers/player_provider.dart';
import '../../../media/presentation/providers/media_provider.dart';
import 'media_selection_dialog.dart';
import '../../../../core/utils/widgets/date_time_picker.dart';

class CreateScheduleScreen extends ConsumerStatefulWidget {
  const CreateScheduleScreen({super.key});

  @override
  ConsumerState<CreateScheduleScreen> createState() =>
      _CreateScheduleScreenState();
}

class _CreateScheduleScreenState extends ConsumerState<CreateScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String? _selectedPlayerId;
  DateTime? _startDate;
  DateTime? _endDate;
  RecurrencePattern _recurrence = RecurrencePattern.none;
  final List<ScheduledMedia> _selectedMedia = [];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final players = ref.watch(playerProviderRef).players;
    final mediaItems = ref.watch(mediaProviderRef).mediaItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle Planification'),
        actions: [
          TextButton(
            onPressed: _submit,
            child: const Text(
              'Enregistrer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Nom
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom de la planification',
                hintText: 'ex: Promotion Été 2024',
                prefixIcon: Icon(Icons.label),
              ),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Veuillez entrer un nom'
                  : null,
            ),
            const SizedBox(height: 16),

            // Player
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Player cible',
                prefixIcon: Icon(Icons.tv),
              ),
              initialValue: _selectedPlayerId,
              items: players
                  .map(
                    (p) => DropdownMenuItem(value: p.id, child: Text(p.name)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedPlayerId = value),
              validator: (value) =>
                  value == null ? 'Veuillez sélectionner un player' : null,
            ),
            const SizedBox(height: 16),

            // Dates
            Row(
              children: [
                Expanded(
                  child: AppDateTimePicker(
                    label: 'Début',
                    value: _startDate,
                    onChanged: (date) => setState(() => _startDate = date),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppDateTimePicker(
                    label: 'Fin',
                    value: _endDate,
                    onChanged: (date) => setState(() => _endDate = date),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Récurrence
            DropdownButtonFormField<RecurrencePattern>(
              decoration: const InputDecoration(
                labelText: 'Récurrence',
                prefixIcon: Icon(Icons.repeat),
              ),
              initialValue: _recurrence,
              items: RecurrencePattern.values
                  .map((r) => DropdownMenuItem(value: r, child: Text(r.name)))
                  .toList(),
              onChanged: (value) => setState(() => _recurrence = value!),
            ),
            const SizedBox(height: 16),

            // Médias
            ListTile(
              title: const Text('Médias de la planification'),
              trailing: const Icon(Icons.add),
              onTap: () async {
                MediaSelectionDialog.show(
                  context,
                  mediaItems: mediaItems,
                  selectedMedia: _selectedMedia,
                  onChanged: (result) {
                    setState(() {
                      _selectedMedia
                        ..clear()
                        ..addAll(result);
                    });
                  },
                );
              },
            ),
            if (_selectedMedia.isNotEmpty)
              ..._selectedMedia.map((sm) {
                final mediaItem = mediaItems.firstWhere(
                  (m) => m.id == sm.mediaId,
                );
                return ListTile(
                  leading: mediaItem.type == MediaType.image
                      ? const Icon(Icons.image)
                      : const Icon(Icons.videocam),
                  title: Text(mediaItem.name),
                  subtitle: Text('Ordre: ${sm.order}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _selectedMedia.remove(sm);
                      });
                    },
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedMedia.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Veuillez ajouter au moins un média à la planification',
            ),
          ),
        );
        return;
      }

      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner une date de début et de fin'),
          ),
        );
        return;
      }

      final newSchedule = Schedule(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        playerId: _selectedPlayerId!,
        startDate: _startDate!,
        endDate: _endDate!,
        recurrence: _recurrence,
        mediaItems: _selectedMedia,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      ref.read(scheduleProviderRef).addSchedule(newSchedule);
      Navigator.pop(context);
    }
  }
}
