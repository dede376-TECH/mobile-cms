import '../core/network/dio_client.dart';

class ApiService {
  final DioClient dioClient;

  ApiService(this.dioClient);

  // Méthodes spécifiques à l'API
  Future<dynamic> fetchData(String endpoint) async {
    try {
      final response = await dioClient.get(endpoint);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Ajoutez d'autres méthodes d'API ici
}
