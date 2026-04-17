import '../models/player.dart';

/// Interface repository pour la gestion des players
/// Implémente le principe Open/Closed - on peut changer d'implémentation
/// (Hive, SQLite, Firebase) sans toucher au code métier
abstract class IPlayerRepository {
  /// Sauvegarde un player
  Future<void> save(Player player);
  
  /// Supprime un player par ID
  Future<void> delete(String id);
  
  /// Récupère un player par ID, null si non trouvé
  Player? get(String id);
  
  /// Récupère tous les players
  List<Player> getAll();
  
  /// Met à jour le statut d'un player
  Future<void> updateStatus(String playerId, PlayerStatus status);
}
