import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cms_local/core/network/interfaces/communication_interfaces.dart';
import '../../domain/models/schedule.dart';
import '../../domain/interfaces/ischedule_repository.dart';
import '../../../../core/di/injection_container.dart';

/// Provider pour la gestion des planifications
/// Respecte SRP : ne gère QUE les schedules
class ScheduleProvider extends ChangeNotifier {
  // Dependencies (injected via constructor - DIP)
  final IScheduleRepository _repository;

  // State
  List<Schedule> _schedules = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Schedule> get schedules => _schedules;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Constructor avec injection de dépendances
  ScheduleProvider({
    required IScheduleRepository repository,
    IScheduleSender? scheduleSender,
  }) : _repository = repository {
    _initialize();
  }

  Future<void> _initialize() async {
    await loadSchedules();
  }

  // ==================== CRUD Operations ====================

  Future<void> loadSchedules() async {
    _setLoading(true);
    try {
      _schedules = _repository.getAll();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur chargement schedules: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addSchedule(Schedule schedule) async {
    _setLoading(true);
    try {
      await _repository.save(schedule);
      _schedules = _repository.getAll();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur ajout schedule: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteSchedule(String scheduleId) async {
    _setLoading(true);
    try {
      await _repository.delete(scheduleId);
      _schedules.removeWhere((item) => item.id == scheduleId);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur suppression schedule: $e';
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

final scheduleProviderRef = ChangeNotifierProvider((ref) {
  return ScheduleProvider(repository: sl<IScheduleRepository>());
});
