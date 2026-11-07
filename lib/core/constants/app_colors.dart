import 'package:flutter/material.dart';
import '../theme/app_palette.dart';
import '../theme/brand_color.dart';
import 'app_strings.dart';

/// Cores do BelaAgenda.
///
/// ANTES: cada cor era `static const` — fixa, decidida na compilação.
/// AGORA: cada cor é um `get` que devolve a cor do ESTILO escolhido
/// (veja app_palette.dart), com a COR DA MARCA do negócio por cima.
/// As telas continuam escrevendo `AppColors.rose`, `AppColors.card`…
/// sem saber qual estilo ou qual negócio está ativo.
///
/// Leia `rose` como "cor principal". Com "Usar a cor da minha marca"
/// ligado, a cor principal é a cor do negócio (ajustada para ter leitura,
/// ver brand_color.dart); desligado, é a cor do próprio estilo.
///
/// Por isso as cores NÃO são mais `const`: um `const` é calculado uma vez
/// quando o app é compilado e nunca muda. Como a cor agora depende da
/// escolha de cada negócio, ela só existe com o app rodando.
///
/// Quem chama [apply] é o main.dart, sempre que o estilo, a chave da marca
/// ou a configuração do negócio mudam. Ninguém mais deve chamar [apply].
class AppColors {
  AppColors._();

  static AppPalette _palette = AppPalette.rosePalette;
  static Color? _brand; // cor da marca JÁ ajustada (null = usa a do estilo)

  static Color _rose          = _palette.rose;
  static Color _roseDark      = _palette.roseDark;
  static Color _roseLight     = _palette.roseLight;
  static Color _lavender      = _palette.lavender;
  static Color _lavenderLight = _palette.lavenderLight;

  /// Estilo ativo agora.
  static AppPalette get palette => _palette;

  /// Cor da marca em uso (já ajustada), ou null se está usando a do estilo.
  static Color? get brand => _brand;

  /// Troca o estilo e, se [brand] vier, usa a cor da marca como principal.
  /// Depois disso o app precisa ser redesenhado (o main.dart faz isso
  /// trocando a `key` do MaterialApp).
  static void apply(AppPalette palette, {Color? brand}) {
    _palette = palette;
    if (brand == null) {
      _brand         = null;
      _rose          = palette.rose;
      _roseDark      = palette.roseDark;
      _roseLight     = palette.roseLight;
      _lavender      = palette.lavender;
      _lavenderLight = palette.lavenderLight;
      return;
    }
    final c = BrandColor.fit(brand, palette);
    _brand     = c;
    _rose      = c;
    _roseDark  = BrandColor.darker(c);
    _roseLight = BrandColor.accentText(c, palette);
    // Se a marca for parecida com a cor secundária do estilo (ex.: marca
    // lilás no Rosé), a secundária vira a principal do estilo, para as
    // duas não se confundirem na tela.
    final swap = BrandColor.similar(c, palette.lavender);
    _lavender      = swap ? palette.rose : palette.lavender;
    _lavenderLight = swap ? palette.roseLight : palette.lavenderLight;
  }

  // ── Fundo ──────────────────────────────────
  static Color get background => _palette.background;
  static Color get card       => _palette.card;
  static Color get cardBorder => _palette.cardBorder;
  static Color get inputFill  => _palette.inputFill;

  // ── Principal ("rose") e secundária ("lavender") ──
  static Color get rose          => _rose;
  static Color get roseDark      => _roseDark;
  static Color get roseLight     => _roseLight;
  static Color get lavender      => _lavender;
  static Color get lavenderLight => _lavenderLight;

  // ── Avisos ─────────────────────────────────
  static Color get green => _palette.green; // Pago / Disponível
  static Color get gold  => _palette.gold;  // Pendente / Parcial
  static Color get error => _palette.error; // Erro / Lotado

  // ── Texto ──────────────────────────────────
  static Color get text      => _palette.text;
  static Color get textMuted => _palette.textMuted;
  static Color get textDim   => _palette.textDim;

  // ── Serviços: cor pela posição do serviço na lista do negócio ──
  static List<Color> get _procPalette =>
      [lavender, green, rose, _palette.extraPink, _palette.extraBlue, gold, lavenderLight, roseLight];

  /// Cor do serviço. Aceita combos ("A + B"): usa o primeiro serviço.
  static Color forProcedure(String procedure) {
    final first = procedure.split(' + ').first.trim();
    final i = AppStrings.procedures.indexOf(first);
    final colors = _procPalette;
    return i < 0 ? lavender : colors[i % colors.length];
  }
}
