import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/interfaces/iplayer_repository.dart';
import '../../domain/models/player.dart';

/// Implémentation Hive du repository des players
/// Respecte le DIP : dépend de l'abstraction IPlayerRepository
class HivePlayerRepository implements IPlayerRepository {
  Box<Player>? _box;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(PlayerAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(PlayerStatusAdapter());
    }

    _box ??= await Hive.openBox<Player>('players');
    _initialized = true;
  }

  @override
  Future<void> save(Player player) async {
    await _ensureInitialized();
    await _box!.put(player.id, player);
  }

  @override
  Future<void> delete(String id) async {
    await _ensureInitialized();
    await _box!.delete(id);
  }

  @override
  Player? get(String id) {
    if (!_initialized) return null;
    return _box?.get(id);
  }

  @override
  List<Player> getAll() {
    if (!_initialized) return [];
    return _box?.values.toList() ?? [];
  }

  @override
  Future<void> updateStatus(String playerId, PlayerStatus status) async {
    await _ensureInitialized();
    final player = _box!.get(playerId);
    if (player != null) {
      final updated = player.copyWith(status: status, lastSeen: DateTime.now());
      await _box!.put(playerId, updated);
    }
  }

  Future<void> init() async {
    await _ensureInitialized();
  }

  Future<void> close() async {
    await _box?.close();
    _initialized = false;
  }
}

// Hive Adapters (déplacés ici pour cohésion)
class PlayerAdapter extends TypeAdapter<Player> {
  @override
  final int typeId = 1;

  @override
  Player read(BinaryReader reader) {
    final jsonString = reader.readString();
    return Player.fromJson(jsonDecode(jsonString));
  }

  @override
  void write(BinaryWriter writer, Player obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}

class PlayerStatusAdapter extends TypeAdapter<PlayerStatus> {
  @override
  final int typeId = 4;

  @override
  PlayerStatus read(BinaryReader reader) {
    return PlayerStatus.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, PlayerStatus obj) {
    writer.writeInt(obj.index);
  }
}
