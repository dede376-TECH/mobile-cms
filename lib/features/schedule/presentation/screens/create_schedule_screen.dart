import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/global_providers.dart';
import '../../domain/models/schedule.dart';
import '../../../media/domain/models/media_item.dart';
import '../../../player/domain/models/player.dart';

class CreateScheduleScreen extends ConsumerStatefulWidget {
  final Player? preselectedPlayer;

  const CreateScheduleScreen({super.key, this.preselectedPlayer});

  @override
  ConsumerState<CreateScheduleScreen> createState() =>
      _CreateScheduleScreenState();
}

class _CreateScheduleScreenState extends ConsumerState<CreateScheduleScreen> {
  int _currentStep = 0;

  // Step 1: Informations générales
  final _nameController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  RecurrencePattern _recurrence = RecurrencePattern.none;
  int _occurrenceCount = 1;
  final Set<int> _selectedWeekDays = {};

  // Step 2: Sélection des appareils
  bool _isDeviceMode = true;
  final Set<String> _selectedPlayerIds = {};

  // Step 3: Médias
  final List<ScheduledMediaItem> _scheduledMediaItems = [];

  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedPlayer != null) {
      _selectedPlayerIds.add(widget.preselectedPlayer!.id);
      _isDeviceMode = true;
    }
  }

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
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // Header avec handle bar
            _buildHeader(),

            // Stepper
            _buildStepper(),

            // Messages inline
            if (_errorMessage != null)
              _buildAlertMessage(_errorMessage!, Colors.red),
            if (_successMessage != null)
              _buildAlertMessage(_successMessage!, Colors.green),

            // Contenu de l'étape
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildStepContent(players, mediaItems),
              ),
            ),

            // Navigation
            _buildNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Nouvelle Planification',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (widget.preselectedPlayer != null)
            Text(
              'Pour: ${widget.preselectedPlayer!.name}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    final steps = ['Infos', 'Appareils', 'Médias'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            final stepIndex = index ~/ 2;
            final isCompleted = _currentStep > stepIndex;
            return Container(
              width: 40,
              height: 2,
              color: isCompleted ? Colors.deepPurple : Colors.grey[300],
            );
          }

          final stepIndex = index ~/ 2;
          final isActive = _currentStep == stepIndex;
          final isCompleted = _currentStep > stepIndex;

          return Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted || isActive
                  ? Colors.deepPurple
                  : Colors.grey[300],
              border: Border.all(
                color: isActive ? Colors.deepPurple : Colors.transparent,
                width: 2,
              ),
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : Text(
                      '${stepIndex + 1}',
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAlertMessage(String message, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: color, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(List<Player> players, List<MediaItem> mediaItems) {
    switch (_currentStep) {
      case 0:
        return _buildStep1Content();
      case 1:
        return _buildStep2Content(players);
      case 2:
        return _buildStep3Content(mediaItems);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1Content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nom
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Nom de la planification',
            hintText: 'ex: Promotion Été 2024',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.label_outline),
          ),
        ),
        const SizedBox(height: 16),

        // Dates
        Row(
          children: [
            Expanded(
              child: _buildDatePicker(
                label: 'Date début',
                value: _startDate,
                onChanged: (date) => setState(() => _startDate = date),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDatePicker(
                label: 'Date fin',
                value: _endDate,
                onChanged: (date) => setState(() => _endDate = date),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Heures
        Row(
          children: [
            Expanded(
              child: _buildTimePicker(
                label: 'Heure début',
                value: _startTime,
                onChanged: (time) => setState(() => _startTime = time),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTimePicker(
                label: 'Heure fin',
                value: _endTime,
                onChanged: (time) => setState(() => _endTime = time),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Récurrence
        Text(
          'Récurrence',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildRecurrencePill('ONCE', RecurrencePattern.none),
            _buildRecurrencePill('DAILY', RecurrencePattern.daily),
            _buildRecurrencePill('WEEKLY', RecurrencePattern.weekly),
            _buildRecurrencePill('WEEKDAYS', RecurrencePattern.weekdays),
            _buildRecurrencePill('WEEKENDS', RecurrencePattern.weekends),
          ],
        ),
        const SizedBox(height: 16),

        // Nombre d'occurrences
        if (_recurrence != RecurrencePattern.none) _buildOccurrenceCounter(),

        // Jours de la semaine
        if (_recurrence == RecurrencePattern.weekly) _buildWeekDaySelector(),
      ],
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime> onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
        );
        if (date != null) onChanged(date);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  value != null
                      ? '${value.day}/${value.month}/${value.year}'
                      : 'Sélectionner',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker({
    required String label,
    required TimeOfDay value,
    required ValueChanged<TimeOfDay> onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final time = await showTimePicker(context: context, initialTime: value);
        if (time != null) onChanged(time);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurrencePill(String label, RecurrencePattern pattern) {
    final isSelected = _recurrence == pattern;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _recurrence = pattern),
      selectedColor: Colors.deepPurple,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[700],
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.deepPurple : Colors.grey[300]!,
        ),
      ),
    );
  }

  Widget _buildOccurrenceCounter() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            'Nombre d\'occurrences',
            style: TextStyle(color: Colors.grey[700]),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: _occurrenceCount > 1
                ? () => setState(() => _occurrenceCount--)
                : null,
          ),
          Text(
            '$_occurrenceCount',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: Colors.deepPurple,
            ),
            onPressed: () => setState(() => _occurrenceCount++),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDaySelector() {
    final days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Jours de la semaine',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: List.generate(7, (index) {
              final isSelected = _selectedWeekDays.contains(index + 1);
              return ChoiceChip(
                label: Text(days[index]),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    if (isSelected) {
                      _selectedWeekDays.remove(index + 1);
                    } else {
                      _selectedWeekDays.add(index + 1);
                    }
                  });
                },
                selectedColor: Colors.deepPurple,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Content(List<Player> players) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle Appareils / Groupes
        if (widget.preselectedPlayer == null)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isDeviceMode = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isDeviceMode
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _isDeviceMode
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          'Appareils',
                          style: TextStyle(
                            fontWeight: _isDeviceMode
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: _isDeviceMode
                                ? Colors.deepPurple
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isDeviceMode = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isDeviceMode
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: !_isDeviceMode
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          'Groupes',
                          style: TextStyle(
                            fontWeight: !_isDeviceMode
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: !_isDeviceMode
                                ? Colors.deepPurple
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Mode appareil fixé
        if (widget.preselectedPlayer != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.tv, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appareil sélectionné',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.preselectedPlayer!.name,
                        style: TextStyle(color: Colors.blue[600]),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.lock, color: Colors.blue[300], size: 20),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // Grille de players
        if (players.isEmpty)
          Center(
            child: Column(
              children: [
                Icon(Icons.tv_off, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'Aucun appareil disponible',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              final isSelected =
                  _selectedPlayerIds.contains(player.id) ||
                  (widget.preselectedPlayer?.id == player.id);

              return InkWell(
                onTap: widget.preselectedPlayer != null
                    ? null
                    : () {
                        setState(() {
                          if (isSelected) {
                            _selectedPlayerIds.remove(player.id);
                          } else {
                            _selectedPlayerIds.add(player.id);
                          }
                        });
                      },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.deepPurple : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.deepPurple : Colors.grey[300]!,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.tv,
                              size: 32,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey[600],
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                player.name,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[800],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              color: Colors.deepPurple,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildStep3Content(List<MediaItem> mediaItems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // État vide ou liste
        if (_scheduledMediaItems.isEmpty)
          _buildEmptyMediaState()
        else
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = _scheduledMediaItems.removeAt(oldIndex);
                _scheduledMediaItems.insert(newIndex, item);
                // Mettre à jour les ordres
                for (var i = 0; i < _scheduledMediaItems.length; i++) {
                  _scheduledMediaItems[i] = _scheduledMediaItems[i].copyWith(
                    order: i + 1,
                  );
                }
              });
            },
            children: _scheduledMediaItems.map((item) {
              final mediaItem = mediaItems.firstWhere(
                (m) => m.id == item.mediaId,
                orElse: () => MediaItem(
                  id: item.mediaId,
                  name: 'Média inconnu',
                  filePath: '',
                  type: MediaType.image,
                  createdAt: DateTime.now(),
                ),
              );
              return _buildMediaItemCard(item, mediaItem, mediaItems);
            }).toList(),
          ),

        const SizedBox(height: 16),

        // Bouton Ajouter
        Center(
          child: OutlinedButton.icon(
            onPressed: () => _showMediaSelector(mediaItems),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un média'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyMediaState() {
    return Center(
      child: InkWell(
        onTap: () => _showMediaSelector(ref.read(mediaProviderRef).mediaItems),
        child: Container(
          width: 200,
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey[400]!,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[50],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate,
                size: 40,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                'Ajouter un média',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaItemCard(
    ScheduledMediaItem item,
    MediaItem mediaItem,
    List<MediaItem> allMediaItems,
  ) {
    return Card(
      key: ValueKey(item.mediaId),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // Header avec numéro et actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#${item.order}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Icon(Icons.drag_handle, color: Colors.grey),
                const Spacer(),
                // Flèche haut
                IconButton(
                  icon: const Icon(Icons.arrow_upward, size: 18),
                  onPressed: item.order > 1
                      ? () => _moveMediaItem(item.order - 1, true)
                      : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                // Flèche bas
                IconButton(
                  icon: const Icon(Icons.arrow_downward, size: 18),
                  onPressed: item.order < _scheduledMediaItems.length
                      ? () => _moveMediaItem(item.order - 1, false)
                      : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                // Supprimer
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.red,
                  ),
                  onPressed: () => _removeMediaItem(item.mediaId),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Contenu
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Miniature
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: mediaItem.type == MediaType.image
                        ? Image.file(
                            File(mediaItem.filePath),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.image),
                          )
                        : const Icon(Icons.videocam, size: 30),
                  ),
                ),
                const SizedBox(width: 12),

                // Nom
                Expanded(
                  child: Text(
                    mediaItem.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Durée et Transition
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
            child: Row(
              children: [
                // Durée
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    initialValue: item.duration.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Durée (s)',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final duration = int.tryParse(value) ?? 10;
                      _updateMediaItemDuration(item.mediaId, duration);
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // Transition
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<TransitionType>(
                    value: item.transition,
                    decoration: const InputDecoration(
                      labelText: 'Transition',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                    items: TransitionType.values.map((t) {
                      return DropdownMenuItem(
                        value: t,
                        child: Text(
                          _getTransitionLabel(t),
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _updateMediaItemTransition(item.mediaId, value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _moveMediaItem(int index, bool up) {
    setState(() {
      final newIndex = up ? index - 1 : index + 1;
      final item = _scheduledMediaItems.removeAt(index);
      _scheduledMediaItems.insert(newIndex, item);
      for (var i = 0; i < _scheduledMediaItems.length; i++) {
        _scheduledMediaItems[i] = _scheduledMediaItems[i].copyWith(
          order: i + 1,
        );
      }
    });
  }

  void _removeMediaItem(String mediaId) {
    setState(() {
      _scheduledMediaItems.removeWhere((item) => item.mediaId == mediaId);
      for (var i = 0; i < _scheduledMediaItems.length; i++) {
        _scheduledMediaItems[i] = _scheduledMediaItems[i].copyWith(
          order: i + 1,
        );
      }
    });
  }

  void _updateMediaItemDuration(String mediaId, int duration) {
    setState(() {
      final index = _scheduledMediaItems.indexWhere(
        (item) => item.mediaId == mediaId,
      );
      if (index != -1) {
        _scheduledMediaItems[index] = _scheduledMediaItems[index].copyWith(
          duration: duration,
        );
      }
    });
  }

  void _updateMediaItemTransition(String mediaId, TransitionType transition) {
    setState(() {
      final index = _scheduledMediaItems.indexWhere(
        (item) => item.mediaId == mediaId,
      );
      if (index != -1) {
        _scheduledMediaItems[index] = _scheduledMediaItems[index].copyWith(
          transition: transition,
        );
      }
    });
  }

  String _getTransitionLabel(TransitionType type) {
    switch (type) {
      case TransitionType.none:
        return 'Aucune';
      case TransitionType.fade:
        return 'Fondu';
      case TransitionType.slide:
        return 'Glissière';
      case TransitionType.zoom:
        return 'Zoom';
    }
  }

  void _showMediaSelector(List<MediaItem> mediaItems) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Sélectionner un média',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.9,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: mediaItems.length,
                    itemBuilder: (context, index) {
                      final media = mediaItems[index];
                      final isAlreadySelected = _scheduledMediaItems.any(
                        (item) => item.mediaId == media.id,
                      );

                      return InkWell(
                        onTap: isAlreadySelected
                            ? null
                            : () {
                                setState(() {
                                  _scheduledMediaItems.add(
                                    ScheduledMediaItem(
                                      mediaId: media.id,
                                      order: _scheduledMediaItems.length + 1,
                                      duration: media.type == MediaType.image
                                          ? 10
                                          : 30,
                                      transition: TransitionType.fade,
                                    ),
                                  );
                                });
                                Navigator.pop(context);
                              },
                        child: Opacity(
                          opacity: isAlreadySelected ? 0.5 : 1.0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                              border: isAlreadySelected
                                  ? Border.all(color: Colors.green)
                                  : null,
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12),
                                    ),
                                    child: media.type == MediaType.image
                                        ? Image.file(
                                            File(media.filePath),
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                          )
                                        : Container(
                                            color: Colors.grey[800],
                                            child: const Center(
                                              child: Icon(
                                                Icons.videocam,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    media.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                if (isAlreadySelected)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Déjà ajouté',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bouton Annuler (ligne du haut)
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text('Annuler la planification'),
              ),
            ),
            const SizedBox(height: 8),
            // Navigation Précédent/Suivant
            Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _currentStep--;
                          _errorMessage = null;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Précédent'),
                    ),
                  )
                else
                  const Expanded(child: SizedBox()),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _currentStep == 2 ? _createSchedule : _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(_currentStep == 2 ? 'Créer' : 'Suivant'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _nextStep() {
    // Validation
    if (_currentStep == 0) {
      if (_nameController.text.trim().isEmpty) {
        setState(() => _errorMessage = 'Veuillez entrer un nom');
        return;
      }
      if (_startDate == null || _endDate == null) {
        setState(() => _errorMessage = 'Veuillez sélectionner les dates');
        return;
      }
    }

    if (_currentStep == 1) {
      final hasSelection =
          widget.preselectedPlayer != null || _selectedPlayerIds.isNotEmpty;
      if (!hasSelection) {
        setState(
          () => _errorMessage = 'Veuillez sélectionner au moins un appareil',
        );
        return;
      }
    }

    setState(() {
      _currentStep++;
      _errorMessage = null;
      _successMessage = null;
    });
  }

  void _createSchedule() {
    if (_scheduledMediaItems.isEmpty) {
      setState(() => _errorMessage = 'Veuillez ajouter au moins un média');
      return;
    }

    final targetPlayerIds = widget.preselectedPlayer != null
        ? [widget.preselectedPlayer!.id]
        : _selectedPlayerIds.toList();

    for (final playerId in targetPlayerIds) {
      final schedule = Schedule(
        id: DateTime.now().millisecondsSinceEpoch.toString() + '_$playerId',
        name: _nameController.text.trim(),
        playerId: playerId,
        startDate: _startDate!,
        endDate: _endDate!,
        recurrence: _recurrence,
        mediaItems: _scheduledMediaItems
            .map(
              (item) => ScheduledMedia(
                mediaId: item.mediaId,
                order: item.order,
                duration: item.duration,
                transition: item.transition,
                transitionDuration: 500,
              ),
            )
            .toList(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      ref.read(scheduleProviderRef).addSchedule(schedule);
    }

    setState(() {
      _successMessage = 'Planification créée avec succès!';
    });

    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pop(context);
    });
  }
}

// Classe interne pour gérer les médias dans le step 3
class ScheduledMediaItem {
  final String mediaId;
  final int order;
  final int duration;
  final TransitionType transition;

  ScheduledMediaItem({
    required this.mediaId,
    required this.order,
    required this.duration,
    required this.transition,
  });

  ScheduledMediaItem copyWith({
    String? mediaId,
    int? order,
    int? duration,
    TransitionType? transition,
  }) {
    return ScheduledMediaItem(
      mediaId: mediaId ?? this.mediaId,
      order: order ?? this.order,
      duration: duration ?? this.duration,
      transition: transition ?? this.transition,
    );
  }
}
