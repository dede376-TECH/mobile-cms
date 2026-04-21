import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/interfaces/imedia_repository.dart';
import '../../domain/models/media_item.dart';

/// Implémentation Hive du repository des médias
class HiveMediaRepository implements IMediaRepository {
  Box<MediaItem>? _box;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(MediaItemAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(MediaTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(TransitionTypeAdapter());
    }

    _box ??= await Hive.openBox<MediaItem>('mediaItems');
    _initialized = true;
  }

  @override
  Future<void> save(MediaItem media) async {
    await _ensureInitialized();
    await _box!.put(media.id, media);
  }

  @override
  Future<void> delete(String id) async {
    await _ensureInitialized();
    await _box!.delete(id);
  }

  @override
  MediaItem? get(String id) {
    if (!_initialized) return null;
    return _box?.get(id);
  }

  @override
  List<MediaItem> getAll() {
    if (!_initialized) return [];
    return _box?.values.toList() ?? [];
  }

  Future<void> init() async {
    await _ensureInitialized();
  }

  Future<void> close() async {
    await _box?.close();
    _initialized = false;
  }
}

class MediaItemAdapter extends TypeAdapter<MediaItem> {
  @override
  final int typeId = 3;

  @override
  MediaItem read(BinaryReader reader) {
    final jsonString = reader.readString();
    return MediaItem.fromJson(jsonDecode(jsonString));
  }

  @override
  void write(BinaryWriter writer, MediaItem obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}

class MediaTypeAdapter extends TypeAdapter<MediaType> {
  @override
  final int typeId = 5;

  @override
  MediaType read(BinaryReader reader) {
    return MediaType.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, MediaType obj) {
    writer.writeInt(obj.index);
  }
}

class TransitionTypeAdapter extends TypeAdapter<TransitionType> {
  @override
  final int typeId = 6;

  @override
  TransitionType read(BinaryReader reader) {
    return TransitionType.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, TransitionType obj) {
    writer.writeInt(obj.index);
  }
}
