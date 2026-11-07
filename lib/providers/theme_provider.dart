import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_palette.dart';

/// O que o usuário escolheu para a aparência do app.
class ThemeSettings {
  /// Estilo (fundo, cartões, textos, cores de aviso).
  final AppPalette palette;

  /// true = a cor principal é a cor da marca do negócio (padrão);
  /// false = a cor principal é a do próprio estilo.
  final bool useBrandColor;

  const ThemeSettings({required this.palette, this.useBrandColor = true});
}

/// Aparência escolhida no app.
///
/// Fluxo:
///   1. Ao abrir o app, [ThemeController.load] lê a escolha salva no aparelho.
///   2. No Início, o botão de paleta (🎨) abre os estilos; ao escolher,
///      [ThemeController.choose] é chamado.
///   3. O main.dart "observa" este provider (e a configuração do negócio):
///      monta as cores em AppColors e redesenha o app inteiro.
///
/// Fica salvo no navegador/celular (SharedPreferences), então vale por
/// aparelho. A COR DA MARCA não fica aqui: ela é do negócio e vem do
/// servidor (Configurações do negócio), igual em todos os aparelhos.
final themeProvider = StateNotifierProvider<ThemeController, ThemeSettings>(
  (ref) => ThemeController(),
);

class ThemeController extends StateNotifier<ThemeSettings> {
  ThemeController() : super(const ThemeSettings(palette: AppPalette.rosePalette));

  static const _paletteKey = 'app_theme';
  static const _brandKey   = 'use_brand_color';

  /// Lê o que foi salvo. Sem nada salvo (ou erro): Rosé + cor da marca.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = ThemeSettings(
        palette:       AppPalette.byId(prefs.getString(_paletteKey)),
        useBrandColor: prefs.getBool(_brandKey) ?? true,
      );
    } catch (_) {
      // Sem acesso ao armazenamento: segue com o padrão.
    }
  }

  /// Aplica a escolha e salva no aparelho.
  Future<void> choose(AppPalette palette, {required bool useBrandColor}) async {
    state = ThemeSettings(palette: palette, useBrandColor: useBrandColor);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_paletteKey, palette.id);
      await prefs.setBool(_brandKey, useBrandColor);
    } catch (_) {
      // Não conseguiu salvar: vale até fechar o app.
    }
  }
}
