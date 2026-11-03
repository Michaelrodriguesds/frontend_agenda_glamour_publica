import 'package:flutter/foundation.dart';

/// Avisa o app quando o ApiService precisou encerrar a sessão sozinho
/// (token inválido/antigo e refresh falhou). O AuthNotifier escuta isto
/// e volta para a tela de login, em vez de ficar preso numa tela com erro.
class AuthEvents extends ChangeNotifier {
  AuthEvents._();
  static final AuthEvents instance = AuthEvents._();

  void forcedLogout() => notifyListeners();
}
