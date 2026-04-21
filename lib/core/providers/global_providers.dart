import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/player/presentation/providers/player_provider.dart';
import '../../features/schedule/presentation/providers/schedule_provider.dart';
import '../../features/media/presentation/providers/media_provider.dart';
import '../di/injection_container.dart';

// Providers globaux pour Riverpod
final playerProviderRef = Provider<PlayerProvider>((ref) {
  return sl<PlayerProvider>();
});

final scheduleProviderRef = Provider<ScheduleProvider>((ref) {
  return sl<ScheduleProvider>();
});

final mediaProviderRef = Provider<MediaProvider>((ref) {
  return sl<MediaProvider>();
});
