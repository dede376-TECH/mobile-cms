import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../network/dio_client.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../services/notification_service.dart';
import '../../services/http_communication_service.dart';
import '../../services/mdns_discovery_service.dart';
import '../../services/websocket_status_service.dart';

import '../../features/dashboard/domain/interfaces/idashboard_repository.dart';
import '../../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../../features/dashboard/data/datasources/dashboard_remote_datasource.dart';

import '../../features/player/data/repositories/hive_player_repository.dart';
import '../../features/schedule/data/repositories/hive_schedule_repository.dart';
import '../../features/media/data/repositories/hive_media_repository.dart';

import '../network/interfaces/communication_interfaces.dart';
import '../../features/player/domain/interfaces/iplayer_repository.dart';
import '../../features/schedule/domain/interfaces/ischedule_repository.dart';
import '../../features/media/domain/interfaces/imedia_repository.dart';

import '../../features/player/presentation/providers/player_provider.dart';
import '../../features/schedule/presentation/providers/schedule_provider.dart';
import '../../features/media/presentation/providers/media_provider.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Core
  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(() => DioClient(sl()));

  // Services
  sl.registerLazySingleton(() => ApiService(sl()));
  sl.registerLazySingleton(() => StorageService());
  sl.registerLazySingleton(() => NotificationService());
  sl.registerLazySingleton(() => HttpCommunicationService());
  sl.registerLazySingleton(() => MdnsDiscoveryService());
  sl.registerLazySingleton(() => WebSocketStatusService());

  // Features - Repositories
  sl.registerLazySingleton<IDashboardRepository>(
    () => DashboardRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<IPlayerRepository>(() => HivePlayerRepository());
  sl.registerLazySingleton<IScheduleRepository>(() => HiveScheduleRepository());
  sl.registerLazySingleton<IMediaRepository>(() => HiveMediaRepository());

  // Features - Data sources (if any, for now only remote for dashboard)
  sl.registerLazySingleton<DashboardRemoteDataSource>(
    () => DashboardRemoteDataSourceImpl(sl()),
  );

  // Communication Services (interfaces)
  sl.registerLazySingleton<IPlayerDiscovery>(() => sl<MdnsDiscoveryService>());
  sl.registerLazySingleton<IPlayerHealthChecker>(
    () => sl<HttpCommunicationService>(),
  );
  sl.registerLazySingleton<IPlayerController>(
    () => sl<HttpCommunicationService>(),
  );
  sl.registerLazySingleton<IScheduleSender>(
    () => sl<HttpCommunicationService>(),
  );
  sl.registerLazySingleton<IMediaSender>(() => sl<HttpCommunicationService>());
  sl.registerLazySingleton<IRealtimeStatusListener>(
    () => sl<WebSocketStatusService>(),
  );

  // Providers
  sl.registerLazySingleton<PlayerProvider>(
    () => PlayerProvider(
      repository: sl(),
      discovery: sl(),
      healthChecker: sl(),
      controller: sl(),
      scheduleSender: sl(),
      realtimeStatus: sl(),
    ),
  );

  sl.registerLazySingleton<ScheduleProvider>(
    () => ScheduleProvider(repository: sl(), scheduleSender: sl()),
  );

  sl.registerLazySingleton<MediaProvider>(
    () => MediaProvider(repository: sl(), mediaSender: sl()),
  );
}
