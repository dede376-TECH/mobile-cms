import '../models/schedule.dart';

/// Interface repository pour la gestion des planifications
abstract class IScheduleRepository {
  /// Sauvegarde une planification
  Future<void> save(Schedule schedule);
  
  /// Supprime une planification par ID
  Future<void> delete(String id);
  
  /// Récupère une planification par ID
  Schedule? get(String id);
  
  /// Récupère toutes les planifications
  List<Schedule> getAll();
  
  /// Récupère les planifications pour un player spécifique
  List<Schedule> getByPlayerId(String playerId);
  
  /// Récupère les planifications actives pour un player
  List<Schedule> getActiveByPlayerId(String playerId);
}
