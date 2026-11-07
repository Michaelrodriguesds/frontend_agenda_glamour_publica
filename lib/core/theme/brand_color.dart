import 'package:flutter/material.dart';
import 'app_palette.dart';

/// Cor da MARCA do negócio (escolhida no cadastro) aplicada por cima do
/// ESTILO do app.
///
/// O problema: cada negócio escolhe a cor que quiser, e algumas cores não
/// dão leitura em todo estilo. Ex.: amarelo-claro no estilo Claro (fundo
/// branco) some; azul-marinho no estilo escuro some. E o texto dos botões
/// é branco, então a cor também não pode ser clara demais.
///
/// A solução: [fit] mantém o TOM da cor (o "matiz": rosa continua rosa,
/// azul continua azul) e só clareia ou escurece o mínimo necessário para
/// passar nas duas regras de leitura:
///   1. texto branco por cima da cor (botões): contraste ≥ 3
///   2. a cor por cima do cartão do estilo (ícones, títulos): contraste ≥ 3
/// Se a cor já passa, ela fica EXATAMENTE como o negócio escolheu.
///
/// Contraste é a conta oficial de acessibilidade (WCAG): 1 = cores iguais,
/// 21 = preto no branco. 3 é o mínimo recomendado para botões e ícones.
class BrandColor {
  BrandColor._();

  static const double minContrast = 3.0;

  /// Contraste WCAG entre duas cores.
  static double contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final hi = la > lb ? la : lb;
    final lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  /// "#RRGGBB" -> cor. Qualquer valor inválido devolve null.
  static Color? parse(String? hex) {
    if (hex == null) return null;
    final h = hex.trim();
    if (!RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(h)) return null;
    return Color(0xFF000000 | int.parse(h.substring(1), radix: 16));
  }

  static bool _ok(Color c, AppPalette p) =>
      contrast(Colors.white, c) >= minContrast && contrast(c, p.card) >= minContrast;

  /// A cor da marca ajustada para ser legível no estilo [p].
  static Color fit(Color brand, AppPalette p) {
    if (_ok(brand, p)) return brand;

    final hsl = HSLColor.fromColor(brand);
    // Procura a lightness (0 = preto, 1 = branco) mais próxima da original
    // que passa nas duas regras. Passos de 1%: no máximo 100 tentativas.
    for (var step = 1; step <= 100; step++) {
      final d = step / 100;
      for (final l in [hsl.lightness - d, hsl.lightness + d]) {
        if (l < 0 || l > 1) continue;
        final c = hsl.withLightness(l).toColor();
        if (_ok(c, p)) return c;
      }
    }
    // Nenhum ajuste serviu (não acontece com os estilos do app, mas por
    // garantia): usa a cor principal do próprio estilo.
    return p.rose;
  }

  /// Versão mais escura (gradientes, botão pressionado).
  static Color darker(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - 0.10).clamp(0.0, 1.0)).toColor();
  }

  /// Versão para TEXTO e destaques: no estilo escuro, mais clara; no
  /// claro, um pouco mais escura (precisa ler bem sobre o cartão).
  static Color accentText(Color c, AppPalette p) {
    final hsl = HSLColor.fromColor(c);
    if (p.isDark) {
      return hsl.withLightness((hsl.lightness + 0.15).clamp(0.0, 0.88)).toColor();
    }
    return hsl.withLightness((hsl.lightness - 0.06).clamp(0.0, 1.0)).toColor();
  }

  /// As duas cores são parecidas? (distância simples de RGB)
  static bool similar(Color a, Color b, {double limit = 60}) {
    double ch(double v) => v * 255;
    final dr = ch(a.r) - ch(b.r), dg = ch(a.g) - ch(b.g), db = ch(a.b) - ch(b.b);
    return (dr * dr + dg * dg + db * db) <= limit * limit;
  }
}
