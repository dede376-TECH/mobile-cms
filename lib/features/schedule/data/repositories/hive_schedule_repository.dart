import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/interfaces/ischedule_repository.dart';
import '../../domain/models/schedule.dart';

/// Implémentation Hive du repository des planifications
class HiveScheduleRepository implements IScheduleRepository {
  Box<Schedule>? _box;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ScheduleAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(RecurrencePatternAdapter());
    }
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(ScheduledMediaAdapter());
    }

    _box ??= await Hive.openBox<Schedule>('schedules');
    _initialized = true;
  }

  @override
  Future<void> save(Schedule schedule) async {
    await _ensureInitialized();
    await _box!.put(schedule.id, schedule);
  }

  @override
  Future<void> delete(String id) async {
    await _ensureInitialized();
    await _box!.delete(id);
  }

  @override
  Schedule? get(String id) {
    if (!_initialized) return null;
    return _box?.get(id);
  }

  @override
  List<Schedule> getAll() {
    if (!_initialized) return [];
    return _box?.values.toList() ?? [];
  }

  @override
  List<Schedule> getByPlayerId(String playerId) {
    if (!_initialized) return [];
    return _box?.values.where((s) => s.playerId == playerId).toList() ?? [];
  }

  @override
  List<Schedule> getActiveByPlayerId(String playerId) {
    if (!_initialized) return [];
    return _box?.values
            .where((s) => s.playerId == playerId && s.isCurrentlyActive())
            .toList() ??
        [];
  }

  Future<void> init() async {
    await _ensureInitialized();
  }

  Future<void> close() async {
    await _box?.close();
    _initialized = false;
  }
}

class ScheduleAdapter extends TypeAdapter<Schedule> {
  @override
  final int typeId = 2;

  @override
  Schedule read(BinaryReader reader) {
    final jsonString = reader.readString();
    return Schedule.fromJson(jsonDecode(jsonString));
  }

  @override
  void write(BinaryWriter writer, Schedule obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}

class RecurrencePatternAdapter extends TypeAdapter<RecurrencePattern> {
  @override
  final int typeId = 7;

  @override
  RecurrencePattern read(BinaryReader reader) {
    return RecurrencePattern.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, RecurrencePattern obj) {
    writer.writeInt(obj.index);
  }
}

class ScheduledMediaAdapter extends TypeAdapter<ScheduledMedia> {
  @override
  final int typeId = 8;

  @override
  ScheduledMedia read(BinaryReader reader) {
    final jsonString = reader.readString();
    return ScheduledMedia.fromJson(jsonDecode(jsonString));
  }

  @override
  void write(BinaryWriter writer, ScheduledMedia obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}
