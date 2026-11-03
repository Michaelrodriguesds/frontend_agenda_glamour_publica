import 'package:flutter/foundation.dart';

/// Broadcaster global e simples (não depende do Riverpod) que o
/// [ApiService] usa pra avisar o resto do app quando qualquer chamada
/// retornar 403 "TRIAL_EXPIRED". O `main.dart` escuta isso pra trocar
/// a tela inteira pela tela de bloqueio, sem precisar passar isso por
/// cada provider individualmente.
class TrialGate extends ChangeNotifier {
  TrialGate._();
  static final TrialGate instance = TrialGate._();

  bool   _blocked    = false;
  String? businessId;

  bool get blocked => _blocked;

  void block(String? businessId) {
    _blocked = true;
    this.businessId = businessId;
    notifyListeners();
  }

  /// Chamado quando o usuário consegue de novo (ex: você liberou o acesso
  /// e ele apertou "tentar novamente")
  void clear() {
    _blocked = false;
    notifyListeners();
  }
}
