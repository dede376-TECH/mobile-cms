import '../../domain/interfaces/idashboard_repository.dart';
import '../../domain/models/dashboard_item.dart';
import '../datasources/dashboard_remote_datasource.dart';

class DashboardRepositoryImpl implements IDashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;

  DashboardRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<DashboardItem>> getDashboardItems() async {
    return await remoteDataSource.getDashboardItems();
  }
}
