import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/business_config_model.dart';
import '../data/services/business_service.dart';
import '../core/constants/app_strings.dart';

enum BusinessConfigStatus { loading, loaded, error }

class BusinessConfigState {
  final BusinessConfigStatus status;
  final BusinessConfig       config;
  final String?              error;

  const BusinessConfigState({required this.status, required this.config, this.error});
}

class BusinessConfigNotifier extends StateNotifier<BusinessConfigState> {
  final BusinessService _service;

  BusinessConfigNotifier(this._service)
      : super(const BusinessConfigState(
          status: BusinessConfigStatus.loading,
          config: BusinessConfig(),
        ));

  Future<void> load() async {
    try {
      state = BusinessConfigState(status: BusinessConfigStatus.loading, config: state.config);
      final config = await _service.getConfig();
      AppStrings.applyBusinessConfig(config);
      state = BusinessConfigState(status: BusinessConfigStatus.loaded, config: config);
    } catch (e) {
      state = BusinessConfigState(
        status: BusinessConfigStatus.error,
        config: state.config,
        error: e.toString(),
      );
    }
  }

  Future<void> save(BusinessConfig newConfig) async {
    final updated = await _service.updateConfig(newConfig);
    AppStrings.applyBusinessConfig(updated);
    state = BusinessConfigState(status: BusinessConfigStatus.loaded, config: updated);
  }

  /// Reseta pro estado inicial (ex: no logout, pra não vazar config de um
  /// usuário pro próximo que logar no mesmo aparelho)
  void reset() {
    state = const BusinessConfigState(
      status: BusinessConfigStatus.loading,
      config: BusinessConfig(),
    );
  }
}

final businessConfigProvider =
    StateNotifierProvider<BusinessConfigNotifier, BusinessConfigState>((ref) {
  return BusinessConfigNotifier(BusinessService());
});
