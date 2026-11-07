import 'package:belaagenda/core/constants/app_colors.dart';
import 'package:belaagenda/core/constants/app_strings.dart';
import 'package:belaagenda/core/theme/app_palette.dart';
import 'package:belaagenda/core/theme/brand_color.dart';
import 'package:belaagenda/data/models/business_config_model.dart';
import 'package:belaagenda/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

double contrast(Color a, Color b) => BrandColor.contrast(a, b);

// As cores que o cadastro (onboarding) oferece para a marca.
const presets = ['#B47FD4', '#E8527A', '#4ECBA0', '#F0C060', '#98CFFF', '#FF9898'];

// Cores "difíceis" que um negócio pode escolher.
const extremas = ['#FFFF00', '#FFFFFF', '#000000', '#0A1A3A', '#00FF00', '#808080', '#3B0A0A'];

void main() {
  // Cada teste começa com o estilo original e sem marca.
  setUp(() {
    AppColors.apply(AppPalette.rosePalette);
    AppStrings.procedures = [];
  });

  group('estilos', () {
    test('6 estilos com ids únicos; id desconhecido volta para o Rosé', () {
      final ids = AppPalette.all.map((p) => p.id).toList();
      expect(ids.length, 6);
      expect(ids.toSet().length, ids.length);
      expect(AppPalette.byId('oceano').name, 'Oceano');
      expect(AppPalette.byId('nao-existe').id, 'rose');
      expect(AppPalette.byId(null).id, 'rose');
    });

    test('Rosé mantém as cores originais do BelaAgenda (inclusive as dos serviços)', () {
      const p = AppPalette.rosePalette;
      expect(p.background, const Color(0xFF0F0A14));
      expect(p.card, const Color(0xFF1A1225));
      expect(p.rose, const Color(0xFFE8527A));
      expect(p.text, const Color(0xFFF5EEF8));
      expect(p.procedureColors, const [
        Color(0xFFB47FD4), Color(0xFF4ECBA0), Color(0xFFE8527A), Color(0xFFFF9898),
        Color(0xFF98CFFF), Color(0xFFF0C060), Color(0xFFD4A8F0), Color(0xFFFF85A1),
      ]);
    });

    for (final p in AppPalette.all.where((p) => p.id != 'rose')) {
      test('legibilidade: ${p.name}', () {
        expect(contrast(p.text, p.card), greaterThanOrEqualTo(4.5));
        expect(contrast(p.textMuted, p.card), greaterThanOrEqualTo(4.5));
        expect(contrast(p.textDim, p.card), greaterThanOrEqualTo(3.0));
        expect(contrast(Colors.white, p.rose), greaterThanOrEqualTo(3.0));
        for (final c in [p.rose, p.green, p.gold, p.error, p.lavender, p.extraPink, p.extraBlue]) {
          expect(contrast(c, p.card), greaterThanOrEqualTo(3.0));
        }
      });
    }
  });

  group('cor da marca (BrandColor)', () {
    test('lê "#RRGGBB" e recusa valor inválido', () {
      expect(BrandColor.parse('#E8527A'), const Color(0xFFE8527A));
      expect(BrandColor.parse('E8527A'), isNull);
      expect(BrandColor.parse('#E852'), isNull);
      expect(BrandColor.parse(null), isNull);
    });

    test('cor que já tem leitura fica EXATAMENTE como o negócio escolheu', () {
      final lilas = BrandColor.parse('#B47FD4')!; // padrão do cadastro
      expect(BrandColor.fit(lilas, AppPalette.rosePalette), lilas);
    });

    for (final p in AppPalette.all) {
      test('qualquer cor fica legível no estilo ${p.name}', () {
        for (final hex in [...presets, ...extremas]) {
          final c = BrandColor.fit(BrandColor.parse(hex)!, p);
          expect(contrast(Colors.white, c), greaterThanOrEqualTo(3.0), reason: '$hex: texto branco no botão');
          expect(contrast(c, p.card), greaterThanOrEqualTo(3.0), reason: '$hex: cor no cartão');
        }
      });
    }

    test('ajuste mantém o tom (amarelo continua amarelo, só mais escuro)', () {
      final c = BrandColor.fit(const Color(0xFFFFFF00), AppPalette.claroPalette);
      final h = HSLColor.fromColor(c);
      expect(h.hue, closeTo(60, 1));
      expect(h.lightness, lessThan(0.5));
    });
  });

  group('AppColors com estilo + marca', () {
    test('sem marca: a cor principal é a do estilo', () {
      AppColors.apply(AppPalette.oceanoPalette);
      expect(AppColors.rose, AppPalette.oceanoPalette.rose);
      expect(AppColors.card, AppPalette.oceanoPalette.card);
      expect(AppColors.brand, isNull);
    });

    test('com marca: a principal é a marca; fundo e texto continuam do estilo', () {
      const verde = Color(0xFF0E7C5B);
      AppColors.apply(AppPalette.claroPalette, brand: verde);
      expect(AppColors.rose, BrandColor.fit(verde, AppPalette.claroPalette));
      expect(AppColors.background, AppPalette.claroPalette.background);
      expect(AppColors.text, AppPalette.claroPalette.text);
      expect(AppColors.green, AppPalette.claroPalette.green);
    });

    test('marca parecida com a secundária: a secundária troca para não confundir', () {
      AppColors.apply(AppPalette.rosePalette, brand: const Color(0xFFB47FD4));
      expect(AppColors.rose, const Color(0xFFB47FD4));
      expect(AppColors.lavender, AppPalette.rosePalette.rose);
    });

    test('cor dos serviços pela posição na lista do negócio', () {
      AppStrings.procedures = ['Corte', 'Escova', 'Manicure'];
      AppColors.apply(AppPalette.oceanoPalette);
      expect(AppColors.forProcedure('Corte'), AppColors.lavender);
      expect(AppColors.forProcedure('Escova + Manicure'), AppColors.green);
      expect(AppColors.forProcedure('Serviço antigo'), AppColors.lavender);
    });
  });

  group('ThemeController (salvo no aparelho)', () {
    test('sem nada salvo: Rosé + cor da marca ligada', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ThemeController();
      await c.load();
      expect(c.state.palette.id, 'rose');
      expect(c.state.useBrandColor, isTrue);
    });

    test('escolher salva estilo e chave da marca', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ThemeController();
      await c.choose(AppPalette.esmeraldaPalette, useBrandColor: false);
      expect(c.state.palette.id, 'esmeralda');
      expect(c.state.useBrandColor, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme'), 'esmeralda');
      expect(prefs.getBool('use_brand_color'), isFalse);
    });

    test('ao abrir de novo carrega o salvo; valor inválido não quebra', () async {
      SharedPreferences.setMockInitialValues({'app_theme': 'claro', 'use_brand_color': false});
      final c = ThemeController();
      await c.load();
      expect(c.state.palette.id, 'claro');
      expect(c.state.useBrandColor, isFalse);

      SharedPreferences.setMockInitialValues({'app_theme': 'tema-apagado'});
      final d = ThemeController();
      await d.load();
      expect(d.state.palette.id, 'rose');
    });
  });

  group('configuração do negócio', () {
    test('dias para retorno e nome do dono vão e voltam do servidor', () {
      final cfg = BusinessConfig.fromJson({
        'businessName': 'Studio Bella',
        'ownerName': 'Ana',
        'services': [
          {'name': 'Cílios', 'price': 120, 'active': true, 'returnDays': 15},
          {'name': 'Manicure', 'price': 40}, // servidor antigo: sem o campo
        ],
        'locations': ['Centro'],
      });
      expect(cfg.ownerName, 'Ana');
      expect(cfg.services[0].returnDays, 15);
      expect(cfg.services[1].returnDays, 0);
      final json = cfg.toJson();
      expect(json['ownerName'], 'Ana');
      expect((json['services'] as List)[0]['returnDays'], 15);
      expect(cfg.services[1].copyWith(returnDays: 30).returnDays, 30);
    });
  });
}
