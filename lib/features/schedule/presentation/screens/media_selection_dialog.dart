// media_selection_dialog.dart - Sélection et édition des médias
import 'package:flutter/material.dart';
import '../../../media/domain/models/media_item.dart';
import '../../domain/models/schedule.dart';

class MediaSelectionDialog {
  /// Ouvre le dialog de sélection/désélection des médias.
  static void show(
    BuildContext context, {
    required List<MediaItem> mediaItems,
    required List<ScheduledMedia> selectedMedia,
    required ValueChanged<List<ScheduledMedia>> onChanged,
  }) {
    showDialog(
      context: context,
      builder: (context) => _MediaSelectionDialogWidget(
        mediaItems: mediaItems,
        selectedMedia: List.from(selectedMedia),
        onChanged: onChanged,
      ),
    );
  }

  /// Ouvre le dialog d'édition des paramètres d'un média (durée, transition).
  static void editSettings(
    BuildContext context, {
    required ScheduledMedia media,
    required MediaItem mediaItem,
    required ValueChanged<ScheduledMedia> onSaved,
  }) {
    showDialog(
      context: context,
      builder: (context) => _MediaSettingsDialog(
        media: media,
        mediaItem: mediaItem,
        onSaved: onSaved,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget interne : sélection des médias
// ---------------------------------------------------------------------------

class _MediaSelectionDialogWidget extends StatefulWidget {
  final List<MediaItem> mediaItems;
  final List<ScheduledMedia> selectedMedia;
  final ValueChanged<List<ScheduledMedia>> onChanged;

  const _MediaSelectionDialogWidget({
    required this.mediaItems,
    required this.selectedMedia,
    required this.onChanged,
  });

  @override
  State<_MediaSelectionDialogWidget> createState() =>
      _MediaSelectionDialogWidgetState();
}

class _MediaSelectionDialogWidgetState
    extends State<_MediaSelectionDialogWidget> {
  late List<ScheduledMedia> _current;

  @override
  void initState() {
    super.initState();
    _current = List.from(widget.selectedMedia);
  }

  bool _isSelected(String mediaId) => _current.any((m) => m.mediaId == mediaId);

  void _toggle(String mediaId, bool? checked) {
    setState(() {
      if (checked == true) {
        _current.add(
          ScheduledMedia(
            mediaId: mediaId,
            order: _current.length,
            duration: 10,
            transition: TransitionType.fade,
            transitionDuration: 500,
          ),
        );
      } else {
        _current.removeWhere((m) => m.mediaId == mediaId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sélectionner des médias'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.mediaItems.length,
          itemBuilder: (context, index) {
            final media = widget.mediaItems[index];
            return CheckboxListTile(
              title: Text(media.name),
              subtitle: Text(media.type == MediaType.image ? 'Image' : 'Vidéo'),
              secondary: Icon(
                media.type == MediaType.image ? Icons.image : Icons.videocam,
              ),
              value: _isSelected(media.id),
              onChanged: (checked) => _toggle(media.id, checked),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onChanged(_current);
            Navigator.pop(context);
          },
          child: const Text('Terminer'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Widget interne : paramètres d'un média
// ---------------------------------------------------------------------------

class _MediaSettingsDialog extends StatefulWidget {
  final ScheduledMedia media;
  final MediaItem mediaItem;
  final ValueChanged<ScheduledMedia> onSaved;

  const _MediaSettingsDialog({
    required this.media,
    required this.mediaItem,
    required this.onSaved,
  });

  @override
  State<_MediaSettingsDialog> createState() => _MediaSettingsDialogState();
}

class _MediaSettingsDialogState extends State<_MediaSettingsDialog> {
  late int _duration;
  late TransitionType _transition;

  @override
  void initState() {
    super.initState();
    _duration = widget.media.duration;
    _transition = widget.media.transition;
  }

  String _transitionLabel(TransitionType t) {
    switch (t) {
      case TransitionType.none:
        return 'Aucune';
      case TransitionType.fade:
        return 'Fondu';
      case TransitionType.slide:
        return 'Glisser';
      case TransitionType.zoom:
        return 'Zoom';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Paramètres: ${widget.mediaItem.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            initialValue: _duration.toString(),
            decoration: const InputDecoration(labelText: 'Durée (secondes)'),
            keyboardType: TextInputType.number,
            onChanged: (v) => _duration = int.tryParse(v) ?? 10,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<TransitionType>(
            decoration: const InputDecoration(labelText: 'Transition'),
            initialValue: _transition,
            items: TransitionType.values
                .map(
                  (t) => DropdownMenuItem(
                    value: t,
                    child: Text(_transitionLabel(t)),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _transition = v);
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
          onPressed: () {
            widget.onSaved(
              widget.media.copyWith(
                duration: _duration,
                transition: _transition,
              ),
            );
            Navigator.pop(context);
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
