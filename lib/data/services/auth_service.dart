import 'package:dio/dio.dart';
import 'api_service.dart';
import 'cache_service.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/utils/trial_gate.dart';

class AuthService {
  final _api = ApiService();

  /// Cria uma conta nova (30 dias grátis a partir de agora)
  Future<void> register({
    required String email,
    required String password,
    String? businessName,
    List<String>? locations,
  }) async {
    try {
      final response = await _api.dio.post(
        ApiEndpoints.register,
        data: {
          'email': email,
          'password': password,
          if (businessName != null) 'businessName': businessName,
          if (locations != null) 'locations': locations,
        },
      );
      final token = response.data['token'] as String;
      await _api.saveToken(token);
    } on DioException catch (e) {
      throw _api.handleError(e);
    }
  }

  /// Faz login (e-mail + senha) e salva o token JWT no armazenamento seguro
  Future<void> login(String email, String password) async {
    try {
      final response = await _api.dio.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );
      final token = response.data['token'] as String;
      await _api.saveToken(token);
    } on DioException catch (e) {
      throw _api.handleError(e);
    }
  }

  /// Envia o código de redefinição de senha para o e-mail informado
  Future<void> forgotPassword(String email) async {
    try {
      await _api.dio.post(ApiEndpoints.forgotPassword, data: {'email': email});
    } on DioException catch (e) {
      throw _api.handleError(e);
    }
  }

  /// Redefine a senha usando o código recebido por e-mail
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await _api.dio.post(ApiEndpoints.resetPassword, data: {
        'email': email,
        'code': code,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      throw _api.handleError(e);
    }
  }

  /// Perfil completo do usuário logado — usado pra mostrar o businessId
  /// e o status do plano na tela de configurações.
  Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await _api.dio.get(ApiEndpoints.me);
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _api.handleError(e);
    }
  }

  /// Remove o token e limpa o cache local — logout completo
  Future<void> logout() async {
    await _api.clearToken();
    await CacheService.instance.clear();
    TrialGate.instance.clear();
  }

  /// Verifica se o usuário está autenticado (tem token salvo)
  Future<bool> isLoggedIn() async {
    return await _api.hasToken();
  }
}
