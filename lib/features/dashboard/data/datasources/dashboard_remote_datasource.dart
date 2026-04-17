import '../../../../services/api_service.dart';
import '../../domain/models/dashboard_item.dart';

abstract class DashboardRemoteDataSource {
  Future<List<DashboardItem>> getDashboardItems();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final ApiService apiService;

  DashboardRemoteDataSourceImpl(this.apiService);

  @override
  Future<List<DashboardItem>> getDashboardItems() async {
    // Simuler un appel API
    await Future.delayed(const Duration(seconds: 1));
    return [
      DashboardItem(id: '1', title: 'Item 1', description: 'Description 1'),
      DashboardItem(id: '2', title: 'Item 2', description: 'Description 2'),
    ];

    /* Logic avec ApiService :
    final response = await apiService.fetchData('/dashboard');
    return (response as List).map((e) => DashboardItem.fromJson(e)).toList();
    */
  }
}
