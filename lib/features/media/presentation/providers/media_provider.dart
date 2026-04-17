import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app_core_ui/domain/interfaces/app_interfaces.dart';
import '../../domain/models/media_item.dart';
import '../../../player/domain/models/player.dart';
import '../../../../core/di/injection_container.dart';
import '../../../app_core_ui/domain/interfaces/icommunication_interfaces.dart';

/// Provider pour la gestion des médias
/// Respecte SRP : ne gère QUE les médias
class MediaProvider extends ChangeNotifier {
  // Dependencies (injected via constructor - DIP)
  final IMediaRepository _repository;
  final IMediaSender? _mediaSender;

  // State
  List<MediaItem> _mediaItems = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<MediaItem> get mediaItems => _mediaItems;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Constructor avec injection de dépendances
  MediaProvider({
    required IMediaRepository repository,
    IMediaSender? mediaSender,
  }) : _repository = repository,
       _mediaSender = mediaSender {
    _initialize();
  }

  Future<void> _initialize() async {
    await loadMediaItems();
  }

  // ==================== CRUD Operations ====================

  Future<void> loadMediaItems() async {
    _setLoading(true);
    try {
      _mediaItems = _repository.getAll();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur chargement médias: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addMediaItem({
    required String name,
    required MediaType type,
    int duration = 10,
    TransitionType transition = TransitionType.fade,
    int transitionDuration = 500,
  }) async {
    _setLoading(true);
    try {
      FilePickerResult? result;

      if (type == MediaType.image) {
        result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );
      } else {
        result = await FilePicker.platform.pickFiles(
          type: FileType.video,
          allowMultiple: false,
        );
      }

      if (result != null && result.files.single.path != null) {
        final media = MediaItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          filePath: result.files.single.path!,
          type: type,
          duration: duration,
          transition: transition,
          transitionDuration: transitionDuration,
          createdAt: DateTime.now(),
        );

        await _repository.save(media);
        _mediaItems = _repository.getAll();
        _error = null;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Erreur ajout média: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteMediaItem(String mediaId) async {
    _setLoading(true);
    try {
      await _repository.delete(mediaId);
      _mediaItems.removeWhere((item) => item.id == mediaId);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur suppression média: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> uploadMediaToPlayer(MediaItem media, Player player) async {
    if (_mediaSender == null) {
      _error = 'Service d\'envoi de média non disponible.';
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      final file = File(media.filePath);
      if (!await file.exists()) {
        throw Exception('Fichier média introuvable: ${media.filePath}');
      }
      final bytes = await file.readAsBytes();
      final success = await _mediaSender!.sendMedia(player, media, bytes);

      if (!success) {
        throw Exception('Échec de l\'envoi du média au player.');
      }
      _error = null;
    } catch (e) {
      _error = 'Erreur envoi média au player: $e';
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

final mediaProviderRef = ChangeNotifierProvider((ref) {
  return MediaProvider(
    repository: sl<IMediaRepository>(),
    mediaSender: sl<IMediaSender>(),
  );
});
