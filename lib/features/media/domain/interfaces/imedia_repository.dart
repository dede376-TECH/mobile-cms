import '../models/media_item.dart';

/// Interface repository pour la gestion des médias
abstract class IMediaRepository {
  /// Sauvegarde un média
  Future<void> save(MediaItem media);
  
  /// Supprime un média par ID
  Future<void> delete(String id);
  
  /// Récupère un média par ID
  MediaItem? get(String id);
  
  /// Récupère tous les médias
  List<MediaItem> getAll();
}
