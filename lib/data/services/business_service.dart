import 'package:dio/dio.dart';
import 'api_service.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/business_config_model.dart';

class BusinessConfigService {
  final _api = ApiService();

  Future<BusinessConfig> getConfig() async {
    try {
      final response = await _api.dio.get(ApiEndpoints.businessConfig);
      return BusinessConfig.fromJson(response.data);
    } on DioException catch (e) {
      throw _api.handleError(e);
    }
  }

  Future<BusinessConfig> updateConfig(BusinessConfig config) async {
    try {
      final response = await _api.dio.put(ApiEndpoints.businessConfig, data: config.toJson());
      return BusinessConfig.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _api.handleError(e);
    }
  }
}
