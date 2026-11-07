import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'business_config_provider.dart';
import '../core/utils/auth_events.dart';
import '../data/services/auth_service.dart';

// ── Estados possíveis ──────────────────────
enum AuthStatus { checking, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String?    error;

  const AuthState({required this.status, this.error});

  AuthState copyWith({AuthStatus? status, String? error}) =>
      AuthState(status: status ?? this.status, error: error);
}

// ── Notifier ────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _service;

  AuthNotifier(this._service)
      : super(const AuthState(status: AuthStatus.checking)) {
    AuthEvents.instance.addListener(_onForcedLogout);
    _check();
  }

  void _onForcedLogout() {
    if (mounted) state = const AuthState(status: AuthStatus.unauthenticated);
  }

  @override
  void dispose() {
    AuthEvents.instance.removeListener(_onForcedLogout);
    super.dispose();
  }

  /// Verifica se já está logado ao abrir o app
  Future<void> _check() async {
    final logged = await _service.isLoggedIn();
    state = AuthState(
      status: logged ? AuthStatus.authenticated : AuthStatus.unauthenticated,
    );
  }

  Future<void> login(String email, String password) async {
    try {
      state = state.copyWith(status: AuthStatus.checking, error: null);
      await _service.login(email, password);
      state = state.copyWith(status: AuthStatus.authenticated);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }

  Future<void> register({
    required String email,
    required String password,
    String? businessName,
    List<String>? locations,
  }) async {
    try {
      state = state.copyWith(status: AuthStatus.checking, error: null);
      await _service.register(
        email: email,
        password: password,
        businessName: businessName,
        locations: locations,
      );
      state = state.copyWith(status: AuthStatus.authenticated);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    await _service.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

// ── Provider global ──────────────────────────
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(AuthService());
});

// ── Nome para a saudação ─────────────────────
// Ordem: 1) "Seu nome" das Configurações do negócio; 2) o que vier do login
// (e-mail do token: "ana.souza@…" -> "Ana"). Recalcula no login/logout e
// quando a configuração do negócio é salva.
final userNameProvider = FutureProvider<String?>((ref) async {
  final auth = ref.watch(authProvider);
  if (auth.status != AuthStatus.authenticated) return null;
  final owner = ref.watch(businessConfigProvider.select((s) => s.config.ownerName)).trim();
  if (owner.isNotEmpty) return owner;
  return AuthService().displayName();
});
