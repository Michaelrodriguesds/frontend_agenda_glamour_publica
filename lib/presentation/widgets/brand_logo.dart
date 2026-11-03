import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Mostra a logo do negócio. Aceita:
///   • data URL  (data:image/jpeg;base64,...) — logo escolhida da galeria
///   • link http(s)
///   • vazio → mostra o emoji 🌸 no lugar
class BrandLogo extends StatelessWidget {
  final String logo;
  final double size;
  const BrandLogo({super.key, required this.logo, this.size = 36});

  // Evita decodificar o base64 a cada rebuild.
  static String? _lastKey;
  static Uint8List? _lastBytes;

  static Uint8List? _decode(String data) {
    if (_lastKey == data) return _lastBytes;
    try {
      final bytes = base64Decode(data.substring(data.indexOf(',') + 1));
      _lastKey = data;
      _lastBytes = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  Widget _fallback() => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(size / 4),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Text('🌸', style: TextStyle(fontSize: size * 0.5)),
      );

  @override
  Widget build(BuildContext context) {
    Widget? img;
    if (logo.startsWith('data:image')) {
      final bytes = _decode(logo);
      if (bytes != null) {
        img = Image.memory(bytes,
            width: size, height: size, fit: BoxFit.cover, gaplessPlayback: true,
            errorBuilder: (_, __, ___) => _fallback());
      }
    } else if (logo.startsWith('http')) {
      img = Image.network(logo,
          width: size, height: size, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback());
    }
    if (img == null) return _fallback();
    return ClipRRect(borderRadius: BorderRadius.circular(size / 4), child: img);
  }
}
